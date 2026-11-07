extends Node3D
# Original FP mesh/hand clips. No plant animation is repurposed as a defuse clip.
var game
var specs={}
var held:Node3D
var world:Node3D
var anim:AnimationPlayer
var operating=false
var last_time=-0.001
var tick_clock=0.0
var history=[]
func _ready():
 specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/timebomb/device.json"))
 held=load(specs.asset).instantiate();held.position=Vector3(0.18,-0.37,-0.72);held.scale.z*=-1;game.player.camera.add_child(held);held.hide()
 anim=held.find_children("*","AnimationPlayer",true,false)[0]
 for mesh in held.find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 world=load(specs.world.asset).instantiate();add_child(world);world.hide()
func cancel():
 if operating and is_instance_valid(game.player.viewmodel):game.player.viewmodel.visible=not game.player.is_wolf and not game.spectator.active and not game.player.is_scoped()
 operating=false;last_time=-0.001
 if is_instance_valid(held):held.hide();anim.stop()
func reset():
 cancel();tick_clock=0;history.clear()
 if is_instance_valid(world):world.hide()
func source_events(time):
 for event in specs.sourcePlantEvents:
  var at=float(event.timeMs)/1000
  if at>last_time and at<=time:
   for key in str(event.key).split(";"):
    var tokens=key.strip_edges().split(" ",false)
    if tokens.size()==2 and tokens[0]=="sound_key" and tokens[1] in ["10","11"]:
     game.game_audio.play_at(specs.soundKeys[tokens[1]],game.player.global_position,false);history.append(key.strip_edges())
 last_time=time
func complete_plant(actor):
 if actor==game.player:history.append("INSTALL_TIMEBOMB")
 game.game_audio.play_at(specs.soundKeys["12"],game.destruction.bomb,false)
 cancel()
func _process(delta):
 var d=game.destruction
 if not game.running or not d.enabled:reset();return
 if game.menu_open or game.application_suspended:cancel();return
 world.visible=d.phase=="combat" and (d.planted or d.dropped)
 if world.visible:world.global_position=d.bomb+Vector3.UP*0.08
 if d.planted and d.phase=="combat":
  tick_clock-=delta
  if tick_clock<=0:
   tick_clock=0.25 if d.fuse<10 else 1.0
   game.game_audio.play_at("root/wt_snd/interface/bomb_tick.wav",d.bomb,false)
 else:tick_clock=0
 var planting=d.phase=="combat" and not d.planted and game.health>0 and d.operator_id==game.player.get_instance_id() and d.progress>0
 if not planting:cancel();return
 operating=true;held.show();game.player.viewmodel.hide()
 var selecting=d.progress<float(specs.selectSeconds)
 var clip="select" if selecting else "plant"
 if anim.assigned_animation!=clip:anim.play(clip)
 var time=d.progress if selecting else d.progress-float(specs.selectSeconds)
 anim.seek(time,true);anim.pause()
 if not selecting:source_events(time)
