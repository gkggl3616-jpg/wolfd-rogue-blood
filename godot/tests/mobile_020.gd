extends SceneTree
var game
var failures=[]
var checks=0
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=4):
 for i in range(n):await process_frame
func _initialize():call_deferred("run")
func run():
 var location="user://controls020-%d.json" % Time.get_ticks_usec();var book=preload("res://scripts/content_book.gd").new(true,location)
 check(book.set_control_layout({"fire":[0.7,0.6,1.5]}),"Touch arrangement persists atomically")
 var reopened=preload("res://scripts/content_book.gd").new(true,location);check(reopened.control_layout.fire==[0.7,0.6,1.5],"A reopened profile restores exact normalized center and size")
 book.save_blocked=true;check(not book.set_control_layout({"fire":[0.1,0.2,1.0]}) and book.control_layout.fire==[0.7,0.6,1.5],"Failed save preserves active arrangement")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(location))
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 check(game.book.tattoos.all(func(row):return row.has("iconSource") and row.icon!=row.texture and row.renderPriority==1 and row.uvTranspose==(row.role=="body")),"All 819 tattoos use source shop cards and approved orientation")
 game.show_library("Ayarlar");var ui=game.library_panel;ui.settings_tab="Ses";ui.refresh();await frames()
 var close=ui.detail_helper.native_window.find_widget("Exit");check(close.target_rect().size.x>close.size.x,"Close has enlarged visible and hit area")
 var point=close.get_global_transform()*close.target_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true);await frames()
 check(not is_instance_valid(game.library_panel) or game.library_panel.page!="Ayarlar","Real close click reaches button through source sheets")
 game.open_interface("Ayarlar",true);ui=game.library_panel;ui.navigate("controls");await frames();var editor=ui.get_children().filter(func(node):return node.get_script()==preload("res://ui/control_editor.gd"))[0]
 editor.set_row("fire",Vector2(220,350),1.5);editor.save();await frames()
 check(is_equal_approx(game.book.control_layout.fire[2],1.5),"Control size saves")
 check(game.touch.buttons[0].position.distance_to(Vector2(220,350))<1 and game.touch.buttons[0].scale.x>game.touch.ui_scale,"Game applies saved control center and size")
 check(not game.book.set_control_layout({"fire":[0.2,0.4,NAN]}),"Invalid touch preferences rejected")
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
 game.book.acquire_all();var weapon=game.book.weapons.filter(func(row):return row.get("available",false) and row.category=="rifle" and not game.book.default_owned.has(row.id))[0]
 game.book.loadouts[1].primary=weapon.id;game.match_sp=50;game.open_round_selection("human");var previous=game.book.active_loadout
 check(not game.choose_round_loadout(1) and game.match_sp==50 and game.book.active_loadout==previous,"Insufficient SP leaves balance and equipped set unchanged")
 game.match_sp=150;check(game.choose_round_loadout(1) and game.match_sp==50,"Accepted nonstarter loadout deducts exact displayed local cost")
 game.enemy_defeated();check(game.match_sp==150,"Personal elimination awards SP separately from persistent currency")
 game.match_sp=1990;game.enemy_defeated();check(game.match_sp==2000,"SP awards clamp at capacity")
 check(game.loadout_sp_cost(0)==0 and game.loadout_sp_cost(99)>2000,"Standard set is free and invalid selection cannot bypass cost validation")
 if not game.player.is_wolf:game.player.switch_form(true)
 await frames(30);game.player.action_time=0;check(game.player.begin_roar(),"Roar starts");game.player.roar_effect.advance(0.5)
 check(game.player.extra_health>0 and game.player.extra_health<99,"Roar replenishes progressively")
 game.player.roar_effect.advance(10);check(game.player.extra_health==99,"Completed howl respects cap")
 var hp=game.health;game.take_damage(110);check(game.player.extra_health==0 and game.health==hp-11,"Shield absorbs damage and excess reaches HP")
 for mode in [3000,3001,3020,3021]:
  game.local_room={"mode":mode,"map":26,"team":"blue","allyBots":0,"enemyBots":0,"roundGoal":3,"matchSeconds":105};check(game.start_round(),"Source destruction starts "+str(mode))
  check(game.destruction.sites.size()==2 and game.destruction.limit==3 and game.time_left==105,"Source sites and round/time rules apply")
  game.destruction.advance(106);check(game.running and game.destruction.wins.blue==1 and game.destruction.phase=="between","Timeout ends turn without ending match")
  game.destruction.advance(5);check(game.destruction.number==2 and game.destruction.phase=="combat","New turn restores actors and clock")
  game.destruction.planted=true;game.destruction.fuse=0.01;game.destruction.advance(0.1);check(game.destruction.wins.red==1,"Bomb can win after timer")
 game.local_room={"mode":3000,"map":26,"team":"blue","allyBots":1,"enemyBots":1,"roundGoal":3,"matchSeconds":105};game.start_round();await frames(8)
 var friend=game.enemies.get_children().filter(func(actor):return not actor.is_queued_for_deletion() and actor.team=="blue")[0];var enemy=game.enemies.get_children().filter(func(actor):return not actor.is_queued_for_deletion() and actor.team=="red")[0]
 friend.opponent=null;friend.think();check(friend.opponent==enemy,"Objective navigation still selects hostile bots instead of bypassing combat perception")
 enemy.position=game.destruction.site_position(game.destruction.sites[0]);enemy.velocity=Vector3.ZERO;enemy.sees_player=false;game.destruction.advance(3.1);check(game.destruction.planted,"Red bot performs actual timed planting at original source site")
 enemy.damage(1000,{"actor":"bot","attackerTeam":"blue"});check(game.running,"Red elimination after planting does not instantly end bomb turn")
 friend.position=game.destruction.bomb;friend.velocity=Vector3.ZERO;friend.sees_player=false;game.destruction.advance(5.1);check(game.destruction.wins.blue==1,"Blue bot performs timed defuse")
 for i in range(2):game.destruction.advance(5);game.destruction.advance(106)
 check(not game.running and game.last_result.victory and game.destruction.wins.blue==3,"Match finishes only after selected number of round wins")
 var report=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-020-validation.json"),FileAccess.WRITE);report.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures}));report.close()
 game.queue_free();await frames();print("MOBILE_020_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
