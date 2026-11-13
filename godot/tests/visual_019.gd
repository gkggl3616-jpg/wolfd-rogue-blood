extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=8):
 var draw=RenderingServer.render_loop_enabled
 if n>10:RenderingServer.render_loop_enabled=false
 for i in range(n):await process_frame
 RenderingServer.render_loop_enabled=draw
func capture(name):
 await frames();await RenderingServer.frame_post_draw
 var path=output.path_join(name+".png");var pixels=root.get_texture().get_image();var err=pixels.save_png(path)
 captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":err==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);game.book.offline_edition=true;game.sync_collection();game.book.acquire_all()
 game.show_library("Karakterler");var ui=game.library_panel;ui.preview_wolf=true
 for id in ["pair-model0","pair-model1"]:
  ui.replace_preview(game.book.characters.filter(func(row):return row.id==id)[0]);var animator=ui.preview_model.find_children("*","AnimationPlayer",true,false)[0]
  for phase in [0.1,0.9]:
   animator.seek(animator.get_animation("idle").length*phase,true);animator.pause();await capture(id+"-wolf-idle-"+str(int(phase*100))+"-019")
 ui.navigate("Dövmeler");ui.search_query="OG";ui.refresh()
 for id in ["tattoo-12955","tattoo-20803","tattoo-21803"]:
  var item=game.book.tattoos.filter(func(row):return row.id==id)[0];game.book.set_tattoo(item.role,item.texture,item.id)
 ui.selected=game.book.tattoos.filter(func(row):return row.id=="tattoo-12955")[0];ui.detail_helper.show_details();await capture("solid-wolf-og-overlay-019")
 ui.preview_angle=0;ui.detail_helper.show_details();await capture("solid-wolf-front-no-showthrough-019")
 game.inbox.state.messages=[]
 for id in ["pair-model48","pair-model50"]:
  var entry=game.book.characters.filter(func(row):return row.id==id)[0];game.inbox.enqueue(game.inbox.state,"character",id,entry.name,1,"visual019-"+id,"Sistem")
 ui.navigate("gifts");await capture("full-card-character-gifts-019")
 ui.navigate("Karakterler")
 root.size=Vector2i(800,450);await frames();ui.safe_insets=Vector4(24,6,28,8);ui.refresh();await capture("expanded-small-phone-header-019")
 root.size=Vector2i(2712,1220);await frames();ui.safe_insets=Vector4(52,12,56,12);ui.refresh();await capture("x7-pro-resolution-header-019")
 root.size=Vector2i(1280,720);await frames();ui.safe_insets=Vector4.ZERO
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 for id in ["19002","19502"]:game.inbox.state.powerCounts[id]=3;game.equip_power_item(id)
 await frames(30);game.player.action_time=0;await capture("wolf-hud-powers-run-button-removed-019")
 game.player.shot_cooldown=0;game.attack();await frames(4);await capture("original-left-claw-019")
 game.player.shot_cooldown=0;game.attack();await frames(4);await capture("original-right-claw-019")
 game.player.begin_roar();await frames(20);game.player.begin_roar();await frames(70);await capture("restarted-source-howl-019")
 await frames(180);await capture("howl-extra-health-019")
 game.queue_free();await frames()
 var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"testFixtureCatalogueUnlocked":true,"testFixtureGifts":true},"  ")+"\n");f.close();quit()
