extends SceneTree
var output
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=4):
 for i in range(n):await process_frame
func run():
 root.size=Vector2i(1280,720);var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);game.book.wolf_mutation="normal";game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.match_flow.signal_start();game.match_flow.start_flash=0
 var p=game.player;game.health=game.max_health();p.position=Vector3(0,.03,12);p.rotation.y=0;p.yaw=0;p.pitch=0;p.pivot.rotation.x=0;p.velocity=Vector3.ZERO;p.camera.current=true;game.inbox.state.powerSlots.claw="16018";await frames(6)
 var directory="/dev/shm/wolf031-gameplay-frames";DirAccess.make_dir_recursive_absolute(directory);var captures=[];var trace=[];var names={10:"wolf-running-240hp",30:"wolf-running-after-crouch-release",51:"wolf-standing-after-roll",55:"wolf-native-claw-swing",65:"wolf-native-airborne-pose"};var saved=0
 for i in range(80):
  if i==0:Input.action_press("forward")
  if i==20:Input.action_press("crouch")
  if i==30:Input.action_release("crouch")
  if i==40:Input.action_release("forward");Input.action_press("roll")
  if i==41:Input.action_release("roll")
  if i==52:Input.action_press("fire")
  if i==60:Input.action_release("fire");Input.action_press("jump")
  if i==61:Input.action_release("jump")
  for tick in range(6):await physics_frame
  game._process(.1);await RenderingServer.frame_post_draw;var image=root.get_texture().get_image();saved+=1 if image.save_png(directory.path_join("%04d.png" % i))==OK else 0
  trace.append({"sampleSecond":float(i)/10,"hp":game.health,"clip":p.current_clip,"crouching":p.crouching,"rolling":p.rolling,"capsuleHeight":p.capsule.height,"position":[p.position.x,p.position.y,p.position.z]})
  if names.has(i):
   var name=names[i]+"-031";var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":image.get_width(),"height":image.get_height(),"saved":image.save_png(path)==OK})
 game.touch.reset();game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0 if saved==80 else 1,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"movieFrames":80,"movieFrameRate":10,"trace":trace,"scope":"Actual default-camera controlled input sequence: run, explicit crouch/release, stationary native roll, native claws and jump. Normal240HP; original claw16018 equipped for demonstration; no FT. Silent render capture."},"  "));file.close();quit(0 if saved==80 else 1)
