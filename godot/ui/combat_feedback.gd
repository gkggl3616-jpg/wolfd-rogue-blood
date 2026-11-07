extends Control
const Art=preload("res://ui/source_theme.gd")
var game
var hit_time=0.0
var hurt_time=0.0
var hit:TextureRect
var arrow:TextureRect
var vignette:ColorRect

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	vignette=ColorRect.new();vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader=Shader.new()
	shader.code="shader_type canvas_item; uniform float strength=0.0; void fragment(){vec2 p=abs(UV-vec2(0.5))*2.0; float edge=smoothstep(0.45,1.0,max(p.x,p.y)); COLOR=vec4(0.68,0.015,0.035,edge*edge*strength);}"
	var surface=ShaderMaterial.new();surface.shader=shader;vignette.material=surface;add_child(vignette)
	hit=Art.sprite(self,"wt_interface/play/hit.dtx",Vector2.ZERO,Vector2(32,32),Rect2(0,0,32,32))
	arrow=Art.sprite(self,"wt_interface/hud/damagearrow.dtx",Vector2.ZERO,Vector2(100,100))
	arrow.pivot_offset=Vector2(50,50)
	hit.hide();arrow.hide()

func show_hit():hit_time=0.16

func show_damage(source_position=null):
	hurt_time=0.65
	if source_position is Vector3:
		var actor=game.spectator.target if game.spectator.active and game.actor_alive(game.spectator.target) else game.player
		var local=actor.global_basis.inverse()*(source_position-actor.global_position)
		arrow.rotation=atan2(local.x,-local.z)
		arrow.set_meta("has_direction",true)
	else:arrow.set_meta("has_direction",false)

func reset():
	hit_time=0;hurt_time=0
	if is_instance_valid(hit):hit.hide();arrow.hide();vignette.material.set_shader_parameter("strength",0.0)

func _process(delta):
	visible=game.running and not game.menu_open
	if not visible:reset();return
	hit_time=maxf(0,hit_time-delta);hurt_time=maxf(0,hurt_time-delta)
	var dimensions=get_viewport_rect().size
	hit.position=dimensions*0.5-Vector2(16,16);hit.visible=hit_time>0
	arrow.position=dimensions*0.5-Vector2(50,50);arrow.visible=hurt_time>0 and arrow.get_meta("has_direction",false)
	arrow.modulate.a=clampf(hurt_time/0.65,0,1)
	var watched=game.spectator.target if game.spectator.active and game.actor_alive(game.spectator.target) else null
	var health=watched.health if watched!=null else game.health
	var low_health=clampf((25.0-health)/25.0,0,1)*0.25 if health>0 else 0.0
	vignette.material.set_shader_parameter("strength",maxf(low_health,hurt_time*0.7))
