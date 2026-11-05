extends Node2D
const Art=preload("res://ui/source_theme.gd")

# A touch belongs to exactly one target until release. Visual targets deliberately
# do not use TouchScreenButton's independent global input handling.
class TouchTarget extends Node2D:
	signal pressed
	var action = ""

var game
var move_finger = -1
var look_finger = -1
var center = Vector2.ZERO
var thumb = Vector2.ZERO
var buttons = []
var last_size = Vector2.ZERO
var direction_buttons = false
var action_fingers = {}
var ui_scale = 1.0
var stick_radius = 64.0
var icon_textures = {}
var last_icon_state = []

func _ready():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/control-icons.json"))
	if catalog is Dictionary:
		for key in catalog:
			var entry=catalog[key]
			icon_textures[key]=Art.atlas(entry.asset,Rect2(entry.region[0],entry.region[1],entry.region[2],entry.region[3])) if entry.has("region") else Art.texture(entry.asset)
	for item in [["fire", "ATEŞ"], ["jump", "ZIPLA"], ["crouch", "EĞİL"], ["reload", "ŞARJÖR"], ["transform", "DÖNÜŞ"], ["sprint", "KOŞ"], ["aim", "NİŞAN"], ["forward", "İLERİ"], ["backward", "GERİ"], ["left", "SOL"], ["right", "SAĞ"], ["roll", "TAKLA"]]:
		var button = TouchTarget.new()
		button.action = item[0]
		add_child(button)
		var text = Label.new()
		text.text = item[1]
		text.position = Vector2(-34, -8)
		text.size = Vector2(68, 20)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 10)
		text.add_theme_font_override("font",Art.font())
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text)
		var icon=Sprite2D.new();icon.name="ActionImage";button.add_child(icon)
		buttons.append(button)
	buttons[5].pressed.connect(func():
		if can_control():
			game.player.normal_run_toggled = not game.player.normal_run_toggled
	)
	resize()

func can_control():
	return game.is_combat_active()

func resize():
	reset()
	last_size = get_viewport_rect().size
	ui_scale = minf(last_size.y / 720.0, last_size.x / 1024.0)
	stick_radius = 64.0 * ui_scale
	center = last_size * Vector2(0.20, 0.76)
	var locations = [Vector2(0.68,0.77), Vector2(0.79,0.62), Vector2(0.85,0.71), Vector2(0.75,0.86), Vector2(0.72,0.64), Vector2(0.61,0.62), Vector2(0.83,0.88)]
	for i in range(7):
		buttons[i].position = last_size * locations[i]
	for i in range(4):
		buttons[i+7].position = center + [Vector2(0,-70), Vector2(0,70), Vector2(-70,0), Vector2(70,0)][i] * ui_scale
	buttons[11].position = last_size * Vector2(0.65, 0.91)
	for button in buttons:button.scale = Vector2.ONE * ui_scale
	queue_redraw()

func _process(_delta):
	visible = can_control()
	for i in range(7, 11):
		buttons[i].visible = direction_buttons
	buttons[11].visible = game.player.is_wolf
	buttons[4].visible = not game.hunt.active and int(game.local_room.get("mode",0))!=game.WOLF_BATTLE
	buttons[5].get_child(0).text = "KOŞ AÇIK" if game.player.normal_run_toggled else "KOŞU"
	buttons[3].get_child(0).text = "KÜKRE" if game.player.is_wolf else "ŞARJÖR"
	buttons[6].get_child(0).text = "GÜÇLÜ" if game.player.is_wolf else "NİŞAN"
	buttons[0].get_child(0).visible = false
	buttons[4].get_child(0).visible = false
	buttons[2].get_child(0).text = "ÇÖMEL"
	var icon_state=[game.player.is_wolf,game.player.weapon_info.get("category","rifle"),game.player.mutation_id]
	if last_icon_state!=icon_state:
		last_icon_state=icon_state
		for button in buttons:
			var key=button.action
			if key=="fire" and game.player.is_wolf:key="wolf_fire"
			elif key=="fire" and icon_state[1]=="knife":key="knife_fire"
			elif key=="fire" and icon_state[1]=="grenade":key="grenade_fire"
			if key=="reload" and game.player.is_wolf:key="roar"
			if key=="aim" and game.player.is_wolf:key="strong"
			var image=button.get_child(1) as Sprite2D
			image.texture=icon_textures.get(key)
			if key=="strong" and game.player.mutation_id in ["guardian","ghost"]:image.texture=Art.texture("wt_interface/play/common/skillup_%swolf.dtx" % game.player.mutation_id)
			if button.action=="transform" and game.player.is_wolf:image.texture=Art.texture("res://assets/ui/form-icons/human.png")
			if image.texture:
				image.scale=Vector2.ONE*(44.0/maxf(image.texture.get_width(),image.texture.get_height()))
			button.get_child(0).visible=image.texture==null and not button.action in ["forward","backward","left","right"]
	if get_viewport_rect().size != last_size:
		resize()
	if not visible:
		reset()
	queue_redraw()

