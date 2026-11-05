extends SceneTree

func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/ui/control-icons")
	var entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/library/characters.json")).characters
	var pair=entries.filter(func(entry):return entry.id=="pair-model0")[0]
	var results={}
	for row in [["jump","human","jump",0.45],["crouch","human","crouch",0.5],["sprint","human","run",0.2],["roar","wolf","roar",0.35],["roll","wolf","special_attack",0.4]]:
		var view=SubViewport.new();view.size=Vector2i(96,96);view.transparent_bg=true;view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var model=load(pair[row[1]].asset).instantiate();model.rotation.y=-PI/2.4;view.add_child(model)
		var white=StandardMaterial3D.new();white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;white.albedo_color=Color.WHITE
		for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.material_override=white
		var player=model.find_children("*","AnimationPlayer",true,false)[0]
		if not player.has_animation(row[2]):push_error("Control icon source clip missing");quit(1);return
		player.play(row[2]);player.advance(player.get_animation(row[2]).length*row[3]);player.pause()
		for i in range(3):await process_frame
		var box=AABB();var found=false
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if not mesh.visible:continue
			var posed=mesh.bake_mesh_from_current_skeleton_pose()
			var bounds=mesh.global_transform*posed.get_aabb()
			box=box.merge(bounds) if found else bounds;found=true
		var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(box.size.x,box.size.y)*1.15;view.add_child(camera);camera.position=box.get_center()+Vector3(0,0,10);camera.look_at(box.get_center(),Vector3.UP)
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		var asset="res://assets/ui/control-icons/"+row[0]+".png";view.get_texture().get_image().save_png(asset)
		results[row[0]]={"asset":asset,"sha256":FileAccess.get_sha256(asset),"model":pair[row[1]].asset,"clip":row[2],"phase":row[3],"basis":"rendered_source_animation_pose"}
		root.remove_child(view);view.queue_free();await process_frame
	var ui=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/catalog.json"))
	for row in [["fire","wt_interface/item/bullets/7.62.dtx"],["wolf_fire","wt_interface/item/bullets/wolf.dtx"],["strong","wt_interface/item/bullets/power wolf.dtx"],["knife_fire","wt_interface/item/bullets/c.q.c knife.dtx"],["grenade_fire","wt_interface/item/bullets/red grenade.dtx"]]:
		var texture=ui.textures[row[1]]
		var source_image=Image.load_from_file(texture.asset);var used=source_image.get_used_rect()
		results[row[0]]={"asset":texture.asset,"sha256":FileAccess.get_sha256(texture.asset),"sourceSha256":texture.sha256,"source":row[1],"basis":"original_source_texture","region":[used.position.x,used.position.y,used.size.x,used.size.y]}
	results.reload={"asset":"res://assets/ui/control-icons/reload.png","sha256":FileAccess.get_sha256("res://assets/ui/control-icons/reload.png"),"basis":"rendered_source_magazine"}
	var aim=Image.new();aim.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><g fill="none" stroke="white" stroke-width="3"><circle cx="32" cy="32" r="17"/><path d="M32 5V22M32 42V59M5 32H22M42 32H59"/></g></svg>')
	var aim_asset="res://assets/ui/control-icons/aim.png";aim.save_png(aim_asset)
	results.aim={"asset":aim_asset,"sha256":FileAccess.get_sha256(aim_asset),"basis":"native_target_symbol"}
	results.transform={"asset":"res://assets/ui/form-icons/wolf.png","sha256":FileAccess.get_sha256("res://assets/ui/form-icons/wolf.png"),"basis":"rendered_source_model_silhouette"}
	var file=FileAccess.open("res://assets/ui/control-icons.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  ")+"\n");file.close();print("CONTROL_ICONS ",results.size());quit()
