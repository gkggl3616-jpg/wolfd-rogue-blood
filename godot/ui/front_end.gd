extends Control

const Art = preload("res://ui/source_theme.gd")
const Layout = preload("res://ui/source_layout.gd")
const CameraFit = preload("res://scripts/preview_camera.gd")
const CollectionPage = preload("res://ui/collection_page.gd")
const SettingsPage = preload("res://ui/settings_page.gd")
const PcScreens = preload("res://ui/pc_screens.gd")

const NAMES = {"entry":"Giriş", "servers":"Sunucular", "lobby":"Lobi", "room":"Oda", "create_room":"Oda Oluştur", "maps":"Mod ve Haritalar", "pause":"Duraklatıldı", "result":"Maç Sonucu", "admin":"Yerel Yönetim", "power":"Güç Slotu", "events":"Etkinlikler", "missions":"Görevler", "gifts":"Hediyeler", "friends":"Arkadaşlar", "clan":"Klan", "ranking":"Sıralama"}
const SERVICE_LAYOUTS = {"events":"interface/wolfeventdialog", "missions":"interface/mission/missionsheet", "gifts":"interface/giftbox", "friends":"interface/gamebuddy", "clan":"section/pride", "ranking":"section/rankingsection"}
var game
var page = "lobby"
var canvas: Control
var content: Control
var links = {}
var history = []
var virtual_width = 1024.0
var pending_refresh = false
var building = false
var source_layouts = []
var wallet_label: Label
var notice: Label
var detail_helper
var modal: Control
var selected = {}
var search_query = ""
var filter_id = "all"
var offset = 0
var room_title: LineEdit
var room_mode: OptionButton
var room_map: OptionButton
var mode_choice = 0
var map_choice = 0
var preview_view: SubViewport
var preview_root: Node3D
var preview_model: Node3D
var preview_camera: Camera3D
var preview_container: SubViewportContainer
var preview_wolf = false
var settings_draft = {}
var settings_dirty = false
var settings_tab = "Ses"
var last_error = ""

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Art.theme()
	resized.connect(schedule_refresh)
	refresh()

func schedule_refresh():
	if pending_refresh or building or not is_inside_tree() or is_queued_for_deletion(): return
	pending_refresh = true
	call_deferred("refresh")

