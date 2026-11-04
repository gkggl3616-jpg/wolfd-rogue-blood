extends SceneTree

const Touch = preload("res://scripts/touch.gd")
class PlayerDouble extends RefCounted:
	var move_axis = Vector2.ZERO
	var normal_run_toggled = false
	var is_wolf = false
	var look_total = Vector2.ZERO
	func look(delta): look_total += delta

class GameDouble extends RefCounted:
	var running = true
	var menu_open = false
	var application_suspended = false
	var player = PlayerDouble.new()
	var blocked = Rect2(850, 20, 150, 50)
	func gameplay_touch_blocked(point): return blocked.has_point(point)

var checks = 0
var failures = 0
var touch
var game

func _initialize(): call_deferred("run")

func ensure(value, description):
	checks += 1
	if not value: failures += 1;push_error("FAIL " + description)
	else: print("PASS " + description)

func down(index, point):
	var event = InputEventScreenTouch.new()
	event.index = index;event.position = point;event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func up(index):
	var event = InputEventScreenTouch.new()
	event.index = index;event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index, point, delta):
	var event = InputEventScreenDrag.new()
	event.index = index;event.position = point;event.relative = delta
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run():
	root.size = Vector2i(1280, 720)
	for action in ["fire", "jump", "crouch", "reload", "transform", "sprint", "aim", "forward", "backward", "left", "right", "roll"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	game = GameDouble.new()
	touch = Touch.new();touch.game = game;root.add_child(touch)
	touch.direction_buttons = false
	await process_frame
	down(1, touch.center)
	drag(1, touch.center + Vector2(0, -60), Vector2(0, -60))
	down(2, Vector2(700, 300))
	drag(2, Vector2(720, 300), Vector2(20, 0))
	down(3, touch.buttons[0].position)
	ensure(game.player.move_axis.y < -0.8 and game.player.look_total.x == 20 and Input.is_action_pressed("fire"), "move, look and fire retain three independent fingers")
	up(3)
	drag(2, touch.buttons[0].position, Vector2(12, 0))
	ensure(not Input.is_action_pressed("fire") and touch.look_finger == 2, "look finger cannot become fire by dragging across button")
	up(1);up(2)
	down(3, touch.buttons[0].position);down(4, touch.buttons[0].position)
	up(3)
	ensure(Input.is_action_pressed("fire"), "releasing one of two fire fingers does not release the other")
	drag(4, Vector2(650, 320), Vector2(100, 40))
	ensure(touch.look_finger == -1, "held action finger never becomes camera drag")
	up(4)
	ensure(not Input.is_action_pressed("fire"), "last fire finger releases action")
	down(5, game.blocked.get_center())
	ensure(touch.look_finger == -1 and not touch.action_fingers.has(5), "actual HUD control bounds block gameplay capture")
	up(5)
	game.menu_open = true
	down(6, touch.buttons[0].position)
	ensure(not Input.is_action_pressed("fire"), "opening menu blocks touches immediately before visibility updates")
	game.menu_open = false
	drag(6, Vector2(750, 300), Vector2(10, 0))
	ensure(touch.look_finger == -1, "menu-owned drag cannot acquire camera after closing")
	up(6)
	down(7, touch.buttons[5].position);down(8, touch.buttons[5].position)
	ensure(game.player.normal_run_toggled, "two simultaneous sprint fingers toggle run only once")
	up(7);up(8)
	down(9, touch.buttons[0].position)
	touch.resize()
	ensure(not Input.is_action_pressed("fire") and touch.action_fingers.is_empty(), "viewport resize clears previous touch ownership")
	game.application_suspended = true
	down(10, touch.buttons[0].position)
	ensure(not Input.is_action_pressed("fire"), "background application cannot acquire touch actions")
	game.application_suspended = false
	touch.direction_buttons = true
	await process_frame
	down(11, touch.buttons[7].position);down(12, touch.buttons[7].position);up(11)
	ensure(Input.is_action_pressed("forward"), "overlapping forward fingers do not create a false release and second tap")
	up(12)
	ensure(not Input.is_action_pressed("forward"), "last forward release stops movement")
	touch.reset();touch.queue_free()
	await process_frame
	print("TOUCH_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
