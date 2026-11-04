extends RefCounted

static var data = {}
static var ui_font: Font
const GOLD = Color("e0ca7b")
const INK = Color("111517")
const BUTTON_TEXTURE = "wt_interface/inven_shop/is_inven_weponbar.dtx"

static func catalog():
	if data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/catalog.json"))
		if parsed is Dictionary: data = parsed
	return data

static func key(value):
	var path = str(value).strip_edges().trim_prefix('"').trim_suffix('"').replace("\\", "/").to_lower()
	while "//" in path: path = path.replace("//", "/")
	if path.contains("/game/wt_interface/"): path = "wt_interface/" + path.split("/game/wt_interface/", true, 1)[1]
	return path.trim_prefix("root/")

static func texture(source):
	if source is Texture2D: return source
	if str(source).begins_with("res://"):
		return load(source) if ResourceLoader.exists(source) else null
	var info = catalog().get("textures", {}).get(key(source), {})
	return load(info.asset) if not info.is_empty() and ResourceLoader.exists(info.asset) else null

static func atlas(source, region: Rect2):
	var image = texture(source) if source is String else source
	if image == null or not region.has_area() or region.position.x < 0 or region.position.y < 0 or region.end.x > image.get_width() or region.end.y > image.get_height(): return null
	var result = AtlasTexture.new()
	result.atlas = image;result.region = region
	return result

static func font():
	if ui_font == null:
		var binding = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/engine-fonts.json"))
		ui_font = load(binding.fonts["0"].asset).duplicate()
		ui_font.fallbacks = [ThemeDB.fallback_font]
	return ui_font

static func label(text, dimensions = Vector2(200, 32), pixels = 18, color = Color.WHITE):
	var node = Label.new();node.text = str(text);node.size = dimensions
	node.add_theme_font_override("font", font());node.add_theme_font_size_override("font_size", pixels)
	node.add_theme_color_override("font_color", color);node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func sprite(parent, source, at: Vector2, dimensions: Vector2, region = Rect2()):
	var image = texture(source)
	var node = TextureRect.new();node.texture = atlas(image, region if region.has_area() else Rect2(Vector2.ZERO, image.get_size())) if image else null
	node.position = at;node.size = dimensions;node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE;node.set_meta("source_texture", key(source));parent.add_child(node)
	return node

static func panel_style(source = BUTTON_TEXTURE, region = Rect2(0, 0, 234, 80), margins = 6.0):
	var style = StyleBoxTexture.new();style.texture = atlas(source, region)
	style.texture_margin_left = margins;style.texture_margin_right = margins;style.texture_margin_top = margins;style.texture_margin_bottom = margins
	style.content_margin_left = 10;style.content_margin_right = 10;style.content_margin_top = 6;style.content_margin_bottom = 6
	return style

static func theme():
	var result = Theme.new();result.default_font = font();result.default_font_size = 18
	for kind in ["Button", "OptionButton", "LineEdit", "SpinBox", "TextEdit", "ItemList"]:
		result.set_stylebox("normal", kind, panel_style())
		result.set_stylebox("hover", kind, panel_style(BUTTON_TEXTURE, Rect2(0, 80, 234, 80)))
		result.set_stylebox("pressed", kind, panel_style(BUTTON_TEXTURE, Rect2(0, 160, 234, 80)))
		result.set_color("font_color", kind, Color.WHITE)
		result.set_color("font_hover_color", kind, GOLD)
	result.set_stylebox("panel", "PanelContainer", panel_style())
	return result

static func native_theme():
	var result=Theme.new();result.default_font=font();result.default_font_size=12
	for kind in ["OptionButton","LineEdit","ItemList","TextEdit"]:
		for state in ["normal","hover","pressed","focus","read_only","disabled","panel"]:result.set_stylebox(state,kind,StyleBoxEmpty.new())
		result.set_color("font_color",kind,Color("b6c8cc"))
	result.set_stylebox("panel","PanelContainer",StyleBoxEmpty.new())
	return result

static func button(parent, text, at: Vector2, dimensions: Vector2, callback = Callable()):
	var node = TextureButton.new();node.position = at;node.size = dimensions;node.ignore_texture_size = true
	node.texture_normal = atlas(BUTTON_TEXTURE, Rect2(0, 0, 234, 80))
	node.texture_hover = atlas(BUTTON_TEXTURE, Rect2(0, 80, 234, 80))
	node.texture_pressed = atlas(BUTTON_TEXTURE, Rect2(0, 160, 234, 80))
	node.texture_disabled = atlas(BUTTON_TEXTURE, Rect2(0, 240, 234, 80));node.stretch_mode = TextureButton.STRETCH_SCALE
	var caption = label(text, dimensions, 18);caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);node.add_child(caption)
	if callback.is_valid(): node.pressed.connect(callback)
	node.set_meta("source_texture", BUTTON_TEXTURE);node.set_meta("caption", caption)
	parent.add_child(node)
	return node

static func set_button_text(button_node, text):
	if button_node.has_meta("caption"): button_node.get_meta("caption").text = text

static func section(parent, text, at, dimensions):
	var node = PanelContainer.new();node.position = at;node.size = dimensions
	node.add_theme_stylebox_override("panel", panel_style("wt_interface/lobby/ladder_lb_bg_bar.dtx", Rect2(0, 0, 512, 30), 3))
	var caption = label(text, dimensions, 18, GOLD);node.add_child(caption);parent.add_child(node)
	return node
