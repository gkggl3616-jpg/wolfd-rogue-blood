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
  if not valid(point) or not lane_clear(point,threat):continue
  var cost=actor.global_position.distance_to(point)*.45+absf(point.distance_to(threat)-preferred)*1.3
  for other in game.enemies.get_children():
   if other!=actor and game.actor_alive(other) and other.team==actor.team:
    cost+=maxf(0,3-point.distance_to(other.global_position))*4
    if other.tactics!=null and other.tactics.goal_valid:cost+=maxf(0,2-point.distance_to(other.tactics.goal))*3
  if cost<best_cost:best=point;best_cost=cost
 if best is Vector3:goal=best;goal_valid=true;cooldown=1.1
 return best
func advance(delta):
 cooldown=maxf(0,cooldown-delta);recovery=maxf(0,recovery-delta)
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
