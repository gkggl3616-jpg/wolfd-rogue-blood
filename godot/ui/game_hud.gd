extends Control
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const Radar=preload("res://ui/local_radar.gd")
const Feedback=preload("res://ui/combat_feedback.gd")
class AimReticle extends Control:
	func _draw():
		var center=Vector2(16,16)
		for i in range(4):
			var axis=Vector2.from_angle(PI*i/2)
			draw_line(center+axis*4,center+axis*10,Color("7cec65"),1.5,true)
		draw_circle(center,1,Color.WHITE)
class RoundButton extends Button:
	func _draw():
		var center=size*0.5;var radius=minf(size.x,size.y)*0.5-1
		draw_circle(center,radius,Color(0.035,0.045,0.05,0.65 if not is_pressed() else 0.9))
		draw_arc(center,radius,0,TAU,48,Color(0.7,0.76,0.77,0.6),1.2,true)
var game
var health_view
var weapon_view
var timer_view
var score_view
var score:Label
var weapon_name:Label
var preview_name:Label
var map_name:Label
var slots=[]
var slot_icons=[]
var slot_ids=[]
var menu:Button
var inventory:Button
var cross:Control
var last_state=[]
var pc_layer:Control
var radar
var feedback
var class_icon:TextureRect

func part(key,dimensions,keep):
	var view=Layout.new();pc_layer.add_child(view);view.configure(key,dimensions)
	view.show_only(keep)
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

