extends SceneTree
var checks = 0
var failures = 0
var game
func _initialize(): call_deferred("run")
func ensure(value, description):
	checks += 1
	if not value: failures += 1;push_error("FAIL " + description)
	else: print("PASS " + description)
func frames(count):
	for _i in range(count): await process_frame

func contact():
	Input.action_release("forward")
	await frames(2)
	if game.player.wall_hold_cooldown > 0:
		await frames(int(ceil(game.player.wall_hold_cooldown * 60)) + 3)
	game.player.reset_locomotion()
	game.player.position = Vector3(0, 1.4, -6.35)
	game.player.velocity = Vector3(0, 0, -9)
	game.player.yaw = 0;game.player.rotation.y = 0
	Input.action_press("forward")
	game.player.action_time = 0;game.player.shot_cooldown = 0
	await frames(2)
	Input.action_release("forward")
	await frames(2)
	Input.action_press("forward")
	await frames(4)

func run():
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate();game.test_mode = true;root.add_child(game)
	await frames(3)
	game.start_round();game.spawn_clock = 1000
	await frames(25)
	game.player.switch_form();await frames(22)
	var wall = game.block(Vector3(0, 2, -7), Vector3(4,6,0.4), "576371")
	await frames(2)
	game.equipment.equip_power(19601)
	await contact()
	ensure(game.player.is_on_wall() and not game.player.is_on_floor(), "wolf makes real airborne contact with vertical wall")
	game.equipment.equip_power(0)
	ensure(not game.player.begin_wall_hold(), "unequipped special item cannot start wall hold")
	game.equipment.equip_power(19601);game.player.wolf_running = false
	ensure(not game.player.begin_wall_hold(), "walking into a wall cannot replace the required wolf run")
	game.player.wolf_running = true
	game.attack()
	ensure(game.player.wall_holding and game.player.current_clip == "wall_hold", "running attack at wall starts source wall-hold clip")
	var at = game.player.position
	await frames(20)
	ensure(game.player.wall_holding and absf(game.player.position.y - at.y) < 0.05, "wall hold maintains contact without falling or teleporting")
	var health = game.health;game.take_damage(5)
	ensure(game.health == health-5, "wall holding grants no damage immunity")
	Input.action_release("forward");await frames(2)
	ensure(not game.player.wall_holding, "releasing forward detaches from wall")
	game.player.wolf_running = true
	ensure(not game.player.begin_wall_hold(), "wall cooldown prevents immediate reattachment")
	await contact();ensure(game.player.begin_wall_hold(), "wall hold can restart after actual cooldown and another double tap")
	Input.action_press("jump");await frames(2);Input.action_release("jump")
	ensure(not game.player.wall_holding and game.player.velocity.y > 0 and game.player.velocity.z > 0, "jump leaves wall with outward impulse and real collision")
	await contact();game.player.begin_wall_hold();game.show_inventory()
	ensure(not game.player.wall_holding, "opening menu cleans up wall-hold state")
	game.resume();await contact();game.player.begin_wall_hold();game.player.switch_form()
	ensure(not game.player.wall_holding and not game.player.is_wolf, "form change clears wall attachment")
	game.player.switch_form();await frames(22)
	await contact();game.player.begin_wall_hold();await frames(135)
	ensure(not game.player.wall_holding, "mobile hold duration is bounded")
	var unsupported = game.book.characters.filter(func(row): return row.get("available") == true and row.get("sourceTeam")==game.local_room.get("team","blue") and not "wall_hold" in row.wolf.clips)
	ensure(not unsupported.is_empty(), "catalog retains characters without a wall-hold clip as unsupported for this move")
	if not unsupported.is_empty():
		game.select_library_character(unsupported[0]);await contact()
		ensure(not game.player.begin_wall_hold(), "missing source animation is never replaced with arbitrary clip")
	Input.action_release("forward");Input.action_release("jump")
	game.queue_free();await frames(3)
	print("WALL_HOLD_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
