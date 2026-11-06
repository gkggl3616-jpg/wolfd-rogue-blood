extends SceneTree
const Graph=preload("res://scripts/navigation_graph.gd")
const Traverse=preload("res://scripts/bot_traversal.gd")
func _initialize():call_deferred("run")
func v(a):return Vector3(a[0],a[1],a[2])
func arr(p):return [p.x,p.y,p.z]
func run():
 var records=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/offline.json"));var previews=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"));var results=[]
 for number in [72,37,106]:
  var record=records.filter(func(r):return int(r.number)==number)[0];var preview=previews.filter(func(r):return int(r.number)==number)[0]
  var scene=load(preview.previewAsset).instantiate();root.add_child(scene)
  for mesh in scene.find_children("*","MeshInstance3D",true,false):mesh.create_trimesh_collision()
  await physics_frame;await physics_frame
  var world=scene.get_world_3d().direct_space_state;var nav=load(record.navigation);var graph=Graph.new(nav);var edges={};var points=[]
  for polygon in graph.polygons:
   for i in range(polygon.size()):
    var a=polygon[i];var b=polygon[(i+1)%polygon.size()];var key=str(a)+str(b) if str(a)<str(b) else str(b)+str(a)
    if edges.has(key):edges[key].count+=1
    else:edges[key]={"point":(a+b)*0.5,"count":1}
  var buckets={}
  for edge in edges.values():
   if edge.count!=1:continue
   var p=edge.point;var component=graph.component(p)
   if component<0:continue
   var cell=Vector2i(floori(p.x/3),floori(p.z/3));var item={"point":p,"component":component}
   points.append(item)
   if not buckets.has(cell):buckets[cell]=[]
   buckets[cell].append(item)
  var pairs={}
  for a in points:
   var cell=Vector2i(floori(a.point.x/3),floori(a.point.z/3))
   for x in range(-2,3):
    for z in range(-2,3):
     for b in buckets.get(cell+Vector2i(x,z),[]):
      if a.component>=b.component or absf(a.point.y-b.point.y)>3.0:continue
      var distance=a.point.distance_to(b.point)
      if distance<0.05 or distance>5.1:continue
      var key=Vector2i(a.component,b.component)
      if not pairs.has(key):pairs[key]=[]
      var values=pairs[key]
      if values.size()<16 or distance<values[-1].distance:
       values.append({"a":a.point,"b":b.point,"distance":distance});values.sort_custom(func(c,d):return c.distance<d.distance)
       if values.size()>16:values.pop_back()
  var ordered=pairs.values();ordered.sort_custom(func(a,b):return a[0].distance<b[0].distance)
  var links=[]
  for candidates in ordered:
   for candidate in candidates:
    if graph.connected(candidate.a,candidate.b):break
    var feet=[]
    for p in [candidate.a,candidate.b]:
     var ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.3,p-Vector3.UP*0.6,1);ray.hit_back_faces=true
     var hit=world.intersect_ray(ray)
     if hit.is_empty() or hit.normal.y<0.65:break
     feet.append(hit.position+Vector3.UP*0.12)
    if feet.size()!=2:continue
    var forward=Traverse.plan(world,feet[0],feet[1]);var backward=Traverse.plan(world,feet[1],feet[0])
    if forward.is_empty() and backward.is_empty():continue
    var bidirectional=not forward.is_empty() and not backward.is_empty()
    if forward.is_empty():candidate={"a":candidate.b,"b":candidate.a};feet.reverse();forward=backward
    links.append({"entry":arr(candidate.a),"exit":arr(candidate.b),"feetEntry":arr(feet[0]),"feetExit":arr(feet[1]),"forwardSeconds":forward.seconds,"backwardSeconds":backward.get("seconds",0),"bidirectional":bidirectional})
    graph.join_points(candidate.a,candidate.b,bidirectional);break
  results.append({"number":number,"geometrySha256":preview.sha256,"navigationSha256":record.sha256,"links":links,"validation":"Both directions: 24 swept crouched-capsule ballistic samples, 4.05m horizontal / 0.99m up / 3m down limit, launch velocity <=6.3m/s. Local bot traversal, not decoded PC links."})
  print("BOT_TRAVERSALS ",number," boundaries=",points.size()," componentPairs=",pairs.size()," admitted=",links.size())
  root.remove_child(scene);scene.queue_free();await process_frame
 var file=FileAccess.open("res://assets/maps/traversals.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  ")+"\n");file.close();quit()
