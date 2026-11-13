extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=4):
 for i in range(n):await process_frame
func room(team):
 game.local_room={"mode":3000,"map":26,"team":team,"allyBots":0,"enemyBots":0,"roundGoal":9,"matchSeconds":180};check(game.start_round(),"Source destruction starts");await frames();game.player.set_physics_process(false);game.player.velocity=Vector3.ZERO;game.destruction.advance(10)
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 check(game.economy.mutation_cost("normal")==50 and game.economy.mutation_cost("power")==250 and game.economy.mutation_cost("guardian")==900 and game.economy.mutation_cost("ghost")==500,"Mutation card prices match both readable source video frames")
 var presentation=game.bomb_presentation;var spec=presentation.specs
 check(is_equal_approx(float(spec.selectSeconds)+float(spec.installEventSeconds),float(spec.plantSeconds)),"Plant deadline is original Select plus INSTALL_TIMEBOMB")
 check(spec.sourcePlantEvents.any(func(e):return str(e.key).contains("INSTALL_TIMEBOMB") and int(e.timeMs)==4667),"Device carries the original installation event")
 check(presentation.held.find_children("*","MeshInstance3D",true,false).size()==4,"Original hands, LED, body and assembly mesh imported")
 check(presentation.anim.has_animation("select") and presentation.anim.has_animation("plant") and not presentation.anim.has_animation("defuse"),"Source clips remain distinct from unresolved defuse hand animation")
 for row in [spec,spec.world]:check(FileAccess.get_sha256(row.asset)==row.sha256,"Device/world bytes match source conversion record")
 await room("red")
 var d=game.destruction;check(is_equal_approx(float(d.tuning.plantSeconds),5.333),"Runtime uses source timing")
 game.player.position=d.site_position(d.sites[0]);Input.action_press("interact");d.advance(0.3);await frames()
 check(game.using_bomb() and presentation.operating and presentation.held.visible and not game.player.viewmodel.visible,"Starting plant equips original device and hides firearm")
 check(presentation.anim.assigned_animation=="select","Source equip clip precedes assembly")
 var ammo=game.ammo;game.attack();game.reload_weapon();check(game.ammo==ammo and game.reloading==0,"Device interaction blocks firing and reload")
 d.advance(1.1);await frames();check(presentation.anim.assigned_animation=="plant" and presentation.history.has("sound_key 10"),"Original assembly animation triggers its source sound event")
 Input.action_release("interact");d.advance(0.1);await frames()
 check(not presentation.operating and not presentation.held.visible and game.player.viewmodel.visible,"Cancel restores current firearm and clears device")
 check(d.progress==0 and game.match_sp==0,"Cancelled device cannot commit objective or reward")
 Input.action_press("interact");d.advance(float(d.tuning.plantSeconds));Input.action_release("interact");await frames()
 check(d.planted and presentation.world.visible and presentation.history.count("INSTALL_TIMEBOMB")==1,"Install commits one actual world bomb and one event")
 check(presentation.game.source_hud.bomb_clock.visible and not presentation.game.source_hud.timer_view.visible,"Plant replaces the round clock immediately without overlapping countdowns")
 check(game.match_sp==50 and game.economy.earned==50,"Plant reward is credited once in the result ledger")
 d.fuse=0.01;d.advance(0.02);await frames(2)
 check(d.phase=="between" and not presentation.world.visible,"Explosion removes physical bomb during round result")
 var effects=game.clientfx.active.filter(func(n):return is_instance_valid(n) and not n.is_queued_for_deletion() and n.round_effect)
 check(not effects.is_empty(),"Original explosion survives the round-result transition")
 await frames(3);check(is_instance_valid(effects[0]) and effects[0].elapsed>0,"Round explosion advances beyond the winning frame")
 await room("blue");d=game.destruction;d.planted=true;d.bomb=game.player.position;d.fuse=40
 Input.action_press("interact");d.advance(2);await frames()
 check(not presentation.held.visible and game.source_hud.bomb_progress.visible,"Defuse has its own progress without replaying plant hands")
 check(game.source_hud.defuse_label.visible and (game.source_hud.bomb_progress.global_position/game.source_hud.get_viewport_rect().size).distance_to(Vector2(170.0/640,227.0/360))<.003,"Defuse progress and label use the measured source video area while the firearm stays visible")
 d.advance(3.1);Input.action_release("interact");await frames()
 check(d.wins.blue==1 and game.match_sp==50,"Defuse event and reward resolve once")
 await room("blue");d=game.destruction;game.enemy_defeated();game.match_stats.headshots=2;d.wins.blue=8;d.finish("blue","Maç kazanıldı");await frames()
 check(not game.running and game.last_result.roundScores.blue==9 and game.last_result.kills==1,"Match snapshot separates round wins from kills")
 check(game.last_result.walletRewards.gp==10 and game.last_result.earnedSp==100,"Award cards use credited local values, not invented PC rewards")
 var wallet=game.wallet.duplicate();var ui=game.pc_panel
 check(ui.result_tab=="summary" and not ui.links.has("Yeniden oyna"),"Source result opens four-card overview without extra menu buttons")
 ui.links.ResultDetails.pressed.emit();await frames();check(ui.result_tab=="details" and game.last_result.stats.headshots==2 and game.wallet==wallet,"Source Details opens immutable stats without another credit")
 ui.links.ResultSummary.pressed.emit();await frames();check(ui.result_tab=="awards" and game.wallet==wallet,"Source Back returns to the award overview")
 ui.links.Confirm.pressed.emit();await frames();check(game.pc_panel.page=="room" and game.local_room.roundGoal==9 and game.local_room.team=="blue","Result returns to the configured room")
 game.local_room={"mode":3000,"map":26,"team":"red","allyBots":1,"enemyBots":1,"roundGoal":9,"matchSeconds":180};game.start_round();await frames();game.player.set_physics_process(false);game.destruction.advance(10)
 for bot in game.enemies.get_children():bot.set_physics_process(false)
 var friend=game.enemies.get_children().filter(func(a):return a.team=="red")[0];var enemy=game.enemies.get_children().filter(func(a):return a.team=="blue")[0];var identity=enemy.roster_id
 friend.damage(10000,{"actor":"bot","attackerTeam":"blue","name":enemy.display_name,"rosterId":identity});enemy.damage(10000)
 check(game.match_roster[identity].kills==1 and game.match_roster[identity].deaths==1 and game.match_roster.player.kills==1,"Detailed roster records actual bot and player eliminations")
 game.destruction.finish("red","Tur");game.destruction.advance(5);await frames()
 var next=game.enemies.get_children().filter(func(a):return not a.is_queued_for_deletion() and a.team=="blue")[0]
 check(next.roster_id==identity and game.match_roster[identity].kills==1,"Bot identity and stats survive a new round")
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-022-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));f.close()
 game.queue_free();await frames();print("MOBILE_022_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
func _initialize():call_deferred("run")
