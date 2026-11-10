extends "res://ui/room_settings_page.gd"
# Original compact creator: mode / variant / team / map keep their source
# widgets. Offline bot controls live in their own optional window.
var options:Control
func build():
	draft=ui.room_draft
	var veil=ColorRect.new();veil.name="RoomCreatorVeil";veil.color=Color(0,0,0,.48);veil.size=Vector2(1024,768);veil.mouse_filter=Control.MOUSE_FILTER_STOP;ui.content.add_child(veil)
	view=ui.native("interface/createfield",ui.content,Vector2(303,202),Vector2(417,335))
	view.show_only(["BackGround","FieldNameEditBox","PasswordEditBox","SelectMap","ModeTypeComboBox","GameOptionComboBox","TeamComboBox","MapComboBox","Confirm","Cancel"])
	var title=view.find_widget("FieldNameEditBox");title.editable=true;title.max_length=48;title.text=draft.title;ui.room_title=title
	title.set_meta("navigation_input","room_title");title.text_changed.connect(func(value):draft.title=value)
	var password=view.find_widget("PasswordEditBox");password.editable=true;password.secret=true;password.text=str(draft.get("passwordEdit",""));password.placeholder_text="";password.set_meta("navigation_input","room_password");password.text_changed.connect(func(value):draft.passwordEdit=value)
	family=picker("ModeTypeComboBox");variant=picker("GameOptionComboBox");maps=picker("MapComboBox");team=picker("TeamComboBox")
	var modes=[{"id":0,"name":"Botlu Eğitim"},{"id":ui.game.LocalHunt.MODE,"name":"Kurt Avı"},{"id":ui.game.LocalTutorial.MODE,"name":"Öğretici Mod"},{"id":ui.game.WOLF_BATTLE,"name":"Kurt Savaşı"}]
	for row in ui.game.map_catalog.data.modes:modes.append({"id":int(row.id),"name":row.displayName})
	for row in modes:
		var base=row.name.get_slice(" · ",0)
		if not families.has(base):families[base]=[];family.add_item(base,int(row.id))
		families[base].append(row)
	for i in range(family.item_count):
		if families[family.get_item_text(i)].any(func(row):return row.id==int(draft.mode)):family.select(i)
	team.add_item("Mavi takım",0);team.add_item("Kırmızı takım",1);team.select(1 if draft.team=="red" else 0)
	team.item_selected.connect(func(i):draft.team="red" if i==1 else "blue")
	family.item_selected.connect(func(_i):fill_variants());variant.item_selected.connect(func(_i):draft.mode=variant.get_selected_id();fill_rules())
	maps.item_selected.connect(func(_i):draft.map=maps.get_selected_id();refresh_photo())
	ui.room_mode=family;ui.room_map=maps;ui.room_form=team
	var photo=view.find_widget("SelectMap");var gallery=preload("res://ui/touch_button.gd").new();gallery.position=photo.position;gallery.size=photo.size;gallery.ignore_texture_size=true;gallery.tooltip_text="Harita görselleri";view.add_child(gallery);gallery.pressed.connect(show_maps);ui.links["Harita görselleri"]=gallery
	var option_action=Button.new();option_action.hide();view.add_child(option_action);option_action.pressed.connect(show_options);ui.links["Bot ve maç ayarları"]=option_action
	build_options();fill_variants()
	view.bind_action("Confirm",apply);view.bind_action("Cancel",ui.go_back)
	ui.links.PLOK=view.find_widget("Confirm");ui.links.PLCancel=view.find_widget("Cancel");ui.links.PLExit=ui.links.PLCancel
	ui.links.Confirm=ui.links.PLOK;ui.links.Cancel=ui.links.PLCancel
	title.text_submitted.connect(func(_value):apply())
