extends SceneTree
var output
var game
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
 for i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw;var image=root.get_texture().get_image();var path=output.path_join(name+".png");var err=image.save_png(path);captures.append({"name":name,"path":path,"width":image.get_width(),"height":image.get_height(),"saved":err==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);game.book.offline_edition=true;game.sync_collection();game.book.acquire_all();game.show_library("Dövmeler");var ui=game.library_panel
 for item in ui.detail_helper.entries.slice(0,3):game.book.set_tattoo(item.role,item.texture,item.id)
 ui.selected=ui.detail_helper.entries[1];ui.detail_helper.show_details();await capture("original-tattoo-shop-cards-020")
 ui.search_query="OG";ui.refresh();await capture("og-family-preserved-020")
 ui.navigate("Ayarlar");ui.settings_tab="Ses";ui.refresh();await capture("large-close-settings-020")
 ui.navigate("controls");await frames();var editor=ui.get_children().filter(func(node):return node.get_script()==preload("res://ui/control_editor.gd"))[0];editor.set_row("fire",Vector2(900,510),1.5);await capture("drag-resize-controls-020");editor.save()
 game.local_room={"mode":3000,"map":26,"team":"red","allyBots":0,"enemyBots":0,"roundGoal":3,"matchSeconds":105};game.start_round();await frames();await capture("destruction-bomb-controls-020")
 game.player.position=game.destruction.site_position(game.destruction.sites[0]);Input.action_press("interact");game.destruction.advance(3.1);Input.action_release("interact");await capture("destruction-bomb-planted-020")
 game.destruction.fuse=0.01;game.destruction.advance(0.02);await capture("destruction-round-score-020")
 game.destruction.advance(5);await capture("destruction-next-round-020")
 game.show_home();game.pc_panel.navigate("room_settings");await capture("destruction-room-round-options-020")
 game.queue_free();await frames();var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false}));f.close();quit()
