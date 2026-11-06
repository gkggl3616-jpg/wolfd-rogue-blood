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
var collection_shop = false
var canvas: Control
var content: Control
var links = {}
var history = []
var virtual_width = 1024.0
var safe_insets=Vector4.ZERO
var pending_refresh = false
var building = false
var source_layouts = []
var wallet_label: Label
var profile_label: Label
var notice: Label
var detail_helper
var modal: Control
var selected = {}
var search_query = ""
var filter_id = "all"
var quality_id="all"
var preview_team="blue"
var target_primary_slot = "primary"
var offset = 0
var room_title: LineEdit
var room_mode: OptionButton
var room_map: OptionButton
var room_goal:OptionButton
var room_time:OptionButton
var room_allies: OptionButton
var room_enemies: OptionButton
var room_difficulty: OptionButton
var room_form: OptionButton
var room_draft = {"title":"Yerel Oda","mode":0,"map":0,"team":"blue"}
var mode_choice = 0
var map_choice = 0
var map_gallery_page=0
var rank_page=0
var pass_page=0
var rank_image
var rank_background
var last_rank_gp=-1
var preview_view: SubViewport
var preview_root: Node3D
var preview_model: Node3D
var preview_camera: Camera3D
var preview_container: SubViewportContainer
var preview_wolf = false
var preview_angle=0.0
var preview_drag=false
var preview_finger=-1
var settings_draft = {}
var settings_dirty = false
var settings_tab = "Ses"
var last_error = ""

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents=true
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
	var focused=get_viewport().gui_get_focus_owner()
	var input_id="";var caret=0
	if focused is LineEdit and is_ancestor_of(focused):
		input_id=focused.get_meta("navigation_input","");caret=focused.caret_column
	if page=="create_room" and is_instance_valid(room_title) and room_title.is_inside_tree():room_draft.title=room_title.text
	for child in get_children(): remove_child(child);child.queue_free()
	links.clear();source_layouts.clear();modal = null;preview_model = null;preview_view = null;preview_container = null;detail_helper = null;wallet_label=null;profile_label=null
	var dimensions = get_viewport_rect().size
	virtual_width = 1024.0
	var overlay=game.running and page in ["pause","Ayarlar","maps","scoreboard"]
	var shade = ColorRect.new();shade.color = Color(0,0,0,0.45) if overlay else Color("050709");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	# The supplied PC recordings fill both 4:3 and 16:9 displays. Legacy 2D
	# coordinates stretch on each axis; a centered 4:3 canvas adds false gutters.
	var safe=usable_rect()
	canvas = Control.new();canvas.clip_contents=true;canvas.size = Vector2(virtual_width,768);canvas.position=safe.position;canvas.scale = safe.size/Vector2(1024,768);add_child(canvas)
	var lobby_background=page in ["lobby","room","create_room","maps","pin","profile","rankbook"]
	if not overlay:background("wt_interface/lobby/lb_bg.dtx" if lobby_background else "wt_interface/inven_shop/is_bg.dtx",607 if lobby_background else 352)
	content = Control.new();content.position.y = 0;content.size = Vector2(virtual_width,768);canvas.add_child(content)
	var desktop = PcScreens.new();desktop.ui = self;desktop.build()
	if page not in ["entry","pause"] and not (page=="Ayarlar" and overlay):build_header()
	text(canvas,"WOLF ROGUE BLOOD  ·  YEREL OTURUM",Vector2(8,751),Vector2(600,16),10,Color("a9b6b8"))
	text(canvas,"ÇEVRİMDIŞI",Vector2(876,751),Vector2(140,16),10,Art.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	building = false
	if input_id!="":
		for node in content.find_children("*","LineEdit",true,false):
			if node.get_meta("navigation_input","")==input_id:node.grab_focus();node.caret_column=mini(caret,node.text.length());break
	if not last_error.is_empty(): show_error(last_error)

func usable_rect():
	var rect=get_viewport_rect()
	var inset=safe_insets
	if OS.has_feature("android"):
		var safe=DisplayServer.get_display_safe_area()
		if safe.has_area():
			var mapped=get_viewport().get_final_transform().affine_inverse()*Rect2(safe)
			mapped=rect.intersection(mapped)
			if mapped.has_area():rect=mapped
	return Rect2(rect.position+Vector2(inset.x,inset.y),Vector2(maxf(1,rect.size.x-inset.x-inset.z),maxf(1,rect.size.y-inset.y-inset.w)))

func trace(source):
	if source not in source_layouts: source_layouts.append(source)
	set_meta("source_layouts",source_layouts)

func background(source, split):
	var extra = virtual_width - 1024
	Art.sprite(canvas,source,Vector2.ZERO,Vector2(split+extra,768),Rect2(0,0,split,768))
	Art.sprite(canvas,source,Vector2(split+extra,0),Vector2(1024-split,768),Rect2(split,0,1024-split,768))

func text(parent,value,at,dimensions,font_size=12,color=Color.WHITE):
	var node = Art.label(value,dimensions,font_size,color);node.position = at;parent.add_child(node);return node

func paragraph(parent,value,at,dimensions,font_size=12):
	var label = text(parent,"",at,dimensions,font_size);label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;label.text=str(value);label.size=dimensions
	return label

func button(parent,title,at,dimensions,callback,enabled=true):
	var node = Art.button(parent,title,at,dimensions,callback);node.disabled = not enabled;links[title] = node;return node

func native(source,parent,at=Vector2.ZERO,dimensions=Vector2(1024,768)):
	trace(source)
	var node = Layout.new();parent.add_child(node);node.configure(source,dimensions);node.position = at
	return node

func build_header():
	# Compact account strip and 32px source icon states, as in references 1/4/5.
	var mark=ColorRect.new();mark.color=Color("222628");mark.size=Vector2(1024,58);mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(mark)
	profile_label=text(canvas,game.profile_name,Vector2(48,31),Vector2(170,19),12)
	text(canvas,"Etkinlik Bonusu",Vector2(48,5),Vector2(160,14),10,Color("9ca9ab"))
	for y in [8,21]:
		var bar=ColorRect.new();bar.color=Color("666b6b");bar.position=Vector2(137,y);bar.size=Vector2(72,9);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(bar)
	var rank=game.ranks.current(int(game.wallet.gp))
	rank_background=Art.sprite(canvas,rank.background,Vector2(10,12),Vector2(32,32));rank_image=Art.sprite(canvas,rank.asset,Vector2(10,12),Vector2(32,32));rank_image.tooltip_text=rank.name+" · Yerel rütbe"
	last_rank_gp=-1
	wallet_label=text(canvas,"",Vector2(218,3),Vector2(202,51),10,Color("c1c6c8"))
	var chain=button(canvas,"‹ KLAN ZİNCİRİ ›",Vector2(423,9),Vector2(128,37),func():navigate("clan"));chain.modulate=Color("79c9ac")
	var pass_button=button(canvas,"WOLF\nPASS",Vector2(554,9),Vector2(54,37),func():navigate("wolfpass"));pass_button.modulate=Color("b698ee")
	var entries = [["Etkinlikler","events","event"],["Sıralama","ranking","ranking"],["Mağaza","Mağaza","shop"],["Envanter","Envanter","inven"],["Klan","clan","pride"],["Hediyeler","gifts","gift"],["Arkadaşlar","friends","msg"],["Profil","profile","record"],["Web","web","web"],["Ayarlar","Ayarlar","option"],["Geri","back","back"]]
	for i in range(entries.size()):
		var entry = entries[i]
		var node=Art.icon_button(canvas,"wt_interface/all/a_lb_icon_%s.dtx" % entry[2],Vector2(614+i*37,7),entry[0],func():
			if entry[1]=="":choose_section()
			elif entry[1]=="back":go_back()
			else:navigate(entry[1])
		)
		links[entry[0]]=node
		if entry[1]==page:node.modulate=Color("ffe36a")
		if entry[1]=="gifts" and game.inbox.pending_count()>0:text(node,str(game.inbox.pending_count()),Vector2(18,0),Vector2(18,15),10,Art.GOLD)
	links["Diğer"]=button(canvas,"☰",Vector2(398,31),Vector2(22,21),choose_section)
	var power_link=Button.new();power_link.hide();canvas.add_child(power_link);power_link.pressed.connect(func():navigate("power"));links["Güç"]=power_link


func choose_section():
	confirm("Menüler","",func():pass)
	var entries=[["Güç","power"],["Kartlar","Kartlar"],["Lobi","lobby"],["Görevler","missions"],["Wolf Pass","wolfpass"],["Kutular","Kutular"],["Arkadaşlar","friends"],["Klan","clan"],["Sıralama","ranking"],["Dövmeler","Dövmeler"],["Profil şifresi","pin"],["Yerel yönetim","admin"],["Etkinlikler","events"]]
	for i in range(entries.size()):
		var entry=entries[i]
		button(modal,entry[0],Vector2(296+(i%2)*230,275+int(i/2)*31),Vector2(200,28),func():close_modal();navigate(entry[1]))

func _process(_delta):
	if is_instance_valid(rank_image) and last_rank_gp!=int(game.wallet.gp):
		var rank=game.ranks.current(int(game.wallet.gp));rank_image.texture=Art.texture(rank.asset);rank_background.texture=Art.texture(rank.background);rank_image.tooltip_text=rank.name+" · Yerel rütbe";last_rank_gp=int(game.wallet.gp)
	if is_instance_valid(profile_label):profile_label.text=game.profile_name
	if is_instance_valid(wallet_label): wallet_label.text = "ALTIN:  %d     KP:  %s\nNAKİT:  %s     GP:  %d\nÇevrimiçi hesap bağlı değil" % [game.wallet.gold,game.wallet_text("kp"),game.wallet_text("cash"),game.wallet.gp]
	if detail_helper != null and detail_helper.has_method("update"): detail_helper.update(_delta)

func navigate(next,remember=true,back_step=false):
	if modal != null: return
	if not game.profile_lock.unlocked and next not in ["entry","pin"]:next="pin"
	if page == "Ayarlar" and settings_dirty:
		confirm("Kaydedilmemiş ayarlar", "Değişiklikleri uygulayıp devam et?", func():
			if detail_helper.apply(): navigate(next,remember,back_step)
		,func(): settings_dirty = false;navigate(next,remember,back_step))
		return
	if back_step and not history.is_empty(): history.pop_back()
	if remember and page != next: history.append(page)
	if next == "Ayarlar" and page != "Ayarlar": settings_draft = game.book.settings.duplicate(true);settings_dirty = false
	if next=="create_room" and page!="create_room":
		room_draft={"title":"Yerel Oda","mode":0,"map":0,"team":"blue","playerForm":"human","botDifficulty":"normal"}
		room_draft.merge(game.local_room,true)
	if next=="Dövmeler" and page!="Dövmeler":preview_angle=PI
	if next=="Mağaza":collection_shop=true
	elif next=="Envanter":collection_shop=false
	page = next;offset = 0;selected = {};search_query = "";filter_id = "all";quality_id="all";last_error = ""
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
	notice = text(canvas,last_error,Vector2(10,746),Vector2(1004,20),11)
	notice.tooltip_text=last_error
	var plate=StyleBoxFlat.new();plate.bg_color=Color("111719");notice.add_theme_stylebox_override("normal",plate)
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
	if allow_training: picker.add_item("Botlu Eğitim",0)
	if allow_training: picker.add_item("Kurt Avı · Yerel",game.LocalHunt.MODE)
	if allow_training: picker.add_item("Öğretici Mod · Yerel",game.LocalTutorial.MODE)
	if allow_training: picker.add_item("Kurt Savaşı · Yerel",game.WOLF_BATTLE)
	for mode in game.map_catalog.data.modes:
		var title={1000:"Ölüm Oyunu",1001:"Ölüm Oyunu · Ağır Silah",1010:"Ölüm Oyunu · Kurt Savaşı",1020:"Ölüm Oyunu · İnsan",1021:"Ölüm Oyunu · İnsan/Ağır"}.get(int(mode.id),mode.sourceName)
		picker.add_item(title,int(mode.id))
	parent.add_child(picker);return picker

func map_picker(parent,at,dimensions):
	var picker = OptionButton.new();picker.theme = Art.theme();picker.position = at;picker.size = dimensions;picker.fit_to_longest_item = false;parent.add_child(picker);return picker

func clear_preview():
	if is_instance_valid(preview_container):
		preview_container.get_parent().remove_child(preview_container);preview_container.queue_free()
	preview_container = null;preview_model = null;preview_root = null;preview_view = null

func build_preview(at,dimensions,entry):
	clear_preview()
	var container=SubViewportContainer.new();container.position=at;container.size=dimensions*canvas.scale;container.scale=Vector2.ONE/canvas.scale;container.stretch=true;content.add_child(container)
	preview_container = container
	container.gui_input.connect(preview_input)
	preview_view=SubViewport.new();preview_view.size=Vector2i(dimensions*canvas.scale);preview_view.own_world_3d=true;preview_view.transparent_bg=true;container.add_child(preview_view)
	preview_root=Node3D.new();preview_view.add_child(preview_root)
	var environment=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_CLEAR_COLOR;settings.background_color=Color(0,0,0,0);settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_energy=0.7;environment.environment=settings;preview_root.add_child(environment)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);light.light_energy=1.6;preview_root.add_child(light)
	preview_camera=Camera3D.new();preview_camera.fov=50;preview_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;preview_root.add_child(preview_camera)
	replace_preview(entry)