func reset():
	move_finger = -1
	look_finger = -1
	thumb = Vector2.ZERO
	action_fingers.clear()
	game.player.move_axis = Vector2.ZERO
	for button in buttons:
		Input.action_release(button.action)

func release_finger(index):
	if action_fingers.has(index):
		var action = action_fingers[index]
		action_fingers.erase(index)
		if not action in action_fingers.values():
			Input.action_release(action)
	if index == move_finger:
		move_finger = -1
		thumb = Vector2.ZERO
		game.player.move_axis = Vector2.ZERO
	if index == look_finger:
		look_finger = -1

func _input(event):
	# Owned releases must be received even when a GUI now covers this finger.
	if event is InputEventScreenTouch and not event.pressed:
		release_finger(event.index)
	elif event is InputEventScreenDrag and can_control():
		if event.index == move_finger:
			update_stick(event.position)
		elif event.index == look_finger:
			game.player.look(event.relative * (720.0 / maxf(1.0, last_size.y)))

func _unhandled_input(event):
	if not event is InputEventScreenTouch or not event.pressed or not can_control():
		return
	if action_fingers.has(event.index) or event.index == move_finger or event.index == look_finger:
		return
	if game.gameplay_touch_blocked(event.position):
		return
	for button in buttons:
		if not button.visible or (button.action == "roll" and not game.player.is_wolf):
			continue
		if button.action in ["forward", "backward", "left", "right"] and not direction_buttons:
			continue
		if event.position.distance_to(button.position) <= (38 if button.action == "fire" else 34) * ui_scale:
			var was_held = button.action in action_fingers.values()
			action_fingers[event.index] = button.action
			if not was_held:
				Input.action_press(button.action)
				button.pressed.emit()
			get_viewport().set_input_as_handled()
			return
	if event.position.x < last_size.x * 0.35:
		if direction_buttons or move_finger != -1:
			return
		move_finger = event.index
		update_stick(event.position)
	elif look_finger == -1:
		look_finger = event.index
	get_viewport().set_input_as_handled()

func update_stick(point):
	thumb = (point - center).limit_length(stick_radius)
	var deadzone = stick_radius * 0.125
	game.player.move_axis = thumb.normalized() * ((thumb.length()-deadzone)/(stick_radius-deadzone)) if thumb.length() > deadzone else Vector2.ZERO
	queue_redraw()

func _draw():
	if not direction_buttons:
		draw_circle(center, 76 * ui_scale, Color(0.04,0.05,0.06,0.20))
		draw_arc(center, 76 * ui_scale, 0, TAU, 64, Color(0.7,0.8,0.9,0.32), 1.5 * ui_scale)
		draw_circle(center + thumb, 31 * ui_scale, Color(0.04,0.05,0.06,0.55))
		draw_arc(center + thumb, 31 * ui_scale, 0, TAU, 40, Color(0.66,0.53,0.26,0.7), 2 * ui_scale)
	for button in buttons:
		if not button.visible:
			continue
		var radius = (32 if button.action == "fire" else 27) * ui_scale
		var color = Color(0.04,0.05,0.06,0.64)
		if Input.is_action_pressed(button.action) or (button.action == "sprint" and game.player.normal_run_toggled):
			color = color.lightened(0.35)
		draw_circle(button.position,radius,color)
		var border = Color(0.67,0.73,0.75,0.55)
		if button.action == "transform":border = Color("b19a38")
		if button.action == "aim" and game.player.is_wolf:border=Color("bd944b")
		draw_arc(button.position,radius,0,TAU,48,border,1.4*ui_scale,true)
		if button.action in ["forward","backward","left","right"]:
			var direction={"forward":Vector2.UP,"backward":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[button.action]
			var across=Vector2(-direction.y,direction.x)
			draw_colored_polygon(PackedVector2Array([button.position+direction*13*ui_scale,button.position-direction*7*ui_scale+across*9*ui_scale,button.position-direction*7*ui_scale-across*9*ui_scale]),Color("d6dddd"))
		if button.get_child(1).texture!=null:continue
		if button.action == "fire":
			if game.player.is_wolf:
				for i in range(3):
					var at = button.position + Vector2(-12+i*8,-8)*ui_scale
					draw_line(at,at+Vector2(9,17)*ui_scale,Color(0.9,0.92,0.94,0.9),3*ui_scale,true)
			else:
				draw_arc(button.position,11*ui_scale,0,TAU,24,Color(0.9,0.92,0.94,0.9),1.5*ui_scale,true)
				for i in range(4):
					var dir = Vector2.from_angle(PI*i/2)
					draw_line(button.position+dir*7*ui_scale,button.position+dir*16*ui_scale,Color.WHITE,1.5*ui_scale,true)
		elif button.action == "transform":
			for offset in [Vector2(-8,-6),Vector2(-3,-11),Vector2(4,-11),Vector2(9,-5)]:
				draw_circle(button.position+offset*ui_scale,3*ui_scale,Color("d8c063"))
			draw_circle(button.position+Vector2(0,5)*ui_scale,7*ui_scale,Color("d8c063"))
