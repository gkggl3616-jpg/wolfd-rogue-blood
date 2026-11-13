extends RefCounted
var game
var enabled=false
var phase="combat"
var wins={"red":0,"blue":0}
var number=1
var limit=5
var sites=[]
var planted=false
var bomb=Vector3.ZERO
var carrier
var dropped=false
var fuse=40.0
var progress=0.0
var operator_id=0
var wait=0.0
var dead={"red":0,"blue":0}
var tuning={}
var attacker_team="red"
var roles_swapped=false
var last_winner=""
var last_reason=""
func begin():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/destruction.json"))
 enabled=int(game.local_room.get("mode",0)) in [3000,3001,3020,3021]
 wins={"red":0,"blue":0};dead={"red":0,"blue":0};number=1;phase="combat";planted=false;progress=0;operator_id=0;carrier=null;dropped=false;attacker_team="red";roles_swapped=false;last_winner="";last_reason=""
 tuning=data.mobileTuning.duplicate(true);tuning.merge(game.economy.rules.destruction,true)
 sites=data.maps.get(str(int(game.local_room.get("map",0))),{}).get("sites",[]);limit=game.match_rules.goal
 if enabled and sites.size()!=2:enabled=false;return false
 return true
func defender_team():return "blue" if attacker_team=="red" else "red"
func spawn_team(team):return "red" if team==attacker_team else "blue"
func site_position(row):return Vector3(row.position[0],row.position[1],row.position[2])
func role(team):return "SALDIRI" if team==attacker_team else "SAVUNMA"
func swap_after():return maxi(1,int(game.local_room.get("roleSwapAfterRounds",tuning.roleSwapAfterRounds)))
func prepare():
 phase="prepare";wait=float(tuning.prepareSeconds);progress=0;operator_id=0
 assign_carrier();game.announce("RAUNT %d · HAZIR · %s" % [number,role(game.local_room.get("team","blue"))])
func start_combat():
 if phase!="prepare":return
 phase="combat";game.close_round_selection();game.match_flow.signal_start();game.announce("RAUNT %d · BAŞLA" % number)
func assign_carrier():
 carrier=null;dropped=false
 if game.health>0 and game.local_room.get("team","blue")==attacker_team:carrier=game.player
 else:
  for actor in game.enemies.get_children():
   if game.actor_alive(actor) and actor.team==attacker_team:carrier=actor;break
 if game.actor_alive(carrier):bomb=carrier.global_position
func nearby(actor):
 if planted:return actor.global_position.distance_to(bomb)<3
 for row in sites:
  if actor.global_position.distance_to(site_position(row))<float(row.radius)+1:return true
 return false
func can_operate(actor):
 return game.actor_alive(actor) and game.actor_team(actor)==(defender_team() if planted else attacker_team) and (planted or actor==carrier) and not (actor==game.player and actor.is_wolf) and nearby(actor)
func cancel_operation():progress=0;operator_id=0
func finish(team,reason):
 if phase!="combat":return
 if team in wins:wins[team]+=1
 last_winner=team;last_reason=reason;phase="between";wait=float(tuning.betweenRoundsSeconds);cancel_operation()
 game.player.reset_combat();game.touch.reset();game.clear_projectiles();game.announce(reason)
 if team in wins:game.game_audio.match_sound("round_"+team+"_win")
 if int(wins.get(team,0))>=limit:game.match_rules.winner=team;game.end_round(reason)
func actor_dead(team,actor=null):
 dead[team]+=1
 if actor!=null and actor==carrier and not planted:
  bomb=actor.global_position;carrier=null;dropped=true;cancel_operation();game.announce("Bomba düştü")
 elif actor!=null and actor.get_instance_id()==operator_id:cancel_operation()
func next_turn():
 number+=1;planted=false;carrier=null;dropped=false;cancel_operation();dead={"red":0,"blue":0}
 game.restart_destruction_turn();prepare()
func advance(delta):
 if not enabled or not game.running or game.menu_open or game.application_suspended:return
 if phase in ["prepare","between","swap"]:
  wait=maxf(0,wait-delta)
  if wait>0:return
  if phase=="prepare":start_combat()
  elif phase=="between" and game.local_room.get("swapRoles",true) and not roles_swapped and number>=swap_after():
   attacker_team=defender_team();roles_swapped=true;phase="swap";wait=float(tuning.roleSwapSeconds);game.announce("SAVUNMA VE SALDIRI DEĞİŞİMİ")
  else:next_turn()
  return
 game.time_left=maxf(0,game.time_left-delta)
 if planted:
  fuse=maxf(0,fuse-delta)
  # Expiry wins this frame. An earlier defuse has already left combat.
  if fuse<=0:
   game.game_audio.play_at("root/wt_snd/specialweapon/timebomb/explosion_bomb.wav",bomb,false)
   finish(attacker_team,"Bomba patladı")
   if game.running:game.clientfx.play("Exp_Basictimebomb",null,bomb,false,0,null,true)
   return
 elif game.time_left<=0:finish(defender_team(),"Tur süresi doldu");return
 for team in ["red","blue"]:
  var population=game.bot_limit(team)+(1 if game.local_room.get("team","blue")==team else 0)
  if population>0 and dead[team]>=population and not (team==attacker_team and planted):finish(defender_team() if team==attacker_team else attacker_team,"Rakip takım elendi");return
 if game.actor_alive(carrier):bomb=carrier.global_position
 elif carrier!=null:carrier=null;dropped=not planted;cancel_operation()
 if dropped:
  var pickups=game.enemies.get_children().filter(func(actor):return game.actor_alive(actor) and actor.team==attacker_team)
  if game.health>0 and game.local_room.get("team","blue")==attacker_team:pickups.push_front(game.player)
  for actor in pickups:
   if actor.global_position.distance_to(bomb)<=float(tuning.pickupRadius):carrier=actor;dropped=false;game.announce("Bomba alındı");break
 var workers=[]
 if game.health>0 and Input.is_action_pressed("interact"):workers.append(game.player)
 for actor in game.enemies.get_children():
  if game.actor_alive(actor) and actor.kind=="human" and not actor.sees_player:workers.append(actor)
 var worker=null
 for actor in workers:
  if can_operate(actor) and Vector2(actor.velocity.x,actor.velocity.z).length()<0.3:worker=actor;break
 if worker==null:cancel_operation();return
 if operator_id!=worker.get_instance_id():progress=0;operator_id=worker.get_instance_id()
 progress+=delta
 if progress>=float(tuning.defuseSeconds if planted else tuning.plantSeconds):
  if planted:
   if worker==game.player:game.award_sp("defuse","Bomba imha edildi")
   game.game_audio.play_ui("root/wt_snd/interface/msg_bomb_defuse.wav");finish(defender_team(),"Bomba etkisiz hale getirildi")
  else:
   planted=true;bomb=worker.global_position;carrier=null;dropped=false;fuse=float(tuning.fuseSeconds);cancel_operation()
   game.bomb_presentation.complete_plant(worker);game.game_audio.play_ui("root/wt_snd/interface/msg_bomb_plant.wav")
   if worker==game.player:game.award_sp("plant","Bombaman")
   game.announce("Bomba kuruldu · Savunma bombayı çözmeli")
func objective(actor):
 if planted or dropped:return bomb
 if sites.is_empty():return actor.global_position
 if game.actor_team(actor)==attacker_team and game.actor_alive(carrier) and actor!=carrier:return carrier.global_position
 var site=sites[actor.get_instance_id()%sites.size()];var point=site.get("approach",site.position)
 return Vector3(point[0],point[1],point[2])