func refresh():
	pending_refresh = false
	if not is_inside_tree() or is_queued_for_deletion():return
	building = true
	for child in get_children(): remove_child(child);child.queue_free()
	links.clear();source_layouts.clear();modal = null;preview_model = null;preview_view = null;preview_container = null;detail_helper = null
	var dimensions = get_viewport_rect().size
	var factor = minf(dimensions.y / 768.0, dimensions.x / 1024.0)
	virtual_width = 1024.0
	var shade = ColorRect.new();shade.color = Color("050709");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	canvas = Control.new();canvas.size = Vector2(virtual_width,768);canvas.scale = Vector2.ONE * factor;canvas.position = (dimensions-Vector2(1024,768)*factor)*0.5;add_child(canvas)
	background("wt_interface/lobby/lb_bg.dtx" if page in ["lobby","room","create_room","maps"] else "wt_interface/inven_shop/is_bg.dtx", 607 if page in ["lobby","room","create_room","maps"] else 352)
	content = Control.new();content.position.y = 0;content.size = Vector2(virtual_width,768);canvas.add_child(content)
	var desktop = PcScreens.new();desktop.ui = self;desktop.build()
	if page not in ["entry","pause","Ayarlar","create_room"]: build_header()
	wallet_label = text(canvas,"",Vector2(16,746),Vector2(virtual_width-290,22),16)
	text(canvas,"ÇEVRİMDIŞI · YEREL OTURUM",Vector2(virtual_width-280,746),Vector2(264,22),14,Art.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	building = false
	if not last_error.is_empty(): show_error(last_error)

func trace(source):
	if source not in source_layouts: source_layouts.append(source)
	set_meta("source_layouts",source_layouts)

func background(source, split):
	var extra = virtual_width - 1024
	Art.sprite(canvas,source,Vector2.ZERO,Vector2(split+extra,768),Rect2(0,0,split,768))
	Art.sprite(canvas,source,Vector2(split+extra,0),Vector2(1024-split,768),Rect2(split,0,1024-split,768))

func text(parent,value,at,dimensions,font_size=20,color=Color.WHITE):
	var node = Art.label(value,dimensions,font_size,color);node.position = at;parent.add_child(node);return node

func paragraph(parent,value,at,dimensions,font_size=20):
	var label = text(parent,value,at,dimensions,font_size);label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func button(parent,title,at,dimensions,callback,enabled=true):
	var node = Art.button(parent,title,at,dimensions,callback);node.disabled = not enabled;links[title] = node;return node

func native(source,parent,at=Vector2.ZERO,dimensions=Vector2(1024,768)):
	trace(source)
	var node = Layout.new();parent.add_child(node);node.configure(source,dimensions);node.position = at
	return node

func build_header():
	# The source background contains the old product mark only in this rectangle.
	var mark = ColorRect.new();mark.position = Vector2.ZERO;mark.size = Vector2(246,58);mark.color = Color("242628");canvas.add_child(mark)
	text(canvas,"WOLF ROGUE BLOOD",Vector2(14,14),Vector2(228,32),20,Art.GOLD)
	var entries = [["Lobi","lobby"],["Envanter","Envanter"],["Karakter","Karakterler"],["Mağaza","Mağaza"],["Ayarlar","Ayarlar"],["Diğer",""]]
	var width = minf(132,(virtual_width-368)/float(entries.size()))
	for i in range(entries.size()):
		var entry = entries[i]
		button(canvas,entry[0],Vector2(250+i*width,4),Vector2(width-4,50),func():
			if entry[1]=="":choose_section()
			else:navigate(entry[1])
		)
	button(canvas,"Geri",Vector2(virtual_width-110,4),Vector2(102,50),go_back)

func choose_section():
	confirm("Menüler","",func():pass)
	var entries=[["Görevler","missions"],["Etkinlikler","events"],["Hediyeler","gifts"],["Arkadaşlar","friends"],["Klan","clan"],["Sıralama","ranking"],["Dövmeler","Dövmeler"],["Efektler","Efektler"],["Yerel yönetim","admin"]]
	for i in range(entries.size()):
		var entry=entries[i]
		button(modal,entry[0],Vector2(296+(i%2)*230,292+int(i/2)*38),Vector2(200,30),func():close_modal();navigate(entry[1]))

func _process(_delta):
	if is_instance_valid(wallet_label): wallet_label.text = "%s     Nakit %d     KP %d     Altın %d     GP %d" % [game.profile_name,game.wallet.cash,game.wallet.kp,game.wallet.gold,game.wallet.gp]
	if detail_helper != null and detail_helper.has_method("update"): detail_helper.update(_delta)

func navigate(next,remember=true,back_step=false):
	if modal != null: return
	if page == "Ayarlar" and settings_dirty:
		confirm("Kaydedilmemiş ayarlar", "Değişiklikleri uygulayıp devam et?", func():
			if detail_helper.apply(): navigate(next,remember,back_step)
		,func(): settings_dirty = false;navigate(next,remember,back_step))
		return
	if back_step and not history.is_empty(): history.pop_back()
	if remember and page != next: history.append(page)
	if next == "Ayarlar" and page != "Ayarlar": settings_draft = game.book.settings.duplicate(true);settings_dirty = false
	page = next;offset = 0;selected = {};search_query = "";filter_id = "all";last_error = ""
	refresh()

func go_back():
	if modal != null: close_modal();return
	if not history.is_empty(): navigate(history.back(),false,true)
	elif game.running: close_menu()
	elif page != "lobby": navigate("lobby",false)

func close_menu():
	if page == "Ayarlar" and settings_dirty:
		confirm("Kaydedilmemiş ayarlar","Ayarları uygulayıp kapat?",func():
			if detail_helper.apply(): close_menu()
		,func(): settings_dirty = false;close_menu())
		return
	if game.library_panel == self: game.library_panel = null
	if game.pc_panel == self: game.pc_panel = null
	get_parent().remove_child(self);queue_free()
	if game.running: game.resume()
	else: game.show_home()

func show_error(value):
	last_error = str(value)
	if is_instance_valid(notice): notice.queue_free()
	notice = paragraph(canvas,last_error,Vector2(virtual_width*0.2,678),Vector2(virtual_width*0.6,60),19)
	notice.add_theme_color_override("font_color",Color("ffc278"));notice.z_index = 50

func close_modal():
	if is_instance_valid(modal): modal.get_parent().remove_child(modal);modal.queue_free()
	modal = null

func confirm(title,body,accept,discard=Callable()):
	close_modal()
	modal=Control.new();modal.size=canvas.size;modal.mouse_filter=Control.MOUSE_FILTER_STOP;modal.z_index=100;canvas.add_child(modal)
	var veil=ColorRect.new();veil.color=Color(0,0,0,0.76);veil.size=canvas.size;modal.add_child(veil)
	var box=Layout.new();modal.add_child(box);box.configure("interface/messagebox",Vector2(471,286));box.position=Vector2(276,241)
	trace("interface/messagebox")
	var keep=["MessageBoxBack","MessageBoxTitle","Message","OKButton","CancelButton"] if discard.is_valid() else ["MessageBoxBack","MessageBoxTitle","Message","ConfirmButton"]
	for i in range(box.records.size()):box.controls[i].visible=box.records[i].name in keep
	box.set_value("MessageBoxTitle",title);box.set_value("Message",body)
	box.find_widget("Message").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	box.bind_action("OKButton" if discard.is_valid() else "ConfirmButton",func():close_modal();accept.call())
	if discard.is_valid():box.bind_action("CancelButton",func():close_modal();discard.call())

func mode_picker(parent,at,dimensions,allow_training=true):
	var picker = OptionButton.new();picker.theme = Art.theme();picker.position = at;picker.size = dimensions;picker.fit_to_longest_item = false
	if allow_training: picker.add_item("Yerel Eğitim Arenası",0)
	for mode in game.map_catalog.data.modes: picker.add_item(mode.sourceName,int(mode.id))
	parent.add_child(picker);return picker

func map_picker(parent,at,dimensions):
	var picker = OptionButton.new();picker.theme = Art.theme();picker.position = at;picker.size = dimensions;picker.fit_to_longest_item = false;parent.add_child(picker);return picker

func clear_preview():
	if is_instance_valid(preview_container):
		preview_container.get_parent().remove_child(preview_container);preview_container.queue_free()
	preview_container = null;preview_model = null;preview_root = null;preview_view = null

func build_preview(at,dimensions,entry):
	clear_preview()
	var container=SubViewportContainer.new();container.position=at;container.size=dimensions;container.stretch=true;content.add_child(container)
	preview_container = container
	preview_view=SubViewport.new();preview_view.size=Vector2i(dimensions);preview_view.own_world_3d=true;container.add_child(preview_view)
	preview_root=Node3D.new();preview_view.add_child(preview_root)
	var environment=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("0c1418");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_energy=0.7;environment.environment=settings;preview_root.add_child(environment)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;preview_root.add_child(light)
	preview_camera=Camera3D.new();preview_camera.fov=50;preview_root.add_child(preview_camera)
	replace_preview(entry)

func replace_preview(entry):
	if not is_instance_valid(preview_root):return
	if is_instance_valid(preview_model):preview_root.remove_child(preview_model);preview_model.queue_free()
	var resource=load(entry.wolf.asset if preview_wolf else entry.human.asset) as PackedScene
	if resource==null:return
	preview_model=resource.instantiate();preview_model.scale*=1.6;preview_root.add_child(preview_model)
	for animation in preview_model.find_children("*","AnimationPlayer",true,false):
		if animation.has_animation("idle"):animation.play("idle");animation.advance(0)
	CameraFit.frame(preview_camera,preview_root,Vector2(preview_view.size))

func build_admin():
	Art.section(content,"YEREL YÖNETİM",Vector2(20,20),Vector2(virtual_width-40,44))
	paragraph(content,"Bu geliştirme işlemleri yalnızca yerel profile veya bağlı localhost panelindeki oyuncuya uygulanır. Üretim hesabı değildir.",Vector2(40,100),Vector2(virtual_width-80,110),23)
	var currency=OptionButton.new();currency.position=Vector2(50,255);currency.size=Vector2(360,60)
	for name in ["Nakit","KP","Altın","GP"]:currency.add_item(name)
	content.add_child(currency)
	var amount=SpinBox.new();amount.position=Vector2(440,255);amount.size=Vector2(350,60);amount.min_value=1;amount.max_value=1000000;amount.value=1000;content.add_child(amount)
	button(content,"Yerel bakiye ekle",Vector2(50,370),Vector2(virtual_width-100,70),func():
		if game.grant_money(["cash","kp","gold","gp"][currency.selected],int(amount.value),"Yerel yönetim"):show_error("Yerel işlem kaydedildi." if game.remote_player.is_empty() else "Localhost paneline gönderildi; sunucu sonucu bekleniyor.")
		else:show_error("İşlem kaydedilemedi; bakiye değiştirilmedi.")
	)
