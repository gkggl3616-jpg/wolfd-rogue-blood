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
	if not fx.is_empty(): play_source_effect(fx, where)
	if kind == "smoke": return
	for enemy in enemies.get_children():
		var distance = enemy.global_position.distance_to(where)
		if distance > 6: continue
		var query = PhysicsRayQueryParameters3D.create(where + Vector3.UP * 0.1, enemy.global_position + Vector3.UP, 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): enemy.damage(int(amount * (1 - distance / 6)))

func show_home():
	running=false
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

	get_tree().change_scene_to_file(map_catalog.map_record(map_number).asset)

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
	if not OS.has_feature("android") and DisplayServer.get_name()!="headless":Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

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
	if profile_lock!=null and not profile_lock.unlocked:return false
	if not is_local_mode(int(local_room.get("mode",0))):
		announce("Özgün mod kuralları henüz tamamlanmadı.")
		return false
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
	preview_spawn = Vector3(0, 0.1, 8)
	preview_name = "Eğitim Arenası"
	var spawn_yaw = 0.0
	if not record.is_empty():
		active_map = load(record.previewAsset).instantiate()
		active_map.set_meta("map_number",map_number)
		add_child(active_map)
		for mesh in active_map.find_children("*", "MeshInstance3D", true, false):
			mesh.create_trimesh_collision()
		install_navigation(record.navigation,active_map)
		var ambient = Node3D.new();ambient.set_script(MapAudio);ambient.game = self
		ambient.map_number = map_number;active_map.add_child(ambient)
		var anchor = record.startPoints[0]
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
	kills = 0
	match_serial+=1;match_stats={"attacks":0,"hits":0,"damage":0,"headshots":0};kill_feed.clear()
	match_id=Crypto.new().generate_random_bytes(16).hex_encode()
	hunt.active=int(local_room.get("mode",0))==LocalHunt.MODE
	if hunt.active:hunt.begin(local_room.get("playerForm","human"))
	tutorial.active=int(local_room.get("mode",0))==LocalTutorial.MODE
	time_left = 90
	reloading = 0
	player.position = preview_spawn
	player.velocity = Vector3.ZERO
	player.reset_combat()
	player.yaw = spawn_yaw
	player.rotation = Vector3(0, spawn_yaw, 0)
	running = true
	resume()
	if hunt.active and player.is_wolf!=(hunt.player_form=="wolf"):player.switch_form(true)
	if tutorial.active:
		if player.is_wolf:player.switch_form(true)
		tutorial.begin(player.position,match_stats.attacks)
	spawn_clock = 0
	announce("Kurt Avı · Raunt 1/3" if hunt.active else "10 hedef · 90 saniye")
	update_hud()
	return true

func is_local_mode(value):return value in [0,LocalHunt.MODE,LocalTutorial.MODE]
func is_combat_active():return running and not menu_open and not application_suspended and (not hunt.active or hunt.phase=="combat")
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
		health=100;ammo=weapon_capacity();reserve=ammo*4;weapon_ammo.clear();time_left=LocalHunt.SECONDS
		player.position=preview_spawn;player.velocity=Vector3.ZERO;player.reset_combat();spawn_clock=0
		announce("Kurt Avı · Raunt %d/3" % hunt.round_number)
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
	time_left -= delta
	spawn_clock -= delta
	if spawn_clock <= 0 and enemies.get_child_count() < 4 and (not hunt.active or hunt.spawned<LocalHunt.TARGET):
		if spawn_enemy() and hunt.active:hunt.spawned+=1
		spawn_clock = 3.5
	if time_left <= 0:
		if hunt.active:finish_hunt_round(false)
		else:end_round("Süre doldu")
	update_hud()

func spawn_enemy(kind="",difficulty=""):
	var points = [Vector3(-10, 0.1, -10), Vector3(10, 0.1, -10), Vector3(0, 0.1, -18), Vector3(-15, 0.1, 10), Vector3(15, 0.1, 10)]
	if offline_map_number != 0:
		points = offline_spawn_points()
		if points.is_empty(): return false
	var enemy = CharacterBody3D.new()
	enemy.set_script(EnemyScript)
	enemy.game = self
	enemy.kind=kind if kind in ["human","wolf"] else (hunt.enemy_kind() if hunt.active else ("wolf" if bot_spawn_count%2==0 else "human"))
	enemy.display_name=("İnsan" if enemy.kind=="human" else "Kurt")+" %02d" % (bot_spawn_count+1)
	enemy.difficulty=difficulty if BotRules.LEVELS.has(difficulty) else bot_difficulty
	enemy.position = points.pick_random()
	enemies.add_child(enemy)
	bot_spawn_count+=1
	return true

func notify_bot_noise(point,radius):
	for enemy in enemies.get_children():
		if not enemy.is_queued_for_deletion():enemy.hear_noise(point,radius)

