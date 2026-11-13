extends SceneTree
var game
var checks=0
var failures=[]
var muzzle_groups={}
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func frames(n=3):
 for i in range(n):await process_frame
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 var lights=game.native_map_lighting
 check(lights.catalog.maps.size()==34,"All selected source maps have lighting streams")
 var previews=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"))
 for record in previews:
  var scene=load(record.previewAsset).instantiate();root.add_child(scene)
  var meshes=scene.find_children("*","MeshInstance3D",true,false)
  var before=scene.find_children("*","CollisionShape3D",true,false).size()
  var count=lights.apply(scene,int(record.number));var source=lights.catalog.maps[str(int(record.number))]
  check(count==int(source.vertices) and count>0,"Native render stream "+str(record.number))
  check(scene.get_meta("native_lightmap_count",0)==int(source.decodedLightmaps),"Native decoded atlas binding "+str(record.number))
  check(meshes.all(func(m):return not m.visible) and scene.get_node("NativeSourceLighting").visible,"Exactly one visible geometry "+str(record.number))
  check(before==scene.find_children("*","CollisionShape3D",true,false).size() and lights.apply(scene,int(record.number))==0,"Lighting preserves collision and is idempotent "+str(record.number))
  scene.queue_free();await frames(1)
 game.local_room={"mode":0,"map":0,"title":"stable030","team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.match_flow.advance_match(2);game.player.set_physics_process(false)
 var identity=game.bot_roster.identity(game,"red",0).duplicate(true)
 game.book.selected_characters.red="pair-model0";game.profile_name="ChangedLocal030"
 check(identity==game.bot_roster.identity(game,"red",0),"Player loadout and nickname edits preserve room bot identity")
 game.spawn_enemy("human","normal","red");await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false)
 var missing=[];var missing_sockets=[]
 for weapon in game.bot_roster.arsenal.values():
  bot.prepare_weapon(weapon);await frames(1)
  if weapon.hhMuzzleFx=="":continue
  var flash=weapon.sockets.filter(func(s):return s.name=="Flash")
  var skel=bot.weapon.find_children("*","Skeleton3D",true,false)[0]
  var effect=bot.play_native_muzzle()
  if game.clientfx.canonical(weapon.hhMuzzleFx)=="":
   missing.append(weapon.itemId);check(effect==null,"Absent native rocket effect remains diagnosed "+weapon.name);continue
  if flash.is_empty():
   missing_sockets.append(weapon.itemId);check(effect==null,"Absent source Flash socket remains diagnosed "+weapon.name);continue
  check(load("res://scripts/native_socket_bone.gd").find(skel,flash[0],weapon.bones)>=0,"Verified native Flash bone "+weapon.name)
  check(effect!=null and effect.get_parent()==bot and effect.actor==null,"World muzzle attaches to owning bot "+weapon.name)
  if effect==null:continue
  muzzle_groups[effect.group]=true;effect.set_process(false);effect._process(.005)
  var particles=effect.parts.filter(func(p):return p.node is CPUParticles3D)
  for part in particles:
   var keys=part.spec.properties.get("Ck",[])
   if not keys.is_empty():check(is_equal_approx(part.node.color_ramp.sample(0).a,1.0-float(keys[0][4])),"Native muzzle opacity "+weapon.name)
   check(part.node.scale_amount_curve!=null,"Individual particle lifetime scale "+weapon.name)
  bot.position.x+=.2;bot.rotation.y+=.1;effect._process(.005)
  check(effect.native_attachment()==bot and effect.global_position.is_finite(),"Moving animated muzzle parent "+weapon.name)
  effect.queue_free();await frames(1)
 check(muzzle_groups.size()==23 and missing.size()==3 and missing_sockets.size()==1,"Twenty-three verified HH groups; three missing groups and one missing source socket retained")
 var survivor=game.bot_roster.identity(game,"blue",0).duplicate(true);game.removed_bot_ids.append("red-0")
 check(survivor==game.bot_roster.identity(game,"blue",0),"Kicking another bot preserves survivor equipment")
 game.queue_free();await frames()
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-030-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"nativeLightedMaps":34,"nativeHhMuzzleGroups":muzzle_groups.size(),"missingHhMuzzleProfiles":missing,"missingHhSockets":missing_sockets,"physicalAndroidDeviceTested":false},"  ")+"\n");f.close();print("MOBILE_030_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
