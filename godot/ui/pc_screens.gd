extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const Collection=preload("res://ui/collection_page.gd")
const Options=preload("res://ui/settings_page.gd")
var ui
var view

func build():
	match ui.page:
		"entry":entry()
		"servers":servers()
		"lobby":lobby()
		"room":room()
		"create_room":create_room()
		"maps":maps()
		"pause":pause_page()
		"result":result_page()
		"power":power()
		"Ayarlar":ui.detail_helper=Options.new();ui.detail_helper.ui=ui;ui.detail_helper.build_native()
		"Mağaza","Envanter","Karakterler","Dövmeler","Efektler":ui.detail_helper=Collection.new();ui.detail_helper.ui=ui;ui.detail_helper.build_native()
		"admin":ui.build_admin()
		_:service()

func layout(id,at=Vector2.ZERO,dimensions=Vector2(1024,768)):
	return ui.native(id,ui.content,at,dimensions)

func enable(name,callback,identity=null):
	var node=view.find_widget(name,identity)
	if node is BaseButton:
		view.bind_action(name,callback,identity);ui.links[name]=node
	return node

func only(names):
	for i in range(view.records.size()):view.controls[i].visible=view.records[i].name in names

func entry():
	view=layout("section/title")
	view.set_value("Version","Wolf Rogue Blood · 0.9 geliştirme")
	# The sole rebrand region is the original title/logo area. No source paths
	# are renamed and the original backdrop is left intact.
	var strip=ColorRect.new();strip.color=Color("151b20");strip.position=Vector2(375,444);strip.size=Vector2(275,150);ui.content.add_child(strip)
	ui.paragraph(ui.content,"WOLF ROGUE\nBLOOD",Vector2(385,459),Vector2(255,120),30).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(ui.content,"Yerel oturuma devam",Vector2(362,635),Vector2(300,42),func():ui.navigate("servers"))
	ui.paragraph(ui.content,"Çevrimiçi hesap hizmeti bağlı değil.",Vector2(262,700),Vector2(500,35),15).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func servers():
	view=layout("section/serverlist")
	only(["BackGround","NormalServer","Server","Notice"])
	for i in range(view.records.size()):
		var node=view.controls[i];var record=view.records[i]
		if record.name=="Server":node.visible=int(view.field(record,"identity",-1))==100
		if record.name=="Notice":node.hide()
	var row=enable("Server",func():ui.navigate("lobby"),100)
	if row:
		row.position=Vector2(462,132)
		var caption=ui.text(row,"YEREL OTURUM · BU CİHAZ",Vector2(16,10),Vector2(490,28),17)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.paragraph(ui.content,"Çevrimiçi sunucu listesi alınamadı.\nOyuncu sayısı ve ping üretilmez.",Vector2(24,150),Vector2(390,160),17)
	enable("NormalServer",func():ui.show_error("Çevrimiçi sunucu hizmeti bağlı değil."))

func lobby():
	view=layout("section/battle")
	only(["LobbyBackGround","CreateBattle","QuickStart","Refresh","ChannelButtonGroup","Channel1","Channel2","Channel3","Channel4","Channel5","ChatTypeGroup","ToAllChatButton","ToPrideChatButton","ToShoutingChatButton","ChatListBox","ChatEditBox","ChannelUserListBox","RoomNumberSort","RoomStatusSort","RoomTypeSort","RoomMapNameSort","ChannelName","PlayModeSelectComboBox"])
	enable("CreateBattle",func():ui.navigate("create_room"))
	enable("QuickStart",func():ui.navigate("room" if not ui.game.local_room.is_empty() else "maps"))
	enable("Refresh",ui.refresh)
	for i in range(1,6):enable("Channel%d" % i,func():ui.show_error("Yalnızca bu cihazdaki yerel kanal hazır."))
	for name in ["RoomNumberSort","RoomStatusSort","RoomTypeSort","RoomMapNameSort"]:enable(name,func():ui.show_error("Yerel oda listesi güncel."))
	var users=view.find_widget("ChannelUserListBox")
	if users is ItemList:users.add_item(ui.game.profile_name);users.set_meta("data_origin","local_profile")
	var chat=view.find_widget("ChatEditBox")
	if chat is LineEdit:chat.placeholder_text="Çevrimiçi sohbet bağlı değil";chat.editable=false
	view.set_value("ChannelName","YEREL KANAL",1)
	var duplicate=view.find_widget("ChannelName",-1)
	if duplicate:duplicate.hide()
	if ui.game.local_room.is_empty():ui.paragraph(ui.content,"Yerel oda yok.",Vector2(28,150),Vector2(550,70),17)
	else:
		var row=ui.button(ui.content,ui.game.local_room.title,Vector2(6,122),Vector2(590,45),func():ui.navigate("room"))
		row.set_meta("data_origin","local_room")
		ui.paragraph(ui.content,"1 yerel oyuncu · ağ maçı değil",Vector2(615,140),Vector2(390,70),15)

