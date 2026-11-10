extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const Collection=preload("res://ui/collection_page.gd")
const Options=preload("res://ui/settings_page.gd")
const Cards=preload("res://ui/card_page.gd")
const Boxes=preload("res://ui/box_page.gd")
const ProfileLockPage=preload("res://ui/profile_lock_page.gd")
const SourceCard=preload("res://ui/source_item_card.gd")
const Gifts=preload("res://ui/gift_page.gd")
const CareerPage=preload("res://ui/career_page.gd")
var ui
var view

func build():
	match ui.page:
		"entry":entry()
		"servers":servers()
		"lobby":lobby()
		"room":room()
		"create_room":lobby();create_room()
		"room_settings":
			room();ui.detail_helper=preload("res://ui/room_settings_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.room_view=view;ui.detail_helper.build()
		"maps":maps()
		"pause":pause_page()
		"kick":ui.detail_helper=preload("res://ui/local_kick_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"loading":ui.detail_helper=preload("res://ui/match_flow_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.loading()
		"result":result_page()
		"profile":profile()
		"pin":ui.detail_helper=ProfileLockPage.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"gifts":ui.detail_helper=Gifts.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"Setler":ui.detail_helper=preload("res://ui/source_sets_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.build()
		"Kutular":ui.detail_helper=Boxes.new();ui.detail_helper.ui=ui;ui.detail_helper.build()
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
	view.set_value("Version","Wolf Rogue Blood · "+str(ProjectSettings.get_setting("application/config/version"))+(" çevrimdışı" if OS.has_feature("offline_release") else " geliştirme"))
	# The sole rebrand region is the original title/logo area. No source paths
	# are renamed and the original backdrop is left intact.
	var strip=ColorRect.new();strip.color=Color("151b20");strip.position=Vector2(375,444);strip.size=Vector2(275,150);ui.content.add_child(strip)
	ui.paragraph(ui.content,"WOLF ROGUE\nBLOOD",Vector2(385,459),Vector2(255,120),30).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(ui.content,"Yerel oturuma devam",Vector2(362,635),Vector2(300,42),func():ui.navigate("servers" if ui.game.profile_lock.unlocked else "pin"))
	ui.button(ui.content,ui.game.profile_name+" · Oyuncu adı",Vector2(362,590),Vector2(300,32),local_name_window)
	ui.paragraph(ui.content,"Çevrimdışı oyun",Vector2(262,700),Vector2(500,35),15).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func local_name_window():
	ui.close_modal();ui.modal=Control.new();ui.modal.size=Vector2(1024,768);ui.modal.mouse_filter=Control.MOUSE_FILTER_STOP;ui.modal.z_index=100;ui.canvas.add_child(ui.modal)
	var veil=ColorRect.new();veil.color=Color(0,0,0,.72);veil.size=ui.modal.size;ui.modal.add_child(veil)
	var dialog=ui.native("interface/nicknamemessagebox",ui.modal,Vector2(276,241),Vector2(471,286))
	dialog.set_value("MessageBoxTitle","OYUNCU ADI");dialog.set_value("Message1","Bu cihazdaki oyuncu adın");dialog.set_value("Message2","2–24 karakter")
	var name=dialog.find_widget("NickNameEditBox");name.editable=true;name.max_length=24;name.text=ui.game.profile_name;name.grab_focus();name.caret_column=name.text.length()
	var submit=func():
		if not ui.game.book.set_local_name(name.text):ui.show_error("Oyuncu adı kaydedilemedi. 2–24 karakter kullan.");return
		ui.game.profile_name=ui.game.book.local_name;ui.last_error="";ui.close_modal();ui.refresh()
	dialog.bind_action("ConfirmButton",submit);dialog.bind_action("CancelButton",ui.close_modal);name.text_submitted.connect(func(_text):submit.call())

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
	ui.paragraph(ui.content,"ÇEVRİMDIŞI OYUN\nBu cihazdaki odalar",Vector2(24,150),Vector2(390,160),17)
	enable("NormalServer",func():ui.show_error("Çevrimiçi sunucu hizmeti bağlı değil."))

func lobby():
	ui.detail_helper=preload("res://ui/lobby_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.build();view=ui.detail_helper.view

func room():
	if ui.game.local_room.is_empty():lobby();return
	view=layout("section/field")
	only(["BackGround","FieldNumber","FieldName","UserListTop","StartGame","Invite","RedTeam","BlueTeam","RedCurChars","RedMaxChars","BlueCurChars","BlueMaxChars","ChangeTeam","ChangeRule","CurrentMap","GameMode","MapName","MaxChars","MissionObject","RoundTime","ChatTypeGroup","ToAllChatButton","ToPrideChatButton","ChatListBox","ChatEditBox","ChannelName"])
	var data=ui.game.local_room
	view.find_widget("PowerMasterRoomTitle").show()
	view.find_widget("UserListTop").texture=Art.atlas("wt_interface/battleroom/br_powermaster_tap.dtx",Rect2(0,0,603,48))
	for name in preload("res://ui/room_info.gd").visible_fields():
		var widget=view.find_widget(name)
		if widget:widget.show()
	preload("res://ui/room_info.gd").bind(ui.game,view,data)
	view.set_value("FieldName",data.get("title","Yerel Oda"))
	# Both legacy fields occupy the same rectangle; only the room title is drawn.
	view.find_widget("FieldNumber").hide()
	view.set_value("ChannelName","Yerel Oda",1)
	for name in ["RedTeam","BlueTeam"]:
		var users=view.find_widget(name)
		if users is ItemList and ((name=="RedTeam")== (data.team=="red")):users.add_item(ui.game.profile_name,Art.texture(ui.game.ranks.current(int(ui.game.wallet.gp)).asset));users.set_meta("data_origin","local_profile")
	enable("ChangeTeam",change_team)
	enable("ChangeRule",func():ui.navigate("room_settings"))
	enable("Invite",invite_window)
	var training=ui.game.is_local_mode(int(data.mode))
	var hunting=int(data.mode)==ui.game.LocalHunt.MODE
	view.set_value("GameMode",("Öğretici Mod" if int(data.mode)==ui.game.LocalTutorial.MODE else ("Kurt Avı · Yerel" if hunting else ("Kurt Savaşı · Yerel" if int(data.mode)==ui.game.WOLF_BATTLE else "Botlu Eğitim"))) if training else ui.game.map_catalog.mode_name(int(data.mode)))
	view.set_value("MapName","Eğitim Arenası" if int(data.map)==0 else ui.game.map_catalog.map_record(int(data.map)).displayName)
	view.set_value("MaxChars","%d Oyuncu" % int(data.get("capacity",16)))
	if training:
		var rules=preload("res://scripts/source_match_rules.gd").new();rules.configure(data)
		view.set_value("MissionObject",(("%d Tur" % rules.goal) if rules.round_based else ("%d Puan" % rules.goal)) if rules.enabled else ("3 raunt · 4 rakip" if hunting else "10 hedef"))
		view.set_value("RoundTime",("%d:%02d" % [rules.seconds/60,rules.seconds%60]) if rules.enabled else "90 saniye")
		if rules.enabled:view.set_value("GameMode",ui.game.map_catalog.mode_name(int(data.mode)))
		var opponent=view.find_widget("BlueTeam" if data.team=="red" else "RedTeam")
		for i in range(ui.game.bot_limit("red" if data.team=="blue" else "blue")):opponent.add_item("%s %d" % ["Kırmızı" if data.team=="blue" else "Mavi",i+1])
		for team in ["Red","Blue"]:
			var own=(team=="Red")== (data.team=="red")
			var count=1+ui.game.bot_limit(data.team) if own else ui.game.bot_limit("red" if data.team=="blue" else "blue")
			view.set_value(team+"CurChars","%d / %d" % [count,int(data.get("capacity",16)/2)]);view.find_widget(team+"CurChars").size.x=66;view.find_widget(team+"MaxChars").hide()
		var allies=view.find_widget("RedTeam" if data.team=="red" else "BlueTeam")
		for i in range(ui.game.bot_limit(data.team)):allies.add_item("%s %d" % ["Kırmızı" if data.team=="red" else "Mavi",i+1])
		var roster=preload("res://ui/room_roster_page.gd").new();roster.ui=ui;roster.build(view)
	var map_image=view.find_widget("CurrentMap")
	if int(data.map)!=0:
		map_image.texture=Art.map_photo(ui.game.map_catalog,int(data.map))
	var start=enable("StartGame",func():ui.game.match_flow.request_start(ui))
	if start:start.disabled=not training
	if not training:
		start.tooltip_text="Bu modda yalnızca harita önizlemesi açılabilir."
		ui.button(ui.content,"Haritayı gez",Vector2(12,542),Vector2(170,28),func():ui.mode_choice=int(data.mode);ui.map_choice=int(data.map);ui.navigate("maps"))
	# Translated source mode captions are longer than the old English field.
	preload("res://ui/room_info.gd").bind(ui.game,view,data)
	var mode_caption=view.find_widget("GameMode")
	if mode_caption is Label:
		mode_caption.size=Vector2(105,28);mode_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;mode_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mode_caption.add_theme_font_size_override("font_size",12)
		mode_caption.tooltip_text=mode_caption.text
	ui.links["Bot ve maç ayarları"]=ui.links.ChangeRule
	ui.room_presentation=preload("res://ui/room_presentation.gd").new();ui.room_presentation.name="RoomPresentation";ui.room_presentation.ui=ui;ui.content.add_child(ui.room_presentation);ui.room_presentation.build(view)
	if ui.game.match_flow.phase=="countdown":
		start.disabled=true
		var counter=preload("res://ui/match_flow_page.gd").new();counter.ui=ui;counter.countdown()

func change_team():
	var candidate=ui.game.local_room.duplicate(true);candidate.team="red" if candidate.team=="blue" else "blue"
	var saved=ui.game.local_rooms.commit(candidate)
	if saved.is_empty():ui.show_error(ui.game.local_rooms.last_error);return
	ui.game.local_room=saved;ui.refresh()

func invite_window():
	ui.close_modal();ui.modal=Control.new();ui.modal.size=ui.canvas.size;ui.modal.mouse_filter=Control.MOUSE_FILTER_STOP;ui.modal.z_index=100;ui.canvas.add_child(ui.modal)
	var veil=ColorRect.new();veil.color=Color(0,0,0,0.76);veil.size=ui.canvas.size;ui.modal.add_child(veil)
	var invite=ui.native("interface/gameinvitewindow",ui.modal,Vector2(312,180),Vector2(400,375))
	invite.show_only(["BackGround","NotExistLobbyUser","InviteButton","CancelButton","Exit"])
	invite.set_value("NotExistLobbyUser","Davet edilebilecek çevrimiçi oyuncu yok.")
	invite.find_widget("InviteButton").disabled=true
	invite.bind_action("CancelButton",ui.close_modal);invite.bind_action("Exit",ui.close_modal)

func create_room():
	ui.detail_helper=preload("res://ui/room_create_page.gd").new();ui.detail_helper.ui=ui;ui.detail_helper.build()


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
	only(["GameMenuBack","ExitButton","GameComeBack","Option","GameExit","UserKickVote"])
	enable("ExitButton",ui.game.resume);enable("GameComeBack",ui.game.resume)
	enable("Option",func():ui.navigate("Ayarlar"))
	enable("UserKickVote",func():ui.navigate("kick"))
	enable("GameExit",func():ui.game.running=false;ui.game.clear_projectiles();ui.navigate("lobby"))

func result_page():
	view=layout("section/result")
	only(["BackGround","Confirm","ChannelName"])
	var result=ui.game.last_result
	var detailed=ui.result_tab=="details"
	var background=view.find_widget("BackGround")
	background.texture=Art.atlas("wt_interface/gameresult/gr_bg.dtx" if detailed else "wt_interface/gameresult/gr_cc_bg.dtx",Rect2(0,0,1024,768))
	view.set_value("ChannelName","" if not detailed else ui.game.preview_name+" · "+result.get("title","Maç sonucu"),1)
	var scores=result.get("roundScores",{})
	var rewards=result.get("walletRewards",{})
	var stats=result.get("stats",{})
	if not detailed:
		# The four upper cards, fifth lower-left card and footer are the actual
		# PC gr_cc_bg layout. Only recorded local values are filled in.
		Art.sprite(ui.content,"wt_interface/gameresult/gr_result.dtx",Vector2(425,0),Vector2(175,59),Rect2(0,0 if result.get("victory",false) else 60,175,59))
		var cards=[["ÖLDÜRME",int(result.get("kills",0)),"ÖLDÜRME"],["TAM KAFADAN",int(stats.get("headshots",0)),"TAM KAFADAN"],["KAZANILAN GP",int(rewards.get("gp",0)),"GP"],["KAZANILAN ALTIN",int(rewards.get("gold",0)),"ALTIN"]]
		for i in range(cards.size()):
			var x=10+i*255
			ui.text(ui.content,cards[i][0],Vector2(x+12,52),Vector2(225,24),17,Art.GOLD)
			ui.text(ui.content,ui.game.profile_name,Vector2(x+12,77),Vector2(220,18),12)
			var number=ui.text(ui.content,str(cards[i][1]),Vector2(x+20,233),Vector2(197,60),36);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			var count=ui.text(ui.content,"%d %s" % [cards[i][1],cards[i][2]],Vector2(x+12,415),Vector2(225,24),15);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var sp=ui.text(ui.content,"SP\n%d" % int(result.get("earnedSp",0)),Vector2(34,510),Vector2(167,120),26,Art.GOLD);sp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var progress=result.get("progression",{});var after=progress.get("after",ui.game.ranks.progress(int(ui.game.wallet.gp)));var before=progress.get("before",after)
		var rank=ui.game.ranks.current(int(after.gp));Art.sprite(ui.content,rank.asset,Vector2(328,496),Vector2(28,32))
		var next_rank=ui.game.ranks.next(int(after.gp))
		if not next_rank.is_empty():Art.sprite(ui.content,next_rank.asset,Vector2(898,496),Vector2(28,32))
		var bar=Control.new();bar.name="AccountRankProgress";bar.position=Vector2(376,495);bar.size=Vector2(512*float(after.fraction),36);bar.clip_contents=true;ui.content.add_child(bar)
		Art.sprite(bar,"wt_interface/gameresult/gr_cc_bg.dtx",Vector2.ZERO,Vector2(512,36),Rect2(376,495,512,36)).modulate=Art.GOLD
		bar.tooltip_text="%s · %d GP kaldı" % [after.rankName,int(after.remainingGp)] if not after.maxed else "En yüksek yerel seviye"
		var level_text="Seviye %d → %d · %s" % [int(before.level),int(after.level),after.rankName] if int(after.level)>int(before.level) else "Seviye %d · %s" % [int(after.level),after.rankName]
		ui.text(ui.content,ui.game.profile_name+" · "+level_text,Vector2(330,543),Vector2(600,24),15,Art.GOLD if int(after.level)>int(before.level) else Color.WHITE).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		ui.text(ui.content,"%d / %d" % [int(result.get("kills",0)),int(result.get("deaths",0))],Vector2(270,650),Vector2(130,30),22).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		ui.text(ui.content,str(int(rewards.get("gold",0))),Vector2(415,650),Vector2(130,30),22).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		for x in [562,710,858]:ui.text(ui.content,"—",Vector2(x,650),Vector2(130,30),20).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	else:
		for team in ["red","blue"]:
			var y=172 if team=="red" else 493
			var winner=result.get("winner","")
			if winner in ["red","blue"]:
				Art.sprite(ui.content,"wt_interface/gameresult/gr_result.dtx",Vector2(601,85 if team=="red" else 406),Vector2(175,59),Rect2(0,(0 if team=="red" else 120)+(0 if winner==team else 60),175,59))
			var rows=result.get("roster",[]).filter(func(row):return row.team==team)
			for i in range(rows.size()):
				var row=rows[i];var native=ui.native("interface/resultuserinfo",ui.content,Vector2(4,y+i*30),Vector2(774,30));native.show_only(["GameRanking","NickName","Point","Dead","GetGamePoint","GetGold"])
				native.set_value("GameRanking",str(i+1));native.set_value("NickName",row.name);native.set_value("Point",str(row.kills)+"/");native.set_value("Dead",row.deaths);native.set_value("GetGamePoint",row.get("gp",0));native.set_value("GetGold",row.get("gold",0))
		var summary=ui.native("interface/mybattleresult",ui.content);summary.show_only(["NickName","GetGamePoint","GetGold","Point_Dead"])
		summary.set_value("NickName",ui.game.profile_name);summary.set_value("GetGamePoint",rewards.get("gp",0));summary.set_value("GetGold",rewards.get("gold",0));summary.set_value("Point_Dead","%d / %d" % [int(result.get("kills",0)),int(result.get("deaths",0))])
		if not scores.is_empty():ui.text(ui.content,"%d : %d" % [int(scores.red),int(scores.blue)],Vector2(350,75),Vector2(170,48),30,Art.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		ui.text(ui.content,"SP  %d\nKazanılan  %d\nHarcanan  %d" % [int(result.get("matchSp",0)),int(result.get("earnedSp",0)),int(result.get("spentSp",0))],Vector2(790,390),Vector2(220,135),16)
	var left=Art.atlas_button(ui.content,"wt_interface/gameresult/gr_button_back.dtx" if detailed else "wt_interface/gameresult/gr_button_detail.dtx",[Rect2(0,0,200,30),Rect2(0,31,200,30),Rect2(0,62,200,30)],Vector2(13,701 if detailed else 727),Vector2(200,30),func():ui.result_tab="awards" if detailed else "details";ui.refresh())
	if detailed:ui.links.ResultSummary=left;ui.links.ResultAwards=left
	else:ui.links.ResultDetails=left
	enable("Confirm",func():ui.navigate("room"));view.find_widget("Confirm").position=Vector2(811,701 if detailed else 727);view.find_widget("Confirm").tooltip_text="Odaya dön"

func profile():
	view=layout("interface/userrecord",Vector2(299,112),Vector2(425,522))
	only(["RecordBack","Exit","Confirm"])
	var background=view.find_widget("RecordBack");background.texture=Art.atlas("wt_interface/record/mm_bg.dtx",Rect2(0,0,425,522));background.size=Vector2(425,522)
	view.find_widget("Confirm").position.y=484
	enable("Exit",ui.go_back);enable("Confirm",ui.go_back)
	ui.trace("interface/userinfopropertypage")
	# The supplied mm_bg has twelve 24px rows, unlike the older attribute
	# page. Bind the values to the actual baked Turkish row labels.
	var values=[ui.game.ranks.current(int(ui.game.wallet.gp)).name,ui.game.profile_name,"—","—","—","—","—","—","—",str(ui.game.wallet.gold),ui.game.wallet_text("cash"),"—"]
	for i in range(values.size()):ui.text(ui.content,values[i],Vector2(478,183+i*24),Vector2(228,22),12)
	var progress=ui.game.ranks.progress(int(ui.game.wallet.gp))
	ui.text(ui.content,"Seviye %d / %d · %d GP · Yerel profil" % [progress.level,progress.maxLevel,progress.gp],Vector2(312,478),Vector2(390,22),11)
	ui.button(ui.content,"İkinci şifre · Yerel profil",Vector2(318,640),Vector2(385,30),func():ui.navigate("pin"))
	ui.button(ui.content,"Rütbeler · Yerel GP",Vector2(318,678),Vector2(385,30),func():ui.navigate("rankbook"))

func map_gallery():
	ui.confirm("HARİTA SEÇ","",func():pass)
	for child in ui.modal.get_children():
		if child is Layout:child.hide()
	var panel=Panel.new();panel.position=Vector2(173,130);panel.size=Vector2(678,508);ui.modal.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("151b20");style.border_color=Color("616b6e");style.set_border_width_all(1);panel.add_theme_stylebox_override("panel",style)
	ui.text(panel,"HARİTA GÖRSELLERİ",Vector2(20,14),Vector2(638,30),20,Art.GOLD)
	var picker=ui.room_map if ui.page in ["create_room","room_settings"] else ui.game.map_picker
	var indices=[]
	for i in range(picker.item_count):
		if not ui.game.map_catalog.photo(picker.get_item_id(i)).is_empty():indices.append(i)
	var count=indices.size();ui.map_gallery_page=clampi(ui.map_gallery_page,0,maxi(0,int((count-1)/6)))
	for i in range(ui.map_gallery_page*6,mini(count,ui.map_gallery_page*6+6)):
		var index=indices[i];var number=picker.get_item_id(index);var column=(i%6)%3;var row=int((i%6)/3)
		var cell=SourceCard.create(panel,Vector2(20+column*214,60+row*174),Vector2(208,163),func():
			picker.select(index);picker.item_selected.emit(index);ui.close_modal()
			if ui.page in ["create_room","room_settings"]:ui.refresh()
		)
		Art.sprite(cell,Art.map_photo(ui.game.map_catalog,number),Vector2(4,4),Vector2(200,112)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	ui.text(ui.content,"Seviye %d · %s" % [ui.game.ranks.progress(int(ui.game.wallet.gp)).level,rank.name],Vector2(116,142),Vector2(850,30),22)
	ui.text(ui.content,"%d GP · Sonraki rütbe: %s" % [int(ui.game.wallet.gp),str(next.get("localMinimumGp","Tamamlandı"))],Vector2(116,180),Vector2(850,30),16)
	var rows=ui.game.ranks.catalog.ranks;ui.rank_page=clampi(ui.rank_page,0,int((rows.size()-1)/15))
	for i in range(ui.rank_page*15,mini(rows.size(),ui.rank_page*15+15)):
		var row=rows[i];var at=Vector2(38+(i%15)%3*322,248+int((i%15)/3)*80)
		Art.sprite(ui.content,row.background,at,Vector2(40,40));Art.sprite(ui.content,row.asset,at,Vector2(40,40))
		ui.text(ui.content,row.name,at+Vector2(49,0),Vector2(267,22),15)
		ui.text(ui.content,"Sv. %d · %d GP" % [i+1,int(row.localMinimumGp)],at+Vector2(49,25),Vector2(267,22),12)
	ui.button(ui.content,"Önceki",Vector2(38,675),Vector2(200,32),func():ui.rank_page-=1;ui.refresh(),ui.rank_page>0)
	ui.button(ui.content,"Sonraki",Vector2(256,675),Vector2(200,32),func():ui.rank_page+=1;ui.refresh(),(ui.rank_page+1)*15<rows.size())
	ui.paragraph(ui.content,"Kaynak rütbe adları ve simgeleri. GP eşikleri bu cihazdaki yerel ilerleme içindir.",Vector2(480,675),Vector2(500,50),13)

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
