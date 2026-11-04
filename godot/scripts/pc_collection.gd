extends Control

signal navigate(page)
signal close_requested
signal power_requested
const Layout = preload("res://scripts/pc_layout.gd")
const CATEGORY_NAMES = {"rifle": "Tüfek", "pistol": "Tabanca", "smg": "Hafif makineli", "sniper": "Keskin nişancı", "shotgun": "Pompalı", "machinegun": "Makineli", "heavy": "Ağır silah", "knife": "Bıçak", "grenade": "Bomba", "rocket": "Roket", "launcher": "Bomba atar"}
var game
var page = "Mağaza"
var canvas: Control
var grid
var search: LineEdit
var category: OptionButton
var group = "all"
var selected_entry = {}
var detail: Control
var sets: Control
var count_label: Label
var page_label: Label
var wallet_label: Label
var wallet_clock = 0.0
var previous: Button
var next: Button
var action_button: Button
var set_buttons = []

func text(parent, value, at, dimensions, font_size = 17):
	var label = Label.new();label.text = value;label.position = at;label.size = dimensions;label.add_theme_font_size_override("font_size", font_size);label.clip_text = true;label.mouse_filter = Control.MOUSE_FILTER_IGNORE;parent.add_child(label);return label

func button(parent, value, at, dimensions, callback):
	var control = Button.new();control.text = value;control.position = at;control.size = dimensions;control.pressed.connect(callback);parent.add_child(control);return control

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	canvas = Control.new();canvas.size = Vector2(1024, 768);add_child(canvas)
	var source = Layout.read_catalog().textures["wt_interface/inven_shop/is_bg.dtx"]
	var background = TextureRect.new(); var atlas = AtlasTexture.new();atlas.atlas = load(source.asset);atlas.region = Rect2(0, 0, 1024, 768);background.texture = atlas;background.size = Vector2(1024, 768);background.mouse_filter = Control.MOUSE_FILTER_IGNORE;canvas.add_child(background)
	var top = ColorRect.new();top.color = Color("232629");top.size = Vector2(1024, 58);canvas.add_child(top)
	text(canvas, "WOLF ROGUE BLOOD", Vector2(14, 17), Vector2(224, 32), 20)
	var index = 0
	for name in ["Mağaza", "Envanter", "Karakterler", "Dövmeler", "Efektler", "Ayarlar"]:
		button(canvas, name, Vector2(246 + index * 110, 2), Vector2(106, 54), func(): navigate.emit(name));index += 1
	button(canvas, "Kapat", Vector2(912, 2), Vector2(98, 54), func(): close_requested.emit())
	var left_title = ColorRect.new();left_title.color = Color("101619");left_title.position = Vector2(4, 61);left_title.size = Vector2(345, 36);canvas.add_child(left_title)
	text(canvas, "EKİPMAN / ÖNİZLEME", Vector2(14, 65), Vector2(330, 30), 18)
	button(canvas, "Kurt yeteneği · Güç slotu", Vector2(14, 108), Vector2(330, 54), func(): power_requested.emit())
	var tabs = Control.new();tabs.set_script(Layout);canvas.add_child(tabs);tabs.configure("interface/shoppropertysheet");tabs.position.x = 72
	for control in tabs.controls:
		if control is TextureButton:
			control.position.y = 62;control.size.y = 54
			control.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	tabs.bind_action("MainWeapon", func(): change_group("primary"));tabs.bind_action("SubWeapon", func(): change_group("pistol"));tabs.bind_action("SpecialWeapon", func(): change_group("special"))
	tabs.bind_action("Avility", func(): power_requested.emit());tabs.bind_action("ExItem", func(): navigate.emit("Dövmeler"));tabs.bind_action("Best", func(): change_group("all"))

	var all_tab = tabs.find_widget("Best"); var fill = ColorRect.new();fill.color = Color("353b40");fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fill.mouse_filter = Control.MOUSE_FILTER_IGNORE;all_tab.add_child(fill)
	text(all_tab, "Tümü", Vector2(0, 8), Vector2(77, 30), 17).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category = OptionButton.new();category.position = Vector2(848, 62);category.size = Vector2(150, 54);category.add_item("Tüm türler");category.set_item_metadata(0, "all")
	for kind in CATEGORY_NAMES: category.add_item(CATEGORY_NAMES[kind]);category.set_item_metadata(category.item_count - 1, kind)
	category.item_selected.connect( func(_index): group = "all";refresh_catalog(true));canvas.add_child(category)
	search = LineEdit.new();search.placeholder_text = "Silah ara…";search.position = Vector2(366, 118);search.size = Vector2(630, 54);search.text_changed.connect( func(_value): refresh_catalog(true));canvas.add_child(search)
	var grid_layout = Control.new();grid_layout.set_script(Layout);canvas.add_child(grid_layout);grid_layout.configure("interface/shoppropertypage");grid_layout.position.y = 20
	grid = grid_layout.find_widget("ItemListBox");grid.selected.connect(select_entry);grid.page_changed.connect(update_count)
	detail = Control.new();canvas.add_child(detail)
	sets = Control.new();canvas.add_child(sets);build_sets()
	count_label = text(canvas, "", Vector2(366, 534), Vector2(630, 28), 16)
	page_label = text(canvas, "", Vector2(620, 706), Vector2(120, 34), 17);page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	previous = button(canvas, "Önceki", Vector2(366, 694), Vector2(150, 54), func(): grid.set_page_offset(grid.page_offset - grid.capacity))
	next = button(canvas, "Sonraki", Vector2(846, 694), Vector2(150, 54), func(): grid.set_page_offset(grid.page_offset + grid.capacity))
	button(canvas, "Hazır silahları envantere ekle", Vector2(366, 636), Vector2(630, 54), func():
		if game.book.acquire_all(): refresh_catalog(false)
		else: game.announce("Envanter kaydedilemedi.")
	)
	wallet_label = text(canvas, "", Vector2(366, 748), Vector2(630, 20), 14)
	resized.connect(fit);fit();set_page(page)

