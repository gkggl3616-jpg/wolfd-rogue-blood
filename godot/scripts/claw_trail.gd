extends Node3D
# Ribbons follow the exact endpoint bone names in abilityswingtrail.dat.
# Sampling lifetime is a mobile render choice; texture and bindings are source data.
var player
var remaining=0.0
var bindings=[]
var skeleton
var samples=[]
var meshes=[]
var material
func clear():
	remaining=0;samples=[];bindings=[]
	for node in meshes:
		if is_instance_valid(node):node.queue_free()
	meshes=[]
func begin():
	clear()
	if not player.is_wolf or not player.game.is_combat_active():return false
	var item=player.game.power_item(player.game.inbox.state.powerSlots.get("claw",""))
	var trail=item.get("trail",player.game.power_catalog.get("defaultClawTrail",{}))
	if trail.is_empty():return false
	var found=player.wolf.find_children("*","Skeleton3D",true,false)
	if found.is_empty():return false
	skeleton=found[0]
	for bone in trail.bones:
		var index=skeleton.find_bone(bone)
		if index<0:return false
		bindings.append(index)
	material=StandardMaterial3D.new();material.albedo_texture=load(trail.asset);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.vertex_color_use_as_albedo=true;material.no_depth_test=false
	for i in range(2):
		var mesh=MeshInstance3D.new();mesh.mesh=ImmediateMesh.new();mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh);meshes.append(mesh)
	remaining=0.18;return true
func _process(delta):
	if remaining<=0:return
	if not player.game.is_combat_active() or not player.is_wolf or not is_instance_valid(skeleton):clear();return
	remaining-=delta
	if remaining<=0:clear();return
	var positions=[]
	for bone in bindings:positions.append(to_local(skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin))
	samples.append(positions)
	if samples.size()>8:samples.pop_front()
	if samples.size()<2:return
	for side in range(2):
		var mesh=meshes[side].mesh as ImmediateMesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in range(samples.size()):
			for j in range(2):
				mesh.surface_set_color(Color(1,1,1,float(i+1)/samples.size()));mesh.surface_set_uv(Vector2(float(i)/maxi(1,samples.size()-1),j));mesh.surface_add_vertex(samples[i][side*2+j])
		mesh.surface_end()
