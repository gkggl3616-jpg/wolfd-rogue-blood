extends RefCounted
# A local bot jump is admitted only after sweeping its whole crouched capsule
# through the ballistic arc. No teleport, invisible floor or collision bypass.
static func plan(world,from,to,exclude=[]):
 var flat=Vector3(to.x-from.x,0,to.z-from.z)
 # These are the existing local arc velocity/time bounds, not PC statistics.
 # Their product admits the full reachable horizontal distance (4.34m).
 if flat.length()>7.0*.62 or to.y-from.y>0.99 or from.y-to.y>3.0:return {}
 var seconds=clampf(maxf(flat.length()/7.0,sqrt(absf(to.y-from.y)/10.0)),0.22,0.62)
 var velocity=flat/seconds+Vector3.UP*((to.y-from.y+10*seconds*seconds)/seconds)
 if velocity.y>6.3 or velocity.y<0:return {}
 if Vector2(velocity.x,velocity.z).length()>7.001:return {}
 var shape=CapsuleShape3D.new();shape.radius=0.42;shape.height=1.2
 var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.exclude=exclude
 var previous=from
 for i in range(1,25):
  var time=seconds*i/24.0
  var point=from+velocity*time-Vector3.UP*10*time*time
  query.transform=Transform3D(Basis.IDENTITY,previous+Vector3.UP*0.65);query.motion=point-previous
  if not world.intersect_shape(query,1).is_empty():return {}
  var cast=world.cast_motion(query)
  if cast.size()<2 or cast[0]<0.999:return {}
  previous=point
 query.transform=Transform3D(Basis.IDENTITY,to+Vector3.UP*0.65);query.motion=Vector3.ZERO
 if not world.intersect_shape(query,1).is_empty():return {}
 return {"velocity":velocity,"seconds":seconds}
