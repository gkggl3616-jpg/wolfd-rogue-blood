extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for _i in range(n):await process_frame
func capture(name,settle=5):
 await frames(settle);await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func freeze():
 game.player.set_physics_process(false)
 for bot in game.enemies.get_children():
  bot.set_physics_process(false);bot.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;bot.source_events.set_process(false)
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);game.wallet.gp=95
 game.show_home();await capture("level-1-existing-rank-and-gp-029")
 game.local_room={"mode":0,"title":"Kurt ve Bot Kontrolü","map":0,"team":"blue","capacity":16,"allyBots":4,"enemyBots":4};game.pc_panel.navigate("room");await capture("eight-distinct-ready-room-identities-029")
 game.local_room.allyBots=0;game.local_room.enemyBots=0;game.start_round();await frames(65);game.match_flow.advance_match(2);freeze();var p=game.player
 if p.is_wolf:p.switch_form(true)
 p.position=Vector3(0,.05,6);p.rotation.y=0;p.yaw=0;p.pitch=0;p.pivot.rotation.x=0
 for team in ["red","blue"]:
  for slot in range(4):game.spawn_enemy("human","normal",team)
 await frames();freeze()
 var bots=game.enemies.get_children().filter(func(n):return not n.is_queued_for_deletion())
 for i in range(bots.size()):
  var bot=bots[i]
  for j in range(bots.size()):bots[j].position=Vector3(-8+j*2,.02,-4)
  bot.position=Vector3(0,.02,2.5);bot.rotation.y=PI;bot.play("attack");bot.anim.seek(.15,true)
  game.source_hud.refresh_from_game();await capture("native-hand-"+bot.roster_id+"-"+bot.display_name.validate_filename()+"-"+bot.weapon_data.name.validate_filename()+"-029")
 for i in range(bots.size()):bots[i].position=Vector3(-7+i*2,.02,-1);bots[i].rotation.y=PI;bots[i].play("idle");bots[i].anim.seek(.2,true)
 await capture("eight-distinct-characters-and-source-weapons-029")
 for bot in bots:bot.queue_free()
 await frames();game.spawn_enemy("human","hard","red");await frames();freeze();var bot=game.enemies.get_child(0);bot.position=Vector3(-6,.1,7);bot.rotation.y=0;p.position=Vector3(0,.1,-8);game.health=1000;bot.roster_identity=bot.roster_identity.duplicate(true);bot.roster_identity.role="flanker";bot.opponent=p;bot.has_target=true;bot.last_known=p.position;bot.sees_player=true;bot.reaction=0
 p.position=Vector3(0,.1,11);p.yaw=0;p.rotation.y=0;bot.last_known=p.position;bot.rotation.y=PI;bot.set_physics_process(true);bot.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE;bot.source_events.set_process(true)
 await capture("bot-tactical-approach-029",35);await capture("bot-moving-fire-and-reposition-029",65);bot.set_physics_process(false);game.health=100;bot.queue_free();await frames()
 game.show_home();game.book.selected_characters.blue="pair-model1";game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.match_flow.advance_match(2);freeze();p.position=Vector3(-6,.02,8);p.rotation.y=0;p.yaw=0;p.pitch=-.12;p.pivot.rotation.x=p.pitch;p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.source_events.set_process(false)
 game.inbox.state.powerSlots.claw="16018";p.play_clip("idle");p.anim.seek(.2,true);game.source_hud.refresh_from_game();await capture("purple-claw-without-ft-no-hand-glow-029")
 game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.use_power("energy");p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await capture("ft-active-original-health-cost-029",30)
 game.advance_power_effects(1);game.source_hud.refresh_from_game();await capture("ft-one-second-percent-health-tick-029")
 game.advance_power_effects(9);p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await capture("ft-expired-hand-glow-removed-029",30)
 p.claw_trail.set_process(false);p.claw_trail.begin();p.claw_trail.source_window(1,true);p.anim.play("attack",0);p.anim.advance(0)
 for i in range(7):
  p.anim.seek(.05+i*.025,true);p.anim.advance(0);await frames(1);p.claw_trail._process(.016)
 await capture("player-source-claw-world-trail-029")
 p.claw_trail.finish();p.claw_trail._process(.06);await capture("player-source-claw-tail-fade-029");p.claw_trail._process(.2);await capture("player-source-claw-tail-expired-029");p.claw_trail.set_process(true)
 game.spawn_enemy("wolf","normal","red");await frames();freeze();bot=game.enemies.get_child(0);bot.position=Vector3(-3,.02,6.3);bot.rotation.y=PI;bot.claw_trail.set_process(false)
 for clip in ["attack","attack_right"]:
  bot.anim.play(clip,0);bot.anim.advance(0);bot.claw_trail.begin();bot.claw_trail.source_window(1 if clip=="attack" else 0,true)
  for i in range(7):
   bot.anim.seek(.05+i*.025,true);bot.anim.advance(0);await frames(1);bot.claw_trail._process(.016)
  await capture("npc-native-"+clip+"-claw-trail-029");bot.claw_trail.clear()
 bot.claw_trail.set_process(true);bot.queue_free();await frames();game.wallet.gp=95;game.match_wallet_start=game.wallet.duplicate();game.enemy_defeated({"target":"QA bot"});game.end_round("Seviye ilerlemesi");game.pc_panel.result_tab="awards";game.pc_panel.refresh();await capture("actual-kill-level-2-rank-result-progress-029")
 game.show_home();await capture("saved-gp-level-2-header-029");game.pc_panel.navigate("profile");await capture("profile-existing-rank-level-2-029");game.pc_panel.navigate("rankbook");await capture("existing-rank-level-list-029")
 game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"apkProduced":false},"  "));file.close();quit()
