extends SceneTree
const Native=preload("res://ui/source_layout.gd")
const Rooms=preload("res://scripts/local_rooms.gd")
var checks=0
var failures=[]
var game
var ui
func _initialize():call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func layout(parent,id):
	for item in parent.find_children("*","Control",true,false):
		if item is Native and item.layout_id==id:return item
	return null
func touch(button,index=0,drag=false):
	var point=root.get_final_transform()*button.get_global_rect().get_center();var e=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=true;Input.parse_input_event(e);await frames(1)
	e=InputEventScreenTouch.new();e.index=index;e.position=point+Vector2(80,0) if drag else point;e.pressed=false;Input.parse_input_event(e);await frames(3)
func select(picker,id):
	for i in range(picker.item_count):
		if picker.get_item_id(i)==id:picker.select(i);picker.item_selected.emit(i);return true
	return false
func run():
	var store=Rooms.new();store.configure("user://room032-regression.json",true);store.save_blocked=false;store.rooms=[];store.next_id=1
	var spec={"title":"Şifreli Kurt Odası","mode":1000,"map":1,"team":"blue","capacity":8,"allyBots":3,"enemyBots":4,"passwordEdit":"kurt-test-032"}
	var first=store.commit(spec,true);check(not first.is_empty() and first.roomId==1 and not first.has("passwordEdit"),"Create returns a unique real room and never stores plaintext password")
	check(store.accepts_password(1,"kurt-test-032") and not store.accepts_password(1,"wrong"),"Local password gate checks the actual protected room")
	check(not FileAccess.get_file_as_string(store.storage_path).contains("kurt-test-032"),"Persisted room file contains no plaintext password")
	var second=store.commit({"title":"Açık İnsan Odası","mode":1001,"map":50,"team":"red","capacity":12},true);check(second.roomId==2 and store.rooms.size()==2 and store.population(first)==8,"Different rooms keep stable IDs and actual capacity-limited population")
	var reload=Rooms.new();reload.configure(store.storage_path,true);check(reload.rooms==store.rooms and reload.next_id==3 and reload.accepts_password(1,"kurt-test-032"),"Directory and protected entry survive a real disk reload")
	var before=store.rooms.duplicate(true);var next=store.next_id;store.save_blocked=true;var failed=store.commit(spec,true);check(failed.is_empty() and store.rooms==before and store.next_id==next,"Failed save preserves every existing room and ID counter")
	store.save_blocked=false;var edited=first.duplicate(true);edited.title="Yeni Başlık";edited.passwordEdit="";var saved=store.commit(edited);check(saved.roomId==1 and store.rooms.size()==2 and store.accepts_password(1,""),"Edit updates the same room and explicitly clearing its password removes the gate")
	var duplicate={"schema":1,"rooms":[first,first],"nextId":3};check(not store.valid(duplicate),"Duplicate room IDs are rejected on load")
	var leaked=first.duplicate(true);leaked.password="unsafe";check(not store.valid({"schema":1,"rooms":[leaked],"nextId":3}),"Unvalidated plaintext-password saves are rejected")
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);ui=game.pc_panel;ui.navigate("lobby");await frames()
	check(game.local_rooms.rooms.is_empty() and layout(ui.content,"interface/fieldbutton")==null,"Fresh offline lobby fabricates no rooms or remote players")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(960,540),Vector2i(800,450)]:
		root.size=dimensions;await frames();ui.navigate("lobby");await frames();var header=ui.get_node("ResponsiveHeader")
		check(header.size==Vector2(1024,58) and header.scale.is_equal_approx(ui.canvas.scale) and ui.content.scale==Vector2.ONE and ui.content.position==Vector2.ZERO,"Fixed source header and unshifted content: "+str(dimensions))
		var icon=ui.links.Envanter;var hit=root.get_final_transform()*icon.get_global_transform_with_canvas()*icon.target_rect();check(hit.size.x>=47.9 and hit.size.y>=47.9,"Source-size icon retains a real 48px physical touch area: "+str(dimensions))
		await touch(ui.links.Envanter);check(ui.page=="Envanter","First finger selects actual header route at "+str(dimensions));ui.navigate("lobby");await frames();await touch(ui.links.Envanter,0,true);check(ui.page=="lobby","Dragging off a toolbar action cannot open the wrong page: "+str(dimensions))
	root.size=Vector2i(1280,720);await frames();ui.navigate("lobby");await frames();ui.links.CreateBattle.pressed.emit();await frames()
	var create=layout(ui.content,"interface/createfield");check(ui.page=="create_room" and layout(ui.content,"section/battle")!=null and ui.content.find_child("RoomCreatorVeil",false,false)!=null,"Compact source creator overlays the actual lobby")
	check(create.position==Vector2(303,202) and create.size==Vector2(417,335) and create.find_widget("SelectMap").texture!=null and int(ui.room_draft.mode)==1000,"Creator starts on an admitted PC mode with a real source map photograph")
	check(not ui.links["Bot ve maç ayarları"].visible and ui.links["Harita görselleri"].size==create.find_widget("SelectMap").size,"Offline options do not add extra buttons outside source dialog geometry")
	await touch(ui.links.Diğer);check(ui.detail_helper.options.visible,"Header context opens working bot and match options");ui.detail_helper.options.hide()
	ui.room_title.text="Türkçe Kurt Odası";ui.room_draft.title=ui.room_title.text;var password=create.find_widget("PasswordEditBox");password.text="oda032";password.text_changed.emit(password.text);password.grab_focus();password.caret_column=3
	root.size=Vector2i(1920,1080);await frames();create=layout(ui.content,"interface/createfield");password=create.find_widget("PasswordEditBox");check(password.secret and password.text=="oda032" and password.has_focus() and password.caret_column==3 and ui.room_title.text=="Türkçe Kurt Odası","Resize keeps private input, Unicode title and focused caret")
	ui.room_draft.capacity=8;select(ui.detail_helper.capacity,8);select(ui.detail_helper.allies,3);select(ui.detail_helper.enemies,4);ui.links.PLOK.pressed.emit();await frames();var room1=game.local_room.duplicate(true)
	check(ui.page=="room" and game.local_rooms.rooms.size()==1 and room1.capacity==8 and room1.allyBots==3,"Create commits the complete validated room once")
	var room=layout(ui.content,"section/field");check(room.find_widget("UserListTop").texture is AtlasTexture and room.find_widget("RedTeamType").texture!=null and room.find_widget("GameOption").texture!=null,"Room binds native colored team header and original mode/form sprites")
	var roster=ui.content.find_child("RoomRosterblue",false,false);check(roster!=null and roster.size==Vector2(294,352) and roster.get_child_count()==8,"All eight native rows fit without an unnecessary scrolling roster")
	var closed=layout(roster.get_child(4),"interface/fielduserbutton");check(closed.find_widget("UserState").texture.region.position.y==88,"Closed slots show the actual source closed-state artwork")
	ui.go_back();await frames();var current=layout(ui.content,"interface/fieldlistscreen");check(current.find_widget("CurrentMap").texture!=null and current.find_widget("CurrentRoomName").text==room1.title and current.find_widget("MaxChars").text=="4 vs 4","Lobby binds separate native map, title and team-capacity fields")
	ui.links.CreateBattle.pressed.emit();await frames();ui.room_title.text="İnsan İkinci Oda";ui.room_draft.title=ui.room_title.text;ui.links.PLOK.pressed.emit();await frames();var room2=game.local_room.duplicate(true);check(room2.roomId!=room1.roomId and game.local_rooms.rooms.size()==2 and not room2.has("passwordDigest"),"Creating another room retains the first and does not inherit its password")
	ui.go_back();await frames();var helper=ui.detail_helper;helper.select_room(room1.roomId);check(ui.page=="lobby" and game.local_room==room2 and helper.list.find_widget("CurrentRoomName").text==room1.title,"Selecting previews another room without joining or changing the active configuration")
	helper.join_selected();await frames();var prompt=layout(ui.modal,"interface/passwordmessagebox");check(prompt!=null and ui.page=="lobby","Joining the protected selection opens the original password dialog")
	prompt.find_widget("PasswordEditBox").text="wrong";prompt.find_widget("OKButton").pressed.emit();check(ui.modal!=null and game.local_room==room2 and ui.last_error!="","Wrong password cannot enter or replace the active room")
	prompt.find_widget("PasswordEditBox").text="oda032";prompt.find_widget("OKButton").pressed.emit();await frames();check(ui.page=="room" and game.local_room==room1,"Correct password enters the exact selected room")
	ui.links.ChangeRule.pressed.emit();await frames();ui.room_title.text="İptal Edilen";ui.room_draft.title=ui.room_title.text;ui.links.PLCancel.pressed.emit();await frames();check(game.local_room==room1 and game.local_rooms.by_id(room1.roomId)==room1,"Cancel settings preserves both active and persisted room")
	ui.links.ChangeRule.pressed.emit();await frames();ui.room_title.text="Kaydedilmiş Oda";ui.room_draft.title=ui.room_title.text;ui.links.PLOK.pressed.emit();await frames();check(game.local_room.roomId==room1.roomId and game.local_room.title=="Kaydedilmiş Oda" and game.local_rooms.rooms.size()==2,"Saving settings edits the same directory entry")
	var stable=game.local_room.duplicate(true);game.local_rooms.save_blocked=true;ui.links.ChangeTeam.pressed.emit();await frames();check(game.local_room==stable,"Failed team-change save leaves the real roster untouched");game.local_rooms.save_blocked=false;ui.last_error=""
	ui.links.ChangeTeam.pressed.emit();await frames();check(game.local_room.team!=stable.team and game.local_rooms.by_id(stable.roomId).team==game.local_room.team,"Successful team switch updates the room and directory together")
	for i in range(18):game.local_rooms.commit({"title":"Liste Odası %02d" % i,"mode":1001 if i%2 else 1000,"map":1,"team":"blue"},true)
	ui.navigate("lobby");await frames();helper=ui.detail_helper;check(helper.row_views.size()==16 and helper.list.find_widget("NextPage").visible,"Actual room list paginates at the sixteen source rows")
	helper.list.find_widget("NextPage").pressed.emit();await frames();check(ui.detail_helper.row_views.size()==4 and ui.lobby_page_index==1,"Next page shows the remaining real rooms")
	for dimensions in [Vector2i(1280,720),Vector2i(960,540),Vector2i(800,450)]:
		root.size=dimensions;await frames();ui.navigate("lobby");await frames();var rows=ui.detail_helper.row_views;var expected=rows[0].get_meta("room_id");await touch(rows[0]);check(game.local_rooms.selected_id==expected and ui.page=="lobby","Dense native room rows select the nearest touched row at "+str(dimensions))
	var filter=layout(ui.content,"section/battle").find_widget("PlayModeSelectComboBox");select(filter,1001);await frames();check(ui.lobby_page_index==0 and ui.detail_helper.visible_rooms.all(func(row):return row.mode==1001),"Mode filter resets pagination and binds only matching real rooms")
	game.queue_free();await frames();var report={"checks":checks,"passed":failures.is_empty(),"failures":failures,"physicalAndroidDeviceTested":false,"scope":"Native lobby/create/room flow, fixed PC header, real touch events, source panel bindings, local directory/password persistence and transactional failure paths"};var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-032-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  ")+"\n");f.close();print("MOBILE_032_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
