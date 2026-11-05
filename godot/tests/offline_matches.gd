extends SceneTree

var checks = 0
var failures = []

func check(value, label):
	checks += 1
	if not value: failures.append(label);push_error(label)

func _initialize(): call_deferred("run")

func run():
	var game = Node3D.new();game.set_script(load("res://scripts/game.gd"));game.test_mode = true
	root.add_child(game)
	await process_frame
	game.set_process(false);game.player.set_physics_process(false)
	var offline_book = load("res://scripts/content_book.gd").new(false, "user://unused-offline-qa.json", true)
	var available = offline_book.weapons.filter(func(item):return item.get("available") == true and item.get("engineImported") == true)
	check(offline_book.owned.size() == available.size() and available.size() > 800, "Offline collection exposes actual imported weapons without a server")
	check(offline_book.equip(available[-1].id), "Offline weapons can be equipped locally")
	var maps = game.map_catalog.offline_maps()
	check(maps.size() == 19, "All 19 geometries have independent offline navigation")
	check(game.map_catalog.preview_record(1, 46).is_empty(), "Offline map 46 does not invent its original mode pairing")
	var summaries = []
	for entry in maps:
		game.local_room = {"mode": 0, "map": int(entry.number)}
		check(game.start_round(), "Starts offline map " + str(entry.number))
		await physics_frame;await physics_frame;await process_frame
		check(game.running and not game.exploring and not game.arena_root.visible, "Real map replaces synthetic arena")
		check(game.navigation_region.navigation_mesh.get_polygon_count() > 0, "Navigation installed")
		var points = game.offline_spawn_points()
		if points.is_empty():
			print("OFFLINE_SPAWN_DIAGNOSTIC ", entry.number, " player=",game.player.position," closest=",NavigationServer3D.map_get_closest_point(game.offline_navigation_map,game.player.position)," regions=",NavigationServer3D.map_get_regions(game.offline_navigation_map).size())
		check(not points.is_empty(), "Reachable clear bot spawns: " + str(entry.number))
		if points.is_empty(): continue
		check(game.spawn_enemy(), "Bot instantiates")
		var enemy = game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())[0]
		check(is_instance_valid(enemy.navigator), "Bot navigation agent installed")
		var before = enemy.position
		for i in range(50): await physics_frame
		var travelled = enemy.position.distance_to(before)
		check(travelled > 0.25, "Bot follows path: " + str(entry.number))
		game.menu_open = true
		before = enemy.position
		for i in range(5): await physics_frame
		check(enemy.position.is_equal_approx(before), "Menu pauses bot movement")
		game.menu_open = false
		summaries.append({"number": int(entry.number), "safeBotSpawns": points.size(), "botTravelMetres": travelled})
		game.kills = 9;enemy.damage(1000)
		check(game.kills == 10 and not game.running and game.last_result.title == "Arena tamamlandı", "Victory ends local match")
		check(game.start_round() and game.kills == 0 and game.health == 100, "Retry resets score and health")
		await physics_frame;await physics_frame
		game.take_damage(100)
		check(not game.running and game.last_result.title == "Yenildin", "Death ends local match")
		await process_frame
	game.local_room = {"mode": 0, "map": 9999}
	check(not game.start_round() and not game.running, "Unknown map cannot silently start arena")
	game.local_room = {"mode": 1, "map": 1}
	check(not game.start_round() and not game.running, "Original modes cannot silently substitute offline rules")
	game.local_room = {};game.start_round()
	check(game.offline_map_number == 0 and game.arena_root.visible and not is_instance_valid(game.navigation_region), "Return to arena clears navigation")
	game.spawn_clock = 1000;game.time_left = 1;game._process(2)
	check(not game.running and game.last_result.title == "Süre doldu", "Timer ends the round")
	game.running = false
	root.remove_child(game);game.queue_free();await process_frame;await process_frame
	var file = FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/offline-match-validation.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"passed":failures.is_empty(), "checks":checks, "maps":summaries,
			"scope":"Headless physics/navigation/local match regression. Original mode rules and Android device QA not certified.",
			"navigationCatalogSha256":FileAccess.get_sha256("res://assets/maps/offline.json"),
			"physicalAndroidDeviceTested":false},"  ")+"\n");file.close()
	print("OFFLINE_MATCH_QA ", checks, " checks; failures=", failures)
	quit(0 if failures.is_empty() else 1)
