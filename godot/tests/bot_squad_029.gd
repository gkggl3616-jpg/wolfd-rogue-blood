extends SceneTree
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=3):
 for _i in range(n):await physics_frame
func run():
 var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.set_process(false);game.player.set_physics_process(false);game.health=500
 for team in ["red","blue"]:
  for slot in range(4):check(game.spawn_enemy("human","normal",team),"Real squad spawn "+team+str(slot))
 var traces={};var refs={}
 for bot in game.enemies.get_children():
  refs[bot.roster_id]=weakref(bot);traces[bot.roster_id]={"name":bot.display_name,"character":bot.character_info.id,"weapon":bot.weapon_data.itemId,"weaponName":bot.weapon_data.name,"origin":bot.position,"maximumTravel":0.0,"shots":0,"minimumHealth":bot.health,"recoveries":0}
 var names={};var characters={};var weapons={}
 for row in traces.values():names[row.name]=true;characters[row.character]=true;weapons[row.weapon]=true
 check(traces.size()==8 and names.size()==8 and characters.size()==8 and weapons.size()==8,"All eight live actors have distinct names, characters and primary weapons")
 for i in range(480):
  await physics_frame
  for id in refs:
   var bot=refs[id].get_ref()
   if not is_instance_valid(bot):continue
   var row=traces[id];row.maximumTravel=maxf(row.maximumTravel,bot.position.distance_to(row.origin));row.shots=maxi(row.shots,bot.shots_fired);row.minimumHealth=mini(row.minimumHealth,bot.health);row.recoveries=bot.tactics.recoveries
 check(traces.values().filter(func(row):return row.maximumTravel>1).size()>=6,"At least six autonomous squad actors make real physical route progress")
 check(traces.values().filter(func(row):return row.shots>0).size()>=4,"Several different weapons fire during the real squad encounter")
 check(game.health<500 or traces.values().any(func(row):return row.minimumHealth<100),"The encounter produces real collision-tested hostile damage")
 game.menu_open=true;var paused={}
 for bot in game.enemies.get_children():
  if not bot.is_queued_for_deletion():paused[bot.roster_id]=bot.position
 await frames(20)
 check(game.enemies.get_children().all(func(bot):return bot.is_queued_for_deletion() or bot.position==paused.get(bot.roster_id,bot.position)),"Menu freezes all remaining squad actors")
 for id in traces:traces[id].origin=[traces[id].origin.x,traces[id].origin.y,traces[id].origin.z]
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/bot-squad-029-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"simulatedPhysicsSeconds":8,"traces":traces,"botHealth":100,"botDirectDamage":8,"physicalAndroidDeviceTested":false,"apkProduced":false},"  ")+"\n");file.close();game.queue_free();await frames();print("BOT_SQUAD_029_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
