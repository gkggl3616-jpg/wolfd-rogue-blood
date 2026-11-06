extends SceneTree
var game
var output = "/workspace/scratch/mobile-visuals"
var captures = []
var failures = 0
func _initialize():
	if not OS.get_cmdline_user_args().is_empty(): output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func frames(count):
	for _i in range(count): await process_frame
func capture(name):
	await frames(8)
	await RenderingServer.frame_post_draw
	var pixels = root.get_texture().get_image()
	var path = output.path_join(name + ".png")
	var error = pixels.save_png(path)
	if error != OK: failures += 1
	var details={"name": name, "path": path, "width": pixels.get_width(), "height": pixels.get_height(), "saved": error == OK}
	var ui=game.library_panel if is_instance_valid(game.library_panel) else game.pc_panel
	if is_instance_valid(ui):
		details["sourceLayouts"]=ui.source_layouts.duplicate();details["nativeCanvasPosition"]=[ui.canvas.position.x,ui.canvas.position.y];details["nativeCanvasScale"]=[ui.canvas.scale.x,ui.canvas.scale.y]
	captures.append(details)
	print("VISUAL_CAPTURE ",path)
func run():
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate();game.test_mode = true;root.add_child(game)
	await capture("launcher-1280")
	game.show_home();await capture("lobby-1280")
	game.pc_panel.choose_section();await capture("extra-sections-1280");game.pc_panel.close_modal()
	game.show_library("Envanter");await capture("inventory-1280")
	game.library_panel.selected=game.book.weapon(game.book.slots.pistol);game.library_panel.detail_helper.info_tab="properties";game.library_panel.detail_helper.refresh_grid();await capture("weapon-properties-1280")
	game.library_panel.target_primary_slot="secondary_primary";game.equip_item_from_ui(game.book.weapon(game.book.slots.primary),"secondary_primary");game.library_panel.selected=game.book.weapon(game.book.slots.primary);game.library_panel.refresh();await capture("secondary-slot-1280")
	root.size=Vector2i(1024,768);await capture("inventory-native-1024")
	root.size=Vector2i(1920,1080);await capture("inventory-1920")
	root.size=Vector2i(1280,720)
	for page in ["Mağaza","Karakterler","Dövmeler","Efektler","power","Kartlar"]:
		game.library_panel.navigate(page);await capture({"Mağaza":"shop","Karakterler":"characters","Dövmeler":"tattoos","Efektler":"effects","power":"power","Kartlar":"cards"}[page]+"-1280")
	game.library_panel.page = "Ayarlar";game.library_panel.refresh();await capture("settings-1280")
	for tab in ["Kontrol","Görüntü","Diğer"]:
		game.library_panel.settings_tab=tab;game.library_panel.refresh();await capture({"Kontrol":"settings-controls","Görüntü":"settings-graphics","Diğer":"settings-other"}[tab]+"-1280")
	game.library_panel.detail_helper.changed("invert_y",true);game.library_panel.go_back();await capture("settings-unsaved-1280")
	game.library_panel.close_modal();game.library_panel.settings_dirty=false
	game.library_panel.close_menu();await frames(2)
	game.show_home()
	for page in ["profile","gifts","events","missions","friends","clan","ranking"]:
		game.pc_panel.navigate(page);await capture(page+"-1280")
		if game.pc_panel.modal!=null:game.pc_panel.close_modal()
	game.show_home();game.pc_panel.navigate("create_room");await capture("create-room-1280")
	game.local_room={"title":"Yerel Eğitim","mode":0,"map":0,"team":"blue"};game.pc_panel.navigate("room");await capture("room-1280")
	game.start_round();game.spawn_clock = 1000;await frames(25)
	await capture("human-1280")
	game.pause_game();await capture("pause-1280");game.resume();await frames(2)
	game.player.switch_form();await frames(25)
	await capture("wolf-1280")
	game.block(Vector3(0,2,-7),Vector3(4,6,0.4),"576371")
	game.equipment.equip_power(19601)
	game.player.position = Vector3(0,1.4,-6.35);game.player.velocity = Vector3(0,0,-9)
	game.player.yaw = 0;game.player.rotation.y = 0
	Input.action_press("forward");await frames(2);Input.action_release("forward");await frames(2);Input.action_press("forward");await frames(4)
	game.player.action_time = 0;game.attack()
	await capture("wolf-wall-hold-1280")
	Input.action_release("forward")
	game.player.reset_combat();game.player.position=Vector3(0,3,0);game.player.velocity=Vector3.ZERO
	Input.action_press("forward");await frames(2);game.player.wolf_running=true;game.strong_attack();await capture("airborne-attack-1280");Input.action_release("forward")
	game.show_maps()
	for index in range(game.mode_picker.item_count):
		if game.mode_picker.get_item_id(index) == 1000: game.mode_picker.select(index)
	game.refresh_mode_maps()
	for index in range(game.map_picker.item_count):
		if game.map_picker.get_item_id(index) == 84: game.map_picker.select(index)
	game.refresh_map_status();game.start_map_preview()
	if game.player.is_wolf: game.player.switch_form()
	await capture("container-ship-1280")
	game.local_room={"title":"Çevrimdışı Bot Maçı","mode":0,"map":84,"team":"blue"}
	game.show_home();game.pc_panel.navigate("room");await capture("offline-room-1280")
	game.start_round();game.spawn_clock=1000;await frames(20);game.spawn_enemy();await frames(15)
	await capture("offline-container-bots-1280")
	game.end_round("Yerel maç tamamlandı");await capture("offline-result-1280")
	game.local_room={"title":"Zor Botlar","mode":0,"map":0,"team":"blue","botDifficulty":"hard"}
	game.start_round();game.spawn_clock=1000
	game.player.position=Vector3(0,0.1,5);game.player.velocity=Vector3.ZERO
	game.spawn_enemy("human","hard");var bot=game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())[-1]
	bot.brain_enabled=false;bot.position=Vector3(0,0.1,0);bot.rotation.y=PI;bot.set_physics_process(false)
	await capture("human-bot-hard-1280")
	bot.ammo=0;bot.begin_reload();await capture("bot-reload-1280")
	root.size=Vector2i(2160,992);game.start_round();game.spawn_clock=1000
	if not game.player.is_wolf:game.player.switch_form()
	await frames(20);await capture("wolf-reference-aspect-2160")
	game.player.switch_form();await frames(20);await capture("human-reference-aspect-2160")
	game.show_home();root.size = Vector2i(1920,1080);await capture("lobby-1920")
	game.show_front_screen("servers");await capture("servers-1920")
	root.size=Vector2i(1024,768);game.show_home();await capture("lobby-native-1024")
	var report = {"rendering": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(), "captures": captures, "physicalAndroidDeviceTested": false, "allCharacterStatesValidated": false, "failures": failures}
	var file = FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	game.queue_free();await frames(3)
	print("VISUAL_QA failures=",failures)
	quit(0 if failures == 0 else 1)
