extends SceneTree
var game
var checks=0
var failures=[]
func ensure(v,label):
	checks+=1
	if not v:failures.append(label);push_error(label)
func frames(n=4):
	for i in range(n):await process_frame
func _initialize():call_deferred("run")
func run():
	game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	var data=game.game_audio.gameplay_sources();ensure(data.voiceRows==791 and data.missingVoices.is_empty(),"All 791 exact human/wolf voice rows have original available audio")
	ensure(game.clientfx.catalog.sourceGroupCount==628 and game.clientfx.catalog.projectiles.size()==4 and game.clientfx.catalog.models.size()>=93,"Full ClientFX catalogue and original FX meshes load")
	for char in game.book.characters:
		for form in ["human","wolf"]:
			var binding=game.clientfx.catalog.characters[char.id][form]
			for effect in binding.effects.values():ensure(game.clientfx.catalog.groups.has(effect) and game.clientfx.catalog.groups[effect].available,"Every bound character effect is complete: "+char.id+"/"+effect)
	game.local_room={"mode":0,"map":0,"team":"red","allyBots":0,"enemyBots":0};game.book.choose_character("pair-model48");game.start_round();game.spawn_clock=10000
	if not game.player.is_wolf:game.player.switch_form(true)
	await frames(24);game.player.action_time=0;game.player.roar_effect.cooldown=0
	ensure(game.player.begin_roar(),"Source fire-wolf roar begins")
	await frames(28)
	ensure(game.clientfx.group_instances(game.player,"Howling_Fire_1").is_empty(),"Howling waits for the actual source event at 933ms")
	await frames(36)
	ensure(not game.clientfx.group_instances(game.player,"Howling_Fire_1").is_empty(),"Source Howling starts at its animation key")
	ensure(game.game_audio.event_history.any(func(r):return r.key.contains("cryice")),"Roar uses model-specific source voice table rather than a generic WAV")
	var transform=game.clientfx.socket_transform(game.player,"cry");ensure(transform.origin.is_finite() and transform.origin.distance_to(game.player.global_position)<4,"Named source socket binds inside actual character bounds")
	var smoke=game.clientfx.play("Cage_smoke",null,game.player.position+Vector3(0,1,-3),true)
	await frames(2)
	ensure(smoke.parts.any(func(p):return p.node is CPUParticles3D and p.node.lifetime==55 and p.node.preprocess>0),"World smoke keeps source lifetime and warms its existing particles")
	ensure(smoke.parts.all(func(p):return not p.node is CPUParticles3D or p.node.visibility_aabb.has_point(Vector3(35,0,0))),"Smoke visibility bounds include its source emission radius")
	game.menu_open=true;await frames();ensure(game.clientfx.active.is_empty(),"Pause removes all effects and camera shake")
	game.menu_open=false;game.player.roar_effect.stop();await frames(4)
	game.player.reset_combat();await frames(65)
	ensure(game.player.is_on_floor() and game.player.position.y> -1,"Red training spawn is clear of the central pillar and stays grounded")
	ensure(game.clientfx.install_strong(game.player),"Actual UMFi3 strong claw loads without modifying admitted character GLBs")
	ensure(game.strong_attack(),"Grounded strong-claw action uses its original animation")
	await frames(15)
	ensure(not game.clientfx.group_instances(game.player,"Fireball_SE").is_empty(),"Source ProjectileFX alias creates the correct attached hand effect")
	var skeleton=game.player.wolf.find_children("*","Skeleton3D",true,false)[0]
	ensure(range(skeleton.get_bone_count()).all(func(i):return skeleton.get_bone_global_pose(i).origin.is_finite()),"Strong claw source tracks keep finite live skeleton transforms")
	await frames(50);game.clientfx.clear();await frames(4)
	for kind in game.clientfx.catalog.typeCounts:
		var chosen=""
		for name in game.clientfx.catalog.groups:
			var spec=game.clientfx.catalog.groups[name]
			if spec.available and spec.nodes.any(func(n):return n.type==kind):chosen=name;break
		ensure(chosen!="","A complete source group exercises renderer type "+kind)
		if chosen!="":
			var fx=game.clientfx.play(chosen,game.player);await frames(1);ensure(is_instance_valid(fx) or float(game.clientfx.catalog.groups[chosen].nodes[0].end)<=0.02,"Source renderer constructs "+kind);game.clientfx.clear();await frames()
	for mode in [1000,1001,1010,1020,1021]:
		var maps=game.map_catalog.maps_for_mode(mode).filter(func(m):return not game.map_catalog.offline_record(m.number).is_empty())
		ensure(not maps.is_empty(),"Original mode has its own source-linked ready maps: "+str(mode))
		game.local_room={"mode":mode,"map":maps[0].number,"team":"blue","pointGoal":40,"matchSeconds":1200,"allyBots":0,"enemyBots":0}
		ensure(game.start_round(),"Source deathmatch starts: "+str(mode));game.spawn_clock=10000
		ensure(game.target_score()==40 and game.time_left==1200,"Original score/time options replace training defaults")
		if mode in [1020,1021]:
			ensure(not game.player.is_wolf,"Human-only source mode forces human form");game.player.switch_form();ensure(not game.player.is_wolf,"Human-only source mode blocks transformation")
		if mode==1010:ensure(game.player.is_wolf,"Wolf-only source mode forces wolf form")
		game.take_damage(10000,null,{"attackerTeam":"red"});ensure(game.running and game.respawn_remaining==3,"Source deathmatch respawns even with zero allied bots");game._process(3.1)
		ensure(game.health>0 and game.deaths==1,"Respawn restores health while retaining the match score")
		game.kills=39;game.enemy_defeated();ensure(not game.running and game.last_result.winner=="blue" and game.last_result.victory,"Source point limit selects actual winning team")
	var mode=1000;var map=game.map_catalog.maps_for_mode(mode).filter(func(m):return not game.map_catalog.offline_record(m.number).is_empty())[0]
	game.local_room={"mode":mode,"map":map.number,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000;game.kills=3;game.time_left=.01;game._process(.02)
	ensure(game.last_result.winner=="blue" and game.last_result.victory,"Time limit uses team scores to choose the winner")
	ensure(game.game_audio.event_history[-1].allowMenu and game.game_audio.event_history[-1].key.ends_with("msg_round_blue_win.wav"),"Winning announcement continues on the result screen instead of being paused with world sounds")
	game.start_round();game.spawn_clock=10000;game.time_left=.01;game._process(.02);ensure(game.last_result.winner=="draw" and not game.last_result.victory,"A tied timeout is a draw and never a victory")
	game.local_room={"mode":1000,"map":map.number,"pointGoal":99999,"matchSeconds":1};game.start_round();game.spawn_clock=10000;ensure(game.target_score()==100 and game.time_left==600,"Unknown options fall back to exact source defaults")
	game.queue_free();await frames()
	var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/clientfx-gameplay-017-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  ")+"\n");f.close();print("CLIENTFX_GAMEPLAY_017_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
