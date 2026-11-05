extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const Collection=preload("res://ui/collection_page.gd")
const Options=preload("res://ui/settings_page.gd")
const Cards=preload("res://ui/card_page.gd")
const Boxes=preload("res://ui/box_page.gd")
const ProfileLockPage=preload("res://ui/profile_lock_page.gd")
const SourceCard=preload("res://ui/source_item_card.gd")
const CareerPage=preload("res://ui/career_page.gd")
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
		"profile":profile()
		"pin":ui.detail_helper=ProfileLockPage.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"Kutular":ui.detail_helper=Boxes.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"scoreboard":scoreboard()
		"rankbook":rankbook()
		"missions","wolfpass":ui.detail_helper=CareerPage.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"Kartlar":ui.detail_helper=Cards.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"Ayarlar":ui.detail_helper=Options.new();ui.detail_helper.ui=ui;ui.detail_helper.build_native()
		"Mağaza","Envanter","Karakterler","Dövmeler","Efektler","power":ui.detail_helper=Collection.new();ui.detail_helper.ui=ui;ui.detail_helper.build_native()
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
	view.show_only(names)

func entry():
	view=layout("section/title")
	view.set_value("Version","Wolf Rogue Blood · 0.12 çevrimdışı" if OS.has_feature("offline_release") else "Wolf Rogue Blood · 0.12 geliştirme")
	# The sole rebrand region is the original title/logo area. No source paths
	# are renamed and the original backdrop is left intact.
	var strip=ColorRect.new();strip.color=Color("151b20");strip.position=Vector2(375,444);strip.size=Vector2(275,150);ui.content.add_child(strip)
	ui.paragraph(ui.content,"WOLF ROGUE\nBLOOD",Vector2(385,459),Vector2(255,120),30).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(ui.content,"Yerel oturuma devam",Vector2(362,635),Vector2(300,42),func():ui.navigate("servers" if ui.game.profile_lock.unlocked else "pin"))
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
	if users is ItemList:users.add_item(ui.game.profile_name,Art.texture(ui.game.ranks.current(int(ui.game.wallet.gp)).asset));users.set_meta("data_origin","local_profile")
	var chat=view.find_widget("ChatEditBox")
	if chat is LineEdit:chat.placeholder_text="Çevrimiçi sohbet bağlı değil";chat.editable=false
	view.set_value("ChannelName","YEREL KANAL",1)
	var duplicate=view.find_widget("ChannelName",-1)
	if duplicate:duplicate.hide()
	if ui.game.local_room.is_empty():ui.paragraph(ui.content,"Yerel oda yok.",Vector2(28,150),Vector2(550,70),17)
	else:
		var row=ui.button(ui.content,ui.game.local_room.get("title","Yerel Oda"),Vector2(6,122),Vector2(590,45),func():ui.navigate("room"))
		row.set_meta("data_origin","local_room")
		ui.paragraph(ui.content,"1 yerel oyuncu · ağ maçı değil",Vector2(615,140),Vector2(390,70),15)
		var room_data=ui.game.local_room
		Art.sprite(ui.content,ui.game.map_catalog.photo(int(room_data.map)).get("asset",""),Vector2(612,130),Vector2(407,120),Rect2(0,0,407,120))
		var plate=ColorRect.new();plate.color=Color("20282c");plate.position=Vector2(612,255);plate.size=Vector2(407,212);ui.content.add_child(plate)
		var mode_name="Kurt Avı · Yerel" if int(room_data.mode)==ui.game.LocalHunt.MODE else ("Öğretici Mod" if int(room_data.mode)==ui.game.LocalTutorial.MODE else "Botlu Eğitim")
		ui.paragraph(ui.content,"%s\nMod: %s\nHarita: %s\nBotlar: %s\n1 yerel oyuncu" % [room_data.get("title","Yerel Oda"),mode_name,"Eğitim Arenası" if int(room_data.map)==0 else ui.game.map_catalog.map_record(int(room_data.map)).displayName,ui.game.BotRules.profile(room_data.get("botDifficulty","normal")).name],Vector2(624,268),Vector2(382,180),16)

