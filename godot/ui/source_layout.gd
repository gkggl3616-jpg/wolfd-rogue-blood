extends Control
const Art = preload("res://ui/source_theme.gd")
var records = []
var controls = []
var natural_size = Vector2(1024, 768)
var unresolved_parents = []
var unsupported_types = {}
var layout_id = ""
var textures_enabled = true

class SourceLabel extends Label:
	func _get_minimum_size():return Vector2.ZERO
class SourceInput extends LineEdit:
	func _has_point(point):return editable and Rect2(Vector2.ZERO,size).has_point(point)
	func _get_minimum_size():return Vector2.ZERO
class SourceChoice extends OptionButton:
	func _has_point(point):return not disabled and Rect2(Vector2.ZERO,size).grow(12).has_point(point)
	func _get_minimum_size():return Vector2.ZERO

class SourceSlider extends Range:
	var editable = false
	var foreground: Texture2D
	var background: Texture2D
	var dragging = false
	var finger = -1
	func _init():
		focus_mode = Control.FOCUS_ALL
		value_changed.connect(func(_value):queue_redraw())
	func _has_point(point):
		return editable and Rect2(Vector2(0,-26),Vector2(size.x,size.y+52)).has_point(point)
	func _draw():
		if background:draw_texture_rect(background,Rect2(Vector2.ZERO,size),false)
		var weight=clampf((value-min_value)/maxf(0.001,max_value-min_value),0,1)
		if foreground and weight>0:draw_texture_rect_region(foreground,Rect2(Vector2.ZERO,Vector2(size.x*weight,size.y)),Rect2(0,0,foreground.get_width()*weight,foreground.get_height()))
	func set_at(point):
		value=min_value+clampf(point.x/maxf(1,size.x),0,1)*(max_value-min_value)
	func _gui_input(event):
		if not editable:return
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed
			if dragging:grab_focus();set_at(event.position)
			accept_event()
		elif event is InputEventMouseMotion and dragging:set_at(event.position);accept_event()
		elif event is InputEventScreenTouch:
			if event.pressed and finger==-1:finger=event.index;set_at(event.position)
			elif not event.pressed and event.index==finger:finger=-1
			accept_event()
		elif event is InputEventScreenDrag and event.index==finger:set_at(event.position);accept_event()
		elif event is InputEventKey and event.pressed:
			if event.keycode==KEY_LEFT:value-=maxf(step,1);accept_event()
			elif event.keycode==KEY_RIGHT:value+=maxf(step,1);accept_event()

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
		var x = maxf(0, size.x - width) if alignment == 2 else (maxf(0, (size.x-width)*0.5) if alignment == 3 else 0.0)
		for character in value:
			if character.is_valid_int():
				var region = Rect2(0, int(character) * step, cell.x, cell.y)
				if region.end.y <= texture.get_height(): draw_texture_rect_region(texture, Rect2(x, 0, cell.x, cell.y), region, tint)
			x += cell.x + spacing

static func read_catalog(): return Art.catalog()
func field(record, property, fallback = null): return record.fields.get(property, [fallback])[0]
func pair(value, fallback = Vector2.ZERO): return Vector2(value[0],value[1]) if value is Array and value.size() >= 2 else fallback
func rect(value):
	return Rect2(float(value[0]),float(value[1]),float(value[2])-float(value[0]),float(value[3])-float(value[1])) if value is Array and value.size() == 4 else Rect2()
func texture_key(value): return Art.key(value)
func image(record): return Art.texture(field(record,"texture","")) if textures_enabled else null
func atlas(texture, region): return Art.atlas(texture,region) if textures_enabled else null
func caption(record):
	var value = str(record.get("resolvedCaption", field(record,"caption","")))
	var pattern = RegEx.new();pattern.compile("(?i)wolf\\s*team")
	return pattern.sub(value,"Wolf Rogue Blood",true)

func configure(source_id, dimensions = Vector2(1024,768)):
	for child in get_children(): remove_child(child);child.queue_free()
	controls.clear();unresolved_parents.clear();unsupported_types.clear()
	layout_id = source_id;natural_size = dimensions;size = dimensions;mouse_filter = Control.MOUSE_FILTER_IGNORE;theme = Art.native_theme() if textures_enabled else null
	records = read_catalog().get("layouts",{}).get(source_id,{}).get("widgets",[])
	for record in records:
		var node = create_widget(record);controls.append(node);add_child(node)
	for i in range(records.size()):
		var record = records[i];var parent = record.get("parentIndex")
		if parent == null:
			if str(field(record,"parent","")).is_empty(): continue
			unresolved_parents.append({"widget":record.name,"parent":field(record,"parent","")})
			controls[i].hide()
			continue
		var index = int(parent)
		if index < 0 or index >= controls.size() or controls[i].is_ancestor_of(controls[index]):
			unresolved_parents.append({"widget":record.name,"reason":"invalid_or_cyclic_parent"});continue
		controls[i].reparent(controls[index],false)
	for node in controls:
		if node is BaseButton and node.toggle_mode and node.get_parent().get_meta("adapter","")=="group":
			var group=node.get_parent()
			if not group.has_meta("radio_group"):group.set_meta("radio_group",ButtonGroup.new())
			node.button_group=group.get_meta("radio_group")
	return not records.is_empty()

func show_only(names):
	for i in range(records.size()):controls[i].visible=records[i].name in names
	# A visible child does not render through a hidden radio group / image parent.
	for node in controls:
		if not node.visible:continue
		var ancestor=node.get_parent()
		while ancestor!=self and ancestor is Control:
			ancestor.show();ancestor=ancestor.get_parent()

