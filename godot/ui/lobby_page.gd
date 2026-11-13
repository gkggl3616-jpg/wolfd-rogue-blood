extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Info=preload("res://ui/room_info.gd")
var ui
var view
var list
var visible_rooms=[]
var row_views=[]
var touch_owner=-1
var touched_row
var touch_origin=Vector2.ZERO
var mouse_row
func build():
	var directory=ui.game.local_rooms
	if not ui.game.local_room.is_empty():
		var remembered=directory.remember(ui.game.local_room)
		if not remembered.is_empty():ui.game.local_room=remembered
	view=ui.native("section/battle",ui.content)
	view.show_only(["LobbyBackGround","CreateBattle","QuickStart","Refresh","ChannelButtonGroup","Channel1","Channel2","Channel3","Channel4","Channel5","ChatTypeGroup","ToAllChatButton","ToPrideChatButton","ToShoutingChatButton","ChatListBox","ChatEditBox","ChannelUserListBox","RoomNumberSort","RoomStatusSort","RoomTypeSort","RoomMapNameSort","ChannelName","PlayModeSelectComboBox"])
	bind("CreateBattle",func():ui.navigate("create_room"));bind("QuickStart",join_selected);bind("Refresh",ui.refresh);bind("Channel1",ui.refresh)
	for i in range(2,6):view.find_widget("Channel%d" % i).tooltip_text="Çevrimiçi kanal"
	var filter=view.find_widget("PlayModeSelectComboBox");filter.disabled=false;filter.clear();filter.add_item("Tümü",99999)
	for mode in [{"id":0,"displayName":"Botlu Eğitim"},{"id":ui.game.LocalHunt.MODE,"displayName":"Kurt Avı"},{"id":ui.game.WOLF_BATTLE,"displayName":"Kurt Savaşı"}]+ui.game.map_catalog.data.modes:
		filter.add_item(mode.displayName,int(mode.id))
		if int(mode.id)==ui.lobby_mode_filter:filter.select(filter.item_count-1)
	filter.item_selected.connect(func(_i):ui.lobby_mode_filter=-1 if filter.get_selected_id()==99999 else filter.get_selected_id();ui.lobby_page_index=0;ui.refresh())
	for pair in [["RoomNumberSort","number"],["RoomStatusSort","state"],["RoomTypeSort","mode"],["RoomMapNameSort","map"]]:
		bind(pair[0],func():ui.lobby_descending=not ui.lobby_descending if ui.lobby_sort==pair[1] else false;ui.lobby_sort=pair[1];ui.refresh())
	var users=view.find_widget("ChannelUserListBox");users.add_item(ui.game.profile_name,Art.texture(ui.game.ranks.current(int(ui.game.wallet.gp)).asset));users.set_meta("data_origin","local_profile")
	var chat=view.find_widget("ChatEditBox");chat.placeholder_text="Çevrimiçi sohbet bağlı değil";chat.editable=false
	view.set_value("ChannelName","YEREL KANAL",1)
	var duplicate=view.find_widget("ChannelName",-1)
	if duplicate:duplicate.hide()
	visible_rooms=directory.rooms.filter(func(room):return ui.lobby_mode_filter==-1 or int(room.mode)==ui.lobby_mode_filter)
	visible_rooms.sort_custom(func(a,b):
		var av=int(a.roomId) if ui.lobby_sort=="number" or ui.lobby_sort=="state" else (int(a.mode) if ui.lobby_sort=="mode" else int(a.map));var bv=int(b.roomId) if ui.lobby_sort=="number" or ui.lobby_sort=="state" else (int(b.mode) if ui.lobby_sort=="mode" else int(b.map))
		return av>bv if ui.lobby_descending else av<bv)
	list=ui.native("interface/fieldlistscreen",ui.content);list.show_only([])
	if visible_rooms.is_empty():
		ui.paragraph(ui.content,"Yerel oda yok." if ui.lobby_mode_filter==-1 else "Bu modda oda yok.",Vector2(28,150),Vector2(550,70),17);return
	if not visible_rooms.any(func(room):return int(room.roomId)==directory.selected_id):directory.selected_id=int(visible_rooms[0].roomId)
	ui.lobby_page_index=clampi(ui.lobby_page_index,0,int((visible_rooms.size()-1)/16))
	for index in range(16):
		var at=ui.lobby_page_index*16+index
		if at>=visible_rooms.size():break
		build_row(visible_rooms[at],index)
	list.bind_action("PrevPage",func():ui.lobby_page_index-=1;ui.refresh());list.bind_action("NextPage",func():ui.lobby_page_index+=1;ui.refresh())
	for name in ["PrevPage","NextPage"]:list.find_widget(name).visible=visible_rooms.size()>16
	list.find_widget("PrevPage").disabled=ui.lobby_page_index==0;list.find_widget("NextPage").disabled=(ui.lobby_page_index+1)*16>=visible_rooms.size()
	update_details()
func bind(name,callback):
	view.bind_action(name,callback);ui.links[name]=view.find_widget(name)
