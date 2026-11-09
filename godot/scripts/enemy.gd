extends CharacterBody3D
const Rules=preload("res://scripts/bot_rules.gd")
const Traversal=preload("res://scripts/bot_traversal.gd")
var game
var team="red"
var opponent
var character_info={}
var roster_identity={}
var tactics
var attack_goal=Vector3.ZERO
var attack_moving=false
var source_events
var target_clock=0.0
var kind="wolf"
var display_name="Bot"
var roster_id=""
var nameplate:Label3D
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
var reload_phase=""
var requested_motion=Vector3.ZERO
var ammo=30
var reserve=90
var capacity=30
var fire_interval=0.15
var reload_seconds=2.5
var melee_windup=0.0
var pending_melee={}
var next_right_attack=false
var claw_trail
var rolling=false
var roll_time=0.0
var roll_cooldown=0.0
var roll_direction=Vector3.ZERO
var crouched=false
var weapon:Node3D
var weapon_attachment
var weapon_inventory={}
var native_hand_socket_verified=false
var fire_sound:AudioStreamPlayer3D
var reload_sound:AudioStreamPlayer3D
var weapon_data={}
var shots_fired=0
var reloads_completed=0
var rolls_completed=0
var brain_enabled=true
var cover_clock=0.0
var link_flight={}
var jumps_completed=0

func _ready():
 health=int(game.mutations.profile("normal").health) if kind=="wolf" else game.mutations.HUMAN_HEALTH
 profile=Rules.profile(difficulty)
 tactics=preload("res://scripts/bot_tactics.gd").new();tactics.actor=self;tactics.progress_origin=global_position
 opponent=game.player if team!=game.local_room.get("team","blue") else null
 collision_layer=2;collision_mask=3;floor_snap_length=0.35;floor_max_angle=deg_to_rad(48)
 set_meta("enemy",true);set_meta("source_native_attachment",true)
 collider=CollisionShape3D.new();capsule=CapsuleShape3D.new();capsule.radius=0.42;capsule.height=1.9;collider.shape=capsule;collider.position.y=0.95;add_child(collider)
 navigator=NavigationAgent3D.new();navigator.path_desired_distance=0.55;navigator.target_desired_distance=0.8;navigator.radius=0.42;navigator.height=1.9;add_child(navigator)
 navigator.link_reached.connect(begin_link_traversal)
 if game.offline_navigation_map.is_valid():navigator.set_navigation_map(game.offline_navigation_map)
 var character=character_info if not character_info.is_empty() else game.book.character_for_team(team)
 if character.is_empty():character=game.character_info
 character_info=character
 body=load(character[kind].asset).instantiate()
 if kind=="wolf":preload("res://scripts/wolf_surface.gd").apply(body)
 body.scale*=1.6;body.rotation.y=PI;add_child(body);body_base=body.transform
 var players=body.find_children("*","AnimationPlayer",true,false)
 if not players.is_empty():
  anim=players[0]
  for clip in ["idle","run","crouch","crouch_run"]:
   if anim.has_animation(clip):anim.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
  play("idle");anim.advance(0)
 if kind=="human":prepare_weapon()
 else:
  game.clientfx.install_right_attack(self);claw_trail=Node3D.new();claw_trail.set_script(preload("res://scripts/claw_trail.gd"));claw_trail.player=self;add_child(claw_trail)
 nameplate=Label3D.new();nameplate.text=display_name;nameplate.position.y=2.25;nameplate.font_size=20;nameplate.pixel_size=.0015;nameplate.outline_size=3;nameplate.fixed_size=true;nameplate.modulate=Color("92c9ed");nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED;nameplate.hide();add_child(nameplate)
 source_events=Node.new();source_events.set_script(preload("res://scripts/actor_source_events.gd"));source_events.actor=self;add_child(source_events)
 build_patrol()
 patrol_index=int(roster_identity.get("slot",0))*3%maxi(1,patrol_points.size())
 destination=patrol_points[patrol_index] if not patrol_points.is_empty() else global_position
 # Enemy spawn anchors are static map knowledge, never hidden live actor positions.
 if not game.destruction.enabled:
  var opposite="red" if team=="blue" else "blue";var objectives=[]
  if game.offline_map_number==0:
   for x in [-9,-3,3,9]:objectives.append(Vector3(x,0,12 if opposite=="blue" else -12))
  else:
   for anchor in game.team_start_points(game.map_catalog.offline_record(game.offline_map_number),opposite):
    var p=anchor.position;objectives.append(Vector3(p[0],p[1],p[2]))
  var connected=objectives.filter(func(point):return reachable(point))
  if not connected.is_empty():destination=NavigationServer3D.map_get_closest_point(game.offline_navigation_map,connected[int(roster_identity.get("slot",0))%connected.size()])