func room():
	if ui.game.local_room.is_empty():lobby();return
	view=layout("section/field")
	only(["BackGround","FieldNumber","FieldName","UserListTop","StartGame","Invite","RedTeam","BlueTeam","RedCurChars","RedMaxChars","BlueCurChars","BlueMaxChars","ChangeTeam","ChangeRule","CurrentMap","GameMode","MapName","MaxChars","MissionObject","RoundTime","ChatTypeGroup","ToAllChatButton","ToPrideChatButton","ChatListBox","ChatEditBox","ChannelName"])
	var data=ui.game.local_room
	view.set_value("FieldName",data.title)
	# Both legacy fields occupy the same rectangle; only the room title is drawn.
	view.find_widget("FieldNumber").hide()
	view.set_value("ChannelName","YEREL OTURUM",1)
	for name in ["RedTeam","BlueTeam"]:
		var users=view.find_widget(name)
		if users is ItemList and ((name=="RedTeam")== (data.team=="red")):users.add_item(ui.game.profile_name,Art.texture(ui.game.ranks.current(int(ui.game.wallet.gp)).asset));users.set_meta("data_origin","local_profile")
	enable("ChangeTeam",func():data.team="red" if data.team=="blue" else "blue";ui.refresh())
	enable("ChangeRule",func():ui.navigate("create_room"))
	var training=ui.game.is_local_mode(int(data.mode))
	var hunting=int(data.mode)==ui.game.LocalHunt.MODE
	view.set_value("GameMode",("Öğretici Mod" if int(data.mode)==ui.game.LocalTutorial.MODE else ("Kurt Avı · Yerel" if hunting else "Botlu Eğitim")) if training else ui.game.map_catalog.mode_record(int(data.mode)).sourceName)
	view.set_value("MapName","Eğitim Arenası" if int(data.map)==0 else ui.game.map_catalog.map_record(int(data.map)).displayName)
	view.set_value("MaxChars","1 oyuncu")
	if training:
		view.set_value("MissionObject","3 raunt · 4 rakip" if hunting else "10 hedef")
		view.set_value("RoundTime","90 saniye")
		ui.paragraph(ui.content,"Botlar: %s\nİnsan ve kurt · Hasar her seviyede aynı" % ui.game.BotRules.profile(data.get("botDifficulty","normal")).name,Vector2(617,432),Vector2(385,78),15)
		var opponent=view.find_widget("BlueTeam" if data.team=="red" else "RedTeam")
		for i in range(4):opponent.add_item("BOT · %s %02d" % [("İnsan" if data.get("playerForm","human")=="wolf" else "Kurt") if hunting else ("Kurt" if i%2==0 else "İnsan"),i+1])
		for team in ["Red","Blue"]:
			var count=1 if (team=="Red")== (data.team=="red") else 4
			view.set_value(team+"CurChars","%d / %d" % [count,count]);view.find_widget(team+"CurChars").size.x=66;view.find_widget(team+"MaxChars").hide()
		ui.text(ui.content,"Yerel rakip planı · çevrimiçi oyuncu değil",Vector2(18,485),Vector2(570,30),12)
	var map_image=view.find_widget("CurrentMap")
	if int(data.map)!=0:
		map_image.texture=Art.atlas(ui.game.map_catalog.photo(int(data.map)).get("asset",""),Rect2(0,0,407,120))
	var start=enable("StartGame",ui.game.start_round)
	if start:start.disabled=not training
	if not training:
		ui.paragraph(ui.content,"Özgün maç kuralları tamamlanmadı. Yalnızca geometri gezintisi açılabilir.",Vector2(617,440),Vector2(385,90),16)
		ui.button(ui.content,"Haritayı gez",Vector2(12,542),Vector2(170,28),func():ui.mode_choice=int(data.mode);ui.map_choice=int(data.map);ui.navigate("maps"))
	var chat=view.find_widget("ChatEditBox")
	if chat is LineEdit:chat.placeholder_text="Çevrimiçi sohbet bağlı değil";chat.editable=false

