extends SceneTree
const Rules=preload("res://scripts/bot_rules.gd")
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(count=3):
	for i in range(count):await physics_frame
func run():
	var mesh=NavigationMesh.new()
	mesh.vertices=PackedVector3Array([Vector3(0,0,0),Vector3(2,0,0),Vector3(2,0,2),Vector3(0,0,2),Vector3(2,0,0),Vector3(4,0,0),Vector3(4,0,2),Vector3(2,0,2),Vector3(10,0,0),Vector3(12,0,0),Vector3(12,0,2),Vector3(10,0,2)])
	for polygon in [[0,1,2,3],[4,5,6,7],[8,9,10,11]]:mesh.add_polygon(PackedInt32Array(polygon))
	var graph=load("res://scripts/navigation_graph.gd").new(mesh)
	check(graph.connected(Vector3(1,0,1),Vector3(3,0,1)),"Shared geometric edges connect even when vertex indices differ")
	check(not graph.connected(Vector3(1,0,1),Vector3(11,0,1)),"Disconnected islands are rejected before native corridor queries")
	var reachable_goal=graph.nearest_in_component(Vector3(1,0,1),Vector3(11,0,1))
	check(reachable_goal is Vector3 and reachable_goal.x<5,"Unreachable goal falls back inside the bot's actual component")
	check(graph.component(Vector3(1,5,1))==-1,"A point above a floor is not mistaken for that polygon")
	var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	game.start_round();game.set_process(false);game.player.set_physics_process(false)
	check(game.navigation_region.navigation_mesh.get_polygon_count()>0,"Training arena has real navigation too")
	var outcomes=[]
	for level in ["easy","normal","hard"]:
		game.player.position=Vector3(0,0.1,-7);game.player.velocity=Vector3.ZERO;game.health=100
		game.spawn_enemy("human",level)
		var bot=game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())[-1]
		bot.position=Vector3(0,0.1,0);bot.brain_enabled=false;bot.set_physics_process(false)
		await frames()
		check(bot.health==100 and bot.profile.skillRating>=80 and bot.profile.skillRating<=110,"Difficulty changes neither health nor the requested skill-rating bounds: "+level)
		check(bot.patrol_points.size()>0,"Bot knows reachable patrol points: "+level)
		check(is_instance_valid(bot.weapon) and bot.weapon.get_parent() is BoneAttachment3D,"Source rifle is attached to the actual hand: "+level)
		check(bot.anim.has_animation("reload") and bot.reload_sound.stream!=null,"Reload uses source body animation and sound: "+level)
		bot.profile.spread=0;bot.sees_player=true;bot.reaction=0;bot.attack_clock=0
		var fired=bot.fire();outcomes.append(100-game.health)
		check(fired and game.health==92 and bot.ammo==bot.capacity-1,"Real collision-tested shot has the same eight damage: "+level)
		check(not bot.fire(),"Fire interval cannot be bypassed: "+level)
		var wall=game.block(Vector3(0,1.5,-3.5),Vector3(5,3,0.25),"576371");await frames()
		bot.attack_clock=0;var ammo=bot.ammo
		check(not bot.can_see_player() and not bot.fire() and bot.ammo==ammo,"Wall blocks both sight and shooting: "+level)
		bot.last_known=Vector3(0,0.1,-7);bot.has_target=true;bot.memory=2
		game.player.position=Vector3(4,0.1,-7);bot.think()
		check(bot.last_known==Vector3(0,0.1,-7),"Hidden player movement is not known through a wall: "+level)
		bot.memory=0;bot.think();check(not bot.has_target,"Unseen target memory expires: "+level)
		bot.hear_noise(game.player.position,26);check(bot.has_target and bot.last_known==game.player.position,"An actually emitted nearby sound can be investigated: "+level)
		wall.queue_free();await frames()
		bot.ammo=0;bot.reserve=bot.capacity+7;check(bot.begin_reload(),"Empty magazine starts a real reload: "+level)
		game.menu_open=true;bot.set_physics_process(true);var remaining=bot.reload_remaining;await frames(25)
		check(bot.reload_remaining==remaining and bot.ammo==0,"Menu freezes reload and ammunition: "+level)
		game.menu_open=false;await frames(int(ceil(bot.reload_seconds*60))+4)
		bot.set_physics_process(false)
		check(bot.ammo==bot.capacity and bot.reserve==7 and bot.reloads_completed==1,"Reload transfers finite reserve exactly once: "+level)
		bot.ammo=0;bot.reserve=0;check(not bot.begin_reload(),"No unlimited refill without reserve: "+level)
		game.enemies.remove_child(bot);bot.queue_free();await frames()
	check(outcomes==[8,8,8],"All three levels have identical actual hit damage")
	for level in ["easy","normal","hard"]:
		game.player.position=Vector3(0,0.1,-1.5);game.health=100
		game.spawn_enemy("wolf",level);var wolf=game.enemies.get_child(0)
		wolf.brain_enabled=false;wolf.position=Vector3(0,0.1,0);wolf.state="attack";wolf.sees_player=true;wolf.reaction=0
		wolf.set_physics_process(false);wolf.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;wolf.source_events.set_process(false);await frames(3);wolf.begin_melee()
		var clip=wolf.active_clip;var record=game.clientfx.animation_record(wolf,clip);var keys=record.events.filter(func(e):return str(e.key).to_lower().contains("fire_key"))
		check(not keys.is_empty(),"Wolf melee resolves its source animation fire key: "+level)
		wolf.source_events.last_clip=clip;wolf.source_events.last_record=record
		var time=float(keys[0].timeMs)/1000
		wolf.source_events.dispatch_range(-.001,time-.001);check(game.health==100,"Wolf melee cannot hit before source fire key: "+level)
		wolf.source_events.dispatch_range(time-.001,time);check(game.health==92,"Wolf melee has the same damage at every level: "+level)
		game.enemies.remove_child(wolf);wolf.queue_free();await frames()
	game.player.position=Vector3(5,0.1,-9);game.health=100
	game.spawn_enemy("human","hard");var bot=game.enemies.get_child(0);bot.brain_enabled=false;bot.position=Vector3(5,0.1,-1.3);bot.last_known=game.player.position
	await frames(10)
	var cover=bot.find_cover()
	check(cover is Vector3 and bot.reachable(cover),"Cover candidate has a connected route around actual arena geometry")
	if cover is Vector3:
		var hit=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP*1.2,cover+Vector3.UP*1.2,1,[game.player.get_rid()]))
		check(not hit.is_empty(),"Chosen cover actually blocks the threat's line of sight")
	bot.position=Vector3(0,0.1,0);bot.state="patrol";bot.destination=Vector3(0,0.1,-8);await frames(12)
	check(bot.begin_dodge(Vector3.RIGHT),"Human bot performs a collision-checked roll on a supported route")
	var hp=bot.health;bot.damage(1);check(bot.health==hp-1,"Rolling does not grant damage immunity")
	await frames(40)
	check(not bot.rolling and bot.rolls_completed==1 and bot.body.transform.is_equal_approx(bot.body_base),"Roll ends and restores the source body transform")
	game.menu_open=true;var position_before=bot.position;await frames(20)
	check(bot.position==position_before,"Menu freezes bot locomotion")
	game.menu_open=false
	bot.position=Vector3(-2,0.1,0);bot.state="chase";bot.destination=Vector3(2,0.1,0)
	var stair=game.block(Vector3(0,0.10,0),Vector3(1,0.20,3),"576371")
	var highest=0.0
	for i in range(100):await physics_frame;highest=maxf(highest,bot.position.y)
	check(highest>0.18 and bot.position.x>0.8,"Bot actually traverses a small stair without walking through geometry")
	stair.queue_free()
	game.enemies.remove_child(bot);bot.queue_free();await frames()
	game.player.position=Vector3(0,0.1,-7)
	game.spawn_enemy("wolf","normal");bot=game.enemies.get_child(0);bot.brain_enabled=false;bot.position=Vector3(0,0.1,0);bot.has_target=true;bot.destination=game.player.position;bot.state="chase"
	await frames(15)
	check(Vector2(bot.velocity.x,bot.velocity.z).length()>4.5,"Alert bot actually runs along navigation")
	game.queue_free();await frames()
	var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/bot-validation.json"),FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"actualShotDamageByDifficulty":outcomes,"profileRatings":[80,95,110],"physicalAndroidDeviceTested":false,"originalPcBotImplementation":false},"  ")+"\n");file.close()
	print("BOT_BEHAVIOUR_QA ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