func build_options():
	options=Control.new();options.name="OfflineRoomOptions";options.set_meta("close_scope",true);options.size=Vector2(1024,768);options.mouse_filter=Control.MOUSE_FILTER_STOP;ui.content.add_child(options)
	var veil=ColorRect.new();veil.color=Color(0,0,0,.7);veil.size=options.size;options.add_child(veil)
	var window=ui.native("interface/gameoption",options,Vector2(252,128),Vector2(520,512));window.show_only(["BackGround","Exit"]);window.bind_action("Exit",func():options.hide())
	ui.text(options,"BOT VE MAÇ AYARLARI",Vector2(275,155),Vector2(460,34),20)
	for row in [["Oyuncu sınırı",215],["Zorluk",270],["Dost / rakip bot",325],["Hedef",380],["Süre",435]]:ui.text(options,row[0],Vector2(278,row[1]),Vector2(210,28),15)
	capacity=ui.map_picker(options,Vector2(498,215),Vector2(235,30))
	for n in range(2,17,2):capacity.add_item("%d oyuncu" % n,n)
	for i in range(capacity.item_count):
		if capacity.get_item_id(i)==int(draft.get("capacity",16)):capacity.select(i)
	capacity.item_selected.connect(func(_i):draft.capacity=capacity.get_selected_id();fill_bot_limits())
	difficulty=ui.map_picker(options,Vector2(498,270),Vector2(235,30))
	for level in ["easy","normal","hard"]:
		difficulty.add_item(ui.game.BotRules.LEVELS[level].name);difficulty.set_item_metadata(difficulty.item_count-1,level)
		if level==draft.get("botDifficulty","normal"):difficulty.select(difficulty.item_count-1)
	difficulty.item_selected.connect(func(_i):draft.botDifficulty=difficulty.get_selected_metadata())
	allies=ui.map_picker(options,Vector2(498,325),Vector2(112,30));enemies=ui.map_picker(options,Vector2(621,325),Vector2(112,30))
	allies.item_selected.connect(func(i):draft.allyBots=i);enemies.item_selected.connect(func(i):draft.enemyBots=i)
	goal=ui.map_picker(options,Vector2(498,380),Vector2(235,30));clock=ui.map_picker(options,Vector2(498,435),Vector2(235,30))
	goal.item_selected.connect(func(_i):draft.pointGoal=goal.get_selected_id();draft.roundGoal=goal.get_selected_id());clock.item_selected.connect(func(_i):draft.matchSeconds=clock.get_selected_id())
	ui.button(options,"Tamam",Vector2(498,540),Vector2(235,36),func():options.hide())
	ui.room_allies=allies;ui.room_enemies=enemies;ui.room_difficulty=difficulty;ui.room_goal=goal;ui.room_time=clock;options.hide()
func fill_rules():
	maps.clear();var local=ui.game.is_local_mode(int(draft.mode))
	if local and not Rules.supports(int(draft.mode)):maps.add_item("Eğitim Arenası",0)
	for row in (ui.game.map_catalog.offline_maps() if local and not Rules.supports(int(draft.mode)) else ui.game.map_catalog.maps_for_mode(int(draft.mode))):maps.add_item(row.displayName,int(row.number))
	for i in range(maps.item_count):
		if maps.get_item_id(i)==int(draft.get("map",0)):maps.select(i)
	if maps.item_count:draft.map=maps.get_selected_id()
	goal.clear();clock.clear();var rules=Rules.new();rules.configure(draft);goal.disabled=not rules.enabled;clock.disabled=not rules.enabled
	if rules.enabled:
		for row in rules.record.goals:
			var n=int(row.rounds if rules.round_based else row.points);goal.add_item(("%d Tur" if rules.round_based else "%d Puan") % n,n)
			if n==rules.goal:goal.select(goal.item_count-1)
		for row in rules.record.times:
			clock.add_item("%d:%02d" % [int(row.seconds)/60,int(row.seconds)%60],int(row.seconds))
			if int(row.seconds)==rules.seconds:clock.select(clock.item_count-1)
		draft.pointGoal=rules.goal;draft.roundGoal=rules.goal;draft.matchSeconds=rules.seconds
	else:goal.add_item("Yerel kural",10);clock.add_item("1:30",90)
	fill_bot_limits();refresh_photo()
func apply():
	var title=view.find_widget("FieldNameEditBox").text.strip_edges()
	if title.length()<2 or maps.item_count==0:ui.show_error("Oda adı ve moda uygun harita gerekli.");return
	draft.title=title;draft.capacity=capacity.get_selected_id();draft.playerForm="wolf" if int(draft.mode)==ui.game.LocalHunt.MODE and draft.team=="red" else "human"
	var saved=ui.game.local_rooms.commit(draft,true)
	if saved.is_empty():ui.show_error(ui.game.local_rooms.last_error);return
	ui.game.local_room=saved;ui.history=["lobby"];ui.navigate("room",false)
func dismiss_overlay():
	if not options.visible:return false
	options.hide();return true

func show_options():
	options.show();ui.call_deferred("raise_close_controls")
