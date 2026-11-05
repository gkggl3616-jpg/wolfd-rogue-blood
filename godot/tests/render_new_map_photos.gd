extends SceneTree
func _initialize():call_deferred("run")
func run():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/photos.json"))
 var previews=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"))
 var viewport=SubViewport.new();viewport.size=Vector2i(320,180);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("7995ad");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=0.9;stage.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);stage.add_child(light)
 var camera=Camera3D.new();camera.fov=80;stage.add_child(camera)
 for row in previews:
  if data.maps.any(func(photo):return int(photo.number)==int(row.number)):continue
  var model=load(row.previewAsset).instantiate();stage.add_child(model)
  var anchor=row.startPoints[0];var p=anchor.position;camera.position=Vector3(p[0],p[1]+1.6,p[2]);camera.rotation=Vector3(-0.05,float(anchor.yaw),0)
  for i in range(5):await process_frame
  await RenderingServer.frame_post_draw
  var asset="res://assets/maps/thumbnails/%d.png" % int(row.number);var error=viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(asset))
  if error!=OK:push_error("Map preview save failed");quit(1);return
  data.maps.append({"number":row.number,"asset":asset,"sha256":FileAccess.get_sha256(asset),"source":row.previewAsset,"sourceSha256":row.sha256,"kind":"rendered_world_preview","note":"Actual converted map rendered at source spawn. Original PC photograph unavailable from remote archive during this update."})
  print("MAP_PHOTO_RENDER ",row.number);stage.remove_child(model);model.queue_free();await process_frame
 data.association="Original 19 PC thumbnails retain exact attribute associations. Fifteen added worlds use labelled Godot renders of their actual geometry."
 var file=FileAccess.open("res://assets/maps/photos.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"  ")+"\n");file.close()
 viewport.queue_free();await process_frame;quit()
