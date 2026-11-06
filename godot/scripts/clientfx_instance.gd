extends Node3D
# Source curves/assets and socket attachments. Counts, light energy and camera
# displacement are bounded for mobile; unsupported source nodes stay diagnosed.
var system
var actor
var group=""
var looping=false
var depth=0
var elapsed=0.0
var duration=0.0
var tail=0.0
var parts=[]
func val(spec,key,fallback=null):return spec.properties.get(key,[fallback])[0]
func choice(spec,key,fallback=0):return int(str(val(spec,key,str(fallback))).get_slice(",",0))
func vector(values):return Vector3(values[0],values[1],-values[2])
func curve(spec,key,time,fallback):
	var keys=spec.properties.get(key,[])
	if keys.is_empty():return fallback
	if time<=float(keys[0][0]):return keys[0]
	for i in range(1,keys.size()):
		if time<=float(keys[i][0]):
			var a=keys[i-1];var b=keys[i];var t=clampf((time-float(a[0]))/maxf(0.001,float(b[0])-float(a[0])),0,1);var result=[time]
			for j in range(1,a.size()):result.append(lerpf(a[j],b[j],t))
			return result
	return keys[-1]
func material(spec):
	var result=StandardMaterial3D.new();result.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;result.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;result.cull_mode=BaseMaterial3D.CULL_DISABLED
	var blend=choice(spec,"BlendMode")
	if str(val(spec,"RenderStyle0","")).to_lower().contains("additive"):blend=1
	result.blend_mode=BaseMaterial3D.BLEND_MODE_ADD if blend in [1,7,9] else (BaseMaterial3D.BLEND_MODE_MUL if blend==2 else BaseMaterial3D.BLEND_MODE_MIX)
	result.no_depth_test=choice(spec,"DisableZ")==1
	return result
