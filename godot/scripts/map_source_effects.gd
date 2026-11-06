extends Node3D
var game
var map_number=0
var entries=[]
var sprites=[]
var missing=[]
var clock=0.0
func _ready():
	var path="res://assets/maps/%d-objects.json" % map_number
	if not FileAccess.file_exists(path):return
	for row in JSON.parse_string(FileAccess.get_file_as_string(path)):
		var p=row.get("properties",{})
		if not p.get("StartOn",true) or p.get("Template",false):continue
		var position=p.get("Pos",[0,0,0]);var point=Vector3(position[0],position[1],-position[2])*.016
		if row.type=="SpecialFX":
			var name=game.clientfx.canonical(p.get("FxName",""))
			if name=="":
				if p.get("FxName","<none>")!="<none>":missing.append({"object":p.get("Name",""),"effect":p.get("FxName",""),"reason":"definition_missing"})
				continue
			entries.append({"name":name,"point":point,"loop":p.get("Loop",false),"instance":null,"played":false})
		elif row.type=="ScaleSprite":
			var key=str(p.get("Filename","")).replace("\\","/").to_lower().trim_prefix("root/");var source=game.clientfx.catalog.mapSprites.get(key,{})
			if source.get("frames",[]).is_empty():missing.append({"object":p.get("Name",""),"source":key,"reason":"sprite_source_missing"});continue
			var sprite=Sprite3D.new();sprite.texture=load(source.frames[0]);sprite.pixel_size=.016;sprite.position=point;sprite.scale=Vector3(float(p.get("ScaleX",1)),float(p.get("ScaleY",1)),1)
			sprite.billboard=BaseMaterial3D.BILLBOARD_DISABLED if p.get("Rotatable",false) else BaseMaterial3D.BILLBOARD_ENABLED;sprite.shaded=false
			var color=p.get("Color",[255,255,255]);sprite.modulate=Color(color[0]/255.0,color[1]/255.0,color[2]/255.0,p.get("Alpha",1));sprite.no_depth_test=false
			if p.get("Additive",false):
				var m=StandardMaterial3D.new();m.albedo_texture=sprite.texture;m.albedo_color=sprite.modulate;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;m.billboard_mode=sprite.billboard;sprite.material_override=m
			add_child(sprite);sprites.append({"node":sprite,"source":source})
func _process(delta):
	clock+=delta
	for sprite in sprites:
		sprite.node.visible=game.running and not game.menu_open
		var source=sprite.source;var texture=load(source.frames[int(clock*source.fps)%source.frames.size()]);sprite.node.texture=texture
		if sprite.node.material_override:sprite.node.material_override.albedo_texture=texture
	if not game.is_match_active():return
	for entry in entries:
		if is_instance_valid(entry.instance) and not entry.instance.is_queued_for_deletion():continue
		if entry.played and not entry.loop:continue
		entry.instance=game.clientfx.play(entry.name,null,entry.point,entry.loop,0,self);entry.played=is_instance_valid(entry.instance)
