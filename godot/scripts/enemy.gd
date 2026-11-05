extends CharacterBody3D
const Rules=preload("res://scripts/bot_rules.gd")
var game
var kind="wolf"
var display_name="Bot"
var difficulty="normal"
var profile={}
var health=Rules.HEALTH
var attack_clock=0.0
var anim:AnimationPlayer
var active_clip=""
var body:Node3D
var body_base=Transform3D.IDENTITY
var capsule:CapsuleShape3D
var collider:CollisionShape3D
var navigator:NavigationAgent3D
var path_clock=0.0
var think_clock=0.0
var reaction=0.0
var memory=0.0
var sees_player=false
var has_target=false
var last_known=Vector3.ZERO
var destination=Vector3.ZERO
var state="patrol"
var patrol_points=[]
var patrol_index=0
var reload_remaining=0.0
var ammo=30
var reserve=90
var capacity=30
var fire_interval=0.15
var reload_seconds=2.5
var melee_windup=0.0
var rolling=false
var roll_time=0.0
var roll_cooldown=0.0
var roll_direction=Vector3.ZERO
var crouched=false
var weapon:Node3D
var fire_sound:AudioStreamPlayer3D
var reload_sound:AudioStreamPlayer3D
var weapon_data={}
var shots_fired=0
var reloads_completed=0
var rolls_completed=0
var brain_enabled=true
var cover_clock=0.0

func _ready():
 profile=Rules.profile(difficulty)
 collision_layer=2;collision_mask=3;floor_snap_length=0.35;floor_max_angle=deg_to_rad(48)
 set_meta("enemy",true)
 collider=CollisionShape3D.new();capsule=CapsuleShape3D.new();capsule.radius=0.42;capsule.height=1.9;collider.shape=capsule;collider.position.y=0.95;add_child(collider)
 navigator=NavigationAgent3D.new();navigator.path_desired_distance=0.55;navigator.target_desired_distance=0.8;navigator.radius=0.42;navigator.height=1.9;add_child(navigator)
 if game.offline_navigation_map.is_valid():navigator.set_navigation_map(game.offline_navigation_map)
 body=load(game.character_info[kind].asset).instantiate();body.scale*=1.6;body.rotation.y=PI;add_child(body);body_base=body.transform
 var players=body.find_children("*","AnimationPlayer",true,false)
 if not players.is_empty():
  anim=players[0]
  for clip in ["idle","run","crouch","crouch_run"]:
   if anim.has_animation(clip):anim.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
  play("idle");anim.advance(0)
 if kind=="human":prepare_weapon()
 var indicator=Label3D.new();indicator.text=("İNSAN" if kind=="human" else "KURT")+" · "+profile.name;indicator.position.y=2.25;indicator.font_size=26;indicator.modulate=Color("e2b2a7");indicator.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(indicator)
 build_patrol()
 destination=patrol_points[0] if not patrol_points.is_empty() else global_position

func prepare_weapon():
 weapon_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/bots/catalog.json"))
 capacity=int(weapon_data.capacity);ammo=capacity;reserve=capacity*3;fire_interval=float(weapon_data.fireInterval);reload_seconds=float(weapon_data.reloadSeconds)
 weapon=load(weapon_data.asset).instantiate()
 var skeletons=body.find_children("*","Skeleton3D",true,false)
 if not skeletons.is_empty():
  var skeleton=skeletons[0];var bone=skeleton.find_bone("Bip01 R Hand")
  if bone>=0:
   var attachment=BoneAttachment3D.new();attachment.bone_name="Bip01 R Hand";skeleton.add_child(attachment)
   var hand=skeleton.global_transform*skeleton.get_bone_global_pose(bone)
   var intended=Transform3D(global_basis,hand.origin-global_basis.z*0.24+Vector3.DOWN*0.02)
   attachment.add_child(weapon);weapon.transform=hand.affine_inverse()*intended
 if weapon.get_parent()==null:weapon.position=Vector3(0.18,1.35,-0.4);add_child(weapon)
 fire_sound=AudioStreamPlayer3D.new();fire_sound.bus="WolfWeapons";fire_sound.max_distance=40;fire_sound.volume_db=-15;fire_sound.stream=load(weapon_data.fireSound);add_child(fire_sound)
 reload_sound=AudioStreamPlayer3D.new();reload_sound.bus="WolfWeapons";reload_sound.max_distance=20;reload_sound.volume_db=-18;reload_sound.stream=load(weapon_data.reloadSound);add_child(reload_sound)

