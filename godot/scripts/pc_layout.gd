extends Control
const ItemGrid = preload("res://scripts/pc_item_grid.gd")


static var catalog = {}
var records = []
var controls = []
var natural_size = Vector2(1024, 768)
var unresolved_parents = []
var unsupported_types = {}

class DigitDisplay extends Control:
	var texture: Texture2D
	var cell = Vector2(13, 22)
	var step = 25.0
	var spacing = 0.0
	var alignment = 1
	var tint = Color.WHITE
	var value = "0":
		set(next): value = str(next);queue_redraw()
	func _draw():
		if not texture: return
		var width = value.length() * (cell.x + spacing) - spacing
		var x = maxf(0, size.x - width) if alignment == 2 else (maxf(0, (size.x - width) * 0.5) if alignment == 3 else 0.0)
		for character in value:
			if character.is_valid_int():
				var region = Rect2(0, int(character) * step, cell.x, cell.y)
				if region.end.y <= texture.get_height(): draw_texture_rect_region(texture, Rect2(x, 0, cell.x, cell.y), region, tint)
			x += cell.x + spacing

static func read_catalog():
	if catalog.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pc_ui/catalog.json"))
		if data is Dictionary: catalog = data
		if FileAccess.file_exists("res://assets/full_ui/catalog.json"):
			var expanded = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full_ui/catalog.json"))
			if expanded is Dictionary: catalog.textures.merge(expanded.get("textures", {}), true)
	return catalog

func field(record, key, fallback = null):
	return record.fields.get(key, [fallback])[0]

func pair(value, fallback = Vector2.ZERO):
	return Vector2(value[0], value[1]) if value is Array and value.size() >= 2 else fallback

func rect(value):
	if value is Array and value.size() == 4: return Rect2(float(value[0]), float(value[1]), float(value[2]) - float(value[0]), float(value[3]) - float(value[1]))
	return Rect2()

func texture_key(value):
	return str(value).replace("\\", "/").replace("//", "/").to_lower().trim_prefix("root/")

func image(record):
	var info = read_catalog().textures.get(texture_key(field(record, "texture", "")), {})
	return load(info.asset) if not info.is_empty() else null

func atlas(texture, region):
	if not texture: return null
	if region.size.x <= 0 or region.size.y <= 0: return null
	if region.position.x < 0 or region.position.y < 0 or region.end.x > texture.get_width() or region.end.y > texture.get_height(): return null
	var result = AtlasTexture.new();result.atlas = texture;result.region = region;return result

func caption(record):
	var text = str(field(record, "caption", ""))
	var index = str(field(record, "captionindex", -1))
	if text.is_empty():
		for table in read_catalog().strings.values():
			if table.has(index): text = table[index];break
	return text.replace("WolfTeam", "Wolf Rogue").replace("Wolfteam", "Wolf Rogue").replace("WOLFTEAM", "WOLF ROGUE")

func configure(layout_id, dimensions = Vector2(1024, 768)):
	for node in get_children(): remove_child(node);node.queue_free()
	controls.clear();unresolved_parents.clear();unsupported_types.clear()
	natural_size = dimensions;size = dimensions;mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout = read_catalog().layouts.get(layout_id, {})
	records = layout.get("widgets", [])
	for record in records:
		var node = create_widget(record);controls.append(node);add_child(node)
	for i in range(records.size()):
		var record = records[i]; var parent_name = str(field(record, "parent", "")); var parent_id = field(record, "parentidentity", null)
		if parent_name.is_empty(): continue
		var matches = []
		for j in range(records.size()):
			if i != j and records[j].name.to_lower() == parent_name.to_lower() and (parent_id == null or field(records[j], "identity", -1) == parent_id): matches.append(j)
		if matches.size() != 1: unresolved_parents.append({"widget": record.name, "parent": parent_name, "matches": matches.size()});continue
		var target = controls[matches[0]]
		if controls[i].is_ancestor_of(target): unresolved_parents.append({"widget": record.name, "parent": parent_name, "reason": "cycle"});continue
		controls[i].reparent(target, false)
	return not records.is_empty()

