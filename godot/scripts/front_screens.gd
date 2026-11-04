extends Control
const Layout = preload("res://scripts/pc_layout.gd")
var game
var page = "entry"
var canvas: Control
var source_view
var links = {}

func label_at(value, at, dimensions, font = 20):
	var text = Label.new();text.text = value;text.position = at;text.size = dimensions;text.add_theme_font_size_override("font_size", font);text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;text.mouse_filter = Control.MOUSE_FILTER_IGNORE;canvas.add_child(text);return text

func button_at(value, at, dimensions, callback):
	var button = Button.new();button.text = value;button.position = at;button.size = dimensions;button.pressed.connect(callback);canvas.add_child(button);links[value] = button;return button

func plate(at, dimensions):
	var panel = ColorRect.new();panel.color = Color("0b1018");panel.position = at;panel.size = dimensions;canvas.add_child(panel)

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new();canvas.size = Vector2(1024, 768);add_child(canvas)
	source_view = Control.new();source_view.set_script(Layout);canvas.add_child(source_view)
	var layout = "section/title" if page == "entry" else ("section/serverlist" if page == "servers" else "interface/wolfeventdialog")
	source_view.configure(layout)
	if page == "entry":

		plate(Vector2(375, 444), Vector2(275, 150))
		var title = label_at("WOLF ROGUE\nBLOOD", Vector2(385, 459), Vector2(255, 120), 34);title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_at("Sunucu seçimi", Vector2(312, 620), Vector2(400, 56), func(): game.show_front_screen("servers"))
		button_at("Yerel deneme", Vector2(312, 686), Vector2(400, 56), game.show_home)
	else:
		plate(Vector2.ZERO, Vector2(1024, 58));label_at("WOLF ROGUE BLOOD", Vector2(14, 15), Vector2(400, 36), 25)
		button_at("Giriş", Vector2(470, 4), Vector2(120, 50), func(): game.show_front_screen("entry"))
		button_at("Sunucular", Vector2(600, 4), Vector2(140, 50), func(): game.show_front_screen("servers"))
		button_at("Etkinlikler", Vector2(750, 4), Vector2(140, 50), func(): game.show_front_screen("events"))
		button_at("Lobi", Vector2(900, 4), Vector2(110, 50), game.show_home)
		if page == "servers":
			for i in range(source_view.records.size()):
				if source_view.records[i].name != "BackGround": source_view.controls[i].hide()
			var local = source_view.find_widget("Server", 100);local.show();local.position = Vector2(462, 132);local.size = Vector2(548, 56);source_view.bind_action("Server", game.show_home, 100)
			var caption = Label.new();caption.text = "YEREL DENEME";caption.position = Vector2(16, 14);caption.size = Vector2(490, 32);caption.mouse_filter = Control.MOUSE_FILTER_IGNORE;local.add_child(caption)
			label_at("Yerel oyun hazır. Çevrimiçi sunucu listesi bağlı değil.", Vector2(25, 142), Vector2(402, 150), 22)
			label_at("Çevrimiçi sunucular için hesap ve maç sunucusu bağlantısı gerekiyor.", Vector2(470, 215), Vector2(530, 100), 20)
		else:
			for i in range(source_view.records.size()):
				if source_view.records[i].name != "BackGround": source_view.controls[i].hide()
			label_at("Etkinlik hizmeti bağlı değil. Aktif etkinlik ve ödül verisi alınamadı.", Vector2(65, 207), Vector2(870, 100), 24)
			button_at("Lobiye dön", Vector2(740, 655), Vector2(220, 56), game.show_home)
	resized.connect(fit);fit()

func fit():
	var viewport_size = get_viewport().get_visible_rect().size; var ratio = minf(viewport_size.x / 1024.0, viewport_size.y / 768.0);canvas.scale = Vector2.ONE * ratio;canvas.position = (viewport_size - Vector2(1024, 768) * ratio) * 0.5
