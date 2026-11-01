extends SceneTree

func _initialize():
	call_deferred("run")

func ensure(condition, text):
	if not condition:
		push_error("SMOKE FAILED: "+text)
		quit(1)
		return false
	print("PASS "+text)
	return true

func frames(count):
	for _i in range(count):
		await process_frame

func run():
	root.size = Vector2i(1280,720)
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await frames(3)
	if not ensure(game.player.anim != null,"animated character imported"):return
	for clip in ["idle","run","jump","attack","reload","crouch","crouch_run"]:
		if not ensure(game.player.anim.has_animation(clip),"human clip "+clip):return
	game.start_round()
	await frames(25)
	if not ensure(game.running and not game.menu_open,"round starts"):return
	if not ensure(game.player.is_on_floor(),"player collision rests on arena floor"):return
	var old_z = game.player.position.z
	Input.action_press("forward")
	await frames(40)
	Input.action_release("forward")
	if not ensure(game.player.position.z < old_z - 0.5,"movement advances player"):return
	Input.action_press("jump")
	await frames(6)
	Input.action_release("jump")
	if not ensure(game.player.position.y > 0.1,"jump has physical height"):return
	await frames(70)
	var down = InputEventScreenTouch.new()
	down.index = 1
	down.pressed = true
	down.position = game.touch.center
	Input.parse_input_event(down)
	var drag = InputEventScreenDrag.new()
	drag.index = 1
	drag.position = game.touch.center + Vector2(0,-60)
	drag.relative = Vector2(0,-60)
	Input.parse_input_event(drag)
	await frames(2)
	if not ensure(game.player.move_axis.y < -0.8,"touch joystick controls movement"):return
	var look = InputEventScreenTouch.new()
	look.index = 2
	look.pressed = true
	look.position = Vector2(700,300)
	Input.parse_input_event(look)
	var old_yaw = game.player.yaw
	var look_drag = InputEventScreenDrag.new()
	look_drag.index = 2
	look_drag.position = Vector2(725,310)
	look_drag.relative = Vector2(25,10)
	Input.parse_input_event(look_drag)
	await frames(2)
	if not ensure(game.player.yaw != old_yaw and game.player.move_axis.y < -0.8,"second finger looks while first finger moves"):return
	var fire = InputEventScreenTouch.new()
	fire.index = 3
	fire.pressed = true
	fire.position = game.touch.buttons[0].position
	game.player.shot_cooldown = 0
	var before_touch_ammo = game.ammo
	Input.parse_input_event(fire)
	await frames(3)
	if not ensure(game.ammo < before_touch_ammo and game.player.move_axis.y < -0.8,"third finger fires while movement remains held"):return
	for event in [fire,look,down]:
		event.pressed = false
		Input.parse_input_event(event)
	await frames(3)
	if not ensure(game.player.move_axis == Vector2.ZERO and not Input.is_action_pressed("fire"),"releasing touch fingers clears movement and fire"):return
	game.ammo = 30
	Input.action_press("crouch")
	await frames(5)
	if not ensure(game.player.crouching and game.player.capsule.height < 1.3,"crouch reduces the physical collision height"):return
	Input.action_release("crouch")
	await frames(5)
	if not ensure(not game.player.crouching and game.player.capsule.height > 1.7,"standing restores collision height when there is clearance"):return
	game.player.switch_form()
	if not ensure(game.player.is_wolf and game.player.wolf.visible and not game.player.human.visible,"human transforms to wolf"):return
	for clip in ["idle","run","jump","attack","roar","crouch","crouch_run"]:
		if not ensure(game.player.anim.has_animation(clip),"wolf clip "+clip):return
	game.player.switch_form()
	game.player.shot_cooldown = 0
	game.attack()
	if not ensure(game.ammo == 29,"firing consumes ammunition"):return
	game.reload_weapon()
	await frames(110)
	if not ensure(game.ammo == 30 and game.reserve == 119,"reload transfers reserve ammunition"):return
	for enemy in game.enemies.get_children():
		enemy.queue_free()
	await frames(2)
	game.spawn_clock = 100
	game.spawn_enemy()
	var enemy = game.enemies.get_child(0)
	enemy.position = game.player.position - game.player.global_basis.z * 1.7
	enemy.set_physics_process(false)
	await frames(3)
	game.player.switch_form()
	game.player.shot_cooldown = 0
	game.attack()
	if not ensure(enemy.health == 55,"wolf claw damages a visible nearby target"):return
	var before = game.wallet.cash
	enemy.damage(100)
	if not ensure(game.kills == 1 and game.wallet.cash == before+25,"defeating a target grants the configured local reward"):return
	game.take_damage(100)
	if not ensure(not game.running and game.health == 0,"zero health ends the round"):return
	game.grant_money("gold",1000,"Smoke test")
	if not ensure(game.wallet.gold == 1000,"local administrator can grant gold"):return
	print("WOLF_ROGUE_SMOKE_OK")
	game.queue_free()
	await frames(3)
	quit(0)
