extends RefCounted
# Pellet COUNT is native. The 4-degree distribution is an explicit local
# adapter until the PC spread/recoil fields have independent unit proof.
static func directions(forward,count):
 var result=[];forward=forward.normalized();count=clampi(count,1,32)
 var right=forward.cross(Vector3.UP).normalized()
 if right.is_zero_approx():right=Vector3.RIGHT
 var up=right.cross(forward).normalized()
 for i in range(count):
  if count==1:result.append(forward);continue
  var radius=tan(deg_to_rad(4))*sqrt((i+.5)/float(count));var angle=i*2.39996322973
  result.append((forward+right*cos(angle)*radius+up*sin(angle)*radius).normalized())
 return result
