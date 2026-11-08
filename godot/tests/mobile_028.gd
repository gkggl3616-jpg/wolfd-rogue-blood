extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=2):
 for _i in range(n):await process_frame
func item(name):return game.book.weapons.filter(func(r):return r.name==name)[0]
func equip(name):
 var selected=item(name);game.book.acquire(selected.id);check(game.equip_library_weapon(selected),"Equip native fixture "+name);return selected
func projectiles():return game.get_children().filter(func(n):return n.get_script()==load("res://scripts/grenade.gd") and not n.is_queued_for_deletion())
func physics(n=2):
 for _i in range(n):await physics_frame
 await process_frame
func native_projectile(name,position,velocity):
 var row=game.book.weapons.filter(func(r):return game.player.native_weapon_rules[r.id].projectile==name)[0]
 var p=game.launch_projectile(game.player.native_weapon_rules[row.id],row.name);p.position=position;p.velocity=velocity;return p
func wall(position,size):
 var body=StaticBody3D.new();body.position=position;body.collision_layer=1;var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size;shape.shape=box;body.add_child(shape);game.add_child(body);return body
func projectile_physics():
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":1,"enemyBots":0};game.start_round();await frames();game.player.set_physics_process(false);game.match_flow.advance_match(2)
 if game.player.is_wolf:game.player.switch_form(true)
 game.player.position=Vector3(1000,10,10);game.player.guard_remaining=0
 game.spawn_enemy("human","normal","red");game.spawn_enemy("human","normal","blue");await frames()
 var targets=game.enemies.get_children().filter(func(n):return not n.is_queued_for_deletion());var enemy=targets.filter(func(n):return n.team=="red")[0];var ally=targets.filter(func(n):return n.team=="blue")[0]
 for actor in targets:actor.set_physics_process(false);actor.health=2000
 enemy.position=Vector3(1000,10,0);ally.position=Vector3(1001,10,0);await physics()
 var barrier=wall(Vector3(1000,11,2),Vector3(8,4,.1));await physics()
 var arrow=native_projectile("Arrow",Vector3(1000,11,4),Vector3(0,0,-320));await physics(3)
 check(is_instance_valid(arrow) and arrow.stuck and arrow.position.z>2 and enemy.health==2000,"Swept320m/s arrow collides with a10cm wall instead of tunneling to the target")
 game.clear_projectiles();await frames()
 var rocket=native_projectile("Missile",Vector3(1000,11,4),Vector3(0,0,-320));var rocket_ref=weakref(rocket);await physics(3)
 check(not is_instance_valid(rocket_ref.get_ref()),"A swept contact rocket detonates and frees exactly once on the wall")
 check(enemy.health==2000 and ally.health==2000,"Real world geometry blocks explosion damage while allies remain excluded")
 barrier.queue_free();await physics()
 arrow=native_projectile("Arrow",Vector3(1000,11,4),Vector3(0,0,-320));await physics(3)
 check(is_instance_valid(arrow) and arrow.stuck and enemy.health<2000,"High-speed arrows hit the actual actor capsule and retain their stuck model")
 if is_instance_valid(arrow):
  var before=arrow.global_position;enemy.position.x+=1;await physics();check(arrow.global_position.distance_to(before+Vector3.RIGHT)<.01,"A stuck arrow follows the moving actor without inheriting its parent lifetime")
 game.clear_projectiles();await frames();enemy.position=Vector3(1000,10,0);await physics();var hp=enemy.health;var ally_hp=ally.health
 var grenade=native_projectile("HGrenadeTimed",Vector3(1000,11,1),Vector3.ZERO);grenade.gravity=0;grenade.fuse=.05;await physics(6)
 check(enemy.health<hp and ally.health==ally_hp,"A native timed explosion damages an exposed enemy and preserves allied health")
 game.clear_projectiles();await frames()
 grenade=native_projectile("HGrenadeTimed",Vector3(1000,14,4),Vector3(1,0,0));grenade.fuse=1;await physics();var age=grenade.age;var point=grenade.position
 game.menu_open=true;await physics(4);check(is_equal_approx(grenade.age,age) and grenade.position==point,"Menu pause freezes both flight and native fuse")
 game.menu_open=false;game.application_suspended=true;await physics(4);check(is_equal_approx(grenade.age,age) and grenade.position==point,"Application suspension freezes flight and fuse independently")
 game.application_suspended=false;game.health=0;await physics(4);check(grenade.age>age and grenade.position!=point,"A projectile already in flight continues after player death while the match is active")
 game.health=100;game.clear_projectiles();await frames()
 var floor_body=wall(Vector3(1000,9.9,0),Vector3(20,.2,20));enemy.position=Vector3(1010,10,0);ally.position=Vector3(1000,10,0);await physics()
 var mine=native_projectile("Mine",Vector3(1000,10.5,0),Vector3(0,-2,0));await physics(40)
 check(is_instance_valid(mine) and mine.stuck and not mine.detonated,"An armed native mine rests on a real floor and ignores a nearby ally")
 var mine_ref=weakref(mine);enemy.position=Vector3(1000,10,0);await physics(4);check(not is_instance_valid(mine_ref.get_ref()),"Native enemy-detection radius triggers a mine when a hostile capsule enters")
 game.clear_projectiles();await frames();enemy.health=2000;enemy.position=Vector3(1000,10,0);ally.position=Vector3(1005,10,0);await physics()
 var sticky=native_projectile("ATGrenadeTimed2",Vector3(1000,11,2),Vector3(0,0,-28.8));await physics(6)
 check(is_instance_valid(sticky) and sticky.stuck,"Native attach grenade sticks on a real actor collision")
 if is_instance_valid(sticky):
  var before=sticky.position;enemy.position.x+=1;await physics();check(sticky.position.distance_to(before+Vector3.RIGHT)<.01,"An attached grenade follows the struck actor")
 game.clear_projectiles();await frames();enemy.position=Vector3(1000,10,0);game.player.position=Vector3(1000,10,2);await physics()
 var native=game.player.native_weapon_rules[game.book.weapons.filter(func(r):return game.player.native_weapon_rules[r.id].projectile=="HGrenadeTimed")[0].id]
 grenade=game.launch_projectile(native,"MK-5 G",enemy,Vector3.FORWARD);grenade.position=Vector3(1000,11,2);grenade.velocity=Vector3.ZERO;grenade.gravity=0;grenade.fuse=.1;var original_owner=grenade.owner_name;enemy.queue_free();await physics(10)
 check(game.health<100 and original_owner!="","A freed bot owner retains its team/name and its airborne grenade still damages the player")
 game.clear_projectiles();await frames();game.health=100;game.respawn_remaining=0;game.spawn_enemy("human","normal","red");await frames();var posthumous_target=game.enemies.get_children().filter(func(n):return n.team=="red" and not n.is_queued_for_deletion())[0];posthumous_target.set_physics_process(false);posthumous_target.position=Vector3(1000,10,0);posthumous_target.health=1;await physics();var kills=game.kills
 grenade=native_projectile("HGrenadeTimed",Vector3(1000,11,1),Vector3.ZERO);grenade.gravity=0;grenade.fuse=.05;game.health=0;await physics(6)
 check(game.kills==kills+1,"A player's already released grenade awards its posthumous elimination while the match continues")
 game.health=100;game.clear_projectiles();await frames();var energy=native_projectile("FullMoon",Vector3(1000,12,4),Vector3.ZERO);energy.set_physics_process(false);await frames(4)
 check(is_instance_valid(energy.trail) and energy.trail.parts.any(func(part):return part.node is MeshInstance3D and part.node.visible and part.node.material_override.albedo_color.a>.1),"Native energy-bullet sprites remain visible when the source Ck transparency is zero")
 check(energy.trail.parts.filter(func(part):return part.node is CPUParticles3D).all(func(part):return not part.node.local_coords),"Flying energy particles retain world coordinates instead of moving old trail samples with the projectile")
 game.clear_projectiles();floor_body.queue_free();await frames()
