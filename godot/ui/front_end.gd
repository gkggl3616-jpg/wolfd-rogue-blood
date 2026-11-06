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
var set_filter_item=""
var canvas: Control
var content: Control
var links = {}
var history = []
var virtual_width = 1024.0
var safe_insets=Vector4.ZERO
var pending_refresh = false
var building = false
var source_layouts = []
var wallet_label: Control
var currency_values={}
var gp_header_label: Label
var gp_header_bar: ProgressBar
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
var preview_container: TextureRect
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
	if page in ["create_room","room_settings"] and is_instance_valid(room_title) and room_title.is_inside_tree():room_draft.title=room_title.text
	for child in get_children(): remove_child(child);child.queue_free()
	links.clear();source_layouts.clear();modal = null;preview_model = null;preview_view = null;preview_container = null;detail_helper = null;wallet_label=null;currency_values.clear();gp_header_label=null;gp_header_bar=null;profile_label=null
	var dimensions = get_viewport_rect().size
	virtual_width = 1024.0
	var overlay=game.running and page in ["pause","Ayarlar","maps","scoreboard"]
	var shade = ColorRect.new();shade.color = Color(0,0,0,0.45) if overlay else Color("050709");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	# The supplied PC recordings fill both 4:3 and 16:9 displays. Legacy 2D
	# coordinates stretch on each axis; a centered 4:3 canvas adds false gutters.
	var safe=usable_rect()
	canvas = Control.new();canvas.clip_contents=true;canvas.size = Vector2(virtual_width,768);canvas.position=safe.position;canvas.scale = safe.size/Vector2(1024,768);add_child(canvas)
	var lobby_background=page in ["lobby","room","room_settings","create_room","maps","pin","profile","rankbook"]
	if not overlay:background("wt_interface/lobby/lb_bg.dtx" if lobby_background else "wt_interface/inven_shop/is_bg.dtx",607 if lobby_background else 352)
	if not overlay and page!="entry":
		var clean_top=ColorRect.new();clean_top.size=Vector2(1024,94);clean_top.color=Color.BLACK;clean_top.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(clean_top)
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
	# Physical screen coordinates keep touch targets and text readable regardless
	# of the legacy 1024x768 canvas's separate horizontal/vertical scales.
	var safe=usable_rect();var pixels=get_viewport().get_final_transform().get_scale().abs()
	var density=maxf(1,minf(safe.size.x*pixels.x/1280.0,safe.size.y*pixels.y/640.0))
	var height=72.0
	var strip=Control.new();strip.name="ResponsiveHeader";strip.position=safe.position;strip.scale=Vector2.ONE*density/pixels;strip.size=Vector2(safe.size.x*pixels.x/density,height);add_child(strip)
	var mark=ColorRect.new();mark.color=Color("222628");mark.size=strip.size;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.add_child(mark)
	var header_virtual=height*density/pixels.y/canvas.scale.y
	content.scale.y=(768-header_virtual)/(768-44)
	content.position.y=header_virtual-44*content.scale.y
	if page=="admin":content.position.y=header_virtual;content.scale.y=(768-header_virtual)/768
	if is_instance_valid(preview_view):
		preview_view.size=Vector2i(preview_container.size*canvas.scale*content.scale)
		CameraFit.frame(preview_camera,preview_root,Vector2(preview_view.size))
	var entries=[["Etkinlikler","events","event"],["Sıralama","ranking","ranking"],["Mağaza","Mağaza","shop"],["Envanter","Envanter","inven"],["Klan","clan","pride"],["Hediyeler","gifts","gift"],["Arkadaşlar","friends","msg"],["Profil","profile","record"],["Web","web","web"],["Ayarlar","Ayarlar","option"],["Geri","back","back"]]
	var wallet_x=clampf(strip.size.x*0.275,132,352);var wallet_width=clampf(strip.size.x*0.133,100,170)
	var account_width=wallet_x+wallet_width+8;var slots=maxi(4,int((strip.size.x-account_width-12)/56))
	if slots<12:
		var priority=["Mağaza","Envanter","Geri","Hediyeler","Ayarlar","Etkinlikler","Sıralama","Klan","Arkadaşlar","Profil","Web"].slice(0,maxi(1,slots-1))
		entries=entries.filter(func(entry):return entry[0] in priority)
	var start_x=account_width+8
	var pitch=(strip.size.x-8-start_x)/(entries.size()+1)
	var icon_size=minf(height-8,pitch-4)
	var rank=game.ranks.current(int(game.wallet.gp))
	rank_background=Art.sprite(strip,rank.background,Vector2(8,(height-32)/2),Vector2(32,32));rank_image=Art.sprite(strip,rank.asset,Vector2(8,(height-32)/2),Vector2(32,32));rank_image.tooltip_text=rank.name+" · Yerel rütbe"
	last_rank_gp=-1
	var profile_width=wallet_x-54
	profile_label=text(strip,game.profile_name,Vector2(46,6),Vector2(profile_width,19),12);profile_label.tooltip_text=game.profile_name
	gp_header_bar=ProgressBar.new();gp_header_bar.position=Vector2(46,31);gp_header_bar.size=Vector2(profile_width,9);gp_header_bar.show_percentage=false;strip.add_child(gp_header_bar)
	var bar_back=StyleBoxFlat.new();bar_back.bg_color=Color("333a3d");gp_header_bar.add_theme_stylebox_override("background",bar_back)
	var bar_fill=StyleBoxFlat.new();bar_fill.bg_color=Color("889297");gp_header_bar.add_theme_stylebox_override("fill",bar_fill)
	gp_header_bar.add_theme_font_size_override("font_size",1);gp_header_bar.size=Vector2(profile_width,8)
	gp_header_label=text(strip,"",Vector2(46,44),Vector2(profile_width,16),10,Color("c1c6c8"))
	wallet_label=Control.new();wallet_label.name="CurrencyPanel";wallet_label.position=Vector2(wallet_x,4);wallet_label.size=Vector2(wallet_width,height-8);strip.add_child(wallet_label)
	var divider=ColorRect.new();divider.color=Color("4c5356");divider.position=Vector2(-8,0);divider.size=Vector2(1,height-8);divider.mouse_filter=Control.MOUSE_FILTER_IGNORE;wallet_label.add_child(divider)
	for i in range(4):
		var key=["gold","kp","cash","jt"][i];var caption=["ALTIN:","KP:","NAKİT:","JT:"][i];var y=i*(height-8)/4
		text(wallet_label,caption,Vector2(0,y),Vector2(49,16),11,Color("c1c6c8"))
		var value=text(wallet_label,"",Vector2(50,y),Vector2(wallet_width-50,16),11);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;currency_values[key]=value
	currency_values.jt.tooltip_text="JoyToken hesabı bağlı değil."
	for i in range(entries.size()):
		var entry=entries[i]
		var node=Art.icon_button(strip,"wt_interface/all/a_lb_icon_%s.dtx" % entry[2],Vector2(start_x+i*pitch,(height-icon_size)/2),entry[0],func():
			if entry[1]=="back":go_back()
			else:navigate(entry[1])
		)
		node.size=Vector2.ONE*icon_size;node.stretch_mode=TextureButton.STRETCH_SCALE
		links[entry[0]]=node
		if entry[1]==page:node.modulate=Color("ffe36a")
		if entry[1]=="gifts" and game.inbox.pending_count()>0:text(node,str(game.inbox.pending_count()),Vector2(25,0),Vector2(18,16),11,Art.GOLD)
	links["Diğer"]=button(strip,"☰",Vector2(start_x+entries.size()*pitch,(height-icon_size)/2),Vector2.ONE*icon_size,choose_section)
	var power_link=Button.new();power_link.hide();strip.add_child(power_link);power_link.pressed.connect(func():navigate("power"));links["Güç"]=power_link