func build_patrol():
 if game.navigation_graph==null or not game.offline_navigation_map.is_valid():return
 var graph=game.navigation_graph
 var origin=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,global_position)
 var group=graph.component(origin)
 var candidates=[]
 for i in range(graph.centers.size()):
  if graph.components[i]==group and graph.centers[i].distance_to(global_position)>2.0:candidates.append(graph.centers[i])
 candidates.sort_custom(func(a,b):return a.distance_squared_to(global_position)<b.distance_squared_to(global_position))
 var stride=maxi(1,int(candidates.size()/16))
 for i in range(0,candidates.size(),stride):
  if reachable(candidates[i]):patrol_points.append(candidates[i])

func reachable(point):
 if not game.offline_navigation_map.is_valid():return false
 var map=game.offline_navigation_map
 var start=NavigationServer3D.map_get_closest_point(map,global_position)
 var end=NavigationServer3D.map_get_closest_point(map,point)
 if end.distance_to(point)>3:return false
 if game.navigation_graph==null or not game.navigation_graph.connected(start,end):return false
 var path=NavigationServer3D.map_get_path(map,start,end,true)
 return path.size()>=2 and path[-1].distance_to(end)<0.8

func can_see_player():
 var offset=game.player.global_position-global_position
 if offset.length()>38:return false
 if game.player.is_cloaked() and offset.length()>3:return false
 var flat=Vector3(offset.x,0,offset.z)
 if flat.length()>3 and flat.normalized().dot(-global_basis.z)<-0.25:return false
 return line_to_player()

func line_to_player():
 var eye=global_position+Vector3.UP*1.4
 var height=game.player.capsule.height*0.58 if is_instance_valid(game.player.capsule) else 1.0
 var query=PhysicsRayQueryParameters3D.create(eye,game.player.global_position+Vector3.UP*height,1,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 return not hit.is_empty() and hit.collider==game.player

func hear_noise(point,radius):
 if health<=0 or not game.running or game.menu_open:return
 var distance=point.distance_to(global_position)
 var query=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,point+Vector3.UP,1,[get_rid(),game.player.get_rid()])
 if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():radius*=0.55
 if distance<=radius:
  last_known=point;has_target=true;memory=float(profile.memory);destination=point

func think():
 var visible_now=can_see_player()
 if visible_now:
  if not sees_player:reaction=float(profile.reaction)
  last_known=game.player.global_position;has_target=true;memory=float(profile.memory)
 sees_player=visible_now
 if not sees_player and memory<=0:has_target=false
 if rolling or reload_remaining>0:return
 if state=="cover":
  if global_position.distance_to(destination)<1.3 or cover_clock<=0:begin_reload()
  return
 if kind=="human" and ammo<=0 and reserve>0:
  var cover=find_cover()
  if cover is Vector3 and global_position.distance_to(cover)>1.2:destination=cover;state="cover";cover_clock=4.0
  else:begin_reload()
  return
 if has_target:
  destination=last_known;state="chase" if sees_player else "investigate"
  var distance=global_position.distance_to(last_known)
  if sees_player and reaction<=0:
   if distance<(22 if kind=="human" and ammo>0 else 1.8):state="attack"
   if game.player.is_wolf and distance<4 and game.player.action_time>0 and randf()<float(profile.dodgeChance):begin_dodge()
 else:
  state="patrol"
  if patrol_points.is_empty():destination=global_position
  elif global_position.distance_to(destination)<1.0:
   patrol_index=(patrol_index+1)%patrol_points.size();destination=patrol_points[patrol_index]

