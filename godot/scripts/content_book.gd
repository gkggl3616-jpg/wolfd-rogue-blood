extends RefCounted

const AtomicStore = preload("res://scripts/atomic_store.gd")

var weapons = []
var characters = []
var tattoos = []
var effects = []
var stat_labels={}
var models = {}
var owned = {}
var default_owned = {}
var inventory_revision = 3
var slots = {}
var loadouts = []
var active_loadout = 0
var loadout_names=["Standart","SLH 1","SLH 2","SLH 3","SLH 4"]
var wolf_mutation="normal"
var selected_character = ""
var selected_tattoos = {}
var selected_tattoo_ids={}
var selected_characters={}
const DEFAULT_SETTINGS = {"sensitivity": 1.0, "volume": 0.8, "music_volume": 1.0, "effects_volume": 1.0, "weapons_volume": 1.0, "ui_volume": 1.0, "directions": true, "invert_y": false, "shadows": false, "fps": 60}
var settings = DEFAULT_SETTINGS.duplicate(true)
var control_layout={}
var local_name = "Yerel oyuncu"
var persistent = true
var storage_path = "user://collection.json"
var save_blocked = false
var offline_edition = false

func _init(save_enabled = true, save_path = "user://collection.json", offline_mode = false):
	persistent = save_enabled
	offline_edition = offline_mode
	storage_path = save_path
	var data = read_json("res://assets/library/weapons.json")
	weapons = data.get("items", [])
	models = data.get("models", {})
	var source_text=read_json("res://assets/ui/weapon-text.json").get("items",{})
	for item in weapons:
		if source_text.has(item.id):item["description"]=source_text[item.id].description;item["sourceDetails"]=source_text[item.id]
	characters = read_json("res://assets/library/characters.json").get("characters", [])
	var visuals = read_json("res://assets/library/visuals.json")
	tattoos = visuals.get("tattoos", [])
	effects = visuals.get("effects", [])
	var presentation=read_json("res://assets/presentation/catalog.json");var labels=presentation.get("items",{});stat_labels=presentation.get("statLabels",{})
	for item in characters+tattoos:
		if labels.has(item.id):item["sourceName"]=item.name;item.name=labels[item.id].name
		if presentation.get("characterStats",{}).has(item.id):item["sourceStats"]=presentation.characterStats[item.id]

	if persistent and FileAccess.file_exists(storage_path):
		var result = AtomicStore.read_json(storage_path)
		var stored = result.data
		var version = stored.get("schemaVersion", 1)
		save_blocked = not result.ok or not (version is int or version is float) or (version != 1 and version != 2 and version != 3)
		if save_blocked:
			stored = {}
		var saved_name = stored.get("localName", "Yerel oyuncu")
		if valid_local_name(saved_name): local_name = saved_name.strip_edges()
		var saved_owned = stored.get("owned", {})
		if saved_owned is Dictionary:
			for item in weapons+characters+tattoos:
				if saved_owned.get(item.id) == true and (not offline_edition or version>=3): owned[item.id] = true
		var saved_slots = stored.get("slots", {})
		if saved_slots is Dictionary: slots = saved_slots
		var presets = stored.get("loadouts", [])
		if presets is Array:
			for preset in presets.slice(0, 5):
				loadouts.append(preset if preset is Dictionary else {})
		var active = stored.get("activeLoadout", 0)
		if active is int or active is float: active_loadout = clampi(int(active), 0, 4)
		if stored.get("wolfMutation","") in ["normal","power","guardian","ghost"]:wolf_mutation=stored.wolfMutation
		var character = stored.get("character", "")
		if character is String and characters.any( func(row): return row.id == character and row.get("available") == true): selected_character = character
		var saved_tattoos = stored.get("tattoos", {})
		if saved_tattoos is Dictionary:
			for role in ["body", "left", "right"]:
				var texture = saved_tattoos.get(role, "")
				if texture is String and tattoo_matches_role(role,texture): selected_tattoos[role] = texture
		var saved_ids=stored.get("tattooIds",{})
		if saved_ids is Dictionary:
			for role in ["left","body","right"]:
				var id=saved_ids.get(role,"")
				if tattoos.any(func(row):return row.id==id and row.role==role and row.texture==selected_tattoos.get(role,"")):selected_tattoo_ids[role]=id
		var team_choices=stored.get("teamCharacters",{})
		if team_choices is Dictionary:
			for team in ["red","blue"]:
				if characters.any(func(row):return row.id==team_choices.get(team,"") and row.get("sourceTeam",team)==team and row.get("available",false)):selected_characters[team]=team_choices[team]
		var layout=stored.get("controlLayout",{})
		if preload("res://scripts/control_layout.gd").valid(layout):control_layout=layout.duplicate(true)
		var saved_settings = stored.get("settings", {}).duplicate() if stored.get("settings",{}) is Dictionary else {}
		if version<3 and offline_edition:saved_settings["directions"]=true
		if saved_settings is Dictionary:
			for key in settings:
				var setting = validated_setting(key, saved_settings.get(key, settings[key]))
				if setting != null: settings[key] = setting
	var defaults = {}
	# Source assets are the shop catalogue, never an ownership grant.
	for kind in ["rifle", "pistol", "knife", "grenade"]:
		for item in weapons:
			if item.category == kind and item.get("engineImported") == true:
				owned[item.id] = true;default_owned[item.id]=true;defaults[slot_for(kind)] = item.id;break
	for team in ["red","blue"]:
		for entry in characters:
			if entry.get("available",false) and entry.get("sourceTeam","")==team:
				owned[entry.id]=true;default_owned[entry.id]=true;break
	for role in ["left","body","right"]:
		for entry in tattoos:
			if entry.role==role:
				owned[entry.id]=true;default_owned[entry.id]=true;break
	if loadouts.is_empty(): loadouts.append(slots.duplicate())
	while loadouts.size() < 5: loadouts.append(defaults.duplicate())
	for preset in loadouts:
		for slot in defaults:
			var entry = weapon(preset.get(slot, ""))
			if entry.is_empty() or entry.get("engineImported") != true or not owned.get(entry.id, false) or slot_for(entry.category) != slot: preset[slot] = defaults[slot]
	for preset in loadouts:
		var extra=weapon(preset.get("secondary_primary",""))
		if extra.is_empty() or extra.get("available")!=true or not owned.get(extra.id,false) or slot_for(extra.category)!="primary":preset.erase("secondary_primary")
	slots = loadouts[active_loadout]

