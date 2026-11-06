extends SceneTree
const Fit=preload("res://scripts/preview_camera.gd")
const MenuPose=preload("res://scripts/menu_preview.gd")
func _initialize():call_deferred("run")
func run():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/character-portraits.json"));var chars=JSON.parse_string(FileAccess.get_file_as_string("res://assets/library/characters.json")).characters
 var viewport=SubViewport.new();viewport.size=Vector2i(420,450);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage);var environment=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_CLEAR_COLOR;env.background_color=Color(0,0,0,0);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_energy=.8;environment.environment=env;stage.add_child(environment)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;stage.add_child(light);var camera=Camera3D.new();camera.fov=40;stage.add_child(camera)
 for id in data.portraits:
  var entry=data.portraits[id]
  if entry.kind!="rendered_character_card":continue
  var char=chars.filter(func(row):return row.id==id)[0];var holder=Node3D.new();stage.add_child(holder);var model=load(entry.model).instantiate();holder.add_child(model);MenuPose.apply(model,char);Fit.frame(camera,holder,Vector2(viewport.size))
  for i in range(4):await process_frame
  await RenderingServer.frame_post_draw
  var original=viewport.get_texture().get_image();var card=Image.create(420,150,false,Image.FORMAT_RGBA8);var tone=Color("561c1c") if entry.team=="red" else Color("13375b")
  for y in range(150):
   for x in range(420):card.set_pixel(x,y,tone.lerp(Color("080d15"),clampf(absf(x-230)/320.0+float(y)/700,0,1)))
  var body=original.duplicate();body.resize(140,150,Image.INTERPOLATE_LANCZOS);card.blend_rect(body,Rect2i(0,0,140,150),Vector2i(0,0))
  var used=original.get_used_rect();var face=original.get_region(Rect2i(used.position+Vector2i(int(used.size.x*.15),0),Vector2i(maxi(1,int(used.size.x*.7)),maxi(1,int(used.size.y*.35)))))
  var factor=maxf(280.0/face.get_width(),150.0/face.get_height());face.resize(ceili(face.get_width()*factor),ceili(face.get_height()*factor),Image.INTERPOLATE_LANCZOS);card.blend_rect(face,Rect2i((face.get_width()-280)/2,(face.get_height()-150)/2,280,150),Vector2i(140,0))
  var result=card.save_png(ProjectSettings.globalize_path(entry.asset));print("CHARACTER_CARD ",id," ",result)
  stage.remove_child(holder);holder.queue_free();await process_frame
 viewport.queue_free();await process_frame;quit()
