extends CharacterBody3D
# Native assets, class, speed, gravity, lifetime and effect associations.
# Collision radius, bounce restitution and 6m damage falloff are local adapters.
var game
var fuse=2.0
var kind="grenade"
var damage_amount=90
var native={}
var definition={}
var owner_actor
var attack_id=""
var visual:Node3D
var trail
var stuck=false
var attachment:WeakRef
var attachment_transform=Transform3D.IDENTITY
var detonated=false
var age=0.0
var impact_count=0
var gravity=-12.0
var projectile_class="CGrenade"
var socket_skeleton:Skeleton3D
var socket_bones={}
var owner_team=""
var owner_name=""
var owner_roster=""
var owner_was_player=true
func _ready():
 if not is_instance_valid(owner_actor):owner_actor=game.player
 owner_team=game.actor_team(owner_actor);owner_was_player=owner_actor==game.player
 owner_name=game.profile_name if owner_was_player else owner_actor.display_name;owner_roster="player" if owner_was_player else owner_actor.roster_id
 collision_layer=4;collision_mask=3;add_collision_exception_with(owner_actor)
 set_meta("source_projectile",true)
 var shape=CollisionShape3D.new();var sphere=SphereShape3D.new();sphere.radius=.07;shape.shape=sphere;add_child(shape)
 var props=definition.get("properties",{})
 if not props.is_empty():
  projectile_class=props.get("Class","CGrenade");fuse=maxf(.01,float(props.get("Lifetime",2)))
  gravity=float(props.get("GravityOverride",-500))*.016 if props.get("Gravity",false) else 0.0
  if gravity==0 and props.get("Gravity",false):gravity=-8.0 # Explicit local default when the source override is zero.
  if definition.get("availableModel",false):
   visual=load(definition.asset).instantiate();var scale=props.get("ModelScale",[1,1,1]);visual.scale*=Vector3(scale[0],scale[1],-scale[2]);add_child(visual)
   visual.visible=definition.get("visibleModel",true)
   var skeletons=visual.find_children("*","Skeleton3D",true,false)
   if not skeletons.is_empty():
    socket_skeleton=skeletons[0]
    for name in definition.get("sockets",{}):socket_bones[name]=preload("res://scripts/native_socket_bone.gd").find(socket_skeleton,definition.sockets[name],definition.get("bones",[]))
  if props.get("FlySound",false) and definition.get("sound","")!="":game.game_audio.play_at("root/"+str(props.Sound).replace("\\","/").to_lower(),global_position,true,"WolfWeapons",-18)
 else:
  var mesh=MeshInstance3D.new();var model=SphereMesh.new();model.radius=.12;model.height=.24;mesh.mesh=model;mesh.material_override=game.material("566b4c");add_child(mesh)
 ensure_trail()
func native_socket_transform(name):
 if not is_instance_valid(socket_skeleton) or int(socket_bones.get(name,-1))<0:return global_transform
 var socket=definition.sockets[name];var p=socket.position;var q=socket.rotation
 var transform=socket_skeleton.global_transform*socket_skeleton.get_bone_global_pose(socket_bones[name])*Transform3D(Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized()),Vector3(p[0],p[1],p[2]))
 return Transform3D(transform.basis.orthonormalized(),transform.origin)
func team():return owner_team
func ensure_trail():
 if definition.get("trailFx","")=="" or (is_instance_valid(trail) and not trail.is_queued_for_deletion()):return
 trail=game.clientfx.play(definition.trailFx,null,global_position,true,0,self)
func impact_effect(point):
 var impact=game.projectile_catalog.get("impacts",{}).get(native.get("impactFx",""),{})
 if impact.get("fx","")!="":game.clientfx.play(impact.fx,null,point)
 var sound=str(impact.get("properties",{}).get("Sound",""))
 if sound!="" and sound.to_lower()!="surface":game.game_audio.play_at("root/"+sound.replace("\\","/").to_lower(),point,true,"WolfEffects",-12)