func prepare_weapon(next_profile={}):
 if not weapon_data.is_empty():weapon_inventory[weapon_data.get("itemId","legacy")]={"ammo":ammo,"reserve":reserve}
 if is_instance_valid(weapon_attachment):weapon_attachment.get_parent().remove_child(weapon_attachment);weapon_attachment.queue_free()
 elif is_instance_valid(weapon):weapon.get_parent().remove_child(weapon);weapon.queue_free()
 for sound in [fire_sound,reload_sound]:
  if is_instance_valid(sound):remove_child(sound);sound.queue_free()
 weapon_attachment=null;native_hand_socket_verified=false
 weapon_data=next_profile if not next_profile.is_empty() else game.bot_weapon_profile(self)
 capacity=int(weapon_data.capacity);var stored=weapon_inventory.get(weapon_data.get("itemId","legacy"),{"ammo":capacity,"reserve":capacity*3});ammo=int(stored.ammo);reserve=int(stored.reserve);fire_interval=float(weapon_data.fireInterval);reload_seconds=float(weapon_data.reloadSeconds);reload_remaining=0
 weapon=load(weapon_data.asset).instantiate()
 var skeletons=body.find_children("*","Skeleton3D",true,false)
 if not skeletons.is_empty():
  var skeleton=skeletons[0];var bone=skeleton.find_bone("Bip01 R Hand")
  if bone>=0:
   var attachment=BoneAttachment3D.new();attachment.bone_name="Bip01 R Hand";skeleton.add_child(attachment);weapon_attachment=attachment
   var hand=skeleton.global_transform*skeleton.get_bone_global_pose(bone)
   var intended=Transform3D(global_basis,hand.origin-global_basis.z*0.24+Vector3.DOWN*0.02)
   attachment.add_child(weapon);weapon.transform=hand.affine_inverse()*intended
   var info=game.clientfx.model_record(self);var sockets=game.clientfx.animations.models.get(info.get("donor",""),{}).get("sockets",[])
   for socket in sockets:
    if socket.name!="RightHand" or socket.boneName!=attachment.bone_name:continue
    var q=socket.rotation;var p=socket.position;var scale=socket.scale
    # Both the body skeleton and HH source vertices use .016 world units.
    # The native hand socket supplies rotation/offset; remove a second root scale.
    weapon.transform=Transform3D(Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized()).scaled(Vector3(scale[0],scale[1],scale[2])),Vector3(p[0],p[1],p[2]));native_hand_socket_verified=true;break
 if weapon.get_parent()==null:weapon.position=Vector3(0.18,1.35,-0.4);add_child(weapon)
 fire_sound=AudioStreamPlayer3D.new();fire_sound.bus="WolfWeapons";fire_sound.max_distance=40;fire_sound.volume_db=-15;fire_sound.stream=load(weapon_data.fireSound) if weapon_data.fireSound!="" else null;add_child(fire_sound)
 reload_sound=AudioStreamPlayer3D.new();reload_sound.bus="WolfWeapons";reload_sound.max_distance=20;reload_sound.volume_db=-18;reload_sound.stream=load(weapon_data.reloadSound) if weapon_data.reloadSound!="" else null;add_child(reload_sound)

