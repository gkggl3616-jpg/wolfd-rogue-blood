extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for i in range(n):await process_frame
func capture(name,settle=5):
 await frames(settle);await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 for record in game.map_catalog.offline_maps():
  game.local_room={"mode":0,"map":int(record.number),"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.match_flow.advance_match(2);game.player.set_physics_process(false);game.source_hud.refresh_from_game();await capture("native-lightmap-map-"+str(int(record.number))+"-030")
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.match_flow.advance_match(2);game.player.set_physics_process(false)
 var p=game.player
 if p.is_wolf:p.switch_form(true)
 p.position=Vector3(0,.05,6);p.yaw=0;p.rotation.y=0;p.pitch=0;p.pivot.rotation.x=0
 game.spawn_enemy("human","normal","red");await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false);bot.source_events.set_process(false);bot.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;bot.position=Vector3(0,.02,2.5);bot.rotation.y=PI
 var seen={}
 for weapon in game.bot_roster.arsenal.values():
  var group=game.clientfx.canonical(weapon.hhMuzzleFx)
  if group=="" or seen.has(group) or not weapon.sockets.any(func(s):return s.name=="Flash"):continue
  seen[group]=true;bot.prepare_weapon(weapon);await frames(1);bot.play("attack");bot.anim.seek(.1,true);var effect=bot.play_native_muzzle();effect.set_process(false);effect._process(.005)
  await capture("npc-native-muzzle-"+group.validate_filename()+"-030",2);effect.queue_free();await frames(1)
 game.queue_free();await frames();var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"scope":"34 source lightmap maps and 23 staged real native third-person muzzle groups"},"  "));f.close();quit()