func create_widget(record):
	var kind = str(record.type).to_lower();var adapter = record.get("adapter","")
	var node: Control
	var source = image(record)
	var at = pair(field(record,"position",field(record,"realposition",field(record,"startposition",[0,0]))))
	var dimensions = pair(field(record,"size",[0,0]))
	match adapter:
		"image":
			node = TextureRect.new();node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode = TextureRect.STRETCH_SCALE
			node.texture = atlas(source,rect(field(record,"spriterect",[0,0,dimensions.x,dimensions.y])))
		"text":
			node = SourceLabel.new();node.text = caption(record);node.clip_text = true
			if textures_enabled:node.add_theme_font_override("font",Art.font(int(field(record,"fontfaceindex",51))))
			var area = rect(field(record,"fontrect",[]));at = area.position;dimensions = area.size
			node.add_theme_font_size_override("font_size",int(field(record,"fontsize",14)))
			var color = field(record,"captioncolor",[255,255,255]);node.add_theme_color_override("font_color",Color(float(color[0])/255,float(color[1])/255,float(color[2])/255))
			var align = int(field(record,"fontalign",1));node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if align & 4 else (HORIZONTAL_ALIGNMENT_CENTER if align & 2 else HORIZONTAL_ALIGNMENT_LEFT)
			node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if align & 8 else VERTICAL_ALIGNMENT_TOP
		"digits":
			node = DigitDisplay.new();node.texture = source;node.cell = dimensions;node.step = float(field(record,"numberheightspacing",dimensions.y));node.spacing = float(field(record,"numberspacing",0));node.alignment = int(field(record,"numberalign",1))
			var area = rect(field(record,"numberrect",[]));at = area.position;dimensions = area.size
		"button":
			node = preload("res://ui/touch_button.gd").new();node.ignore_texture_size = true;node.stretch_mode = TextureButton.STRETCH_SCALE;node.disabled = true
			node.texture_normal = atlas(source,rect(field(record,"buttondefaultrect",[0,0,dimensions.x,dimensions.y])))
			node.texture_hover = atlas(source,rect(field(record,"buttonoverrect",[])))
			node.texture_pressed = atlas(source,rect(field(record,"buttonclickrect",[])))
			node.texture_disabled = atlas(source,rect(field(record,"buttondisablerect",[])))
			if node.texture_disabled == null: node.texture_disabled = node.texture_normal
			node.toggle_mode = field(record,"buttontype","") == "BT_CHECK" or kind == "radiobutton"
			if node.toggle_mode:
				var selected = atlas(source,rect(field(record,"buttonselectrect",[])))
				if selected != null: node.texture_pressed = selected
			if not caption(record).is_empty():
				var text = Art.label(caption(record),Vector2(180,maxf(24,dimensions.y)),int(field(record,"fontsize",12))) if textures_enabled else Label.new()
				text.position.x = dimensions.x + 5;text.mouse_filter = Control.MOUSE_FILTER_IGNORE;node.add_child(text)
		"input":
			node = SourceInput.new();node.max_length = int(field(record,"editboxmaxlength",64));node.editable = false
		"choice":
			node = SourceChoice.new();node.fit_to_longest_item = false;node.disabled = true
			if textures_enabled and record.fields.get("texture",[]).size()>1:
				var arrow=Art.texture(record.fields.texture[1])
				if arrow:node.add_theme_icon_override("arrow",Art.atlas(arrow,Rect2(0,0,minf(arrow.get_width(),18),minf(arrow.get_width(),18))))
		"slider":
			node = SourceSlider.new();node.min_value = float(field(record,"sliderminvalue",0));node.max_value = float(field(record,"slidermaxvalue",100));node.editable = false
			if textures_enabled:
				var paths = record.fields.get("texture",[])
				if paths.size() >= 2:
					node.background=Art.texture(paths[1]);node.foreground=Art.texture(paths[0])
		"list":
			node = ItemList.new();node.allow_reselect = true;node.select_mode = ItemList.SELECT_SINGLE
			node.set_meta("requires_data_binding",true)
		"text_area":
			if kind == "memobox": node = TextEdit.new();node.editable = false
			else: node = RichTextLabel.new();node.bbcode_enabled = false;node.scroll_active = true
		"color":
			node = ColorPickerButton.new();node.disabled = true
		"line":
			node = HSeparator.new()
		"dialog":
			node = PanelContainer.new();node.visible = false;node.set_meta("requires_explicit_open",true)
		"group":
			node = Control.new()
		_:
			node = Control.new();unsupported_types[kind] = int(unsupported_types.get(kind,0))+1
	node.name = str(record.name).validate_node_name();node.position = at;node.size = dimensions
	node.set_meta("source_record",record);node.set_meta("source_layout",layout_id);node.set_meta("adapter",adapter)
	if int(field(record,"fontfaceindex",0))==51:node.set_meta("font_binding_pending",51)
	if adapter in ["image","text","digits","group","line"] or adapter not in ["button","input","choice","slider","list","text_area","color","dialog"]: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else: node.mouse_filter = Control.MOUSE_FILTER_STOP
	if adapter != "dialog": node.visible = field(record,"renderstate",true) != false
	return node

func find_widget(widget_name, identity = null):
	var matches = []
	for i in range(records.size()):
		if records[i].name == widget_name and (identity == null or field(records[i],"identity",-1) == identity): matches.append(controls[i])
	return matches[0] if matches.size() == 1 else null

func bind_action(widget_name, callback, identity = null):
	var node = find_widget(widget_name,identity)
	if not node is BaseButton: return false
	node.disabled = false;node.tooltip_text = "";node.pressed.connect(callback);return true

func set_value(widget_name, value, identity = null):
	var node = find_widget(widget_name,identity)
	if node is Label or node is LineEdit or node is RichTextLabel or node is TextEdit: node.text = str(value);return true
	if node is DigitDisplay: node.value = str(value);return true
	return false