func damage_actor(actor,amount,point):
 if not is_instance_valid(actor) or (actor!=game.player and not actor.has_meta("enemy")):return
 if amount<=0 or not game.hostile(actor,team()):return
 var context={"weapon":native.get("weaponName","Silah"),"attackId":attack_id,"hitPosition":point,"sourceActor":owner_actor if is_instance_valid(owner_actor) else null,"sourcePosition":global_position,"attackerTeam":team(),"name":owner_name,"rosterId":owner_roster,"posthumous":owner_was_player and game.health<=0}
 if not owner_was_player:context.actor="bot"
 if actor==game.player:game.take_damage(roundi(amount),global_position,context)
 else:actor.damage(roundi(amount),context)
func detonate():
 if detonated:return
 detonated=true;impact_count+=1
 if definition.is_empty():game.explode(global_position,damage_amount,kind);queue_free();return
 impact_effect(global_position)
 var amount=float(native.get("splashDamage",0));var targets=game.combat_targets(team())
 var world_excludes=[game.player.get_rid()]
 for actor in game.enemies.get_children():world_excludes.append(actor.get_rid())
 game.begin_damage_batch()
 for actor in targets:
  if not game.actor_alive(actor):continue
  var distance=actor.global_position.distance_to(global_position)
  if distance>=6 or amount<=0:continue
  var query=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.1,actor.global_position+Vector3.UP,1,world_excludes)
  var obstruction=get_world_3d().direct_space_state.intersect_ray(query)
  if obstruction.is_empty():damage_actor(actor,amount*(1-distance/6),actor.global_position+Vector3.UP)
 game.finish_damage_batch();queue_free()
func contact(collider,point,normal):
 if detonated:return
 if projectile_class in ["CProjectile","CGrenadeLauncher","CLaserTypeBullet"]:
  if float(native.get("baseDamage",0))>0:damage_actor(collider,float(native.baseDamage),point)
  detonate();return
 if projectile_class=="CArrow":
  damage_actor(collider,float(native.get("baseDamage",damage_amount)),point);impact_effect(point)
  stuck=true;velocity=Vector3.ZERO
 elif projectile_class in ["CAttachGrenade","CMine"]:
  stuck=true;velocity=Vector3.ZERO
  var indicate=definition.get("indicateFx","")
  if indicate!="":game.clientfx.play(indicate,null,global_position,true,0,self)
 else:velocity=velocity.bounce(normal)*.4
 if stuck and is_instance_valid(collider):attachment=weakref(collider);attachment_transform=collider.global_transform.affine_inverse()*global_transform
func _physics_process(delta):
 if detonated or not game.is_match_active():return
 age+=delta;fuse-=delta;ensure_trail()
 if stuck:
  var target=attachment.get_ref() if attachment!=null else null
  if is_instance_valid(target):global_transform=target.global_transform*attachment_transform
  elif attachment!=null:stuck=false;attachment=null
  if projectile_class=="CMine" and age>=.4:
   var radius=maxf(0,float(definition.get("properties",{}).get("EnemyDetectRadius",0))*.016)
   for actor in game.combat_targets(team()):
    var base=actor.global_position+Vector3.UP*actor.capsule.radius;var top=actor.global_position+Vector3.UP*(actor.capsule.height-actor.capsule.radius)
    if Geometry3D.get_closest_point_to_segment(global_position,base,top).distance_to(global_position)<=radius+actor.capsule.radius:detonate();return
 else:
  velocity.y+=gravity*delta
  var collision=move_and_collide(velocity*delta)
  if collision:contact(collision.get_collider(),collision.get_position(),collision.get_normal())
  if is_instance_valid(visual) and velocity.length()>.1:
   if projectile_class in ["CArrow","CProjectile","CLaserTypeBullet"]:
    var up=Vector3.UP if absf(velocity.normalized().dot(Vector3.UP))<.99 else Vector3.RIGHT
    look_at(global_position+velocity,up)
   else:visual.rotate_x(delta*5)
 if fuse<=0:
  if projectile_class in ["CArrow","CProjectile","CLaserTypeBullet"]:queue_free()
  else:detonate()
