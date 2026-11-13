extends SceneTree
const Native=preload("res://ui/source_layout.gd")
var game
var output
var captures=[]
var failures=[]
func _initialize():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func frames(n=6):
	for i in range(n):await process_frame
func layout(parent,id):
	for node in parent.find_children("*","Control",true,false):
		if node is Native and node.layout_id==id:return node
	return null
func select(picker,id):
	for i in range(picker.item_count):
		if picker.get_item_id(i)==id:picker.select(i);picker.item_selected.emit(i);return true
	return false
func capture(name,expected=""):
	if expected!="" and game.pc_panel.page!=expected:failures.append(name+" expected "+expected+" got "+game.pc_panel.page)
	await frames();await RenderingServer.frame_post_draw;var image=root.get_texture().get_image();var path=output.path_join(name+"-032.png");captures.append({"name":name,"path":path,"width":image.get_width(),"height":image.get_height(),"saved":image.save_png(path)==OK})
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	var ui=game.pc_panel;ui.navigate("lobby");await capture("source-lobby-empty")
	ui.navigate("create_room");await capture("source-create-over-lobby");ui.room_title.text="Kurt ve İnsan";ui.room_draft.title=ui.room_title.text;var input=layout(ui.content,"interface/createfield").find_widget("PasswordEditBox");input.text="review32";input.text_changed.emit(input.text);await capture("source-creator-private-password")
	ui.detail_helper.show_options();select(ui.detail_helper.capacity,8);select(ui.detail_helper.allies,3);select(ui.detail_helper.enemies,4);await capture("creator-context-bot-options");ui.detail_helper.options.hide()
	ui.links["Harita görselleri"].pressed.emit();await capture("source-creator-map-gallery");ui.close_modal();ui.detail_helper.apply();var first=game.local_room.duplicate(true);await capture("source-colored-team-room")
	ui.go_back();await capture("source-lobby-selected-native-details")
	ui.navigate("create_room");ui.room_title.text="Yıkım · 9 Kazanma";ui.room_draft.title=ui.room_title.text;select(ui.detail_helper.family,3000);select(ui.detail_helper.goal,9);select(ui.detail_helper.clock,180);await capture("source-destruction-creator");ui.detail_helper.apply();await capture("source-destruction-room-rules");ui.go_back();await capture("source-lobby-two-real-rooms")
	ui.detail_helper.select_room(first.roomId);await capture("source-select-without-entering");ui.detail_helper.join_selected();await capture("source-password-room-entry");var prompt=layout(ui.modal,"interface/passwordmessagebox");prompt.find_widget("PasswordEditBox").text="wrong";prompt.find_widget("OKButton").pressed.emit();await capture("source-wrong-password-keeps-lobby");prompt.find_widget("PasswordEditBox").text="review32";prompt.find_widget("OKButton").pressed.emit();await capture("source-enter-selected-room","room")
	ui.links.ChangeRule.pressed.emit();await capture("source-room-settings");ui.links.PLCancel.pressed.emit();await capture("source-cancel-settings-preserves-room")
	ui.go_back();root.size=Vector2i(960,540);await capture("source-lobby-phone-960");ui.detail_helper.select_room(game.local_room.roomId);ui.detail_helper.join_room(game.local_room.roomId,"review32");await capture("source-room-phone-960","room")
	root.size=Vector2i(2160,992);ui.navigate("create_room");await capture("source-creator-wide-2160");ui.go_back();root.size=Vector2i(1280,720);await frames()
	for i in range(18):game.local_rooms.commit({"title":"Yerel Oda %02d" % i,"mode":1001 if i%2 else 1000,"map":1,"team":"blue"},true)
	ui.navigate("lobby");await capture("source-sixteen-room-page");select(layout(ui.content,"section/battle").find_widget("PlayModeSelectComboBox"),1001);await capture("source-filter-real-room-configurations")
	ui.navigate("Envanter");await capture("source-header-consistent-inventory")
	game.queue_free();await frames();var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"captures":captures,"failures":failures.size(),"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"sourcePageAssertions":true,"scope":"Real native lobby/create/room states. Directory pagination contains configurations explicitly created by the QA fixture, never remote players. All geometry uses source1024x768 coordinates. Password inputs are masked. Full PC parity is not asserted."},"  "));f.close();quit(0 if failures.is_empty() else 1)
