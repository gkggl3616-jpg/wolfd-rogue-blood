extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const TouchScript = preload("res://scripts/touch.gd")
const MapCatalogScript = preload("res://scripts/map_catalog.gd")
const EquipmentScript = preload("res://scripts/equipment.gd")
const ContentBook = preload("res://scripts/content_book.gd")
const LibraryMenu = preload("res://scripts/library_menu.gd")
const GrenadeScript = preload("res://scripts/grenade.gd")
const PcLayout = preload("res://scripts/pc_layout.gd")
const PcHud = preload("res://scripts/pc_hud.gd")
const Lobby = preload("res://scripts/lobby.gd")
const FrontScreens = preload("res://scripts/front_screens.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const LauncherScreen = preload("res://scripts/launcher_screen.gd")
const AtomicStore = preload("res://scripts/atomic_store.gd")
const MapAudio = preload("res://scripts/map_audio.gd")
var book
var current_weapon_id = "legacy-ak47"
var weapon_ammo = {}
var library_panel: Control
var pc_panel: Control
var source_hud: Control
var game_audio
var equipment
var map_catalog
var mode_picker: OptionButton
var map_picker: OptionButton
var map_status: Label
var map_start: Button
var map_preview: Button
var arena_root: Node3D
var active_map: Node3D
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
var kills = 0
var time_left = 90.0
var spawn_clock = 0.0
var enemies: Node3D
var hud_label: Label
var message: Label
var message_clock = 0.0
var overlay: PanelContainer
var overlay_box: VBoxContainer
var crosshair: Label
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
var menu_backdrop: ColorRect
var transient_effects: Node3D

func _ready():
	book = ContentBook.new( not test_mode)
	game_audio = Node.new();game_audio.set_script(GameAudio);game_audio.game = self;add_child(game_audio)
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
	build_world()
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.game = self
	player.position = Vector3(0, 0.05, 8)
	add_child(player)
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

func label(text, size = 20):
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func build_ui():
	var layer = CanvasLayer.new()
	add_child(layer)
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud_label = label("", 20)
	hud_label.position = Vector2(28, 18)
	hud_label.size = Vector2(500, 110);hud_label.clip_text = true
	root.add_child(hud_label)
	message = label("", 24)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message.position = Vector2(-320, 96)
	message.size = Vector2(640, 40)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message)
	crosshair = label("＋", 30)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(15, 20)
	root.add_child(crosshair)
	source_hud = Control.new();source_hud.set_script(PcHud);source_hud.game = self;root.add_child(source_hud)
	var admin = Button.new()
	admin.text = "YÖNETİCİ"
	admin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	admin.position = Vector2(-165, 18)
	admin.size = Vector2(140, 44)
	admin.pressed.connect(show_admin)
	root.add_child(admin)
	gui_touch_blockers.append(admin)
	var inventory_button = Button.new()
	inventory_button.text = "ENVANTER"
	inventory_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inventory_button.position = Vector2(-165, 70)
	inventory_button.size = Vector2(140, 44)
	inventory_button.pressed.connect( func(): show_library("Envanter"))
	root.add_child(inventory_button)
	gui_touch_blockers.append(inventory_button)
	var slots = HBoxContainer.new();slots.position = Vector2(610, 115);slots.add_theme_constant_override("separation", 6);root.add_child(slots)
	gui_touch_blockers.append(slots)
	for pair in [["ANA", "primary"], ["TAB.", "pistol"], ["BIÇAK", "knife"], ["BOMBA", "grenade"]]:
		var button = Button.new();button.text = pair[0];button.custom_minimum_size = Vector2(75, 44);button.pressed.connect( func(): equip_slot(pair[1]));slots.add_child(button)
	var pause_button = Button.new()
	pause_button.text = "II"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-222, 18)
	pause_button.size = Vector2(45, 44)
	pause_button.pressed.connect(pause_game)
	root.add_child(pause_button)
	gui_touch_blockers.append(pause_button)
	touch = Node2D.new()
	touch.set_script(TouchScript)
	touch.game = self
	layer.add_child(touch)
	menu_backdrop = ColorRect.new()
	menu_backdrop.color = Color("0a0d12")
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu_backdrop)
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.position = Vector2(-280, -245)
	overlay.size = Vector2(560, 490)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.11, 0.96)
	style.set_corner_radius_all(16)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	overlay.add_theme_stylebox_override("panel", style)
	root.add_child(overlay)
	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 14)
	overlay.add_child(overlay_box)