func _ready():
	for spec in system.catalog.groups[group].nodes:
		duration=maxf(duration,float(spec.end))
		if not spec.get("available",false):continue
		var node;var materials=[];var mat=material(spec);var kind=spec.type
		if kind=="LTBModel":
			node=load(spec.asset).instantiate();add_child(node)
			for mesh in node.find_children("*","MeshInstance3D",true,false):
				var slot=spec.get("meshSlots",{}).get(str(mesh.name),"0");var skin=spec.get("skins",{}).get(slot,{})
				var m=material(spec)
				var original=mesh.get_active_material(0)
				if original is BaseMaterial3D:m.albedo_texture=original.albedo_texture
				mesh.material_override=m;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;materials.append({"material":m,"frames":skin.get("frames",[]),"fps":skin.get("fps",1)})
			for anim in node.find_children("*","AnimationPlayer",true,false):
				if spec.get("animation","")!="" and anim.has_animation(spec.animation):anim.play(spec.animation)
		elif kind in ["Sprite","FlareSpriteFX"]:
			node=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2.ONE
			if not spec.get("frames",[]).is_empty():quad.size=load(spec.frames[0]).get_size()
			node.mesh=quad;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED if choice(spec,"Facing")==0 else BaseMaterial3D.BILLBOARD_DISABLED;node.material_override=mat;add_child(node);materials.append({"material":mat,"frames":spec.get("frames",[]),"fps":spec.get("fps",1)})
		elif kind in ["ParticleSystem","SpriteSystem"]:
			node=CPUParticles3D.new();node.emitting=false;node.one_shot=not looping
			var interval=maxf(0.02,float(val(spec,"EmissionInterval",0.1)));var emission=maxf(1,float(val(spec,"ParticlesPerEmission",val(spec,"SpritesPerEmission",5))))
			var lifetime=clampf(float(val(spec,"MaxParticleLifeSpan",val(spec,"MaxSpriteLifespan",0.5))),0.05,60)
			node.preprocess=minf(6,lifetime*.3) if looping and actor==null else 0
			node.amount=clampi(ceili(emission*(lifetime if looping else maxf(.02,minf(lifetime,float(spec.end)-float(spec.start))))/interval),1,128);node.lifetime=lifetime;node.lifetime_randomness=clampf(1.0-float(val(spec,"MinParticleLifeSpan",val(spec,"MinSpriteLifespan",lifetime)))/lifetime,0,1);node.explosiveness=clampf(1.0-minf(lifetime,maxf(0.02,float(spec.end)-float(spec.start)))/lifetime,0,1);tail=maxf(tail,lifetime)
			var shape=choice(spec,"Type",choice(spec,"EmissionType"));var radius=maxf(0,float(val(spec,"MaxRadius",10)))*0.016
			node.emission_shape=CPUParticles3D.EMISSION_SHAPE_POINT if shape==1 else CPUParticles3D.EMISSION_SHAPE_SPHERE;node.emission_sphere_radius=radius
			if shape in [2,4]:
				node.emission_shape=CPUParticles3D.EMISSION_SHAPE_RING;node.emission_ring_radius=radius;node.emission_ring_inner_radius=clampf(float(val(spec,"MinRadius",0))*0.016,0,radius);node.emission_ring_height=0.01 if shape==2 else radius
			var low=vector(val(spec,"MinParticleVelocity",val(spec,"MinSpriteVelocity",[0,0,0])));var high=vector(val(spec,"MaxParticleVelocity",val(spec,"MaxSpriteVelocity",[0,10,0])))
			node.direction=(low+high).normalized() if (low+high).length()>0.001 else Vector3.UP;node.spread=90 if low.dot(high)<0 else 35
			node.initial_velocity_min=minf(low.length(),high.length())*0.016;node.initial_velocity_max=maxf(low.length(),high.length())*0.016
			node.gravity=Vector3.DOWN*float(val(spec,"GravityAcceleration",0))*0.016+vector(val(spec,"AdditionalAcceleration",[0,0,0]))*0.016
			var bounds=minf(256,maxf(2,radius+node.initial_velocity_max*lifetime+float(curve(spec,"Sk",0,[0,10])[1])*.016))
			node.visibility_aabb=AABB(Vector3.ONE*-bounds,Vector3.ONE*bounds*2)
			node.local_coords=choice(spec,"MoveParticlesWithSystem")==1;node.angular_velocity_min=float(val(spec,"MinAngularVelocity",0));node.angular_velocity_max=float(val(spec,"MaxAngularVelocity",0))
			var colors=spec.properties.get("Ck",[])
			if not colors.is_empty():
				var gradient=Gradient.new();gradient.offsets=PackedFloat32Array();gradient.colors=PackedColorArray()
				for ck in colors:gradient.add_point(clampf(ck[0],0,1),Color(ck[1],ck[2],ck[3],ck[4]))
				node.color_ramp=gradient;mat.vertex_color_use_as_albedo=true
			var quad=QuadMesh.new();quad.size=Vector2.ONE;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;quad.material=mat;node.mesh=quad;add_child(node);materials.append({"material":mat,"frames":spec.get("frames",[]),"fps":spec.get("fps",1)})
		elif kind=="DynaLight":node=OmniLight3D.new();node.shadow_enabled=false;add_child(node)
		elif kind=="PlaySound":
			node=AudioStreamPlayer3D.new();node.bus="WolfEffects";node.stream=load(spec.sound).duplicate();node.max_distance=maxf(1,float(val(spec,"OuterRadius",2400))*0.016);node.pitch_scale=clampf(float(val(spec,"PitchShift",1)),0.1,4);node.volume_db=linear_to_db(maxf(0.001,float(val(spec,"Volume",100))/100.0))-10
			var loop_sound=choice(spec,"Loop")==1
			if node.stream is AudioStreamWAV:node.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD if loop_sound else AudioStreamWAV.LOOP_DISABLED;node.stream.loop_begin=0;node.stream.loop_end=roundi(node.stream.get_length()*node.stream.mix_rate)
			elif node.stream is AudioStreamOggVorbis or node.stream is AudioStreamMP3:node.stream.loop=loop_sound
			add_child(node)
		elif kind in ["LightningFX","PolyTrail"]:
			node=MeshInstance3D.new();node.mesh=ImmediateMesh.new();node.material_override=mat;mat.vertex_color_use_as_albedo=true
			if spec.get("texture","")!="":mat.albedo_texture=load(spec.texture)
			add_child(node);materials.append({"material":mat,"frames":[],"fps":1})
		else:node=Node3D.new();add_child(node)
		node.hide();parts.append({"node":node,"spec":spec,"materials":materials,"baseScale":node.scale,"started":false,"samples":[],"nextSample":0.0,"child":null,"fixed":Transform3D.IDENTITY})
	duration=maxf(0.05,duration)
