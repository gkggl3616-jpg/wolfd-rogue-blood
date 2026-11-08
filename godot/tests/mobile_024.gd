extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(n=4):
	for i in range(n):await process_frame
func _initialize():call_deferred("run")
func run():
	game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.book.selected_characters.blue="pair-model1";game.book.selected_characters.red="pair-model170"
	game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000;await frames(65);game.player.set_physics_process(false)
	var p=game.player;var fx=game.clientfx
	check(p.is_wolf and p.is_on_floor(),"Locomotion starts with a real grounded wolf")
	check(is_equal_approx(p.camera_arm.spring_length,6.2) and is_equal_approx(p.pivot.position.y,1.0),"Default wolf framing follows the new video reference calibration")
	check(fx.motion_index.donors.size()==27,"All 27 admitted wolf donors have a locomotion record")
	for donor in fx.motion_index.donors:
		var row=fx.motion_index.donors[donor]
		check(row.clips.size()==16 and FileAccess.get_sha256(row.asset)==row.sha256,"Sixteen original compressed clips have verified bytes: "+donor)
	var directions={"run_left":Vector2.LEFT,"run_right":Vector2.RIGHT,"run_back":Vector2.DOWN,"run_forward_left":Vector2(-1,-1),"run_forward_right":Vector2(1,-1),"run_back_left":Vector2(-1,1),"run_back_right":Vector2(1,1)}
	for clip in directions:
		check(p.locomotion_clip(directions[clip])==clip and p.anim.has_animation(clip),"Movement selects the original directional clip: "+clip)
		check(fx.animation_record(p,clip).get("durationMs",0)>0,"Directional footsteps retain source event timing: "+clip)
	p.crouching=true
	check(p.locomotion_clip(Vector2.LEFT)=="crouch_left" and p.locomotion_clip(Vector2.DOWN)=="crouch_back","Crouched side/back movement uses its own clips")
	p.crouching=false;p.position.y=5;p.velocity=Vector3.ZERO;p._physics_process(.01);p.action_time=0;p.update_locomotion(Vector2.UP,.6)
	check(not p.is_on_floor() and p.current_clip=="jump_air","Expired takeoff keeps an airborne pose rather than running in midair")
	p.update_locomotion(Vector2.ZERO,1.5);check(p.current_clip=="jump_air","Long falls keep the original airborne pose")
	p.position=Vector3(-6,.005,8);p.velocity=Vector3.DOWN
	for i in range(5):p._physics_process(.016)
	check(p.is_on_floor() and p.current_clip=="jump_land" and p.landing_remaining>0,"Real floor contact starts the original landing clip")
	p.update_locomotion(Vector2.ZERO,1);check(p.current_clip=="idle","Landing finishes and returns to grounded movement")
	game.inbox.state.powerSlots.claw="16018";p.claw_trail.refresh_glow();await frames()
	check(p.claw_trail.glow.is_empty(),"Purple claw alone cannot activate the FT hand effect")
	game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.health=game.max_health();game.use_power("energy");p.claw_trail.refresh_glow();await frames()
	check(p.claw_trail.glow.size()==2,"Successfully activated FT creates both original hand glows")
	p.claw_trail.clear();p.claw_trail.refresh_glow();check(p.claw_trail.glow.size()==2,"Changing a claw ribbon cannot duplicate the energy effect")
	game.inbox.state.powerSlots.claw="";p.claw_trail.refresh_glow();check(p.claw_trail.glow.size()==2,"Changing the claw cannot cancel an active FT effect")
	game.clear_power_effects();await frames();check(p.claw_trail.glow.is_empty(),"Ending FT removes both glows independently of claw ownership")
	game.bot_roster.identity(game,"red",0).characterId="pair-model170";game.spawn_enemy("wolf","normal","red");await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false)
	check("icewolf" in fx.model_record(bot).get("donor",""),"Ice response uses the actual attacking character donor")
	var hp=game.health;game.take_damage(1,bot.position,{"attackerTeam":"red","sourceActor":bot})
	check(game.health==hp-1 and fx.frost.size()==1,"Confirmed ice hit adds presentation without extra damage")
	var frost=fx.group_instances(p,"lockedinice")
	check(frost.size()==1 and frost[0].screen_canvas!=null and frost[0].parts[0].node is TextureRect,"Source PlayerView ice becomes a screen texture rather than a world quad")
	check(fx.frost[0].remaining>3.3 and fx.frost[0].remaining<=3.5,"Frost presentation follows the original effect duration")
	var overlay=frost[0].parts[0].node;frost[0]._process(.1);check(overlay.modulate.a>.5,"Verified screen transparency fades from visible ice toward clear")
	var meshes=fx.frost[0].meshes
	game.take_damage(1,bot.position,{"attackerTeam":"red","sourceActor":bot});await frames()
	check(fx.frost.size()==1 and fx.group_instances(p,"lockedinice").size()==1,"Repeated ice hits refresh rather than stacking overlays")
	fx._process(4);check(fx.frost.is_empty() and meshes.all(func(row):return not is_instance_valid(row.mesh.get_ref()) or row.mesh.get_ref().material_overlay==row.previous),"Frost expiration restores the original materials")
	fx.clear();game.take_damage(1,bot.position,{"attackerTeam":"blue","sourceActor":bot});check(fx.frost.is_empty(),"Rejected friendly damage cannot create frost")
	game.source_hud.feedback.show_death();await frames(1);check(fx.group_instances(p,"Deathdirecting").size()==1,"Death uses the original screen texture and color curve")
	game.source_hud.feedback.reset();await frames();check(fx.group_instances(p,"Deathdirecting").is_empty(),"New life removes the source death overlay")
	game.show_home();game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames();p.set_physics_process(false)
	if p.is_wolf:p.switch_form(true)
	var sniper=game.book.weapons.filter(func(row):return row.category=="sniper" and row.get("available",false))[0];game.book.acquire(sniper.id);check(game.equip_library_weapon(sniper),"An actual imported sniper can be equipped")
	if p.weapon_anim.has_animation("select"):check(p.weapon_clip=="select" and p.weapon_action_time>0,"Equipping plays original Select instead of jumping to idle")
	Input.action_press("aim");check(p.is_scoped(),"Held aim opens the sniper scope")
	game.ammo=0;game.reload_weapon();check(game.reloading>0 and not p.is_scoped(),"Reload closes the scope to show original hands and magazine")
	p._physics_process(.2);check(is_equal_approx(p.camera.fov,74.0) and p.viewmodel.visible,"Reload restores the ordinary field of view and visible hands even with aim held")
	Input.action_release("aim");fx.clear();game.queue_free();await frames()
	var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-024-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));file.close()
	print("MOBILE_024_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