func find_cover():
 if not game.offline_navigation_map.is_valid():return null
 var best=null;var cost=INF
 var count=int(profile.coverSamples)
 for i in range(count):
  var angle=TAU*float(i)/count
  var candidate=global_position+Vector3(cos(angle),0,sin(angle))*(3.0+float(i%2)*2.5)
  candidate=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,candidate)
  if absf(candidate.y-global_position.y)>1 or candidate.distance_to(global_position)<1.2:continue
  var clearance=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new();shape.radius=0.44;shape.height=1.9;clearance.shape=shape;clearance.transform=Transform3D(Basis.IDENTITY,candidate+Vector3.UP);clearance.collision_mask=1;clearance.exclude=[get_rid()]
  if not get_world_3d().direct_space_state.intersect_shape(clearance,1).is_empty():continue
  var ray=PhysicsRayQueryParameters3D.create(last_known+Vector3.UP*1.2,candidate+Vector3.UP*1.2,1,[get_rid(),game.player.get_rid()])
  if get_world_3d().direct_space_state.intersect_ray(ray).is_empty() or not reachable(candidate):continue
  var distance=candidate.distance_to(global_position)
  if distance<cost:best=candidate;cost=distance
 return best

func begin_reload():
 if not game.running or game.menu_open or health<=0:return false
 if kind!="human" or ammo>=capacity or reserve<=0 or reload_remaining>0 or rolling:return false
 reload_remaining=reload_seconds;state="reload";velocity.x=0;velocity.z=0;play("reload")
 if not game.test_mode:reload_sound.play()
 return true

func begin_dodge(direction=Vector3.ZERO):
 if not game.running or game.menu_open or health<=0:return false
 if rolling or roll_cooldown>0 or reload_remaining>0 or not is_on_floor():return false
 if direction.length()<0.1:direction=global_basis.x*(1 if randf()>0.5 else -1)
 direction.y=0;direction=direction.normalized()
 var old_height=capsule.height;capsule.height=1.1;collider.position.y=0.55
 var landing=global_position+direction*3.6
 var supported=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,landing) if game.offline_navigation_map.is_valid() else landing+Vector3.UP*100
 if test_move(global_transform,direction*3.6) or supported.distance_to(landing)>0.8 or not reachable(supported):
  capsule.height=old_height;collider.position.y=old_height*0.5;return false
 rolling=true;roll_time=0;roll_direction=direction;roll_cooldown=float(profile.dodgeCooldown);state="dodge"
 play("special_attack" if kind=="wolf" and anim.has_animation("special_attack") else "crouch")
 return true

func fire():
 if not game.running or game.menu_open or health<=0 or attack_clock>0:return false
 if kind!="human" or ammo<=0 or reload_remaining>0 or rolling or reaction>0 or not sees_player or not line_to_player():return false
 ammo-=1;shots_fired+=1;attack_clock=fire_interval;play("attack")
 var eye=global_position+Vector3.UP*1.4
 var target=game.player.global_position+Vector3.UP*game.player.capsule.height*0.58
 var direction=(target-eye).normalized()
 var spread=float(profile.spread)
 direction=(direction+global_basis.x*randf_range(-spread,spread)+Vector3.UP*randf_range(-spread,spread)).normalized()
 var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,eye+direction*45,1,[get_rid()]))
 if hit and hit.collider==game.player:game.take_damage(Rules.DAMAGE,global_position)
 if not game.test_mode:fire_sound.play()
 return true

func melee_hit():
 if global_position.distance_to(game.player.global_position)<2.1 and line_to_player():game.take_damage(Rules.DAMAGE,global_position)

