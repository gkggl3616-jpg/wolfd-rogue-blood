extends Node
const Instance=preload("res://scripts/clientfx_instance.gd")
var game
var catalog={}
var animations={}
var names={}
var active=[]
var missing=[]
var camera_shake=Vector2.ZERO
var motion_index={}
var motion_donor=""
var motion_clips={}
var frost=[]
func clear_frost(entry):
	for row in entry.meshes:
		var mesh=row.mesh.get_ref()
		if is_instance_valid(mesh):mesh.material_overlay=row.previous
func frost_hit(victim,attacker):
	if not is_instance_valid(attacker) or not game.actor_alive(victim) or game.game_audio.actor_form(attacker)!="wolf":return
	# The ice form association is source data; this hit presentation does not
	# infer an unverified PC stun, movement penalty or damage modifier.
	var effects=model_record(attacker).get("effects",{}).values()
	if not effects.any(func(name):return str(name).to_lower() in ["howling_ice_1","cryicewolf"]):return
	for entry in frost:
		if entry.actor.get_ref()==victim:clear_frost(entry)
	frost=frost.filter(func(entry):return entry.actor.get_ref()!=victim)
	var node=catalog.groups.lockedinice.nodes[0];var seconds=float(node.end)
	var model=victim.wolf if victim==game.player and victim.is_wolf else (victim.human if victim==game.player else victim.body)
	var material=StandardMaterial3D.new();material.albedo_texture=load(node.frames[0]);material.albedo_color=Color(.85,.95,1,.48);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.roughness=.2
	var meshes=[]
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).to_lower().begins_with("tattoo"):continue
		meshes.append({"mesh":weakref(mesh),"previous":mesh.material_overlay});mesh.material_overlay=material
	frost.append({"actor":weakref(victim),"remaining":seconds,"meshes":meshes})
	for effect in group_instances(victim,"lockedinice"):effect.queue_free()
	play("lockedinice",victim)
func _ready():
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/clientfx/catalog.json"))
	animations=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/animation-events.json"))
	motion_index=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/locomotion/index.json"))
	for name in catalog.groups:names[name.to_lower()]=name
func canonical(name):return names.get(str(name).to_lower(),"")
func play(name,actor=null,where=null,loop=false,depth=0,parent=null,round_effect=false):
	var key=canonical(name)
	active=active.filter(func(n):return is_instance_valid(n) and not n.is_queued_for_deletion())
	if key=="" or depth>3 or active.size()>=64:
		if key=="" and not str(name) in missing:missing.append(str(name))
		return null
	var instance=Instance.new();instance.system=self;instance.actor=actor;instance.group=key;instance.looping=loop;instance.depth=depth;instance.round_effect=round_effect
	(parent if is_instance_valid(parent) else game.transient_effects).add_child(instance)
	instance.global_position=where if where is Vector3 else (actor.global_position if is_instance_valid(actor) else Vector3.ZERO)
	active.append(instance);return instance
func stop_actor(actor):
	for node in active:
		if is_instance_valid(node) and node.actor==actor:node.queue_free()
func group_instances(actor,name):return active.filter(func(n):return is_instance_valid(n) and not n.is_queued_for_deletion() and n.actor==actor and n.group==canonical(name))
func clear():
	for node in active:
		if is_instance_valid(node):node.queue_free()
	active=[];camera_shake=Vector2.ZERO
	for entry in frost:clear_frost(entry)
	frost=[]
func _process(delta):
	for entry in frost:
		entry.remaining-=delta
		if entry.remaining<=0 or not game.actor_alive(entry.actor.get_ref()):clear_frost(entry);entry.remaining=0
	frost=frost.filter(func(entry):return entry.remaining>0)
	if not game.running or game.menu_open or game.application_suspended:clear()
	elif not game.is_match_active():
		for node in active:
			if is_instance_valid(node) and not node.round_effect:node.queue_free()
	if is_instance_valid(game.player) and is_instance_valid(game.player.camera):
		var camera=get_viewport().get_camera_3d()
		if camera!=null:camera.h_offset=clampf(camera_shake.x,-0.08,0.08);camera.v_offset=clampf(camera_shake.y,-0.08,0.08)
	camera_shake=Vector2.ZERO