func _process(delta):
	if not system.game.is_match_active() or (actor!=null and (not is_instance_valid(actor) or actor.is_queued_for_deletion())):queue_free();return
	elapsed+=delta
	if is_instance_valid(actor) and get_parent()==system.game.transient_effects:global_transform=Transform3D(actor.global_basis,actor.global_position)
	if not looping and elapsed>duration+tail:queue_free();return
	var age=fmod(elapsed,duration) if looping else elapsed
	for part in parts:
		var spec=part.spec;var node=part.node;var kind=spec.type
		if age<float(spec.start):node.hide();continue
		if age>float(spec.end)+(node.lifetime if node is CPUParticles3D else 0):
			node.hide()
			if node is AudioStreamPlayer3D:node.stop()
			continue
		var life=age-float(spec.start);var phase=clampf(life/maxf(0.001,float(spec.end)-float(spec.start)),0,1);var ck=curve(spec,"Ck",phase,[0,1,1,1,1]);var color=Color(ck[1],ck[2],ck[3],ck[4]);var scale_key=curve(spec,"Sk",phase,[0,1]);var scale_value=maxf(0.001,float(scale_key[1]));node.show()
		if is_instance_valid(actor):
			var socket=str(val(spec,"AttachName",""))
			node.global_transform=system.socket_transform(actor,socket) if socket!="" else global_transform
			# SocketAttach chooses a position. ClientFX ParentAlign uses the
			# reference object's orientation, not the animated neck/hand basis.
			node.global_basis=actor.global_basis.orthonormalized()
		else:node.global_transform=global_transform
		var offset=vector(val(spec,"Offset",[0,0,0]))*0.016;node.global_position+=global_basis.orthonormalized()*offset
		if choice(spec,"UpdatePos")==0:
			# A nested fly effect is fixed in its moving projectile reference
			# frame. Freezing that child in world space leaves it behind the hand.
			if not part.started:part.fixed=node.transform if depth>0 else node.global_transform
			elif depth>0:node.transform=part.fixed
			else:node.global_transform=part.fixed
		var rotation=vector(val(spec,"RotateAdd",[0,0,0]))+vector(val(spec,"Rotate",[0,0,0]))*life
		node.rotate_object_local(Vector3.RIGHT,deg_to_rad(rotation.x));node.rotate_object_local(Vector3.UP,deg_to_rad(rotation.y));node.rotate_object_local(Vector3.BACK,deg_to_rad(rotation.z))
		if not part.started:
			part.started=true
			if node is CPUParticles3D:node.emitting=true;node.restart()
			if node is AudioStreamPlayer3D and not system.game.test_mode:node.play()
			if kind=="CreateFX":part.child=system.play(spec.group,null if system.catalog.groups[group].get("sourceType","")=="ProjectileFX" else actor,node.global_position,choice(spec,"Loop")==1,depth+1,node)
		if node is OmniLight3D:node.light_color=color;node.light_energy=color.a*0.6;node.omni_range=maxf(0.1,scale_value*0.016)
		elif node is CPUParticles3D:node.scale_amount_min=scale_value*0.016;node.scale_amount_max=scale_value*0.016
		elif kind=="LTBModel":node.scale=part.baseScale*scale_value*vector(val(spec,"ModelScale",[1,1,-1])).abs()
		elif kind in ["Sprite","FlareSpriteFX"]:node.scale=Vector3.ONE*scale_value*0.016
		elif kind=="CamJitter":
			var distance=node.global_position.distance_to(system.game.player.camera.global_position);var outer=maxf(0.1,float(val(spec,"OuterRadius",600))*.016);var inner=float(val(spec,"InnerRadius",0))*.016
			var strength=clampf((outer-distance)/maxf(.01,outer-inner),0,1)*minf(.08,scale_value*.001)
			system.camera_shake+=Vector2(sin(elapsed*97),cos(elapsed*89))*strength
		elif kind=="LightningFX":lightning(part,color)
		elif kind=="PolyTrail":trail(part,color)
		for entry in part.materials:
			entry.material.albedo_color=Color.WHITE if node is CPUParticles3D or kind in ["PolyTrail","LightningFX"] else color
			if not entry.frames.is_empty():entry.material.albedo_texture=load(entry.frames[int(life*float(entry.fps))%entry.frames.size()])
func lightning(part,color):
	if elapsed<part.nextSample:return
	var spec=part.spec;var mesh=part.node.mesh as ImmediateMesh;mesh.clear_surfaces();part.nextSample=elapsed+maxf(0.025,float(val(spec,"MinLifetime",0.05)))
	var radius=maxf(0.01,float(val(spec,"OmniDirectionalRadius",50))*.016);var bolts=clampi(int(val(spec,"MaxNumBolts",2)),1,8);var segments=clampi(int(val(spec,"MaxSegmentsPerBolt",3)),2,12);var width=maxf(0.001,float(val(spec,"MaxBoltWidth",1))*.016)
	for bolt in range(bolts):
		var end=Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1)).normalized()*radius;var side=end.cross(Vector3.UP).normalized()*width
		if side.is_zero_approx():side=Vector3.RIGHT*width
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in range(segments+1):
			var t=float(i)/segments;var point=end*t
			if i>0 and i<segments:point+=Vector3(randf_range(-.1,.1),randf_range(-.1,.1),randf_range(-.1,.1))*radius
			for edge in [-1,1]:mesh.surface_set_color(color);mesh.surface_set_uv(Vector2(t,(edge+1)*.5));mesh.surface_add_vertex(point+side*edge)
		mesh.surface_end()
func trail(part,color):
	if elapsed<part.nextSample:return
	var spec=part.spec;part.nextSample=elapsed+maxf(.016,float(val(spec,"SectionInterval",.02)));part.samples.append({"point":part.node.global_position,"time":elapsed})
	var lifetime=maxf(.02,float(val(spec,"SectionLifespan",.2)));part.samples=part.samples.filter(func(s):return elapsed-s.time<=lifetime)
	if part.samples.size()>32:part.samples.pop_front()
	var mesh=part.node.mesh as ImmediateMesh;mesh.clear_surfaces()
	if part.samples.size()<2:return
	var width=maxf(.001,float(val(spec,"TrailWidth",.5))*.016);mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(part.samples.size()):
		var t=float(i)/maxi(1,part.samples.size()-1);var point=part.node.to_local(part.samples[i].point)
		for edge in [-1,1]:mesh.surface_set_color(Color(color,color.a*t));mesh.surface_set_uv(Vector2(t,(edge+1)*.5));mesh.surface_add_vertex(point+Vector3.RIGHT*width*edge)
	mesh.surface_end()
