extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(n=4):
	for i in range(n):await process_frame
func frozen_bots():
	for bot in game.enemies.get_children():bot.set_physics_process(false)
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.local_room={"title":"Sayım kontrolü","mode":0,"map":0,"team":"blue","allyBots":2,"enemyBots":2};game.show_home();game.pc_panel.navigate("room");await frames()
	var flow=game.match_flow;var original=game.local_room.duplicate(true);var serial=game.match_serial
	check(flow.request_start(game.pc_panel) and not flow.request_start(game.pc_panel),"Repeated Start cannot create two countdowns or matches")
	check(flow.phase=="countdown" and not game.running and game.pc_panel.links.StartGame.disabled,"Room stays visible with Start locked during source countdown")
	flow.advance_start(1);check(game.match_serial==serial and flow.countdown==2.5,"Counting does not reset scores or create a premature match")
	game.pc_panel.go_back();check(not flow.starting() and game.local_room==original and game.match_serial==serial,"Back cancels room countdown without losing settings")
	flow.request_start(game.pc_panel);flow.advance_start(3.5);await frames()
	check(flow.phase=="loading" and game.pc_panel.page=="loading" and not game.running,"GO enters a separate source loading screen before preparation")
	check("section/load" in game.pc_panel.source_layouts,"Loading uses the original source layout")
	flow.advance_start(.01);check(not game.running,"Loading screen gets a real frame instead of being skipped")
	flow.advance_start(.01);await frames();game.player.set_physics_process(false);game.spawn_clock=1000
	check(game.running and flow.preparing() and game.selection_active,"Completed load enters initial preparation and equipment selection")
	check(not game.source_hud.timer_view.visible,"Initial HAZIR hides the combat timer")
	var ammo=game.ammo;game.attack();check(game.ammo==ammo and game.match_stats.attacks==0,"Preparation blocks firing")
	check(game.choose_round_loadout(0) and flow.preparing() and not game.is_match_active(),"Early equipment selection cannot bypass HAZIR")
	var time=game.time_left;game._process(2);check(game.time_left==time and flow.ready_left==8,"Initial preparation has its own clock")
	flow.advance_match(8);await frames();game.source_hud.refresh_from_game()
	check(game.is_combat_active() and game.source_hud.start_view.visible,"Preparation ends once with the original BAŞLA graphic")
	flow.advance_match(2)
	game.spawn_enemy("human","normal","blue");game.spawn_enemy("human","normal","red");await frames();frozen_bots()
	var enemy=game.enemies.get_children().filter(func(b):return b.team=="red")[0];var enemy_id=enemy.roster_id
	game.open_interface("scoreboard");await frames();var board=game.match_scoreboard
	check(board.manual and board.visible and not game.menu_open and game.is_match_active(),"Live scoreboard is an overlay and never pauses the match")
	time=game.time_left;game._process(.5);check(is_equal_approx(game.time_left,time-.5),"Round clock continues with scoreboard held open")
	check(board.rows.has("player") and board.rows.has(enemy_id),"Source scoreboard contains actual local and bot identities")
	for dimensions in [Vector2i(1280,720),Vector2i(2160,992),Vector2i(800,450)]:
		root.size=dimensions;await frames();var logical=board.get_viewport_rect().size
		check((board.panel.global_position/logical).distance_to(Vector2(124.0/1024,149.0/768))<.003,"Scoreboard keeps the measured video origin at "+str(dimensions))
		check(Rect2(Vector2.ZERO,logical).encloses(Rect2(board.canvas.get_global_transform()*Vector2(124,149),Vector2(780,562)*board.canvas.scale)),"Both team columns and source footer fit at "+str(dimensions))
	root.size=Vector2i(1280,720);await frames()
	enemy.damage(10000);await frames();board.refresh_rows()
	check(board.rows.has(enemy_id) and board.rows[enemy_id].modulate.r<1 and game.match_roster[enemy_id].deaths==1,"Eliminated bot remains as a grey roster row with its recorded death")
	check(board.rows.player.find_widget("Point").value==str(game.kills),"Live player kills update without rebuilding a menu")
	var tab=InputEventKey.new();tab.physical_keycode=KEY_TAB;tab.pressed=false;game._input(tab);await frames()
	check(not board.manual and not game.menu_open and game.is_combat_active(),"Releasing Tab closes only the scoreboard")
	game.open_round_selection("wolf",true);time=game.time_left;var hp=game.health;game._process(.5);game.take_damage(10)
	check(is_equal_approx(game.time_left,time-.5) and game.is_match_active() and not game.is_combat_active(),"In-match selection blocks the player while the match clock continues")
	check(game.health==hp,"A player choosing respawn equipment cannot receive combat damage")
	game.finish_round_selection();await frames()
	game.show_home();game.local_room={"mode":3000,"map":26,"team":"red","allyBots":2,"enemyBots":1,"roundGoal":9,"matchSeconds":180};game.pc_panel.navigate("room");flow.request_start(game.pc_panel);flow.advance_start(3.5);await frames()
	check(flow.loading_path.ends_with(".glb") or flow.loading_path.ends_with(".tscn"),"Actual source map is requested through threaded loading")
	var deadline=Time.get_ticks_msec()+20000
	while flow.starting() and Time.get_ticks_msec()<deadline:
		flow.advance_start(.02);await frames(1);OS.delay_msec(5)
	check(game.running and game.offline_map_number==26 and is_instance_valid(game.active_map),"Threaded loading starts the selected real map")
	game.player.set_physics_process(false);frozen_bots();var d=game.destruction;d.advance(10);flow.advance_match(2)
	var friend=game.enemies.get_children().filter(func(b):return b.team=="red")[0];var friend_id=friend.roster_id
	d.carrier=friend
	game.pause_game();game.pc_panel.navigate("kick");await frames();var ui=game.pc_panel;var helper=ui.detail_helper
	check("interface/kickwindow" in ui.source_layouts and helper.ids.size()==2 and not helper.ids.has("player"),"Source kick menu lists only actual own-team bots")
	check(ui.links.Confirm.disabled,"Kick requires an explicit selected bot")
	var close=ui.links.Exit;var pixels=(root.get_final_transform()*close.get_global_transform_with_canvas()).get_scale().abs()
	check((close.target_rect().size*pixels).x>=47.9 and (close.target_rect().size*pixels).y>=47.9,"Compact close artwork retains the actual 48-pixel finger target")
	helper.selection.select(0);helper.selection.item_selected.emit(0);helper.view.find_widget("Bug").pressed.emit()
	var kills=game.kills;var sp=game.match_sp;var deaths=d.dead.red
	ui.links.Confirm.pressed.emit();await frames()
	check(game.pc_panel.page=="pause" and game.local_room.allyBots==1 and game.removed_bot_ids.has(friend_id),"Confirm removes one bot from the local room and returns to the game menu")
	check(game.match_roster[friend_id].removalReason=="Bug" and game.kills==kills and game.match_sp==sp and d.dead.red==deaths,"Selected removal reason is retained without fabricating a kill, SP or vote")
	check(d.dropped and d.carrier==null and not d.planted,"Removing the actual carrier drops the single unplanted bomb")
	check(not game.remove_local_bot("player") and not game.remove_local_bot(friend_id),"Self-removal and duplicate removal are rejected")
	var opponent_id=game.match_roster.values().filter(func(r):return r.team=="blue")[0].id
	check(not game.remove_local_bot(opponent_id),"Source own-team menu cannot remove opponents")
	game.resume();d.finish("red","Kontrol turu");d.advance(1.1);await frames()
	check(board.auto_showing() and board.visible and not game.menu_open,"Round result opens the source scoreboard automatically after its banner")
	check(board.scores.red.text=="1","Round scoreboard uses round wins rather than personal kills")
	d.advance(4);await frames();frozen_bots()
	check(d.phase=="prepare" and not board.visible,"Next round closes the automatic scoreboard")
	check(not game.source_hud.timer_view.visible,"Round phase change invalidates cached HUD visibility")
	check(not game.enemies.get_children().any(func(b):return game.actor_alive(b) and b.roster_id==friend_id),"Removed identity cannot silently respawn next round")
	d.advance(10);game.take_damage(10000);await frames(1)
	check(game.spectator.active and game.source_hud.feedback.death_time>0,"Actual player death triggers one red pulse before teammate spectating")
	var pulse=game.source_hud.feedback.death_time;game.take_damage(1);check(game.source_hud.feedback.death_time==pulse,"Repeated damage on a dead player cannot restart death feedback")
	game.show_home();game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames();game.player.set_physics_process(false);game.spawn_clock=1000
	game.player.position=Vector3(0,.05,2);game.player.rotation.y=0;game.player.yaw=0;game.spawn_enemy("wolf","normal","red");await frames();frozen_bots()
	enemy=game.enemies.get_children().filter(func(b):return not b.is_queued_for_deletion())[0];enemy.position=Vector3(0,.05,.4);enemy.health=300;await frames(4)
	game.player.source_events.set_process(false);game.attack();game.player.anim.speed_scale=0;game.player.anim.seek(0,true);var events=game.player.source_events;events._process(0)
	check(not game.player.pending_melee.is_empty() and enemy.health==300,"Source claw attack queues contact without dealing damage at button press")
	var record=game.clientfx.animation_record(game.player,"attack");var contacts=record.get("events",[]).filter(func(e):return str(e.key).to_lower().contains("fire_key"))
	check(not contacts.is_empty(),"Current wolf uses an actual decoded FIRE_KEY")
	if not contacts.is_empty():
		var contact=float(contacts[0].timeMs)/1000
		game.player.anim.seek(contact-.001,true);events._process(0);check(enemy.health==300,"Pre-contact animation cannot deal early damage")
		game.player.anim.seek(contact+.001,true);events._process(0)
		check(enemy.health<300,"Original contact event commits melee damage")
		var after=enemy.health;events.dispatch("FIRE_KEY 1");check(enemy.health==after,"Duplicate animation contact cannot hit twice")
		check(game.clientfx.active.any(func(f):return is_instance_valid(f) and f.group=="Impact_Flesh"),"Confirmed melee contact produces the original hit effect")
		game.player.shot_cooldown=0;game.attack();game.pause_game();game.resume();check(game.player.pending_melee.is_empty(),"Opening a menu cancels a queued melee contact")
	var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-023-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));file.close()
	game.queue_free();await frames();print("MOBILE_023_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
func _initialize():call_deferred("run")