func read_json(path):
	if not FileAccess.file_exists(path): return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func slot_for(kind):
	return kind if kind in ["pistol", "knife", "grenade"] else "primary"

func weapon(id):
	if not id is String: return {}
	for item in weapons:
		if item.id == id: return item
	return {}

func acquire(id):
	var item = weapon(id)
	if item.is_empty() or item.get("engineImported") != true: return false
	var previous = owned.get(id, false);owned[id] = true
	if save(): return true
	if previous: owned[id] = true
	else: owned.erase(id)
	return false

func acquire_all():
	var previous = owned.duplicate()
	for item in weapons+characters+tattoos:
		if item.get("engineImported",true) == true: owned[item.id] = true
	if save(): return true
	owned.clear();owned.merge(previous);return false

func equip(id,target_slot=""):
	var item = weapon(id)
	if item.is_empty() or not owned.get(id, false) or item.get("engineImported") != true: return false
	var natural_slot=slot_for(item.category)
	var slot=target_slot if target_slot!="" else natural_slot
	if slot!=natural_slot and not (natural_slot=="primary" and slot=="secondary_primary"):return false
	var previous=slots.get(slot,null);slots[slot]=id
	if save(): return true
	if previous==null:slots.erase(slot)
	else:slots[slot]=previous
	return false

func select_loadout(index):
	if index < 0 or index >= loadouts.size(): return false
	var previous = active_loadout;active_loadout = index;slots = loadouts[index]
	if save(): return true
	active_loadout = previous;slots = loadouts[previous];return false

func select_mutation(value):
	if value not in ["normal","power","guardian","ghost"]:return false
	var previous=wolf_mutation;wolf_mutation=value
	if save():return true
	wolf_mutation=previous;return false

func validated_setting(key, value):
	if key in ["directions", "shadows", "invert_y"]: return value if value is bool else null
	if not (value is int or value is float) or not is_finite(float(value)): return null
	if key == "fps": return int(value) if value == 30 or value == 60 else null
	if key == "sensitivity": return clampf(float(value), 0.2, 3.0)
	if key in ["volume", "music_volume", "effects_volume", "weapons_volume", "ui_volume"]: return clampf(float(value), 0, 1)
	return null

func set_setting(key, value):
	var clean = validated_setting(key, value)
	if not settings.has(key) or clean == null: return false
	var previous = settings[key];settings[key] = clean
	if save(): return true
	settings[key] = previous;return false

func set_control_layout(candidate):
	if not preload("res://scripts/control_layout.gd").valid(candidate):return false
	var previous=control_layout;control_layout=candidate.duplicate(true)
	if save():return true
	control_layout=previous;return false

func default_settings():
	return DEFAULT_SETTINGS.duplicate(true)

func update_settings(candidate):
	if not candidate is Dictionary or candidate.size() != settings.size(): return false
	var clean = {}
	for key in settings:
		var value = validated_setting(key,candidate.get(key))
		if value == null: return false
		clean[key] = value
	var previous = settings
	settings = clean
	if save(): return true
	settings = previous
	return false

