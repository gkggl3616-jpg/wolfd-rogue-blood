extends RefCounted

static var data = {}
static var ui_font: Font
const GOLD = Color("e0ca7b")
const INK = Color("111517")
const BUTTON_TEXTURE = "wt_interface/all/a_button_ok.dtx"

# The PC action plate has four 90x28 states. Stretch only its empty column;
# stretching a weapon card (or the baked TAMAM caption) changes the entire UI.
class ActionButton extends TextureButton:
	var sheet: Texture2D
	func _draw():
		if sheet == null:return
		var row=87 if disabled else (58 if is_pressed() else (29 if is_hovered() else 0))
		draw_texture_rect_region(sheet,Rect2(0,0,8,size.y),Rect2(0,row,8,28))
		draw_texture_rect_region(sheet,Rect2(size.x-8,0,8,size.y),Rect2(82,row,8,28))

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

static func map_photo(map_catalog,number):
	var image=texture(map_catalog.photo(number).get("asset",""))
	if image==null:return null
	var region=Rect2(Vector2.ZERO,image.get_size())
	if image.get_width()>=407 and image.get_height()>=120:region=Rect2(0,0,407,120)
	return atlas(image,region)

static func atlas(source, region: Rect2):
	var image = texture(source) if source is String else source
	if image == null or not region.has_area() or region.position.x < 0 or region.position.y < 0 or region.end.x > image.get_width() or region.end.y > image.get_height(): return null
	var result = AtlasTexture.new()
	result.atlas = image;result.region = region
	return result

static func font(face_index=51):
	# Face 51 used by the Turkish item/account text is absent from the supplied
	# four-font binding. Keep it a regular fallback, not Square 721 Black.
	if face_index not in [0,1,2,3]:return ThemeDB.fallback_font
	if ui_font == null:
		var binding = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/engine-fonts.json"))
		ui_font = load(binding.fonts["0"].asset).duplicate()
		ui_font.fallbacks = [ThemeDB.fallback_font]
	if face_index==0:return ui_font
	var binding=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/engine-fonts.json"))
	return load(binding.fonts[str(face_index)].asset)

static func label(text, dimensions = Vector2(200, 32), pixels = 12, color = Color.WHITE):
	var node = Label.new();node.text = str(text);node.size = dimensions
	node.clip_text=true
	node.add_theme_font_override("font", font());node.add_theme_font_size_override("font_size", pixels)
	node.add_theme_color_override("font_color", color);node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func sprite(parent, source, at: Vector2, dimensions: Vector2, region = Rect2()):
	var image = texture(source)
	# Set expansion before assigning the texture. Assigning a large texture in
	# KEEP_SIZE first grows the rect, which later survives IGNORE_SIZE changes.
	var node = TextureRect.new();node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture = atlas(image, region if region.has_area() else Rect2(Vector2.ZERO, image.get_size())) if image else null
	node.position = at;node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE;node.set_meta("source_texture", key(source));parent.add_child(node)
	return node

static func panel_style(source = BUTTON_TEXTURE, region = Rect2(5, 0, 3, 28), margins = 1.0):
	var style = StyleBoxTexture.new();style.texture = atlas(source, region)
	style.texture_margin_left = margins;style.texture_margin_right = margins;style.texture_margin_top = margins;style.texture_margin_bottom = margins
	style.content_margin_left = 10;style.content_margin_right = 10;style.content_margin_top = 6;style.content_margin_bottom = 6
	return style

static func theme():
	var result = Theme.new();result.default_font = font();result.default_font_size = 12
	for kind in ["Button", "OptionButton", "LineEdit", "SpinBox", "TextEdit", "ItemList"]:
		var field=StyleBoxFlat.new();field.bg_color=Color("101619");field.border_color=Color("4b5356");field.set_border_width_all(1);field.content_margin_left=5;field.content_margin_right=5
		result.set_stylebox("normal", kind, field)
		result.set_stylebox("hover", kind, field)
		result.set_stylebox("pressed", kind, field)
		result.set_color("font_color", kind, Color("c8ced0"))
		result.set_color("font_hover_color", kind, GOLD)
	var panel=StyleBoxFlat.new();panel.bg_color=Color("101619");panel.border_color=Color("4b5356");panel.set_border_width_all(1)
	result.set_stylebox("panel", "PanelContainer", panel)
	return result

static func native_theme():
	var result=Theme.new();result.default_font=font();result.default_font_size=12
	for kind in ["OptionButton","LineEdit","ItemList","TextEdit"]:
		for state in ["normal","hover","pressed","focus","read_only","disabled","panel"]:result.set_stylebox(state,kind,StyleBoxEmpty.new())
		result.set_color("font_color",kind,Color("b6c8cc"))
	result.set_stylebox("panel","PanelContainer",StyleBoxEmpty.new())
	return result

static func button(parent, text, at: Vector2, dimensions: Vector2, callback = Callable()):
	var node = ActionButton.new();node.sheet=texture(BUTTON_TEXTURE);node.position = at;node.size = dimensions;node.ignore_texture_size = true
	node.texture_normal = atlas(BUTTON_TEXTURE, Rect2(5, 0, 3, 28))
	node.texture_hover = atlas(BUTTON_TEXTURE, Rect2(5, 29, 3, 28))
	node.texture_pressed = atlas(BUTTON_TEXTURE, Rect2(5, 58, 3, 28))
	node.texture_disabled = atlas(BUTTON_TEXTURE, Rect2(5, 87, 3, 28));node.stretch_mode = TextureButton.STRETCH_SCALE
	var caption = label(text, dimensions, 12,INK);caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);node.add_child(caption)
	if callback.is_valid(): node.pressed.connect(callback)
	node.set_meta("source_texture", BUTTON_TEXTURE);node.set_meta("caption", caption)
	parent.add_child(node)
	return node

static func atlas_button(parent,source,regions,at,dimensions,callback=Callable()):
	var node=TextureButton.new();node.ignore_texture_size=true;node.stretch_mode=TextureButton.STRETCH_SCALE;node.position=at;node.size=dimensions
	node.texture_normal=atlas(source,regions[0]);node.texture_hover=atlas(source,regions[1]);node.texture_pressed=atlas(source,regions[2]);node.texture_disabled=atlas(source,regions[-1])
	if callback.is_valid():node.pressed.connect(callback)
	node.set_meta("source_texture",key(source));parent.add_child(node);return node

static func icon_button(parent,source,at,title,callback):
	var node=atlas_button(parent,source,[Rect2(0,0,32,32),Rect2(0,32,32,32),Rect2(0,64,32,32),Rect2(0,96,32,32)],at,Vector2(32,32),callback)
	node.tooltip_text=title;node.accessibility_name=title
	return node

static func set_button_text(button_node, text):
	if button_node.has_meta("caption"): button_node.get_meta("caption").text = text

static func section(parent, text, at, dimensions):
	var node = PanelContainer.new();node.position = at;node.size = dimensions
	node.add_theme_stylebox_override("panel", panel_style("wt_interface/lobby/ladder_lb_bg_bar.dtx", Rect2(0, 0, 512, 30), 3))
	var caption = label(text, dimensions, 18, GOLD);node.add_child(caption);parent.add_child(node)
	return node
