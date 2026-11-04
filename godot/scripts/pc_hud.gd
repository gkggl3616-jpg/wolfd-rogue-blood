extends Control

const Layout = preload("res://scripts/pc_layout.gd")
var game
var health_view
var weapon_view
var timer_view
var score_view
var weapon_label: Label
var reload_label: Label
var last_state = []
var last_weapon = ""

func part(key, dimensions, keep):
	var view = Control.new();view.set_script(Layout);add_child(view);view.configure(key, dimensions)
	for i in range(view.records.size()): view.controls[i].visible = view.records[i].name in keep
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE;return view

func label_at(parent, value, at, dimensions, font_size):
	var node = Label.new();node.text = value;node.position = at;node.size = dimensions;node.add_theme_font_size_override("font_size", font_size);node.mouse_filter = Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_view = part("interface/hudplayer", Vector2(100, 71), ["HPBack", "HealthPoint"]);health_view.scale = Vector2.ONE * 1.35
	weapon_view = part("interface/hudweapon", Vector2(150, 128), ["WeaponBack", "WeaponName", "Bullet", "CurrentBullet", "MaxBullet"]);weapon_view.scale = Vector2.ONE * 1.3
	weapon_label = label_at(weapon_view, "", Vector2(-80, 82), Vector2(235, 28), 14);weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;weapon_label.clip_text = true
	reload_label = label_at(weapon_view, "", Vector2(-80, 110), Vector2(235, 24), 14);reload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_view = part("interface/hudtimer", Vector2(86, 41), ["Colon", "Minute", "Second"]);timer_view.scale = Vector2.ONE * 1.4

	var minute = timer_view.find_widget("Minute");minute.position = Vector2(0, 7);minute.size = Vector2(32, 23);minute.alignment = 2
	var second = timer_view.find_widget("Second");second.position = Vector2(48, 7);second.size = Vector2(32, 23);second.alignment = 1
	var colon = timer_view.find_widget("Colon");colon.text = ":";colon.position = Vector2(32, 2);colon.size = Vector2(16, 32);colon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;colon.add_theme_font_size_override("font_size", 24)
	score_view = part("interface/hudscore", Vector2(120, 40), ["MyKill", "MaxPoint"]);score_view.find_widget("MyKill").position = Vector2.ZERO;score_view.find_widget("MaxPoint").position = Vector2(85, 4)
	label_at(score_view, "HEDEF", Vector2(-62, 0), Vector2(60, 30), 17);label_at(score_view, "/", Vector2(66, -3), Vector2(15, 30), 23)
	resized.connect(arrange);arrange();refresh_from_game()

func arrange():
	if not health_view: return
	var canvas = get_viewport().get_visible_rect().size
	health_view.position = Vector2(28, 133);weapon_view.position = Vector2(canvas.x - 205, 147)
	timer_view.position = Vector2(canvas.x * 0.5 - 60, 22);score_view.position = Vector2(canvas.x * 0.5 - 27, 65)

func refresh_from_game():
	var state = [game.running, game.menu_open, game.player.is_wolf, game.ammo, game.reserve, game.health, int(game.time_left), game.kills, game.exploring, game.current_weapon_id, game.reloading > 0]
	if state == last_state: return
	last_state = state;visible = game.running and not game.menu_open
	health_view.set_value("HealthPoint", game.health)
	weapon_view.visible = not game.player.is_wolf
	var knife = game.player.weapon_info.get("category", "") == "knife"
	for key in ["CurrentBullet", "MaxBullet", "Bullet"]: weapon_view.find_widget(key).visible = not knife
	weapon_view.set_value("CurrentBullet", game.ammo);weapon_view.set_value("MaxBullet", game.reserve)
	reload_label.text = "ŞARJÖR…" if game.reloading > 0 else ""
	if last_weapon != game.current_weapon_id:
		last_weapon = game.current_weapon_id
		var item = game.book.weapon(last_weapon);weapon_label.text = item.get("name", game.player.weapon_info.get("name", ""))
		var icon = weapon_view.find_widget("WeaponName")
		icon.texture = load(item.icon) if not item.is_empty() else null;icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	timer_view.visible = not game.exploring;score_view.visible = not game.exploring
	var seconds = maxi(0, int(game.time_left));timer_view.set_value("Minute", "%02d" % int(seconds / 60));timer_view.set_value("Second", "%02d" % (seconds % 60))
	score_view.set_value("MyKill", game.kills);score_view.set_value("MaxPoint", 10)

func _process(_delta): refresh_from_game()