func create_room():
	view=layout("interface/createfield",Vector2(303,202),Vector2(417,335))
	only(["BackGround","FieldNameEditBox","SelectMap","Confirm","Cancel"])
	var name=view.find_widget("FieldNameEditBox");name.editable=true;name.text=ui.room_draft.title;ui.room_title=name
	name.set_meta("navigation_input","room_title");name.text_changed.connect(func(value):ui.room_draft.title=value)
	ui.room_mode=ui.mode_picker(ui.content,Vector2(353,267),Vector2(163,30))
	for i in range(ui.room_mode.item_count):
		if ui.room_mode.get_item_id(i)==int(ui.room_draft.mode):ui.room_mode.select(i)
	ui.room_difficulty=ui.map_picker(ui.content,Vector2(521,267),Vector2(92,30))
	ui.room_difficulty.tooltip_text="Bot zorluğu"
	for value in ["easy","normal","hard"]:
		ui.room_difficulty.add_item(ui.game.BotRules.LEVELS[value].name);ui.room_difficulty.set_item_metadata(ui.room_difficulty.item_count-1,value)
		if value==ui.room_draft.get("botDifficulty","normal"):ui.room_difficulty.select(ui.room_difficulty.item_count-1)
	ui.room_difficulty.item_selected.connect(func(index):ui.room_draft.botDifficulty=ui.room_difficulty.get_item_metadata(index))
	ui.room_form=ui.map_picker(ui.content,Vector2(353,304),Vector2(163,30))
	ui.room_map=ui.map_picker(ui.content,Vector2(308,461),Vector2(365,28))
	var gallery=ui.button(ui.content,"▣",Vector2(677,461),Vector2(42,28),map_gallery);gallery.tooltip_text="Haritaları fotoğraflarıyla seç"
	var refresh_photo=func():view.find_widget("SelectMap").texture=Art.atlas(ui.game.map_catalog.photo(ui.room_map.get_selected_id()).get("asset",""),Rect2(0,0,407,120))
	var fill=func():
		ui.room_map.clear()
		if ui.game.is_local_mode(ui.room_mode.get_selected_id()):
			ui.room_map.add_item("Eğitim Arenası",0)
			for map in ui.game.map_catalog.offline_maps():ui.room_map.add_item(map.displayName,int(map.number))
		else:
			for map in ui.game.map_catalog.maps_for_mode(ui.room_mode.get_selected_id()):ui.room_map.add_item(map.displayName,int(map.number))
		for i in range(ui.room_map.item_count):
			if ui.room_map.get_item_id(i)==int(ui.room_draft.map):ui.room_map.select(i)
		if ui.room_map.item_count:ui.room_draft.map=ui.room_map.get_selected_id()
		var hunting=ui.room_mode.get_selected_id()==ui.game.LocalHunt.MODE
		ui.room_form.clear();ui.room_form.add_item("Mavi · İnsan" if hunting else "Mavi takım",0);ui.room_form.add_item("Kırmızı · Kurt" if hunting else "Kırmızı takım",1)
		ui.room_form.select((1 if ui.room_draft.get("playerForm","human")=="wolf" else 0) if hunting else (1 if ui.room_draft.team=="red" else 0))
		refresh_photo.call()
	ui.room_mode.item_selected.connect(func(_index):ui.room_draft.mode=ui.room_mode.get_selected_id();fill.call())
	ui.room_map.item_selected.connect(func(_index):ui.room_draft.map=ui.room_map.get_selected_id();refresh_photo.call())
	ui.room_form.item_selected.connect(func(index):ui.room_draft.team="red" if index==1 else "blue";ui.room_draft.playerForm="wolf" if index==1 else "human")
	fill.call()
	enable("Cancel",ui.go_back);ui.links.PLCancel=ui.links.Cancel;ui.links.PLExit=ui.links.Cancel
	enable("Confirm",func():
		if name.text.strip_edges().length()<2 or ui.room_map.item_count==0:ui.show_error("Oda adı ve moda bağlı harita gerekli.");return
		ui.game.local_room={"title":name.text.strip_edges(),"mode":ui.room_mode.get_selected_id(),"map":ui.room_map.get_selected_id(),"team":ui.room_draft.team,"botDifficulty":ui.room_difficulty.get_selected_metadata(),"playerForm":"wolf" if ui.room_form.selected==1 else "human"};ui.navigate("room")
	);ui.links.PLOK=ui.links.Confirm
	ui.text(ui.content,"Yerel oturum",Vector2(316,504),Vector2(190,25),12)

