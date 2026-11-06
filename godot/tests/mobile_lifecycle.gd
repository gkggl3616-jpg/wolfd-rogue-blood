extends SceneTree

var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func ensure(value, description):
	checks += 1
	if not value: failures += 1;push_error("FAIL " + description)
	else: print("PASS " + description)
func frames(count):
	for _i in range(count): await process_frame

func run():
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true;root.add_child(game)
	await frames(3)
	ensure(not quit_on_go_back,"Android Back is handled by game navigation instead of quitting the application")
	game.start_round();game.spawn_clock = 1000
	await frames(25)
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);await frames(2)
	ensure(game.running and game.menu_open and game.pc_panel.page=="pause","Android Back opens the source pause menu during a round")
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);await frames(2)
	ensure(game.running and not game.menu_open,"Android Back from the pause menu resumes without quitting")
	game.ammo = 11;game.reserve = 49
	var first = game.current_weapon_id
	game.equip_slot("pistol");game.ammo = 4;game.reserve = 7
	game.equip_slot("primary")
	ensure(game.current_weapon_id == first and game.ammo == 11 and game.reserve == 49, "switching weapons preserves individual ammunition")
	game.book.select_loadout(1);game.equip_slot("primary")
	ensure(game.ammo == 11 and game.reserve == 49, "switching equipment set cannot refill a shared weapon")
	game.equip_slot("pistol")
	ensure(game.ammo == 4 and game.reserve == 7, "secondary weapon ammunition remains independent")
	game.equip_slot("primary")
	game.reload_weapon()
	var reload_remaining = game.reloading
	Input.action_press("forward");Input.action_press("fire")
	game.player.normal_run_toggled = true
	game.suspend_application()
	ensure(game.application_suspended and paused and game.menu_open, "focus loss pauses the entire scene and opens pause menu")
	ensure(not Input.is_action_pressed("fire") and not Input.is_action_pressed("forward") and not game.player.normal_run_toggled, "focus loss clears held actions and sprint")
	var time_before = game.time_left
	var ammo_before = game.ammo
	await frames(15)
	game.attack()
	ensure(game.time_left == time_before and game.ammo == ammo_before and game.reloading == reload_remaining, "combat and reload timers cannot advance in background")
	game.restore_application()
	ensure(not game.application_suspended and not paused and game.menu_open, "returning from background waits for explicit Continue")
	game.resume();await frames(170)
	ensure(game.ammo == game.weapon_capacity() and game.reserve == 30, "interrupted reload transfers reserve exactly once after resume")
	game.book.set_setting("music_volume", 0.0)
	game.book.set_setting("weapons_volume", 0.6)
	game.apply_settings()
	ensure(AudioServer.is_bus_mute(AudioServer.get_bus_index("WolfMusic")), "music can be muted independently")
	ensure(not AudioServer.is_bus_mute(AudioServer.get_bus_index("WolfWeapons")) and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("WolfWeapons"))), 0.6), "weapon volume remains independent of music mute")
	game.equip_slot("grenade");game.player.shot_cooldown = 0;game.attack()
	ensure(game.get_children().any(func(node): return node.get_script() == game.GrenadeScript), "grenade action creates a live projectile")
	game.play_source_effect(game.book.effects[0], game.player.position)
	ensure(game.transient_effects.get_child_count() > 0, "source sprite effect attaches to transient scene root")
	var previous_effects=game.transient_effects.get_children()
	game.start_round()
	await frames(2)
	ensure(not game.get_children().any(func(node): return node.get_script() == game.GrenadeScript) and previous_effects.all(func(node):return not is_instance_valid(node)), "round transition removes previous projectiles and effects while permitting new source passives")
	game.show_library("Ayarlar");await frames(3)
	var veil=game.library_panel.get_child(0)
	ensure(game.menu_open and veil.visible and veil.color.a<1 and not game.menu_backdrop.visible, "in-game menu uses a translucent full-screen veil over the rendered scene")
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 768)]:
		root.size = size;await frames(3)
		veil=game.library_panel.get_child(0)
		ensure(veil.mouse_filter==Control.MOUSE_FILTER_STOP and veil.get_global_rect().encloses(Rect2(Vector2.ZERO, game.get_viewport().get_visible_rect().size)), "menu veil blocks gameplay input across viewport %s" % str(size))
	game.queue_free();await frames(3)
	print("MOBILE_LIFECYCLE_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
