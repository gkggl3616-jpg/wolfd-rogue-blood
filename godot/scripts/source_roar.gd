extends Node3D
# Source ClientFX assets/timings/color and scale keys, rendered with a bounded mobile adapter.
var player
var elapsed=0.0
var parts=[]
var active_group=""
var definition={}
func _ready():definition=JSON.parse_string(FileAccess.get_file_as_string("res://assets/abilities/source-roars.json"))
func stop():
 for part in parts:
  if is_instance_valid(part.node):part.node.queue_free()
 parts=[];active_group="";elapsed=0
func begin():
 stop()
 active_group=definition.characters.get(player.game.character_info.id,"")
 if active_group=="":return
 for spec in definition.groups[active_group].nodes:
  var node
  var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;material.cull_mode=BaseMaterial3D.CULL_DISABLED
  if spec.type=="LTBModel":
   node=load(spec.asset).instantiate();add_child(node)
   for mesh in node.find_children("*","MeshInstance3D",true,false):mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  elif spec.type=="ParticleSystem":
   node=CPUParticles3D.new();node.emitting=false;node.one_shot=true;node.amount=clampi(int(value(spec,"ParticlesPerEmission",10)),1,64)
   node.lifetime=clampf(float(value(spec,"MaxParticleLifeSpan",0.8)),0.05,2);node.explosiveness=1
   node.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;node.emission_sphere_radius=float(value(spec,"MaxRadius",15))*0.016
   var low=value(spec,"MinParticleVelocity",[0,0,0]);var high=value(spec,"MaxParticleVelocity",[0,20,0]);node.initial_velocity_min=Vector3(low[0],low[1],low[2]).length()*0.016;node.initial_velocity_max=maxf(node.initial_velocity_min,Vector3(high[0],high[1],high[2]).length()*0.016)
   node.direction=Vector3.UP;node.spread=60;node.gravity=Vector3.DOWN*float(value(spec,"GravityAcceleration",0))*0.016
   var colors=spec.properties.get("Ck",[])
   if not colors.is_empty():
    var gradient=Gradient.new();gradient.offsets=PackedFloat32Array();gradient.colors=PackedColorArray()
    for ck in colors:gradient.add_point(float(ck[0]),Color(ck[1],ck[2],ck[3],ck[4]))
    node.color_ramp=gradient;material.vertex_color_use_as_albedo=true
   node.local_coords=false;var mesh=QuadMesh.new();mesh.size=Vector2.ONE*maxf(0.03,float(curve(spec,"Sk",0,[0,10])[1])*0.016)
   material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mesh.material=material;node.mesh=mesh;add_child(node)
  elif spec.type=="DynaLight":
   node=OmniLight3D.new();node.shadow_enabled=false;add_child(node)
  else:continue
  var offset=value(spec,"Offset",[0,0,0]);node.position=Vector3(offset[0],offset[1],-offset[2])*0.016
  # Named cry socket is not a bone in every converted model. Source offset
  # is retained; neck height is the explicit fallback, never a generic circle.
  if str(value(spec,"AttachName","")).to_lower()=="cry":node.position.y+=1.6
  node.hide();parts.append({"node":node,"spec":spec,"material":material,"started":false,"baseScale":node.scale})
func value(spec,key,fallback):return spec.properties.get(key,[fallback])[0]
func curve(spec,key,t,fallback):
 var keys=spec.properties.get(key,[])
 if keys.is_empty():return fallback
 for i in range(1,keys.size()):
  if t<=float(keys[i][0]):
   var a=keys[i-1];var b=keys[i];var ratio=clampf((t-float(a[0]))/maxf(0.001,float(b[0])-float(a[0])),0,1);var result=[t]
   for j in range(1,a.size()):result.append(lerpf(a[j],b[j],ratio))
   return result
 return keys[-1]
func _process(delta):
 if active_group=="":return
 if not player.game.is_combat_active() or not player.is_wolf:stop();return
 elapsed+=delta
 var finished=true
 for part in parts:
  var spec=part.spec;var node=part.node
  if elapsed<float(spec.start):finished=false;continue
  if elapsed>float(spec.end)+(node.lifetime if node is CPUParticles3D else 0):node.hide();continue
  finished=false;node.show()
  if not part.started:
   part.started=true
   if node is CPUParticles3D:node.emitting=true
  var phase=clampf((elapsed-float(spec.start))/maxf(0.01,float(spec.end)-float(spec.start)),0,1)
  var ck=curve(spec,"Ck",phase,[0,1,1,1,0.5]);var color=Color(ck[1],ck[2],ck[3],ck[4])
  if node is OmniLight3D:node.light_color=color;node.light_energy=color.a*0.6;node.omni_range=maxf(0.1,float(curve(spec,"Sk",phase,[0,150])[1])*0.016)
  else:
   part.material.albedo_color=Color.WHITE if node is CPUParticles3D else color
   if spec.has("frames") and not spec.frames.is_empty():part.material.albedo_texture=load(spec.frames[int(elapsed*float(spec.get("fps",1)))%spec.frames.size()])
   if spec.type=="LTBModel":node.scale=part.baseScale*maxf(0.001,float(curve(spec,"Sk",phase,[0,1])[1]))
 if finished:stop()
