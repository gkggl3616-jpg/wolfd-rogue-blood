extends Node3D

const Frontend = preload("res://ui/front_end.gd")
const GameHud = preload("res://ui/game_hud.gd")
const SourceArt = preload("res://ui/source_theme.gd")

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const TouchScript = preload("res://scripts/touch.gd")
const MapCatalogScript = preload("res://scripts/map_catalog.gd")
const EquipmentScript = preload("res://scripts/equipment.gd")
const ContentBook = preload("res://scripts/content_book.gd")
const GrenadeScript = preload("res://scripts/grenade.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const AtomicStore = preload("res://scripts/atomic_store.gd")
const MapAudio = preload("res://scripts/map_audio.gd")
const BotRules = preload("res://scripts/bot_rules.gd")
const NavigationGraph = preload("res://scripts/navigation_graph.gd")
const ProfileLock=preload("res://scripts/profile_lock.gd")
const BoxCollection=preload("res://scripts/box_collection.gd")
const LocalHunt=preload("res://scripts/local_hunt.gd")
const LocalTutorial=preload("res://scripts/local_tutorial.gd")
const RankBook=preload("res://scripts/rank_book.gd")
const LocalCareer=preload("res://scripts/local_career.gd")
const GiftInbox=preload("res://scripts/gift_inbox.gd")
const WolfMutations=preload("res://scripts/wolf_mutations.gd")
const WOLF_BATTLE=900003
var inbox=GiftInbox.new()
var mutations=WolfMutations.new()
var shop_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/shop.json"))
var power_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/power.json"))
var round_selection_enabled=false
var selection_transform=false
var selection_active=false
var selection_panel
var booster_remaining=0.0
var booster_tuning={}
var healing_uses={}
var career=LocalCareer.new()
var match_id=""
var profile_lock
var boxes=BoxCollection.new()
var hunt=LocalHunt.new()
var tutorial=LocalTutorial.new()
var ranks=RankBook.new()
var map_photo:TextureRect
var match_stats={"attacks":0,"hits":0,"damage":0,"headshots":0}
var kill_feed=[]
var match_serial=0
var book
var current_weapon_id = "legacy-ak47"
var weapon_ammo = {}
var library_panel: Control
var pc_panel: Control
var source_hud: Control
var game_audio
var clientfx
var match_rules=preload("res://scripts/source_match_rules.gd").new()
var announced_last_minute=false
var first_kill_announced=false
var equipment
var map_catalog
var mode_picker: OptionButton
var map_picker: OptionButton
var map_status: Label
var map_start: BaseButton
var map_preview: BaseButton
var arena_root: Node3D
var active_map: Node3D
var offline_map_number = 0
var navigation_region: NavigationRegion3D
var offline_navigation_map = RID()
var navigation_graph
var exploring = false
var preview_spawn = Vector3.ZERO
var preview_name = ""
var player
var running = false
var menu_open = true
var health = 100
var ammo = 30
var reserve = 120
var reloading = 0.0
var deaths=0
var respawn_remaining=0.0
var team_frags={"red":0,"blue":0}
var kills = 0
var time_left = 90.0
var spawn_clock = 0.0
var bot_difficulty = "normal"
var bot_spawn_count = 0
var enemies: Node3D
var hud_label: Label
var message: Label
var message_clock = 0.0
var overlay: PanelContainer
var overlay_box: VBoxContainer
var crosshair: Control
var touch
var wallet = {"cash": 0, "kp": 0, "gold": 0, "gp": 0}
var remote_token = ""
var remote_player = ""
var profile_name = "Yerel oyuncu"
var poll: HTTPRequest
var grant_http: HTTPRequest
var poll_clock = 0.0
var grant_queue = []
var grant_busy = false
var test_mode = false
var character_info = {}
var application_suspended = false
var tree_was_paused = false
var gui_touch_blockers = []
var wallet_storage_path = "user://wallet.json"
var wallet_save_blocked = false
var current_loadout_slot = "primary"
var local_room = {}
var last_result = {}
var menu_backdrop: ColorRect
var transient_effects: Node3D

func _ready():
	profile_lock=ProfileLock.new(not test_mode)
	book = ContentBook.new(not test_mode, "user://collection.json", OS.has_feature("offline_release"))
	profile_name = book.local_name
	game_audio = Node.new();game_audio.set_script(GameAudio);game_audio.game = self;add_child(game_audio)
	clientfx=Node.new();clientfx.set_script(preload("res://scripts/clientfx_system.gd"));clientfx.game=self;add_child(clientfx)
	equipment = EquipmentScript.new( not test_mode)
	map_catalog = MapCatalogScript.new()
	var roster = JSON.parse_string(FileAccess.get_file_as_string("res://assets/roster.json"))
	if not roster is Dictionary or not roster.get("characters") is Array or roster.characters.is_empty():
		push_error("Onaylı insan/kurt çifti bulunamadı; oyun başlatılmadı.")
		return
	character_info = roster.characters[0]
	if character_info.get("pairConfirmed") != true or character_info.get("engineImported") != true or character_info.get("visualValidation") != "passed":
		push_error("Karakter çifti doğrulanmadı; oyun başlatılmadı.")
		return
	for entry in book.characters:
		if entry.get("available", false) and (entry.id == book.selected_character or (book.selected_character == "" and entry.id == "pair-model0")): character_info = entry
	setup_inputs()
	load_wallet()
	sync_collection()
	build_world()
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.game = self
	player.position = Vector3(0, 0.05, 8)
	add_child(player)
	if book.wolf_mutation!="normal":
		var model=player.prepare_mutation(book.wolf_mutation)
		if model:player.apply_mutation(model,book.wolf_mutation)
	enemies = Node3D.new()
	add_child(enemies)
	transient_effects = Node3D.new()
	add_child(transient_effects)
	build_ui()
	equip_slot("primary")
	apply_settings()
	poll = HTTPRequest.new()
	poll.timeout = 2.0
	add_child(poll)
	poll.request_completed.connect(on_poll)
	grant_http = HTTPRequest.new()
	grant_http.timeout = 3.0
	add_child(grant_http)
	grant_http.request_completed.connect(on_grant)
	show_launcher()
	if not test_mode:seed_gifts()
	update_hud()

func setup_inputs():
	var keys = {"forward": KEY_W, "backward": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "crouch": KEY_CTRL, "sprint": KEY_SHIFT, "reload": KEY_R, "transform": KEY_3, "pause": KEY_ESCAPE, "admin": KEY_F10, "inventory": KEY_I}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	if not InputMap.has_action("roll"): InputMap.add_action("roll")
	var roll_key = InputEventKey.new();roll_key.physical_keycode = KEY_Q;InputMap.action_add_event("roll", roll_key)


	for action in ["fire", "aim"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
		InputMap.action_erase_events(action)

func material(color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = 0.9
	return mat

func block(at, size, color, solid = true):
	var body = StaticBody3D.new() if solid else Node3D.new()
	body.position = at
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material(color)
	body.add_child(mesh)
	if solid:
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	arena_root.add_child(body)
	return body

func build_world():
	arena_root = Node3D.new()
	add_child(arena_root)
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("142032")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b3c8df")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -25, 0)
	light.light_color = Color("cddbf5")
	light.light_energy = 1.5
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 38
	add_child(light)
	block(Vector3(0, -0.15, 0), Vector3(52, 0.3, 52), "343f4e")
	for at in [Vector3(-5, 0.8, -4), Vector3(5, 0.8, -4), Vector3(-6, 0.8, 5), Vector3(6, 0.8, 5)]:
		block(at, Vector3(3, 1.6, 2), "576371")
		block(at + Vector3(0, 0.81, 0), Vector3(3.1, 0.06, 2.1), "bba277", false)
	for at in [Vector3(0, 1, -12), Vector3(-11, 1, 0), Vector3(11, 1, 0)]:
		block(at, Vector3(2, 2, 2), "374e5c")
	for x in [-1, 1]:
		block(Vector3(x * 25, 2.5, 0), Vector3(1, 5, 52), "1c2634")
		block(Vector3(0, 2.5, x * 25), Vector3(52, 5, 1), "1c2634")
	for i in range(-4, 5):
		block(Vector3(i * 5, 0.015, 0), Vector3(0.025, 0.02, 48), "59616b", false)
		block(Vector3(0, 0.015, i * 5), Vector3(48, 0.02, 0.025), "59616b", false)
	var sign = Label3D.new()
	sign.text = "WOLF ROGUE\nBLOOD // TRAINING"
	sign.font_size = 120
	sign.pixel_size = 0.009
	sign.position = Vector3(0, 5.5, -24.35)
	sign.modulate = Color("f07b65")
	arena_root.add_child(sign)

func build_ui():
	var layer = CanvasLayer.new();add_child(layer)
	var root = Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter = Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	hud_label = SourceArt.label("");hud_label.hide();root.add_child(hud_label)
	message = SourceArt.label("",Vector2(900,60),16);message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);message.position=Vector2(-450,140);message.size=Vector2(900,60);root.add_child(message)
	source_hud=GameHud.new();source_hud.game=self;root.add_child(source_hud)
	touch=Node2D.new();touch.set_script(TouchScript);touch.game=self;layer.add_child(touch)
	menu_backdrop=ColorRect.new();menu_backdrop.color=Color("050709");menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(menu_backdrop)
	# Kept only for backwards-compatible QA/accessors; no old panel is displayed.
	overlay=PanelContainer.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER);overlay.position=Vector2(-280,-245);overlay.size=Vector2(560,490);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(overlay)
	overlay_box=VBoxContainer.new();overlay.add_child(overlay_box);overlay.hide()

func center_overlay(dimensions):
	overlay.offset_left = - dimensions.x / 2.0
	overlay.offset_right = dimensions.x / 2.0
	overlay.offset_top = - dimensions.y / 2.0
	overlay.offset_bottom = dimensions.y / 2.0

func clear_overlay():
	if is_instance_valid(player) and is_instance_valid(player.roar_effect): player.roar_effect.stop()
	clear_pc_panel()
	if is_instance_valid(library_panel): library_panel.get_parent().remove_child(library_panel);library_panel.queue_free();library_panel = null
	for child in overlay_box.get_children():
		overlay_box.remove_child(child)
		child.queue_free()
	center_overlay(Vector2(560, 490))
	overlay.show()
	menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if touch:
		touch.reset()
	if player:
		player.reset_locomotion()

func show_library(initial_page = "Mağaza"):
	if is_instance_valid(library_panel):
		if library_panel.page == initial_page: library_panel.close_menu()
		else: library_panel.navigate(initial_page)
		return
	open_interface(initial_page,true)

func apply_settings():
	if not is_instance_valid(touch): return
	touch.direction_buttons = bool(book.settings.directions)
	game_audio.apply_settings()
	for light in find_children("*", "DirectionalLight3D", true, false): light.shadow_enabled = bool(book.settings.shadows)
	if not test_mode: Engine.max_fps = int(book.settings.fps)

func activate_prepared_weapon(item,prepared):
	weapon_ammo[current_weapon_id]={"ammo":ammo,"reserve":reserve}
	player.apply_prepared_weapon(prepared)
	current_weapon_id=item.id
	var stored=weapon_ammo.get(item.id,{"ammo":weapon_capacity(),"reserve":weapon_capacity()*4})
	ammo=int(stored.ammo);reserve=int(stored.reserve);reloading=0;update_hud()

func equip_library_weapon(item):
	if not book.owned.get(item.id,false):return false
	if running and match_rules.enabled and not match_rules.weapon_allowed(item.get("category","")):return false
	var prepared=player.prepare_library_weapon(item)
	if prepared.is_empty():return false
	activate_prepared_weapon(item,prepared);return true

func select_library_character(entry):
	if entry.get("available")!=true:return false
	var models=player.prepare_character(entry)
	if models.is_empty():return false
	if not book.choose_character(entry.id):
		for model in models:model.free()
		announce("Karakter seçimi kaydedilemedi.");return false
	if running and entry.get("sourceTeam",local_room.get("team","blue"))!=local_room.get("team","blue"):
		for model in models:model.free()
		return true
	character_info=entry;player.apply_prepared_character(models);return true

func weapon_capacity():
	return int(player.weapon_info.get("shotsPerClip", 30))

func equip_slot(slot):
	var item=book.weapon(book.slots.get(slot,""))
	if item.is_empty() or not equip_library_weapon(item):return false
	current_loadout_slot=slot;return true

func cycle_primary():
	if current_loadout_slot=="primary" and book.slots.get("secondary_primary","")!="":return equip_slot("secondary_primary")
	return equip_slot("primary")

func play_source_effect(entry, where):
	var sprite = AnimatedSprite3D.new(); var frames = SpriteFrames.new();frames.set_animation_loop("default", false);frames.set_animation_speed("default", float(entry.fps))
	for path in entry.frames: frames.add_frame("default", load(path))
	sprite.sprite_frames = frames;sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED;sprite.pixel_size = 0.02;sprite.position = where;sprite.shaded = false;transient_effects.add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free);sprite.play("default")
	return sprite