func center_overlay(dimensions):
	overlay.offset_left = - dimensions.x / 2.0
	overlay.offset_right = dimensions.x / 2.0
	overlay.offset_top = - dimensions.y / 2.0
	overlay.offset_bottom = dimensions.y / 2.0

func clear_overlay():
	if is_instance_valid(player) and is_instance_valid(player.roar_effect): player.roar_effect.stop()
	clear_pc_panel()
	if is_instance_valid(library_panel): library_panel.queue_free();library_panel = null
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

func menu_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 50
	button.pressed.connect(callback)
	overlay_box.add_child(button)
	return button

func show_menu(title, text, button, callback):
	clear_overlay()
	overlay_box.add_child(label(title, 30))
	var body = label(text, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(480, 100)
	overlay_box.add_child(body)
	menu_button(button, callback)
	var help = label("PC: WASD · Space zıpla · Ctrl eğil · Shift koş\n3 dönüşüm · Fare ateş / nişan · R şarjör / kükreme\nİnsan: birinci şahıs · Kurt: üçüncü şahıs\nF10 yönetici · Esc duraklat", 15)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_box.add_child(help)
	menu_button("Mod ve harita listesi", show_maps)
	menu_button("Envanter · Kurt yeteneği", show_inventory)
	menu_button("Mağaza · Envanter · Karakterler · Ayarlar", show_library)
	center_overlay(Vector2(560, 640))

func show_library(initial_page = "Mağaza"):
	if is_instance_valid(library_panel): library_panel.close_menu();return
	clear_overlay();overlay.hide()
	var panel = PanelContainer.new();panel.set_script(LibraryMenu);panel.game = self;panel.page = initial_page;library_panel = panel;overlay.get_parent().add_child(panel)

func apply_settings():
	if not is_instance_valid(touch): return
	touch.direction_buttons = bool(book.settings.directions)
	game_audio.apply_settings()
	for light in find_children("*", "DirectionalLight3D", true, false): light.shadow_enabled = bool(book.settings.shadows)
	if not test_mode: Engine.max_fps = int(book.settings.fps)

func equip_library_weapon(item):
	if not book.owned.get(item.id, false): return false
	weapon_ammo[current_weapon_id] = {"ammo": ammo, "reserve": reserve}
	if not player.equip_library_weapon(item): return false
	current_weapon_id = item.id
	var stored = weapon_ammo.get(item.id, {"ammo": weapon_capacity(), "reserve": weapon_capacity() * 4})
	ammo = int(stored.ammo);reserve = int(stored.reserve);reloading = 0;update_hud();return true

func select_library_character(entry):
	if entry.get("available") != true: return false
	if not book.choose_character(entry.id): announce("Karakter seçimi kaydedilemedi.");return false
	character_info = entry;player.load_character(entry);return true

func weapon_capacity():
	return int(player.weapon_info.get("shotsPerClip", 30))

func equip_slot(slot):
	var item = book.weapon(book.slots.get(slot, ""))
	if not item.is_empty(): equip_library_weapon(item)

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
	if not fx.is_empty(): play_source_effect(fx, where)
	if kind == "smoke": return
	for enemy in enemies.get_children():
		var distance = enemy.global_position.distance_to(where)
		if distance > 6: continue
		var query = PhysicsRayQueryParameters3D.create(where + Vector3.UP * 0.1, enemy.global_position + Vector3.UP, 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): enemy.damage(int(amount * (1 - distance / 6)))

func show_home():
	running = false;clear_overlay();overlay.hide()
	pc_panel = PanelContainer.new();pc_panel.set_script(Lobby);pc_panel.game = self;overlay.get_parent().add_child(pc_panel)

func show_front_screen(page):
	if page not in ["entry", "servers", "events"]: return
	running = false;clear_overlay();overlay.hide()
	pc_panel = Control.new();pc_panel.set_script(FrontScreens);pc_panel.game = self;pc_panel.page = page;overlay.get_parent().add_child(pc_panel)

func show_launcher():
	running = false;clear_overlay();overlay.hide()
	pc_panel = Control.new();pc_panel.set_script(LauncherScreen);pc_panel.game = self;overlay.get_parent().add_child(pc_panel)

func show_maps():
	clear_overlay()
	center_overlay(Vector2(560, 660))
	overlay_box.add_child(label("MOD VE HARİTALAR", 26))
	overlay_box.add_child(label("19 seçim · 18 doğrulanmış mod eşleşmesi", 16))
	mode_picker = OptionButton.new()
	mode_picker.custom_minimum_size.y = 44
	mode_picker.fit_to_longest_item = false
	for mode in map_catalog.data.modes:
		mode_picker.add_item(mode.sourceName, int(mode.id))
	overlay_box.add_child(mode_picker)
	map_picker = OptionButton.new()
	map_picker.custom_minimum_size.y = 44
	map_picker.fit_to_longest_item = false
	overlay_box.add_child(map_picker)
	map_status = label("", 16)
	map_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_status.custom_minimum_size = Vector2(480, 96)
	overlay_box.add_child(map_status)
	map_start = menu_button("Haritayı başlat", start_selected_map)
	map_preview = menu_button("Haritayı gez · Önizleme", start_map_preview)
	mode_picker.item_selected.connect( func(_index): refresh_mode_maps())
	map_picker.item_selected.connect( func(_index): refresh_map_status())
	menu_button("Geri", func():
		if running:
			pause_game_menu()
		else:
			show_home()
	)
	refresh_mode_maps()

func refresh_mode_maps():
	map_picker.clear()
	for entry in map_catalog.maps_for_mode(mode_picker.get_selected_id()):
		map_picker.add_item("%d · %s" % [int(entry.number), entry.displayName], int(entry.number))
	refresh_map_status()

func refresh_map_status():
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
	var record = map_catalog.preview_record(mode_picker.get_selected_id(), map_picker.get_selected_id())
	if record.is_empty():
		return
	var asset = record.previewAsset
	if FileAccess.file_exists(asset) and FileAccess.get_sha256(asset) != record.sha256:
		map_status.text = "Harita dosyası değişmiş; doğrulama gerekiyor."
		return
	running = false
	clear_projectiles()
	for enemy in enemies.get_children():
		enemy.queue_free()
	if is_instance_valid(active_map):
		remove_child(active_map)
		active_map.queue_free()
	active_map = load(asset).instantiate()
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

	get_tree().change_scene_to_file(map_catalog.map_record(map_number).asset)

func pause_game_menu():
	clear_overlay();overlay.hide()
	pc_panel = Control.new();pc_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.get_parent().add_child(pc_panel)
	var shade = ColorRect.new();shade.color = Color(0, 0, 0, 0.75);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);pc_panel.add_child(shade)
	var layout = Control.new();layout.set_script(PcLayout);pc_panel.add_child(layout);layout.configure("interface/gamemenu", Vector2(400, 377))
	var fit = func():
		var viewport_size = get_viewport().get_visible_rect().size
		var factor = minf((viewport_size.x - 40) / 400.0, (viewport_size.y - 40) / 377.0)
		layout.scale = Vector2.ONE * factor;layout.position = (viewport_size - Vector2(400, 377) * factor) * 0.5
	fit.call();pc_panel.resized.connect(fit)
	layout.bind_action("ExitButton", resume);layout.bind_action("GameComeBack", resume)
	layout.bind_action("Option", func(): show_library("Ayarlar"))
	layout.bind_action("GameExit", func(): running = false;show_home())
	if OS.has_feature("android"):

		var close = Button.new();close.text = "×";close.position = Vector2(350, 0);close.size = Vector2(50, 44);close.pressed.connect(resume);layout.add_child(close)

