extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await process_frame
 var nav=NavigationMesh.new();nav.cell_size=0.3;nav.cell_height=0.2;nav.agent_height=2.0;nav.agent_radius=0.6;nav.agent_max_climb=0.2
 var source=NavigationMeshSourceGeometryData3D.new();NavigationServer3D.parse_source_geometry_data(nav,source,game.arena_root);NavigationServer3D.bake_from_source_geometry_data(nav,source)
 var asset="res://assets/maps/offline/arena.res";ResourceSaver.save(nav,asset)
 var file=FileAccess.open("res://assets/maps/arena-navigation.json",FileAccess.WRITE);file.store_string(JSON.stringify({"asset":asset,"sha256":FileAccess.get_sha256(asset),"basis":"local_training_arena_geometry","polygons":nav.get_polygon_count()},"  ")+"\n");file.close()
 game.queue_free();await process_frame;print("ARENA_NAV ",nav.get_polygon_count());quit()