func effect_with(fragment):
	for entry in book.effects:
		if str(entry.source).contains(fragment): return entry
	return {}

func explode(where, amount, kind):
	var fx = effect_with("smoke_seq_1" if kind == "smoke" else "exp_seq_1")
	if clientfx.canonical("Exp_Smoke_1" if kind=="smoke" else "Exp_Granade_2")!="":clientfx.play("Exp_Smoke_1" if kind=="smoke" else "Exp_Granade_2",null,where)
	elif not fx.is_empty(): play_source_effect(fx, where)
	if kind == "smoke": return
	for enemy in enemies.get_children():
		if not hostile(enemy,local_room.get("team","blue")):continue
		var distance = enemy.global_position.distance_to(where)
		if distance > 6: continue
		var query = PhysicsRayQueryParameters3D.create(where + Vector3.UP * 0.1, enemy.global_position + Vector3.UP, 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): enemy.damage(int(amount * (1 - distance / 6)))

func show_home():
	running=false;close_round_selection()
	open_interface("lobby")

func show_front_screen(page):
	if page not in ["entry","servers","events"]:return
	running=false;open_interface(page)

func show_launcher():
	running=false;open_interface("entry")

func open_interface(page, library=false):
	if profile_lock!=null and not profile_lock.unlocked:page="entry";library=false
	clear_overlay();overlay.hide()
	var panel=Frontend.new();panel.game=self;panel.page=page
	if library: library_panel=panel
	else: pc_panel=panel
	overlay.get_parent().add_child(panel)

func show_maps():
	open_interface("maps")

func refresh_mode_maps():
	map_picker.clear()
	for entry in map_catalog.maps_for_mode(mode_picker.get_selected_id()):
		map_picker.add_item("%d · %s" % [int(entry.number), entry.displayName], int(entry.number))
	refresh_map_status()

func refresh_map_status():
	if is_instance_valid(map_photo):map_photo.texture=SourceArt.atlas(map_catalog.photo(map_picker.get_selected_id()).get("asset",""),Rect2(0,0,407,120))
	if map_picker.item_count == 0:
		map_status.text = "Bu mod için doğrulanmış seçili harita yok."
		map_start.disabled = true
		map_preview.disabled = true
		return
	var reason = map_catalog.unavailable_reason(mode_picker.get_selected_id(), map_picker.get_selected_id())
	map_status.text = (reason if reason != "" else "Harita hazır.") + "\n46 · Göbekli Tepe: mod eşleşmesi bekleniyor."
	map_start.disabled = reason != ""
	map_preview.disabled = map_catalog.preview_record(mode_picker.get_selected_id(), map_picker.get_selected_id()).is_empty()
	if not map_preview.disabled:
		map_status.text = "Geometri önizlemesi hazır. Gezinti açılabilir; bu modun maç kuralları henüz tamamlanmadı.\n46 · Göbekli Tepe: mod eşleşmesi bekleniyor."

func set_arena_active(enabled):
	arena_root.visible = enabled
	for body in arena_root.find_children("*", "StaticBody3D", true, false):
		body.collision_layer = 1 if enabled else 0

func start_map_preview():
	close_round_selection()
	hunt.active=false;tutorial.active=false
	var record = map_catalog.preview_record(mode_picker.get_selected_id(), map_picker.get_selected_id())
	if record.is_empty():
		return
	var asset = record.previewAsset
	if FileAccess.file_exists(asset) and FileAccess.get_sha256(asset) != record.sha256:
		map_status.text = "Harita dosyası değişmiş; doğrulama gerekiyor."
		return
	running = false
	offline_map_number = 0
	clear_offline_navigation()
	clear_projectiles()
	for enemy in enemies.get_children():
		enemy.queue_free()
	if is_instance_valid(active_map):
		remove_child(active_map)
		active_map.queue_free()
	active_map = load(asset).instantiate()
	active_map.set_meta("map_number",int(record.number))
	add_child(active_map)
	for mesh in active_map.find_children("*", "MeshInstance3D", true, false):
		mesh.create_trimesh_collision()
	var ambient = Node3D.new()
	ambient.set_script(MapAudio)
	ambient.game = self
	ambient.map_number = int(record.number)
	active_map.add_child(ambient)
	set_arena_active(false)
	var anchor = record.startPoints[0]
	var pos = anchor.position
	preview_spawn = Vector3(pos[0], pos[1], pos[2])
	player.position = preview_spawn
	player.velocity = Vector3.ZERO
	player.yaw = float(anchor.yaw)
	player.rotation.y = player.yaw
	player.reset_locomotion()
	health = 100
	ammo = weapon_capacity()
	reserve = ammo * 4
	weapon_ammo.clear()
	reloading = 0
	exploring = true
	preview_name = map_catalog.map_record(map_picker.get_selected_id()).displayName
	running = true
	resume()
	announce("Harita gezintisi · Maç kuralları kapalı")
	update_hud()

func start_selected_map():

	var mode_id = mode_picker.get_selected_id()
	var map_number = map_picker.get_selected_id()
	var reason = map_catalog.unavailable_reason(mode_id, map_number)
	if reason != "":
		map_status.text = reason
		return

	local_room={"title":"Yerel Ölüm Oyunu","mode":mode_id,"map":map_number,"team":"blue"};start_round(true)

