extends RefCounted
static var data={}
static var library_cache={}
static func apply(model,entry,held_weapon=false):
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/presentation/menu-clips.json"))
 var donor=str(entry.human.donor).to_lower().trim_prefix("root/")
 var mode="primary" if held_weapon else "unarmed"
 var clip=data.get("donors",{}).get(donor,{}).get("clips",{}).get(mode,{})
 var players=model.find_children("*","AnimationPlayer",true,false);var skeletons=model.find_children("*","Skeleton3D",true,false)
 if clip.is_empty() or players.is_empty() or skeletons.is_empty():return false
 var animator=players[0];var skeleton=skeletons[0];var base=animator.get_node(animator.root_node);var path=str(base.get_path_to(skeleton))
 var cache_key=donor+":"+mode+":"+path
 var animation=library_cache.get(cache_key)
 if animation==null:
  animation=Animation.new();animation.length=clip.times[-1]-clip.times[0];animation.loop_mode=Animation.LOOP_LINEAR
  for bone in clip.bones:
   if skeleton.find_bone(bone.name)<0:return false
   var position_track=animation.add_track(Animation.TYPE_POSITION_3D);animation.track_set_path(position_track,NodePath(path+":"+bone.name))
   var rotation_track=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(rotation_track,NodePath(path+":"+bone.name))
   for i in range(clip.times.size()):
    var p=bone.translation[i];var q=bone.rotation[i];var time=clip.times[i]-clip.times[0]
    animation.track_insert_key(position_track,time,Vector3(p[0],p[1],p[2]));animation.track_insert_key(rotation_track,time,Quaternion(q[0],q[1],q[2],q[3]).normalized())
  library_cache[cache_key]=animation
 var library=AnimationLibrary.new();library.add_animation(mode,animation)
 if animator.has_animation_library("menu"):animator.remove_animation_library("menu")
 animator.add_animation_library("menu",library);animator.play("menu/"+mode);animator.advance(0)
 skeleton.force_update_all_bone_transforms();model.set_meta("menu_source_clip",clip.sourceClip);return true
