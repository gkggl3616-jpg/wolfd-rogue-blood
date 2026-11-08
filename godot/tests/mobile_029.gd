extends SceneTree
var checks=0
var failures=[]
var game
func _initialize():call_deferred("run")
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=3):
 for _i in range(n):await process_frame
func physics(n=3):
 for _i in range(n):await physics_frame
func clear_bots():
 for bot in game.enemies.get_children():game.enemies.remove_child(bot);bot.queue_free()
 await physics()
func roster_checks():
 for mode in [0,1000,1001,1010,1020,1021,1022,1023,1024,1025,1026,3000,3001,3020,3021]:
  game.local_room={"mode":mode,"title":"QA029-"+str(mode),"map":0,"team":"blue","allyBots":4,"enemyBots":4}
  var rules=load("res://scripts/source_match_rules.gd").new();rules.configure(game.local_room)
  var names=[];var characters=[];var weapons=[]
  for team in ["red","blue"]:
   for slot in range(4):
    var identity=game.bot_roster.identity(game,team,slot)
    check(not identity.name in names,"Distinct roster name "+str(mode)+team+str(slot));names.append(identity.name)
    check(not identity.characterId in characters,"Distinct source character "+str(mode)+team+str(slot));characters.append(identity.characterId)
    var source=game.book.characters.filter(func(r):return r.id==identity.characterId)[0]
    check(source.available and source.sourceTeam==team,"Available team-correct character "+identity.id)
    var weapon=game.bot_roster.arsenal.get(identity.weaponId,{})
    if rules.form_lock=="wolf":check(weapon.is_empty(),"Wolf-only mode has no hidden human weapon")
    else:
     check(not weapon.is_empty() and rules.weapon_allowed(weapon.category,weapon.native.sourceKind),"Native weapon mask "+str(mode)+identity.id)
     check(not identity.weaponId in weapons,"Unique live primary "+str(mode)+identity.id);weapons.append(identity.weaponId)
    check(game.bot_roster.identity(game,team,slot)==identity,"Stable room/respawn identity "+identity.id)
func wolf_checks(bot):
 bot.set_physics_process(false);bot.source_events.set_process(false);bot.anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 bot.position=Vector3(0,.1,0);game.player.position=Vector3(0,.1,-1.5);game.health=100;await physics()
 var clips=[]
 for i in range(2):
  bot.begin_melee();var clip=bot.active_clip;clips.append(clip)
  var record=game.clientfx.animation_record(bot,clip);var keys=record.events.filter(func(e):return str(e.key).to_lower().contains("fire_key"))
  check(not keys.is_empty() and not bot.pending_melee.is_empty(),"Native wolf attack has a pending source hit "+clip)
  bot.source_events.last_clip=clip;bot.source_events.last_record=record
  var time=float(keys[0].timeMs)/1000;var hp=game.health
  bot.source_events.dispatch_range(-.001,time-.001);check(game.health==hp,"No premature damage "+clip)
  bot.source_events.dispatch_range(time-.001,time);check(game.health==hp-8,"Exactly eight damage at source key "+clip)
  bot.source_events.dispatch_range(time-.001,time);check(game.health==hp-8,"Repeated key cannot hit twice "+clip)
 check(clips==["attack","attack_right"],"Bot alternates original left/right attack clips")
 var trail=bot.claw_trail;trail.set_process(false);check(trail.begin(),"NPC binds native claw endpoint bones")
 trail.source_window(0,true);trail._process(.01);var original=trail.samples[0].points.duplicate();bot.position.x+=.5;bot.rotation.y+=.5;trail._process(.01)
 check(trail.top_level and trail.global_transform==Transform3D.IDENTITY and trail.samples[0].points==original,"Old claw samples stay in world coordinates after actor translation/rotation")
 check(trail.samples[-1].points!=original,"New samples follow the current animated hand")
 trail.source_window(0,false);trail._process(.05);check(not trail.samples.is_empty() and not trail.emitting,"Closing spline stops emission and preserves a fading tail")
 trail._process(.2);check(trail.samples.is_empty() and trail.meshes.is_empty(),"Closed claw trail expires completely")
 bot.begin_melee();game.menu_open=true;bot.source_events._process(0);check(bot.pending_melee.is_empty(),"Menu cancels pending NPC native attack");game.menu_open=false
 bot.claw_trail.set_process(true)
