extends RefCounted
# Local, geometry-checked tactics. Only perceived last_known is a threat input.
const RANGES={"rifle":Vector2(9,26),"smg":Vector2(5,17),"shotgun":Vector2(3,10),"machinegun":Vector2(11,26),"pistol":Vector2(5,17),"sniper":Vector2(18,36),"heavy":Vector2(12,27),"rocket":Vector2(10,24),"launcher":Vector2(8,23),"grenade":Vector2(6,18)}
var actor
var goal=Vector3.ZERO
var goal_valid=false
var cooldown=0.0
var recovery=0.0
var stuck_clock=0.0
var progress_origin=Vector3.ZERO
var recoveries=0
func ranges():return RANGES.get(actor.weapon_data.get("category","rifle"),Vector2(8,22)) if actor.uses_firearm() else Vector2(0,1.8)
func valid(point):
 var game=actor.game
 if not game.offline_navigation_map.is_valid():return false
 var nav=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,point)
 if nav.distance_to(point)>1.5 or absf(nav.y-actor.global_position.y)>2:return false
 if not actor.reachable(nav):return false
 var query=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new();shape.radius=actor.capsule.radius;shape.height=actor.capsule.height;query.shape=shape;query.margin=.001;query.transform=Transform3D(Basis.IDENTITY,nav+Vector3.UP*(shape.height*.5+.05));query.collision_mask=3;query.exclude=[actor.get_rid()]
 return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func lane_clear(point,threat):
 var exclude=[actor.game.player.get_rid()]
 for other in actor.game.enemies.get_children():exclude.append(other.get_rid())
 var query=PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.35,threat+Vector3.UP,1,exclude)
 return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func plan(threat,retreat=false):
 var game=actor.game;var map=game.offline_navigation_map
 if not map.is_valid():return null
 var delta=threat-actor.global_position;delta.y=0
 var forward=delta.normalized() if delta.length()>.1 else -actor.global_basis.z
 var side=forward.cross(Vector3.UP).normalized();var range=ranges();var distance=clampf(delta.length(),range.x+2,range.y-2) if actor.uses_firearm() else 1.6
 var preferred=(range.x+range.y)*.5 if retreat else distance
 var sign=float(actor.roster_identity.get("side",1));var role=actor.roster_identity.get("role","assault");var best=null;var best_cost=INF
 for i in range(10):
  var angle=sign*(.22+float(i%5)*.18);var radial=forward.rotated(Vector3.UP,angle)
  var desired=threat-radial*(preferred+float(i/5)*2)+side*sign*(2.5 if role=="flanker" else 1.0)
  var point=NavigationServer3D.map_get_closest_point(map,desired)
  if not valid(point) or not lane_clear(point,threat) or not game.bot_squads.available(actor,point):continue
  var cost=actor.global_position.distance_to(point)*.45+absf(point.distance_to(threat)-preferred)*1.3
  for other in game.enemies.get_children():
   if other!=actor and game.actor_alive(other) and other.team==actor.team:
    cost+=maxf(0,3-point.distance_to(other.global_position))*4
    if other.tactics!=null and other.tactics.goal_valid:cost+=maxf(0,2-point.distance_to(other.tactics.goal))*3
  if cost<best_cost:best=point;best_cost=cost
 if best is Vector3 and game.bot_squads.reserve(actor,best,"attack"):goal=best;goal_valid=true;cooldown=1.1
 return best
func advance(delta):
 cooldown=maxf(0,cooldown-delta);recovery=maxf(0,recovery-delta);under_fire=maxf(0,under_fire-delta);defensive_cooldown=maxf(0,defensive_cooldown-delta);cover_left=maxf(0,cover_left-delta)
 if cover_phase!="":cover_age+=delta
 if not actor.brain_enabled or actor.rolling or actor.reload_remaining>0 or not actor.is_on_floor():stuck_clock=0;progress_origin=actor.global_position;return
 stuck_clock+=delta
 if stuck_clock<1.4:return
 var moved=progress_origin.distance_to(actor.global_position);progress_origin=actor.global_position;stuck_clock=0
 if moved>.35 or actor.requested_motion.length()<.4 or actor.global_position.distance_to(actor.destination)<1.2:return
 for i in range(8):
  var angle=TAU*float((i+int(actor.roster_identity.get("slot",0)))%8)/8;var candidate=actor.global_position+Vector3(cos(angle),0,sin(angle))*3
  if valid(candidate):
   goal=NavigationServer3D.map_get_closest_point(actor.game.offline_navigation_map,candidate);goal_valid=true;recovery=1.2;recoveries+=1;actor.destination=goal;actor.path_clock=0;return