func pause_game_menu():
	open_interface("pause")

func clear_pc_panel():
	if is_instance_valid(pc_panel):
		pc_panel.get_parent().remove_child(pc_panel);pc_panel.queue_free();pc_panel = null

func resume():
	if profile_lock!=null and not profile_lock.unlocked:return
	if application_suspended:return
	clear_pc_panel()
	if is_instance_valid(library_panel):
		library_panel.get_parent().remove_child(library_panel);library_panel.queue_free();library_panel=null
	menu_open=false;overlay.hide()
	if is_instance_valid(menu_backdrop):menu_backdrop.hide()
	if not OS.has_feature("android") and DisplayServer.get_name()!="headless":Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if selection_active else Input.MOUSE_MODE_CAPTURED

func clear_projectiles():
	if is_instance_valid(transient_effects):
		for effect in transient_effects.get_children():
			transient_effects.remove_child(effect)
			effect.queue_free()
	for node in get_children():
		if node.get_script() == GrenadeScript:
			remove_child(node)
			node.queue_free()

func start_round(with_selection=false):
	if profile_lock!=null and not profile_lock.unlocked:return false
	if not is_local_mode(int(local_room.get("mode",0))):
		announce("Özgün mod kuralları henüz tamamlanmadı.")
		return false
	if preload("res://scripts/source_match_rules.gd").supports(local_room.get("mode",0)) and not map_catalog.belongs_to_mode(int(local_room.mode),int(local_room.get("map",0))):
		announce("Harita bu özgün moda bağlı değil.");return false
	game_audio.clear_match_voices();match_rules.configure(local_room);announced_last_minute=false;first_kill_announced=false
	close_round_selection();round_selection_enabled=with_selection
	var team_character=book.character_for_team(local_room.get("team","blue"))
	if not team_character.is_empty() and team_character.id!=character_info.id:
		var models=player.prepare_character(team_character)
		if models.is_empty():announce("Takım karakteri yüklenemedi.");return false
		character_info=team_character;player.apply_prepared_character(models)
	var map_number = int(local_room.get("map", 0))
	var record = map_catalog.offline_record(map_number) if map_number != 0 else {}
	if map_number != 0 and record.is_empty():
		announce("Bu haritanın çevrimdışı doğrulaması eksik.")
		return false
	if not record.is_empty():
		for binding in [[record.previewAsset, record.geometrySha256], [record.navigation, record.sha256]]:
			if FileAccess.file_exists(binding[0]) and FileAccess.get_sha256(binding[0]) != binding[1]:
				announce("Harita dosyası değişmiş; doğrulama gerekiyor.")
				return false
	if is_instance_valid(player.roar_effect): player.roar_effect.stop()
	clear_projectiles()
	if is_instance_valid(source_hud):source_hud.feedback.reset()
	exploring = false
	offline_map_number = map_number
	bot_difficulty = local_room.get("botDifficulty","normal")
	if not BotRules.LEVELS.has(bot_difficulty):bot_difficulty="normal"
	bot_spawn_count=0
	clear_offline_navigation()
	if is_instance_valid(active_map):
		remove_child(active_map)
		active_map.queue_free()
	set_arena_active(record.is_empty())
	preview_spawn = Vector3(0 if local_room.get("team","blue")=="blue" else 3, 0.1, 12 if local_room.get("team","blue")=="blue" else -12)
	preview_name = "Eğitim Arenası"
	var spawn_yaw = 0.0 if local_room.get("team","blue")=="blue" else PI
	if not record.is_empty():
		active_map = load(record.previewAsset).instantiate()
		active_map.set_meta("map_number",map_number)
		add_child(active_map)
		for mesh in active_map.find_children("*", "MeshInstance3D", true, false):
			mesh.create_trimesh_collision()
		install_navigation(record.navigation,active_map)
		var ambient = Node3D.new();ambient.set_script(MapAudio);ambient.game = self
		ambient.map_number = map_number;active_map.add_child(ambient)
		var source_fx=Node3D.new();source_fx.set_script(preload("res://scripts/map_source_effects.gd"));source_fx.game=self;source_fx.map_number=map_number;active_map.add_child(source_fx)
		var anchors=team_start_points(record,local_room.get("team","blue"))
		if anchors.is_empty():announce("Takım doğma alanı doğrulanamadı.");return false
		var anchor = anchors[0]
		var opposing=team_start_points(record,"red" if local_room.get("team","blue")=="blue" else "blue")
		for candidate in anchors:
			var p=Vector3(candidate.position[0],candidate.position[1],candidate.position[2])
			var nav=NavigationServer3D.map_get_closest_point(offline_navigation_map,p)
			if opposing.any(func(other):return navigation_graph.connected(NavigationServer3D.map_get_closest_point(offline_navigation_map,Vector3(other.position[0],other.position[1],other.position[2])),nav)):
				anchor=candidate;break
		preview_spawn = Vector3(anchor.position[0], anchor.position[1], anchor.position[2])
		spawn_yaw = float(anchor.yaw)
		preview_name = map_catalog.map_record(map_number).displayName
	else:
		var arena=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/arena-navigation.json"))
		install_navigation(arena.asset,arena_root)
	for enemy in enemies.get_children():
		enemy.queue_free()
	health = 100
	ammo = weapon_capacity()
	reserve = ammo * 4
	weapon_ammo.clear()
	kills = 0;deaths=0;team_frags={"red":0,"blue":0};respawn_remaining=0
	match_serial+=1;match_stats={"attacks":0,"hits":0,"damage":0,"headshots":0};kill_feed.clear()
	match_id=Crypto.new().generate_random_bytes(16).hex_encode()
	hunt.active=int(local_room.get("mode",0))==LocalHunt.MODE
	if hunt.active:hunt.begin(local_room.get("playerForm","human"))
	tutorial.active=int(local_room.get("mode",0))==LocalTutorial.MODE
	time_left = match_rules.seconds
	reloading = 0
	player.position = preview_spawn
	player.velocity = Vector3.ZERO
	player.reset_combat()
	var mutation_model=player.prepare_mutation(book.wolf_mutation)
	if mutation_model:player.apply_mutation(mutation_model,book.wolf_mutation)
	booster_remaining=0;booster_tuning={};healing_uses.clear()
	player.yaw = spawn_yaw
	player.rotation = Vector3(0, spawn_yaw, 0)
	running = true
	resume()
	if hunt.active and player.is_wolf!=(hunt.player_form=="wolf"):player.switch_form(true)
	if tutorial.active:
		if player.is_wolf:player.switch_form(true)
		tutorial.begin(player.position,match_stats.attacks)
	spawn_clock = 0
	if int(local_room.get("mode",0))==WOLF_BATTLE:
		if not player.is_wolf:player.switch_form(true)
	elif not hunt.active and not tutorial.active and with_selection and player.is_wolf:player.switch_form(true)
	health=max_health()
	if match_rules.enabled:
		if match_rules.form_lock!="mixed" and player.is_wolf!=(match_rules.form_lock=="wolf"):player.switch_form(true)
		if not player.is_wolf and not match_rules.weapon_allowed(player.weapon_info.get("category","")):
			var candidates=book.weapons.filter(func(w):return w.get("available",false) and book.owned.get(w.id,false) and match_rules.weapon_allowed(w.category) and w.category=="rifle")
			if not candidates.is_empty():equip_library_weapon(candidates[0])
	game_audio.match_sound("round_start")
	if with_selection and not tutorial.active:open_round_selection()
	announce(("%d Puan · %d dakika" % [match_rules.goal,match_rules.seconds/60]) if match_rules.enabled else ("Kurt Avı · Raunt 1/3" if hunt.active else "10 hedef · 90 saniye"))
	update_hud()
	return true

func is_local_mode(value):return value in [0,LocalHunt.MODE,LocalTutorial.MODE,WOLF_BATTLE] or preload("res://scripts/source_match_rules.gd").supports(value)
func announce_kill_sound(team,headshot):
	if not first_kill_announced:
		first_kill_announced=true;game_audio.match_sound("round_first_kill_"+team)
	if headshot:game_audio.match_sound("head_shot")
func target_score():return match_rules.goal if match_rules.enabled else 10
func open_round_selection(kind="",transform_after=false):
	if not running or tutorial.active or exploring:return false
	close_round_selection();touch.reset();player.velocity=Vector3.ZERO
	selection_active=true;selection_transform=transform_after
	selection_panel=load("res://ui/round_selection.gd").new();selection_panel.game=self
	selection_panel.kind=("wolf" if player.is_wolf else "human") if kind=="" else kind
	overlay.get_parent().add_child(selection_panel)
	if DisplayServer.get_name()!="headless":Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	return true
func close_round_selection():
	selection_active=false;selection_transform=false
	if is_instance_valid(selection_panel):
		selection_panel.get_parent().remove_child(selection_panel);selection_panel.queue_free()
	selection_panel=null
	if is_instance_valid(touch):touch.reset()
	if running and not menu_open and not application_suspended and not OS.has_feature("android") and DisplayServer.get_name()!="headless":Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func finish_round_selection():
	var transform_after=selection_transform
	close_round_selection()
	if transform_after and running and not player.is_wolf:player.switch_form(true)