func maps():
	view=layout("interface/gameoption",Vector2(252,128),Vector2(520,512))
	only(["BackGround","Exit"])
	enable("Exit",ui.go_back)
	ui.text(ui.content,"MOD VE HARİTALAR",Vector2(276,156),Vector2(460,35),20,Art.GOLD)
	ui.game.mode_picker=ui.mode_picker(ui.content,Vector2(276,218),Vector2(470,44),false)
	for i in range(ui.game.mode_picker.item_count):
		if ui.game.mode_picker.get_item_id(i)==ui.mode_choice:ui.game.mode_picker.select(i)
	ui.game.map_picker=ui.map_picker(ui.content,Vector2(276,292),Vector2(390,44))
	ui.game.map_photo=Art.sprite(ui.content,"",Vector2(276,365),Vector2(225,120));ui.game.map_photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.game.map_status=ui.paragraph(ui.content,"",Vector2(512,355),Vector2(234,175),14)
	ui.button(ui.content,"Görseller",Vector2(674,300),Vector2(72,28),map_gallery)
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
	view.find_widget("RedResult").visible=(ui.game.hunt.wins>ui.game.hunt.losses) if ui.game.hunt.active else (ui.game.kills>=10 and ui.game.health>0)
	view.set_value("ChannelName","ÇEVRİMDIŞI MAÇ SONUCU",1)
	ui.text(ui.content,ui.game.last_result.get("title","Tur bitti"),Vector2(24,182),Vector2(740,40),22,Art.GOLD)
	var result="%s · %s\nÖldürme: %d\nCan: %d\nKalan süre: %d saniye" % [ui.game.profile_name,ui.game.preview_name,ui.game.kills,ui.game.health,maxi(0,int(ui.game.time_left))]
	if ui.game.hunt.active:result+="\nKazanılan raunt: %d · Kaybedilen: %d" % [ui.game.hunt.wins,ui.game.hunt.losses]
	result+="\n\nBu sonuç bu cihazdaki yerel maça aittir."
	ui.paragraph(ui.content,result,Vector2(35,250),Vector2(740,300),20)
	enable("Confirm",func():ui.navigate("lobby"))
	ui.button(ui.content,"Yeniden oyna",Vector2(590,701),Vector2(200,30),ui.game.start_round)

func profile():
	view=layout("interface/userrecord",Vector2(299,112),Vector2(425,522))
	only(["RecordBack","Exit","Confirm"])
	var background=view.find_widget("RecordBack");background.texture=Art.atlas("wt_interface/record/mm_bg.dtx",Rect2(0,0,425,522));background.size=Vector2(425,522)
	view.find_widget("Confirm").position.y=484
	enable("Exit",ui.go_back);enable("Confirm",ui.go_back)
	ui.trace("interface/userinfopropertypage")
	# The supplied mm_bg has twelve 24px rows, unlike the older attribute
	# page. Bind the values to the actual baked Turkish row labels.
	var values=[ui.game.ranks.current(int(ui.game.wallet.gp)).name,ui.game.profile_name,"—","—","—","—","—","—","—",str(ui.game.wallet.gold),str(ui.game.wallet.cash),"—"]
	for i in range(values.size()):ui.text(ui.content,values[i],Vector2(478,183+i*24),Vector2(228,22),12)
	ui.text(ui.content,"Yerel profil · çevrimiçi kayıt alınmadı",Vector2(312,478),Vector2(390,22),11)
	ui.button(ui.content,"İkinci şifre · Yerel profil",Vector2(318,640),Vector2(385,30),func():ui.navigate("pin"))
	ui.button(ui.content,"Rütbeler · Yerel GP",Vector2(318,678),Vector2(385,30),func():ui.navigate("rankbook"))

