extends SceneTree
var output="/workspace/wolfd-rogue-blood/docs/review/human-014"
var captures=[]
var game
func _initialize():
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=20):
	for i in range(n):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw
	var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path)
	captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK})
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	game.show_library("Karakterler");await capture("human-character-inventory-014")
	root.size=Vector2i(1024,768);await capture("human-character-inventory-native-014")
	root.size=Vector2i(1280,720);game.local_room={"mode":0,"map":84,"team":"blue"};game.start_round();game.spawn_clock=10000;await frames();game.set_process(false)
	for i in range(3):game.enemy_defeated({"target":"BOT %d" % (i+1),"headshot":i==1})
	game.source_hud.refresh_from_game();await capture("human-hud-kill-feed-014")
	var report={"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"physicalAndroidDeviceTested":false,"testFixtureCombatEvents":true};var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	game.queue_free();await frames();quit()