func _initialize():call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(4);game.player.set_physics_process(false)
 if game.player.is_wolf:game.player.switch_form(true)
 var rules=game.player.native_weapon_rules
 check(rules.size()==903,"All903 native combat/view records are present")
 for row in game.book.weapons:
  game.book.acquire(row.id);check(game.equip_library_weapon(row),"Actual native weapon equip "+row.id);await frames(1)
  var info=game.player.weapon_info;var native=rules[row.id]
  check(info.shotsPerClip==native.capacity and is_equal_approx(info.fireIntervalMs,native.fireIntervalMs),"Native capacity and cadence reach gameplay "+row.id)
  var position=native.godotPosition;check(game.player.viewmodel.position.is_equal_approx(Vector3(position[0],position[1],position[2])),"Native camera position reaches the actual imported model "+row.id)
 var fixtures={"DE-50":[7,200,82],"AKEI-47 CLASSIC":[30,106,66],"FullMoon":[45,280,80],"SUPAS PT":[8,1200,44]}
 for name in fixtures:
  equip(name);var expected=fixtures[name];check(game.weapon_capacity()==expected[0] and game.player.weapon_info.fireIntervalMs==expected[1] and game.player.weapon_info.damage==expected[2],"Independent decoded source fixture "+name)
 var grenade_models={}
 for row in game.book.weapons:
  if row.category=="grenade" and not grenade_models.has(row.model):grenade_models[row.model]=row
 for model in grenade_models:
  var row=grenade_models[model];game.equip_library_weapon(row);await frames(1)
  check(game.player.weapon_anim.has_animation("prefire") and game.player.weapon_anim.has_animation("postfire"),"Both original throw clips install "+model)
  check(game.player.weapon_motion.throw_release_time()>=.06 and game.player.weapon_motion.throw_release_time()<=.134,"Original fire_key timing resolves despite source clip casing "+model)
  for clip in ["prefire","postfire"]:
   game.player.play_weapon_clip(clip,.5);game.player.weapon_anim.seek(.2,true)
   var skeleton=game.player.viewmodel.find_children("*","Skeleton3D",true,false)[0]
   check(skeleton.get_bone_global_pose(skeleton.get_bone_count()-1).is_finite(),"Native throw pose has finite bone transforms "+model+clip)
 check(grenade_models.size()==31,"All31 grenade viewmodels receive original throw animation admission")
 equip("MK-5 G");game.ammo=1;game.player.shot_cooldown=0;game.reloading=0;var attacks=game.match_stats.attacks;game.attack()
 check(not game.pending_throw.is_empty() and game.ammo==1 and game.match_stats.attacks==attacks,"Preparing a grenade reserves no ammo or completed attack before release")
 var pre=game.pending_throw.preSeconds;var release=game.pending_throw.releaseAt
 game.advance_pending_throw(pre+release-.001);check(projectiles().is_empty() and game.ammo==1,"A grenade cannot leave the hand before its original postfire key")
 game.menu_open=true;var elapsed=game.pending_throw.elapsed;game.advance_pending_throw(2);check(game.pending_throw.elapsed==elapsed,"Menu pauses a pending native throw")
 game.menu_open=false;game.advance_pending_throw(.0011);check(projectiles().size()==1 and game.ammo==0 and game.match_stats.attacks==attacks+1,"Exactly one projectile and round appear at the native throw release")
 var grenade=projectiles()[0];grenade.set_physics_process(false)
 check(is_equal_approx(grenade.velocity.length(),28.8) and is_equal_approx(grenade.gravity,-8) and is_equal_approx(grenade.fuse,1.5),"MK-5G uses source velocity1800, gravity-500 and lifetime1.5 in world units")
 check(grenade.definition.availableModel and grenade.visual!=null,"Thrown grenade uses its real source model and skin")
 game.clear_projectiles();await frames();equip("MK-5 G");game.ammo=1;game.player.shot_cooldown=0;game.attack();equip("AKEI-47 CLASSIC");game.advance_pending_throw(1);check(game.pending_throw.is_empty() and projectiles().is_empty(),"Switching weapons cancels an unreleased throw")
 equip("MK-5 G");check(game.ammo==1,"A canceled grenade throw preserves its original inventory round")
 equip("AKEI-47 CLASSIC");game.ammo=0;game.reserve=90;game.reloading=0;game.player.weapon_motion.event_history.clear();game.game_audio.event_history.clear();game.reload_weapon()
 check(is_equal_approx(game.reloading,2.5),"AK reload duration uses the original2.5s imported animation")
 game.player.weapon_motion.advance(.332);check(game.player.weapon_motion.event_history.is_empty(),"Native first reload sound is not played early")
 game.player.weapon_motion.advance(.001);game.player.weapon_motion.advance(.933);game.player.weapon_motion.advance(.567)
 check(game.player.weapon_motion.event_history.map(func(e):return e.key)==[1,2,3],"The three actual AK reload events follow original333/1266/1833ms keys")
 check(game.game_audio.event_history.size()==3 and game.game_audio.event_history[1].key.ends_with("akei47_reload2.wav"),"Original sound events reach the real sound routing bank")
 game.reloading=0;game.spawn_enemy("human","normal","red");await frames();var target=game.enemies.get_child(0);target.set_physics_process(false);target.health=2000;target.position=game.player.position+Vector3(0,0,-3);game.player.camera.look_at(target.position+Vector3.UP);await physics_frame;await physics_frame
 equip("SUPAS PT");game.ammo=8;game.player.shot_cooldown=0;var hits=game.match_stats.hits;var hp=target.health;game.attack()
 check(game.player.weapon_info.pellets==6 and hp-target.health==264,"Six original SUPAS pellets each hit a real collider for44 base damage")
 check(game.match_stats.hits==hits+1 and game.ammo==7,"A multi-pellet attack spends one cartridge and counts one successful attack")
 target.queue_free();await frames();game.clear_projectiles()
 check(game.projectile_catalog.projectiles.size()==72 and game.projectile_catalog.models.size()==66,"All72 native projectile definitions and66 distinct flight models are packaged")
 var class_seen={}
 for name in game.projectile_catalog.projectiles:
  var definition=game.projectile_catalog.projectiles[name];var selected=game.book.weapons.filter(func(r):return rules[r.id].projectile==name)[0];game.equip_library_weapon(selected);var projectile=game.launch_projectile(rules[selected.id],selected.name);projectile.position=Vector3(1000,10,0);projectile.set_physics_process(false)
  check(projectile.definition.availableModel and projectile.projectile_class==definition.properties.Class,"Actual flight model/class instantiates "+name)
  check(is_equal_approx(projectile.fuse,maxf(.01,float(definition.properties.Lifetime))),"Native flight lifetime is retained "+name)
  class_seen[projectile.projectile_class]=true;projectile.queue_free();await frames(1)
 check(class_seen.size()==10,"Every referenced native projectile class has an engine instantiation case")
 # Native clip-based shell loading and independent weapon cooldown state.
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames();game.player.set_physics_process(false)
 if game.player.is_wolf:game.player.switch_form(true)
 equip("SUPAS PT");game.ammo=3;game.reserve=5;game.reloading=0;game.reload_weapon();check(game.player.weapon_info.reloadPerShell,"SUPAS uses its verified insertion/finish clip pair")
 game.advance_reload(.667);check(game.ammo==4 and game.reserve==4 and game.reloading>0,"The first original insertion adds only one shell")
 game.attack();game.advance_reload(.667);check(game.ammo==5 and game.shell_reload.phase=="finish","Fire requests interrupt shell loading after the current insertion")
 game.advance_reload(1);check(game.reloading==0 and game.shell_reload.is_empty() and game.ammo==5,"The original finishing clip completes without filling the rest of the tube")
 equip("I-115 GL");game.player.shot_cooldown=1.75;equip("DE-50");check(game.player.shot_cooldown==0,"Switching away from a slow weapon does not borrow its cooldown")
 equip("I-115 GL");check(is_equal_approx(game.player.shot_cooldown,1.75),"Switching back cannot bypass that weapon's existing cooldown")
 var permitted={1022:["knife","grenade"],1023:["knife"],1024:["knife","pistol","grenade"],1025:["knife","pistol","sniper","grenade"],1026:["knife","heavy","rocket","launcher","minigun","grenade"]}
 for mode in permitted:
  var maps=game.map_catalog.maps_for_mode(mode,true);check(not maps.is_empty(),"New source weapon mode has an admitted map "+str(mode));game.local_room={"mode":mode,"map":int(maps[0].number),"team":"blue","allyBots":0,"enemyBots":0};game.source_hud.refresh_from_game();check(game.start_round(),"Real source weapon mode starts "+str(mode));await frames();game.player.set_physics_process(false)
  game.source_hud.refresh_from_game();check(game.source_hud.score_view.find_widget("Mode").text==game.match_rules.title()+"   "+str(game.target_score())+" Puan","Source mode title refreshes even after another mode used the same map "+str(mode))
  check(not game.player.is_wolf and game.weapon_allowed_item(game.book.weapon(game.current_weapon_id)),"Source human lock and allowed initial equipment are enforced "+str(mode))
  for category in ["knife","pistol","rifle","smg","sniper","shotgun","machinegun","heavy","rocket","launcher","minigun","grenade"]:check(game.match_rules.weapon_allowed(category)==(category in permitted[mode]),"Independent native slot-mask fixture "+str(mode)+"/"+category)
  check(game.spawn_enemy("human","normal","red"),"Mode bot spawns "+str(mode));await frames();var bot=game.enemies.get_children().filter(func(n):return not n.is_queued_for_deletion())[0];bot.set_physics_process(false);check(bot.weapon_data.category==game.match_rules.preferred_categories()[0] and is_instance_valid(bot.weapon),"Bot carries the original third-person weapon allowed by its source mode "+str(mode))
  game.running=false
 await projectile_physics()
 game.queue_free();await frames()
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-028-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"nativeWeaponsEquipped":903,"grenadeViewmodels":grenade_models.size(),"projectileDefinitionsExercised":72,"projectileClassesExercised":class_seen.size(),"apkProduced":false},"  ")+"\n");file.close();print("MOBILE_028_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