func room():
	if ui.game.local_room.is_empty():lobby();return
	view=layout("section/field")
	only(["BackGround","FieldNumber","FieldName","UserListTop","StartGame","Invite","RedTeam","BlueTeam","RedCurChars","RedMaxChars","BlueCurChars","BlueMaxChars","ChangeTeam","ChangeRule","CurrentMap","GameMode","MapName","MaxChars","MissionObject","RoundTime","ChatTypeGroup","ToAllChatButton","ToPrideChatButton","ChatListBox","ChatEditBox","ChannelName"])
	var data=ui.game.local_room
	view.set_value("FieldName",data.title)
	view.set_value("FieldNumber","YEREL")
	view.set_value("ChannelName","YEREL OTURUM",1)
	for name in ["RedTeam","BlueTeam"]:
		var users=view.find_widget(name)
		if users is ItemList and ((name=="RedTeam")== (data.team=="red")):users.add_item(ui.game.profile_name);users.set_meta("data_origin","local_profile")
	enable("ChangeTeam",func():data.team="red" if data.team=="blue" else "blue";ui.refresh())
	enable("ChangeRule",func():ui.navigate("create_room"))
	var training=int(data.mode)==0
	view.set_value("GameMode","Yerel Eğitim" if training else ui.game.map_catalog.mode_record(int(data.mode)).sourceName)
	view.set_value("MapName","Eğitim Arenası" if training else ui.game.map_catalog.map_record(int(data.map)).displayName)
	view.set_value("MaxChars","1 yerel oyuncu")
	var start=enable("StartGame",ui.game.start_round)
	if start:start.disabled=not training
	if not training:
		ui.paragraph(ui.content,"Özgün maç kuralları tamamlanmadı. Yalnızca geometri gezintisi açılabilir.",Vector2(617,440),Vector2(385,90),16)
		ui.button(ui.content,"Haritayı gez",Vector2(12,542),Vector2(170,28),func():ui.mode_choice=int(data.mode);ui.map_choice=int(data.map);ui.navigate("maps"))
	var chat=view.find_widget("ChatEditBox")
	if chat is LineEdit:chat.placeholder_text="Çevrimiçi sohbet bağlı değil";chat.editable=false

func create_room():
	view=layout("section/prideladder/prideladdercreateroomdialog",Vector2(303,145),Vector2(417,512))
	only(["PLBackGround","PLFieldNameEditBox","PLExit","PLOK","PLCancel","ModeText","MapText"])
	var name=view.find_widget("PLFieldNameEditBox");name.editable=true;name.text="Yerel Oda";ui.room_title=name
	ui.room_mode=ui.mode_picker(ui.content,Vector2(380,238),Vector2(316,28))
	ui.room_map=ui.map_picker(ui.content,Vector2(380,300),Vector2(316,28))
	var fill=func():
		ui.room_map.clear()
		if ui.room_mode.get_selected_id()==0:ui.room_map.add_item("Yerel Eğitim",0)
		else:
			for map in ui.game.map_catalog.maps_for_mode(ui.room_mode.get_selected_id()):ui.room_map.add_item(map.displayName,int(map.number))
	ui.room_mode.item_selected.connect(func(_index):fill.call());fill.call()
	enable("PLExit",ui.go_back);enable("PLCancel",ui.go_back)
	enable("PLOK",func():
		if name.text.strip_edges().length()<2 or ui.room_map.item_count==0:ui.show_error("Oda adı ve moda bağlı harita gerekli.");return
		ui.game.local_room={"title":name.text.strip_edges(),"mode":ui.room_mode.get_selected_id(),"map":ui.room_map.get_selected_id(),"team":"blue"};ui.navigate("room")
	)
	ui.paragraph(ui.content,"Yerel oturum · çevrimiçi oda değildir.",Vector2(330,445),Vector2(360,70),15)

