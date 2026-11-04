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
	if not found: return bounds
	var center = content.to_global(bounds.get_center())
	var aspect = maxf(0.1, viewport_size.x / maxf(1, viewport_size.y))
	var tangent = tan(deg_to_rad(camera.fov) * 0.5)
	var distance = maxf(bounds.size.y * 0.6 / tangent, bounds.size.x * 0.6 / (tangent * aspect)) + bounds.size.z * 0.5
	camera.global_position = center + Vector3(0, 0, maxf(0.3, distance))
	camera.look_at(center)
	return bounds
