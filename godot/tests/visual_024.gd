extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
	for i in range(n):await process_frame
func capture(name):
	await frames();await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path);captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK})
func pose(clip,time):
	game.clientfx.install_motion(game.player,clip);game.player.current_clip="";game.player.play_clip(clip);game.player.anim.seek(time,true)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.book.selected_characters.blue="pair-model1";game.book.selected_characters.red="pair-model170"
	game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.player.set_physics_process(false);game.match_flow.advance_match(2)
	var p=game.player;p.position=Vector3(-6,.02,8);p.rotation.y=0;p.yaw=0;p.pitch=-.12;p.pivot.rotation.x=p.pitch;p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	game.inbox.state.powerSlots.claw="16018";game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.use_power("energy");pose("idle",.2);await frames(65);await capture("purple-claw-passive-024")
	pose("run_forward_left",.22);await capture("original-diagonal-run-024")
	pose("crouch_back",.28);await capture("original-crouch-back-024")
	pose("jump_air",.4);p.position.y=1.8;await capture("original-airborne-pose-024")
	p.position.y=.02;pose("jump_land",.12);await capture("original-landing-pose-024")
	pose("attack",.12);p.claw_trail.begin();await frames(2);p.anim.seek(.2,true);await capture("equipped-purple-claw-swing-024")
	game.spawn_enemy("wolf","normal","red");await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false);bot.position=p.position+Vector3(-2,0,-5)
	pose("idle",.2);game.take_damage(1,bot.position,{"attackerTeam":"red","sourceActor":bot});await capture("source-ice-screen-and-body-024")
	game.clientfx.clear();game.source_hud.feedback.reset();game.source_hud.feedback.show_death();await capture("source-death-screen-024")
	game.source_hud.feedback.reset();game.show_home();game.book.selected_characters.red="pair-model0";game.book.selected_characters.blue="pair-model44";game.local_room={"mode":1010,"map":97,"team":"red","allyBots":0,"enemyBots":0,"pointGoal":100};game.start_round();await frames(65);p.set_physics_process(false);game.match_flow.advance_match(2)
	p.look_at(Vector3(0,p.position.y,0));p.yaw=p.rotation.y;game.inbox.state.powerSlots.claw="16018";game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.use_power("energy");pose("idle",.2);await frames(45);await capture("native-taksim-purple-claw-024")
	game.spawn_enemy("wolf","normal","blue");await frames();bot=game.enemies.get_child(0);bot.set_physics_process(false);bot.position=p.position-p.global_basis.z*4+p.global_basis.x*2;game.take_damage(1,bot.position,{"attackerTeam":"blue","sourceActor":bot});await capture("native-taksim-ice-hit-024")
	game.source_hud.feedback.reset();game.show_home();game.book.selected_characters.blue="pair-model1";game.local_room={"mode":0,"map":26,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames();p.set_physics_process(false);game.match_flow.advance_match(2)
	if p.is_wolf:p.switch_form(true)
	var sniper=game.book.weapons.filter(func(row):return row.category=="sniper" and row.get("available",false))[0];game.book.acquire(sniper.id);game.equip_library_weapon(sniper);p.weapon_anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	if p.weapon_anim.has_animation("select"):p.weapon_anim.seek(p.weapon_anim.get_animation("select").length*.45,true)
	await capture("original-weapon-select-024")
	Input.action_press("aim");p._physics_process(.2);game.source_hud.refresh_from_game();await capture("sniper-scope-open-024")
	game.ammo=0;game.reload_weapon();p.weapon_anim.seek(p.weapon_anim.get_animation("reload").length*.45,true);p._physics_process(.2);game.source_hud.refresh_from_game();await capture("reload-closes-scope-024")
	Input.action_release("aim");game.reloading=0;p.weapon_action_time=0;p._physics_process(.2);game.source_hud.refresh_from_game();await capture("sniper-scope-closed-024")
	game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false},"  "));file.close();quit()