func maps():
	view=layout("interface/gameoption",Vector2(252,128),Vector2(520,512))
	only(["BackGround","Exit"])
	enable("Exit",ui.go_back)
	ui.text(ui.content,"MOD VE HARİTALAR",Vector2(276,156),Vector2(460,35),20,Art.GOLD)
	ui.game.mode_picker=ui.mode_picker(ui.content,Vector2(276,218),Vector2(470,44),false)
	for i in range(ui.game.mode_picker.item_count):
		if ui.game.mode_picker.get_item_id(i)==ui.mode_choice:ui.game.mode_picker.select(i)
	ui.game.map_picker=ui.map_picker(ui.content,Vector2(276,292),Vector2(470,44))
	ui.game.map_status=ui.paragraph(ui.content,"",Vector2(276,365),Vector2(470,145),17)
	ui.game.map_start=ui.button(ui.content,"Haritayı başlat",Vector2(276,540),Vector2(220,44),ui.game.start_selected_map)
	ui.game.map_preview=ui.button(ui.content,"Haritayı gez · Önizleme",Vector2(512,540),Vector2(234,44),ui.game.start_map_preview)
	ui.game.mode_picker.item_selected.connect(func(_index):ui.game.refresh_mode_maps())
	ui.game.map_picker.item_selected.connect(func(_index):ui.game.refresh_map_status())
	ui.game.refresh_mode_maps()
	for i in range(ui.game.map_picker.item_count):
		if ui.game.map_picker.get_item_id(i)==ui.map_choice:ui.game.map_picker.select(i)
	ui.game.refresh_map_status()

func pause_page():
	view=layout("interface/gamemenu",Vector2(312,195),Vector2(400,377))
	only(["GameMenuBack","ExitButton","GameComeBack","Option","GameExit"])
	enable("ExitButton",ui.game.resume);enable("GameComeBack",ui.game.resume)
	enable("Option",func():ui.navigate("Ayarlar"))
	enable("GameExit",func():ui.game.running=false;ui.game.clear_projectiles();ui.navigate("lobby"))

func result_page():
	view=layout("section/result")
	only(["BackGround","Confirm","RedResult","ChannelName"])
	view.set_value("ChannelName","YEREL EĞİTİM SONUCU",1)
	ui.text(ui.content,ui.game.last_result.get("title","Tur bitti"),Vector2(24,115),Vector2(550,40),22,Art.GOLD)
	ui.paragraph(ui.content,"%s\nHedef: %d / 10\nCan: %d\nKalan süre: %d saniye\n\nBu sonuç yalnızca yerel eğitime aittir." % [ui.game.profile_name,ui.game.kills,ui.game.health,maxi(0,int(ui.game.time_left))],Vector2(35,210),Vector2(740,300),20)
	enable("Confirm",func():ui.navigate("lobby"))
	ui.button(ui.content,"Yeniden oyna",Vector2(590,701),Vector2(200,30),ui.game.start_round)

func power():
	ui.trace("interface/abilityequipmentpage")
	ui.trace("interface/charequipmentpage")
	var item=ui.game.equipment.rules.items[0]
	Art.sprite(ui.content,"wt_interface/inven_shop/iv_ch_top.dtx",Vector2(3,62),Vector2(256,24),Rect2(0,0,256,24))
	Art.sprite(ui.content,item.icon,Vector2(42,150),Vector2(250,230)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.text(ui.content,item.name,Vector2(370,145),Vector2(620,40),24,Art.GOLD)
	ui.paragraph(ui.content,item.description,Vector2(370,210),Vector2(600,310),18)
	var equipped=ui.game.equipment.has_wolf_ability()
	ui.button(ui.content,"Güç slotuna tak" if not equipped else "Takılı · Çıkar",Vector2(620,625),Vector2(355,48),func():
		if not ui.game.equipment.equip_power(0 if equipped else 19601):ui.show_error("Güç slotu kaydedilemedi.");return
		ui.game.player.reset_locomotion();ui.refresh()
	)
	ui.paragraph(ui.content,"Havada güçlü saldırı tamamlanmadı; sayısal değerler yeni mobil uyarlamadır.",Vector2(370,535),Vector2(600,60),16)

func service():
	var id=ui.SERVICE_LAYOUTS.get(ui.page,"section/messagebox")
	view=layout(id)
	for control in view.controls:
		if control is BaseButton:control.disabled=true
	ui.confirm(ui.NAMES.get(ui.page,ui.page),"Gerçek hesap / hizmet bağlantısı yok. Bu ekranda veri veya ödül sonucu üretilmez.",ui.go_back)
