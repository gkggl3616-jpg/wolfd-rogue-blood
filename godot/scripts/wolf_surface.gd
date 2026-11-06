extends RefCounted
# Keep original meshes/skins. Solid body triangles must participate in the
# depth buffer; alpha blending is reserved for fur and tattoo shells.
static func apply(model):
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var name=str(mesh.name).to_lower()
  if name.begins_with("tattoo") or not "body" in name:continue
  for surface in range(mesh.mesh.get_surface_count()):
   var source=mesh.get_active_material(surface)
   if source is StandardMaterial3D and source.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA:
    var material=source.duplicate();material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    mesh.set_surface_override_material(surface,material)
