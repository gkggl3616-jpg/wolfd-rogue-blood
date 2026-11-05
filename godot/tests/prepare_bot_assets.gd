extends SceneTree

func _initialize():call_deferred("run")
func bounds_of(node):
	var result=AABB();var found=false
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.visible:continue
		var box=mesh.global_transform*mesh.get_aabb()
		result=result.merge(box) if found else box;found=true
	return result

func run():
	DirAccess.make_dir_recursive_absolute("res://assets/bots")
	DirAccess.make_dir_recursive_absolute("res://assets/ui/control-icons")
	var source="res://assets/weapons/ak47/viewmodel.glb"
	var original=load(source).instantiate();root.add_child(original)
	var animation=original.find_children("*","AnimationPlayer",true,false)[0]
	animation.play("idle");animation.advance(0)
	for i in range(3):await process_frame
	var gun=Node3D.new();gun.name="Rifle";root.add_child(gun)
	var pivot=Node3D.new();pivot.name="SourcePose";gun.add_child(pivot);pivot.owner=gun
	var magazine
	var triangles=0
	for mesh in original.find_children("*","MeshInstance3D",true,false):
		if not str(mesh.name).begins_with("WT_PV_"):continue
		var baked=mesh.bake_mesh_from_current_skeleton_pose()
		var clean=ArrayMesh.new()
		for surface in range(baked.get_surface_count()):
			var material=mesh.get_active_material(surface)
			if material and str(material.resource_name).to_lower().contains("hand"):continue
			var arrays=baked.surface_get_arrays(surface)
			clean.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			clean.surface_set_material(clean.get_surface_count()-1,material)
			triangles+=baked.surface_get_array_index_len(surface)/3
		if clean.get_surface_count()==0:continue
		var rigid=MeshInstance3D.new();rigid.name=mesh.name;rigid.mesh=clean
		pivot.add_child(rigid);rigid.global_transform=mesh.global_transform;rigid.owner=gun
		if str(mesh.name).contains("_MAG"):magazine=rigid
	var box=bounds_of(gun)
	var scale_factor=0.85/maxf(box.size.x,box.size.z)
	pivot.scale=Vector3(scale_factor,scale_factor,-scale_factor)
	pivot.position=-(pivot.basis*box.get_center())
	var scene=PackedScene.new();scene.pack(gun)
	var asset="res://assets/bots/rifle.scn"
	if ResourceSaver.save(scene,asset)!=OK or magazine==null:push_error("World rifle bake failed");quit(1);return
	var view=SubViewport.new();view.size=Vector2i(128,128);view.transparent_bg=true;view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var photo=MeshInstance3D.new();photo.mesh=magazine.mesh;view.add_child(photo);photo.transform=magazine.global_transform
	for surface in range(photo.mesh.get_surface_count()):
		var material=photo.mesh.surface_get_material(surface)
		if material is StandardMaterial3D:
			var thumbnail_material=material.duplicate();thumbnail_material.metallic=0;thumbnail_material.roughness=0.7;photo.set_surface_override_material(surface,thumbnail_material)
	var env_node=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color(0,0,0,0);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_energy=0.9;env_node.environment=env;view.add_child(env_node)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=1.6;view.add_child(light)
	box=photo.global_transform*photo.get_aabb()
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(box.size.y,maxf(box.size.x,box.size.z))*1.3
	view.add_child(camera);camera.position=box.get_center()+Vector3(0.6,0.2,1).normalized()*2;camera.look_at(box.get_center(),Vector3.UP)
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var icon="res://assets/ui/control-icons/reload.png"
	var pixels=view.get_texture().get_image();pixels.get_region(pixels.get_used_rect()).save_png(icon)
	var weapon=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/ak47/weapon.json"))
	var info={"asset":asset,"sha256":FileAccess.get_sha256(asset),"source":source,"sourceSha256":FileAccess.get_sha256(source),
		"excludedFirstPersonHands":true,"triangles":triangles,"capacity":int(weapon.shotsPerClip),"fireInterval":float(weapon.fireIntervalMs)/1000.0,"reloadSeconds":float(weapon.reloadSeconds),
		"fireSound":weapon.sounds.fire.asset,"reloadSound":weapon.sounds.reload.asset,"magazineIcon":icon,"magazineIconSha256":FileAccess.get_sha256(icon),
		"worldLengthMetres":0.85,"originalPcWorldModel":false}
	var file=FileAccess.open("res://assets/bots/catalog.json",FileAccess.WRITE);file.store_string(JSON.stringify(info,"  ")+"\n");file.close()
	root.remove_child(original);original.queue_free();root.remove_child(gun);gun.queue_free();view.queue_free();await process_frame
	print("BOT_ASSET_BAKE ",triangles," triangles; actual source magazine rendered");quit()