func clear_pc_panel():
	if is_instance_valid(pc_panel):
		pc_panel.get_parent().remove_child(pc_panel);pc_panel.queue_free();pc_panel = null

func resume():
	if application_suspended: return
	clear_pc_panel()
	menu_open = false
	overlay.hide()
	if not OS.has_feature("android") and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear_projectiles():
	if is_instance_valid(transient_effects):
		for effect in transient_effects.get_children():
			transient_effects.remove_child(effect)
			effect.queue_free()
	for node in get_children():
		if node.get_script() == GrenadeScript:
			remove_child(node)
			node.queue_free()

func start_round():
	if is_instance_valid(player.roar_effect): player.roar_effect.stop()
	clear_projectiles()
	exploring = false
	if is_instance_valid(active_map):
		remove_child(active_map)
		active_map.queue_free()
	set_arena_active(true)
	for enemy in enemies.get_children():
		enemy.queue_free()
	health = 100
	ammo = weapon_capacity()
	reserve = ammo * 4
	weapon_ammo.clear()
	kills = 0
	time_left = 90
	reloading = 0
	player.position = Vector3(0, 0.1, 8)
	player.velocity = Vector3.ZERO
	player.reset_locomotion()
	player.yaw = 0
	player.rotation = Vector3.ZERO
	running = true
	resume()
	spawn_clock = 0
	announce("10 hedef · 90 saniye")
	update_hud()