func replace_preview(entry):
	if not is_instance_valid(preview_root):return
	if is_instance_valid(preview_model):preview_root.remove_child(preview_model);preview_model.queue_free()
	var resource=load(entry.wolf.asset if preview_wolf else entry.human.asset) as PackedScene
	if resource==null:return
	preview_model=resource.instantiate();preview_model.scale*=1.6;preview_root.add_child(preview_model)
	preview_model.rotation.y=preview_angle
	for mesh in preview_model.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).to_lower().begins_with("tattoo"):mesh.hide()
	for animation in preview_model.find_children("*","AnimationPlayer",true,false):
		if animation.has_animation("idle"):animation.play("idle");animation.advance(0)
	CameraFit.frame(preview_camera,preview_root,Vector2(preview_view.size))

func preview_input(event):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:preview_drag=event.pressed;preview_container.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and preview_finger<0:preview_finger=event.index
		elif not event.pressed and event.index==preview_finger:preview_finger=-1
		preview_container.accept_event()
	elif (event is InputEventMouseMotion and preview_drag) or (event is InputEventScreenDrag and event.index==preview_finger):
		preview_angle+=event.relative.x*0.01
		if is_instance_valid(preview_model):preview_model.rotation.y=preview_angle
		preview_container.accept_event()

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