func build_row(data,index):
	var row=list.find_widget("FieldListButton",index);row.show();row.disabled=false;row.set_meta("data_origin","local_room");row.set_meta("room_id",int(data.roomId))
	row.pressed.connect(func():select_room(int(data.roomId)))
	row.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index==MOUSE_BUTTON_LEFT:select_room(int(data.roomId));join_selected())
	var fields=ui.native("interface/fieldbutton",row,Vector2.ZERO,Vector2(587,21));fields.show_only(["FieldID","Secret","FieldName","GameState","CurChars","MaxChars","GameMode","MapName"])
	var info=Info.values(ui.game,data);fields.set_value("FieldID",str(data.roomId));fields.set_value("FieldName",data.title);fields.set_value("GameState","BEKLEME");fields.set_value("CurChars",str(ui.game.local_rooms.population(data)));fields.set_value("MaxChars","/ "+str(data.get("capacity",16)));fields.set_value("GameMode",info.mode);fields.set_value("MapName",info.map)
	for name in ["GameState","GameMode","MapName","CurChars","MaxChars"]:
		var label=fields.find_widget(name);label.add_theme_font_size_override("font_size",9 if name=="GameState" else 10)
	fields.find_widget("CurChars").position.x=312;fields.find_widget("CurChars").size.x=16;fields.find_widget("MaxChars").size.x=31
	fields.find_widget("Secret").visible=data.get("passwordDigest","")!="";row.tooltip_text=data.title+" · "+info.map;row_views.append(row)
func select_room(id):
	ui.game.local_rooms.selected_id=id;update_details()
func update_details():
	var data=ui.game.local_rooms.by_id(ui.game.local_rooms.selected_id)
	if data.is_empty():return
	for name in Info.visible_fields(true):
		var control=list.find_widget(name)
		if control:control.show()
	Info.bind(ui.game,list,data,true)
	for row in row_views:row.self_modulate=Color("e6d28e") if int(row.get_meta("room_id"))==int(data.roomId) else Color.WHITE
	ui.links.QuickStart.disabled=false
func join_selected():
	var data=ui.game.local_rooms.by_id(ui.game.local_rooms.selected_id)
	if data.is_empty():ui.navigate("create_room");return
	if data.get("passwordDigest","")=="":join_room(data.roomId,"");return
	ui.close_modal();ui.modal=Control.new();ui.modal.size=ui.canvas.size;ui.modal.mouse_filter=Control.MOUSE_FILTER_STOP;ui.modal.z_index=100;ui.canvas.add_child(ui.modal)
	var veil=ColorRect.new();veil.color=Color(0,0,0,.7);veil.size=ui.canvas.size;ui.modal.add_child(veil)
	var dialog=ui.native("interface/passwordmessagebox",ui.modal,Vector2(276,241),Vector2(471,286));dialog.show_only(["MessageBoxBack","MessageBoxTitle","Message","InputBack","PasswordEditBox","OKButton","CancelButton","Exit"])
	dialog.set_value("MessageBoxTitle","Şifreli Oda");dialog.set_value("Message",data.title)
	var entry=dialog.find_widget("PasswordEditBox");entry.editable=true;entry.secret=true;entry.grab_focus()
	var submit=func():
		if not ui.game.local_rooms.accepts_password(data.roomId,entry.text):ui.show_error("Oda şifresi yanlış.");entry.clear();return
		var password=entry.text;ui.close_modal();ui.last_error="";join_room(data.roomId,password)
	dialog.bind_action("OKButton",submit);entry.text_submitted.connect(func(_value):submit.call());dialog.bind_action("CancelButton",ui.close_modal);dialog.bind_action("Exit",ui.close_modal)
func join_room(id,password):
	if not ui.game.local_rooms.accepts_password(id,password):return false
	ui.game.local_room=ui.game.local_rooms.by_id(id);ui.navigate("room");return true
func nearest_row(point,expanded):
	var found=null;var distance=INF
	for row in row_views:
		var local=row.get_global_transform_with_canvas().affine_inverse()*point
		if not (row.target_rect() if expanded else Rect2(Vector2.ZERO,row.size)).has_point(local):continue
		var value=point.distance_squared_to(row.get_global_rect().get_center())
		if value<distance:found=row;distance=value
	return found
func cancel_input():touch_owner=-1;touched_row=null;mouse_row=null
func handle_input(event):
	if event is InputEventMouse:
		if event.device==InputEvent.DEVICE_ID_EMULATION:
			if nearest_row(event.position,true)!=null:ui.get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			var row=nearest_row(event.position,false)
			if event.pressed:
				mouse_row=row
				if row!=null and event.double_click:select_room(row.get_meta("room_id"));mouse_row=null;join_selected()
			elif row!=null and row==mouse_row:mouse_row=null;select_room(row.get_meta("room_id"))
			if row!=null:ui.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			if touch_owner>=0:return
			var row=nearest_row(event.position,true)
			if row==null:return
			touch_owner=event.index;touched_row=row;touch_origin=event.position;ui.get_viewport().set_input_as_handled()
		elif event.index==touch_owner:
			var row=touched_row;touch_owner=-1;touched_row=null;ui.get_viewport().set_input_as_handled()
			if is_instance_valid(row) and nearest_row(event.position,true)==row and ((event.position-touch_origin)*ui.get_viewport().get_final_transform().get_scale().abs()).length()<18:select_room(row.get_meta("room_id"))
	elif event is InputEventScreenDrag and event.index==touch_owner:
		if event.position.distance_to(touch_origin)>18:touched_row=null
