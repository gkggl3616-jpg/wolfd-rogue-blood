extends Control
var game
var canvas: Control
var data = {}
var local_button: Button

func numbers(value):
	var parts = str(value).split(","); var result = []
	for part in parts: result.append(float(part.strip_edges()))
	return result

func image(value):
	var parts = str(value).rsplit(",", true, 4)
	if parts.size() != 5: return null
	var key = parts[0].strip_edges().replace("\\", "/").trim_prefix("./").to_lower()
	if not data.textures.has(key): return null
	var atlas = AtlasTexture.new();atlas.atlas = load(data.textures[key].asset)
	var left = float(parts[1]); var top = float(parts[2]);atlas.region = Rect2(left, top, float(parts[3]) - left, float(parts[4]) - top);return atlas

func plate(at, dimensions):
	var panel = ColorRect.new();panel.color = Color("10151c");panel.position = at;panel.size = dimensions;canvas.add_child(panel)

func label_at(value, at, dimensions, font = 20):
	var label = Label.new();label.text = value;label.position = at;label.size = dimensions;label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size", font);label.mouse_filter = Control.MOUSE_FILTER_IGNORE;canvas.add_child(label);return label

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/launcher/catalog.json"))
	canvas = Control.new();canvas.size = Vector2(1020, 666);add_child(canvas)
	for section in data.sections:
		if not section.section.begins_with("AREA "): continue
		var name = section.section.trim_prefix("AREA "); var fields = section.fields
		if name in ["TITLE", "DOWNLOAD", "GUNCELLENIYOR", "MINIMIZE", "CLOSE", "WEB_PAGE"]: continue
		var texture = image(fields.get("IMAGE_NORMAL", ""))
		if not texture: continue
		var position_values = numbers(fields.get("POSITION", "0,0")); var sprite = TextureRect.new();sprite.texture = texture;sprite.position = Vector2(position_values[0], position_values[1]);sprite.size = texture.get_size();sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE;canvas.add_child(sprite)
	plate(Vector2(390, 0), Vector2(240, 102)); var title = label_at("WOLF ROGUE\nBLOOD", Vector2(400, 8), Vector2(220, 88), 30);title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate(Vector2(492, 120), Vector2(498, 305))
	label_at("Çevrimiçi hesap girişi henüz kullanılamıyor.\nYerel denemeye devam edebilirsin.", Vector2(516, 163), Vector2(450, 180), 25)
	for row in [[455, false], [504, true]]:
		var field = LineEdit.new();field.position = Vector2(501, row[0]);field.size = Vector2(260, 30);field.editable = false;field.secret = row[1];field.placeholder_text = "Hesap hizmeti bağlı değil" if not row[1] else "";canvas.add_child(field)
	plate(Vector2(778, 445), Vector2(212, 90));label_at("ÇEVRİMİÇİ GİRİŞ\nBAĞLI DEĞİL", Vector2(795, 459), Vector2(180, 65), 19)
	plate(Vector2(495, 543), Vector2(495, 57));local_button = Button.new();local_button.text = "Yerel oyun · Sunucu seçimi";local_button.position = Vector2(500, 547);local_button.size = Vector2(485, 50);local_button.pressed.connect( func(): game.show_front_screen("servers"));canvas.add_child(local_button)
	plate(Vector2(0, 617), Vector2(1020, 49));label_at("WOLF ROGUE BLOOD", Vector2(20, 628), Vector2(500, 30), 20)
	resized.connect(fit);fit()

func fit():
	var dimensions = get_viewport().get_visible_rect().size; var ratio = minf(dimensions.x / 1020, dimensions.y / 666);canvas.scale = Vector2.ONE * ratio;canvas.position = (dimensions - Vector2(1020, 666) * ratio) * 0.5
