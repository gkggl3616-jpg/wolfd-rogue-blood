extends SceneTree
const Fit=preload("res://scripts/preview_camera.gd")
func _initialize():call_deferred("run")
func run():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/character-portraits.json"))
 var viewport=SubViewport.new();viewport.size=Vector2i(420,150);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var environment=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color(0,0,0,0);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_energy=0.8;environment.environment=env;stage.add_child(environment)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;stage.add_child(light)
 var camera=Camera3D.new();camera.fov=35;stage.add_child(camera)
 for id in data.portraits:
  var entry=data.portraits[id]
  if entry.kind!="rendered_model_preview":continue
  var holder=Node3D.new();stage.add_child(holder)
  var model=load(entry.model).instantiate();holder.add_child(model)
  for animation in model.find_children("*","AnimationPlayer",true,false):
   if animation.has_animation("idle"):animation.play("idle");animation.advance(0.1)
  var bounds=Fit.frame(camera,holder,Vector2(viewport.size))
  var center=holder.to_global(bounds.position+Vector3(bounds.size.x*0.5,bounds.size.y*0.78,bounds.size.z*0.5))
  var distance=bounds.size.y*0.52*0.6/tan(deg_to_rad(camera.fov)*0.5)+bounds.size.z*0.5
  camera.global_position=center+Vector3(0,0,distance);camera.look_at(center)
  for i in range(5):await process_frame
  await RenderingServer.frame_post_draw
  var result=viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(entry.asset))
  print("PORTRAIT ",id," ",result)
  stage.remove_child(holder);holder.queue_free();await process_frame
 viewport.queue_free();await process_frame;quit()
