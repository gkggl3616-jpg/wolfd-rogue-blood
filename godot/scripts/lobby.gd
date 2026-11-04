extends PanelContainer
const PreviewCamera = preload("res://scripts/preview_camera.gd")
var game
var preview_wolf = false
var viewport: SubViewport
var model_root: Node3D
var form_label: Label
var preview_model: Node3D
var links = {}
var preview_camera: Camera3D

func button(parent, title, callback):
	var node = Button.new();node.text = title;node.custom_minimum_size.y = 54;node.pressed.connect(callback);parent.add_child(node);links[title] = node;return node

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 24;offset_top = 20;offset_right = -24;offset_bottom = -20
	var style = StyleBoxFlat.new();style.bg_color = Color("101722");style.border_color = Color("997b42");style.set_border_width_all(1);style.set_corner_radius_all(12);style.content_margin_left = 24;style.content_margin_right = 24;style.content_margin_top = 18;style.content_margin_bottom = 18;add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new();box.add_theme_constant_override("separation", 14);add_child(box)
	var head = HBoxContainer.new();box.add_child(head); var title = game.label("WOLF ROGUE BLOOD", 29);title.size_flags_horizontal = Control.SIZE_EXPAND_FILL;head.add_child(title)
	head.add_child(game.label("ÇEVRİMDIŞI DENEME", 17))
	var wallet = game.label("Nakit %d   KP %d   Altın %d   GP %d" % [game.wallet.cash, game.wallet.kp, game.wallet.gold, game.wallet.gp], 16);box.add_child(wallet)
	var body = HBoxContainer.new();body.size_flags_vertical = Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation", 22);box.add_child(body)
	var nav_scroll = ScrollContainer.new();nav_scroll.custom_minimum_size.x = 225;nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(nav_scroll)
	var nav = VBoxContainer.new();nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL;nav.add_theme_constant_override("separation", 10);nav_scroll.add_child(nav)
	for entry in [["Mağaza", "Mağaza"], ["Envanter", "Envanter"], ["Karakterler", "Karakterler"], ["Dövmeler", "Dövmeler"], ["Ayarlar", "Ayarlar"]]: button(nav, entry[0], func(): game.show_library(entry[1]))
	button(nav, "Güç slotu", game.show_inventory);button(nav, "Yerel yönetici", game.show_admin)
	button(nav, "Sunucu seçimi", func(): game.show_front_screen("servers"));button(nav, "Etkinlikler", func(): game.show_front_screen("events"))
	var center = VBoxContainer.new();center.size_flags_horizontal = Control.SIZE_EXPAND_FILL;body.add_child(center)
	form_label = game.label("", 21);form_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;center.add_child(form_label)
	var view = SubViewportContainer.new();view.stretch = true;view.size_flags_vertical = Control.SIZE_EXPAND_FILL;view.size_flags_horizontal = Control.SIZE_EXPAND_FILL;view.custom_minimum_size = Vector2(350, 360);center.add_child(view)
	viewport = SubViewport.new();viewport.size = Vector2i(420, 460);viewport.own_world_3d = true;view.add_child(viewport);model_root = Node3D.new();viewport.add_child(model_root)
	var light = DirectionalLight3D.new();light.rotation_degrees = Vector3(-25, -25, 0);light.light_energy = 2;model_root.add_child(light)
	var environment = WorldEnvironment.new(); var settings = Environment.new();settings.background_mode = Environment.BG_COLOR;settings.background_color = Color("131e2c");settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color = Color("c5d8ed");settings.ambient_light_energy = 0.55;environment.environment = settings;model_root.add_child(environment)
	preview_camera = Camera3D.new();preview_camera.fov = 50;model_root.add_child(preview_camera)
	viewport.size_changed.connect(frame_preview)
	view.gui_input.connect( func(event):
		if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and is_instance_valid(preview_model): preview_model.rotation.y += event.relative.x * 0.01
	)
	var forms = HBoxContainer.new();center.add_child(forms)
	for entry in [["İnsan", false], ["Kurt", true]]: button(forms, entry[0], func(): preview_wolf = entry[1];refresh_model()).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right = VBoxContainer.new();right.custom_minimum_size.x = 320;right.add_theme_constant_override("separation", 12);body.add_child(right)
	right.add_child(game.label("EKİPMAN %d" % (game.book.active_loadout + 1), 22))
	for entry in [["Ana silah", "primary"], ["Tabanca", "pistol"], ["Bıçak", "knife"], ["Bomba", "grenade"]]:
		var item = game.book.weapon(game.book.slots.get(entry[1], "")); var line = game.label(entry[0] + "\n" + item.get("name", "Boş"), 17);line.custom_minimum_size = Vector2(320, 58);line.clip_text = true;right.add_child(line)
	button(right, "Deneme arenasına gir", game.start_round)
	button(right, "Haritaları gez", game.show_maps)
	var hint = game.label("Arenada 90 saniyede 10 hedef. Harita gezintisi maç başlatmaz.", 15);hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;hint.custom_minimum_size.x = 320;right.add_child(hint)
	refresh_model()

func refresh_model():
	if is_instance_valid(preview_model): model_root.remove_child(preview_model);preview_model.queue_free()
	preview_model = (game.player.wolf if preview_wolf else game.player.human).duplicate();preview_model.position = Vector3.ZERO;preview_model.rotation = Vector3.ZERO;preview_model.show();model_root.add_child(preview_model)
	for animation in preview_model.find_children("*", "AnimationPlayer", true, false): animation.play("idle");animation.advance(0)
	form_label.text = str(game.character_info.get("name", "Karakter")) + " · " + ("Kurt" if preview_wolf else "İnsan")
	frame_preview()

func frame_preview():
	if is_instance_valid(preview_camera) and is_instance_valid(preview_model):
		PreviewCamera.frame(preview_camera, model_root, Vector2(viewport.size))
