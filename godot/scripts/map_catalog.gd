extends RefCounted


var data = {}
var valid = false
var previews = []
var offline = []
var photos={}

func _init(source = {}):
	if FileAccess.file_exists("res://assets/maps/photos.json"):
		for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/photos.json")).maps:photos[int(row.number)]=row
	data = source
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/catalog.json"))
	valid = data is Dictionary and data.get("schemaVersion") == 1 and data.get("maps") is Array and data.get("modes") is Array
	if not valid:
		data = {"maps": [], "modes": []}

	var names=JSON.parse_string(FileAccess.get_file_as_string("res://assets/presentation/catalog.json")).get("modes",{})
	for mode in data.modes:
		mode["displayName"]=names.get(str(int(mode.id)),{}).get("name","Oyun Modu")
		mode.id = int(mode.id)
		mode.mapNumbers = mode.mapNumbers.map( func(number): return int(number))
	for entry in data.maps:
		entry.number = int(entry.number)
		entry.allowedModeIds = entry.allowedModeIds.map( func(number): return int(number))
	if FileAccess.file_exists("res://assets/maps/previews.json"):
		var source_previews = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"))
		if source_previews is Array:
			previews = source_previews
	if FileAccess.file_exists("res://assets/maps/offline.json"):
		var source_offline = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/offline.json"))
		if source_offline is Array: offline = source_offline

# A separate, local ruleset. This does not assert any original mode pairing.
func photo(number):return photos.get(int(number),{})

func offline_record(map_number):
	for record in previews:
		if int(record.number) != map_number or record.get("previewValidated") != true: continue
		if record.get("startPoints", []).is_empty(): return {}
		for nav in offline:
			if int(nav.number) == map_number and nav.geometrySha256 == record.sha256 and ResourceLoader.exists(nav.navigation, "NavigationMesh"):
				var result = record.duplicate(true)
				result.merge(nav, true)
				return result
	return {}

func offline_maps():
	var result = []
	for entry in data.maps:
		if not offline_record(int(entry.number)).is_empty(): result.append(entry)
	return result

func preview_record(mode_id, map_number):
	if not belongs_to_mode(mode_id, map_number):
		return {}
	for record in previews:
		if int(record.number) == map_number and record.get("previewValidated") == true and record.get("startPoints", []).size() > 0:
			var asset = record.get("previewAsset", "")
			if asset.begins_with("res://assets/maps/geometry/") and ResourceLoader.exists(asset, "PackedScene"):
				return record
	return {}

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

	return not mode.is_empty() and not entry.is_empty() and map_number in mode.mapNumbers and mode_id in entry.allowedModeIds

func maps_for_mode(mode_id, ready_only = false):
	var result = []
	for entry in data.maps:
		if belongs_to_mode(mode_id, int(entry.number)) and ( not ready_only or unavailable_reason(mode_id, int(entry.number)) == ""):
			result.append(entry)
	return result

func unavailable_reason(mode_id, map_number):
	if not belongs_to_mode(mode_id, map_number):
		return "Bu harita seçilen moda bağlı değil."
	if preload("res://scripts/source_match_rules.gd").supports(mode_id):
		return "" if not offline_record(map_number).is_empty() else "Kaynak haritanın çevrimdışı hazırlığı eksik."
	var entry = map_record(map_number)
	if entry.get("status") != "ready" or entry.get("enabled") != true:
		return "Mod eşleşmesi doğrulandı. Özgün harita sahnesinin aktarımı bekleniyor."
	if mode_record(mode_id).get("implementationStatus") != "implemented":
		return "Bu modun oyun kuralları henüz tamamlanmadı."
	var asset = entry.get("asset")
	if not asset is String or not asset.begins_with("res://assets/maps/") or not asset.get_extension() in ["tscn", "scn"] or not ResourceLoader.exists(asset, "PackedScene"):
		return "Harita sahnesi bulunamadı."
	return ""

func random_ready_map(mode_id):
	var available = maps_for_mode(mode_id, true)
	return available.pick_random() if not available.is_empty() else {}

func mode_name(mode_id):return mode_record(mode_id).get("displayName","Oyun Modu")