func _physics_process(delta):
 if not game.is_combat_active() or health<=0 or is_queued_for_deletion():return
 attack_clock=maxf(0,attack_clock-delta);reaction=maxf(0,reaction-delta);memory=maxf(0,memory-delta);roll_cooldown=maxf(0,roll_cooldown-delta);cover_clock=maxf(0,cover_clock-delta)
 if position.y<game.preview_spawn.y-150:queue_free();return
 if not is_on_floor():velocity.y-=20*delta
 if melee_windup>0:
  melee_windup-=delta
  if melee_windup<=0:melee_hit()
 if rolling:
  roll_time+=delta;velocity.x=roll_direction.x*6.0;velocity.z=roll_direction.z*6.0
  var axis=Vector3.UP.cross(global_basis.inverse()*roll_direction).normalized()
  var center=Transform3D(Basis.IDENTITY,Vector3.UP*0.7)
  body.transform=center*Transform3D(Basis(axis,TAU*minf(1,roll_time/0.6)),Vector3.ZERO)*center.affine_inverse()*body_base
  if roll_time>=0.6:
   rolling=false;rolls_completed+=1;body.transform=body_base;active_clip=""
 elif reload_remaining>0:
  velocity.x=0;velocity.z=0;reload_remaining-=delta
  if reload_remaining<=0:
   var refill=mini(capacity-ammo,reserve);ammo+=refill;reserve-=refill;reloads_completed+=1;state="investigate";active_clip=""
 else:
  if capsule.height<1.9:
   var query=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new();shape.radius=0.42;shape.height=1.9;query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*0.95);query.collision_mask=1;query.exclude=[get_rid()]
   if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():capsule.height=1.9;collider.position.y=0.95
  if brain_enabled:
   think_clock-=delta
   if think_clock<=0:think_clock=float(profile.think);think()
  if state=="attack" and sees_player:
   velocity.x=0;velocity.z=0
   var offset=game.player.global_position-global_position;offset.y=0
   if offset.length()>0.1:rotation.y=lerp_angle(rotation.y,atan2(-offset.x,-offset.z),delta*7)
   if attack_clock<=0 and reaction<=0:
    if kind=="human" and ammo>0:fire()
    elif melee_windup<=0:melee_windup=0.28;attack_clock=1.1;play("attack")
   elif attack_clock<0.3 and melee_windup<=0:play("idle")
  else:
   path_clock-=delta
   if path_clock<=0:
    var map=game.offline_navigation_map
    var origin=NavigationServer3D.map_get_closest_point(map,global_position)
    var goal=NavigationServer3D.map_get_closest_point(map,destination)
    var reachable_goal=game.navigation_graph.nearest_in_component(origin,goal) if game.navigation_graph!=null else null
    navigator.target_position=reachable_goal if reachable_goal is Vector3 else origin
    path_clock=0.35
   var next=navigator.get_next_path_position()-global_position;next.y=0
   var direction=next.normalized() if not navigator.is_navigation_finished() else Vector3.ZERO
   var speed=5.2 if has_target or state=="cover" else 3.0
   velocity.x=direction.x*speed;velocity.z=direction.z*speed
   if direction.length()>0.1:rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*5);play("crouch_run" if capsule.height<1.9 else "run")
   else:play("idle")
 if not rolling:try_step(Vector3(velocity.x,0,velocity.z)*delta)
 move_and_slide()

func try_step(motion):
 if not is_on_floor() or motion.length()<0.001 or not test_move(global_transform,motion):return false
 var up=Vector3.UP*0.38
 if test_move(global_transform,up):return false
 var forward=motion.normalized()*0.6
 var raised=global_transform.translated(up)
 if test_move(raised,forward):return false
 var ray=PhysicsRayQueryParameters3D.create(raised.origin+forward+Vector3.UP*0.05,global_position+forward-Vector3.UP*0.05,1,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 if hit.is_empty() or hit.normal.y<0.67:return false
 var rise=hit.position.y-global_position.y
 if rise<0.03 or rise>0.38:return false
 var target=global_transform.translated(Vector3.UP*(rise+0.015))
 if test_move(global_transform,Vector3.UP*(rise+0.015)) or test_move(target,motion):return false
 global_position.y+=rise+0.015;velocity.y=0
 return true

func play(clip):
 if anim and anim.has_animation(clip) and active_clip!=clip:anim.play(clip,0.12);active_clip=clip

func is_head_hit(point,ray_origin=null,ray_direction=null):
 var skeletons=body.find_children("*","Skeleton3D",true,false)
 if skeletons.is_empty():return false
 var skeleton=skeletons[0];var index=skeleton.find_bone("Bip01 Head")
 if index<0:return false
 var center=skeleton.global_transform*skeleton.get_bone_global_pose(index).origin
 # The shared movement capsule can be hit before the animated head surface.
 # Classify its actual incoming ray against the source head bone, after the
 # first physics hit has already established visibility and target identity.
 var sample=point
 if ray_origin is Vector3 and ray_direction is Vector3:
  sample=Geometry3D.get_closest_point_to_segment(center,ray_origin,point+ray_direction.normalized()*1.2)
 return sample.distance_to(center)<0.28

func damage(amount,context={}):
 if health<=0 or amount<=0:return false
 game.match_stats.hits+=1;game.match_stats.damage+=mini(health,amount)
 health-=amount
 if health<=0:
  collision_layer=0;context=context.duplicate();context.target=display_name;game.enemy_defeated(context);queue_free()
 elif sees_player and randf()<float(profile.dodgeChance):begin_dodge()
 return true
