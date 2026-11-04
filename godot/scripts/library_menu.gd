extends PanelContainer
const PcCollection = preload("res://scripts/pc_collection.gd")
const PreviewCamera = preload("res://scripts/preview_camera.gd")

var game
var page = "Mağaza"
var search: LineEdit
var filter: OptionButton
var list: VBoxContainer
var detail: VBoxContainer
var count_label: Label
var offset = 0
var effect_preview: TextureRect
var effect_frames = []
var effect_time = 0.0
var effect_fps = 15.0
var traditional_box: VBoxContainer
var pc_collection: Control
const CATEGORY_NAMES = {"rifle": "Tüfek", "pistol": "Tabanca", "smg": "Hafif makineli", "sniper": "Keskin nişancı", "shotgun": "Pompalı", "machinegun": "Makineli", "heavy": "Ağır silah", "knife": "Bıçak", "grenade": "Bomba", "rocket": "Roket", "launcher": "Bomba atar"}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 20;offset_top = 20;offset_right = -20;offset_bottom = -20
	var style = StyleBoxFlat.new();style.bg_color = Color("101722");style.set_corner_radius_all(12)
	style.content_margin_left = 20;style.content_margin_right = 20;style.content_margin_top = 16;style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new();traditional_box = box;box.add_theme_constant_override("separation", 12);add_child(box)
	var head = HBoxContainer.new();box.add_child(head)
	var title = game.label("WOLF ROGUE BLOOD", 26);title.size_flags_horizontal = Control.SIZE_EXPAND_FILL;head.add_child(title)
	var close = Button.new();close.text = "Kapat";close.pressed.connect(close_menu);head.add_child(close)
	var tabs = HBoxContainer.new();box.add_child(tabs)
	for name in ["Mağaza", "Envanter", "Karakterler", "Dövmeler", "Efektler", "Ayarlar"]:
		var button = Button.new();button.text = name;button.custom_minimum_size.y = 44;button.pressed.connect( func(): page = name;offset = 0;refresh());tabs.add_child(button)
	var power = Button.new();power.text = "Güç slotu";power.pressed.connect( func(): queue_free();game.show_inventory());tabs.add_child(power)
	var filters = HBoxContainer.new();box.add_child(filters)
	search = LineEdit.new();search.placeholder_text = "İsim veya kaynak kimliği ara…";search.size_flags_horizontal = Control.SIZE_EXPAND_FILL;search.text_changed.connect( func(_value): offset = 0;refresh());filters.add_child(search)
	filter = OptionButton.new()
	for name in ["Tümü", "rifle", "pistol", "smg", "sniper", "shotgun", "machinegun", "knife", "grenade", "rocket", "launcher"]:
		filter.add_item(CATEGORY_NAMES.get(name, name));filter.set_item_metadata(filter.item_count - 1, name)
	filter.item_selected.connect( func(_index): offset = 0;refresh());filters.add_child(filter)
	count_label = game.label("", 15);box.add_child(count_label)
	var body = HBoxContainer.new();body.size_flags_vertical = Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation", 20);box.add_child(body)
	var scroll = ScrollContainer.new();scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;body.add_child(scroll)
	list = VBoxContainer.new();list.size_flags_horizontal = Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation", 6);scroll.add_child(list)
	var right_scroll = ScrollContainer.new();right_scroll.custom_minimum_size.x = 355;right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(right_scroll)
	detail = VBoxContainer.new();detail.custom_minimum_size.x = 330;detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation", 12);right_scroll.add_child(detail)
	var pages = HBoxContainer.new();box.add_child(pages)
	for pair in [["Önceki", -30], ["Sonraki", 30]]:
		var button = Button.new();button.text = pair[0];button.pressed.connect( func(): offset = maxi(0, offset + pair[1]);refresh());pages.add_child(button)
	pc_collection = Control.new();pc_collection.set_script(PcCollection);pc_collection.game = game;pc_collection.page = page
	pc_collection.navigate.connect( func(value): page = value;offset = 0;refresh())
	pc_collection.close_requested.connect(close_menu)
	pc_collection.power_requested.connect( func(): game.show_inventory())
	add_child(pc_collection)
	refresh()

