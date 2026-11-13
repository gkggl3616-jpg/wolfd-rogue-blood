extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for _i in range(n):await process_frame
func capture(name,settle=5):
 await frames(settle);await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func equip(name):
 var row=game.book.weapons.filter(func(r):return r.name==name)[0];game.book.acquire(row.id);game.equip_library_weapon(row);game.ammo=game.weapon_capacity();game.reloading=0;game.player.shot_cooldown=0;return row
func freeze():
 game.player.set_physics_process(false)
 for bot in game.enemies.get_children():bot.set_physics_process(false)
func pose():
 var p=game.player;p.position=Vector3(-6,.02,8);p.rotation.y=0;p.yaw=0;p.pitch=-.1;p.pivot.rotation.x=p.pitch
 p.weapon_anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 await capture("login-source-interface-028");game.show_home();await capture("home-source-interface-028")
 game.show_library("Envanter");var ui=game.library_panel
 for name in ["DE-50","AKEI-47 CLASSIC","SUPAS PT","FullMoon"]:
  ui.selected=game.book.weapons.filter(func(r):return r.name==name)[0];ui.detail_helper.info_tab="properties";ui.detail_helper.show_details();await capture("native-properties-"+name.validate_filename()+"-028")
 game.show_home();game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);freeze();game.match_flow.advance_match(2)
 if game.player.is_wolf:game.player.switch_form(true)
 pose();var p=game.player
 for name in ["DE-50","AKEI-47 CLASSIC","SUPAS PT","FullMoon"]:
  equip(name);p.play_weapon_clip("idle",1);p.weapon_anim.seek(.1,true);game.source_hud.refresh_from_game();await capture("native-viewmodel-"+name.validate_filename()+"-028")
 equip("SUPAS PT");game.ammo=3;game.reserve=5;game.reload_weapon();p.weapon_anim.seek(.35,true);game.source_hud.refresh_from_game();await capture("supas-original-shell-insertion-028")
 game.advance_reload(.667);p.weapon_anim.seek(.35,true);game.source_hud.refresh_from_game();await capture("supas-one-shell-added-028")
 game.attack();game.advance_reload(.667);p.weapon_anim.seek(.55,true);game.source_hud.refresh_from_game();await capture("supas-original-finishing-rack-028");game.advance_reload(1)
 for projectile_name in ["HGrenadeTimed","ATGrenadeTimed2","Mine"]:
  var row=game.book.weapons.filter(func(r):return p.native_weapon_rules[r.id].projectile==projectile_name)[0];equip(row.name);p.play_weapon_clip("idle",1);p.weapon_anim.seek(.1,true);game.source_hud.refresh_from_game();await capture(projectile_name+"-held-native-028")
  game.attack();p.weapon_anim.seek(.25,true);await capture(projectile_name+"-native-prefire-028")
  game.advance_pending_throw(game.pending_throw.preSeconds);p.weapon_anim.seek(.15,true);game.advance_pending_throw(.15);game.source_hud.refresh_from_game()
  for shot in game.get_children().filter(func(n):return n.get_script()==load("res://scripts/grenade.gd")):shot.set_physics_process(false)
  await capture(projectile_name+"-native-postfire-028");game.cancel_pending_throw();game.clear_projectiles();game.clientfx.clear();await frames()
 equip("DE-50");p.play_weapon_clip("idle",1);p.weapon_anim.seek(.1,true)
 for name in ["Missile","Arrow","FullMoon","HGrenadeTimed","ATGrenadeTimed2","Mine"]:
  var row=game.book.weapons.filter(func(r):return p.native_weapon_rules[r.id].projectile==name)[0];var shot=game.launch_projectile(p.native_weapon_rules[row.id],row.name);shot.position=p.camera.global_position-p.camera.global_basis.z*1.4+p.camera.global_basis.x*.3;shot.set_physics_process(false);shot.rotation.y=PI/2
  await capture("source-flight-model-"+name+"-028",12);game.clear_projectiles();game.clientfx.clear();await frames()
 for mode in [1022,1023,1024,1025,1026]:
  var maps=game.map_catalog.maps_for_mode(mode,true);game.show_home();game.local_room={"mode":mode,"map":int(maps[0].number),"team":"blue","allyBots":0,"enemyBots":0};game.pc_panel.navigate("room");await capture("source-weapon-mode-room-"+str(mode)+"-028")
  game.start_round();await frames(65);freeze();game.match_flow.advance_match(2);p.weapon_anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  game.spawn_enemy("human","normal","red");await frames();freeze();var bot=game.enemies.get_children().filter(func(n):return not n.is_queued_for_deletion())[0];bot.position=p.position-p.camera.global_basis.z*3.5;bot.position.y=p.position.y;await physics_frame;var ground=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bot.position+Vector3.UP*4,bot.position+Vector3.DOWN*8,1,[p.get_rid(),bot.get_rid()]));
  if not ground.is_empty():bot.position=ground.position+Vector3.UP*.03
  bot.look_at(Vector3(p.position.x,bot.position.y,p.position.z));game.source_hud.refresh_from_game();await capture("source-weapon-mode-bot-"+str(mode)+"-028")
 game.show_home();game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);freeze();game.match_flow.advance_match(2);pose()
 p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.play_clip("idle");p.anim.seek(.2,true);game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.source_hud.refresh_from_game();await capture("ft-before-activation-028")
 game.use_power("energy");p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await capture("ft-active-health-cost-and-hand-effect-028",30)
 game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"apkProduced":false},"  "));file.close();quit()