func round_button(dimensions):
	var button=RoundButton.new();button.flat=true;button.focus_mode=Control.FOCUS_NONE;button.size=dimensions;button.custom_minimum_size=dimensions
	for state in ["normal","hover","pressed","focus","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	return button

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	feedback=Feedback.new();feedback.game=game;add_child(feedback)
	pc_layer=Control.new();pc_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(pc_layer)
	health_view=part("interface/hudplayer",Vector2(100,71),["HPBack","HealthPoint"])
	# self_modulate hides only the plate, not its health-number child.
	health_view.find_widget("HPBack").self_modulate.a=0
	health_view.find_widget("HealthPoint").modulate=Color("f32639")
	weapon_view=part("interface/hudweapon",Vector2(116,64),["CurrentBullet","MaxBullet"])
	weapon_name=Art.label("",Vector2(260,20),12);weapon_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;pc_layer.add_child(weapon_name)
	score_view=part("interface/hudscore",Vector2(312,64),["Mode","RedTeamScore","BlueTeamScore"])
	var background=Art.sprite(score_view,"wt_interface/play/common/pl_score.dtx",Vector2.ZERO,Vector2(312,60),Rect2(0,0,312,60))
	background.modulate=Color(0.4,0.42,0.44,0.9);score_view.move_child(background,0)
	for row in [[5,Color("602832")],[255,Color("214554")]]:
		var plate=ColorRect.new();plate.color=row[1];plate.position=Vector2(row[0],5);plate.size=Vector2(55,55);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;score_view.add_child(plate)
	class_icon=Art.sprite(score_view,"res://assets/ui/form-icons/human.png",Vector2(5,5),Vector2(55,55))
	Art.sprite(score_view,"res://assets/ui/form-icons/wolf.png",Vector2(255,5),Vector2(55,55))
	var kills=score_view.find_widget("RedTeamScore");kills.position=Vector2(98,28);kills.size=Vector2(45,23);kills.alignment=3;kills.modulate=Color("f32639")
	var goal=score_view.find_widget("BlueTeamScore");goal.position=Vector2(177,28);goal.size=Vector2(45,23);goal.alignment=3;goal.modulate=Color("59c1e4")
	var slash=Art.label("/",Vector2(18,23),18);slash.position=Vector2(148,27);slash.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;score_view.add_child(slash)
	score=Art.label("HEDEF",Vector2(78,16),10,Color("bdc6c9"));score.position=Vector2(175,8);score_view.add_child(score)
	timer_view=part("interface/hudtimer",Vector2(86,41),["Colon","Minute","Second"])
	var minute=timer_view.find_widget("Minute");minute.position=Vector2(0,4);minute.size=Vector2(32,23);minute.alignment=2
	var second=timer_view.find_widget("Second");second.position=Vector2(48,4);second.size=Vector2(32,23);second.alignment=1
	var colon=timer_view.find_widget("Colon");colon.text=":";colon.position=Vector2(32,-1);colon.size=Vector2(16,32);colon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	preview_name=Art.label("",Vector2(500,23),12,Art.GOLD);preview_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(preview_name)
	map_name=Art.label("",Vector2(155,20),10,Color("c6cecf"));pc_layer.add_child(map_name)
	radar=Radar.new();radar.game=game;radar.size=Vector2(128,128);pc_layer.add_child(radar)
	cross=AimReticle.new();cross.size=Vector2(32,32);cross.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(cross);game.crosshair=cross
	menu=round_button(Vector2(42,42));menu.tooltip_text="Menü";menu.pressed.connect(game.pause_game);pc_layer.add_child(menu)
	inventory=round_button(Vector2(42,42));inventory.tooltip_text="Envanter";inventory.pressed.connect(func():game.show_library("Envanter"));pc_layer.add_child(inventory)
	Art.sprite(menu,"wt_interface/all/a_lb_icon_option.dtx",Vector2(9,9),Vector2(24,24),Rect2(4,0,24,22))
	Art.sprite(inventory,"wt_interface/all/a_lb_icon_inven.dtx",Vector2(9,9),Vector2(24,24),Rect2(4,0,24,22))
	game.gui_touch_blockers.append(menu);game.gui_touch_blockers.append(inventory)
	var number=0
	for slot in ["primary","pistol","knife","grenade"]:
		var button=round_button(Vector2(44,44))
		button.tooltip_text="Ana silahlar arasında geç" if slot=="primary" else {"pistol":"Tabanca","knife":"Bıçak","grenade":"Bomba"}[slot]
		button.pressed.connect(func():
			if slot=="primary":game.cycle_primary()
			else:game.equip_slot(slot)
		)
		var icon=Art.sprite(button,"",Vector2(4,9),Vector2(36,24));icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var key=Art.label(str([1,2,5,4][number]),Vector2(10,14),8,Color("c1b77e"));key.position=Vector2(18,29);button.add_child(key)
		pc_layer.add_child(button);slots.append(button);slot_icons.append(icon);slot_ids.append(slot);game.gui_touch_blockers.append(button);number+=1
	resized.connect(arrange);arrange();refresh_from_game()

func arrange():
	if not is_instance_valid(menu):return
	var dimensions=get_viewport_rect().size
	var factor=dimensions.y/645.0
	pc_layer.scale=Vector2.ONE*factor;pc_layer.size=dimensions/factor
	var native=pc_layer.size
	health_view.position=Vector2(24,native.y-53)
	weapon_view.position=Vector2(native.x-143,native.y-91);weapon_name.position=Vector2(native.x-287,native.y-25)
	score_view.position=Vector2(native.x*0.5-156,4)
	timer_view.position=Vector2(native.x*0.5-43,64)
	preview_name.position=Vector2(native.x*0.5-250,8)
	map_name.position=Vector2(native.x*0.82,7);radar.position=Vector2(native.x*0.82,28)
	menu.position=Vector2(native.x*0.05,7);inventory.position=Vector2(native.x*0.05+48,7)
	for i in range(slots.size()):slots[i].position=Vector2(native.x*0.5-104+i*52,native.y-48)
	cross.position=dimensions*0.5-Vector2(16,16)

func refresh_from_game():
	visible=game.running and not game.menu_open
	if not is_instance_valid(game.player):return
	cross.visible=visible and not game.player.is_wolf
	var state=[game.health,game.ammo,game.reserve,int(game.time_left),game.kills,game.current_weapon_id,game.reloading>0,game.exploring,game.player.is_wolf,game.preview_name,game.book.slots.duplicate()]
	if state==last_state:return
	last_state=state
	health_view.set_value("HealthPoint",game.health)
	weapon_view.visible=not game.player.is_wolf and game.player.weapon_info.get("category","")!="knife"
	weapon_view.set_value("CurrentBullet",game.ammo);weapon_view.set_value("MaxBullet",game.reserve)
	weapon_name.text="KURT" if game.player.is_wolf else ("ŞARJÖR…" if game.reloading>0 else game.player.weapon_info.get("name",""))
	var seconds=maxi(0,int(game.time_left));timer_view.set_value("Minute","%02d" % int(seconds/60));timer_view.set_value("Second","%02d" % (seconds%60))
	score_view.set_value("RedTeamScore",game.kills);score_view.set_value("BlueTeamScore",10);score_view.set_value("Mode","Yerel Eğitim")
	class_icon.texture=Art.texture("res://assets/ui/form-icons/wolf.png" if game.player.is_wolf else "res://assets/ui/form-icons/human.png")
	timer_view.visible=not game.exploring;score_view.visible=not game.exploring
	preview_name.visible=game.exploring;preview_name.text=game.preview_name+" · GEZİNTİ"
	map_name.text=game.preview_name
	for i in range(slots.size()):
		slots[i].visible=not game.player.is_wolf
		var id=game.book.slots.get(slot_ids[i],"")
		var entry=game.book.weapon(id)
		slot_icons[i].texture=Art.atlas(entry.get("icon",""),Rect2(0,0,210,75))
		slots[i].modulate=Color.WHITE if id==game.current_weapon_id else Color(0.8,0.85,0.85,0.5)

func _process(_delta):refresh_from_game()
