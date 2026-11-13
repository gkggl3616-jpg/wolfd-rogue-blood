extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=4):
 for i in range(n):await process_frame
func room(team="red",allies=1,opponents=1):
 game.local_room={"mode":3000,"map":26,"team":team,"allyBots":allies,"enemyBots":opponents,"roundGoal":9,"matchSeconds":180}
 check(game.start_round(),"Supported source room starts")
 await frames()
 for bot in game.enemies.get_children():bot.set_physics_process(false);bot.sees_player=false;bot.velocity=Vector3.ZERO
 game.player.set_physics_process(false);game.player.velocity=Vector3.ZERO
func run():
 var ledger=preload("res://scripts/match_economy.gd").new()
 check(ledger.begin()==0,"Video match starts at zero SP")
 check(ledger.elimination(2790,true)==2940,"Headshot reward is separate and not clamped to 2000/2800")
 check(ledger.elimination(0,false)==150,"Second quick kill earns a separate local streak award")
 ledger.advance(9);check(ledger.elimination(0,false)==100,"Expired kill chain cannot grant a streak")
 ledger.death();check(ledger.elimination(0,false)==100,"Death resets kill chain")
 var source={"sourceStats":{"wolf":{"values":[0,0,0,25,0,0]}}}
 check(ledger.yp_capacity(source,"normal",{"healthPercent":75})==200,"Decoded character and tattoo bonuses can exceed 99 YP")
 check(ledger.yp_capacity(source,"guardian",{"healthPercent":75})==360,"Mutation capacity is independent of normal wolf")
 check(ledger.yp_capacity(source,"normal",{},25)==150,"Equipped YP bonus enters the same capacity calculation")
 if "--economy-only" in OS.get_cmdline_user_args():
  print("MATCH_ECONOMY_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1);return
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 await room()
 var d=game.destruction
 check(d.phase=="prepare" and not game.is_match_active(),"Preparation locks player and bots")
 var clock=game.time_left;d.advance(9);check(d.phase=="prepare" and game.time_left==clock,"Preparation has its own clock")
 d.advance(1);check(game.is_combat_active(),"Start opens combat after countdown")
 check(d.carrier==game.player,"Exactly one attacking player owns the bomb")
 var friend=game.enemies.get_children().filter(func(a):return a.team=="red")[0]
 friend.position=d.site_position(d.sites[0]);check(not d.can_operate(friend),"A noncarrier attacker cannot plant")
 game.player.position=d.site_position(d.sites[0]);Input.action_press("interact");d.advance(2)
 check(d.progress==2 and not d.planted,"Plant requires a sustained hold")
 Input.action_release("interact");d.advance(0.1);check(d.progress==0 and d.operator_id==0,"Releasing cancels progress")
 Input.action_press("interact");d.advance(2);game.player.position+=Vector3(40,0,0);d.advance(0.1)
 check(d.progress==0 and game.match_sp==0,"Leaving the site cancels without reward")
 game.player.position=d.site_position(d.sites[0]);d.advance(float(d.tuning.plantSeconds));Input.action_release("interact")
 check(d.planted and d.carrier==null and d.fuse==40,"Completing one plant leaves one timed bomb")
 check(game.match_sp==50,"Plant credits the planter exactly once")
 d.advance(0.1);check(game.match_sp==50,"Planted state cannot repeat plant reward")
 game.time_left=0;d.advance(0.1);check(d.phase=="combat","Normal round timeout cannot cancel a live bomb")
 var defender=game.enemies.get_children().filter(func(a):return a.team=="blue")[0]
 defender.position=d.bomb;d.advance(2);check(d.progress==2,"Defender channels defuse")
 defender.position+=Vector3(10,0,0);d.advance(0.1);check(d.progress==0,"Defuse resets after leaving bomb")
 defender.position=d.bomb;d.fuse=0.1;d.progress=4.99;d.operator_id=defender.get_instance_id();d.advance(0.2)
 check(d.phase=="between" and d.wins.red==1 and d.wins.blue==0,"Fuse expiry and defuse in one frame produce exactly one winner")
 d.finish("blue","duplicate");check(d.wins.blue==0,"Finished round rejects a second result")
 await room()
 d=game.destruction;d.advance(10)
 var ally=game.enemies.get_children().filter(func(a):return a.team=="red")[0]
 ally.position=game.player.position+Vector3(4,0,0)
 var dropped_at=game.player.position
 game.take_damage(10000)
 check(game.health==0 and game.spectator.active and game.player.collision_layer==0,"Dead player enters spectator without a collidable body")
 check(game.spectator.target==ally and game.spectator.camera.current,"Spectator selects a living teammate and owns the camera")
 check(d.dropped and d.carrier==null and d.bomb==dropped_at,"Dead carrier drops the bomb at death location")
 check(not game.is_combat_active(),"Spectator cannot attack or operate bomb")
 ally.position=dropped_at;d.advance(0.1);check(d.carrier==ally and not d.dropped,"Living attacker can recover a dropped bomb")
 ally.health=0;game.spectator._process(0);check(game.spectator.target==null,"No living teammate gives a waiting view, never an enemy")
 d.phase="between";d.wait=0;d.advance(0.1)
 check(game.health>0 and not game.spectator.active and game.player.camera.current and game.player.collision_layer==1,"Next round restores player's camera, health and collision")
 await room("blue",2,1)
 d=game.destruction;d.advance(10)
 var bots=game.spectator.candidates();game.take_damage(10000);game.spectator.cycle(1)
 check(game.spectator.target==bots[1],"Mobile spectator cycles among teammates")
 bots[1].health=0;game.spectator._process(0);check(game.spectator.target==bots[0],"Dead watched teammate automatically changes target")
 await room("blue")
 d=game.destruction;d.advance(10);var first_spawn=game.preview_spawn
 game.match_sp=2800;game.kills=4;d.wins={"red":7,"blue":0};d.number=8;d.finish("blue","eighth round")
 d.advance(5);check(d.phase=="swap" and d.attacker_team=="blue" and d.wins=={"red":7,"blue":1},"After eight rounds roles swap without swapping team score")
 d.advance(5);check(d.number==9 and d.phase=="prepare" and game.preview_spawn!=first_spawn,"Ninth preparation uses the opposite source spawn")
 check(game.local_room.team=="blue" and game.match_sp==2800 and game.kills==4,"Swap preserves identity, SP and personal score")
 check(d.carrier==game.player and d.spawn_team("blue")=="red","Bomb permission and spawn role change together")
 d.advance(10);d.planted=true;d.bomb=game.player.position;d.fuse=10;game.application_suspended=true;d.advance(20)
 check(d.fuse==10 and d.phase=="combat","Background suspension freezes objective clocks")
 game.application_suspended=false;d.wins={"red":8,"blue":1};d.finish("red","match target")
 check(not game.running and game.last_result.winner=="red","Only the selected win goal ends the match")
 check(not game.spectator.active,"Match end clears spectator mode")
 game.book.acquire_all()
 var paid=game.book.weapons.filter(func(row):return row.get("available",false) and row.category=="rifle" and not game.book.default_owned.has(row.id))[0]
 game.book.loadouts[0].primary=paid.id;game.book.loadouts[1].primary=paid.id;game.book.select_loadout(0);game.book.select_mutation("guardian")
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round(true)
 check(game.match_sp==0 and game.current_weapon_id==game.book.starter_slots.primary and game.player.mutation_id=="normal","Unpaid saved loadout and mutation cannot enter a fresh match")
 game.finish_round_selection();check(game.current_weapon_id==game.book.starter_slots.primary,"Selection timeout retains genuinely free standard equipment")
 game.open_round_selection("human");check(not game.choose_round_loadout(1),"Paid preset cannot bypass zero SP through saved active set")
 game.match_sp=game.loadout_sp_cost(1);check(game.choose_round_loadout(1) and game.match_sp==0 and game.current_weapon_id==paid.id,"Paid preset becomes usable only after the displayed debit")
 var active=game.current_weapon_id;var other=game.book.weapons.filter(func(row):return row.get("available",false) and row.category=="rifle" and row.id!=paid.id)[0]
 check(game.equip_item_from_ui(other) and game.current_weapon_id==active and game.equipped_slots().primary==paid.id,"Inventory editing prepares a future set without changing paid match equipment")
 game.open_round_selection("human");game.choose_round_loadout(0)
 check(game.current_weapon_id==game.book.starter_slots.primary and game.book.loadouts[0].primary==paid.id,"Free standard cannot smuggle custom weapons or overwrite saved presets")
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-021-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));f.close()
 game.queue_free();await frames();print("MOBILE_021_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
func _initialize():call_deferred("run")
