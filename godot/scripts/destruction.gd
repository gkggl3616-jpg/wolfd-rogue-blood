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
var fuse=40.0
var progress=0.0
var operator_id=0
var wait=0.0
var dead={"red":0,"blue":0}
var tuning={}
func begin():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/destruction.json"));enabled=int(game.local_room.get("mode",0)) in [3000,3001,3020,3021];wins={"red":0,"blue":0};dead={"red":0,"blue":0};number=1;phase="combat";planted=false;progress=0;operator_id=0;tuning=data.mobileTuning
 sites=data.maps.get(str(int(game.local_room.get("map",0))),{}).get("sites",[]);limit=game.match_rules.goal
 if enabled and sites.size()!=2:enabled=false;return false
 return true
func site_position(row):return Vector3(row.position[0],row.position[1],row.position[2])
func nearby(actor):
 if planted:return actor.global_position.distance_to(bomb)<3
 for row in sites:
  if actor.global_position.distance_to(site_position(row))<float(row.radius)+1:return true
 return false
func finish(team,reason):
 if phase!="combat":return
 if team in wins:wins[team]+=1
 phase="between";wait=float(tuning.betweenRoundsSeconds);game.player.reset_combat();game.touch.reset();game.clear_projectiles();game.announce(reason)
 if team in wins:game.game_audio.match_sound("round_"+team+"_win")
 if int(wins.get(team,0))>=limit:game.match_rules.winner=team;game.end_round(reason)
func actor_dead(team):dead[team]+=1
func advance(delta):
 if phase=="between":
  wait-=delta
  if wait<=0:
   number+=1;phase="combat";planted=false;progress=0;operator_id=0;dead={"red":0,"blue":0};game.restart_destruction_turn()
  return
 game.time_left=maxf(0,game.time_left-delta)
 if planted:
  fuse-=delta
  if fuse<=0:finish("red","Bomba patladı · Kırmızı takım turu kazandı");return
 elif game.time_left<=0:
  finish("blue","Tur süresi doldu · Mavi takım turu kazandı");return
 var populations={}
 for team in ["red","blue"]:
  populations[team]=game.bot_limit(team)+(1 if game.local_room.get("team","blue")==team else 0)
  if populations[team]>0 and dead[team]>=populations[team] and not (team=="red" and planted):finish("blue" if team=="red" else "red","Rakip takım elendi");return
 var workers=[]
 if game.health>0 and Input.is_action_pressed("interact"):workers.append(game.player)
 for actor in game.enemies.get_children():
  if game.actor_alive(actor) and actor.kind=="human" and not actor.sees_player:workers.append(actor)
 var worker=null
 for actor in workers:
  if game.actor_team(actor)==("blue" if planted else "red") and not (actor==game.player and actor.is_wolf) and nearby(actor) and Vector2(actor.velocity.x,actor.velocity.z).length()<0.3:worker=actor;break
 if worker==null:progress=0;operator_id=0;return
 if operator_id!=worker.get_instance_id():progress=0;operator_id=worker.get_instance_id()
 progress+=delta
 if progress>=float(tuning.defuseSeconds if planted else tuning.plantSeconds):
  if planted:finish("blue","Bomba çözüldü · Mavi takım turu kazandı")
  else:planted=true;bomb=worker.global_position;fuse=float(tuning.fuseSeconds);progress=0;operator_id=0;game.announce("Bomba kuruldu · Mavi takım bombayı çözmeli")
func objective(actor):
 if planted:return bomb
 if sites.is_empty():return actor.global_position
 var site=sites[actor.get_instance_id()%sites.size()];var point=site.get("approach",site.position)
 return Vector3(point[0],point[1],point[2])
