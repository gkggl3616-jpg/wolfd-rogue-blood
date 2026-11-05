extends SceneTree
var checks=0
var errors=[]
func _initialize():call_deferred("run")
func ensure(value,title):
	checks+=1
	if not value:errors.append(title);push_error(title)
func frames():
	for i in range(4):await process_frame
func run():
	var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	game.local_room={"mode":0,"map":0,"team":"blue"};game.start_round();game.spawn_clock=9999;game.set_process(false)
	game.enemy_defeated({"target":"QA Bot","headshot":true});game.source_hud.refresh_from_game()
	ensure(game.kills==1 and game.deaths==0,"real kill advances only the player team score")
	ensure(game.kill_feed[0].weaponId==game.current_weapon_id,"kill retains exact weapon identity")
	ensure(game.kill_feed[0].attackerTeam=="blue" and game.kill_feed[0].targetTeam=="red","kill feed keeps team identities")
	ensure(game.source_hud.feed_layer.get_child_count()==4,"kill row renders attacker, weapon, victim and headshot")
	var label=game.source_hud.score_view.find_widget("BlueTeamScore");ensure(str(label.value)=="1","blue score displays the actual local kill count")
	game.take_damage(100,null,{"name":"QA Enemy","weapon":"Tüfek"})
	ensure(game.deaths==1 and game.kill_feed[0].attacker=="QA Enemy","actual lethal bot damage generates death announcement")
	game.show_library("Karakterler");await frames();var ui=game.library_panel
	ensure(ui.preview_model!=null and ui.preview_container.position.y==180,"full body preview uses the new character framing")
	for title in ["N","M","AT","Karakteri kullan"]:ensure(ui.links.has(title),"character action exists: "+title)
	ensure(ui.detail_helper.details.find_children("*","ProgressBar",true,false).size()==4,"stats panel shows four verified local attributes")
	var report={"checks":checks,"passed":errors.is_empty(),"failures":errors};var file=FileAccess.open("res://../docs/human-reference-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close();game.queue_free();await frames();print(JSON.stringify(report));quit(0 if errors.is_empty() else 1)
