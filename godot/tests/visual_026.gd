extends SceneTree
const Native=preload("res://ui/source_layout.gd")
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
	for i in range(n):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func select(picker,id):
	for i in range(picker.item_count):
		if picker.get_item_id(i)==id:picker.select(i);picker.item_selected.emit(i);return
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	var ui=game.pc_panel;ui.navigate("entry");await capture("entry-and-local-profile-026")
	var desktop=preload("res://ui/pc_screens.gd").new();desktop.ui=ui;desktop.local_name_window();await capture("source-player-name-dialog-026");ui.close_modal()
	ui.navigate("servers");await capture("source-local-server-selection-026");ui.navigate("lobby");await capture("source-lobby-empty-026")
	ui.navigate("create_room");await capture("source-compact-room-creator-026")
	select(ui.room_mode,1000);ui.room_map.select(0);ui.room_map.item_selected.emit(0);await capture("source-mode-variant-and-map-026")
	ui.links["Bot ve maç ayarları"].pressed.emit();await capture("separate-bot-and-match-settings-026");ui.go_back()
	ui.links["Harita görselleri"].pressed.emit();await capture("source-map-gallery-create-026");ui.close_modal()
	ui.room_title.text="Video odası";ui.room_title.text_changed.emit(ui.room_title.text);ui.room_allies.select(2);ui.room_allies.item_selected.emit(2);ui.room_enemies.select(3);ui.room_enemies.item_selected.emit(3);ui.links.PLOK.pressed.emit();await capture("source-team-rosters-owner-and-bots-026")
	ui.links.ChangeTeam.pressed.emit();await capture("source-team-change-026")
	ui.links.ChangeRule.pressed.emit();await capture("source-room-rule-dialog-026");ui.detail_helper.show_maps();await capture("source-map-gallery-room-settings-026");ui.close_modal();ui.links.PLCancel.pressed.emit()
	ui.go_back();await capture("source-lobby-room-columns-026");ui.navigate("room");ui.links.StartGame.pressed.emit();await capture("source-room-start-countdown-026")
	game.match_flow.advance_start(3.5);await capture("source-map-loading-026")
	var deadline=Time.get_ticks_msec()+20000
	while game.match_flow.starting() and Time.get_ticks_msec()<deadline:game.match_flow.advance_start(.1);await frames(1);OS.delay_msec(5)
	game.player.set_physics_process(false)
	for bot in game.enemies.get_children():bot.set_physics_process(false)
	await capture("source-preparation-after-loading-026");game.match_flow.advance_match(10);await capture("source-match-start-026")
	game.end_round("Görüntü kontrolü");await capture("source-result-and-return-026");game.pc_panel.links.Confirm.pressed.emit();await capture("source-return-to-same-room-026")
	game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false},"  "));file.close();quit()
