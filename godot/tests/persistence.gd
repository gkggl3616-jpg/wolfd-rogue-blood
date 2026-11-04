extends SceneTree

const Store = preload("res://scripts/atomic_store.gd")
const Book = preload("res://scripts/content_book.gd")
const Equipment = preload("res://scripts/equipment.gd")
var checks = 0
var failures = 0
var directory = "user://persistence-qa-" + str(Time.get_ticks_usec())

func ensure(value, description):
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL " + description)
	else:
		print("PASS " + description)

func _initialize():
	DirAccess.make_dir_recursive_absolute(directory)
	call_deferred("run")

func run():
	var path = directory + "/collection.json"
	var book = Book.new(true, path)
	ensure(book.set_setting("sensitivity", 1.7), "settings write succeeds")
	ensure(book.set_setting("music_volume", 0.2) and book.set_setting("weapons_volume", 0.6), "independent volume settings save")
	var reopened = Book.new(true, path)
	ensure(is_equal_approx(reopened.settings.music_volume, 0.2) and is_equal_approx(reopened.settings.weapons_volume, 0.6), "independent volume settings survive reopening")
	ensure(is_equal_approx(reopened.settings.sensitivity, 1.7), "existing settings survive reopening")
	ensure(not book.set_setting("fps", 45) and not book.set_setting("ui_volume", "1") and not book.set_setting("effects_volume", NAN), "invalid settings cannot be persisted")
	ensure(Store.write_json(path, {"schemaVersion": 2, "settings": {"volume": 0.35, "directions": false}}), "legacy collection fixture written")
	var migrated = Book.new(true, path)
	ensure(is_equal_approx(migrated.settings.volume, 0.35) and not migrated.settings.directions and migrated.settings.music_volume == 1, "old master volume and controls retained with neutral channel defaults")
	ensure(migrated.loadouts.size() == 5, "five equipment sets survive initialization")
	var original_bytes = FileAccess.get_file_as_bytes(path)
	DirAccess.make_dir_absolute(path + ".pending")
	ensure(not migrated.set_setting("music_volume", 0.1) and migrated.settings.music_volume == 1, "failed setting save rolls back memory")
	ensure(not migrated.select_loadout(3) and migrated.active_loadout == 0, "failed loadout save rolls back active set")
	var old_owned = migrated.owned.duplicate(true)
	ensure(not migrated.acquire_all() and migrated.owned == old_owned, "failed acquire-all rolls back ownership")
	var candidate = migrated.characters.filter(func(row): return row.get("available") == true)[0]
	ensure(not migrated.choose_character(candidate.id) and migrated.selected_character == "", "failed character selection rolls back")
	var tattoo = migrated.tattoos.filter(func(row): return row.get("role") == "body")[0]
	ensure(not migrated.set_tattoo("body", tattoo.texture) and migrated.selected_tattoos.is_empty(), "failed tattoo save rolls back")
	ensure(not migrated.set_tattoo("left", tattoo.texture), "body tattoo cannot be assigned to arm UV")
	var unknown = migrated.tattoos.filter(func(row): return row.get("role") == "unknown")[0]
	ensure(not migrated.set_tattoo("body", unknown.texture), "unresolved tattoo role cannot be guessed")
	ensure(FileAccess.get_file_as_bytes(path) == original_bytes, "write failure leaves previous collection byte-for-byte intact")
	DirAccess.remove_absolute(path + ".pending")
	var equipment_path = directory + "/equipment.json"
	var power = Equipment.new(true, equipment_path)
	ensure(power.equip_power(19601) and Equipment.new(true, equipment_path).has_wolf_ability(), "power slot survives reopening")
	var power_bytes = FileAccess.get_file_as_bytes(equipment_path)
	DirAccess.make_dir_absolute(equipment_path + ".pending")
	ensure(not power.equip_power(0) and power.has_wolf_ability(), "failed power-slot save does not unequip item")
	ensure(FileAccess.get_file_as_bytes(equipment_path) == power_bytes, "power-slot failure preserves previous file")
	DirAccess.remove_absolute(equipment_path + ".pending")
	var corrupt_path = directory + "/corrupt.json"
	var file = FileAccess.open(corrupt_path, FileAccess.WRITE)
	file.store_string("{broken");file.close()
	ensure(not Book.new(true, corrupt_path).set_setting("volume", 0.1) and FileAccess.get_file_as_string(corrupt_path) == "{broken", "malformed existing save is not overwritten with defaults")
	Store.write_json(corrupt_path, {"schemaVersion": 99})
	ensure(not Book.new(true, corrupt_path).acquire_all(), "newer unknown save schema remains untouched")
	var game = load("res://scripts/game.gd").new()
	game.message = Label.new()
	game.wallet_storage_path = directory + "/wallet.json"
	ensure(game.grant_money("gold", 10, "test") and Store.read_json(game.wallet_storage_path).data.gold == 10, "wallet grants become visible only after durable save")
	DirAccess.make_dir_absolute(game.wallet_storage_path + ".pending")
	ensure(not game.grant_money("gold", 25, "test") and game.wallet.gold == 10, "failed wallet grant leaves balance unchanged")
	ensure(Store.read_json(game.wallet_storage_path).data.gold == 10, "failed wallet grant preserves previous disk balance")
	DirAccess.remove_absolute(game.wallet_storage_path + ".pending")
	game.message.free();game.free()
	for name in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory + "/" + name)
	DirAccess.remove_absolute(directory)
	print("PERSISTENCE_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