func pause_game():
	if is_instance_valid(library_panel): library_panel.close_menu();return
	if not running:
		return
	if menu_open:
		resume()
	else:
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
	if event is InputEventKey and event.pressed and not event.echo and not menu_open:
		var keys = {KEY_1: "primary", KEY_2: "pistol", KEY_4: "grenade", KEY_5: "knife"}
		if keys.has(event.physical_keycode): equip_slot(keys[event.physical_keycode])
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
	if is_instance_valid(menu_backdrop): menu_backdrop.visible = menu_open
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
	time_left -= delta
	spawn_clock -= delta
	if spawn_clock <= 0 and enemies.get_child_count() < 4:
		spawn_enemy()
		spawn_clock = 3.5
	if time_left <= 0:
		end_round("Süre doldu")
	update_hud()

func spawn_enemy():
	var points = [Vector3(-10, 0.1, -10), Vector3(10, 0.1, -10), Vector3(0, 0.1, -18), Vector3(-15, 0.1, 10), Vector3(15, 0.1, 10)]
	var enemy = CharacterBody3D.new()
	enemy.set_script(EnemyScript)
	enemy.game = self
	enemy.position = points.pick_random()
	enemies.add_child(enemy)

func attack():
	if application_suspended: return
	if player.rolling or player.wall_holding: return
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
	player.play_clip("attack")
	if player.is_wolf:
		var body_attack = player.wolf_running and equipment.has_wolf_ability()
		if body_attack:
			player.play_clip("body_attack")
			player.wolf_running = false
		for enemy in enemies.get_children():
			var offset = enemy.global_position - player.global_position
			if offset.length() < 2.8 and offset.normalized().dot( - player.global_basis.z) > 0.1:
				var query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, enemy.global_position + Vector3.UP, 3, [player.get_rid()])
				var hit = get_world_3d().direct_space_state.intersect_ray(query)
				if hit and hit.collider == enemy:
					enemy.damage(65 if body_attack else 45)
					announce("Vücut saldırısı" if body_attack else "Pençe isabeti")
		return
	if kind != "knife": ammo -= 1
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
		if hit.collider.has_meta("enemy"):
			var damage = int(player.weapon_info.get("damage", 25));hit.collider.damage(damage)
			announce("İsabet +%d" % damage)
	var flash = OmniLight3D.new()
	flash.position = player.global_position + Vector3(0, 1.4, 0)
	flash.light_color = Color("ffc77f")
	flash.light_energy = 2
	flash.omni_range = 3
	transient_effects.add_child(flash)
	get_tree().create_timer(0.06).timeout.connect(flash.queue_free)

func reload_weapon():
	if not running or menu_open:
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

func enemy_defeated():
	kills += 1
	grant_money("cash", 25, "Arena hedef ödülü")
	grant_money("gp", 10, "Arena gelişim ödülü")
	if kills >= 10:
		grant_money("gold", 10, "Arena tamamlandı")
		end_round("Arena tamamlandı")
	update_hud()

func take_damage(amount):
	if not running:
		return
	health = maxi(0, health - amount)
	if health == 0:
		end_round("Yenildin")

func end_round(title):
	running = false
	show_menu(title, "Etkisiz hale getirilen hedef: %d / 10\nKazandığın yerel bakiyeler korunur." % kills, "Yeniden dene", start_round)

func announce(text):
	message.text = text
	message_clock = 1.6

func update_hud():
	if not hud_label:
		return
	hud_label.text = "WOLF ROGUE BLOOD · %s\n%s\nNakit %d  ·  KP %d\nAltın %d  ·  GP %d" % ["KURT" if player.is_wolf else "İNSAN", profile_name, int(wallet.cash), int(wallet.kp), int(wallet.gold), int(wallet.gp)]
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
		if stored is Dictionary:
			for key in wallet:
				var amount = stored.get(key, 0)
				if (amount is int or amount is float) and is_finite(float(amount)): wallet[key] = clampi(int(amount), 0, 1000000000)

