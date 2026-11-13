extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
 for i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw;var img=root.get_texture().get_image();var path=output.path_join(name+".png");var error=img.save_png(path);captures.append({"name":name,"path":path,"width":img.get_width(),"height":img.get_height(),"saved":error==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.local_room={"mode":3000,"map":26,"team":"blue","allyBots":2,"enemyBots":1,"roundGoal":9,"matchSeconds":180};game.start_round(true);await frames()
 for bot in game.enemies.get_children():bot.set_physics_process(false)
 game.player.set_physics_process(false)
 await capture("video-aligned-equipment-021");game.finish_round_selection();await capture("round-preparation-021")
 game.destruction.advance(10);game.match_flow.advance_match(2);game.match_sp=2940;game.take_damage(10000);await frames();game.source_hud.refresh_from_game();await capture("teammate-spectator-021")
 game.destruction.phase="combat";game.destruction.number=8;game.destruction.wins={"red":7,"blue":0};game.destruction.finish("blue","Sekizinci tur");await capture("round-result-021")
 game.destruction.advance(5);await capture("attack-defense-swap-021")
 game.destruction.advance(5);await capture("role-spawn-and-carrier-021")
 game.show_home();game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.player.set_physics_process(false);game.book.acquire_all();
 for role in ["body","left","right"]:
  var choices=game.book.tattoos.filter(func(row):return row.role==role and float(row.get("appliedBonuses",{}).get("healthPercent",0))>=30)
  if not choices.is_empty():game.book.set_tattoo(role,choices[0].texture,choices[0].id)
 game.inbox.state.powerCounts={"19002":3,"19502":3};game.equip_power_item("19002");game.equip_power_item("19502");game.player.apply_tattoos();game.player.restore_howl_health();game.match_sp=2940;game.source_hud.refresh_from_game();await capture("character-yp-and-sp-021");game.open_round_selection("wolf");await capture("video-aligned-mutations-021");game.finish_round_selection();root.size=Vector2i(2160,992);await capture("video-layout-wide-phone-021")
 game.queue_free();await frames();var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false}));f.close();quit()
