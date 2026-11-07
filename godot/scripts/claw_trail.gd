extends Node3D
# Ribbons follow the exact endpoint bone names in abilityswingtrail.dat.
# Sampling lifetime is a mobile render choice; texture and bindings are source data.
var player
var remaining=0.0
var source_control=false
var enabled_sides=[true,true]
var bindings=[]
var skeleton
var samples=[]
var meshes=[]
var material
var glow=[]
func refresh_glow():
	# The reference glow belongs to active FT/energy, independently of the
	# equipped claw. Item ownership alone cannot start a combat effect.
	var active=player.is_wolf and player.game.is_combat_active() and player.game.booster_remaining>0
	if not active:
		for effect in glow:
			if is_instance_valid(effect):effect.queue_free()
		glow=[];return
	glow=glow.filter(func(effect):return is_instance_valid(effect) and not effect.is_queued_for_deletion())
	for group in ["wolf_Hand_glowL","wolf_Hand_glowR"]:
		if not glow.any(func(effect):return effect.group==group):
			var effect=player.game.clientfx.play(group,player,null,true)
			if effect!=null:glow.append(effect)
func clear():
	remaining=0;samples=[];bindings=[];source_control=false;enabled_sides=[true,true]
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
func source_window(side,enabled):
	if side<0 or side>1:return
	if not source_control:
		if remaining<=0 and not begin():return
		source_control=true;enabled_sides=[false,false]
	enabled_sides[side]=enabled
	if not enabled_sides.any(func(v):return v):clear()
func _process(delta):
	refresh_glow()
	if remaining<=0:return
	if not player.game.is_combat_active() or not player.is_wolf or not is_instance_valid(skeleton):clear();return
	remaining=0.18 if source_control else remaining-delta
	if remaining<=0:clear();return
	var positions=[]
	for bone in bindings:positions.append(to_local(skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin))
	samples.append(positions)
	if samples.size()>8:samples.pop_front()
	if samples.size()<2:return
	for side in range(2):
		meshes[side].visible=enabled_sides[side]
		var mesh=meshes[side].mesh as ImmediateMesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in range(samples.size()):
			for j in range(2):
				mesh.surface_set_color(Color(1,1,1,float(i+1)/samples.size()));mesh.surface_set_uv(Vector2(float(i)/maxi(1,samples.size()-1),j));mesh.surface_add_vertex(samples[i][side*2+j])
		mesh.surface_end()
