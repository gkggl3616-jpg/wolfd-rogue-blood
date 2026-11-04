extends Control

signal selected(entry)
signal page_changed
var entries = []
var cards = []
var owned = {}
var slots = {}
var page_offset = 0
var capacity = 9
var selected_id = ""
var cell = Vector2(210, 117)
var rows = 3
var columns = 3
var spacing = Vector2.ZERO
var source_catalog = {}
var group: ButtonGroup

func field(record, key, fallback = null): return record.fields.get(key, [fallback])[0]

func configure(record, catalog):
	source_catalog = catalog
	var dimensions = field(record, "size", [210, 117]);cell = Vector2(dimensions[0], dimensions[1])
	rows = clampi(int(field(record, "listboxrow", 1)), 1, 20);columns = clampi(int(field(record, "listboxcolumn", 1)), 1, 20);capacity = rows * columns
	var gap = field(record, "listboxspacing", [0, 0]);spacing = Vector2(gap[0], gap[1])
	size = Vector2(columns * cell.x + (columns - 1) * spacing.x, rows * cell.y + (rows - 1) * spacing.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func atlas(key, region):
	var info = source_catalog.textures.get(key, {})
	if info.is_empty(): return null
	var texture = load(info.asset); var result = AtlasTexture.new();result.atlas = texture;result.region = Rect2(region[0], region[1], region[2] - region[0], region[3] - region[1]);return result

func set_entries(values, ownership, equipment):
	entries = values;owned = ownership;slots = equipment;page_offset = 0;rebuild()

func set_page_offset(next):
	var last = ((maxi(1, entries.size()) - 1) / capacity) * capacity
	page_offset = clampi((int(next) / capacity) * capacity, 0, last);rebuild();page_changed.emit()

func rebuild():
	for child in get_children(): remove_child(child);child.queue_free()
	cards.clear();group = ButtonGroup.new()
	for index in range(page_offset, mini(entries.size(), page_offset + capacity)):
		var entry = entries[index]; var local_index = index - page_offset
		var card = TextureButton.new();card.ignore_texture_size = true;card.stretch_mode = TextureButton.STRETCH_SCALE;card.position = Vector2(local_index % columns, local_index / columns) * (cell + spacing);card.size = cell - Vector2(1, 2);card.toggle_mode = true;card.button_group = group;card.button_pressed = entry.id == selected_id
		card.texture_normal = atlas("wt_interface/inven_shop/is_inven_weponbar.dtx", [0, 0, 210, 115]);card.texture_hover = atlas("wt_interface/inven_shop/is_inven_weponbar.dtx", [0, 118, 210, 232]);card.texture_pressed = atlas("wt_interface/inven_shop/is_inven_weponbar.dtx", [0, 234, 210, 350]);card.tooltip_text = entry.name
		card.set_meta("entry", entry);add_child(card);cards.append(card)
		var icon = TextureRect.new();icon.texture = load(entry.icon);icon.position = Vector2(2, 2);icon.size = Vector2(205, 70);icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter = Control.MOUSE_FILTER_IGNORE;card.add_child(icon)
		var title = Label.new();title.text = entry.name;title.position = Vector2(4, 74);title.size = Vector2(202, 21);title.add_theme_font_size_override("font_size", 15);title.clip_text = true;title.mouse_filter = Control.MOUSE_FILTER_IGNORE;card.add_child(title)
		var status = Label.new();status.text = "Takılı" if entry.id in slots.values() else ("Envanterde" if owned.get(entry.id, false) else "");status.position = Vector2(6, 94);status.size = Vector2(195, 20);status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;status.add_theme_font_size_override("font_size", 13);status.add_theme_color_override("font_color", Color("d6b765"));status.mouse_filter = Control.MOUSE_FILTER_IGNORE;card.add_child(status)
		card.pressed.connect( func(): selected_id = entry.id;selected.emit(entry))

func select_id(id):
	selected_id = id
	for card in cards: card.set_pressed_no_signal(card.get_meta("entry").id == id)
