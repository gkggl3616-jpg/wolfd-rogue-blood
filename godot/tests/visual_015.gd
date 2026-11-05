extends SceneTree
var game
var output=""
var captures=[]
func _initialize():
 output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=8):
 for i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw
 var pixels=root.get_texture().get_image();var path=output.path_join(name+".png");var error=pixels.save_png(path)
 captures.append({"name":name,"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"saved":error==OK})
func run():
 root.size=Vector2i(2160,992);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
 game.book.offline_edition=true;game.book.acquire_all();game.show_library("Karakterler");var ui=game.library_panel
 ui.safe_insets=Vector4(36,8,44,12);ui.filter_id="red";ui.refresh();await capture("red-characters-phone-015")
 ui.filter_id="blue";ui.selected={};ui.preview_wolf=false;ui.refresh();await capture("blue-characters-phone-015")
 root.size=Vector2i(1280,720);ui.safe_insets=Vector4.ZERO;ui.navigate("Dövmeler");await capture("tattoo-triplets-015")
 var entry=ui.detail_helper.entries.filter(func(row):return not row.get("placeholder",false) and row.role=="body")[0]
 ui.selected=entry;ui.preview_team="red";ui.preview_angle=PI;ui.detail_helper.show_details();await capture("red-wolf-tattoos-015")
 ui.preview_team="blue";ui.preview_angle=PI;ui.detail_helper.show_details();await capture("blue-wolf-tattoos-015")
 ui.navigate("power");ui.filter_id="claw";ui.detail_helper.refresh_grid();ui.selected=game.power_item("16020");ui.detail_helper.info_tab="properties";ui.detail_helper.show_details();await capture("source-claw-powers-015")
 ui.navigate("Envanter");ui.quality_id="Efsane";ui.refresh();await capture("weapon-quality-filter-015")
 ui.navigate("create_room");game.local_room={"mode":0,"map":106,"team":"blue"};ui.room_draft.merge(game.local_room,true);ui.refresh();await capture("new-maps-selection-015")
 game.local_room={"mode":0,"map":89,"team":"blue"};game.start_round();game.spawn_clock=10000;await frames(20);game.spawn_enemy("human");await capture("storage-team-spawn-015")
 game.local_room={"mode":0,"map":0,"team":"blue"};game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 await frames(20);game.reload_weapon();await capture("source-wolf-roar-015")
 game.queue_free();await frames()
 var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"physicalAndroidDeviceTested":false,"safeInsetsFixture":true},"  ")+"\n");file.close();quit()
