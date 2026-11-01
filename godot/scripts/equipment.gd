extends RefCounted

const WOLF_ABILITY = 19601
var owned = [WOLF_ABILITY] # Local development starter item, not a migrated account.
var power_slot = 0
var persistent = true
var rules = {}

func _init(save_enabled = true):
	persistent = save_enabled
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/rules.json"))
	if persistent and FileAccess.file_exists("user://equipment.json"):
		var saved = JSON.parse_string(FileAccess.get_file_as_string("user://equipment.json"))
		if saved is Dictionary and saved.get("schemaVersion") == 1:
			if int(saved.get("powerSlot",0)) == WOLF_ABILITY and WOLF_ABILITY in owned:
				power_slot = WOLF_ABILITY

func has_wolf_ability():
	return power_slot == WOLF_ABILITY and WOLF_ABILITY in owned

func equip_power(item_id):
	if item_id != 0 and (item_id != WOLF_ABILITY or item_id not in owned):
		return false
	power_slot = item_id
	if persistent:
		var file = FileAccess.open("user://equipment.pending",FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify({"schemaVersion":1,"powerSlot":power_slot}))
			file.close()
			DirAccess.rename_absolute("user://equipment.pending","user://equipment.json")
	return true
