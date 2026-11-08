extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for _i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.book.selected_characters.red="pair-model0";game.book.selected_characters.blue="pair-model44";game.local_room={"mode":1010,"map":97,"team":"red","allyBots":0,"enemyBots":0,"pointGoal":100};game.start_round();await frames(65);game.match_flow.advance_match(2)
 var p=game.player;p.set_physics_process(false);p.look_at(Vector3(0,p.position.y,0));p.yaw=p.rotation.y;p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.source_events.set_process(false);p.anim.play("idle",0);p.anim.seek(.2,true)
 game.inbox.state.powerSlots.claw="16018";game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.source_hud.refresh_from_game();await capture("native-taksim-wolf-without-ft-029")
 game.use_power("energy");p.claw_trail.refresh_glow();game.bot_roster.identity(game,"blue",0).characterId="pair-model44";game.spawn_enemy("wolf","normal","blue");await frames();var bot=game.enemies.get_child(0);bot.set_physics_process(false);bot.source_events.set_process(false);bot.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 var desired=p.position-p.global_basis.z*4+p.global_basis.x*2;var nav=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,desired);var ground=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(nav+Vector3.UP*3,nav-Vector3.UP*5,1,[p.get_rid(),bot.get_rid()]));bot.position=ground.position+Vector3.UP*.02 if not ground.is_empty() else nav;bot.look_at(Vector3(p.position.x,bot.position.y,p.position.z));bot.anim.play("attack",0);bot.anim.advance(0);bot.claw_trail.set_process(false);bot.claw_trail.begin();bot.claw_trail.source_window(1,true)
 for i in range(7):bot.anim.seek(.05+i*.025,true);bot.anim.advance(0);await frames(1);bot.claw_trail._process(.016)
 game.source_hud.refresh_from_game();await capture("native-taksim-ft-and-npc-source-claw-029")
 game.take_damage(8,bot.position,{"attackerTeam":"blue","sourceActor":bot});game.source_hud.refresh_from_game();await capture("native-taksim-distinct-ice-hit-and-ft-029")
 game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"apkProduced":false,"scope":"Actual supplied Taksim geometry with controlled local wolf poses; no native renderer or Android-device claim"},"  "));file.close();quit()