func model_record(actor):
	var form=game.game_audio.actor_form(actor)
	if actor==game.player and form=="wolf" and actor.mutation_id!="normal":
		var source=game.mutations.model(actor.mutation_id,game.local_room.get("team","blue"));return catalog.get("mutations",{}).get(source.get("definition",""),{})
	return catalog.characters.get(actor.character_info.get("id",""),{}).get(form,{})
func animation_record(actor,clip):
	var info=model_record(actor);var donor=info.get("donor","")
	var form=game.game_audio.actor_form(actor)
	var aliases={"idle":"LSt","run":"LRF","jump":"LJJ","attack":"UMFi1" if form=="wolf" else "URi1Fi","reload":"URi1Re","crouch":"LC","crouch_run":"LCWF","roar":"T_CRY","wolf_run":"T_WallDash","body_attack":"T_Bodyatk","special_attack":"T_Specialatk","wall_hold":"T_WallHold_L","airborne_attack":"T_WallDashAtk","strong_attack":"UMFi3","attack_right":"UMFi2"}
	var source=aliases.get(clip,clip)
	if form=="wolf":source=motion_index.aliases.get(clip,source)
	var action=actor.character_info.get(form,{}).get("sourceActions",{}).get(clip,{})
	if actor!=game.player or actor.mutation_id=="normal":
		if action.has("clip"):source=action.clip
		if action.has("donor"):donor="root/"+str(action.donor).replace("\\","/").to_lower().trim_prefix("root/")
	return animations.models.get(donor,{}).get("animations",{}).get(source,{})
func socket_transform(actor,name):
	var model=actor.wolf if actor==game.player and actor.is_wolf else (actor.human if actor==game.player else actor.body)
	var skeletons=model.find_children("*","Skeleton3D",true,false)
	if skeletons.is_empty():return Transform3D(actor.global_basis,actor.global_position)
	var skeleton=skeletons[0];var info=model_record(actor);var sockets=animations.models.get(info.get("donor",""),{}).get("sockets",[])
	for socket in sockets:
		if str(socket.name).to_lower()!=str(name).to_lower():continue
		var index=skeleton.find_bone(socket.boneName)
		if index<0:continue
		var q=socket.rotation;var p=socket.position
		var transform=skeleton.global_transform*skeleton.get_bone_global_pose(index)*Transform3D(Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized()),Vector3(p[0],p[1],p[2]))
		transform.basis=transform.basis.orthonormalized();return transform
	var bone=skeleton.find_bone(name)
	if bone<0:
		var fallback="Bip01 Head" if str(name).to_lower() in ["cry","lefteye","righteye"] else ("Bip01 L Hand" if "lhand" in str(name).to_lower() or "left" in str(name).to_lower() else ("Bip01 R Hand" if "rhand" in str(name).to_lower() or "right" in str(name).to_lower() else "Bip01 Spine2"))
		bone=skeleton.find_bone(fallback)
	if bone>=0:
		var transform=skeleton.global_transform*skeleton.get_bone_global_pose(bone);transform.basis=transform.basis.orthonormalized();return transform
	return Transform3D(actor.global_basis,actor.global_position+Vector3.UP*1.6)

var strong_data={}
var right_data={}
func install_strong(actor):
	if strong_data.is_empty():strong_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/strong-clips.json")).donors
	return install_action(actor,"strong_attack",strong_data)
func install_right_attack(actor):
	if right_data.is_empty():right_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/right-clips.json")).donors
	return install_action(actor,"attack_right",right_data)
func install_motion(actor,clip):
	if not is_instance_valid(actor.anim):return false
	if actor.anim.has_animation(clip):return true
	var donor=model_record(actor).get("donor","")
	var record=motion_index.donors.get(donor,{})
	if not clip in record.get("clips",[]):return false
	if donor!=motion_donor:
		var bytes=FileAccess.get_file_as_bytes(record.asset).decompress_dynamic(32*1024*1024,FileAccess.COMPRESSION_GZIP)
		if bytes.is_empty():return false
		motion_clips=JSON.parse_string(bytes.get_string_from_utf8()).clips;motion_donor=donor
	if not motion_clips.has(clip):return false
	var installed=install_action(actor,clip,{donor:motion_clips[clip]})
	if installed:actor.anim.get_animation(clip).loop_mode=Animation.LOOP_NONE if clip=="jump_land" else Animation.LOOP_LINEAR
	return installed