func native_socket_transform(name):
 if not is_instance_valid(weapon):return global_transform
 var found=weapon.find_children("*","Skeleton3D",true,false)
 if found.is_empty():return weapon.global_transform
 var sockets=weapon_data.get("sockets",[]).filter(func(s):return s.name==name)
 if sockets.is_empty():return weapon.global_transform
 var socket=sockets[0];var skeleton=found[0];var bone=preload("res://scripts/native_socket_bone.gd").find(skeleton,socket,weapon_data.get("bones",[]))
 if bone<0:return weapon.global_transform
 var q=socket.rotation;var p=socket.position;var transform=skeleton.global_transform*skeleton.get_bone_global_pose(bone)*Transform3D(Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized()),Vector3(p[0],p[1],p[2]))
 return Transform3D(transform.basis.orthonormalized(),transform.origin)
func play_native_muzzle():
 var source=weapon_data.get("hhMuzzleFx","")
 if source=="" or game.clientfx.canonical(source)=="":return null
 if not weapon_data.get("sockets",[]).any(func(s):return s.name=="Flash"):return null
 return game.clientfx.play(source,null,native_socket_transform("Flash").origin,false,0,self)

func max_health():return int(game.mutations.profile("normal").health) if kind=="wolf" else game.mutations.HUMAN_HEALTH
func uses_firearm():return kind=="human" and weapon_data.get("category","")!="knife"

func _process(_delta):
 if is_instance_valid(anim):anim.active=game.is_match_active() and health>0
 if is_instance_valid(nameplate):nameplate.visible=game.running and not game.menu_open and not game.selection_active and health>0 and team==game.local_room.get("team","blue") and global_position.distance_to(game.player.global_position)>2

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

func choose_opponent():
 var candidates=game.combat_targets(team)
 candidates.sort_custom(func(a,b):return global_position.distance_squared_to(a.global_position)<global_position.distance_squared_to(b.global_position))
 var previous=opponent
 for candidate in candidates:
  opponent=candidate
  if can_see_player():return
 opponent=previous if game.actor_alive(previous) else (candidates[0] if not candidates.is_empty() else null)

func can_see_player():
 if not game.actor_alive(opponent):return false
 var offset=opponent.global_position-global_position
 if offset.length()>38:return false
 if opponent.has_method("is_cloaked") and opponent.is_cloaked() and offset.length()>3:return false
 var flat=Vector3(offset.x,0,offset.z)
 if flat.length()>3 and flat.normalized().dot(-global_basis.z)<-0.25:return false
 return line_to_player()

func line_to_player():
 if not game.actor_alive(opponent):return false
 var eye=global_position+Vector3.UP*minf(1.4,capsule.height*.8)
 var height=opponent.capsule.height*0.58 if is_instance_valid(opponent.capsule) else 1.0
 var query=PhysicsRayQueryParameters3D.create(eye,opponent.global_position+Vector3.UP*height,3,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 return not hit.is_empty() and hit.collider==opponent

func hear_noise(point,radius):
 if health<=0 or not game.running or game.menu_open:return
 var distance=point.distance_to(global_position)
 var query=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,point+Vector3.UP,1,[get_rid(),game.player.get_rid()])
 if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():radius*=0.55
 if distance<=radius:
  last_known=point;has_target=true;memory=float(profile.memory);destination=point

