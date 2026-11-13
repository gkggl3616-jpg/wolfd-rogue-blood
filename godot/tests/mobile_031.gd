extends SceneTree
var game
var checks=0
var failures=[]
var trace=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func frames(n=3):
 for i in range(n):await process_frame
func physics(n=3):
 for i in range(n):await physics_frame
func tap(point,index=0):
 var e=InputEventScreenTouch.new();e.index=index;e.position=root.get_final_transform()*point;e.pressed=true;Input.parse_input_event(e);await frames(2)
 e=InputEventScreenTouch.new();e.index=index;e.position=root.get_final_transform()*point;e.pressed=false;Input.parse_input_event(e);await frames(3)
func clear_bots():
 for bot in game.enemies.get_children():game.enemies.remove_child(bot);bot.queue_free()
 await physics()
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(960,540)]:
  root.size=size;game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};check(game.start_round(true),"Wolf selection starts "+str(size));await frames(4)
  check(game.match_sp==0 and not game.selection_panel.card_buttons[0].disabled and game.round_mutation_cost("normal")==0,"Zero-SP default wolf can be confirmed "+str(size))
  await tap(game.selection_panel.card_buttons[0].get_global_rect().get_center())
  check(not game.selection_active and game.player.is_wolf and game.health==240 and game.max_health()==240,"Actual native touchscreen selects 240HP normal wolf "+str(size))
 game.match_sp=1500;game.open_round_selection("wolf");await frames();await tap(game.selection_panel.card_buttons[1].get_global_rect().get_center())
 check(game.player.mutation_id=="power" and game.match_sp==1250 and game.max_health()==270,"Paid mutation uses displayed SP and explicit offline HP delta")
 game.open_round_selection("wolf");await frames();await tap(game.selection_panel.card_buttons[1].get_global_rect().get_center())
 check(game.match_sp==1250 and not game.selection_active,"Confirming the equipped mutation cannot charge twice")
 var p=game.player;game.match_flow.signal_start();p.switch_form(true);game.health=100;game.take_damage(25);p.switch_form(true)
 check(game.max_health()==270 and absf(float(game.health)/game.max_health()-.75)<.01,"Human 100HP and wolf form preserve damage fraction")
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.match_flow.advance_match(2)
 if not p.is_wolf:p.switch_form(true)
 p.set_physics_process(true);p.position=Vector3(50,.05,0);p.velocity=Vector3.ZERO
 var floor=game.block(Vector3(50,-.05,0),Vector3(16,.1,8),"576371");await physics(10)
 Input.action_press("crouch");await physics(5);Input.action_release("crouch");await physics(12)
 check(not p.crouching and is_equal_approx(p.capsule.height,1.8),"Releasing crouch restores upright capsule above actual supporting geometry")
 Input.action_press("crouch");await physics(5);var roof=game.block(Vector3(50,1.48,0),Vector3(5,.2,5),"576371");await physics(3);Input.action_release("crouch");await physics(8)
 check(p.crouching,"A real low ceiling still blocks standing")
 roof.queue_free();await physics(12);check(not p.crouching,"Removing the ceiling clears crouch without another button press")
 p.position=Vector3(46,.03,0);p.rotation.y=0;p.yaw=0;p.velocity=Vector3.ZERO;var step=game.block(Vector3(49,.12,0),Vector3(1.5,.24,3),"576371");await physics(5)
 Input.action_press("right");var highest=0.0
 for i in range(70):await physics_frame;highest=maxf(highest,p.position.y)
 Input.action_release("right");check(highest>.23 and p.position.x>50.3 and not p.crouching,"Running wolf physically crosses a small curb upright")
 step.queue_free();p.position=Vector3(49,.03,0);p.velocity=Vector3.ZERO;await physics(5);check(p.begin_roll(),"Grounded source roll starts");await physics(80)
 check(not p.rolling and not p.crouching and p.capsule.height>1.7,"Completed roll cannot leave normal running stuck in crouch")
 Input.action_press("forward");await physics(10)
 check(p.current_clip=="run" and p.anim.get_meta("native_wolf_pose_run","")=="run","Actual running uses combined native upper/lower tracks")
 Input.action_release("forward");p.set_physics_process(false);floor.queue_free();await physics()
 for kind in ["human","wolf"]:
  for difficulty in ["easy","normal","hard"]:
   check(game.spawn_enemy(kind,difficulty,"red"),"Spawn HP fixture "+kind+difficulty);await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false)
   check(bot.health==(240 if kind=="wolf" else 100),"Equal form-correct HP at every difficulty "+kind+difficulty);await clear_bots()
 p.position=Vector3(-14,.1,14);game.health=1000
 for team in ["blue","blue","red"]:game.spawn_enemy("human","normal",team)
 await physics(5);var a=game.enemies.get_child(0);var b=game.enemies.get_child(1);var target=game.enemies.get_child(2)
 for bot in [a,b,target]:bot.set_physics_process(false)
 a.position=Vector3(-15,.1,5);a.rotation.y=0;b.position=Vector3(15,.1,5);b.rotation.y=0;target.position=Vector3(-15,.1,-6);var wall=game.block(Vector3(0,1.2,0),Vector3(8,2.4,.5),"576371");await physics(3)
 a.opponent=target;b.opponent=target;check(a.can_see_player() and not b.can_see_player(),"Squad fixture has one witness and an occluded teammate")
 a.think();b.has_target=false;b.memory=0;b.think()
 check(b.has_target and b.last_known==target.position and b.tactics.reports_received>0,"Occluded teammate receives an actual witnessed contact")
 var seen=b.last_known;target.position.x+=1;await physics(2);b.think();check(b.last_known==seen and b.last_known!=target.position,"Shared report cannot track unseen target motion")
 var ga=a.tactics.approach(seen);var gb=b.tactics.approach(seen)
 check(ga is Vector3 and gb is Vector3 and ga.distance_to(gb)>=1.6,"Coordinated approach reserves distinct connected goals")
 if ga is Vector3:check(not game.bot_squads.reserve(b,ga,"conflict"),"An ally cannot reserve the same cover/approach slot")
 if gb is Vector3:
  var before_radius=gb.distance_to(seen);a.attack_clock=0;a.reaction=0;a.sees_player=a.can_see_player();var fired=a.fire();var push=b.tactics.approach(seen)
  check(fired and game.bot_squads.covering_fire(b) and push is Vector3 and push.distance_to(seen)<before_radius-1,"Actual allied covering fire changes the flanker's advance distance")
 wall.queue_free();await physics(3);a.position=Vector3(5,.1,-1.3);a.rotation.y=0;target.position=Vector3(5,.1,-9);target.health=10000;a.opponent=target;a.last_known=target.position;a.has_target=true;a.memory=20;a.tactics.under_fire=2;await physics(3)
 check(a.tactics.begin_cover(),"Damaged human bot finds connected, physically occluded cover")
 var minimum=INF;var held=0;var shots=a.shots_fired;a.set_physics_process(true)
 for i in range(720):
  await physics_frame
  if not is_instance_valid(a):break
  minimum=minf(minimum,a.global_position.distance_to(a.tactics.cover_anchor))
  if a.state=="cover_hold":held+=1
  if i%30==0:trace.append({"tick":i,"position":[a.position.x,a.position.y,a.position.z],"state":a.state,"phase":a.tactics.cover_phase,"shots":a.shots_fired})
 a.set_physics_process(false)
 check(minimum<1.1 and held>=10,"Bot actually reaches and holds cover, rather than only naming a cover state")
 check(a.tactics.peeks>0 and a.shots_fired>shots,"Bot leaves cover through a clear firing lane and actually shoots")
 check(a.tactics.cover_cycles>0,"A short firing peek returns to cover")
 await clear_bots();game.show_maps()
 for i in range(game.mode_picker.item_count):
  if game.mode_picker.get_item_id(i)==1000:game.mode_picker.select(i)
 game.refresh_mode_maps()
 for i in range(game.map_picker.item_count):
  if game.map_picker.get_item_id(i)==84:game.map_picker.select(i)
 game.refresh_map_status();game.start_map_preview();check(game.health==game.max_health(),"Source-map exploration displays the correct current form HP")
 game.queue_free();await frames()
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-031-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"coverTrace":trace,"humanBaseHp":100,"normalWolfBaseHp":240,"physicalAndroidDeviceTested":false},"  ")+"\n");f.close();print("MOBILE_031_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