func choose_section():
	confirm("Menüler","",func():pass)
	var entries=[["Güç","power"],["Kartlar","Kartlar"],["Lobi","lobby"],["Görevler","missions"],["Kutular","Kutular"],["Setler","Setler"],["Arkadaşlar","friends"],["Klan","clan"],["Sıralama","ranking"],["Dövmeler","Dövmeler"],["Profil şifresi","pin"],["Yerel yönetim","admin"],["Etkinlikler","events"],["Mağaza","Mağaza"],["Envanter","Envanter"],["Hediyeler","gifts"],["Profil","profile"],["Web","web"],["Ayarlar","Ayarlar"]]
	for i in range(entries.size()):
		var entry=entries[i]
		button(modal,entry[0],Vector2(296+(i%2)*230,275+int(i/2)*31),Vector2(200,28),func():close_modal();navigate(entry[1]))

func _process(_delta):
	if is_instance_valid(rank_image) and last_rank_gp!=int(game.wallet.gp):
		var rank=game.ranks.current(int(game.wallet.gp));rank_image.texture=Art.texture(rank.asset);rank_background.texture=Art.texture(rank.background);rank_image.tooltip_text=rank.name+" · Yerel rütbe";last_rank_gp=int(game.wallet.gp)
	if is_instance_valid(profile_label):profile_label.text=game.profile_name
	if is_instance_valid(wallet_label):
		currency_values.gold.text="%d A" % game.wallet.gold;currency_values.kp.text=game.wallet_text("kp")+" KP";currency_values.cash.text=game.wallet_text("cash")+" N";currency_values.jt.text="— JT"
		gp_header_label.text="GP: %d" % game.wallet.gp
		var current=game.ranks.current(int(game.wallet.gp));var next=game.ranks.next(int(game.wallet.gp));var start=int(current.localMinimumGp);var finish=int(next.get("localMinimumGp",start+100))
		gp_header_bar.value=100.0*(int(game.wallet.gp)-start)/maxi(1,finish-start)
	if detail_helper != null and detail_helper.has_method("update"): detail_helper.update(_delta)

func navigate(next,remember=true,back_step=false):
	if next=="wolfpass":next="missions"
	if next!="Setler":set_filter_item=""
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
	if next in ["create_room","room_settings"] and page!=next:
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
		var title=game.map_catalog.mode_name(int(mode.id))
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
	var container=TextureRect.new();container.position=at;container.size=dimensions;container.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;container.stretch_mode=TextureRect.STRETCH_SCALE;container.mouse_filter=Control.MOUSE_FILTER_STOP;content.add_child(container)
	preview_container = container
	container.gui_input.connect(preview_input)
	preview_view=SubViewport.new();preview_view.size=Vector2i(dimensions*canvas.scale*content.scale);preview_view.own_world_3d=true;preview_view.transparent_bg=true;preview_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(preview_view);container.texture=preview_view.get_texture()
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
	preview_model=resource.instantiate()
	if preview_wolf:preload("res://scripts/wolf_surface.gd").apply(preview_model)
	preview_model.scale*=1.6;preview_root.add_child(preview_model)
	preview_model.rotation.y=preview_angle
	for mesh in preview_model.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).to_lower().begins_with("tattoo"):mesh.hide()
	var menu_pose=not preview_wolf and preload("res://scripts/menu_preview.gd").apply(preview_model,entry)
	if not menu_pose:
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
