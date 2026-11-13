extends RefCounted
# Correct the OG back decal's atlas orientation without changing source assets,
# positions, normals, weights, joints, arm decals or other tattoo families.
static var cache={}
static func apply(mesh,transpose_uv):
	if not mesh.has_meta("source_tattoo_mesh"):mesh.set_meta("source_tattoo_mesh",mesh.mesh)
	var source=mesh.get_meta("source_tattoo_mesh")
	if not transpose_uv:mesh.mesh=source;return
	var key=source.get_instance_id()
	if not cache.has(key):
		var corrected=ArrayMesh.new()
		for surface in range(source.get_surface_count()):
			var arrays=source.surface_get_arrays(surface);var uv=arrays[Mesh.ARRAY_TEX_UV]
			for i in range(uv.size()):uv[i]=Vector2(uv[i].y,uv[i].x)
			arrays[Mesh.ARRAY_TEX_UV]=uv
			corrected.add_surface_from_arrays(source.surface_get_primitive_type(surface),arrays)
			corrected.surface_set_material(surface,source.surface_get_material(surface))
		cache[key]=corrected
	mesh.mesh=cache[key]
