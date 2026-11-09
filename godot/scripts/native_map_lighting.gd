extends RefCounted
# Native two-pass RGB lightmaps and Gouraud colours on unchanged source triangles.
const LIGHT_SHADER=preload("res://ui/native_map_light.gdshader")
var catalog={}
var blend_shader:Shader
func _init():
 catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/lighting/index.json"))
 blend_shader=Shader.new();blend_shader.code=LIGHT_SHADER.code.replace("ALBEDO = base.rgb", "ALPHA = base.a;\n ALBEDO = base.rgb")
func floats(bytes,offset,count):return bytes.slice(offset,offset+count*4).to_float32_array()
func vectors3(bytes,offset,count):return bytes.slice(offset,offset+count*12).to_vector3_array()
func vectors2(bytes,offset,count):
 var f=floats(bytes,offset,count*2);var result=PackedVector2Array();result.resize(count)
 for i in range(count):result[i]=Vector2(f[i*2],f[i*2+1])
 return result
func apply(scene,number):
 var record=catalog.maps.get(str(int(number)),{})
 if record.is_empty() or scene.has_meta("native_lighting_applied"):return 0
 var packed=FileAccess.get_file_as_bytes(record.asset);var raw=packed.decompress_dynamic(256*1024*1024,FileAccess.COMPRESSION_GZIP)
 if raw.size()<4:return 0
 var size=raw.decode_u32(0)
 if size>raw.size()-4:return 0
 var header=JSON.parse_string(raw.slice(4,4+size).get_string_from_utf8());var bytes=raw.slice(4+size);var root=Node3D.new();root.name="NativeSourceLighting"
 var textures=[]
 for path in header.atlases:textures.append(load(path))
 var materials={};var vertices=0
 for surface in header.surfaces:
  var count=int(surface.count);var offset=int(surface.offset)
  if count<=0 or offset<0 or offset+count*44>bytes.size():root.free();return 0
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vectors3(bytes,offset,count);arrays[Mesh.ARRAY_NORMAL]=vectors3(bytes,offset+count*12,count);arrays[Mesh.ARRAY_TEX_UV]=vectors2(bytes,offset+count*24,count);arrays[Mesh.ARRAY_TEX_UV2]=vectors2(bytes,offset+count*32,count)
  var colors=PackedColorArray();colors.resize(count);var at=offset+count*40
  for i in range(count):colors[i]=Color(float(bytes[at+i*4])/255,float(bytes[at+i*4+1])/255,float(bytes[at+i*4+2])/255,1)
  arrays[Mesh.ARRAY_COLOR]=colors
  var key=JSON.stringify([surface.texture,surface.page,surface.cutoff,surface.blend])
  if not materials.has(key):
   var material=ShaderMaterial.new();material.shader=blend_shader if surface.blend else LIGHT_SHADER;material.set_shader_parameter("has_base",surface.texture!="")
   if surface.texture!="":material.set_shader_parameter("base_texture",load(surface.texture))
   material.set_shader_parameter("has_lightmap",int(surface.page)>=0);material.set_shader_parameter("alpha_clip",float(surface.cutoff))
   if int(surface.page)>=0:material.set_shader_parameter("native_lightmap",textures[int(surface.page)])
   materials[key]=material
  var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);var instance=MeshInstance3D.new();instance.mesh=mesh;instance.material_override=materials[key];instance.set_meta("source_visual_only",true);root.add_child(instance);vertices+=count
 # Existing colliders and surface IDs stay on their original imported meshes.
 for mesh in scene.find_children("*","MeshInstance3D",true,false):mesh.hide()
 scene.add_child(root);scene.set_meta("native_lighting_applied",true);scene.set_meta("native_lightmap_count",int(record.decodedLightmaps));scene.set_meta("native_lit_vertices",vertices);return vertices
