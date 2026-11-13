extends SceneTree
var out="/workspace/scratch/airborne-gallery"
func _initialize():
 if not OS.get_cmdline_user_args().is_empty():out=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(out);call_deferred("run")
func run():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/library/characters.json"))
 var viewport=SubViewport.new();viewport.size=Vector2i(320,320);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.own_world_3d=true;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var world=WorldEnvironment.new();var environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("10171b");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_energy=0.8;world.environment=environment;stage.add_child(world)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;stage.add_child(light)
 var camera=Camera3D.new();camera.fov=45;stage.add_child(camera)
 for row in data.characters:
  if row.get("available")!=true:continue
  var model=load(row.wolf.asset).instantiate();stage.add_child(model)
  var anim=model.find_children("*","AnimationPlayer",true,false)[0];anim.play("airborne_attack");anim.seek(anim.get_animation("airborne_attack").length*0.35,true);anim.pause()
  await process_frame
  var skeleton=model.find_children("*","Skeleton3D",true,false)[0]
  var box=AABB();var first=true
  for bone in range(skeleton.get_bone_count()):
   var point=skeleton.to_global(skeleton.get_bone_global_pose(bone).origin)
   if first:box=AABB(point,Vector3.ZERO);first=false
   else:box=box.expand(point)
  box=box.grow(0.25)
  var center=box.get_center();var distance=maxf(box.size.y,box.size.x)*0.65/tan(deg_to_rad(camera.fov)*0.5)+box.size.z*0.5
  camera.global_position=center+Vector3(distance*0.65,distance*0.15,distance);camera.look_at(center)
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png(out.path_join(row.id+".png"));print("AIR_GALLERY ",row.id)
  stage.remove_child(model);model.queue_free();await process_frame
 viewport.queue_free();await process_frame;quit()