func clear_box(box):
	for child in box.get_children(): box.remove_child(child);child.queue_free()

func refresh():
	clear_box(list);clear_box(detail);effect_frames = [];effect_preview = null
	var source_page = page in ["Mağaza", "Envanter"]
	traditional_box.visible = not source_page;pc_collection.visible = source_page
	if source_page: pc_collection.set_page(page);return
	if page == "Ayarlar": show_settings();return
	var entries = game.book.weapons if page in ["Mağaza", "Envanter"] else (game.book.characters if page == "Karakterler" else (game.book.tattoos if page == "Dövmeler" else game.book.effects))
	var rows = []
	for entry in entries:
		if page in ["Mağaza", "Envanter"]:
			if entry.get("engineImported") != true: continue
			if page == "Envanter" and not game.book.owned.get(entry.id, false): continue
			if filter.selected > 0 and entry.category != filter.get_item_metadata(filter.selected): continue
		if page == "Karakterler" and not entry.get("available", false): continue
		var name = entry.get("name", str(entry.get("source", "")).get_file().get_basename().replace("_", " "))
		if not search.text.is_empty() and not (name + " " + str(entry.get("sourceId", ""))).to_lower().contains(search.text.to_lower()): continue
		rows.append(entry)
	if offset >= rows.size(): offset = maxi(0, rows.size() - 30)
	count_label.text = "%s · %d kayıt · %d–%d" % [page, rows.size(), mini(offset + 1, rows.size()), mini(offset + 30, rows.size())]
	for entry in rows.slice(offset, offset + 30):
		var row = HBoxContainer.new();row.custom_minimum_size.y = 56;list.add_child(row)
		if entry.has("icon"):
			var icon = TextureRect.new();icon.texture = load(entry.icon);icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size = Vector2(70, 48);row.add_child(icon)
		var button = Button.new();button.text = entry.get("name", str(entry.get("source", "")).get_file().get_basename().replace("_", " "));button.alignment = HORIZONTAL_ALIGNMENT_LEFT;button.size_flags_horizontal = Control.SIZE_EXPAND_FILL;button.clip_text = true;button.pressed.connect( func(): select_entry(entry));row.add_child(button)
	if not rows.is_empty(): select_entry(rows[mini(offset, rows.size() - 1)])

func description(text):
	var label = game.label(text, 17);label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x = 330;detail.add_child(label)

func action(text, callback):
	var button = Button.new();button.text = text;button.custom_minimum_size.y = 48;button.pressed.connect(callback);detail.add_child(button)

