extends Control
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
var game
var health_view
var weapon_view
var timer_view
var score_view
var score:Label
var weapon_name:Label
var preview_name:Label
var slots=[]
var menu:TextureButton
var inventory:TextureButton
var cross:TextureRect
var last_state=[]
var pc_layer:Control

func part(key,dimensions,keep):
	var view=Layout.new();pc_layer.add_child(view);view.configure(key,dimensions)
	for i in range(view.records.size()):view.controls[i].visible=view.records[i].name in keep
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	pc_layer=Control.new();pc_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(pc_layer)
	health_view=part("interface/hudplayer",Vector2(100,71),["HPBack","HealthPoint"])
	# YP is not implemented: the source health plate's lower YP row is hidden.
	var plate=health_view.find_widget("HPBack")
	if plate.texture is AtlasTexture:
		plate.texture=plate.texture.duplicate();plate.texture.region.size.y=41;plate.size.y=41
	weapon_view=part("interface/hudweapon",Vector2(150,128),["CurrentBullet","MaxBullet"])
	var current=weapon_view.find_widget("CurrentBullet");current.position=Vector2(0,32)
	var maximum=weapon_view.find_widget("MaxBullet");maximum.position=Vector2(61,39)
	weapon_name=Art.label("",Vector2(280,20),12);weapon_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;pc_layer.add_child(weapon_name)
	score_view=part("interface/hudscore",Vector2(312,64),["Mode","MaxPoint","RedTeamScore"])
	var background=Art.sprite(score_view,"wt_interface/play/common/pl_score.dtx",Vector2.ZERO,Vector2(312,60),Rect2(0,0,312,60));score_view.move_child(background,0)
	score_view.set_value("Mode","Yerel Eğitim");score_view.set_value("MaxPoint",10)
	var kills=score_view.find_widget("RedTeamScore");kills.position=Vector2(139,29);kills.size=Vector2(36,23);kills.alignment=3
	score=Art.label("HEDEF",Vector2(60,16),10,Color("bdc6c9"));score.position=Vector2(198,8);score_view.add_child(score)
	timer_view=part("interface/hudtimer",Vector2(86,41),["Colon","Minute","Second"])
	var minute=timer_view.find_widget("Minute");minute.position=Vector2(0,7);minute.size=Vector2(32,23);minute.alignment=2
	var second=timer_view.find_widget("Second");second.position=Vector2(48,7);second.size=Vector2(32,23);second.alignment=1
	var colon=timer_view.find_widget("Colon");colon.text=":";colon.position=Vector2(32,2);colon.size=Vector2(16,32);colon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	preview_name=Art.label("",Vector2(650,23),12,Art.GOLD);preview_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(preview_name)
	cross=Art.sprite(self,"wt_interface/crosshair/cross_pistol.dtx",Vector2.ZERO,Vector2(32,32));game.crosshair=cross
	menu=Art.icon_button(pc_layer,"wt_interface/all/a_lb_icon_option.dtx",Vector2.ZERO,"Menü",game.pause_game)
	inventory=Art.icon_button(pc_layer,"wt_interface/all/a_lb_icon_inven.dtx",Vector2.ZERO,"Envanter",func():game.show_library("Envanter"))
	game.gui_touch_blockers.append(menu);game.gui_touch_blockers.append(inventory)
	for row in [["1  ANA","primary"],["2  İKİNCİ","pistol"],["5  BIÇAK","knife"],["4  BOMBA","grenade"]]:
		var button=Art.button(pc_layer,row[0],Vector2.ZERO,Vector2(82,28),func():
			if row[1]=="primary":game.cycle_primary()
			else:game.equip_slot(row[1])
		);slots.append(button);game.gui_touch_blockers.append(button)
	resized.connect(arrange);arrange();refresh_from_game()

func arrange():
	if not is_instance_valid(menu):return
	var dimensions=get_viewport_rect().size
	var factor=dimensions.y/768.0
	pc_layer.scale=Vector2.ONE*factor;pc_layer.size=dimensions/factor
	var native=pc_layer.size
	health_view.position=Vector2(16,native.y-63)
	weapon_view.position=Vector2(native.x-132,native.y-102);weapon_name.position=Vector2(native.x-296,native.y-24)
	score_view.position=Vector2(native.x*0.5-156,6)
	timer_view.position=Vector2(native.x*0.5-43,64)
	preview_name.position=Vector2(native.x*0.5-325,12)
	menu.position=Vector2(native.x-44,8);inventory.position=Vector2(native.x-84,8)
	for i in range(slots.size()):slots[i].position=Vector2(native.x*0.5-170+i*86,native.y-35)
	cross.position=dimensions*0.5-Vector2(16,16)

func refresh_from_game():
	visible=game.running and not game.menu_open
	if not is_instance_valid(game.player):return
	var state=[game.health,game.ammo,game.reserve,int(game.time_left),game.kills,game.current_weapon_id,game.reloading>0,game.exploring,game.player.is_wolf,game.preview_name]
	if state==last_state:return
	last_state=state
	health_view.set_value("HealthPoint",game.health)
	weapon_view.visible=not game.player.is_wolf and game.player.weapon_info.get("category","")!="knife"
	weapon_name.visible=not game.player.is_wolf
	weapon_view.set_value("CurrentBullet",game.ammo);weapon_view.set_value("MaxBullet",game.reserve)
	weapon_name.text="ŞARJÖR…" if game.reloading>0 else game.player.weapon_info.get("name","")
	var seconds=maxi(0,int(game.time_left));timer_view.set_value("Minute","%02d" % int(seconds/60));timer_view.set_value("Second","%02d" % (seconds%60))
	score_view.set_value("RedTeamScore",game.kills)
	timer_view.visible=not game.exploring;score_view.visible=not game.exploring
	preview_name.visible=game.exploring;preview_name.text=game.preview_name+" · GEZİNTİ / MAÇ KAPALI"

func _process(_delta):refresh_from_game()