func install_action(actor,clip,data,replace_existing=false):
	if not is_instance_valid(actor.anim):return false
	if actor.anim.has_animation(clip) and not replace_existing:return true
	var donor=model_record(actor).get("donor","")
	if not data.has(donor):return false
	var source=data[donor];var model=actor.wolf if actor==game.player else actor.body
	var skeletons=model.find_children("*","Skeleton3D",true,false)
	if skeletons.is_empty():return false
	var skeleton=skeletons[0];var animation_root=actor.anim.get_node(actor.anim.root_node);var path=str(animation_root.get_path_to(skeleton));var animation=Animation.new();animation.length=source.times[-1]-source.times[0]
	for row in source.tracks:
		if skeleton.find_bone(row.bone)<0:return false
		var pos=animation.add_track(Animation.TYPE_POSITION_3D);animation.track_set_path(pos,NodePath(path+":"+row.bone))
		var rot=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(rot,NodePath(path+":"+row.bone))
		for i in range(source.times.size()):
			var p=row.positions[i];var q=row.rotations[i];var time=source.times[i]-source.times[0]
			animation.track_insert_key(pos,time,Vector3(p[0],p[1],p[2]));animation.track_insert_key(rot,time,Quaternion(q[0],q[1],q[2],q[3]).normalized())
	var library=actor.anim.get_animation_library("").duplicate()
	if library.has_animation(clip):library.remove_animation(clip)
	library.add_animation(clip,animation)
	var current=actor.anim.current_animation;var time=actor.anim.current_animation_position if current!="" else 0.0
	actor.anim.remove_animation_library("");actor.anim.add_animation_library("",library)
	if current!="":actor.anim.play(current);actor.anim.seek(time,true)
	return true

var pose_index={}
var pose_cache={}
func install_wolf_pose(actor,clip):
	if not is_instance_valid(actor.anim) or game.game_audio.actor_form(actor)!="wolf":return false
	var donor=model_record(actor).get("donor","")
	if pose_index.is_empty():pose_index=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/wolf-poses/index.json")).donors
	var entry=pose_index.get(donor,{})
	if entry.is_empty():return false
	var variant=clip
	if clip in ["attack","attack_right"]:
		var crouched=actor.crouching if actor==game.player else actor.capsule.height<1.5
		variant+="_crouch" if crouched else ("_air" if not actor.is_on_floor() else "_stand")
	if not variant in entry.clips:return false
	var meta="native_wolf_pose_"+clip
	if actor.anim.get_meta(meta,"")==variant:return true
	if not pose_cache.has(donor):
		if pose_cache.size()>=3:pose_cache.erase(pose_cache.keys()[0])
		var raw=FileAccess.get_file_as_bytes(entry.asset).decompress_dynamic(64*1024*1024,FileAccess.COMPRESSION_GZIP)
		if raw.size()<4:return false
		var size=raw.decode_u32(0)
		if size>raw.size()-4:return false
		pose_cache[donor]={"header":JSON.parse_string(raw.slice(4,4+size).get_string_from_utf8()),"bytes":raw.slice(4+size)}
	var bank=pose_cache[donor];var source=bank.header.clips[variant].duplicate(true);var tracks=[]
	for row in source.tracks:
		var count=int(row.count);var po=int(row.positionOffset);var qo=int(row.rotationOffset)
		if count!=source.times.size() or po<0 or qo<0 or po+count*12>bank.bytes.size() or qo+count*16>bank.bytes.size():return false
		var positions=bank.bytes.slice(po,po+count*12).to_vector3_array();var values=bank.bytes.slice(qo,qo+count*16).to_float32_array();var rotations=[]
		for i in range(count):rotations.append(Vector4(values[i*4],values[i*4+1],values[i*4+2],values[i*4+3]))
		tracks.append({"bone":row.bone,"positions":positions,"rotations":rotations})
	source.tracks=tracks
	if not install_action(actor,clip,{donor:source},true):return false
	actor.anim.get_animation(clip).loop_mode=Animation.LOOP_LINEAR if clip in ["idle","run","crouch","crouch_run","jump_air"] or clip.begins_with("run_") or clip.begins_with("crouch_") else Animation.LOOP_NONE
	actor.anim.set_meta(meta,variant);return true