func select_entry(entry):
	clear_box(detail);effect_frames = [];effect_preview = null
	description(entry.get("name", str(entry.get("source", "")).get_file().get_basename().replace("_", " ")))
	if page in ["Mağaza", "Envanter"]:
		var icon = TextureRect.new();icon.texture = load(entry.icon);icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size = Vector2(330, 170);detail.add_child(icon)
		description("Tür: " + CATEGORY_NAMES.get(entry.category, entry.category) + "\nYerel içerik mağazası. Özgün fiyatlar henüz doğrulanmadığı için deneme envanterine ücretsiz eklenir.")
		if not game.book.owned.get(entry.id, false): action("Envantere ekle", func(): game.book.acquire(entry.id);select_entry(entry))
		else: action("Tak ve kullan", func(): game.book.equip(entry.id);game.equip_library_weapon(entry);close_menu())
		action("Hazır tüm silahları envantere ekle", func(): game.book.acquire_all();select_entry(entry))
	elif page == "Karakterler":
		var view = SubViewportContainer.new();view.custom_minimum_size = Vector2(330, 240);detail.add_child(view)
		var viewport = SubViewport.new();viewport.size = Vector2i(330, 240);viewport.own_world_3d = true;view.add_child(viewport)
		var scene = Node3D.new();viewport.add_child(scene)
		for form in ["human", "wolf"]:
			var model = load(entry[form].asset).instantiate();model.scale *= 1.6;model.position.x = - 0.65 if form == "human" else 0.65;scene.add_child(model)
			var animations = model.find_children("*", "AnimationPlayer", true, false)
			if not animations.is_empty(): animations[0].play("idle")
		var light = DirectionalLight3D.new();light.rotation_degrees = Vector3(-30, -20, 0);light.light_energy = 2;scene.add_child(light)
		var camera = Camera3D.new();camera.fov = 50;scene.add_child(camera)
		PreviewCamera.frame(camera, scene, Vector2(viewport.size))
		description("İnsan ve kurt eşi ile ortak animasyonları kontrol edildi. İnsan birinci şahısta oynanır.")
		action("Karakteri seç", func():
			if game.select_library_character(entry): close_menu()
		)
	elif page == "Dövmeler":
		var icon = TextureRect.new();icon.texture = load(entry.texture);icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size = Vector2(330, 200);detail.add_child(icon)
		description("Görsel dövme. Kaynak yetenek bonusları henüz uygulanmadı.\nBölge: " + entry.role)
		if entry.role != "unknown": action("Dövmeyi tak", func(): equip_tattoo(entry.role, entry.texture))
		else:
			description("Kaynak vücut bölgesi doğrulanmadı; yanlış UV'ye uygulanmaması için takma kapalıdır.")
		for pair in [["Sırttaki dövmeyi çıkar", "body"], ["Sol koldaki dövmeyi çıkar", "left"], ["Sağ koldaki dövmeyi çıkar", "right"]]:
			if game.book.selected_tattoos.has(pair[1]): action(pair[0], func(): equip_tattoo(pair[1], ""))
	elif page == "Efektler":
		effect_frames = entry.frames.map( func(path): return load(path));effect_fps = float(entry.fps);effect_time = 0
		effect_preview = TextureRect.new();effect_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;effect_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;effect_preview.custom_minimum_size = Vector2(330, 250);detail.add_child(effect_preview)
		description("Özgün kaynak görüntü dizisi.")
		action("Oyunda göster", func(): game.play_source_effect(entry, game.player.global_position - game.player.global_basis.z * 3 + Vector3.UP);close_menu())

func show_settings():
	count_label.text = "AYARLAR"
	for pair in [["Bakış hassasiyeti", "sensitivity", 0.2, 3.0], ["Ana ses", "volume", 0.0, 1.0], ["Müzik", "music_volume", 0.0, 1.0], ["Ortam ve efektler", "effects_volume", 0.0, 1.0], ["Silah sesleri", "weapons_volume", 0.0, 1.0], ["Menü sesleri", "ui_volume", 0.0, 1.0]]:
		list.add_child(game.label(pair[0], 20)); var slider = HSlider.new();slider.min_value = pair[2];slider.max_value = pair[3];slider.step = 0.05;slider.value = game.book.settings[pair[1]];slider.custom_minimum_size = Vector2(500, 44);slider.value_changed.connect( func(value): change_setting(pair[1], value));list.add_child(slider)
	for pair in [["Yön düğmeleri", "directions"], ["Gölgeler", "shadows"]]:
		var check = CheckButton.new();check.text = pair[0];check.button_pressed = game.book.settings[pair[1]];check.toggled.connect( func(value): change_setting(pair[1], value));list.add_child(check)
	var fps = OptionButton.new();fps.add_item("30 FPS", 30);fps.add_item("60 FPS", 60);fps.select(0 if int(game.book.settings.fps) == 30 else 1);fps.item_selected.connect( func(_index): change_setting("fps", fps.get_selected_id()));list.add_child(fps)
	description("Ayarlar bu cihazda saklanır.")

func change_setting(key, value):
	if game.book.set_setting(key, value): game.apply_settings()
	else: game.announce("Ayar kaydedilemedi.");refresh()

func equip_tattoo(role, texture):
	if not game.book.set_tattoo(role, texture): game.announce("Dövme seçimi kaydedilemedi.");return
	game.player.apply_tattoos();close_menu()

func _process(delta):
	if is_instance_valid(effect_preview) and not effect_frames.is_empty():
		effect_time += delta
		effect_preview.texture = effect_frames[int(effect_time * effect_fps) % effect_frames.size()]

func close_menu():
	game.library_panel = null
	queue_free()
	if game.running: game.resume()
	else: game.show_home()