func create_widget(record):
	var kind = str(record.type).to_lower(); var node: Control; var source = image(record)
	var at = pair(field(record, "position", field(record, "realposition", field(record, "startposition", [0, 0]))))
	var dimensions = pair(field(record, "size", [0, 0]))
	if kind == "itemlistbox":
		node = Control.new();node.set_script(ItemGrid);node.configure(record, read_catalog());dimensions = node.size
	elif kind == "number":
		node = DigitDisplay.new();node.texture = source;node.cell = dimensions;node.step = float(field(record, "numberheightspacing", dimensions.y));node.spacing = float(field(record, "numberspacing", 0));node.alignment = int(field(record, "numberalign", 1))
		var area = rect(field(record, "numberrect", []));at = area.position;dimensions = area.size
		var color = field(record, "numbercolor", [255, 255, 255]);node.tint = Color(float(color[0]) / 255, float(color[1]) / 255, float(color[2]) / 255)
	elif kind == "statictext":
		node = Label.new();node.text = caption(record);node.add_theme_font_size_override("font_size", int(field(record, "fontsize", 12)));node.clip_text = true
		var area = rect(field(record, "fontrect", []));at = area.position;dimensions = area.size
		var color = field(record, "captioncolor", [255, 255, 255]);node.add_theme_color_override("font_color", Color(float(color[0]) / 255, float(color[1]) / 255, float(color[2]) / 255))
		var align = int(field(record, "fontalign", 1));node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if align & 4 else (HORIZONTAL_ALIGNMENT_CENTER if align & 2 else HORIZONTAL_ALIGNMENT_LEFT);node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if align & 8 else VERTICAL_ALIGNMENT_TOP
	elif kind in ["button", "radiobutton", "columnbutton", "itembutton", "equipmentbutton", "inventoryequipmentbutton", "equipbutton", "serverbutton"]:
		node = TextureButton.new();node.ignore_texture_size = true;node.stretch_mode = TextureButton.STRETCH_SCALE;node.disabled = true
		node.texture_normal = atlas(source, rect(field(record, "buttondefaultrect", [0, 0, dimensions.x, dimensions.y])))
		node.texture_hover = atlas(source, rect(field(record, "buttonoverrect", [])));node.texture_pressed = atlas(source, rect(field(record, "buttonclickrect", [])));node.texture_disabled = atlas(source, rect(field(record, "buttondisablerect", [])))
		if not node.texture_disabled: node.texture_disabled = node.texture_normal
		node.tooltip_text = "Bu işlem henüz bağlanmadı."
		node.mouse_filter = Control.MOUSE_FILTER_STOP
	elif kind == "staticsprite":
		node = TextureRect.new();node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode = TextureRect.STRETCH_SCALE
		var region = rect(field(record, "spriterect", [0, 0, dimensions.x, dimensions.y]));node.texture = atlas(source, region)
	else:
		node = Control.new()
		if kind not in ["buttongropbox", "buttongroupboxex"]: unsupported_types[kind] = int(unsupported_types.get(kind, 0)) + 1
	node.name = str(record.name).validate_node_name();node.position = at;node.size = dimensions;node.set_meta("source_record", record)
	if not node is BaseButton: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.visible = field(record, "renderstate", true) != false
	return node

func find_widget(widget_name, identity = null):
	for i in range(records.size()):
		if records[i].name == widget_name and (identity == null or field(records[i], "identity", -1) == identity): return controls[i]
	return null

func bind_action(widget_name, callback, identity = null):
	var node = find_widget(widget_name, identity)
	if not node is BaseButton: return false
	node.disabled = false;node.tooltip_text = "";node.pressed.connect(callback);return true

func set_value(widget_name, value, identity = null):
	var node = find_widget(widget_name, identity)
	if node is Label: node.text = str(value);return true
	if node is DigitDisplay: node.value = str(value);return true
	return false
