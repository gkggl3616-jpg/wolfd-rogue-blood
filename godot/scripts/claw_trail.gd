extends Node3D
# Original endpoint bones/texture and spline keys. .18s lifetime is a local render adapter.
const LIFETIME=.18
var player
var remaining=0.0
var source_control=false
var enabled_sides=[true,true]
var emitting=false
var clock=0.0
var bindings=[]
var skeleton
var samples=[]
var meshes=[]
var material
var glow=[]
func _ready():top_level=true;global_transform=Transform3D.IDENTITY
func wolf_form():return player.is_wolf if player==player.game.player else player.kind=="wolf"
func combat_active():return player.game.is_combat_active() if player==player.game.player else player.game.is_match_active() and player.game.actor_alive(player)
func refresh_glow():
 var active=player==player.game.player and wolf_form() and combat_active() and player.game.booster_remaining>0
 if not active:
  for effect in glow:
   if is_instance_valid(effect):effect.queue_free()
  glow=[];return
 glow=glow.filter(func(effect):return is_instance_valid(effect) and not effect.is_queued_for_deletion())
 for group in ["wolf_Hand_glowL","wolf_Hand_glowR"]:
  if not glow.any(func(effect):return effect.group==group):
   var effect=player.game.clientfx.play(group,player,null,true)
   if effect!=null:glow.append(effect)
func clear():
 remaining=0;samples=[];bindings=[];source_control=false;enabled_sides=[true,true];emitting=false
 for node in meshes:
  if is_instance_valid(node):node.queue_free()
 meshes=[]
func finish():source_control=false;enabled_sides=[false,false];emitting=false;remaining=LIFETIME if not samples.is_empty() else 0
func begin():
 clear()
 if not wolf_form() or not combat_active():return false
 var item=player.game.power_item(player.game.inbox.state.powerSlots.get("claw","")) if player==player.game.player else player.game.power_item(player.roster_identity.get("clawId",""))
 var trail=item.get("trail",player.game.power_catalog.get("defaultClawTrail",{}))
 if trail.is_empty():return false
 var model=player.wolf if player==player.game.player else player.body
 var found=model.find_children("*","Skeleton3D",true,false)
 if found.is_empty():return false
 skeleton=found[0]
 for bone in trail.bones:
  var index=skeleton.find_bone(bone)
  if index<0:return false
  bindings.append(index)
 material=StandardMaterial3D.new();material.albedo_texture=load(trail.asset);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.vertex_color_use_as_albedo=true
 for _i in range(2):
  var mesh=MeshInstance3D.new();mesh.mesh=ImmediateMesh.new();mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh);meshes.append(mesh)
 remaining=LIFETIME;emitting=true;return true
func source_window(side,enabled):
 if side<0 or side>1:return
 if not source_control:
  if bindings.is_empty() or meshes.is_empty():
   if not begin():return
  source_control=true;enabled_sides=[false,false]
 enabled_sides[side]=enabled;emitting=enabled_sides.any(func(v):return v);remaining=LIFETIME
 if not emitting:source_control=false
func _process(delta):
 refresh_glow()
 if remaining<=0 and samples.is_empty():return
 if not combat_active() or not wolf_form() or not is_instance_valid(skeleton):clear();return
 clock+=maxf(0,delta)
 if not source_control:
  remaining=maxf(0,remaining-delta)
  if remaining<=0:emitting=false
 if emitting:
  var positions=[]
  for bone in bindings:positions.append(skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin)
  samples.append({"points":positions,"time":clock,"sides":enabled_sides.duplicate()})
 samples=samples.filter(func(row):return clock-row.time<LIFETIME)
 if samples.is_empty() and not source_control:clear();return
 for side in range(2):
  var rows=samples.filter(func(row):return row.sides[side]);var mesh=meshes[side].mesh as ImmediateMesh;mesh.clear_surfaces();meshes[side].visible=rows.size()>=2
  if rows.size()<2:continue
  mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
  for i in range(rows.size()):
   var opacity=clampf(1.0-(clock-rows[i].time)/LIFETIME,0,1)
   for j in range(2):mesh.surface_set_color(Color(1,1,1,opacity));mesh.surface_set_uv(Vector2(float(i)/maxi(1,rows.size()-1),j));mesh.surface_add_vertex(rows[i].points[side*2+j])
  mesh.surface_end()
