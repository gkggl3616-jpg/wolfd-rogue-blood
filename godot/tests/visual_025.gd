extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
	for i in range(n):await process_frame
func capture(name,settle=6):
	await frames(settle);await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path);captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK})
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.book.selected_characters.red="pair-model0";game.book.selected_characters.blue="pair-model44";game.local_room={"mode":1010,"map":97,"team":"red","allyBots":0,"enemyBots":0,"pointGoal":100};game.start_round();await frames(65)
	var p=game.player;p.set_physics_process(false);game.match_flow.advance_match(2);p.look_at(Vector3(0,p.position.y,0));p.yaw=p.rotation.y
	p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.play_clip("idle");p.anim.seek(.2,true)
	game.inbox.state.powerCounts={"16018":1,"19502":1,"19002":1};game.inbox.state.powerSlots.claw="16018";game.equip_power_item("19502");game.equip_power_item("19002");p.extra_health=80
	game.source_hud.refresh_from_game();await capture("owned-pack-ft-inactive-025")
	game.use_power("energy");p.claw_trail.refresh_glow();await frames(35);game.source_hud.refresh_from_game();await capture("ft-active-health-cost-025")
	game.clientfx.install_motion(p,"run_forward_left");p.play_clip("run_forward_left");p.anim.seek(.22,true);await capture("ft-running-original-clip-025")
	p.play_clip("idle");p.anim.seek(.2,true);game.use_power("support");game.source_hud.refresh_from_game();await capture("first-aid-and-ft-025")
	game.advance_power_effects(15);p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await frames(20);await capture("ft-expired-no-hand-glow-025")
	game.health=20;game.use_power("support");game.health=20;game.source_hud.refresh_from_game();await capture("first-aid-per-life-limit-025")
	game.use_power("energy");p.claw_trail.refresh_glow();await frames(30);game.source_hud.refresh_from_game();await capture("same-energy-pack-reused-025")
	game.clear_power_effects();game.show_home();game.local_room={"mode":0,"map":26,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);p.set_physics_process(false);game.match_flow.advance_match(2)
	if p.is_wolf:p.switch_form(true)
	var ak=game.book.weapons.filter(func(row):return row.get("available",false) and str(game.book.models.get(row.model,{}).get("source","")).to_lower().ends_with("wt_pv_akei47.ltb"))[0]
	game.book.acquire(ak.id);game.equip_library_weapon(ak);p.weapon_anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	p.weapon_anim.play("idle");p.weapon_anim.seek(.1,true);game.reloading=0;game.ammo=game.weapon_capacity();p.shot_cooldown=0;game.source_hud.refresh_from_game();await capture("ak-original-flash-socket-before-025")
	game.attack();await capture("ak-original-muzzle-flash-025",2)
	game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false},"  "));file.close();quit()
