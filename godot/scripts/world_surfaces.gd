extends RefCounted
# Original DTX flags decide material behavior. Never guess from a wood filename.
var catalog={}
func _init():
	if FileAccess.file_exists("res://assets/gameplay/surfaces.json"):catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/surfaces.json"))
func definition(id):return catalog.get("surfaces",{}).get(str(int(id)),{})
func bind_mesh(mesh):
	var ranges=[];var first=0
	for i in range(mesh.mesh.get_surface_count()):
		var material=mesh.get_active_material(i);var key=str(material.resource_name).replace("\\","/").to_lower() if material!=null else ""
		var record=catalog.get("materials",{}).get(key,{})
		var arrays=mesh.mesh.surface_get_arrays(i)
		var indices=arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else 0;var vertices=arrays[Mesh.ARRAY_VERTEX].size()
		var count=int((indices if indices>0 else vertices)/3)
		ranges.append({"first":first,"last":first+count,"surface":int(record.get("surface",0)),"material":key});first+=count
	for child in mesh.get_children():
		if child is StaticBody3D:
			child.set_meta("source_surface_ranges",ranges);child.set_meta("source_surface_mesh",mesh)
func hit_surface(hit):
	if hit.is_empty() or not is_instance_valid(hit.get("collider")):return {}
	var body=hit.collider
	if body.has_meta("source_surface_id"):return definition(body.get_meta("source_surface_id"))
	var face=int(hit.get("face_index",-1))
	for row in body.get_meta("source_surface_ranges",[]):
		if face>=row.first and face<row.last:return definition(row.surface)
	return {}
func exit_hit(hit,direction,thickness):
	var body=hit.collider
	if not body.has_meta("source_surface_mesh"):return {}
	var mesh=body.get_meta("source_surface_mesh")
	if not is_instance_valid(mesh):return {}
	# TriangleMesh's BVH includes back faces without changing character collision.
	# Its FIRST intersection from just inside the entry prevents skipping another
	# wall/surface in the same world collider. A distant reverse ray cannot do that.
	if not body.has_meta("source_surface_triangles"):
		var triangles=mesh.mesh.generate_triangle_mesh()
		body.set_meta("source_surface_triangles",triangles);body.set_meta("source_surface_faces",triangles.get_faces())
	var triangles=body.get_meta("source_surface_triangles");var faces=body.get_meta("source_surface_faces")
	var local=mesh.global_transform.affine_inverse()
	var exit=triangles.intersect_segment(local*(hit.position+direction*.002),local*(hit.position+direction*(thickness+.002)))
	if exit.is_empty():return {}
	var index=int(exit.face_index)*3;var entry_index=int(hit.get("face_index",-1))*3
	if index+2>=faces.size() or entry_index<0 or entry_index+2>=faces.size():return {}
	var normal_basis=mesh.global_basis.inverse().transposed()
	var entry_normal=(normal_basis*((faces[entry_index+1]-faces[entry_index]).cross(faces[entry_index+2]-faces[entry_index]))).normalized()
	var normal=(normal_basis*((faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]))).normalized()*signf(entry_normal.dot(hit.normal))
	return {"position":mesh.global_transform*exit.position,"normal":normal,"face_index":exit.face_index,"collider":body}
func trace(world,origin,end,exclude=[]):
	var direction=(end-origin).normalized();var current=origin;var impacts=[];var damage_scale=1.0;var layers=0
	for _i in range(9):
		var query=PhysicsRayQueryParameters3D.create(current,end,3,exclude);var hit=world.intersect_ray(query)
		if hit.is_empty():return {"hit":{},"impacts":impacts,"damageScale":damage_scale,"layers":layers}
		var surface=hit_surface(hit);impacts.append({"hit":hit,"surface":surface,"exit":false})
		if hit.collider.has_meta("enemy") or not surface.get("CanShootThrough",false) or layers>=8:
			return {"hit":hit,"impacts":impacts,"damageScale":damage_scale,"layers":layers}
		var thickness=float(surface.get("MaxShootThroughThickness",0))*.016
		if thickness<=0: return {"hit":hit,"impacts":impacts,"damageScale":damage_scale,"layers":layers}
		var exit=exit_hit(hit,direction,thickness)
		var exit_surface=hit_surface(exit)
		if exit.is_empty() or not exit_surface.get("CanShootThrough",false) or exit.normal.dot(direction)<.05 or exit.position.distance_to(hit.position)>thickness+.001:
			return {"hit":hit,"impacts":impacts,"damageScale":damage_scale,"layers":layers}
		# A different solid between the entry and its nearest exit also blocks.
		var inside_query=PhysicsRayQueryParameters3D.create(hit.position+direction*.002,exit.position-direction*.001,3,exclude)
		if not world.intersect_ray(inside_query).is_empty():return {"hit":hit,"impacts":impacts,"damageScale":damage_scale,"layers":layers}
		impacts.append({"hit":exit,"surface":exit_surface,"exit":true});layers+=1
		damage_scale*=clampf(float(surface.get("BulletDamageDampen",1)),0,1)
		current=exit.position+direction*.002
		var distance=maxf(0,(end-current).dot(direction))*clampf(float(surface.get("BulletRangeDampen",1)),0,1)
		end=current+direction*distance
	return {"hit":{},"impacts":impacts,"damageScale":damage_scale,"layers":layers}
func present_impacts(game,impacts):
	for row in impacts:
		if row.hit.collider.has_meta("enemy") or row.surface.is_empty():continue
		var fx=str(row.surface.get("ExitFXName" if row.exit else "ImpactFXName",""))
		if game.clientfx.canonical(fx)!="":game.clientfx.play(fx,null,row.hit.position)
		if row.exit:continue
		var sounds=[]
		for key in ["BulletImpactSnd1","BulletImpactSnd2"]:
			var name=str(row.surface.get(key,"")).replace("\\","/").to_lower()
			if name!="":sounds.append("root/"+name)
		if not sounds.is_empty():game.game_audio.play_at(sounds.pick_random(),row.hit.position,true,"WolfEffects",-14)
