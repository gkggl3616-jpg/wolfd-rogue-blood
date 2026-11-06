extends SceneTree
var game
var output="/dev/shm/wolf-pc-reference-12/visuals"
var captures=[]
var failures=0
func _initialize():
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(count=8):
	for i in range(count):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw
	var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path)
	if error!=OK:failures+=1
	captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK});print("REFERENCE_CAPTURE ",path)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	await capture("entry-012")
	game.show_home();game.pc_panel.navigate("pin");await capture("second-password-012")
	game.pc_panel.navigate("rankbook");await capture("rank-catalogue-012")
	game.pc_panel.navigate("missions");await capture("toolbar-missions-012")
	game.pc_panel.navigate("missions");await capture("local-missions-012")
	game.pc_panel.navigate("create_room");var ui=game.pc_panel
	for i in range(ui.room_map.item_count):
		if ui.room_map.get_item_id(i)==84:ui.room_map.select(i);ui.room_map.item_selected.emit(i)
	ui.links["▣"].pressed.emit();await capture("map-photo-gallery-012")
	ui.close_modal();ui.links.PLOK.pressed.emit();await capture("room-map-photo-rank-012")
	game.show_library("Dövmeler");ui=game.library_panel
	for role in ["body","left","right"]:
		var entry=game.book.tattoos.filter(func(row):return row.role==role)[0];game.book.set_tattoo(role,entry.texture)
	ui.preview_angle=PI;ui.selected=game.book.tattoos.filter(func(row):return row.role=="body")[0];ui.refresh();await capture("wolf-tattoo-slots-012")
	ui.close_menu();game.show_home();game.pc_panel.navigate("Kutular");ui=game.pc_panel
	game.grant_money("cash",1000,"Görüntü kontrolü yerel örnek bakiyesi")
	game.box_action("buy","mystery","visual-purchase");game.accept_gift(game.inbox.state.messages[-1].id);ui.refresh();await capture("box-inventory-012")
	ui.detail_helper.open_box(game.boxes.box("mystery"));await capture("box-opening-012");await frames(110);await capture("box-reward-012")
	ui.close_modal();game.local_room={"title":"Kurt Avı","mode":game.LocalHunt.MODE,"map":84,"playerForm":"wolf","botDifficulty":"normal","team":"blue"};game.start_round();game.spawn_clock=1000;await frames(30);game.spawn_enemy();await capture("hunt-wolf-012")
	game.open_interface("scoreboard");await capture("match-scoreboard-012")
	game.local_room={"title":"Öğretici","mode":game.LocalTutorial.MODE,"map":84};game.start_round();await frames(20);await capture("tutorial-012")
	game.tutorial.active=false;var sniper=game.book.weapons.filter(func(row):return row.category=="sniper" and row.get("available",false))[0];game.book.acquire(sniper.id);game.equip_library_weapon(sniper)
	Input.action_press("aim");await frames(20);await capture("sniper-scope-012");Input.action_release("aim")
	root.size=Vector2i(1024,768);game.show_home();game.pc_panel.navigate("create_room");game.pc_panel.links["▣"].pressed.emit();await capture("map-photo-gallery-native-012")
	var report={"failures":failures,"captures":captures,"rendering":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"physicalAndroidDeviceTested":false,"testFixtureLocalCash":1000}
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	game.queue_free();await frames();print("REFERENCE_VISUAL_QA ",captures.size()," captures; failures=",failures);quit(0 if failures==0 else 1)