func map_gallery():
	ui.confirm("HARİTA SEÇ","",func():pass)
	for child in ui.modal.get_children():
		if child is Layout:child.hide()
	var panel=Panel.new();panel.position=Vector2(173,130);panel.size=Vector2(678,508);ui.modal.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("151b20");style.border_color=Color("616b6e");style.set_border_width_all(1);panel.add_theme_stylebox_override("panel",style)
	ui.text(panel,"HARİTA GÖRSELLERİ",Vector2(20,14),Vector2(638,30),20,Art.GOLD)
	var picker=ui.room_map if ui.page=="create_room" else ui.game.map_picker
	var indices=[]
	for i in range(picker.item_count):
		if not ui.game.map_catalog.photo(picker.get_item_id(i)).is_empty():indices.append(i)
	var count=indices.size();ui.map_gallery_page=clampi(ui.map_gallery_page,0,maxi(0,int((count-1)/6)))
	for i in range(ui.map_gallery_page*6,mini(count,ui.map_gallery_page*6+6)):
		var index=indices[i];var number=picker.get_item_id(index);var column=(i%6)%3;var row=int((i%6)/3)
		var cell=SourceCard.create(panel,Vector2(20+column*214,60+row*174),Vector2(208,163),func():
			picker.select(index);picker.item_selected.emit(index);ui.close_modal()
			if ui.page=="create_room":ui.refresh()
		)
		Art.sprite(cell,ui.game.map_catalog.photo(number).get("asset",""),Vector2(4,4),Vector2(200,112),Rect2(0,0,407,120)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ui.paragraph(cell,picker.get_item_text(index),Vector2(5,119),Vector2(198,38),13)
		cell.set_meta("map_number",number)
	ui.button(panel,"◀",Vector2(20,442),Vector2(90,34),func():ui.map_gallery_page-=1;map_gallery(),ui.map_gallery_page>0)
	ui.text(panel,"%d / %d" % [ui.map_gallery_page+1,maxi(1,ceili(count/6.0))],Vector2(122,445),Vector2(140,30),16)
	ui.button(panel,"▶",Vector2(270,442),Vector2(90,34),func():ui.map_gallery_page+=1;map_gallery(),(ui.map_gallery_page+1)*6<count)
	ui.button(panel,"Kapat",Vector2(492,442),Vector2(164,34),ui.close_modal)

func rankbook():
	var rank=ui.game.ranks.current(int(ui.game.wallet.gp));var next=ui.game.ranks.next(int(ui.game.wallet.gp))
	ui.text(ui.content,"RÜTBELER · YEREL İLERLEME",Vector2(30,85),Vector2(950,35),24,Art.GOLD)
	Art.sprite(ui.content,rank.background,Vector2(36,138),Vector2(64,64));Art.sprite(ui.content,rank.asset,Vector2(36,138),Vector2(64,64))
	ui.text(ui.content,rank.name,Vector2(116,142),Vector2(850,30),22)
	ui.text(ui.content,"%d GP · Sonraki rütbe: %s" % [int(ui.game.wallet.gp),str(next.get("localMinimumGp","Tamamlandı"))],Vector2(116,180),Vector2(850,30),16)
	var rows=ui.game.ranks.catalog.ranks;ui.rank_page=clampi(ui.rank_page,0,int((rows.size()-1)/15))
	for i in range(ui.rank_page*15,mini(rows.size(),ui.rank_page*15+15)):
		var row=rows[i];var at=Vector2(38+(i%15)%3*322,248+int((i%15)/3)*80)
		Art.sprite(ui.content,row.background,at,Vector2(40,40));Art.sprite(ui.content,row.asset,at,Vector2(40,40))
		ui.text(ui.content,row.name,at+Vector2(49,0),Vector2(267,22),15)
		ui.text(ui.content,"%d GP" % int(row.localMinimumGp),at+Vector2(49,25),Vector2(267,22),12)
	ui.button(ui.content,"Önceki",Vector2(38,675),Vector2(200,32),func():ui.rank_page-=1;ui.refresh(),ui.rank_page>0)
	ui.button(ui.content,"Sonraki",Vector2(256,675),Vector2(200,32),func():ui.rank_page+=1;ui.refresh(),(ui.rank_page+1)*15<rows.size())
	ui.paragraph(ui.content,"Kaynak rütbe adları ve simgeleri. GP eşikleri bu cihazdaki yerel ilerleme içindir.",Vector2(480,675),Vector2(500,50),13)

func scoreboard():
	view=layout("interface/gamestatewindow",Vector2(124,145),Vector2(776,470))
	for node in view.controls:node.hide()
	Art.sprite(ui.content,"wt_interface/gamestatewindow/pl_tab_red_back.dtx",Vector2(124,180),Vector2(381,56))
	Art.sprite(ui.content,"wt_interface/gamestatewindow/pl_tab_blue_back.dtx",Vector2(513,180),Vector2(381,56))
	var panel=Panel.new();panel.position=Vector2(124,236);panel.size=Vector2(770,300);ui.content.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("151b20");style.border_color=Color("616b6e");style.set_border_width_all(1);panel.add_theme_stylebox_override("panel",style)
	ui.text(ui.content,"MAÇ DURUMU · YEREL",Vector2(144,150),Vector2(720,26),20,Art.GOLD)
	ui.text(ui.content,ui.game.profile_name,Vector2(144,196),Vector2(340,28),18)
	ui.text(ui.content,"BOTLAR",Vector2(533,196),Vector2(340,28),18)
	var stats=ui.game.match_stats
	ui.paragraph(ui.content,"Öldürme: %d\nKafadan isabet: %d\nİsabet: %d / %d\nVerilen hasar: %d\nCan: %d" % [ui.game.kills,stats.headshots,stats.hits,stats.attacks,stats.damage,ui.game.health],Vector2(144,258),Vector2(335,210),19)
	var row=0
	for bot in ui.game.enemies.get_children():
		if bot.is_queued_for_deletion():continue
		ui.text(ui.content,"%s · %s · %d can" % [bot.display_name,bot.profile.name,maxi(0,bot.health)],Vector2(533,258+row*37),Vector2(340,32),16);row+=1
	ui.button(ui.content,"Devam et",Vector2(382,565),Vector2(260,34),ui.game.resume)

func friends():
	var at=Vector2(297,197)
	Art.sprite(ui.content,"wt_interface/messenger/ms_bg.dtx",at,Vector2(430,374),Rect2(0,0,430,374))
	view=layout("interface/gamebuddy",at,Vector2(430,374))
	for i in range(3):
		var node=Art.atlas_button(ui.content,"wt_interface/messenger/ms_tab.dtx",[Rect2(i*84,0,84,27),Rect2(i*84,27,84,27),Rect2(i*84,54,84,27)],at+Vector2(9+i*84,33),Vector2(84,27),func():ui.show_error("Çevrimiçi liste alınamadı."))
		node.toggle_mode=true;node.set_pressed_no_signal(i==0)
	var close=layout("interface/userrecord",at,Vector2(430,374));close.show_only(["Exit"])
	close.find_widget("Exit").position=Vector2(405,8);close.bind_action("Exit",ui.go_back)
	ui.paragraph(ui.content,"Çevrimiçi hizmet bağlı değil.\nListe alınamadı.",at+Vector2(35,150),Vector2(360,60),12).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func service():
	if ui.page=="friends":friends();return
	if ui.page=="clan":
		ui.trace("section/pride")
		ui.confirm("KLAN","Çevrimiçi klan bilgisi alınamadı.",ui.go_back);return
	var id=ui.SERVICE_LAYOUTS.get(ui.page,"section/messagebox")
	if ui.page=="missions":
		view=layout("interface/mission/missionpopup")
		only(["backGround","buttonGroupBox","missionButton","bingoButton","okButton"])
		enable("okButton",ui.go_back)
		view.find_widget("missionButton").set_pressed_no_signal(true)
	view=layout(id,Vector2(190,83) if ui.page=="gifts" else Vector2.ZERO,Vector2(643,625) if ui.page=="gifts" else Vector2(1024,768))
	if ui.page=="events":view.find_widget("TimeStandard").hide()
	for control in view.controls:
		if control is BaseButton:control.disabled=true
		if control is ItemList:control.clear()
		if control.get_meta("source_record").adapter=="digits":control.hide()
	for name in ["ExitButton","XClose","CloseButton","Exit","Confirm"]:enable(name,ui.go_back)
	ui.paragraph(ui.content,"Çevrimiçi hizmet bağlı değil.\nKayıtlar alınamadı.",Vector2(370,294),Vector2(340,65),12).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
