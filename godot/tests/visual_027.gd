extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=5):
 for _i in range(n):await process_frame
func capture(name,settle=5):
 await frames(settle);await RenderingServer.frame_post_draw;var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":pixels.save_png(path)==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.show_library("Karakterler");var ui=game.library_panel
 for id in ["pair-model170","pair-model172","pair-model174","pair-model176"]:
  var item=game.book.characters.filter(func(row):return row.id==id)[0];ui.selected=item;ui.preview_wolf=true;ui.detail_helper.show_details()
  for angle in [0,PI]:
   ui.preview_angle=angle;ui.replace_preview(item);await capture("source-og-"+id+("-front-027" if angle==0 else "-back-027"))
 game.show_home();game.book.selected_characters.blue="pair-model1";game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65)
 var p=game.player;p.set_physics_process(false);game.match_flow.advance_match(2);p.position=Vector3(-6,.02,8);p.rotation.y=0;p.yaw=0;p.pitch=-.12;p.pivot.rotation.x=p.pitch;p.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;p.play_clip("idle");p.anim.seek(.2,true)
 game.inbox.state.powerCounts["19502"]=1;game.equip_power_item("19502");game.source_hud.refresh_from_game();await capture("ft-before-activation-027")
 game.use_power("energy");p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await capture("ft-current-health-cost-027",30)
 game.advance_power_effects(1);game.source_hud.refresh_from_game();await capture("ft-first-percent-tick-027")
 game.advance_power_effects(7);game.source_hud.refresh_from_game();await capture("ft-eighth-percent-tick-027")
 game.advance_power_effects(2);p.claw_trail.refresh_glow();game.source_hud.refresh_from_game();await capture("ft-ten-seconds-expired-027",35)
 game.show_home();game.local_room={"mode":0,"map":26,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);p.set_physics_process(false);game.match_flow.advance_match(2)
 if p.is_wolf:p.switch_form(true)
 var covered={}
 for item in game.book.weapons:
  var row=p.muzzle_data.items.get(item.id,{})
  if row.get("group","")!="" and row.has("socket") and not covered.has(row.group):covered[row.group]=item
 for group in covered:
  var item=covered[group];game.book.acquire(item.id);game.equip_library_weapon(item);await frames()
  p.weapon_anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  if p.weapon_anim.has_animation("idle"):p.weapon_anim.play("idle");p.weapon_anim.seek(.1,true)
  game.ammo=game.weapon_capacity();game.reloading=0;p.shot_cooldown=0;game.source_hud.refresh_from_game();game.attack();await capture("muzzle-"+str(group).validate_filename()+"-027",0);game.clear_projectiles();game.clientfx.clear();await frames()
 game.show_home();game.local_room={"mode":0,"map":106,"team":"blue","allyBots":1,"enemyBots":1};game.start_round();await frames(65);p.set_physics_process(false);game.match_flow.advance_match(2)
 for bot in game.enemies.get_children():bot.set_physics_process(false)
 await capture("underworld-source-map-and-bot-route-027")
 game.queue_free();await frames();var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"ogCatalogInspection":true,"nativeMuzzleGroupsRendered":covered.size()},"  "));file.close();quit()
