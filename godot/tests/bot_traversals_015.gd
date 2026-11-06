extends SceneTree
var checks=0
var failures=[]
func ensure(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await process_frame;game.set_process(false);game.player.set_physics_process(false)
 var records=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/traversals.json"));var results=[]
 for record in records:
  game.local_room={"mode":0,"map":int(record.number),"team":"blue"};game.start_round();game.player.position+=Vector3.UP*40;game.player.velocity=Vector3.ZERO
  await physics_frame;await physics_frame
  var links=game.active_map.find_children("*","NavigationLink3D",true,false)
  ensure(links.size()==record.links.size(),"All verified links install: "+str(record.number))
  for index in range(links.size()):
   var link=links[index];var spec=link.get_meta("traversal")
   for reversed in ([false,true] if spec.get("bidirectional",true) else [false]):
    var e=spec.feetExit if reversed else spec.feetEntry;var target=spec.feetEntry if reversed else spec.feetExit
    var bot=CharacterBody3D.new();bot.set_script(load("res://scripts/enemy.gd"));bot.game=game;bot.kind="wolf";bot.brain_enabled=false;bot.position=Vector3(e[0],e[1],e[2]);game.enemies.add_child(bot)
    bot.set_physics_process(false);bot.capsule.height=1.2;bot.collider.position.y=0.6
    for i in range(20):bot.velocity.y=-2;bot.move_and_slide();await physics_frame
    bot.begin_link_traversal({"rid":link.get_rid()})
    var began=not bot.link_flight.is_empty();ensure(began,"Launch swept link %d/%d/%s" % [int(record.number),index,str(reversed)])
    if began:
     var seconds=bot.link_flight.seconds;var time=0.0
     while time<seconds+0.02:
      bot._physics_process(1.0/60);time+=1.0/60;await physics_frame
     var error=bot.position.distance_to(Vector3(target[0],target[1],target[2]))
     ensure(error<0.85,"Physical link reaches its landing without teleport: %d/%d/%s" % [int(record.number),index,str(reversed)])
     results.append({"map":record.number,"link":index,"reversed":reversed,"landingError":error})
    game.enemies.remove_child(bot);bot.queue_free();await process_frame
 game.queue_free();await process_frame;await process_frame
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/bot-traversal-validation-015.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"landings":results,"traversalsSha256":FileAccess.get_sha256("res://assets/maps/traversals.json")},"  ")+"\n");file.close()
 print("BOT_TRAVERSALS_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