func think():
 target_clock-=float(profile.think)
 if target_clock<=0 or not game.actor_alive(opponent):choose_opponent();target_clock=0.5
 var visible_now=can_see_player()
 if visible_now:
  if not sees_player:reaction=float(profile.reaction)
  last_known=opponent.global_position;has_target=true;memory=float(profile.memory);game.bot_squads.report(self,opponent,last_known)
 sees_player=visible_now
 if not sees_player:
  var shared=game.bot_squads.contact(self)
  if not shared.is_empty():
   last_known=shared.point;opponent=shared.target.get_ref();has_target=true;memory=minf(float(profile.memory),shared.until-game.bot_squads.clock);tactics.reports_received+=1
 if not sees_player and memory<=0:has_target=false
 if rolling or reload_remaining>0:return
 if tactics.recovery>0:destination=tactics.goal;state="reposition";return
 if state=="cover":
  if global_position.distance_to(destination)<1.3 or cover_clock<=0:begin_reload()
  return
 if uses_firearm() and ammo<=0 and reserve<=0:
  for key in ["secondaryId","knifeId"]:
   var id=roster_identity.get(key,"");var profile=game.bot_roster.arsenal.get(id,{})
   if not profile.is_empty() and id!=weapon_data.get("itemId","") and (not weapon_inventory.has(id) or int(weapon_inventory[id].ammo)+int(weapon_inventory[id].reserve)>0):prepare_weapon(profile);break
 if uses_firearm() and reserve>0 and (ammo<=0 or (not sees_player and has_target and ammo<maxi(1,int(capacity*.25)))):
  var cover=find_cover()
  if cover is Vector3 and global_position.distance_to(cover)>1.2:destination=cover;state="cover";cover_clock=4.0
  else:begin_reload()
  return
 if brain_enabled and uses_firearm():
  if tactics.defend():return
  if has_target and tactics.should_take_cover() and tactics.begin_cover():return
 if has_target:
  destination=last_known;state="chase" if sees_player else "investigate"
  if not sees_player and brain_enabled:
   if tactics.cooldown<=0:tactics.approach(last_known)
   if tactics.goal_valid:destination=tactics.goal
  var distance=global_position.distance_to(last_known)
  if sees_player and reaction<=0:
   attack_moving=false
   var range=tactics.ranges()
   if distance<range.y and (not uses_firearm() or ammo>0):
    state="attack"
    if uses_firearm() and brain_enabled:
     var role=roster_identity.get("role","assault")
     if tactics.cooldown<=0 and (distance<range.x or role in ["assault","flanker"]):tactics.plan(last_known,distance<range.x)
     if tactics.goal_valid and global_position.distance_to(tactics.goal)>.8:attack_goal=tactics.goal;attack_moving=true
   elif uses_firearm() and brain_enabled and tactics.cooldown<=0:
    var point=tactics.plan(last_known)
    if point is Vector3:destination=point
   if opponent==game.player and game.player.is_wolf and distance<4 and game.player.action_time>0 and randf()<float(profile.dodgeChance):begin_dodge()
 else:
  state="patrol"
  if game.destruction.enabled:destination=game.destruction.objective(self)
  elif patrol_points.is_empty():destination=global_position
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
  if absf(candidate.y-global_position.y)>1 or candidate.distance_to(global_position)<1.2 or not game.bot_squads.available(self,candidate):continue
  var clearance=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new();shape.radius=0.44;shape.height=1.9;clearance.shape=shape;clearance.transform=Transform3D(Basis.IDENTITY,candidate+Vector3.UP);clearance.collision_mask=3;clearance.exclude=[get_rid()]
  if not get_world_3d().direct_space_state.intersect_shape(clearance,1).is_empty():continue
  var ray=PhysicsRayQueryParameters3D.create(last_known+Vector3.UP*1.2,candidate+Vector3.UP*1.2,1,[get_rid(),game.player.get_rid()])
  if get_world_3d().direct_space_state.intersect_ray(ray).is_empty() or not reachable(candidate):continue
  var distance=candidate.distance_to(global_position)
  if distance<cost:best=candidate;cost=distance
 return best