func separation(direction):
 var push=Vector3.ZERO
 for other in actor.game.enemies.get_children():
  if other==actor or not actor.game.actor_alive(other):continue
  var offset=actor.global_position-other.global_position;offset.y=0;var d=offset.length()
  if d>.01 and d<1.35:push+=offset/d*(1.35-d)*.75
 var result=direction+push
 return result.normalized() if result.length()>.05 else direction

var under_fire=0.0
var cover_phase=""
var cover_anchor=Vector3.ZERO
var peek_goal=Vector3.ZERO
var cover_left=0.0
var cover_age=0.0
var defensive_cooldown=0.0
var cover_cycles=0
var cover_entries=0
var peeks=0
var reports_received=0
var last_shot=-1000.0
func approach(threat):
 var squad=actor.game.bot_squads
 var role=actor.roster_identity.get("role","assault");var side=float(actor.roster_identity.get("side",1));var delta=threat-actor.global_position;delta.y=0
 var forward=delta.normalized() if delta.length()>.1 else -actor.global_basis.z
 var preferred=(ranges().x+ranges().y)*.5 if actor.uses_firearm() else 1.8
 var supported=role=="flanker" and squad.covering_fire(actor)
 if supported and actor.uses_firearm():preferred=maxf(3,ranges().x+2)
 var best=null;var score=INF
 for i in range(12):
  var angle=side*((.95 if supported else (.65 if role=="flanker" else .15))+float(i%6)*.16)
  var candidate=threat-forward.rotated(Vector3.UP,angle)*(preferred+float(i/6)*2)
  var point=NavigationServer3D.map_get_closest_point(actor.game.offline_navigation_map,candidate)
  if not valid(point) or not squad.available(actor,point):continue
  var value=point.distance_to(actor.global_position)*.3+absf(point.distance_to(threat)-preferred)
  if value<score:best=point;score=value
 if best is Vector3 and squad.reserve(actor,best,"approach"):goal=best;goal_valid=true;cooldown=1.4;return best
 return null
func should_take_cover():return actor.uses_firearm() and cover_phase=="" and defensive_cooldown<=0 and (under_fire>0 or actor.health<actor.max_health()*.65)
func begin_cover():
 var point=actor.find_cover()
 if not point is Vector3 or not actor.game.bot_squads.reserve(actor,point,"cover"):defensive_cooldown=1;return false
 cover_anchor=point;cover_phase="move";cover_left=3.5;cover_age=0;cover_cycles=0;cover_entries+=1;actor.destination=point;actor.state="cover_move";return true
func stop_cover():
 cover_phase="";defensive_cooldown=2.5
 for purpose in ["cover","peek"]:actor.game.bot_squads.claims.erase(actor.roster_id+":"+purpose)
func find_peek():
 for i in range(24):
  var angle=TAU*float((i+int(actor.roster_identity.get("slot",0))*3)%12)/12
  var desired=cover_anchor+Vector3(cos(angle),0,sin(angle))*(1.2+float(i/12)*1.1)
  var point=NavigationServer3D.map_get_closest_point(actor.game.offline_navigation_map,desired)
  if valid(point) and lane_clear(point,actor.last_known) and actor.game.bot_squads.reserve(actor,point,"peek"):return point
 return null
func defend():
 if cover_phase=="":return false
 if not actor.has_target or cover_age>10:stop_cover();return false
 actor.attack_moving=false
 if cover_phase=="move":
  actor.destination=cover_anchor;actor.state="cover_move"
  if actor.global_position.distance_to(cover_anchor)<.85:cover_phase="hold";cover_left=.55+float(int(actor.roster_identity.get("slot",0))%3)*.16;actor.state="cover_hold"
  elif cover_left<=0:stop_cover();return false
 elif cover_phase=="hold":
  actor.state="cover_hold";actor.destination=cover_anchor
  if cover_left>0:return true
  if actor.ammo<maxi(1,int(actor.capacity*.5)) and actor.reserve>0 and actor.begin_reload():cover_left=.2;return true
  var point=find_peek()
  if not point is Vector3:stop_cover();return false
  peek_goal=point;cover_phase="peek_move";cover_left=2.4;peeks+=1
 elif cover_phase=="peek_move":
  actor.state="cover_peek";actor.destination=peek_goal
  if lane_clear(actor.global_position,actor.last_known) and actor.line_to_player():peek_goal=actor.global_position;cover_phase="peek";cover_left=1.1;under_fire=0
  elif cover_left<=0:stop_cover();return false
 elif cover_phase=="peek":
  actor.state="attack" if actor.sees_player else "cover_peek";actor.destination=peek_goal
  if cover_left<=0 or under_fire>0:
   cover_cycles+=1
   if cover_cycles>=2:stop_cover();return false
   cover_phase="move";cover_left=3.5
 return true
