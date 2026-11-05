extends SceneTree

# The PC radar's world-to-texture calibration is not available. Generate a
# local floor plan from the verified navigation geometry, with an explicit
# projection shared by the image and live player marker. No invented markers.
func _initialize():call_deferred("run")

func run():
	DirAccess.make_dir_recursive_absolute("res://assets/maps/radar")
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/offline.json"))
	var results = []
	for row in rows:
		var mesh = load(row.navigation) as NavigationMesh
		var vertices = mesh.get_vertices()
		var low = Vector2(INF,INF);var high = Vector2(-INF,-INF)
		for point in vertices:
			low = low.min(Vector2(point.x,point.z));high = high.max(Vector2(point.x,point.z))
		var extent = high-low
		var side = maxf(extent.x,extent.y)*1.08
		var origin = (low+high)*0.5-Vector2.ONE*side*0.5
		var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" fill="#11191b"/><g fill="#6a7779" stroke="#a5ada9" stroke-width="0.35">'
		for i in range(mesh.get_polygon_count()):
			var points = ""
			for index in mesh.get_polygon(i):
				var v = vertices[index]
				var projected = (Vector2(v.x,v.z)-origin)/side*256
				points += "%.3f,%.3f " % [projected.x,projected.y]
			svg += '<polygon points="'+points+'"/>'
		svg += '</g></svg>'
		var image = Image.new()
		if image.load_svg_from_string(svg)!=OK:push_error("Radar raster failed");quit(1);return
		var asset = "res://assets/maps/radar/%d.png" % int(row.number)
		if image.save_png(asset)!=OK:push_error("Radar save failed");quit(1);return
		results.append({"number":int(row.number),"asset":asset,"sha256":FileAccess.get_sha256(asset),
			"navigationSha256":row.sha256,"worldOrigin":[origin.x,origin.y],"worldSize":side,
			"basis":"navigation_mesh_xz_local_projection","originalPcRadar":false})
	var file = FileAccess.open("res://assets/maps/radar.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  ")+"\n");file.close()
	print("RADAR_BAKE ",results.size());quit()
