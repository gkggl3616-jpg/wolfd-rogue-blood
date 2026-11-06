extends SceneTree
var game
var checks=0
var failures=[]
func ensure(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=3):
 for i in range(n):await physics_frame
func _initialize():call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":2,"enemyBots":3};game.start_round();game.spawn_clock=0
 for i in range(4):game._process(3.6);await frames()
 var own=game.enemies.get_children().filter(func(b):return not b.is_queued_for_deletion() and b.team=="blue")
 var foes=game.enemies.get_children().filter(func(b):return not b.is_queued_for_deletion() and b.team=="red")
 ensure(own.size()==2 and foes.size()==3,"Independent allied/opposing bot counts spawn actual bodies")
 for b in own:
  b.choose_opponent();ensure(b.opponent!=game.player and b.opponent.team=="red","Allies choose opposing bots, never player")
 var a=own[0];var b=foes[0]
 a.set_physics_process(false);b.set_physics_process(false);a.position=Vector3(0,0.1,0);b.position=Vector3(0,0.1,-1.4);game.player.position=Vector3(10,0.1,10);a.opponent=b
 await frames()
 var hp=b.health;var wallet=game.wallet.duplicate();var hits=game.match_stats.hits
 a.melee_hit();ensure(b.health==hp-8,"Allied bot applies equal base damage to opposing bot")
 ensure(game.match_stats.hits==hits and game.wallet==wallet,"Bot damage cannot grant player rewards or accuracy")
 a.opponent=game.player;hp=game.health;a.hit_opponent();ensure(game.health==hp,"Ally cannot damage its player")
 ensure(not a.damage(10),"Player attacks cannot damage allied bot")
 b.damage(1000,{"actor":"bot","attackerTeam":"blue","name":"Dost","weapon":"Pençe"})
 ensure(game.kills==0 and game.team_score("blue")==1 and game.kill_feed[0].attacker=="Dost","Allied kill advances team scoreboard without personal credit")
 game.take_damage(10000,null,{"attackerTeam":"red"})
 ensure(game.running and game.health==0 and game.respawn_remaining==3 and game.is_match_active() and not game.is_combat_active(),"Allied match keeps bots fighting while dead player input is blocked")
 game.player.move_axis=Vector2(0,-1);var dead_position=game.player.position;await frames(5)
 ensure(game.player.position.is_equal_approx(dead_position),"Dead player cannot move during respawn")
 game._process(3.1)
 ensure(game.health==game.max_health() and game.deaths==1 and game.player.position.distance_to(game.preview_spawn)<0.1,"Team respawn restores source team anchor without resetting score")
 game.open_interface("scoreboard");await frames()
 var score_labels=game.pc_panel.content.get_children().filter(func(c):return c.has_meta("scoreboard_team"))
 ensure(score_labels.size()==4 and score_labels.all(func(c):return c.position.y+c.size.y<=490),"Team scoreboard shows live bots in compact correct team columns")
 game.resume()
 for node in game.enemies.get_children():node.queue_free()
 await frames()
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":4,"enemyBots":4};game.start_round()
 for i in range(4):
  game.spawn_clock=0;game._process(0.01);await frames()
  for node in game.enemies.get_children():node.set_physics_process(false)
 var maximum_bots=game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())
 ensure(maximum_bots.size()==8 and maximum_bots.filter(func(node):return node.team=="blue").size()==4,"Maximum four allies and four opponents fit without relying on earlier bots moving")
 for node in maximum_bots:node.queue_free()
 await frames()
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 for duration in [0.4,0.8,1.2]:
  game.player.reset_combat();game.player.position=Vector3(0,0.1,0);game.player.velocity=Vector3.ZERO;await frames(12)
  game.player.move_axis=Vector2(0,-1);ensure(game.player.begin_roll(),"Directional roll begins")
  game.player.roll_duration=duration
  var start=game.player.position;var maximum=0.0
  for i in range(100):
   await physics_frame
   maximum=maxf(maximum,Vector2(game.player.position.x-start.x,game.player.position.z-start.z).length())
  ensure(maximum<=3.02 and maximum>1.5,"Roll displacement stays bounded independently of source clip duration")
 game.player.move_axis=Vector2.ZERO;game.player.reset_combat();game.player.position=Vector3(0,0.1,0);await frames(12)
 var stationary=game.player.position;ensure(game.player.begin_roll(),"Stationary roll begins")
 for i in range(100):await physics_frame
 ensure(Vector2(game.player.position.x-stationary.x,game.player.position.z-stationary.z).length()<0.05,"Stationary roll never creates forward motion")
 var fx=JSON.parse_string(FileAccess.get_file_as_string("res://assets/abilities/source-roars.json"))
 var bound=game.book.characters.filter(func(row):return fx.characters.get(row.id,"")=="Howling_Fire_1")[0]
 game.book.choose_character(bound.id);game.local_room.team=bound.sourceTeam;game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 var tattoo=game.book.tattoos.filter(func(row):return row.role=="body")[0]
 game.book.set_tattoo("body",tattoo.texture,tattoo.id);game.player.apply_tattoos();var roar=game.player.roar_effect
 ensure(not roar.materials.is_empty(),"Actual equipped source tattoo binds to roar material")
 var texture=roar.materials[0].albedo_texture
 game.player.action_time=0;roar.cooldown=0
 ensure(game.player.begin_roar() and roar.source_effect.active_group=="Howling_Fire_1","Source character schedules its own named PC Howling group")
 for i in range(70):await physics_frame
 ensure(not roar.source_effect.parts.is_empty(),"Source Howling meshes start at the animation key instead of prematurely")
 roar.advance(0.01)
 ensure(roar.materials[0].albedo_texture==texture and roar.materials[0].emission_texture==texture and roar.materials[0].emission_energy_multiplier<=0.45,"Roar retains original tattoo color texture and bounds brightness")
 game.menu_open=true;roar.advance(0.01);await frames()
 ensure(not roar.active and roar.materials[0].emission_energy_multiplier==0 and roar.source_effect.parts.is_empty(),"Pause removes source effects and tattoo glow")
 game.book.set_tattoo("body","");game.menu_open=false
 game.show_library("Karakterler");await frames();var ui=game.library_panel
 ensure(ui.preview_view.transparent_bg,"Preview has no separate black rectangle")
 ensure(ui.preview_container.size.y/ui.canvas.scale.y>=590,"Character uses full height of left inventory column")
 ensure(ui.detail_helper.details.find_children("*","ProgressBar",true,false).is_empty(),"Added stats panel removed")
 ui.navigate("Dövmeler");await frames()
 ensure(ui.detail_helper.details.get_children().filter(func(c):return c is BaseButton and c.position.x<350 and c.position.y>=180).is_empty(),"No redundant tattoo equipment shelf in the left preview column")
 var symbols=ui.detail_helper.details.get_children().filter(func(c):return c.has_meta("source_team"))
 ensure(symbols.size()==2 and symbols.all(func(c):return c.size.x<=32),"Compact actual source team symbols replace text bars")
 ui.navigate("create_room");await frames();ensure(ui.room_allies.item_count==5 and ui.room_enemies.item_count==5,"Room exposes independent 0–4 counts")
 game.queue_free();await frames()
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-016-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  ")+"\n");file.close()
 print("MOBILE_016_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
