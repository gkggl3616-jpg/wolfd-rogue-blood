extends SceneTree

const Touch = preload("res://scripts/touch.gd")
class PlayerDouble extends RefCounted:
	var move_axis = Vector2.ZERO
	var normal_run_toggled = false
	var is_wolf = false
	var mutation_id="normal"
	var weapon_info = {"category":"rifle"}
	var look_total = Vector2.ZERO
	func look(delta): look_total += delta

class EquipmentDouble extends RefCounted:
	func has_wolf_ability():return false

class GameDouble extends RefCounted:
	var equipment=EquipmentDouble.new()
	var book={"control_layout":{}}
	var destruction={"enabled":false}
	var health=100
	var running = true
	var menu_open = false
	var application_suspended = false
	var player = PlayerDouble.new()
	const WOLF_BATTLE=900003
	var local_room={}
	var hunt={"active":false}
	func is_combat_active():return running and not menu_open and not application_suspended
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
	event.index = index;event.position = root.get_final_transform()*point;event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func up(index):
	var event = InputEventScreenTouch.new()
	event.index = index;event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index, point, delta):
	var event = InputEventScreenDrag.new()
	event.index = index;event.position = root.get_final_transform()*point
	event.relative = root.get_final_transform()*delta-root.get_final_transform().origin
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run():
	root.size = Vector2i(1280, 720)
	for action in ["fire", "jump", "crouch", "reload", "transform", "sprint", "aim", "forward", "backward", "left", "right", "roll","interact"]:
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
	touch.direction_buttons=false;await process_frame
	down(13,touch.center);drag(13,touch.center+Vector2(2,0),Vector2(2,0))
	ensure(game.player.move_axis.is_zero_approx(),"joystick deadzone cannot drift the character")
	drag(13,touch.center+Vector2(200,-200),Vector2(198,-200))
	ensure(is_equal_approx(game.player.move_axis.length(),1.0),"diagonal joystick motion stays clamped to unit speed")
	up(13)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(2160,992)]:
		root.size=dimensions
		for i in range(3):await process_frame
		var start=touch.last_size*Vector2(0.48,0.35)
		var delta=Vector2(touch.last_size.y*0.1,0)
		game.player.look_total=Vector2.ZERO
		down(14,start);drag(14,start+delta,delta);up(14)
		ensure(is_equal_approx(game.player.look_total.x,72),"same relative touch gesture turns equally at "+str(dimensions))
		down(15,touch.buttons[0].position)
		ensure(Input.is_action_pressed("fire"),"scaled reference fire target remains tappable at "+str(dimensions))
		up(15)
	touch.reset();touch.queue_free()
	await process_frame
	print("TOUCH_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