func choose_round_loadout(index):
	if not selection_active or selection_panel.kind!="human":return false
	if not book.select_loadout(index):announce("Ekipman seçimi kaydedilemedi.");return false
	equip_slot("primary");close_round_selection();return true
func choose_round_mutation(id):
	if not selection_active or selection_panel.kind!="wolf" or not mutations.TYPES.has(id):return false
	var model=player.prepare_mutation(id)
	if model==null:announce("Kurt modeli yüklenemedi.");return false
	if not book.select_mutation(id):model.free();announce("Kurt seçimi kaydedilemedi.");return false
	var transform_after=selection_transform
	player.apply_mutation(model,id)
	close_round_selection()
	if transform_after and not player.is_wolf:player.switch_form(true)
	update_hud();return true
func is_match_active():return running and not menu_open and not application_suspended and not selection_active and (not hunt.active or hunt.phase=="combat")
func is_combat_active():return is_match_active() and health>0
func finish_hunt_round(won):
	if not hunt.finish_round(won):return
	for enemy in enemies.get_children():enemy.collision_layer=0;enemy.queue_free()
	clear_projectiles();player.reset_combat();touch.reset();reloading=0
	if hunt.phase=="finished":end_round("Kurt Avı · %d kazanılan / %d kaybedilen raunt" % [hunt.wins,hunt.losses])
	else:announce("Raunt %d · %s" % [hunt.round_number,"Kazanıldı" if won else "Kaybedildi"]);message_clock=3.0
func advance_hunt(delta):
	if hunt.phase!="intermission":return false
	hunt.intermission=maxf(0,hunt.intermission-delta)
	if hunt.intermission<=0 and hunt.next_round():
		health=max_health();booster_remaining=0;booster_tuning={};healing_uses.clear();ammo=weapon_capacity();reserve=ammo*4;weapon_ammo.clear();time_left=LocalHunt.SECONDS
		player.position=preview_spawn;player.velocity=Vector3.ZERO;player.reset_combat();spawn_clock=0
		announce("Kurt Avı · Raunt %d/3" % hunt.round_number)
		if round_selection_enabled:open_round_selection()
	update_hud();return true

func install_navigation(asset,parent):
	navigation_region=NavigationRegion3D.new()
	NavigationServer3D.region_set_use_async_iterations(navigation_region.get_rid(),false)
	navigation_region.navigation_mesh=load(asset)
	offline_navigation_map=NavigationServer3D.map_create()
	var map=offline_navigation_map
	NavigationServer3D.map_set_active(map,true)
	NavigationServer3D.map_set_use_async_iterations(map,false)
	NavigationServer3D.map_set_cell_size(map,navigation_region.navigation_mesh.cell_size)
	NavigationServer3D.map_set_cell_height(map,navigation_region.navigation_mesh.cell_height)
	NavigationServer3D.map_set_merge_rasterizer_cell_scale(map,0.1)
	navigation_region.set_navigation_map(map);parent.add_child(navigation_region)
	navigation_graph=NavigationGraph.new(navigation_region.navigation_mesh,navigation_region.global_transform)
	if offline_map_number!=0 and FileAccess.file_exists("res://assets/maps/traversals.json"):
		for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/traversals.json")):
			if int(row.number)!=offline_map_number or row.navigationSha256!=FileAccess.get_sha256(asset):continue
			for spec in row.links:
				var a=spec.entry;var b=spec.exit;var link=NavigationLink3D.new()
				link.start_position=Vector3(a[0],a[1],a[2]);link.end_position=Vector3(b[0],b[1],b[2]);link.bidirectional=spec.get("bidirectional",true);link.enter_cost=1.0;link.set_meta("traversal",spec)
				link.set_navigation_map(map);parent.add_child(link)
				navigation_graph.join_points(link.start_position,link.end_position,link.bidirectional)
	NavigationServer3D.region_set_map(navigation_region.get_rid(),map)
	NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(),navigation_region.navigation_mesh)
	NavigationServer3D.map_force_update(map)

func clear_offline_navigation():
	navigation_graph=null
	if is_instance_valid(navigation_region):
		navigation_region.enabled = false
		NavigationServer3D.region_set_map(navigation_region.get_rid(), RID())
		navigation_region.queue_free()
	navigation_region = null
	if offline_navigation_map.is_valid():
		NavigationServer3D.free_rid(offline_navigation_map)
		offline_navigation_map = RID()

func _exit_tree():
	clear_offline_navigation()

func pause_game():
	if is_instance_valid(library_panel):library_panel.go_back();return
	if is_instance_valid(pc_panel):pc_panel.go_back();return
	if not running:return
	pause_game_menu()

func _input(event):
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look(event.relative)
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: Input.action_release("fire")
		elif event.button_index == MOUSE_BUTTON_RIGHT: Input.action_release("aim")
	if event.is_action_pressed("pause"):
		pause_game()
	if event.is_action_pressed("admin"):
		show_admin()
	if event.is_action_pressed("inventory"):
		show_library("Envanter")
	if event is InputEventKey and event.physical_keycode==KEY_TAB and not event.echo and running:
		if event.pressed and not menu_open:open_interface("scoreboard")
		elif not event.pressed and is_instance_valid(pc_panel) and pc_panel.page=="scoreboard":resume()
	if event is InputEventKey and event.pressed and not event.echo and not menu_open:
		var keys = {KEY_1: "primary", KEY_2: "pistol", KEY_4: "grenade", KEY_5: "knife"}
		if event.physical_keycode==KEY_1:cycle_primary()
		elif keys.has(event.physical_keycode):equip_slot(keys[event.physical_keycode])
	if event is InputEventMouseButton and menu_open:
		Input.action_release("fire")
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F6:
		start_round()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and running and not menu_open:
		var action = "fire" if event.button_index == MOUSE_BUTTON_LEFT else ("aim" if event.button_index == MOUSE_BUTTON_RIGHT else "")
		if action != "":
			if event.pressed: Input.action_press(action)
			else: Input.action_release(action)

func _notification(what):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		suspend_application()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		restore_application()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pause_game()

func gameplay_touch_blocked(point):
	for control in gui_touch_blockers:
		if is_instance_valid(control) and control.is_visible_in_tree() and control.get_global_rect().has_point(point):
			return true
	return false

func suspend_application():
	if application_suspended or not is_instance_valid(touch): return
	application_suspended = true
	touch.reset()
	player.reset_locomotion()
	if running and not menu_open: pause_game_menu()
	game_audio.set_suspended(true)
	tree_was_paused = get_tree().paused
	get_tree().paused = true

func restore_application():
	if not application_suspended: return
	application_suspended = false
	get_tree().paused = tree_was_paused
	game_audio.set_suspended(false)
	# Returning to Android never resumes combat until the player chooses Continue.

func _process(delta):
	if is_instance_valid(menu_backdrop): menu_backdrop.visible = menu_open and not running
	if is_instance_valid(message):message.visible=running and not menu_open
	poll_clock -= delta
	if poll_clock <= 0 and not test_mode and not OS.has_feature("android"):
		poll_clock = 3.0
		if poll.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			poll.request("http://127.0.0.1:8765/api/state", PackedStringArray(["X-WolfRogue-Client: godot"]))
	if not grant_busy and not grant_queue.is_empty():
		var grant = grant_queue[0]
		grant_busy = true
		var err = grant_http.request("http://127.0.0.1:8765/api/grants", PackedStringArray(["Content-Type: application/json", "X-Admin-Token: " + remote_token]), HTTPClient.METHOD_POST, JSON.stringify(grant))
		if err != OK:
			grant_busy = false
			grant_queue.pop_front()
	message_clock = maxf(0, message_clock - delta)
	if message_clock <= 0:
		message.text = ""
	crosshair.visible = running and not menu_open
	if not running or menu_open:
		return
	if selection_active:return
	booster_remaining=maxf(0,booster_remaining-delta)
	if hunt.active and advance_hunt(delta):return
	for entry in kill_feed:entry.remaining=maxf(0,entry.remaining-delta)
	kill_feed=kill_feed.filter(func(entry):return entry.remaining>0)
	if reloading > 0:
		reloading -= delta
		if reloading <= 0:
			var refill = mini(weapon_capacity() - ammo, reserve);ammo += refill;reserve -= refill
	if exploring:
		if player.position.y < preview_spawn.y - 150:
			player.position = preview_spawn
			player.velocity = Vector3.ZERO
		update_hud()
		return
	if offline_map_number != 0 and player.position.y < preview_spawn.y - 150:
		player.position = preview_spawn;player.velocity = Vector3.ZERO;player.reset_locomotion()
		take_damage(20)
		announce("Güvenli noktaya dönüş · −20 can")
		if not is_combat_active():return
	if tutorial.active:
		if tutorial.advance(self):end_round("Öğretici tamamlandı")
		update_hud();return
	if respawn_remaining>0:
		respawn_remaining=maxf(0,respawn_remaining-delta)
		if respawn_remaining<=0:
			player.position=preview_spawn;player.velocity=Vector3.ZERO;player.reset_combat();health=max_health();ammo=weapon_capacity();reserve=ammo*4;weapon_ammo.clear()
			announce("Takımına geri döndün")
	time_left -= delta
	if match_rules.enabled and time_left<=60 and not announced_last_minute:
		announced_last_minute=true
		game_audio.match_sound("left_1_minute")
	spawn_clock -= delta
	if spawn_clock<=0:
		var own=local_room.get("team","blue");var opposing="red" if own=="blue" else "blue"
		for team in [opposing,own]:
			var wanted=bot_limit(team)
			var alive=enemies.get_children().filter(func(bot):return not bot.is_queued_for_deletion() and bot.team==team).size()
			if alive<wanted and (not hunt.active or team==own or hunt.spawned<LocalHunt.TARGET):
				if spawn_enemy("","",team) and hunt.active and team==opposing:hunt.spawned+=1
		spawn_clock=3.5
	if time_left <= 0:
		if hunt.active:finish_hunt_round(false)
		else:
			if match_rules.enabled:match_rules.decide(team_score("red"),team_score("blue"))
			end_round("Berabere" if match_rules.enabled and match_rules.winner=="draw" else "Süre doldu")
	update_hud()

