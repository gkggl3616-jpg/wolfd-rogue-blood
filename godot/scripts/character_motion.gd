extends RefCounted
# Sweep the newly occupied head space, never the supporting floor.
static func can_stand(actor, height):
 var current=float(actor.capsule.height)
 if current>=height-.001:return true
 var radius=maxf(.05,float(actor.capsule.radius)-.004)
 var shape=CapsuleShape3D.new();shape.radius=radius;shape.height=height-current+radius*2
 var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.exclude=[actor.get_rid()]
 query.transform=Transform3D(Basis.IDENTITY,actor.global_position+Vector3.UP*(current+(height-current)*.5-radius))
 return actor.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

# A supported step still needs a clear capsule sweep and an actual walkable top.
static func try_step(actor, motion, limit=.38):
 if not actor.is_on_floor() or actor.velocity.y>.1 or motion.length()<.001 or not actor.test_move(actor.global_transform,motion):return false
 var up=Vector3.UP*limit
 if actor.test_move(actor.global_transform,up):return false
 var forward=motion.normalized()*maxf(motion.length(),actor.capsule.radius+.12)
 var raised=actor.global_transform.translated(up)
 if actor.test_move(raised,forward):return false
 var ray=PhysicsRayQueryParameters3D.create(raised.origin+forward+Vector3.UP*.06,actor.global_position+forward-Vector3.UP*.06,1,[actor.get_rid()])
 var hit=actor.get_world_3d().direct_space_state.intersect_ray(ray)
 if hit.is_empty() or hit.normal.y<cos(actor.floor_max_angle):return false
 var rise=hit.position.y-actor.global_position.y
 if rise<.025 or rise>limit:return false
 var target=actor.global_transform.translated(Vector3.UP*(rise+.015))
 if actor.test_move(actor.global_transform,Vector3.UP*(rise+.015)) or actor.test_move(target,motion):return false
 actor.global_position.y+=rise+.015;actor.velocity.y=0;return true