func begin_reload():
 if not game.running or game.menu_open or health<=0:return false
 if kind!="human" or ammo>=capacity or reserve<=0 or reload_remaining>0 or rolling:return false
 reload_phase="insert" if weapon_data.get("reloadPerShell",false) else "magazine"
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
 if not game.actor_alive(opponent):return false
 if not uses_firearm() or ammo<=0 or reload_remaining>0 or rolling or reaction>0 or not sees_player or not line_to_player():return false
 ammo-=1;shots_fired+=1;tactics.last_shot=game.bot_squads.clock;attack_clock=fire_interval;play("attack");play_native_muzzle()
 var eye=global_position+Vector3.UP*minf(1.4,capsule.height*.8)
 var target=opponent.global_position+Vector3.UP*opponent.capsule.height*0.58
 var direction=(target-eye).normalized()
 var spread=float(profile.spread)
 direction=(direction+global_basis.x*randf_range(-spread,spread)+Vector3.UP*randf_range(-spread,spread)).normalized()
 var native=weapon_data.get("native",{})
 if native.get("projectile","")!="":
  native=native.duplicate(true);native.baseDamage=Rules.DAMAGE if native.baseDamage>0 else 0;native.splashDamage=Rules.DAMAGE if native.splashDamage>0 else 0
  game.launch_projectile(native,weapon_data.name,self,direction)
 else:
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,eye+direction*45,3,[get_rid()]))
  if hit and hit.collider==opponent:hit_opponent()
 if not game.test_mode:fire_sound.play()
 return true

func hit_opponent():
 if not game.hostile(opponent,team):return
 var context={"name":display_name,"weapon":weapon_data.get("name","Tüfek") if kind=="human" else "Pençe","attackerTeam":team,"actor":"bot","sourceActor":self,"sourcePosition":global_position,"rosterId":roster_id}
 if opponent==game.player:game.take_damage(Rules.DAMAGE,global_position,context)
 else:opponent.damage(Rules.DAMAGE,context)
func begin_melee():
 var clip="attack_right" if kind=="wolf" and next_right_attack and anim.has_animation("attack_right") else "attack"
 next_right_attack=not next_right_attack;source_events.restart_melee();play(clip)
 attack_clock=maxf(.65,anim.get_animation(clip).length if anim.has_animation(clip) else 1.1)
 var record=game.clientfx.animation_record(self,clip)
 if kind=="wolf" and record.get("events",[]).any(func(e):return str(e.key).to_lower().contains("fire_key")):pending_melee={"clip":clip}
 else:melee_windup=.28
func resolve_melee_event(clip):
 if pending_melee.is_empty() or pending_melee.clip!=clip:return
 pending_melee={}
 if game.is_match_active() and health>0:melee_hit()
func melee_hit():
 if kind=="wolf" and is_instance_valid(claw_trail) and not source_events.has_spline():claw_trail.begin()
 if game.actor_alive(opponent) and global_position.distance_to(opponent.global_position)<2.1 and line_to_player():hit_opponent()

