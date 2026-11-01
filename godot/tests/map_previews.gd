extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var world = Node3D.new()
	root.add_child(world)
	var path = "res://assets/maps/previews.json"
	var rows = JSON.parse_string(FileAccess.get_file_as_string(path))
	var results = []
	var approved = 0
	for row in rows:
		var scene = load(row.previewAsset).instantiate()
		world.add_child(scene)
		var triangles = 0
		for mesh in scene.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				triangles += mesh.mesh.surface_get_array_index_len(surface) / 3
			mesh.create_trimesh_collision()
		await physics_frame
		await physics_frame
		var safe_starts = []
		for point in row.startPoints:
			var p = point.position
			var source = Vector3(p[0],p[1],p[2])
			var query = PhysicsRayQueryParameters3D.create(source+Vector3.UP*2,source-Vector3.UP*15,1)
			query.hit_back_faces = true
			var hit = world.get_world_3d().direct_space_state.intersect_ray(query)
			if hit and hit.normal.y > 0.5:
				var pos = hit.position+Vector3.UP*0.1
				var capsule = CapsuleShape3D.new()
				capsule.radius = 0.36
				capsule.height = 1.8
				var clearance = PhysicsShapeQueryParameters3D.new()
				clearance.shape = capsule
				clearance.transform = Transform3D(Basis.IDENTITY,pos+Vector3.UP*0.9)
				clearance.collision_mask = 1
				if world.get_world_3d().direct_space_state.intersect_shape(clearance,1).is_empty():
					point.position = [pos.x,pos.y,pos.z]
					safe_starts.append(point)
		row.startPoints = safe_starts
		row.previewValidated = triangles > 0 and not safe_starts.is_empty()
		row.validationScope = "Godot headless import, generated triangle collision, source spawn downward rays and standing capsule clearance. Not original mode or Android device QA."
		if row.previewValidated:
			approved += 1
		print("MAP_PREVIEW ",row.number," triangles=",triangles," safe_starts=",safe_starts.size()," approved=",row.previewValidated)
		results.append(row)
		world.remove_child(scene)
		scene.queue_free()
		await process_frame
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	file.close()
	world.queue_free()
	print("MAP_PREVIEW_QA ",approved,"/",rows.size())
	quit(0 if approved == rows.size() else 1)
