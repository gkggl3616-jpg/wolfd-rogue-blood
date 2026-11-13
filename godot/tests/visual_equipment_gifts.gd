extends SceneTree
var output="/workspace/wolfd-rogue-blood/docs/review/equipment-013"
var game
var captures=[]
var failures=0
func _initialize():
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=20):
	for i in range(n):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path)
	if error!=OK:failures+=1
	captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK});print("EQUIPMENT_CAPTURE ",path)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	game.book.acquire_all();game.seed_gifts();game.grant_money("cash",2000,"QA görüntü örnek bakiyesi")
	for item in game.book.weapons.filter(func(row):return row.get("available",false) and row.category in ["rifle","sniper","pistol"]).slice(0,10):game.inbox.enqueue(game.inbox.state,"weapon",item.id,item.name,1,"visual-"+item.id,"QA · Örnek hediye")
	game.show_home();game.pc_panel.navigate("gifts");await capture("gift-inbox-013")
	var helper=game.pc_panel.detail_helper;helper.cards.filter(func(node):return node is BaseButton)[0].pressed.emit();await capture("gift-confirmation-013");game.pc_panel.close_modal()
	for gift in game.inbox.state.messages.duplicate():game.accept_gift(gift.id)
	game.inbox.state.powerCounts["13006"]=1;game.inbox.state.powerCounts["19602"]=1
	for id in ["19002","19502","13006","19602"]:game.equip_power_item(id)
	game.show_library("power");await capture("wolf-power-inventory-013")
	game.library_panel.filter_id="bag";game.library_panel.refresh();await capture("wolf-bag-filter-013")
	game.library_panel.navigate("Dövmeler");await capture("wolf-tattoo-inventory-013")
	game.library_panel.navigate("Envanter");game.library_panel.filter_id="primary";game.library_panel.refresh();await capture("human-loadout-slots-013")
	game.library_panel.detail_helper.info_tab="properties";game.library_panel.detail_helper.show_details();await capture("human-weapon-properties-013")
	game.local_room={"title":"Ekipman seçimi","mode":0,"map":84,"team":"blue"};game.start_round(true);game.match_sp=10000;game.spawn_clock=1000;game.set_process(false);await capture("round-weapon-selection-013")
	game.choose_round_loadout(1);game.player.switch_form();await capture("round-wolf-selection-013")
	for team in ["blue","red"]:
		game.local_room.team=team
		for id in ["power","guardian","ghost"]:
			if not game.selection_active:game.open_round_selection("wolf")
			if not game.choose_round_mutation(id):failures+=1
			game.player.position=game.preview_spawn;game.health=game.max_health();await capture("wolf-"+id+"-"+team+"-013")
	root.size=Vector2i(1024,768);game.open_round_selection("wolf");await capture("round-wolf-selection-native-013")
	game.close_round_selection();game.show_home();game.pc_panel.navigate("gifts");game.pc_panel.detail_helper.tab="history";game.pc_panel.detail_helper.render();await capture("gift-history-native-013")
	var report={"captures":captures,"failures":failures,"rendering":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"physicalAndroidDeviceTested":false,"testFixtureGifts":true,"testFixtureLocalCash":2000,"testFixtureMatchSp":10000};var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	game.queue_free();await frames();print("EQUIPMENT_VISUAL_QA ",captures.size()," captures; ",failures," failures");quit(0 if failures==0 else 1)