func _physics_process(delta):
 if not game.is_match_active() or health<=0 or is_queued_for_deletion():return
 if not link_flight.is_empty():
  link_flight.elapsed+=delta
  velocity=link_flight.velocity-Vector3.UP*20*link_flight.elapsed
  move_and_slide();play("jump")
  if link_flight.elapsed>=link_flight.seconds or (link_flight.elapsed>0.1 and is_on_floor()):link_flight={};jumps_completed+=1;path_clock=0
  return
 tactics.advance(delta)
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
  velocity.x=0;velocity.z=0;advance_reload(delta)
 else:
  if capsule.height<1.5 and not (tactics.cover_phase=="hold" or state=="cover_hold"):
   if preload("res://scripts/character_motion.gd").can_stand(self,1.9):capsule.height=1.9;collider.position.y=.95
  if brain_enabled:
   think_clock-=delta
   if think_clock<=0:think_clock=float(profile.think);think()
  if state=="cover_hold":
   velocity.x=0;velocity.z=0;capsule.height=1.2;collider.position.y=.6;play("crouch")
  elif state=="attack" and sees_player and game.actor_alive(opponent):
   velocity.x=0;velocity.z=0
   if brain_enabled and attack_moving:
    var movement=nav_direction(attack_goal);velocity.x=movement.x*3.4;velocity.z=movement.z*3.4
   var offset=opponent.global_position-global_position;offset.y=0
   if offset.length()>0.1:rotation.y=lerp_angle(rotation.y,atan2(-offset.x,-offset.z),delta*7)
   if attack_clock<=0 and reaction<=0:
    if uses_firearm() and ammo>0:fire()
    elif not uses_firearm() and melee_windup<=0 and pending_melee.is_empty():begin_melee()
   elif attack_clock<0.3 and melee_windup<=0 and pending_melee.is_empty():play("idle")
  else:
   navigator.target_desired_distance=.2 if state=="cover_peek" else (.4 if state=="cover_move" else .8)
   path_clock-=delta
   if path_clock<=0:
    var map=game.offline_navigation_map
    var origin=NavigationServer3D.map_get_closest_point(map,global_position)
    var goal=NavigationServer3D.map_get_closest_point(map,destination)
    var reachable_goal=game.navigation_graph.nearest_in_component(origin,goal) if game.navigation_graph!=null else null
    navigator.target_position=reachable_goal if reachable_goal is Vector3 else origin
    path_clock=0.35
   var next=navigator.get_next_path_position()-global_position;next.y=0
   var direction=tactics.separation(next.normalized()) if not navigator.is_navigation_finished() else Vector3.ZERO
   var speed=5.2 if has_target or state=="cover" else 3.0
   velocity.x=direction.x*speed;velocity.z=direction.z*speed
   if direction.length()>0.1:
    adapt_stance(direction)
    if capsule.height<1.5:velocity.x*=0.6;velocity.z*=0.6
    rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*5);play("jump" if not is_on_floor() else ("crouch_run" if capsule.height<1.5 else "run"))
   else:play("idle")
   if state=="cover_peek":
    var aim=last_known-global_position;aim.y=0
    if aim.length()>.1:rotation.y=lerp_angle(rotation.y,atan2(-aim.x,-aim.z),delta*7)
   if state=="cover_peek" and sees_player and reaction<=0 and attack_clock<=0:fire()
 if not rolling:
  var motion=Vector3(velocity.x,0,velocity.z)*delta
  if not try_step(motion):try_jump(motion)
 if not link_flight.is_empty():velocity=link_flight.velocity
 requested_motion=Vector3(velocity.x,0,velocity.z)
 move_and_slide()

func advance_reload(delta):
 if reload_remaining<=0 or delta<=0 or not game.is_match_active() or health<=0:return
 var remaining=delta
 while reload_remaining>0 and remaining>0:
  var step=minf(remaining,reload_remaining);remaining-=step;reload_remaining-=step
  if reload_remaining>.000001:break
  reload_remaining=0
  if reload_phase=="finish":reload_phase="";reloads_completed+=1;state="investigate";active_clip="";break
  var per_shell=weapon_data.get("reloadPerShell",false)
  var refill=mini(1 if per_shell else capacity-ammo,reserve);ammo+=refill;reserve-=refill
  if per_shell:
   if ammo<capacity and reserve>0 and not (sees_player and ammo>=mini(2,capacity)):
    reload_remaining=reload_seconds;active_clip="";play("reload")
   else:reload_phase="finish";reload_remaining=float(weapon_data.get("reloadFinishSeconds",.5))
  else:reload_phase="";reloads_completed+=1;state="investigate";active_clip=""

func nav_direction(goal):
 if path_clock<=0 or navigator.target_position.distance_to(goal)>1:
  navigator.target_position=goal;path_clock=.35
 path_clock-=get_physics_process_delta_time()
 var next=navigator.get_next_path_position()-global_position;next.y=0
 return tactics.separation(next.normalized()) if not navigator.is_navigation_finished() else Vector3.ZERO