func progression_checks():
 for index in range(game.ranks.catalog.ranks.size()):
  var row=game.ranks.catalog.ranks[index];var progress=game.ranks.progress(row.localMinimumGp)
  check(progress.level==index+1 and progress.rankAsset==row.asset and progress.rankName==row.name,"Existing rank/level binding "+str(index+1))
  check(progress.fraction== (1.0 if progress.maxed else 0.0),"Exact rank threshold progress "+str(index+1))
 check(game.ranks.progress(-10).level==1 and game.ranks.progress(1000000000).maxed,"Negative and capped account levels are bounded")
 var path="user://level029-"+str(Time.get_ticks_usec())+".json";game.wallet_storage_path=path;game.test_mode=false;game.wallet.gp=95;game.level_events=[]
 game.match_wallet_start=game.wallet.duplicate();check(game.grant_money("gp",10,"QA kill"),"GP award is saved atomically")
 check(game.ranks.progress(game.wallet.gp).level==2 and game.level_events.size()==1,"One saved GP crossing causes one account level event")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(path));check(saved.gp==105 and not saved.has("xp"),"Persistence retains one GP ledger and no duplicate XP")
 game.wallet.gp=0;game.load_wallet(path);check(game.wallet.gp==105 and game.ranks.progress(game.wallet.gp).level==2,"Existing saved GP restores the same level/rank")
 var before=FileAccess.get_file_as_bytes(path);DirAccess.make_dir_absolute(path+".pending")
 check(not game.grant_money("gp",400,"QA failure") and game.wallet.gp==105 and game.level_events.size()==1,"Failed wallet write changes neither level nor GP nor events")
 check(FileAccess.get_file_as_bytes(path)==before,"Failed level write preserves prior save bytes")
 DirAccess.remove_absolute(path+".pending");DirAccess.remove_absolute(path);game.test_mode=true
 game.wallet.gp=95;game.match_wallet_start=game.wallet.duplicate();game.level_events=[];game.enemy_defeated({"target":"QA target"})
 check(game.wallet.gp>=105 and game.ranks.progress(game.wallet.gp).level>=2,"Actual elimination GP is connected to level progression")
 game.end_round("QA result");check(game.last_result.progression.before.level==1 and game.last_result.progression.after.level>=2 and game.last_result.progression.earnedGp==game.last_result.walletRewards.gp,"Match result reports actual GP gain and before/after levels")
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 roster_checks();game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.player.set_physics_process(false);await physics(5)
 if game.player.is_wolf:game.player.switch_form(true)
 game.spawn_enemy("human","hard","red");await physics();var bot=game.enemies.get_child(0);bot.set_physics_process(false)
 var identity=bot.roster_identity.duplicate(true);check(bot.display_name==identity.name and bot.character_info.id==identity.characterId and bot.weapon_data.itemId==identity.weaponId,"Actual spawn uses the room identity, character and weapon")
 for weapon in game.bot_roster.arsenal.values():
  bot.prepare_weapon(weapon);await frames(1)
  check(is_instance_valid(bot.weapon) and bot.weapon_attachment is BoneAttachment3D and bot.native_hand_socket_verified,"Native RightHand socket "+weapon.name)
  check(bot.capacity==int(weapon.native.capacity) and is_equal_approx(bot.fire_interval,float(weapon.native.fireIntervalMs)/1000),"Source finite capacity/cadence "+weapon.name)
 var supas=game.bot_roster.arsenal.values().filter(func(w):return w.name=="SUPAS PT")[0];bot.prepare_weapon(supas);bot.ammo=0;bot.reserve=3;bot.sees_player=false;check(bot.begin_reload(),"SUPAS bot starts native per-shell reload");bot.advance_reload(.667)
 check(bot.ammo==1 and bot.reserve==2 and bot.reload_remaining>0,"Native insertion adds exactly one shell")
 bot.advance_reload(.667*2);check(bot.ammo==3 and bot.reserve==0 and bot.reload_phase=="finish","Finite shells require the original finishing phase")
 bot.advance_reload(float(supas.reloadFinishSeconds));check(bot.reload_remaining<=0 and bot.reloads_completed==1,"Finishing rack completes one reload")
 bot.position=Vector3(-6,.1,7);bot.last_known=Vector3(0,.1,-7);await physics()
 var goal=bot.tactics.plan(bot.last_known,true);check(goal is Vector3 and bot.reachable(goal) and bot.tactics.lane_clear(goal,bot.last_known),"Tactical goal has a real connected path and clear firing lane")
 bot.destination=Vector3(0,.1,-7);bot.velocity=Vector3.DOWN*60;bot.move_and_slide();bot.requested_motion=Vector3.RIGHT*3;bot.tactics.progress_origin=bot.position;bot.tactics.stuck_clock=1.39;bot.brain_enabled=true;bot.tactics.advance(.02)
 check(bot.tactics.recoveries>0 and bot.tactics.recovery>0,"Blocked movement intent triggers connected recovery even when actual velocity is zero")
 var primary=game.bot_roster.arsenal[identity.weaponId];bot.prepare_weapon(primary);bot.ammo=0;bot.reserve=0;bot.reload_remaining=0;bot.tactics.recovery=0;bot.think();check(bot.weapon_data.itemId!=primary.itemId,"Exhausted primary switches to finite legal sidearm")
 bot.prepare_weapon(primary);check(bot.ammo==0 and bot.reserve==0,"Re-equipping an exhausted gun cannot refill it")
 bot.roster_identity=identity.duplicate(true);bot.roster_identity.role="flanker";bot.tactics.recovery=0;bot.tactics.cooldown=0;bot.tactics.goal_valid=false
 var rifle=game.bot_roster.arsenal.values().filter(func(w):return w.category=="rifle")[0];bot.prepare_weapon(rifle);bot.ammo=bot.capacity;bot.reserve=bot.capacity*3;bot.reload_remaining=0;bot.attack_clock=0
 bot.position=Vector3(-6,.1,7);bot.rotation.y=0;game.player.position=Vector3(0,.1,-8);game.health=1000;bot.opponent=game.player;bot.has_target=true;bot.sees_player=true;bot.reaction=0;bot.last_known=game.player.position
 var origin=bot.position;var shots=bot.shots_fired;bot.set_physics_process(true);await physics(120);bot.set_physics_process(false)
 check(bot.position.distance_to(origin)>1 and bot.shots_fired>shots and bot.tactics.goal_valid,"Actual flanker follows a connected lateral route while firing, rather than remaining stationary")
 bot.roster_identity=identity;game.health=100
 await clear_bots();game.spawn_enemy("human","normal","red");await physics();bot=game.enemies.get_child(0);bot.set_physics_process(false)
 check(bot.roster_identity==identity,"Respawn keeps the same nickname, source character and primary")
 await clear_bots();game.spawn_enemy("wolf","normal","red");await physics();await wolf_checks(game.enemies.get_child(0));await clear_bots()
 await progression_checks();game.queue_free();await frames()
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-029-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"arsenalProfiles":59,"maximumLiveBots":8,"rankLevels":62,"physicalAndroidDeviceTested":false,"apkProduced":false},"  ")+"\n");file.close();print("MOBILE_029_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