func fit():
	if not is_instance_valid(canvas): return
	var factor = maxf(0.01, minf(size.x / 1024.0, size.y / 768.0));canvas.scale = Vector2.ONE * factor;canvas.position = (size - Vector2(1024, 768) * factor) * 0.5

func set_page(value):
	var changed = page != value;page = value;sets.visible = page == "Envanter"
	detail.position = Vector2(366, 568) if page == "Envanter" else Vector2(14, 174)
	detail.size = Vector2(630, 72) if page == "Envanter" else Vector2(330, 460)
	refresh_catalog(changed);refresh_sets()

func change_group(value):
	group = value;category.select(0);refresh_catalog(true)

func matches_group(item):
	if group == "primary": return game.book.slot_for(item.category) == "primary"
	if group == "pistol": return item.category == "pistol"
	if group == "special": return item.category in ["knife", "grenade", "rocket", "launcher"]
	return true

func normalized(value): return str(value).to_lower().replace("ı", "i").replace("İ", "i")

func refresh_catalog(reset_page):
	var filtered = []; var query = normalized(search.text); var kind = category.get_item_metadata(category.selected)
	for item in game.book.weapons:
		if item.get("engineImported") != true or item.get("available") != true: continue
		if page == "Envanter" and not game.book.owned.get(item.id, false): continue
		if kind != "all" and item.category != kind: continue
		if not matches_group(item): continue
		if not query.is_empty() and not normalized(item.name + " " + str(item.sourceId)).contains(query): continue
		filtered.append(item)
	var old_offset = 0 if reset_page else grid.page_offset
	grid.set_entries(filtered, game.book.owned, game.book.slots);grid.set_page_offset(old_offset)
	var current = {}
	for item in filtered:
		if item.id == selected_entry.get("id", ""): current = item;break
	if current.is_empty() and not filtered.is_empty(): current = filtered[grid.page_offset]
	select_entry(current);update_count()

func update_count():
	count_label.text = "%s · %d silah seçeneği" % [page, grid.entries.size()]
	page_label.text = "%d / %d" % [int(grid.page_offset / grid.capacity) + 1, maxi(1, int(ceil(float(grid.entries.size()) / grid.capacity)))]
	previous.disabled = grid.page_offset == 0;next.disabled = grid.page_offset + grid.capacity >= grid.entries.size()
	update_wallet()

