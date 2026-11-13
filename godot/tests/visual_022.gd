extends SceneTree
var game
var output
var captures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
 for i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw;var img=root.get_texture().get_image();var path=output.path_join(name+".png");var error=img.save_png(path);captures.append({"name":name,"path":path,"width":img.get_width(),"height":img.get_height(),"saved":error==OK})
func room(team):
 game.local_room={"mode":3000,"map":26,"team":team,"allyBots":0,"enemyBots":0,"roundGoal":9,"matchSeconds":180};game.start_round();await frames();game.player.set_physics_process(false);game.player.velocity=Vector3.ZERO;game.destruction.advance(10);game.match_flow.advance_match(2)
func run():
 root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 await room("red");var d=game.destruction
 game.player.position=d.site_position(d.sites[0]);Input.action_press("interact");d.advance(0.4);await capture("original-device-equip-022")
 d.advance(2.8);await capture("original-hands-and-assembly-022")
 Input.action_release("interact");d.advance(0.1);await capture("cancel-restores-weapon-022")
 Input.action_press("interact");d.advance(float(d.tuning.plantSeconds));Input.action_release("interact");game.player.position+=game.player.global_basis.z*2.4;game.player.pitch=-0.55;game.player.pivot.rotation.x=-0.55;await capture("world-bomb-and-fuse-022")
 d.fuse=0.01;d.advance(0.02);await frames(18);await capture("source-bomb-explosion-022")
 await room("blue");d=game.destruction;d.planted=true;d.bomb=game.player.position;d.fuse=40;Input.action_press("interact");d.advance(2);await capture("separate-defuse-progress-022");Input.action_release("interact");d.cancel_operation()
 game.local_room={"mode":3000,"map":26,"team":"blue","allyBots":2,"enemyBots":3,"roundGoal":9,"matchSeconds":180};game.start_round();await frames();game.player.set_physics_process(false);d=game.destruction;d.advance(10)
 for bot in game.enemies.get_children():bot.set_physics_process(false)
 var red=game.enemies.get_children().filter(func(a):return a.team=="red");var blue=game.enemies.get_children().filter(func(a):return a.team=="blue")
 red[0].damage(10000,{"headshot":true});red[1].damage(10000,{"actor":"bot","attackerTeam":"blue","name":blue[0].display_name,"rosterId":blue[0].roster_id});blue[1].damage(10000,{"actor":"bot","attackerTeam":"red","name":red[2].display_name,"rosterId":red[2].roster_id})
 d.wins.blue=8;d.finish("blue","Maç kazanıldı");await capture("match-summary-022")
 await capture("credited-award-cards-022")
 game.pc_panel.links.ResultDetails.pressed.emit();await capture("detailed-match-result-022")
 game.pc_panel.links.Confirm.pressed.emit();await capture("return-to-configured-room-022")
 game.queue_free();await frames();var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":0,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false}));f.close();quit()