func bot_limit(team):
	if int(local_room.get("mode",0))==LocalTutorial.MODE:return 0
	return clampi(int(local_room.get("allyBots",0) if team==local_room.get("team","blue") else local_room.get("enemyBots",4)),0,4)

func actor_alive(actor):
	return is_instance_valid(actor) and not actor.is_queued_for_deletion() and (health>0 if actor==player else actor.health>0)
func actor_team(actor):return local_room.get("team","blue") if actor==player else actor.team
func hostile(actor,team):return actor_alive(actor) and actor_team(actor)!=team
func combat_targets(team):
	var result=[]
	if hostile(player,team):result.append(player)
	for bot in enemies.get_children():
		if hostile(bot,team):result.append(bot)
	return result
func team_score(team):return int(team_frags.get(team,0))+(kills if team==local_room.get("team","blue") else deaths)
func bot_defeated(victim,context):
	if not is_match_active():return
	var team=context.get("attackerTeam","")
	if team not in ["red","blue"] or team==victim.team:return
	team_frags[team]+=1
	announce_kill_sound(team,false)
	kill_feed.push_front({"attacker":context.get("name","Bot"),"target":victim.display_name,"weapon":context.get("weapon","Pençe"),"weaponId":"","headshot":false,"attackerTeam":team,"targetTeam":victim.team,"remaining":6.0})
	if kill_feed.size()>5:kill_feed.resize(5)
	if hunt.active:
		if victim.team!=local_room.get("team","blue"):
			hunt.round_kills+=1
			if hunt.round_kills>=LocalHunt.TARGET:finish_hunt_round(true)
	elif team_score(team)>=target_score():end_round("Arena tamamlandı" if team==local_room.get("team","blue") else "Yenildin")
	update_hud()

func spawn_enemy(kind="",difficulty="",team=""):
	if team=="":team="red" if local_room.get("team","blue")=="blue" else "blue"
	if team not in ["red","blue"]:return false
	var zone_z=-12.0 if team=="red" else 12.0
	var points = [Vector3(-9,0.1,zone_z),Vector3(-6,0.1,zone_z),Vector3(-3,0.1,zone_z),Vector3(3,0.1,zone_z),Vector3(6,0.1,zone_z),Vector3(9,0.1,zone_z)]
	if offline_map_number != 0:
		points = offline_spawn_points(team)
		if points.is_empty(): return false
	points=points.filter(func(p):return p.distance_to(player.position)>1.3 and enemies.get_children().all(func(bot):return bot.is_queued_for_deletion() or bot.position.distance_to(p)>1.1))
	if points.is_empty():return false
	var enemy = CharacterBody3D.new()
	enemy.set_script(EnemyScript)
	enemy.game = self
	enemy.team=team
	enemy.rotation.y=PI if team=="red" else 0.0
	enemy.kind=match_rules.form_lock if match_rules.enabled and match_rules.form_lock!="mixed" else (kind if kind in ["human","wolf"] else ("wolf" if int(local_room.get("mode",0))==WOLF_BATTLE else ((hunt.enemy_kind() if team!=local_room.get("team","blue") else hunt.player_form) if hunt.active else ("wolf" if bot_spawn_count%2==0 else "human"))))
	enemy.display_name=("İnsan" if enemy.kind=="human" else "Kurt")+" %02d" % (bot_spawn_count+1)
	enemy.difficulty=difficulty if BotRules.LEVELS.has(difficulty) else bot_difficulty
	enemy.position = points.pick_random()
	enemies.add_child(enemy)
	bot_spawn_count+=1
	return true

func notify_bot_noise(point,radius):
	for enemy in enemies.get_children():
		if not enemy.is_queued_for_deletion():enemy.hear_noise(point,radius)

func team_start_points(record,team):
	var tag="Team1" if team=="red" else "Team0"
	var points=record.get("startPoints",[]).filter(func(row):return row.get("team")==tag)
	# Two source worlds label one side NoTeam. Keep that original tag and
	# explicitly adapt only the missing side for the local two-team rules.
	if points.is_empty():points=record.get("startPoints",[]).filter(func(row):return row.get("team")=="NoTeam")
	return points

func offline_spawn_points(team=""):
	if team=="":team="red" if local_room.get("team","blue")=="blue" else "blue"
	var points=[];var reachable_points=[];var nav_map=offline_navigation_map
	if not nav_map.is_valid():return points
	var record=map_catalog.offline_record(offline_map_number)
	var anchors=team_start_points(record,team)
	if anchors.is_empty():return points
	NavigationServer3D.map_force_update(nav_map)
	var origin=NavigationServer3D.map_get_closest_point(nav_map,player.position)
	var capsule=CapsuleShape3D.new();capsule.radius=0.44;capsule.height=1.9
	var clearance=PhysicsShapeQueryParameters3D.new();clearance.shape=capsule;clearance.collision_mask=3
	for anchor in anchors:
		var base=Vector3(anchor.position[0],anchor.position[1],anchor.position[2])
		for offset in [Vector3.ZERO,Vector3(1.2,0,0),Vector3(-1.2,0,0),Vector3(0,0,1.2),Vector3(0,0,-1.2)]:
			var sample=base+offset
			var pos=NavigationServer3D.map_get_closest_point(nav_map,sample)
			if pos.distance_to(sample)>3 or pos.distance_to(base)>3.5:continue
			if navigation_graph==null:continue
			# Spawn membership is independent of whether this approximate render
			# collision has a complete route between both source spawn zones.
			# Bots patrol the actual team zone and pursue only reachable surfaces.
			if navigation_graph.connected(pos,origin):
				var path=NavigationServer3D.map_get_path(nav_map,pos,origin,true)
				if path.size()<2 or path[-1].distance_to(origin)>1:continue
			var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*1.5,pos-Vector3.UP*2,1)
			var floor_hit=get_world_3d().direct_space_state.intersect_ray(ray)
			if floor_hit.is_empty() or floor_hit.normal.y<0.65:continue
			pos=floor_hit.position+Vector3.UP*0.12
			var supported=NavigationServer3D.map_get_closest_point(nav_map,pos)
			if absf(supported.y-floor_hit.position.y)>0.5 or Vector2(supported.x-pos.x,supported.z-pos.z).length()>0.35:continue
			clearance.transform=Transform3D(Basis.IDENTITY,pos+Vector3.UP*0.95)
			if not get_world_3d().direct_space_state.intersect_shape(clearance,1).is_empty():continue
			var occupied=pos.distance_to(player.position)<(1.3 if team==local_room.get("team","blue") else 3.5)
			for enemy in enemies.get_children():
				if not enemy.is_queued_for_deletion() and enemy.position.distance_to(pos)<1.2:occupied=true;break
			if not occupied and points.all(func(p):return p.distance_to(pos)>0.7):
				points.append(pos)
				if navigation_graph.connected(supported,origin):reachable_points.append(pos)
	return reachable_points if not reachable_points.is_empty() else points