func update_wallet():
	wallet_label.text = "Nakit: %d   KP: %d   Altın: %d   GP: %d" % [game.wallet.cash, game.wallet.kp, game.wallet.gold, game.wallet.gp]

func _process(delta):
	if not visible: return
	wallet_clock += delta
	if wallet_clock >= 0.25: wallet_clock = 0;update_wallet()

func select_entry(entry):
	selected_entry = entry
	for child in detail.get_children(): detail.remove_child(child);child.queue_free()
	action_button = null
	if entry.is_empty(): text(detail, "Eşleşen silah bulunamadı.", Vector2.ZERO, Vector2(330, 50));return
	grid.select_id(entry.id)
	if page == "Envanter":
		text(detail, entry.name, Vector2.ZERO, Vector2(390, 28), 18)
		text(detail, CATEGORY_NAMES[entry.category] + " · Ekipman %d" % (game.book.active_loadout + 1), Vector2(0, 31), Vector2(390, 30), 16)
		action_button = button(detail, "Tak", Vector2(410, 4), Vector2(210, 54), use_selected)
	else:
		var title = text(detail, entry.name, Vector2.ZERO, Vector2(330, 52), 21);title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var icon = TextureRect.new();icon.texture = load(entry.icon);icon.position = Vector2(0, 62);icon.size = Vector2(330, 185);icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;detail.add_child(icon)
		text(detail, CATEGORY_NAMES[entry.category], Vector2(0, 255), Vector2(330, 30), 19)
		var stats = entry.gameplayTuning
		text(detail, "Şarjör: %d    Hasar: %d" % [stats.capacity, stats.damage], Vector2(0, 292), Vector2(330, 30), 18)
		var info = text(detail, "Yerel geliştirme mağazası. Ekleme ücretsiz; özgün fiyat ve silah dengesi henüz tamamlanmadı.", Vector2(0, 335), Vector2(330, 76), 16);info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_button = button(detail, "Tak" if game.book.owned.get(entry.id, false) else "Envantere ekle", Vector2(0, 420), Vector2(330, 54), use_selected)
	if entry.id in game.book.slots.values(): action_button.text = "Takılı";action_button.disabled = true

func use_selected():
	if selected_entry.is_empty(): return
	var id = selected_entry.id
	if not game.book.owned.get(id, false):
		if not game.book.acquire(id): game.announce("Envanter kaydedilemedi.");return
	else:
		if not game.book.equip(id): game.announce("Ekipman kaydedilemedi.");return
		game.equip_library_weapon(selected_entry)
	refresh_catalog(false);refresh_sets()

func build_sets():
	var view = Control.new();view.set_script(Layout);sets.add_child(view);view.configure("interface/equiplistbox");view.position = Vector2(14, 174)
	for i in range(5):
		var card = view.find_widget("EquipButton", i);card.disabled = false;card.toggle_mode = true;card.tooltip_text = "Ekipman %d" % (i + 1)
		var content = Control.new();content.set_script(Layout);card.add_child(content);content.configure("interface/equipmentbutton", Vector2(209, 115))
		for name in ["CantUseWeapon", "HeavyWeapon", "MainWeaponNameAnother", "PlusMinus", "WeaponPoint"]:
			var node = content.find_widget(name)
			if node: node.hide()
		content.find_widget("SpecialWeaponName", 1).hide()
		card.pressed.connect( func(): select_set(i));set_buttons.append({"button": card, "content": content})

func refresh_sets():
	for i in range(set_buttons.size()):
		var row = set_buttons[i];row.button.set_pressed_no_signal(game.book.active_loadout == i);row.content.set_value("EquipmentName", "EKİPMAN %d" % (i + 1))
		var preset = game.book.loadouts[i]
		for pair in [["MainWeaponName", "primary"], ["SubWeaponName", "pistol"], ["CloseWeaponName", "knife"], ["SpecialWeaponName", "grenade"]]:
			var item = game.book.weapon(preset.get(pair[1], ""));row.content.set_value(pair[0], item.get("name", "Boş"), 0)

func select_set(index):
	if not game.book.select_loadout(index): game.announce("Ekipman seti kaydedilemedi.");return
	game.equip_slot("primary");refresh_catalog(false);refresh_sets()