func save_wallet(candidate = null):
	if test_mode: return true
	if wallet_save_blocked: return false
	if candidate == null: candidate = wallet
	return AtomicStore.write_json(wallet_storage_path, candidate)

func grant_money(currency, amount, reason):
	if not wallet.has(currency) or amount <= 0 or amount > 1000000:
		return false
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
	if code != 200:
		return
	var state = JSON.parse_string(body.get_string_from_utf8())
	if not state is Dictionary or not state.get("players") is Array or state.players.is_empty():
		return
	var entry = state.players[0]
	remote_player = entry.id
	remote_token = state.token
	profile_name = entry.name + " · PC paneli"
	for key in wallet:
		wallet[key] = int(entry.get(key, 0))
	update_hud()

func on_grant(_result, code, _headers, body):
	grant_busy = false
	if grant_queue.is_empty():
		return
	var grant = grant_queue.pop_front()
	if code == 200:
		var result = JSON.parse_string(body.get_string_from_utf8())
		if result is Dictionary:
			wallet[grant.currency] = int(result.get("balance_after", wallet[grant.currency]))
	else:
		announce("PC paneli işlemi doğrulanamadı. Otomatik tekrar verilmedi.")
	update_hud()

func show_admin():
	clear_overlay()
	overlay_box.add_child(label("YEREL YÖNETİCİ", 28))
	overlay_box.add_child(label("Profil: " + profile_name, 17))
	var description = label("PC’de localhost panelindeki ilk oyuncuya bağlıdır.\nAndroid’de yalnızca bu cihazdaki yerel kayıt değişir.", 15)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_box.add_child(description)
	var kind = OptionButton.new()
	for text in ["Nakit", "KP", "Altın", "GP · Gelişim puanı"]:
		kind.add_item(text)
	overlay_box.add_child(kind)
	var amount = SpinBox.new()
	amount.min_value = 1
	amount.max_value = 1000000
	amount.value = 1000
	amount.step = 1
	overlay_box.add_child(amount)
	menu_button("Bakiyeyi ekle", func():
		if grant_money(["cash", "kp", "gold", "gp"][kind.selected], int(amount.value), "Godot yerel yönetici"):
			announce("Bakiye işlemi gönderildi" if remote_player != "" else "Yerel bakiye kaydedildi")
	)
	menu_button("Kapat", func():
		if running:
			resume()
		else:
			show_home()
	)

func show_inventory():
	clear_overlay()
	center_overlay(Vector2(560, 600))
	overlay_box.add_child(label("ENVANTER · GÜÇ SLOTU", 26))
	var item = equipment.rules.items[0]
	var icon = TextureRect.new()
	icon.texture = load(item.icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(80, 80)
	overlay_box.add_child(icon)
	overlay_box.add_child(label(item.name, 22))
	var description = label("Güç slotundayken kurt formunda ileriye iki kez bas ve tut: dört ayak koşusu. Koşarken ateş: vücut saldırısı. Havada duvara temas ederek koşarken ateş: tutunma (kaynak klibi olan karakterler). İleriyi bırak: ayrıl; ZIPLA: duvardan atla.\nKOŞ normal koşuyu açar/kapatır. Havada güçlü saldırı henüz aktarılmadı. Sayısal değerler yeni mobil ayarlarıdır.", 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(480, 144)
	overlay_box.add_child(description)
	var equip = CheckButton.new()
	equip.text = "Güç slotuna tak"
	equip.button_pressed = equipment.has_wolf_ability()
	equip.toggled.connect( func(enabled):
		if not equipment.equip_power(EquipmentScript.WOLF_ABILITY if enabled else 0):
			equip.set_pressed_no_signal(equipment.has_wolf_ability());announce("Güç slotu kaydedilemedi.")
		player.reset_locomotion()
	)
	overlay_box.add_child(equip)
	var directions = CheckButton.new()
	directions.text = "Hareket için yön düğmelerini kullan"
	directions.button_pressed = touch.direction_buttons
	directions.toggled.connect( func(enabled):
		if book.set_setting("directions", enabled): apply_settings()
		else: directions.set_pressed_no_signal(book.settings.directions);announce("Kontrol ayarı kaydedilemedi.")
		touch.reset()
	)
	overlay_box.add_child(directions)
	menu_button("Kapat", func():
		if running:
			resume()
		else:
			show_home()
	)
