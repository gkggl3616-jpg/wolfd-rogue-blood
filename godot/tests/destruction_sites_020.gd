extends SceneTree
func _initialize():call_deferred("run")
func frames(n=6):
 for i in range(n):await process_frame
func run():
 var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);var results=[];var failures=[]
 for number in [26,31,44,87,89,42]:
  game.local_room={"mode":3000,"map":number,"team":"red","allyBots":0,"enemyBots":0};game.start_round();await frames()
  for site in game.destruction.sites:
   var origin=game.destruction.site_position(site);var point=site.get("approach",site.position);var floor=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,Vector3(point[0],point[1],point[2]));var delta=origin.distance_to(floor)
   var access={}
   for team in ["red","blue"]:
    var starts=game.team_start_points(game.map_catalog.offline_record(number),team)
    access[team]=starts.any(func(start):return game.navigation_graph.connected(NavigationServer3D.map_get_closest_point(game.offline_navigation_map,Vector3(start.position[0],start.position[1],start.position[2])),floor))
   var row={"pathFromSpawns":access,"map":number,"site":site.name,"distanceToNavigation":delta,"sourceRadius":site.radius,"reachable":delta<float(site.radius)+1 and access.red and access.blue};results.append(row)
   if not row.reachable:failures.append(row)
 game.queue_free();await frames();var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/destruction-sites-020-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"sites":results,"failures":failures,"passed":failures.is_empty()},"  "));f.close();print("SOURCE_BOMB_SITE_QA ",results.size()," failures=",failures);quit(0 if failures.is_empty() else 1)