func attack():
	if not is_combat_active():return
	if player.rolling or player.wall_holding or player.air_attacking or player.roar_effect.active: return
	if not running or menu_open or reloading > 0 or player.shot_cooldown > 0:
		return
	if player.is_wolf and player.begin_wall_hold():
		announce("Duvara tutunma · İleriyi bırak: ayrıl · Zıpla: duvardan atla")
		return
	var kind = player.weapon_info.get("category", "rifle")
	if not player.is_wolf and kind != "knife" and ammo <= 0:
		if kind == "grenade": announce("Bomba kalmadı");return
		reload_weapon()
		return
	player.shot_cooldown = 0.55 if player.is_wolf else float(player.weapon_info.fireIntervalMs) / 1000.0
	player.action_time = 0.45
	player.current_clip = ""
	match_stats.attacks+=1
	player.play_clip("attack")
	if player.is_wolf:
		notify_bot_noise(player.global_position,8)
		var body_attack = player.wolf_running and equipment.has_wolf_ability() and player.anim.has_animation("body_attack")
		if body_attack:
			player.play_clip("body_attack")
			player.wolf_running = false
		var base=int(mutations.profile(player.mutation_id).damage)
		wolf_melee_hit((65 if player.mutation_id=="normal" else roundi(base*1.4)) if body_attack else base,2.8,"Vücut saldırısı" if body_attack else "Pençe isabeti")
		return
	if kind != "knife": ammo -= 1
	notify_bot_noise(player.global_position,6 if kind=="knife" else 26)
	player.play_weapon_clip("fire", float(player.weapon_info.fireIntervalMs) / 1000.0)
	if player.fire_sound.stream: player.play_weapon_sound("fire")
	if kind in ["grenade", "rocket", "launcher"]:
		var grenade = CharacterBody3D.new();grenade.set_script(GrenadeScript);grenade.game = self;grenade.position = player.camera.global_position - player.camera.global_basis.z * 0.7;grenade.velocity = - player.camera.global_basis.z * 13 + Vector3.UP * 3;grenade.damage_amount = int(player.weapon_info.get("damage", 90));grenade.kind = "smoke" if str(player.weapon_info.get("name", "")).to_lower().contains("smoke") else "grenade";grenade.fuse = 2 if kind == "grenade" else 0.7;add_child(grenade);return
	var camera = player.camera
	var origin = camera.global_position
	var end = origin - camera.global_basis.z * (2.6 if kind == "knife" else 100)
	var query = PhysicsRayQueryParameters3D.create(origin, end, 3, [player.get_rid()])
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		end = hit.position
		if hit.collider.has_meta("enemy") and hostile(hit.collider,local_room.get("team","blue")):
			var head=kind!="knife" and hit.collider.is_head_hit(hit.position,origin,(end-origin).normalized())
			var damage = int(player.weapon_info.get("damage", 25))*(2 if head else 1)
			var actual=mini(hit.collider.health,damage)
			if head:match_stats.headshots+=1
			clientfx.play("Impact_Flesh",null,hit.position)
			hit.collider.damage(damage,{"weapon":player.weapon_info.get("name","Silah"),"headshot":head})
			if is_instance_valid(source_hud):source_hud.feedback.show_hit()
			announce(("Kafadan isabet +%d" if head else "İsabet +%d") % actual)
	var flash = OmniLight3D.new()
	flash.position = player.global_position + Vector3(0, 1.4, 0)
	flash.light_color = Color("ffc77f")
	flash.light_energy = 2
	flash.omni_range = 3
	transient_effects.add_child(flash)
	get_tree().create_timer(0.06).timeout.connect(flash.queue_free)

