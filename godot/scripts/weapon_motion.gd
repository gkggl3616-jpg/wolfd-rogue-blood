extends RefCounted
const Bone=preload("res://scripts/native_socket_bone.gd")
var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/animations/index.json")).models
var audio=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/audio.json")).items
var player
var record={}
var bank={}
var active_events=[]
var elapsed=0.0
var event_index=0
var event_history=[]
func source_clip(alias):
 for name in record.get("animations",{}):
  if str(name).to_lower()==str(alias).to_lower() or (alias=="idle" and str(name).to_lower()=="idle0"):return record.animations[name]
 return {}
func bind(actor,item):
 player=actor;record=catalog.get(item.model,{});bank=audio.get(item.id,{}).get("keys",{});active_events=[];elapsed=0;event_index=0
 if not record.has("asset"):return true
 var bytes=FileAccess.get_file_as_bytes(record.asset).decompress_dynamic(32*1024*1024,FileAccess.COMPRESSION_GZIP)
 var data=JSON.parse_string(bytes.get_string_from_utf8());var skeletons=player.viewmodel.find_children("*","Skeleton3D",true,false)
 if not data is Dictionary or skeletons.is_empty():return false
 var skeleton=skeletons[0];var resolved=[]
 for i in range(data.bones.size()):
  var index=Bone.find(skeleton,{"boneName":data.bones[i].name,"bone":i},data.bones)
  if index<0:return false
  resolved.append(skeleton.get_bone_name(index))
 var root=player.weapon_anim.get_node(player.weapon_anim.root_node);var path=str(root.get_path_to(skeleton));var library=player.weapon_anim.get_animation_library("").duplicate()
 for alias in data.clips:
  var spec=data.clips[alias];var animation=Animation.new();animation.length=spec.times[-1]-spec.times[0]
  for i in range(spec.tracks.size()):
   var row=spec.tracks[i];var position=animation.add_track(Animation.TYPE_POSITION_3D);var rotation=animation.add_track(Animation.TYPE_ROTATION_3D)
   animation.track_set_path(position,NodePath(path+":"+resolved[i]));animation.track_set_path(rotation,NodePath(path+":"+resolved[i]))
   for frame in range(spec.times.size()):
    var p=row.positions[frame];var q=row.rotations[frame];var time=spec.times[frame]-spec.times[0]
    animation.track_insert_key(position,time,Vector3(p[0],p[1],p[2]));animation.track_insert_key(rotation,time,Quaternion(q[0],q[1],q[2],q[3]).normalized())
  if library.has_animation(alias):library.remove_animation(alias)
  library.add_animation(alias,animation)
 player.weapon_anim.remove_animation_library("");player.weapon_anim.add_animation_library("",library);return true
func has_sound_events(alias):
 for event in source_clip(alias).get("events",[]):
  var expression=RegEx.new();expression.compile("(?i)sound_key\\s+(\\d+)")
  for match in expression.search_all(event.key):
   if bank.has(match.get_string(1)) and player.game.game_audio.sounds.has(bank[match.get_string(1)]):return true
 return false
func start(alias):
 active_events=source_clip(alias).get("events",[]);elapsed=0;event_index=0;advance(0)
func advance(delta):
 if not is_instance_valid(player) or not player.game.is_combat_active():return
 elapsed+=maxf(0,delta)
 while event_index<active_events.size() and float(active_events[event_index].timeMs)<=elapsed*1000+.001:
  var event=active_events[event_index];event_index+=1
  var expression=RegEx.new();expression.compile("(?i)sound_key\\s+(\\d+)")
  for match in expression.search_all(event.key):
   var key=match.get_string(1)
   if not bank.has(key):continue
   var source=bank[key];event_history.append({"key":int(key),"source":source,"timeMs":event.timeMs})
   if event_history.size()>64:event_history.pop_front()
   player.game.game_audio.play_at(source,player.global_position,false,"WolfWeapons",-12)
func throw_release_time():
 for event in source_clip("postfire").get("events",[]):
  if str(event.key).to_lower().contains("fire_key"):return float(event.timeMs)/1000.0
 return -1.0
