extends Node2D

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
var direction_buttons = true
var action_fingers = {}

func _ready():
	for item in [["fire", "ATEŞ"], ["jump", "ZIPLA"], ["crouch", "EĞİL"], ["reload", "ŞARJÖR"], ["transform", "DÖNÜŞ"], ["sprint", "KOŞ"], ["aim", "NİŞAN"], ["forward", "İLERİ"], ["backward", "GERİ"], ["left", "SOL"], ["right", "SAĞ"], ["roll", "TAKLA"]]:
		var button = TouchTarget.new()
		button.action = item[0]
		add_child(button)
		var text = Label.new()
		text.text = item[1]
		text.position = Vector2(-38, -10)
		text.size = Vector2(76, 24)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 12)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text)
		buttons.append(button)
	buttons[5].pressed.connect(func():
		if can_control():
			game.player.normal_run_toggled = not game.player.normal_run_toggled
	)
	resize()

func can_control():
	return game.running and not game.menu_open and not game.application_suspended

func resize():
	reset()
	last_size = get_viewport_rect().size
	center = Vector2(115, last_size.y - 132)
	var locations = [Vector2(-108,-132), Vector2(-195,-205), Vector2(-195,-64), Vector2(-280,-132), Vector2(-105,-265), Vector2(225,-95), Vector2(-280,-235)]
	for i in range(7):
		buttons[i].position = Vector2(last_size.x, last_size.y) + locations[i] if i != 5 else Vector2(265, last_size.y - 205)
	for i in range(4):
		buttons[i+7].position = center + [Vector2(0,-70), Vector2(0,70), Vector2(-70,0), Vector2(70,0)][i]
	buttons[11].position = Vector2(last_size.x - 370, last_size.y - 132)
	queue_redraw()

func _process(_delta):
	visible = can_control()
	for i in range(7, 11):
		buttons[i].visible = direction_buttons
	buttons[11].visible = game.player.is_wolf
	buttons[5].get_child(0).text = "KOŞ AÇIK" if game.player.normal_run_toggled else "KOŞ"
	buttons[3].get_child(0).text = "KÜKRE" if game.player.is_wolf else "ŞARJÖR"
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
			game.player.look(event.relative)

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
		if event.position.distance_to(button.position) <= (44 if button.action == "fire" else 33):
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
	thumb = (point - center).limit_length(64)
	game.player.move_axis = thumb / 64 if thumb.length() > 8 else Vector2.ZERO
	queue_redraw()

func _draw():
	if not direction_buttons:
		draw_circle(center, 76, Color(0.1,0.14,0.2,0.6))
		draw_arc(center, 76, 0, TAU, 64, Color(0.7,0.8,0.9,0.4), 2)
		draw_circle(center + thumb, 28, Color(0.7,0.8,0.9,0.4))
	for button in buttons:
		if not button.visible:
			continue
		var radius = 45 if button.action == "fire" else 34
		var color = Color(0.68,0.2,0.18,0.65) if button.action == "fire" else Color(0.14,0.2,0.28,0.75)
		if Input.is_action_pressed(button.action) or (button.action == "sprint" and game.player.normal_run_toggled):
			color = color.lightened(0.35)
		draw_circle(button.position, radius, color)
		draw_arc(button.position, radius, 0, TAU, 40, Color(0.8,0.8,0.85,0.5), 1.5)
