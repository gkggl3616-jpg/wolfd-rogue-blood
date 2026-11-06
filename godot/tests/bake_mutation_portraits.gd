extends SceneTree
const Fit=preload("res://scripts/preview_camera.gd")
func _initialize():call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func run():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mutations/catalog.json"))
	var view=SubViewport.new();view.size=Vector2i(256,256);view.own_world_3d=true;view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var stage=Node3D.new();view.add_child(stage)
	var world=WorldEnvironment.new();var environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(0,0,0,0);environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=0.7;world.environment=environment;stage.add_child(world)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.5;stage.add_child(light)
	var camera=Camera3D.new();camera.fov=45;stage.add_child(camera)
	var normal=JSON.parse_string(FileAccess.get_file_as_string("res://assets/roster.json")).characters[0].wolf.asset
	var models=catalog.models.duplicate();models.append({"id":"normal","team":"blue","asset":normal})
	for entry in models:
		var model=load(entry.asset).instantiate();stage.add_child(model);model.rotation.y=-0.3
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).to_lower().begins_with("tattoo"):mesh.hide()
		var animator=model.find_children("*","AnimationPlayer",true,false)[0];animator.play("idle");animator.advance(0)
		Fit.frame(camera,model,Vector2(view.size));await frames();await RenderingServer.frame_post_draw
		var file="res://assets/mutations/%s-%s.png" % [entry.id,entry.team];var error=view.get_texture().get_image().save_png(file)
		if error!=OK:quit(1);return
		entry.portrait=file;entry.portraitSha256=FileAccess.get_sha256(file)
		print("PORTRAIT ",file);stage.remove_child(model);model.queue_free();await frames(1)
	var file=FileAccess.open("res://assets/mutations/catalog.json",FileAccess.WRITE);file.store_string(JSON.stringify(catalog,"  ")+"\n");file.close()
	view.queue_free();await frames();quit()
