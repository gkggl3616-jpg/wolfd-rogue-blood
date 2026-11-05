extends RefCounted
# Conservative connected components prevent asking Godot 4.7's corridor search
# to retry an unreachable island (which otherwise emits a native query error).
var polygons=[]
var boxes=[]
var centers=[]
var parents=[]
var components=[]
var spatial={}
var component_cache={}

func _init(mesh,world_transform=Transform3D.IDENTITY):
 var vertices=mesh.get_vertices();var canonical={};var ids=[]
 for v in vertices:
  var point=world_transform*v
  if not canonical.has(point):canonical[point]=canonical.size()
  ids.append(canonical[point])
 var edges={}
 for i in range(mesh.get_polygon_count()):
  parents.append(i)
  var indices=mesh.get_polygon(i);var points=PackedVector3Array();var center=Vector3.ZERO
  for index in indices:points.append(world_transform*vertices[index]);center+=world_transform*vertices[index]
  center/=maxi(1,points.size());centers.append(center);polygons.append(points)
  var box=AABB(points[0],Vector3.ZERO)
  for point in points:box=box.expand(point)
  box=box.grow(0.03);boxes.append(box)
  var low=Vector2i(floori(box.position.x/4),floori(box.position.z/4))
  var high=Vector2i(floori(box.end.x/4),floori(box.end.z/4))
  for x in range(low.x,high.x+1):
   for z in range(low.y,high.y+1):
    var cell=Vector2i(x,z)
    if not spatial.has(cell):spatial[cell]=[]
    spatial[cell].append(i)
  for j in range(indices.size()):
   var a=ids[indices[j]];var b=ids[indices[(j+1)%indices.size()]];var key=Vector2i(mini(a,b),maxi(a,b))
   if not edges.has(key):edges[key]=[]
   edges[key].append(i)
 for owners in edges.values():
  if owners.size()==2:
   var a=find(owners[0]);var b=find(owners[1])
   if a!=b:parents[b]=a
 for i in range(parents.size()):components.append(find(i))

func find(index):
 var root=index
 while parents[root]!=root:root=parents[root]
 while parents[index]!=index:
  var next=parents[index];parents[index]=root;index=next
 return root

func component(point):
 if component_cache.has(point):return component_cache[point]
 var best=-1;var distance=INF
 var cell=Vector2i(floori(point.x/4),floori(point.z/4))
 for i in spatial.get(cell,[]):
  if not boxes[i].has_point(point):continue
  var polygon=polygons[i]
  for j in range(1,polygon.size()-1):
   var normal=(polygon[j]-polygon[0]).cross(polygon[j+1]-polygon[0]).normalized()
   if normal.is_zero_approx():continue
   var hit=Geometry3D.segment_intersects_triangle(point+normal*0.15,point-normal*0.15,polygon[0],polygon[j],polygon[j+1])
   if hit is Vector3 and point.distance_squared_to(hit)<distance:
    best=i;distance=point.distance_squared_to(hit)
 var result=components[best] if best>=0 else -1
 if component_cache.size()>256:component_cache.clear()
 component_cache[point]=result
 return result

func connected(from,to):
 var a=component(from)
 return a>=0 and a==component(to)

func nearest_in_component(origin,target):
 var group=component(origin)
 if group<0:return null
 if component(target)==group:return target
 var best=null;var distance=INF
 for i in range(centers.size()):
  if components[i]!=group:continue
  var d=centers[i].distance_squared_to(target)
  if d<distance:distance=d;best=centers[i]
 return best
