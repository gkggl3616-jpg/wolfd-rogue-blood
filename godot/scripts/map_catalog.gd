extends RefCounted

# Source membership and engine readiness are separate requirements.
var data = {}
var valid = false

func _init(source = {}):
	data = source
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/catalog.json"))
	valid = data is Dictionary and data.get("schemaVersion") == 1 and data.get("maps") is Array and data.get("modes") is Array
	if not valid:
		data = {"maps":[], "modes":[]}
	# JSON stores numbers as floats; Array membership requires the same type.
	for mode in data.modes:
		mode.id = int(mode.id)
		mode.mapNumbers = mode.mapNumbers.map(func(number): return int(number))
	for entry in data.maps:
		entry.number = int(entry.number)
		entry.allowedModeIds = entry.allowedModeIds.map(func(number): return int(number))

func mode_record(mode_id):
	for mode in data.modes:
		if int(mode.id) == mode_id:
			return mode
	return {}

func map_record(map_number):
	for entry in data.maps:
		if int(entry.number) == map_number:
			return entry
	return {}

func belongs_to_mode(mode_id, map_number):
	var mode = mode_record(mode_id)
	var entry = map_record(map_number)
	# Require both sides of the allowlist; never infer membership from a name.
	return not mode.is_empty() and not entry.is_empty() and map_number in mode.mapNumbers and mode_id in entry.allowedModeIds

func maps_for_mode(mode_id, ready_only = false):
	var result = []
	for entry in data.maps:
		if belongs_to_mode(mode_id, int(entry.number)) and (not ready_only or unavailable_reason(mode_id, int(entry.number)) == ""):
			result.append(entry)
	return result

func unavailable_reason(mode_id, map_number):
	if not belongs_to_mode(mode_id, map_number):
		return "Bu harita seçilen moda bağlı değil."
	var entry = map_record(map_number)
	if entry.get("status") != "ready" or entry.get("enabled") != true:
		return "Mod eşleşmesi doğrulandı. Özgün harita sahnesinin aktarımı bekleniyor."
	if mode_record(mode_id).get("implementationStatus") != "implemented":
		return "Bu modun oyun kuralları henüz tamamlanmadı."
	var asset = entry.get("asset")
	if not asset is String or not asset.begins_with("res://assets/maps/") or not asset.get_extension() in ["tscn","scn"] or not ResourceLoader.exists(asset, "PackedScene"):
		return "Harita sahnesi bulunamadı."
	return ""

func random_ready_map(mode_id):
	var available = maps_for_mode(mode_id, true)
	return available.pick_random() if not available.is_empty() else {}