func begin_link_traversal(details):
 if not link_flight.is_empty() or not details.has("rid") or not is_on_floor():return
 var owner_id=NavigationServer3D.link_get_owner_id(details.rid)
 var link=instance_from_id(owner_id) if owner_id!=0 else null
 if not is_instance_valid(link) or not link.has_meta("traversal"):return
 var spec=link.get_meta("traversal");var a=spec.feetEntry;var b=spec.feetExit
 var from=Vector3(a[0],a[1],a[2]);var to=Vector3(b[0],b[1],b[2])
 if global_position.distance_to(to)<global_position.distance_to(from):var swap=from;from=to;to=swap
 if global_position.distance_to(from)>0.8:return
 var flight=Traversal.plan(get_world_3d().direct_space_state,global_position,to,[get_rid()])
 if flight.is_empty():return
 flight.elapsed=0.0;link_flight=flight;capsule.height=1.2;collider.position.y=0.6;play("jump")

func adapt_stance(direction):
 var query=PhysicsShapeQueryParameters3D.new();query.collision_mask=1;query.exclude=[get_rid()]
 var shape=CapsuleShape3D.new();shape.radius=0.42;shape.height=1.9;query.shape=shape
 var ahead=global_position+direction*0.7
 query.transform=Transform3D(Basis.IDENTITY,ahead+Vector3.UP)
 if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return
 shape.height=1.2;query.transform.origin=ahead+Vector3.UP*0.65
 if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():capsule.height=1.2;collider.position.y=0.6

func try_jump(motion):
 if motion.length()<0.001 or not is_on_floor() or rolling or reload_remaining>0:return false
 var forward=motion.normalized()*0.9
 if not test_move(global_transform,forward):return false
 var ray=PhysicsRayQueryParameters3D.create(global_position+forward+Vector3.UP*0.9,global_position+forward+Vector3.UP*0.3,1,[get_rid()])
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 if hit.is_empty() or hit.normal.y<0.67:return false
 var rise=hit.position.y-global_position.y
 if rise<0.38 or rise>0.8:return false
 var raised=global_transform.translated(Vector3.UP*(rise+0.08))
 if test_move(global_transform,Vector3.UP*(rise+0.08)) or test_move(raised,forward):return false
 velocity.y=6.3;play("jump");return true

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
 if kind=="wolf":game.clientfx.install_wolf_pose(self,clip)
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
 if context.get("actor","")!="bot":
  if team==game.local_room.get("team","blue"):return false
  game.record_player_hit(mini(health,amount),context)
 elif context.get("attackerTeam",team)==team:return false
 health-=amount;tactics.under_fire=2.0
 game.clientfx.play("Impact_Flesh",null,context.get("hitPosition",global_position+Vector3.UP*1.1))
 if context.get("headshot",false):game.clientfx.play("BloodHeadshot",null,context.get("hitPosition",global_position+Vector3.UP*1.6))
 if health>0:game.clientfx.frost_hit(self,context.get("sourceActor") if context.get("actor","")=="bot" else game.player)
 if game.spectator.active and game.spectator.target==self and is_instance_valid(game.source_hud):game.source_hud.feedback.show_damage(context.get("sourcePosition"))
 if health<=0:
  game.record_elimination(roster_id,context.get("rosterId","") if context.get("actor","")=="bot" else "player")
  if game.destruction.enabled:game.destruction.actor_dead(team,self)
  game.game_audio.voice(self,0)
  collision_layer=0;context=context.duplicate();context.target=display_name
  if context.get("actor","")=="bot":game.bot_defeated(self,context)
  else:game.enemy_defeated(context)
  queue_free()
 elif sees_player and randf()<float(profile.dodgeChance):begin_dodge()
 return true
