extends SceneTree
const Fit=preload("res://scripts/preview_camera.gd")
var failures=[]
var results=[]
func _initialize():call_deferred("run")
func run():
 var path="res://assets/library/characters.json"
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 var viewport=SubViewport.new();viewport.size=Vector2i(180,270);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0,0,0,0);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=0.8;stage.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;stage.add_child(light)
 var camera=Camera3D.new();camera.fov=35;stage.add_child(camera)
 var output=ProjectSettings.globalize_path("res://../docs/review/characters-015");DirAccess.make_dir_recursive_absolute(output)
 for entry in data.characters:
  if entry.get("available",false) or not entry.get("engineImported",false) or entry.has("exclusionReason"):continue
  var accepted=true;var forms=[]
  for form in ["human","wolf"]:
   var info=entry[form]
   if not ResourceLoader.exists(info.asset) or FileAccess.get_sha256(info.asset)!=info.sha256:failures.append(entry.id+form+" hash/import");accepted=false;continue
   var holder=Node3D.new();stage.add_child(holder)
   var model=load(info.asset).instantiate();holder.add_child(model)
   for mesh in model.find_children("*","MeshInstance3D",true,false):
    if str(mesh.name).to_lower().begins_with("tattoo"):mesh.hide()
   var players=model.find_children("*","AnimationPlayer",true,false);var skeletons=model.find_children("*","Skeleton3D",true,false)
   if players.is_empty() or skeletons.is_empty():failures.append(entry.id+form+" skeleton/animation");accepted=false;holder.queue_free();await process_frame;continue
   var animation=players[0];var skeleton=skeletons[0]
   for clip in info.clips:
    if not animation.has_animation(clip):failures.append(entry.id+form+clip);accepted=false;continue
    animation.play(clip)
    for fraction in [0.0,0.5,0.99]:
     animation.seek(animation.get_animation(clip).length*fraction,true)
     for i in range(skeleton.get_bone_count()):
      if not skeleton.get_bone_global_pose(i).is_finite():failures.append(entry.id+form+" nonfinite pose");accepted=false;break
   animation.play("idle");animation.advance(0.1);animation.pause()
   var bounds=Fit.frame(camera,holder,Vector2(viewport.size))
   if bounds.size.y<0.5:accepted=false;failures.append(entry.id+form+" degenerate bounds")
   for i in range(3):await process_frame
   await RenderingServer.frame_post_draw
   var image=viewport.get_texture().get_image();var used=image.get_used_rect()
   var target=output.path_join(entry.id+"-"+form+".png")
   if used.size.x<12 or used.size.y<40 or image.save_png(target)!=OK:accepted=false;failures.append(entry.id+form+" empty rendering")
   forms.append({"form":form,"assetSha256":info.sha256,"captureSha256":FileAccess.get_sha256(target),"path":target.trim_prefix(ProjectSettings.globalize_path("res://..").trim_suffix("/" )+"/"),"clips":info.clips.size(),"boundsHeight":bounds.size.y})
   stage.remove_child(holder);holder.queue_free();await process_frame
  if accepted:entry.available=true;entry.visualValidation="source_engine_render_015"
  results.append({"id":entry.id,"passed":accepted,"forms":forms});print("CHARACTER_ADMISSION ",entry.id," ",accepted)
 var report={"passed":failures.is_empty(),"models":results,"failures":failures,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false}
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/character-admission-015.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
 file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data,"  ")+"\n");file.close()
 viewport.queue_free();await process_frame;print("CHARACTER_ADMISSION_QA ",results.size()," failures=",failures);quit(0 if failures.is_empty() else 1)
