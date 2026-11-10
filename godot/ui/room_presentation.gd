extends Control
# Source-room decoration plus actual local session events. Never remote chat.
const Art=preload("res://ui/source_theme.gd")
const Info=preload("res://ui/room_info.gd")
var ui
var room_key=""
var log_view:RichTextLabel
var input:LineEdit
var ticker:Label
var ticker_width=0.0
var channel_buttons={}

func build(view):
	mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(1024,768)
	if ui.page!="room_settings":showcase()
	room_key=str(ui.game.local_room.get("roomId",0))
	if not ui.room_chat_logs.has(room_key):ui.room_chat_logs[room_key]=[]
	var info=Info.values(ui.game,ui.game.local_room)
	var state=JSON.stringify([ui.game.local_room,ui.game.profile_name])
	if ui.room_chat_states.get(room_key,"")!=state:
		ui.room_chat_states[room_key]=state
		append("[Oda] %s · %s · %s" % [ui.game.local_room.get("title","Yerel Oda"),info.mode,info.map],Color("e2cd77"))
		if not ui.game.is_local_mode(int(ui.game.local_room.get("mode",0))):append("[Oda] Bu modda yalnızca harita önizlemesi açılabilir.",Color("e2cd77"))
		append("[Oda] %s · %s Takım" % [ui.game.profile_name,"Mavi" if ui.game.local_room.team=="blue" else "Kırmızı"],Color("b6d1d8"))
		for team in ["red","blue"]:
			var names=[]
			for slot in range(ui.game.bot_limit(team)):names.append(ui.game.bot_roster.identity(ui.game,team,slot).name)
			if not names.is_empty():append("[Bot] %s · %s hazır" % ["Kırmızı" if team=="red" else "Mavi",", ".join(names)],Color("acbf8c"))
	view.find_widget("ChatListBox").hide();view.find_widget("ChatEditBox").hide()
	log_view=RichTextLabel.new();log_view.name="RoomEventLog";log_view.position=Vector2(44,611);log_view.size=Vector2(648,110);log_view.scroll_following=true;log_view.add_theme_font_override("normal_font",Art.font());log_view.add_theme_font_size_override("normal_font_size",12);log_view.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(log_view)
	input=LineEdit.new();input.name="LocalChatInput";input.position=Vector2(44,725);input.size=Vector2(648,20);input.theme=Art.native_theme();input.add_theme_font_size_override("font_size",12);input.max_length=180;input.placeholder_text="Yerel mesaj";input.text_submitted.connect(submit);add_child(input)
	for entry in [["ToAllChatButton","all"],["ToPrideChatButton","clan"],["ToShoutingChatButton","shout"]]:
		var button=view.find_widget(entry[0]);button.show();button.disabled=false;button.pressed.connect(func():ui.room_chat_channel=entry[1];render_log());channel_buttons[entry[1]]=button
	room_footer(info)
	render_log()

func append(message,color):
	var rows=ui.room_chat_logs[room_key];rows.append({"text":message,"color":color.to_html(false)})
	while rows.size()>80:rows.pop_front()

func submit(message):
	var text=message.strip_edges()
	if text=="" or ui.room_chat_channel!="all":return
	append(ui.game.profile_name+" : "+text,Color("c9d9db"));input.clear();render_log()

func render_log():
	for channel in channel_buttons:channel_buttons[channel].set_pressed_no_signal(ui.room_chat_channel==channel)
	log_view.clear();input.editable=ui.room_chat_channel=="all"
	input.placeholder_text="Yerel mesaj" if input.editable else ("Klan sohbeti çevrimiçi bağlantı gerektirir" if ui.room_chat_channel=="clan" else "Haykırma çevrimiçi bağlantı gerektirir")
	if not input.editable:return
	for row in ui.room_chat_logs[room_key]:
		log_view.push_color(Color(row.color));log_view.add_text(row.text+"\n");log_view.pop()

func showcase():
	for i in range(2):
		var card=Control.new();card.name="RoomShowcase"+str(i);card.position=Vector2(611+i*204,442);card.size=Vector2(203,119);card.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(card)
		var backing=ColorRect.new();backing.color=Color("222b2d");backing.size=card.size;backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(backing)
		Art.sprite(card,"res://assets/ui/room_showcase/"+("mitro" if i==0 else "fullmoon")+".png",Vector2.ZERO,Vector2(203,69))
		ui.text(card,"Mitro Kutusu" if i==0 else "Dolunay Kutusu",Vector2(2,71),Vector2(153,18),12)
		ui.text(card,"Kutu koleksiyonu",Vector2(2,96),Vector2(151,17),11,Color("d79c45"))
		var id="mystery" if i==0 else "wolf"
		var button=Art.button(card,"KUTULAR",Vector2(156,83),Vector2(45,30),func():
			ui.navigate("Kutular")
			ui.selected=ui.game.boxes.catalog.boxes.filter(func(entry):return entry.id==id)[0];ui.refresh())
		button.tooltip_text="Yerel kutu koleksiyonu";ui.links["RoomShowcase"+str(i)]=button
		button.get_meta("caption").add_theme_font_size_override("font_size",9)

func room_footer(info):
	var bar=ColorRect.new();bar.position=Vector2(0,750);bar.size=Vector2(1024,18);bar.color=Color("080e0d");bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bar)
	var clip=Control.new();clip.name="RoomTickerClip";clip.position=Vector2(0,750);clip.size=Vector2(1024,18);clip.clip_contents=true;clip.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(clip)
	var progress=ui.game.ranks.progress(int(ui.game.wallet.gp))
	var text="[Yerel Oda] %s     ·     %s     ·     %s     ·     %s (Seviye %d · %s)" % [ui.game.local_room.get("title","Yerel Oda"),info.mode,info.map,ui.game.profile_name,int(progress.level),progress.rankName]
	ticker_width=Art.font().get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+100
	ticker=ui.text(clip,text,Vector2.ZERO,Vector2(ticker_width,18),12,Color("76cd54"));ticker.name="LocalRoomTicker"

func _process(delta):
	if is_instance_valid(ticker) and ticker_width>1024:
		ticker.position.x-=delta*24
		if ticker.position.x < -ticker_width:ticker.position.x=1024
