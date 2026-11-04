extends Control
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
var game
var health_view
var weapon_view
var timer_view
var score:Label
var weapon_name:Label
var preview_name:Label
var slots=[]
var menu:TextureButton
var inventory:TextureButton
var cross:TextureRect
var last_state=[]

func part(key,dimensions,keep):
	var view=Layout.new();add_child(view);view.configure(key,dimensions)
	for i in range(view.records.size()):view.controls[i].visible=view.records[i].name in keep
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	health_view=part("interface/hudplayer",Vector2(100,71),["HPBack","HealthPoint"]);health_view.scale=Vector2.ONE*1.5
	# The lower source plate contains baked YP placeholders. Show only the
	# implemented health region; unavailable YP must not appear as live state.
	var plate=health_view.find_widget("HPBack")
	if plate.texture is AtlasTexture:
		plate.texture=plate.texture.duplicate();plate.texture.region.size.y=41;plate.size.y=41
	Art.section(self,"CAN",Vector2(20,16),Vector2(160,40))
	weapon_view=part("interface/hudweapon",Vector2(150,128),["CurrentBullet","MaxBullet"]);weapon_view.scale=Vector2.ONE*1.4
	var current=weapon_view.find_widget("CurrentBullet");current.position=Vector2.ZERO
	var maximum=weapon_view.find_widget("MaxBullet");maximum.position=Vector2(78,0)
	var slash=Art.label("/",Vector2(20,40),25);slash.position=Vector2(61,-2);weapon_view.add_child(slash)
	weapon_name=Art.label("",Vector2(350,34),18);weapon_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;add_child(weapon_name)
	timer_view=part("interface/hudtimer",Vector2(86,41),["Colon","Minute","Second"]);timer_view.scale=Vector2.ONE*1.4
	var minute=timer_view.find_widget("Minute");minute.position=Vector2(0,7);minute.size=Vector2(32,23);minute.alignment=2
	var second=timer_view.find_widget("Second");second.position=Vector2(48,7);second.size=Vector2(32,23);second.alignment=1
	var colon=timer_view.find_widget("Colon");colon.text=":";colon.position=Vector2(32,2);colon.size=Vector2(16,32);colon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	score=Art.label("",Vector2(300,36),19,Art.GOLD);score.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(score)
	preview_name=Art.label("",Vector2(800,38),19,Art.GOLD);preview_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(preview_name)
	cross=Art.sprite(self,"wt_interface/crosshair/cross_pistol.dtx",Vector2.ZERO,Vector2(32,32));game.crosshair=cross
	menu=Art.button(self,"Menü",Vector2.ZERO,Vector2(112,52),game.pause_game)
	inventory=Art.button(self,"Envanter",Vector2.ZERO,Vector2(140,52),func():game.show_library("Envanter"))
	game.gui_touch_blockers.append(menu);game.gui_touch_blockers.append(inventory)
	for row in [["ANA","primary"],["TABANCA","pistol"],["BIÇAK","knife"],["BOMBA","grenade"]]:
		var button=Art.button(self,row[0],Vector2.ZERO,Vector2(104,50),func():game.equip_slot(row[1]));slots.append(button);game.gui_touch_blockers.append(button)
	resized.connect(arrange);arrange();refresh_from_game()

func arrange():
	if not is_instance_valid(menu):return
	var dimensions=get_viewport_rect().size
	health_view.position=Vector2(36,56)
	weapon_view.position=Vector2(dimensions.x-220,176);weapon_name.position=Vector2(dimensions.x-370,220)
	timer_view.position=Vector2(dimensions.x*0.5-60,16)
	score.position=Vector2(dimensions.x*0.5-150,62)
	preview_name.position=Vector2(dimensions.x*0.5-400,20)
	menu.position=Vector2(dimensions.x-272,16);inventory.position=Vector2(dimensions.x-150,16)
	for i in range(slots.size()):slots[i].position=Vector2(dimensions.x*0.5-220+i*112,105)
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
	score.text="EĞİTİM · HEDEF %d / 10" % game.kills
	timer_view.visible=not game.exploring;score.visible=not game.exploring
	preview_name.visible=game.exploring;preview_name.text=game.preview_name+" · GEZİNTİ / MAÇ KAPALI"

func _process(_delta):refresh_from_game()
