extends RefCounted

# Fit the actual visible meshes instead of assuming every character has the same
# height, origin, model units, or viewport aspect ratio.
static func frame(camera: Camera3D, content: Node3D, viewport_size: Vector2) -> AABB:
	var bounds = AABB()
	var found = false
	for mesh in content.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or mesh.mesh == null: continue
		var transform = content.global_transform.affine_inverse() * mesh.global_transform
		var box = transform * mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	# Static mesh AABBs describe the bind pose. Frame the displayed skeleton,
	# including its animated root offset, so feet/head stay within the phone panel.
	var posed=AABB();var posed_found=false
	for skeleton in content.find_children("*","Skeleton3D",true,false):
		for i in range(skeleton.get_bone_count()):
			var name=str(skeleton.get_bone_name(i))
			if not name.begins_with("Bip") or not ["Head","Neck","Spine","Pelvis","Clavicle","UpperArm","Forearm","Hand","Thigh","Calf","Foot","Toe0"].any(func(part):return part in name):continue
			var point=content.to_local(skeleton.global_transform*skeleton.get_bone_global_pose(i).origin)
			if not point.is_finite():continue
			posed=posed.expand(point) if posed_found else AABB(point,Vector3.ZERO);posed_found=true
	if posed_found and posed.size.y>0.2:
		bounds=posed.grow(0.16 if camera.projection==Camera3D.PROJECTION_ORTHOGONAL else 0.18)
		if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:bounds.size.y+=0.3
		found=true
	if not found: return bounds
	var center = content.to_global(bounds.get_center())
	var aspect = maxf(0.1, viewport_size.x / maxf(1, viewport_size.y))
	if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:
		camera.size=maxf(bounds.size.y,bounds.size.x/aspect)*1.04
		camera.global_position=center+Vector3(0,0,maxf(3,bounds.size.z*2));camera.look_at(center);return bounds
	var tangent = tan(deg_to_rad(camera.fov) * 0.5)
	var distance = maxf(bounds.size.y * 0.6 / tangent, bounds.size.x * 0.6 / (tangent * aspect)) + bounds.size.z * 0.5
	camera.global_position = center + Vector3(0, 0, maxf(0.3, distance))
	camera.look_at(center)
	return bounds
