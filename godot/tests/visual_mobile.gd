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
	captures.append({"name": name, "path": path, "width": pixels.get_width(), "height": pixels.get_height(), "saved": error == OK})
	print("VISUAL_CAPTURE ",path)
func run():
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate();game.test_mode = true;root.add_child(game)
	await capture("launcher-1280")
	game.show_home();await capture("lobby-1280")
	game.show_library("Envanter");await capture("inventory-1280")
	game.library_panel.page = "Ayarlar";game.library_panel.refresh();await capture("settings-1280")
	game.library_panel.close_menu();await frames(2)
	game.start_round();game.spawn_clock = 1000;await frames(25)
	await capture("human-1280")
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
	game.show_maps()
	for index in range(game.mode_picker.item_count):
		if game.mode_picker.get_item_id(index) == 1000: game.mode_picker.select(index)
	game.refresh_mode_maps()
	for index in range(game.map_picker.item_count):
		if game.map_picker.get_item_id(index) == 84: game.map_picker.select(index)
	game.refresh_map_status();game.start_map_preview()
	if game.player.is_wolf: game.player.switch_form()
	await capture("container-ship-1280")
	game.show_home();root.size = Vector2i(1920,1080);await capture("lobby-1920")
	game.show_front_screen("servers");await capture("servers-1920")
	var report = {"rendering": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(), "captures": captures, "physicalAndroidDeviceTested": false, "allCharacterStatesValidated": false, "failures": failures}
	var file = FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	game.queue_free();await frames(3)
	print("VISUAL_QA failures=",failures)
	quit(0 if failures == 0 else 1)