func offline_spawn_points():
	var points = []
	var nav_map = offline_navigation_map
	if not nav_map.is_valid(): return points
	NavigationServer3D.map_force_update(nav_map)
	var origin = NavigationServer3D.map_get_closest_point(nav_map, player.position)
	if origin.distance_to(player.position) > 4.0: return points
	var capsule = CapsuleShape3D.new();capsule.radius = 0.44;capsule.height = 1.9
	var clearance = PhysicsShapeQueryParameters3D.new();clearance.shape = capsule;clearance.collision_mask = 3
	for i in range(48):
		var angle = TAU * float(i % 16) / 16.0
		var radius = 8.0 + 6.0 * int(i / 16)
		var sample = origin + Vector3(cos(angle), 0, sin(angle)) * radius
		var pos = NavigationServer3D.map_get_closest_point(nav_map, sample)
		if pos.distance_to(sample) > 3.0 or pos.distance_to(origin) < 7.0: continue
		if navigation_graph==null or not navigation_graph.connected(origin,pos):continue
		var path = NavigationServer3D.map_get_path(nav_map, origin, pos, true)
		if path.size() < 2 or path[-1].distance_to(pos) > 1.0: continue
		var ray = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 1.5, pos - Vector3.UP * 2.0, 1)
		var floor_hit = get_world_3d().direct_space_state.intersect_ray(ray)
		if floor_hit.is_empty() or floor_hit.normal.y < 0.65: continue
		pos = floor_hit.position + Vector3.UP * 0.12
		clearance.transform = Transform3D(Basis.IDENTITY, pos + Vector3.UP * 0.95)
		if not get_world_3d().direct_space_state.intersect_shape(clearance, 1).is_empty(): continue
		var occupied = false
		for enemy in enemies.get_children():
			if enemy.position.distance_to(pos) < 2.5: occupied = true;break
		if not occupied: points.append(pos)
	return points

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
		wolf_melee_hit(65 if body_attack else 45,2.8,"Vücut saldırısı" if body_attack else "Pençe isabeti")
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
		if hit.collider.has_meta("enemy"):
			var head=kind!="knife" and hit.collider.is_head_hit(hit.position,origin,(end-origin).normalized())
			var damage = int(player.weapon_info.get("damage", 25))*(2 if head else 1)
			var actual=mini(hit.collider.health,damage)
			if head:match_stats.headshots+=1
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
	if not running or menu_open or application_suspended:return
	for enemy in enemies.get_children():
		if not running:break
		var offset=enemy.global_position-player.global_position
		if offset.length()>=reach or offset.normalized().dot(-player.global_basis.z)<=0.1:continue
		var query=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,enemy.global_position+Vector3.UP,3,[player.get_rid()])
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if hit and hit.collider==enemy:
			enemy.damage(amount);announce(caption)
			if is_instance_valid(source_hud):source_hud.feedback.show_hit()

func strong_attack():
	if not running or menu_open or application_suspended:return false
	if player.begin_air_attack():announce("Havada güçlü saldırı");return true
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
	kill_feed.push_front({"attacker":profile_name,"target":context.get("target","Bot"),"weapon":context.get("weapon","Pençe" if player.is_wolf else "Silah"),"headshot":context.get("headshot",false),"remaining":6.0})
	if kill_feed.size()>5:kill_feed.resize(5)
	grant_money("cash", 25, "Arena hedef ödülü")
	grant_money("gp", 10, "Arena gelişim ödülü")
	if hunt.active:
		hunt.round_kills+=1
		if hunt.round_kills>=LocalHunt.TARGET:finish_hunt_round(true)
	elif kills >= 10:
		grant_money("gold", 10, "Arena tamamlandı")
		end_round("Arena tamamlandı")
	update_hud()

func take_damage(amount, source_position=null):
	if not is_combat_active() or amount<=0:
		return
	health = maxi(0, health - amount)
	if is_instance_valid(source_hud):source_hud.feedback.show_damage(source_position)
	if health == 0:
		if hunt.active:finish_hunt_round(false)
		else:end_round("Yenildin")

func end_round(title):
	if not match_id.is_empty() and not match_id in career.state.matches:
		var next=career.result(match_id,kills,match_stats.headshots,hunt.wins if hunt.active else 0,tutorial.active and tutorial.step>=tutorial.STEPS.size())
		if save_wallet(null,null,next):career.state=next
	running=false;last_result={"title":title,"kills":kills,"health":health,"stats":match_stats.duplicate(),"hunt":hunt.active,"wins":hunt.wins,"losses":hunt.losses}
	open_interface("result")

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
		if stored.has("localBoxes"):
			if boxes.valid_state(stored.localBoxes):boxes.state=stored.localBoxes
			else:wallet_save_blocked=true
		if stored.has("localCareer"):
			if career.valid(stored.localCareer):career.state=stored.localCareer
			else:wallet_save_blocked=true
		if stored is Dictionary:
			for key in wallet:
				var amount = stored.get(key, 0)
				if (amount is int or amount is float) and is_finite(float(amount)): wallet[key] = clampi(int(amount), 0, 1000000000)

func save_wallet(candidate = null,box_candidate=null,career_candidate=null):
	if test_mode: return true
	if wallet_save_blocked: return false
	if candidate == null: candidate = wallet
	var payload=candidate.duplicate(true)
	payload.localBoxes=boxes.state if box_candidate==null else box_candidate
	payload.localCareer=career.state if career_candidate==null else career_candidate
	return AtomicStore.write_json(wallet_storage_path,payload)

func box_action(action,id,request):
	if remote_player!="":return {"ok":false,"error":"Kutular yalnızca bu cihazdaki yerel bakiye ile kullanılır."}
	var result=boxes.prepare(action,id,request,wallet)
	if not result.ok or result.get("duplicate",false):return result
	if not save_wallet(result.wallet,result.state):return {"ok":false,"error":"Kayıt başarısız; bakiye ve kutu değiştirilmedi."}
	wallet=result.wallet;boxes.state=result.state;update_hud();return result

func claim_career(id):
	if remote_player!="":return {"ok":false,"error":"Yerel ödüller yalnızca bu cihazda kullanılır."}
	var result=career.claim(id,wallet)
	if not result.ok:return result
	if not save_wallet(result.wallet,null,result.state):return {"ok":false,"error":"Ödül kaydedilemedi; bakiye değiştirilmedi."}
	wallet=result.wallet;career.state=result.state;update_hud();return result

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