func wolf_melee_hit(amount,reach,caption):
	if not is_combat_active():return
	player.cancel_cloak()
	reach=reach*(1.0+float(gear_stats().rangePercent)/100.0)+float(power_bonus("claw","rangeBonus",0))
	if is_instance_valid(player.claw_trail) and (not is_instance_valid(player.source_events) or not player.source_events.has_spline()):player.claw_trail.begin()
	amount=roundi(amount*wolf_damage_multiplier()*(1.0+float(gear_stats().damagePercent)/100.0))+int(power_bonus("claw","damageBonus",0))
	for enemy in enemies.get_children():
		if not running:break
		if not hostile(enemy,local_room.get("team","blue")):continue
		var offset=enemy.global_position-player.global_position
		if offset.length()>=reach or offset.normalized().dot(-player.global_basis.z)<=0.1:continue
		var query=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,enemy.global_position+Vector3.UP,3,[player.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if hit and hit.collider==enemy:
			enemy.damage(amount);announce(caption)
			if is_instance_valid(source_hud):source_hud.feedback.show_hit()

func strong_attack():
	if not is_combat_active() or not player.is_wolf:return false
	if player.mutation_id=="guardian":return player.begin_guard()
	if player.mutation_id=="ghost":return player.begin_cloak()
	if player.begin_ground_strong():match_stats.attacks+=1;announce("Güçlü pençe");return true
	if player.begin_air_attack():match_stats.attacks+=1;announce("Havada güçlü saldırı");return true
	return false

func reload_weapon():
	if not is_combat_active():
		return
	if player.is_wolf:
		if player.begin_roar():
			announce("Kükreme")
	elif player.weapon_info.get("category", "") not in ["knife", "grenade"] and ammo < weapon_capacity() and reserve > 0 and reloading <= 0:
		reloading = float(player.weapon_info.reloadSeconds)
		player.play_weapon_clip("reload", reloading)
		player.play_weapon_sound("reload")
		player.play_clip("reload")
		player.action_time = reloading
		announce("Şarjör değiştiriliyor…")

func enemy_defeated(context={}):
	if not is_combat_active():return
	kills += 1
	announce_kill_sound(local_room.get("team","blue"),context.get("headshot",false))
	kill_feed.push_front({"attacker":profile_name,"target":context.get("target","Bot"),"weapon":context.get("weapon","Pençe" if player.is_wolf else "Silah"),"headshot":context.get("headshot",false),"remaining":6.0,"weaponId":current_weapon_id if not player.is_wolf else "","attackerTeam":local_room.get("team","blue"),"targetTeam":"red" if local_room.get("team","blue")=="blue" else "blue"})
	if kill_feed.size()>5:kill_feed.resize(5)
	grant_money("cash", 25, "Arena hedef ödülü")
	grant_money("gp", roundi(10*(1.0+float(power_bonus("bag","localGpBonus",0))+float(gear_stats().gpPercent)/100.0)), "Arena gelişim ödülü")
	if hunt.active:
		hunt.round_kills+=1
		if hunt.round_kills>=LocalHunt.TARGET:finish_hunt_round(true)
	elif team_score(local_room.get("team","blue")) >= target_score():
		grant_money("gold", roundi(10*(1+float(gear_stats().goldPercent)/100.0)), "Arena tamamlandı")
		end_round("Arena tamamlandı")
	update_hud()

func take_damage(amount, source_position=null, attacker={}):
	if not is_combat_active() or amount<=0:
		return
	if attacker.get("attackerTeam","")==local_room.get("team","blue"):return
	if player.guard_remaining>0:amount=maxi(1,int(ceil(amount*0.5)))
	game_audio.play_at("root/wt_snd/player/attacked/%s_attacked%d.wav" % ["wolf" if player.is_wolf else "human",randi_range(1,2)],player.global_position,false)
	if player.guard_remaining>0:clientfx.play("FleshDefense",player)
	health = maxi(0, health - amount)
	if is_instance_valid(source_hud):source_hud.feedback.show_damage(source_position)
	if health == 0:
		game_audio.voice(player,0)
		deaths+=1
		kill_feed.push_front({"attacker":attacker.get("name","Bot"),"target":profile_name,"headshot":false,"weaponId":"","weapon":attacker.get("weapon","Pençe"),"attackerTeam":"red" if local_room.get("team","blue")=="blue" else "blue","targetTeam":local_room.get("team","blue"),"remaining":6.0})
		if kill_feed.size()>5:kill_feed.resize(5)
		if hunt.active:finish_hunt_round(false)
		elif (match_rules.enabled or int(local_room.get("allyBots",0))>0) and team_score("red" if local_room.get("team","blue")=="blue" else "blue")<target_score():
			respawn_remaining=3.0;player.reset_combat();touch.reset();announce("Yeniden doğuş · 3 saniye")
		else:end_round("Yenildin")

func end_round(title):
	if match_rules.enabled and match_rules.winner=="":match_rules.decide(team_score("red"),team_score("blue"))
	if match_rules.enabled:game_audio.match_sound("round_draw" if match_rules.winner=="draw" else "round_"+match_rules.winner+"_win")
	close_round_selection()
	if not match_id.is_empty() and not match_id in career.state.matches:
		var next=career.result(match_id,kills,match_stats.headshots,hunt.wins if hunt.active else 0,tutorial.active and tutorial.step>=tutorial.STEPS.size())
		var pending=inbox.state.duplicate(true)
		for mission in career.MISSIONS:
			if not next.claimed.get(mission.id,false) and int(next.totals[mission.stat])>=int(mission.goal):
				if not inbox.enqueue(pending,"cash","cash",mission.name,int(mission.cash),"mission-"+mission.id,"Sistem · Görevler").is_empty():next.claimed[mission.id]=true
		if save_wallet(null,null,next,pending):career.state=next;inbox.state=pending
	running=false;last_result={"title":title,"kills":kills,"health":health,"stats":match_stats.duplicate(),"hunt":hunt.active,"wins":hunt.wins,"losses":hunt.losses,"winner":match_rules.winner,"victory":match_rules.winner==local_room.get("team","blue") if match_rules.enabled else team_score(local_room.get("team","blue"))>=target_score()}
	open_interface("result")

func announce(text):
	message.text = text
	message_clock = 1.6

func update_hud():
	if not hud_label:
		return
	hud_label.text = "WOLF ROGUE BLOOD · %s\n%s\nNakit %s  ·  KP %s\nAltın %d  ·  GP %d" % ["KURT" if player.is_wolf else "İNSAN", profile_name, wallet_text("cash"), wallet_text("kp"), int(wallet.gold), int(wallet.gp)]
	if exploring:
		hud_label.text = "WOLF ROGUE BLOOD · %s\nHARİTA GEZİNTİSİ · Maç kuralları kapalı\n%s" % [preview_name, "KURT" if player.is_wolf else "İNSAN"]
	if is_instance_valid(source_hud): source_hud.refresh_from_game()

func load_wallet(path = ""):
	if test_mode:
		return
	if path == "": path = wallet_storage_path
	if FileAccess.file_exists(path):
		var result = AtomicStore.read_json(path)
		wallet_save_blocked = not result.ok
		var stored = result.data
		if stored.has("localBoxes"):
			if boxes.valid_state(stored.localBoxes):boxes.state=stored.localBoxes
			else:wallet_save_blocked=true
		if stored.has("localCareer"):
			if career.valid(stored.localCareer):career.state=stored.localCareer
			else:wallet_save_blocked=true
		if stored.has("giftInbox"):
			if inbox.valid(stored.giftInbox):inbox.state=stored.giftInbox
			else:wallet_save_blocked=true
		if stored is Dictionary:
			for key in wallet:
				var amount = stored.get(key, 0)
				if (amount is int or amount is float) and is_finite(float(amount)): wallet[key] = clampi(int(amount), 0, 1000000000)

func save_wallet(candidate = null,box_candidate=null,career_candidate=null,inbox_candidate=null):
	if test_mode: return true
	if wallet_save_blocked: return false
	if candidate == null: candidate = wallet
	var payload=candidate.duplicate(true)
	normalize_unlimited_wallet(payload)
	payload.localBoxes=boxes.state if box_candidate==null else box_candidate
	payload.localCareer=career.state if career_candidate==null else career_candidate
	payload.giftInbox=inbox.state if inbox_candidate==null else inbox_candidate
	return AtomicStore.write_json(wallet_storage_path,payload)

func box_action(action,id,request):
	if remote_player!="":return {"ok":false,"error":"Kutular yalnızca bu cihazdaki yerel bakiye ile kullanılır."}
	var funds=wallet.duplicate();normalize_unlimited_wallet(funds)
	var result=boxes.prepare(action,id,request,funds)
	if not result.ok or result.get("duplicate",false):return result
	normalize_unlimited_wallet(result.wallet)
	var pending=inbox.state.duplicate(true)
	if action=="buy":
		result.state.counts[id]=int(result.state.counts.get(id,0))-1
		if inbox.enqueue(pending,"box",id,boxes.box(id).name,1,"purchase-"+request,"Mağaza").is_empty():return {"ok":false,"error":"Hediye kutusu dolu."}
	elif action=="open":pending.entitlements[result.reward.rewardId]=true
	if not save_wallet(result.wallet,result.state,null,pending):return {"ok":false,"error":"Kayıt başarısız; bakiye ve kutu değiştirilmedi."}
	wallet=result.wallet;boxes.state=result.state;inbox.state=pending;sync_collection();update_hud();return result

func claim_career(id):
	if remote_player!="":return {"ok":false,"error":"Yerel ödüller yalnızca bu cihazda kullanılır."}
	var result=career.claim(id,wallet)
	if not result.ok:return result
	var pending=inbox.state.duplicate(true);var amount=int(result.rewardCash)
	if inbox.enqueue(pending,"cash","cash","Yerel ödül · "+id,amount,"career-"+id,"Sistem").is_empty():return {"ok":false,"error":"Hediye kutusu dolu."}
	if not save_wallet(null,null,result.state,pending):return {"ok":false,"error":"Ödül kaydedilemedi; bakiye değiştirilmedi."}
	career.state=result.state;inbox.state=pending;update_hud();return {"ok":true,"delivery":"giftInbox"}

func power_item(id):
	for item in power_catalog.items:
		if item_key(item.id)==item_key(id):return item
	if item_key(id)=="19601":
		var item=equipment.rules.items[0].duplicate(true);item.id="19601";item.slot="ability";item.category="other";item.consumable=false;item.mobileTuning={};return item
	return {}
func power_bonus(slot,key,fallback):
	var item=power_item(inbox.state.powerSlots.get(slot,""))
	return item.get("mobileTuning",{}).get(key,fallback)
func max_health():return roundi(float(mutations.profile(player.mutation_id).health)*(1.0+float(gear_stats().healthPercent)/100.0)) if player.is_wolf else 100
func wolf_damage_multiplier():return float(booster_tuning.get("damageMultiplier",1.0)) if booster_remaining>0 else 1.0
func wolf_speed_multiplier():return (float(booster_tuning.get("speedMultiplier",1.0)) if booster_remaining>0 else 1.0)*(1.0+float(gear_stats().speedPercent)/100.0)
func gear_stats():
	var stats=book.tattoo_bonuses() if book!=null else {"rangePercent":0,"damagePercent":0,"healthPercent":0,"speedPercent":0,"gpPercent":0,"goldPercent":0}
	for key in ["rangePercent","damagePercent"]:stats[key]+=float(power_bonus("claw",key,0))
	return stats
func seed_gifts():
	if book!=null and book.offline_edition:return
	if inbox.state.get("welcome",false):return
	var pending=inbox.state.duplicate(true)
	inbox.enqueue(pending,"power","19002",power_item("19002").name,3,"welcome-medical","Sistem · Başlangıç")
	inbox.enqueue(pending,"power","19502",power_item("19502").name,3,"welcome-energy","Sistem · Başlangıç")
	pending.welcome=true
	if save_wallet(null,null,null,pending):inbox.state=pending
func accept_gift(id):
	if remote_player!="":return {"ok":false,"error":"Yalnızca yerel hediyeler kullanılabilir."}
	var pending=inbox.state.duplicate(true);var matches=pending.messages.filter(func(row):return row.id==id)
	if matches.size()!=1:return {"ok":false,"error":"Hediye bulunamadı."}
	var gift=matches[0]
	if gift.status!="pending" or gift.expires<Time.get_unix_time_from_system():return {"ok":false,"error":"Hediye alınmış veya süresi dolmuş."}
	var balance=wallet.duplicate();var box_state=boxes.state.duplicate(true)
	match gift.kind:
		"cash":
			if is_unlimited_currency("cash"):balance.cash=1000000000
			else:
				if int(balance.cash)+int(gift.amount)>1000000000:return {"ok":false,"error":"Bakiye sınırı dolu; hediye korunuyor."}
				balance.cash=int(balance.cash)+int(gift.amount)
		"box":
			if boxes.box(gift.item).is_empty() or int(box_state.counts.get(gift.item,0))+int(gift.amount)>999:return {"ok":false,"error":"Kutu aktarımı kullanılamıyor."}
			box_state.counts[gift.item]=int(box_state.counts.get(gift.item,0))+int(gift.amount)
		"power":
			if power_item(gift.item).is_empty():return {"ok":false,"error":"Güç eşyası bulunamadı."}
			if int(pending.powerCounts.get(gift.item,0))+int(gift.amount)>999999:return {"ok":false,"error":"Envanter sınırı dolu; hediye korunuyor."}
			pending.powerCounts[gift.item]=int(pending.powerCounts.get(gift.item,0))+int(gift.amount)
		"weapon":
			if book.weapon(gift.item).get("available",false)!=true:return {"ok":false,"error":"Silah bulunamadı."}
			pending.entitlements[gift.item]=true
		"character":
			if not book.characters.any(func(row):return row.id==gift.item and row.get("available",false)):return {"ok":false,"error":"Karakter bulunamadı."}
			pending.entitlements[gift.item]=true
		"tattoo":
			if not book.tattoos.any(func(row):return row.id==gift.item and row.role!="unknown"):return {"ok":false,"error":"Dövme bölgesi doğrulanmadı."}
			pending.entitlements[gift.item]=true
		_:return {"ok":false,"error":"Hediye türü desteklenmiyor."}
	gift.status="accepted";gift.acceptedAt=Time.get_unix_time_from_system()
	if not save_wallet(balance,box_state,null,pending):return {"ok":false,"error":"Aktarım kaydedilemedi; hediye korunuyor."}
	wallet=balance;boxes.state=box_state;inbox.state=pending;sync_collection();update_hud();return {"ok":true}
func buy_power(id,request):
	if book!=null and book.offline_edition:
		var offers=shop_offers(id)
		if offers.is_empty():return {"ok":false,"error":"Kaynak fiyatı doğrulanmadı."}
		return buy_shop(id,offers[0].currency,request)
	if remote_player!="" or not request is String or request.is_empty() or request.length()>160:return {"ok":false,"error":"Yerel işlem gerekli."}
	var item=power_item(id)
	if inbox.state.messages.any(func(row):return row.sourceKey=="power-buy-"+request):return {"ok":true,"duplicate":true}
	if item.is_empty() or wallet.cash<int(item.localPrice):return {"ok":false,"error":"Yerel nakit yetersiz."}
	var pending=inbox.state.duplicate(true);var balance=wallet.duplicate();balance.cash-=int(item.localPrice)
	if inbox.enqueue(pending,"power",str(id),item.name,1,"power-buy-"+request,"Mağaza").is_empty():return {"ok":false,"error":"Hediye kutusu dolu."}
	if not save_wallet(balance,null,null,pending):return {"ok":false,"error":"Alışveriş kaydedilemedi."}
	wallet=balance;inbox.state=pending;return {"ok":true}
func equip_power_item(id):
	if remote_player!="":return false
	var item=power_item(id)
	if item.is_empty():return false
	if int(inbox.state.powerCounts.get(item_key(id),0))<=0:return false
	if item.slot=="ability":return equipment.equip_power(19601)
	var pending=inbox.state.duplicate(true);pending.powerSlots[item.slot]=str(id)
	if not save_wallet(null,null,null,pending):return false
	inbox.state=pending;return true
func use_power(slot):
	if not is_combat_active() or not player.is_wolf:return false
	var item=power_item(inbox.state.powerSlots.get(slot,""))
	if item.is_empty() or not item.consumable or int(inbox.state.powerCounts.get(item.id,0))<1:return false
	var cost=0
	if slot=="support":
		if health>=max_health() or int(healing_uses.get(item.id,0))>=int(item.mobileTuning.usesPerRound):return false
	elif slot=="energy":
		if booster_remaining>0:return false
		cost=maxi(1,ceili(health*float(item.mobileTuning.healthCostFraction)))
		if health<=cost:return false
	else:return false
	var pending=inbox.state.duplicate(true);pending.powerCounts[item.id]=int(pending.powerCounts[item.id])-1
	if not save_wallet(null,null,null,pending):return false
	inbox.state=pending
	if slot=="support":health=mini(max_health(),health+int(item.mobileTuning.heal));healing_uses[item.id]=int(healing_uses.get(item.id,0))+1
	else:health-=cost;booster_tuning=item.mobileTuning;booster_remaining=float(item.mobileTuning.seconds)
	update_hud();return true

func grant_money(currency, amount, reason):
	if not wallet.has(currency) or not valid_balance(amount) or amount < 1 or amount > 1000000:
		return false
	amount=int(amount)
	if remote_player != "" and not OS.has_feature("android"):
		grant_queue.append({"playerId": remote_player, "currency": currency, "amount": amount, "reason": reason, "requestId": "godot-%s-%s" % [Time.get_ticks_usec(), randi()]})
	else:
		var candidate = wallet.duplicate()
		candidate[currency] = mini(1000000000, int(wallet[currency]) + amount)
		if not save_wallet(candidate):
			announce("Bakiye kaydedilemedi; işlem uygulanmadı.")
			return false
		wallet.merge(candidate, true)
	update_hud()
	return true

func on_poll(_result, code, _headers, body):
	if _result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var state = JSON.parse_string(body.get_string_from_utf8())
	if not state is Dictionary or not state.get("players") is Array or state.players.is_empty():
		return
	var entry = state.players[0]
	if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or not entry.get("name") is String:return
	if not state.get("token") is String or state.token.is_empty():return
	var candidate={}
	for key in wallet:
		var amount=entry.get(key)
		if not valid_balance(amount):return
		candidate[key]=int(amount)
	remote_player=entry.id;remote_token=state.token;profile_name=entry.name+" · PC paneli";wallet.merge(candidate,true)
	update_hud()

func valid_balance(value):
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=1000000000 and value==floor(float(value))

func on_grant(_result, code, _headers, body):
	grant_busy = false
	if grant_queue.is_empty():
		return
	var grant = grant_queue.pop_front()
	var result=JSON.parse_string(body.get_string_from_utf8()) if _result==HTTPRequest.RESULT_SUCCESS and code==200 else null
	var valid=result is Dictionary and result.get("request_id")==grant.requestId and result.get("player_id")==grant.playerId and result.get("currency")==grant.currency and result.get("amount")==grant.amount and valid_balance(result.get("balance_after"))
	if valid:wallet[grant.currency]=int(result.balance_after)
	else:
		announce("PC paneli işlemi doğrulanamadı. Otomatik tekrar verilmedi.")
	update_hud()

func show_admin():
	open_interface("admin")

func show_inventory():
	open_interface("power")

func equip_item_from_ui(item,target_slot=""):
	if not book.owned.get(item.get("id",""),false):return false
	var prepared=player.prepare_library_weapon(item)
	if prepared.is_empty():return false
	if not book.equip(item.id,target_slot):prepared.model.free();return false
	activate_prepared_weapon(item,prepared)
	current_loadout_slot=target_slot if target_slot!="" else book.slot_for(item.category)
	return true

func item_key(value):
	var key=str(value)
	return key.trim_suffix(".0") if key.ends_with(".0") and key.trim_suffix(".0").is_valid_int() else key
func shop_offers(id):return shop_catalog.items.get(item_key(id),{}).get("offers",[])
func collection_owned(id):
	var key=item_key(id)
	if shop_catalog.items.get(key,{}).get("kind","")=="power":return int(inbox.state.powerCounts.get(key,0))>0
	return book.owns(key)
func sync_collection():
	if book==null or not book.offline_edition:return
	var pending=inbox.state.duplicate(true);var changed=false
	var balance=wallet.duplicate();normalize_unlimited_wallet(balance)
	# Previously revealed, validated box rewards are real acquisitions too.
	for reward in boxes.state.history:
		if not pending.entitlements.has(reward.rewardId):pending.entitlements[reward.rewardId]=true;changed=true
	if not inbox.state.get("starter017",false):
		# Explicit offline starter allowance: one item per power slot, never
		# the complete asset catalogue. Existing claimed supplies are retained.
		for id in ["19001","19501","13006","16011","19601"]:
			pending.powerCounts[id]=maxi(1,int(pending.powerCounts.get(id,0)))
		pending.starter017=true;changed=true
	if (changed or balance!=wallet) and save_wallet(balance,null,null,pending):inbox.state=pending;wallet=balance
	book.apply_entitlements(inbox.state.entitlements)
	equipment.owned=[19601] if int(inbox.state.powerCounts.get("19601",0))>0 else []
	if not 19601 in equipment.owned:equipment.power_slot=0
	for slot in inbox.state.powerSlots.keys():
		if int(inbox.state.powerCounts.get(inbox.state.powerSlots[slot],0))<=0:inbox.state.powerSlots.erase(slot)
func buy_shop(id,currency,request):
	if remote_player!="" or not request is String or request.is_empty() or request.length()>160:return {"ok":false,"error":"Yerel işlem gerekli."}
	var key=item_key(id);var row=shop_catalog.items.get(key,{})
	var source_key="shop-017-"+request
	if inbox.state.messages.any(func(message):return message.sourceKey==source_key):return {"ok":true,"duplicate":true}
	if row.is_empty():return {"ok":false,"error":"Eşya mağazada bulunamadı."}
	var offers=row.offers.filter(func(offer):return offer.currency==currency)
	if offers.size()!=1 or not wallet.has(currency):return {"ok":false,"error":"Bu para biriminde doğrulanmış fiyat yok."}
	var price=int(offers[0].price)
	if price<=0 or (not is_unlimited_currency(currency) and int(wallet[currency])<price):return {"ok":false,"error":"Bakiye yetersiz."}
	var item={}
	match row.kind:
		"weapon":item=book.weapon(key)
		"character":
			for entry in book.characters:
				if entry.id==key and entry.get("available",false):item=entry;break
		"tattoo":
			for entry in book.tattoos:
				if entry.id==key:item=entry;break
		"power":item=power_item(key)
	if item.is_empty() or item.get("available",true)!=true:return {"ok":false,"error":"Eşya kullanıma hazır değil."}
	if row.kind!="power" and collection_owned(key):return {"ok":false,"error":"Bu eşya zaten envanterde."}
	if row.kind!="power" and inbox.state.messages.any(func(message):return message.item==key and message.status=="pending" and message.expires>=Time.get_unix_time_from_system()):return {"ok":false,"error":"Eşya hediye kutusunda alınmayı bekliyor."}
	var pending=inbox.state.duplicate(true);var balance=wallet.duplicate();normalize_unlimited_wallet(balance)
	if not is_unlimited_currency(currency):balance[currency]-=price
	if inbox.enqueue(pending,row.kind,key,item.name,1,source_key,"Mağaza").is_empty():return {"ok":false,"error":"Hediye kutusu dolu."}
	if not save_wallet(balance,null,null,pending):return {"ok":false,"error":"Alışveriş kaydedilemedi; bakiye korunuyor."}
	wallet=balance;inbox.state=pending;update_hud();return {"ok":true,"delivery":"giftInbox"}

func is_unlimited_currency(currency):
	return remote_player=="" and book!=null and book.offline_edition and currency in shop_catalog.get("currencyPolicy",{}).get("unlimited",[])
func normalize_unlimited_wallet(candidate):
	for currency in ["cash","kp"]:
		if is_unlimited_currency(currency):candidate[currency]=1000000000
func wallet_text(currency):return "∞" if is_unlimited_currency(currency) else str(int(wallet.get(currency,0)))
