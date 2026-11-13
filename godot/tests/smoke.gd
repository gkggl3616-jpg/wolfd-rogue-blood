extends SceneTree

func _initialize():
	call_deferred("run")

func ensure(condition, text):
	if not condition:
		push_error("SMOKE FAILED: "+text)
		quit(1)
		return false
	print("PASS "+text)
	return true

func frames(count):
	for _i in range(count):
		await process_frame

func run():
	root.size = Vector2i(1280,720)
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await frames(3)
	if not ensure(game.map_catalog.valid and game.map_catalog.data.maps.size() == 34,"exactly thirty-four selected maps load"):return
	if not ensure(game.map_catalog.belongs_to_mode(3001,26) and not game.map_catalog.belongs_to_mode(1001,26),"Cappadocia belongs to destruction and cannot leak into deathmatch"):return
	if not ensure(game.map_catalog.belongs_to_mode(6010,72) and not game.map_catalog.belongs_to_mode(3001,72),"Ruins is restricted to its wolf rush modes"):return
	if not ensure(game.map_catalog.belongs_to_mode(5000,82) and not game.map_catalog.belongs_to_mode(1001,82),"Secret Lab is restricted to wolfhunt"):return
	if not ensure(game.map_catalog.map_record(46).allowedModeIds.is_empty() and game.map_catalog.map_record(47).is_empty(),"unverified Gobekli is retained without substituting the night variant"):return
	if not ensure(game.map_catalog.random_ready_map(3022).is_empty() and game.map_catalog.random_ready_map(-1).is_empty(),"random map selection cannot fall back to unready or unrelated maps"):return
	game.show_maps()
	for i in range(game.mode_picker.item_count):
		if game.mode_picker.get_item_id(i)==3022:game.mode_picker.select(i);game.refresh_mode_maps();break
	if not ensure(game.map_start.disabled and game.map_picker.item_count > 0,"mode picker shows linked maps while unfinished maps cannot start"):return
	await frames(3)
	if not ensure(game.overlay.get_global_rect().position.y >= 0 and game.overlay.get_global_rect().end.y <= root.size.y,"map selection panel fits the landscape screen"):return
	game.start_selected_map()
	if not ensure(not game.running and game.menu_open,"activation rechecks readiness and cannot launch the training arena as a source map"):return
	game.show_home()
	if not ensure(game.player.anim != null,"animated character imported"):return
	if not ensure(not game.player.third_person and not game.player.human.visible and game.player.camera_arm.spring_length == 0,"human starts in first person"):return
	for clip in ["idle","run","jump","attack","reload","crouch","crouch_run"]:
		if not ensure(game.player.anim.has_animation(clip),"human clip "+clip):return
	game.start_round()
	game.spawn_clock = 100
	await frames(25)
	if not ensure(game.running and not game.menu_open,"round starts"):return
	if not ensure(game.player.is_on_floor(),"player collision rests on arena floor"):return
	var old_z = game.player.position.z
	Input.action_press("forward")
	await frames(40)
	Input.action_release("forward")
	if not ensure(game.player.position.z < old_z - 0.5,"movement advances player"):return
	Input.action_press("jump")
	await frames(6)
	Input.action_release("jump")
	if not ensure(game.player.position.y > 0.1,"jump has physical height"):return
	await frames(70)
	game.touch.direction_buttons = false
	await frames(2)
	var down = InputEventScreenTouch.new()
	down.index = 1
	down.pressed = true
	down.position = game.touch.center
	Input.parse_input_event(down)
	var drag = InputEventScreenDrag.new()
	drag.index = 1
	drag.position = game.touch.center + Vector2(0,-60)
	drag.relative = Vector2(0,-60)
	Input.parse_input_event(drag)
	await frames(2)
	if not ensure(game.player.move_axis.y < -0.8,"touch joystick controls movement"):return
	var look = InputEventScreenTouch.new()
	look.index = 2
	look.pressed = true
	look.position = Vector2(700,300)
	Input.parse_input_event(look)
	var old_yaw = game.player.yaw
	var look_drag = InputEventScreenDrag.new()
	look_drag.index = 2
	look_drag.position = Vector2(725,310)
	look_drag.relative = Vector2(25,10)
	Input.parse_input_event(look_drag)
	await frames(2)
	if not ensure(game.player.yaw != old_yaw and game.player.move_axis.y < -0.8,"second finger looks while first finger moves"):return
	var fire = InputEventScreenTouch.new()
	fire.index = 3
	fire.pressed = true
	fire.position = game.touch.buttons[0].position
	game.player.shot_cooldown = 0
	var before_touch_ammo = game.ammo
	Input.parse_input_event(fire)
	await frames(3)
	if not ensure(game.ammo < before_touch_ammo and game.player.move_axis.y < -0.8,"third finger fires while movement remains held"):return
	for event in [fire,look,down]:
		event.pressed = false
		Input.parse_input_event(event)
	await frames(3)
	if not ensure(game.player.move_axis == Vector2.ZERO and not Input.is_action_pressed("fire"),"releasing touch fingers clears movement and fire"):return
	game.ammo = 30
	Input.action_press("crouch")
	await frames(5)
	if not ensure(game.player.crouching and game.player.capsule.height < 1.3,"crouch reduces the physical collision height"):return
	Input.action_release("crouch")
	await frames(5)
	if not ensure(not game.player.crouching and game.player.capsule.height > 1.7,"standing restores collision height when there is clearance"):return
	game.player.switch_form()
	if not ensure(game.player.third_person and game.player.camera_arm.spring_length > 3,"wolf has a collision-aware third-person camera"):return
	if not ensure(game.player.is_wolf and game.player.wolf.visible and not game.player.human.visible,"human transforms to wolf"):return
	for clip in ["idle","run","jump","attack","roar","crouch","crouch_run"]:
		if not ensure(game.player.anim.has_animation(clip),"wolf clip "+clip):return
	game.player.switch_form()
	if not ensure(not game.player.third_person and game.player.camera_arm.spring_length == 0,"returning to human restores first person"):return
	if not ensure(game.player.viewmodel.visible and game.player.weapon_anim.has_animation("reload") and game.player.weapon_anim.has_animation("fire"),"human first-person weapon and hand animations are imported"):return
	game.touch.direction_buttons = true
	await frames(2)
	if not ensure(game.touch.buttons.size() == 13 and game.touch.buttons[7].visible,"four movement buttons, separate run and wolf roll buttons are available"):return
	game.player.switch_form()
	game.equipment.equip_power(0)
	game.player.reset_locomotion()
	Input.action_press("forward")
	await frames(3)
	Input.action_release("forward")
	await frames(3)
	Input.action_press("forward")
	await frames(3)
	if not ensure(not game.player.wolf_running,"double forward without equipped ability cannot start wolf run"):return
	Input.action_release("forward")
	await frames(3)
	game.equipment.equip_power(19601)
	game.player.reset_locomotion()
	var forward_touch = InputEventScreenTouch.new()
	forward_touch.index = 4
	forward_touch.position = game.touch.buttons[7].position
	forward_touch.pressed = true
	Input.parse_input_event(forward_touch)
	await frames(3)
	forward_touch.pressed = false
	Input.parse_input_event(forward_touch)
	await frames(3)
	forward_touch.pressed = true
	Input.parse_input_event(forward_touch)
	await frames(3)
	if not ensure(game.player.wolf_running and game.player.movement_speed > 9,"double forward touch activates wolf run only with the power item equipped"):return
	await frames(22)
	if not ensure(game.player.wolf_running,"holding the second forward press keeps wolf run active"):return
	forward_touch.pressed = false
	Input.parse_input_event(forward_touch)
	await frames(3)
	if not ensure(not game.player.wolf_running,"releasing forward stops wolf run"):return
	game.player.reset_locomotion()
	Input.action_press("forward")
	await frames(3)
	Input.action_release("forward")
	await frames(25)
	Input.action_press("forward")
	await frames(3)
	if not ensure(not game.player.wolf_running,"slow separate taps do not count as a double tap"):return
	Input.action_release("forward")
	await frames(3)
	game.player.switch_form()
	game.player.reset_locomotion()
	Input.action_press("forward")
	await frames(3)
	Input.action_release("forward")
	await frames(3)
	Input.action_press("forward")
	await frames(3)
	if not ensure(not game.player.wolf_running,"human cannot activate wolf run even with the item equipped"):return
	Input.action_release("forward")
	await frames(3)
	var run_touch = InputEventScreenTouch.new()
	run_touch.index = 5
	run_touch.position = game.touch.buttons[5].position
	run_touch.pressed = true
	Input.parse_input_event(run_touch)
	await frames(3)
	run_touch.pressed = false
	Input.parse_input_event(run_touch)
	await frames(3)
	Input.action_press("forward")
	await frames(3)
	if not ensure(game.player.normal_run_toggled and game.player.movement_speed > 5,"run button toggles normal sprint without holding another finger"):return
	Input.action_release("forward")
	game.show_inventory()
	await frames(3)
	if not ensure(not game.player.normal_run_toggled and not game.player.wolf_running and game.overlay.get_global_rect().end.y <= root.size.y,"inventory pauses movement, clears sprint and fits the screen"):return
	game.resume()
	game.player.shot_cooldown = 0
	game.attack()
	if not ensure(game.ammo == 29,"firing consumes ammunition"):return
	game.reload_weapon()
	await frames(165)
	if not ensure(game.ammo == 30 and game.reserve == 119,"reload transfers reserve ammunition"):return
	for enemy in game.enemies.get_children():
		enemy.queue_free()
	await frames(2)
	game.spawn_clock = 100
	game.spawn_enemy()
	var enemy = game.enemies.get_child(0)
	enemy.health=100 # Wounded fixture: damage/finisher checks are independent of default wolf HP.
	enemy.position = game.player.position - game.player.global_basis.z * 1.7
	enemy.set_physics_process(false)
	await frames(3)
	game.player.switch_form()
	game.player.shot_cooldown = 0
	game.attack()
	await frames(15)
	if not ensure(enemy.health == 55,"wolf claw damages a visible nearby target"):return
	var before = game.wallet.cash
	game.player.wolf_running = true
	game.player.shot_cooldown = 0
	game.attack()
	await frames(15)
	if not ensure(game.kills==1 and not game.player.wolf_running,"running body attack requires the equipped ability and uses its own contact animation"):return
	# The body attack already defeated this target.
	if not ensure(game.kills == 1 and game.wallet.cash == before+25,"defeating a target grants the configured local reward"):return
	game.take_damage(game.health+game.player.extra_health)
	if not ensure(not game.running and game.health == 0,"zero health ends the round"):return
	game.grant_money("gold",1000,"Smoke test")
	if not ensure(game.wallet.gold == 1000,"local administrator can grant gold"):return
	game.show_maps()
	for index in range(game.mode_picker.item_count):
		if game.mode_picker.get_item_id(index) == 1000:
			game.mode_picker.select(index)
	game.refresh_mode_maps()
	for index in range(game.map_picker.item_count):
		if game.map_picker.get_item_id(index) == 84:
			game.map_picker.select(index)
	game.refresh_map_status()
	if not ensure(not game.map_preview.disabled and not game.map_start.disabled,"source map supports distinct exploration and its newly implemented deathmatch"):return
	game.start_map_preview()
	await frames(35)
	if not ensure(game.exploring and game.active_map != null and game.player.is_on_floor(),"source Container Ship scene loads and its source spawn rests on the generated collision"):return
	if not ensure(not game.arena_root.visible and game.enemies.get_child_count() == 0,"source map exploration disables the training arena and random arena enemies"):return
	var old_time = game.time_left
	await frames(5)
	if not ensure(game.time_left == old_time,"exploration does not pretend to run the original match timer"):return
	game.start_round()
	await frames(30)
	if not ensure(not game.exploring and game.arena_root.visible and game.player.is_on_floor(),"returning from a source map restores the training floor and round"):return
	print("WOLF_ROGUE_SMOKE_OK")
	game.queue_free()
	await frames(3)
	quit(0)
