extends RefCounted

const AtomicStore = preload("res://scripts/atomic_store.gd")

const WOLF_ABILITY = 19601
var owned = [WOLF_ABILITY]
var power_slot = 0
var persistent = true
var rules = {}
var storage_path = "user://equipment.json"
var save_blocked = false

func _init(save_enabled = true, save_path = "user://equipment.json"):
	persistent = save_enabled
	storage_path = save_path
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/rules.json"))
	if persistent and FileAccess.file_exists(storage_path):
		var result = AtomicStore.read_json(storage_path)
		var saved = result.data
		save_blocked = not result.ok or saved.get("schemaVersion") != 1
		if saved is Dictionary and saved.get("schemaVersion") == 1:
			var value = saved.get("powerSlot", 0)
			if (value is int or value is float) and value == WOLF_ABILITY and WOLF_ABILITY in owned:
				power_slot = WOLF_ABILITY

func has_wolf_ability():
	return power_slot == WOLF_ABILITY and WOLF_ABILITY in owned

func equip_power(item_id):
	if item_id != 0 and (item_id != WOLF_ABILITY or item_id not in owned):
		return false
	if persistent:
		if save_blocked or not AtomicStore.write_json(storage_path, {"schemaVersion": 1, "powerSlot": item_id}):
			return false
	power_slot = item_id
	return true