func valid_local_name(value):
	if not value is String: return false
	var name = value.strip_edges()
	if name.length() < 2 or name.length() > 24: return false
	for i in range(name.length()):
		if name.unicode_at(i) < 32 or name.unicode_at(i) == 127: return false
	return true

func set_local_name(value):
	if not valid_local_name(value): return false
	var previous = local_name;local_name = value.strip_edges()
	if save(): return true
	local_name = previous
	return false

func choose_character(id):
	if not characters.any( func(row): return row.id == id and row.get("available") == true): return false
	if offline_edition and not owns(id):return false
	var entry=characters.filter(func(row):return row.id==id)[0]
	var previous_choices=selected_characters.duplicate();selected_characters[entry.get("sourceTeam","blue")]=id
	var previous = selected_character;selected_character = id
	if save(): return true
	selected_character = previous;selected_characters=previous_choices;return false

func set_tattoo(role, texture, item_id=""):
	if role not in ["body", "left", "right"]: return false
	if texture != "" and not tattoo_matches_role(role, texture): return false
	var previous = selected_tattoos.duplicate();var previous_ids=selected_tattoo_ids.duplicate()
	if texture == "": selected_tattoos.erase(role);selected_tattoo_ids.erase(role)
	else:
		var choices=tattoos.filter(func(row):return row.texture==texture and row.role==role and (item_id=="" or row.id==item_id))
		if item_id!="" and choices.size()!=1:return false
		if offline_edition and (choices.is_empty() or not owns(choices[0].id)):return false
		selected_tattoos[role] = texture
		if choices.size()==1:selected_tattoo_ids[role]=choices[0].id
		else:selected_tattoo_ids.erase(role)
	if save(): return true
	selected_tattoos.clear();selected_tattoos.merge(previous);selected_tattoo_ids=previous_ids;return false

func tattoo_matches_role(role, texture):
	return tattoos.any(func(row): return row.texture == texture and row.get("role", "unknown") == role)

func tattoo_render_priority(texture):
	for row in tattoos:
		if row.texture==texture:return int(row.get("renderPriority",0))
	return 0

func tattoo_uv_transpose(role,texture):
	return tattoos.any(func(row):return row.role==role and row.texture==texture and row.get("uvTranspose",false))

func save():
	if not persistent: return true
	if save_blocked: return false
	return AtomicStore.write_json(storage_path, {"schemaVersion": 3, "owned": owned, "slots": slots, "loadouts": loadouts, "activeLoadout": active_loadout, "character": selected_character, "tattooIds":selected_tattoo_ids,"teamCharacters":selected_characters,"tattoos": selected_tattoos, "settings": settings, "localName": local_name,"wolfMutation":wolf_mutation,"controlLayout":control_layout})

func character_for_team(team):
	var chosen=selected_characters.get(team,selected_character)
	for row in characters:
		if row.id==chosen and row.get("available",false) and row.get("sourceTeam",team)==team:return row
	for row in characters:
		if row.get("available",false) and row.get("sourceTeam",team)==team:return row
	return {}
func tattoo_bonuses():
	var totals={"rangePercent":0,"damagePercent":0,"healthPercent":0,"speedPercent":0,"gpPercent":0,"goldPercent":0,"transformPercent":0,"armorPercent":0}
	for role in selected_tattoo_ids:
		for row in tattoos:
			if row.id==selected_tattoo_ids[role] and row.role==role and row.texture==selected_tattoos.get(role,""):
				for key in totals:totals[key]+=float(row.get("appliedBonuses",{}).get(key,0))
	return totals

# The wallet ledger is authoritative for confirmed purchases. Old offline
# all-unlocked collections migrate to defaults plus their accepted gifts.
func owns(id):return owned.get(str(id),false)
func apply_entitlements(entitlements):
	if not offline_edition:return
	owned=default_owned.duplicate()
	for id in entitlements:
		if entitlements[id]==true:owned[str(id)]=true
	for preset in loadouts:
		for slot in preset.keys():
			if not owns(preset[slot]):
				var defaults=weapons.filter(func(row):return default_owned.has(row.id) and slot_for(row.category)==slot)
				if defaults.is_empty():preset.erase(slot)
				else:preset[slot]=defaults[0].id
	for team in selected_characters.keys():
		if not owns(selected_characters[team]):selected_characters.erase(team)
	if not owns(selected_character):selected_character=""
	for role in selected_tattoo_ids.keys():
		if not owns(selected_tattoo_ids[role]):selected_tattoo_ids.erase(role);selected_tattoos.erase(role)
