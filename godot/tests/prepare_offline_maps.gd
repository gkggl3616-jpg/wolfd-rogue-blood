extends SceneTree

# Bake on the workstation, never on a phone. Geometry and source spawn records
# stay unchanged; these are navigation resources for the mobile offline rules.
func _initialize():
	call_deferred("run")

func run():
	DirAccess.make_dir_recursive_absolute("res://assets/maps/offline")
	var records = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"))
	var results = []
	for record in records:
		var scene = load(record.previewAsset).instantiate()
		root.add_child(scene)
		var navigation = NavigationMesh.new()
		navigation.cell_size = 0.3
		navigation.cell_height = 0.2
		navigation.agent_height = 2.0
		navigation.agent_radius = 0.6
		navigation.agent_max_climb = 0.4
		navigation.agent_max_slope = 48.0
		if int(record.number) in [72,36,37,20,24,106]:
			navigation.cell_size=0.16
			navigation.agent_radius=0.44
			navigation.agent_height=1.9
			navigation.agent_max_climb=0.5
		if int(record.number) in [72,36,37,106]:navigation.agent_height=1.2
		if int(record.number) in [72,37,106]:navigation.agent_max_climb=0.8
		# This dense curved map has coincident rasterized edges at 0.3 m.
		if int(record.number) == 97:
			navigation.cell_size = 0.4
			navigation.agent_radius = 0.8
		navigation.region_min_size = 2.0
		navigation.region_merge_size = 10.0
		var geometry = NavigationMeshSourceGeometryData3D.new()
		NavigationServer3D.parse_source_geometry_data(navigation, geometry, scene)
		NavigationServer3D.bake_from_source_geometry_data(navigation, geometry)
		var path = "res://assets/maps/offline/%d.res" % int(record.number)
		if navigation.get_polygon_count() == 0 or ResourceSaver.save(navigation, path) != OK:
			push_error("Offline navigation bake failed: " + str(record.number))
			quit(1);return
		results.append({"number": int(record.number), "geometrySha256": record.sha256,
			"navigation": path, "sha256": FileAccess.get_sha256(path),
			"polygons": navigation.get_polygon_count()})
		print("OFFLINE_BAKE ", int(record.number), " polygons=", navigation.get_polygon_count())
		root.remove_child(scene);scene.queue_free()
		await process_frame
	var file = FileAccess.open("res://assets/maps/offline.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  ")+"\n");file.close()
	quit(0)
