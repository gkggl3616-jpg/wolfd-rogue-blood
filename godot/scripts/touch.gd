extends Node2D

var game
var move_finger = -1
var look_finger = -1
var center = Vector2.ZERO
var thumb = Vector2.ZERO
var look_last = Vector2.ZERO
var buttons = []
var last_size = Vector2.ZERO

func _ready():
	for item in [["fire", "ATEŞ"], ["jump", "ZIPLA"], ["crouch", "EĞİL"], ["reload", "ŞARJÖR"], ["transform", "DÖNÜŞ"], ["sprint", "KOŞ"], ["aim", "NİŞAN"]]:
		var button = TouchScreenButton.new()
		button.action = item[0]
		var shape = CircleShape2D.new()
		shape.radius = 33
		button.shape = shape
		button.shape_centered = true
		add_child(button)
		var text = Label.new()
		text.text = item[1]
		text.position = Vector2(-32, -9)
		text.size = Vector2(64, 20)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 12)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(text)
		buttons.append(button)
	resize()

func resize():
	last_size = get_viewport_rect().size
	center = Vector2(115, last_size.y - 132)
	var locations = [Vector2(-108,-132),Vector2(-195,-205),Vector2(-195,-64),Vector2(-280,-132),Vector2(-105,-265),Vector2(225,-95),Vector2(-280,-235)]
	for i in range(buttons.size()):
		buttons[i].position = Vector2(last_size.x, last_size.y) + locations[i] if i != 5 else Vector2(225,last_size.y - 95)
	queue_redraw()

func _process(_delta):
	visible = game.running and not game.menu_open
	if get_viewport_rect().size != last_size:
		resize()
	if not visible:
		reset()

func reset():
	move_finger = -1
	look_finger = -1
	thumb = Vector2.ZERO
	game.player.move_axis = Vector2.ZERO
	for button in buttons:
		Input.action_release(button.action)
	queue_redraw()

func _input(event):
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			for button in buttons:
				if event.position.distance_to(button.position) < 42:
					return
			if event.position.x < last_size.x * 0.35 and move_finger == -1:
				move_finger = event.index
				update_stick(event.position)
			elif look_finger == -1:
				look_finger = event.index
				look_last = event.position
		else:
			if event.index == move_finger:
				move_finger = -1
				thumb = Vector2.ZERO
				game.player.move_axis = Vector2.ZERO
				queue_redraw()
			if event.index == look_finger:
				look_finger = -1
	if event is InputEventScreenDrag:
		if event.index == move_finger:
			update_stick(event.position)
		elif event.index == look_finger:
			game.player.look(event.relative)

func update_stick(point):
	thumb = (point - center).limit_length(64)
	game.player.move_axis = thumb / 64 if thumb.length() > 8 else Vector2.ZERO
	queue_redraw()

func _draw():
	draw_circle(center, 76, Color(0.1, 0.14, 0.2, 0.6))
	draw_arc(center, 76, 0, TAU, 64, Color(0.7, 0.8, 0.9, 0.4), 2)
	draw_circle(center + thumb, 28, Color(0.7, 0.8, 0.9, 0.4))
	for button in buttons:
		draw_circle(button.position, 34, Color(0.68,0.2,0.18,0.65) if button.action == "fire" else Color(0.14,0.2,0.28,0.75))
		draw_arc(button.position, 34, 0, TAU, 40, Color(0.8,0.8,0.85,0.5), 1.5)
