extends SceneTree

func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/ui/form-icons")
	var entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/library/characters.json")).characters
	var pair=entries.filter(func(entry):return entry.id=="pair-model0")[0]
	var results=[]
	for form in ["human","wolf"]:
		var view=SubViewport.new();view.size=Vector2i(96,96);view.transparent_bg=true;view.own_world_3d=true
		view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var model=load(pair[form].asset).instantiate();model.rotation.y=-PI/6;view.add_child(model)
		var white=StandardMaterial3D.new();white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;white.albedo_color=Color.WHITE
		for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.material_override=white
		var players=model.find_children("*","AnimationPlayer",true,false)
		if not players.is_empty():players[0].play("idle");players[0].advance(0)
		for i in range(3):await process_frame
		var bounds=AABB();var found=false
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree():continue
			var box=mesh.global_transform*mesh.get_aabb()
			bounds=bounds.merge(box) if found else box;found=true
		var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=maxf(bounds.size.y,bounds.size.x)*1.13
		camera.position=bounds.get_center()+Vector3(0,0,10);view.add_child(camera)
		camera.look_at(bounds.get_center(),Vector3.UP)
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		var image=view.get_texture().get_image();image.resize(64,64,Image.INTERPOLATE_LANCZOS)
		var asset="res://assets/ui/form-icons/"+form+".png"
		if image.save_png(asset)!=OK:push_error("Form icon save failed");quit(1);return
		results.append({"form":form,"asset":asset,"sha256":FileAccess.get_sha256(asset),"model":pair[form].asset,"modelSha256":FileAccess.get_sha256(pair[form].asset),"basis":"derived_source_model_silhouette","originalPcHudSprite":false})
		root.remove_child(view);view.queue_free();await process_frame
	var file=FileAccess.open("res://assets/ui/form-icons.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  ")+"\n");file.close();print("FORM_ICONS_QA ",results.size());quit()
