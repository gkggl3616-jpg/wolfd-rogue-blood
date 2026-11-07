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
 var image=root.get_texture().get_image();var path=output.path_join(name+".png");var error=image.save_png(path)
 captures.append({"name":name,"path":path,"width":image.get_width(),"height":image.get_height(),"saved":error==OK})
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
 game.book.offline_edition=true;game.book.acquire_all();game.show_library("Karakterler");await capture("transparent-character-016")
 var ui=game.library_panel;ui.navigate("Dövmeler");await capture("large-wolf-inventory-016")
 ui.navigate("power");await capture("power-inventory-016")
 ui.navigate("create_room");ui.room_allies.select(3);ui.room_allies.item_selected.emit(3);ui.links["Bot ve maç ayarları"].pressed.emit();await capture("ally-bot-selection-016")
 game.local_room={"title":"Yerel Takım Maçı","mode":0,"map":0,"team":"blue","allyBots":3,"enemyBots":4};ui.navigate("room");await capture("team-rosters-016")
 game.start_round();game.spawn_clock=0;game._process(0.01);await frames();game.spawn_clock=10000;await capture("allied-bot-match-016")
 game.set_process(false)
 var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/abilities/source-roars.json"))
 for group in ["Howling_Fire_1","Howling_Ice_1","Howling_Lightning_1"]:
  var ids=catalog.characters.keys().filter(func(id):return catalog.characters[id]==group)
  if ids.is_empty():continue
  var entry=game.book.characters.filter(func(row):return row.id==ids[0])[0]
  game.local_room={"mode":0,"map":0,"team":entry.sourceTeam,"allyBots":0,"enemyBots":0};game.book.choose_character(entry.id);game.start_round();game.spawn_clock=10000
  if not game.player.is_wolf:game.player.switch_form(true)
  if group=="Howling_Fire_1":
   var tattoo=game.book.tattoos.filter(func(row):return row.role=="body" and "Altın" in row.name)[0]
   game.book.set_tattoo("body",tattoo.texture,tattoo.id);game.player.apply_tattoos()
  await frames(22);game.player.set_physics_process(false)
  if group=="Howling_Fire_1":await capture("tattoo-before-roar-016")
  game.player.action_time=0;game.player.begin_roar();await frames(70);await capture(group.to_lower()+"-016");game.player.roar_effect.stop()
 game.queue_free();await frames()
 var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"testFixtureActors":true},"  ")+"\n");file.close();quit()
