extends SceneTree
var game
var output
var captures=[]
var failures=[]
var observer
var movie_frames="/dev/shm/wolf031-squad-frames"
var squad_trace=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for i in range(n):await process_frame
func physics(n=5):
 for i in range(n):await physics_frame
func capture(name,settle=4):
 game.source_hud.refresh_from_game();await frames(settle);await RenderingServer.frame_post_draw
 var im=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":im.get_width(),"height":im.get_height(),"saved":im.save_png(path)==OK})
func tap(button):
 var point=root.get_final_transform()*button.get_global_rect().get_center();var e=InputEventScreenTouch.new();e.index=0;e.position=point;e.pressed=true;Input.parse_input_event(e);await frames(2);e=InputEventScreenTouch.new();e.index=0;e.position=point;e.pressed=false;Input.parse_input_event(e);await frames(3)
func pose(clip,phase=.2):
 var p=game.player;p.set_physics_process(false);p.source_events.set_process(false);p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.play_clip(clip);p.anim.play(clip,0);p.anim.seek(phase,true);p.anim.advance(0)
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round(true);await frames(5);await capture("zero-sp-normal-wolf-enabled-031")
 await tap(game.selection_panel.card_buttons[0]);if game.selection_active:failures.append("Actual touch did not select default wolf")
 game.match_flow.signal_start();game.match_flow.start_flash=0;game.health=game.max_health();var p=game.player;await capture("normal-wolf-240hp-touch-confirmed-031")
 game.match_sp=1500;game.open_round_selection("wolf");await frames();await capture("wolf-selection-paid-variants-and-current-confirm-031")
 await tap(game.selection_panel.card_buttons[2]);await capture("guardian-320hp-local-delta-031")
 game.open_round_selection("wolf");game.choose_round_mutation("ghost");await frames();await capture("ghost-source-body-225hp-031");p.begin_cloak();await capture("ghost-stationary-source-cloak-031");p.cancel_cloak()
 p.begin_roar();await capture("ghost-native-howl-031",30);p.roar_effect.stop();p.action_time=0
 game.open_round_selection("wolf");game.choose_round_mutation("normal");p.switch_form(true);game.health=game.max_health();await capture("human-base-100hp-031");p.switch_form(true);game.health=game.max_health()
 p.position=Vector3(0,.02,8);p.rotation.y=0;p.yaw=0;p.velocity=Vector3.ZERO;p.set_physics_process(true);await physics(6)
 Input.action_press("forward");await physics(18);await capture("actual-run-native-upper-lower-upright-031");Input.action_release("forward");await physics(5)
 Input.action_press("crouch");await physics(7);await capture("deliberate-crouch-distinct-from-run-031");Input.action_release("crouch");await physics(14);await capture("released-crouch-restores-standing-031")
 Input.action_press("forward");p.begin_roll();await capture("source-roll-start-031",6);await capture("source-roll-moving-031",12);Input.action_release("forward");await physics(65);await capture("roll-completed-upright-031")
 observer=Camera3D.new();game.add_child(observer);observer.position=p.position+Vector3(4,2.5,5);observer.look_at(p.position+Vector3.UP);observer.current=true;p.set_physics_process(false)
 for clip in ["idle","run","crouch_run"]:
  p.crouching=clip=="crouch_run";pose(clip,.2);await capture("native-layered-"+clip+"-031")
 p.crouching=true
 for clip in ["attack","attack_right"]:
  pose(clip,0);p.claw_trail.set_process(false);p.claw_trail.begin();p.claw_trail.source_window(1 if clip=="attack" else 0,true)
  for i in range(7):p.anim.seek(.05+i*.025,true);p.anim.advance(0);await frames(1);p.claw_trail._process(.016)
  await capture("crouched-native-"+clip+"-claw-031");p.claw_trail.clear()
 p.claw_trail.set_process(true);p.crouching=false;p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE;p.source_events.set_process(true);p.action_time=0;p.capsule.height=1.8;p.body_shape.position.y=.9
 var floor=game.block(Vector3(50,-.05,0),Vector3(16,.1,8),"576371");var step=game.block(Vector3(49,.12,0),Vector3(1.5,.24,3),"576371");p.position=Vector3(46,.03,0);p.rotation.y=0;p.yaw=0;p.velocity=Vector3.ZERO;observer.position=Vector3(50,3,7);observer.look_at(Vector3(49,1,0));p.set_physics_process(true);await physics(6)
 Input.action_press("right");await physics(18);await capture("physical-step-approach-031",1);await physics(10);await capture("physical-step-capsule-rises-031",1);await physics(28);Input.action_release("right");await capture("physical-step-cleared-standing-031",1);p.set_physics_process(false);floor.queue_free();step.queue_free();await frames()
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.match_flow.start_flash=0;p.set_physics_process(false);p.position=Vector3(100,-100,100);p.collision_layer=0;p.human.hide();p.wolf.hide();p.viewmodel.hide();game.source_hud.set_process(false);game.source_hud.hide();game.touch.set_process(false);game.touch.hide();observer.position=Vector3(0,19,24);observer.look_at(Vector3(0,0,-1));observer.current=true
 for team in ["red","blue"]:
  for slot in range(4):game.spawn_enemy("human","normal",team)
 DirAccess.make_dir_recursive_absolute(movie_frames)
 for i in range(120):
  await physics(6);await RenderingServer.frame_post_draw;var im=root.get_texture().get_image();im.save_png(movie_frames.path_join("%04d.png" % i))
  if i%10==0:
   var path=output.path_join("autonomous-squads-%02d-sec-031.png" % (i/10));captures.append({"name":"autonomous-squads-%02d-sec-031" % (i/10),"path":path,"width":im.get_width(),"height":im.get_height(),"saved":im.save_png(path)==OK})
   var actors=[]
   for bot in game.enemies.get_children():
    if not game.actor_alive(bot):continue
    actors.append({"id":bot.roster_id,"team":bot.team,"position":[bot.position.x,bot.position.y,bot.position.z],"state":bot.state,"health":bot.health,"shots":bot.shots_fired,"coverEntries":bot.tactics.cover_entries,"peeks":bot.tactics.peeks,"sharedReports":bot.tactics.reports_received})
   squad_trace.append({"second":i/10,"actors":actors})
 game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":failures.size(),"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"movieFrames":120,"movieFrameRate":10,"simulatedSquadSeconds":12,"squadTrace":squad_trace,"scope":"Real native-touch selection, wolf poses/physical movement and autonomous eight-NPC encounter. Observer camera and HP fixtures documented; no Android-device claim."},"  "));file.close();quit(0 if failures.is_empty() else 1)
