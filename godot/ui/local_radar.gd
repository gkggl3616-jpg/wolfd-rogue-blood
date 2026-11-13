extends Control
const Art=preload("res://ui/source_theme.gd")
var game
var records=[]
var current_number=-1
var record={}
var image:Texture2D

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/radar.json"))
	if source is Array:records=source

func projection(position_3d):
	if record.is_empty():return Vector2.ZERO
	return (Vector2(position_3d.x,position_3d.z)-Vector2(record.worldOrigin[0],record.worldOrigin[1]))/float(record.worldSize)*size

func _process(_delta):
	var number=game.offline_map_number
	if game.exploring and is_instance_valid(game.active_map):number=int(game.active_map.get_meta("map_number",0))
	if number!=current_number:
		current_number=number;record={};image=null
		for entry in records:
			if int(entry.number)==number:record=entry;image=load(entry.asset);break
	visible=not record.is_empty() and game.running and not game.menu_open
	if visible:queue_redraw()

func _draw():
	if image==null:return
	draw_texture_rect(image,Rect2(Vector2.ZERO,size),false,Color(1,1,1,0.85))
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.65,0.69,0.68,0.8),false,1)
	var actor=game.spectator.target if game.spectator.active and game.actor_alive(game.spectator.target) else game.player
	var point=projection(actor.global_position).clamp(Vector2.ONE*4,size-Vector2.ONE*4)
	draw_arc(point,5,0,TAU,24,Color("e6c26b"),1.4,true)
	var yaw=actor.rotation.y
	var forward=Vector2(-sin(yaw),-cos(yaw))
	var right=Vector2(-forward.y,forward.x)
	draw_colored_polygon(PackedVector2Array([point+forward*7,point-forward*4+right*3.5,point-forward*4-right*3.5]),Color("eaf6f5"))
	if game.destruction.enabled:
		for site in game.destruction.sites:
			var location=projection(game.destruction.site_position(site))
			draw_circle(location,3,Color("e6c26b"))
		if game.destruction.planted or game.destruction.dropped:
			draw_arc(projection(game.destruction.bomb),6,0,TAU,16,Color("ff6d45"),2,true)
