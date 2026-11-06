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
 game.show_library("Karakterler");var ui=game.library_panel;await capture("neutral-character-and-header-018")
 ui.navigate("Mağaza");ui.navigate("Karakterler");ui.filter_id="blue";ui.refresh();await capture("character-source-cards-018")
 root.size=Vector2i(800,450);await frames();ui.safe_insets=Vector4(24,6,28,8);ui.refresh();await capture("responsive-header-small-phone-018")
 root.size=Vector2i(2160,992);await frames();ui.safe_insets=Vector4(44,12,56,16);ui.refresh();await capture("responsive-header-wide-phone-018")
 root.size=Vector2i(1280,720);await frames();ui.safe_insets=Vector4.ZERO;ui.navigate("Dövmeler");ui.search_query="OG";ui.refresh()
 for id in ["tattoo-12955","tattoo-20803","tattoo-21803"]:
  var item=game.book.tattoos.filter(func(row):return row.id==id)[0];game.book.set_tattoo(item.role,item.texture,item.id)
 ui.selected=game.book.tattoos.filter(func(row):return row.id=="tattoo-12955")[0];ui.detail_helper.show_details();await capture("og-source-tattoos-018")
 ui.preview_angle=0;ui.detail_helper.show_details();await capture("og-front-depth-018")
 ui.navigate("create_room")
 for i in range(ui.room_mode.item_count):
  if ui.room_mode.get_item_id(i)==1000:ui.room_mode.select(i);ui.room_mode.item_selected.emit(i);break
 for i in range(ui.room_map.item_count):
  if ui.room_map.get_item_id(i)==84:ui.room_map.select(i);ui.room_map.item_selected.emit(i);break
 await capture("turkish-create-room-018")
 var desk=preload("res://ui/pc_screens.gd").new();desk.ui=ui;desk.map_gallery();await capture("original-map-gallery-018")
 ui.close_modal();ui.links.PLOK.pressed.emit();await capture("source-room-settings-018")
 ui.links.ChangeRule.pressed.emit();await capture("native-room-parameters-018")
 ui.links.PLOK.pressed.emit();ui.links.Invite.pressed.emit();await capture("source-room-invite-018")
 ui.close_modal();ui.navigate("Setler");await capture("source-priced-sets-018")
 ui.detail_helper.scroll_to(240);await capture("source-set-finger-scroll-018")
 ui.navigate("Karakterler");ui.selected=game.book.characters.filter(func(row):return row.id=="pair-model48")[0];ui.detail_helper.info_tab="properties";ui.detail_helper.show_details();await capture("source-character-stats-018")
 game.queue_free();await frames()
 var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"testFixtureCatalogueUnlocked":true},"  ")+"\n");f.close();quit()
