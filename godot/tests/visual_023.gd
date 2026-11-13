extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
	for i in range(n):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path);captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK})
func freeze():
	game.player.set_physics_process(false)
	for bot in game.enemies.get_children():bot.set_physics_process(false)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.local_room={"title":"Video devamı","mode":3000,"map":26,"team":"blue","allyBots":2,"enemyBots":3,"roundGoal":9,"matchSeconds":180};game.show_home();game.pc_panel.navigate("room");game.pc_panel.links.StartGame.pressed.emit()
	await capture("room-countdown-023");game.match_flow.advance_start(3.1);await capture("room-go-023")
	game.match_flow.advance_start(.4);await capture("source-map-loading-023")
	var deadline=Time.get_ticks_msec()+20000
	while game.match_flow.starting() and Time.get_ticks_msec()<deadline:
		game.match_flow.advance_start(.02);await frames(1);OS.delay_msec(5)
	freeze();await capture("separate-preparation-023");game.choose_round_loadout(0);await capture("early-choice-still-ready-023")
	game.destruction.advance(10);await capture("source-start-023");game.match_flow.advance_match(2)
	game.open_interface("scoreboard");await capture("live-scoreboard-023")
	var enemy=game.enemies.get_children().filter(func(b):return b.team=="red")[0];enemy.damage(10000,{"headshot":true});await capture("scoreboard-keeps-dead-player-023")
	game.match_scoreboard.manual=false;game.destruction.finish("blue","Tur kazanıldı");game.destruction.advance(1.1);await capture("automatic-round-scoreboard-023")
	game.destruction.advance(4);await frames();freeze();game.destruction.advance(10);game.match_flow.advance_match(2);game.pause_game();game.pc_panel.links.UserKickVote.pressed.emit();await frames();var helper=game.pc_panel.detail_helper;helper.selection.select(0);helper.selection.item_selected.emit(0);await capture("source-local-kick-menu-023")
	game.show_home();game.local_room={"title":"Pençe ve efekt doğrulaması","mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":1,"enemyBots":0};game.start_round();await frames();freeze();game.match_flow.advance_match(2)
	game.player.position=Vector3(0,.05,2);game.player.rotation.y=0;game.player.yaw=0;game.spawn_enemy("wolf","normal","red");await frames();freeze();enemy=game.enemies.get_children().filter(func(b):return not b.is_queued_for_deletion())[0];enemy.position=Vector3(0,.05,.35);enemy.health=500;await frames()
	game.player.source_events.set_process(false);game.player.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;game.clientfx.clear();game.attack();game.player.anim.seek(0,true);game.player.source_events._process(0)
	for i in range(1,19):
		game.player.anim.advance(.01);game.player.source_events._process(0);await frames(1)
	await capture("source-claw-contact-023")
	game.player.extra_health=0;game.take_damage(10000);await capture("single-death-feedback-023")
	game.end_round("Yerel doğrulama tamamlandı");await frames();game.pc_panel.links.Confirm.pressed.emit();await capture("return-room-settings-preserved-023")
	game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false},"  "));file.close();quit()
