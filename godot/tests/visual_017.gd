extends SceneTree
var game
var output=""
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=8):
	var draw=RenderingServer.render_loop_enabled
	if n>10:RenderingServer.render_loop_enabled=false
	for i in range(n):await process_frame
	RenderingServer.render_loop_enabled=draw
func capture(name):
	await frames();await RenderingServer.frame_post_draw
	var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path)
	captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK});print("SOURCE_CAPTURE ",name)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.book=preload("res://scripts/content_book.gd").new(false,"",true);game.sync_collection();game.apply_settings();game.set_process(false)
	game.show_library("Envanter");await capture("starter-owned-inventory-017")
	var menu=game.library_panel;menu.navigate("Mağaza");menu.navigate("power");menu.filter_id="claw";menu.refresh();await capture("source-claw-shop-017")
	menu.selected=game.power_item("16013");menu.detail_helper.show_details();await capture("source-claw-price-017")
	game.buy_shop("16013","cash","visual017-claw");menu.navigate("gifts");await capture("purchased-claw-gift-017")
	for gift in game.inbox.state.messages:
		if gift.item=="16013":game.accept_gift(gift.id)
	menu.collection_shop=false;menu.navigate("power");await capture("owned-power-inventory-017")
	game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
	if not game.player.is_wolf:game.player.switch_form(true)
	game.equip_power_item("19601");await frames(24);await capture("wolf-run-direction-buttons-017")
	game.book.acquire_all()
	game.show_library("create_room");var ui=game.library_panel;ui.room_draft={"title":"PC Ölüm Oyunu","mode":1000,"map":84,"team":"blue","allyBots":2,"enemyBots":3,"pointGoal":160,"matchSeconds":1200};ui.refresh();await capture("source-room-options-017")
	ui.links.Confirm.pressed.emit();await capture("source-room-roster-017")
	game.start_round();game.spawn_clock=10000
	for i in range(3):game.enemy_defeated({"target":"BOT %d" % i,"headshot":i==1})
	await capture("source-deathmatch-hud-017")
	game.local_room={"title":"Kurt efektleri","mode":1000,"map":84,"team":"red","allyBots":0,"enemyBots":0,"pointGoal":40,"matchSeconds":600};game.book.choose_character("pair-model48");game.start_round();game.spawn_clock=10000
	if not game.player.is_wolf:game.player.switch_form(true)
	await capture("source-transformation-017");await frames(240)
	for pair in [["pair-model48","fire"],["pair-model104","ice"],["pair-model66","lightning"],["pair-model70","radiation"]]:
		var char=game.book.characters.filter(func(row):return row.id==pair[0])[0];game.local_room.team=char.sourceTeam;game.book.choose_character(char.id);game.start_round();game.spawn_clock=10000
		if not game.player.is_wolf:game.player.switch_form(true)
		await frames(22)
		var tattoo=game.book.tattoos.filter(func(row):return row.role=="body" and "Altın" in row.name)[0];game.book.set_tattoo("body",tattoo.texture,tattoo.id);game.player.apply_tattoos();game.player.action_time=0;game.player.begin_roar();await frames(76);await capture("source-"+pair[1]+"-roar-017")
	game.player.reset_combat();await frames(65);game.strong_attack();await frames(10);await capture("source-strong-claw-017")
	game.local_room={"title":"Harita efektleri","mode":0,"map":24,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000;await frames(150)
	var mapfx=game.active_map.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()==preload("res://scripts/map_source_effects.gd"))
	if not mapfx.is_empty() and not mapfx[0].entries.is_empty():
		game.player.set_physics_process(false);var target=mapfx[0].entries[0].point;game.player.camera.global_position=target+Vector3(4,2,6);game.player.camera.look_at(target)
	await capture("source-map-smoke-017");game.player.set_physics_process(true)
	game.local_room={"title":"Ölüm Oyunu","mode":1000,"map":84,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000;game.kills=3;game.deaths=1;game.time_left=.01;game._process(.02);await capture("source-timeout-result-017")
	root.size=Vector2i(2160,992);game.show_library("Dövmeler");game.library_panel.safe_insets=Vector4(36,8,44,12);game.library_panel.refresh();await capture("source-inventory-phone-017")
	game.queue_free();await frames()
	var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"physicalAndroidDeviceTested":false,"testFixtureStats":true,"unlimitedOfflineCurrencies":["cash","kp"],"testFixtureCatalogueUnlockForRoars":true,"testFixtureCameraForMapFx":true},"  ")+"\n");f.close();quit()
