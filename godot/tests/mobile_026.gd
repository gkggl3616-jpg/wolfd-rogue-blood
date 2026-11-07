extends SceneTree
const Native=preload("res://ui/source_layout.gd")
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func layout(parent,id):
	for view in parent.find_children("*","Control",true,false):
		if view is Native and view.layout_id==id:return view
	return null
func select(picker,id):
	for i in range(picker.item_count):
		if picker.get_item_id(i)==id:picker.select(i);picker.item_selected.emit(i);return true
	return false
func members(ui):return ui.content.find_children("*","Control",true,false).filter(func(node):return node.has_meta("room_member"))
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	var ui=game.pc_panel;ui.navigate("entry");await frames()
	var desktop=preload("res://ui/pc_screens.gd").new();desktop.ui=ui;desktop.local_name_window();var dialog=layout(ui.modal,"interface/nicknamemessagebox");var name=dialog.find_widget("NickNameEditBox");var before=game.profile_name
	name.text="x";dialog.find_widget("ConfirmButton").pressed.emit();check(game.profile_name==before and ui.modal!=null,"Invalid entry name keeps the current profile and source dialog")
	game.book.persistent=true;game.book.save_blocked=true;name.text="Kurt 26";dialog.find_widget("ConfirmButton").pressed.emit();check(game.profile_name==before and game.book.local_name==before,"Failed name save rolls back both profile values")
	game.book.persistent=false;game.book.save_blocked=false;dialog.find_widget("ConfirmButton").pressed.emit();await frames();check(game.profile_name=="Kurt 26" and ui.modal==null and ui.last_error=="","Successful entry name save refreshes the launcher and clears stale errors")
	ui.navigate("servers");await frames();var server=layout(ui.content,"section/serverlist");server.find_widget("Server",100).pressed.emit();await frames();check(ui.page=="lobby","Source local server row opens the real local lobby")
	ui.links.QuickStart.pressed.emit();await frames();check(ui.page=="create_room" and game.local_room.is_empty(),"Quick Start without a room opens creation without inventing a room")
	var helper=ui.detail_helper;var creator=layout(ui.content,"interface/createfield")
	check(creator.find_widget("ModeTypeComboBox")==helper.family and creator.find_widget("GameOptionComboBox")==helper.variant,"Source mode and variant fields bind distinct controls")
	check(helper.family.position==Vector2(50,65) and helper.variant.position==Vector2(218,65) and helper.team.position==Vector2(50,102),"Compact source creator preserves all three source field positions")
	check(not helper.options.visible and ui.room_allies.item_count==5 and ui.room_enemies.item_count==5,"Bot options are separate while retaining independent zero-to-four counts")
	check(ui.get_children().filter(func(node):return node is BaseButton and node.has_method("close_control") and node.close_control() and node.is_visible_in_tree()).is_empty(),"Hidden bot options never leak a floating close button onto the creator")
	ui.links["Bot ve maç ayarları"].pressed.emit();check(helper.options.visible,"Explicit bot settings action opens its optional window")
	await frames();check(helper.options.find_children("*","TextureButton",true,false).any(func(node):return node.has_method("close_control") and node.close_control()),"Raised close control stays owned by its optional window")
	select(helper.capacity,2);check(ui.room_allies.item_count==1 and ui.room_enemies.item_count==2 and int(ui.room_draft.allyBots)==0,"Two-player capacity clamps friendly and enemy bot choices")
	select(helper.capacity,16);ui.room_allies.select(3);ui.room_allies.item_selected.emit(3);ui.room_enemies.select(4);ui.room_enemies.item_selected.emit(4)
	ui.go_back();check(ui.page=="create_room" and not helper.options.visible and ui.room_draft.allyBots==3,"Back closes bot options while preserving creation draft")
	check(select(helper.family,1000),"Original deathmatch family is available")
	check(helper.variant.item_count>=2,"Mode family exposes its actual source variants")
	helper.variant.select(helper.variant.item_count-1);helper.variant.item_selected.emit(helper.variant.selected);check(int(ui.room_draft.mode)==helper.variant.get_selected_id(),"Variant changes the actual room mode")
	select(helper.family,0);check(ui.room_map.item_count==35,"Training creator retains all 34 admitted maps plus the arena")
	check(select(ui.room_map,84) and creator.find_widget("SelectMap").texture!=null,"Chosen source map updates the original preview widget")
	ui.room_title.text="Video odası 26";ui.room_title.text_changed.emit(ui.room_title.text);root.size=Vector2i(2160,992);await frames();check(ui.room_title.text=="Video odası 26" and int(ui.room_draft.map)==84 and int(ui.room_draft.allyBots)==3,"Resizing preserves Unicode title, chosen map and bot draft")
	root.size=Vector2i(1280,720);await frames();ui.links.PLOK.pressed.emit();await frames();check(ui.page=="room" and game.local_room.title=="Video odası 26" and game.local_room.capacity==16,"Create commits the complete validated draft to its room")
	var planned=members(ui);check(planned.size()==8 and planned.filter(func(node):return node.get_meta("room_member").owner).size()==1,"Source roster cards contain exactly one owner and the seven planned bots")
	check(planned.filter(func(node):return node.get_meta("room_member").bot).all(func(node):return node.get_meta("room_member").name.begins_with("BOT")),"Bots cannot masquerade as remote accounts or invented ranks")
	ui.links.ChangeTeam.pressed.emit();await frames();var owner=members(ui).filter(func(node):return node.get_meta("room_member").owner)[0];check(game.local_room.team=="red" and owner.get_parent().get_parent().name=="RoomRosterred","Changing team relocates the real owner card")
	owner.pressed.emit();await frames();check(ui.page=="profile","Owner's native roster card opens the actual local player information")
	ui.go_back();await frames();check(ui.page=="room","Back from player information returns to the same room")
	var committed=game.local_room.duplicate(true);ui.links.ChangeRule.pressed.emit();await frames();helper=ui.detail_helper;helper.show_maps();await frames();check(ui.modal!=null and ui.page=="room_settings","Room settings map gallery opens against its own map picker")
	var cards=ui.modal.find_children("*","BaseButton",true,false).filter(func(node):return node.has_meta("map_number"));check(not cards.is_empty(),"Room settings gallery contains source map cards")
	if not cards.is_empty():
		var number=cards[0].get_meta("map_number");cards[0].pressed.emit();await frames();check(int(ui.room_draft.map)==int(number) and game.local_room==committed,"Gallery selection edits only the room draft before confirmation")
	ui.links.PLCancel.pressed.emit();await frames();check(ui.page=="room" and game.local_room==committed,"Cancel settings restores the committed room without applying its draft")
	ui.go_back();await frames();check(ui.page=="lobby" and game.local_room==committed,"Back from a created room returns to lobby rather than reopening creation")
	var field=layout(ui.content,"interface/fieldbutton");check(field!=null and field.find_widget("CurChars").text=="8" and field.find_widget("MaxChars").text=="/ 16","Lobby source columns show real planned occupancy and capacity")
	var lobby=layout(ui.content,"section/battle");var filter=lobby.find_widget("PlayModeSelectComboBox");select(filter,1000);await frames();check(layout(ui.content,"interface/fieldbutton")==null,"Lobby mode filter hides a nonmatching local room")
	filter=layout(ui.content,"section/battle").find_widget("PlayModeSelectComboBox");select(filter,99999);await frames();check(layout(ui.content,"interface/fieldbutton")!=null,"All modes restores the existing room row")
	var row=layout(ui.content,"interface/fieldlistscreen").find_widget("FieldListButton",0);row.pressed.emit();await frames();check(ui.page=="room" and game.local_room==committed,"Native lobby row joins the same configured room")
	var audio=game.game_audio;audio.event_history.clear();ui.links.StartGame.pressed.emit();check(game.match_flow.starting(),"Room start triggers the real countdown")
	check(audio.event_history.size()==1 and audio.event_history[0].key.ends_with("count_3.wav"),"Countdown starts with the original three voice once")
	ui.refresh();await frames();check(audio.event_history.size()==1,"Rebuilding the room cannot replay countdown audio")
	game.application_suspended=true;var clock_before=game.match_flow.countdown;game.match_flow.advance_start(1);check(game.match_flow.countdown==clock_before and audio.event_history.size()==1,"Suspending the application freezes countdown and its voice steps")
	game.application_suspended=false
	for i in range(3):game.match_flow.advance_start(1)
	check(audio.event_history.map(func(event):return event.key.get_file())==["count_3.wav","count_2.wav","count_1.wav","count_0.wav"],"Actual countdown transitions play three, two, one and GO exactly once")
	ui.go_back();check(not game.match_flow.starting() and game.local_room==committed,"Back cancels countdown while preserving committed settings")
	game.test_mode=false;check(audio.room_countdown(0),"Original GO stream can create an actual audio player")
	var go_voice=audio.active_voices[-1];audio.clear_match_voices();check(is_instance_valid(go_voice) and not go_voice.is_queued_for_deletion(),"Fast round setup preserves the ending of the original GO voice")
	audio.stop_room_countdown();check(go_voice.is_queued_for_deletion(),"Cancelling countdown stops its actual audio player")
	game.test_mode=true
	game.local_room={"mode":0,"map":72};check(game.start_round(),"Ruins starts for the isolated-spawn regression")
	game.set_process(false);game.player.set_physics_process(false);await physics_frame;await physics_frame;await process_frame
	var ruin_spawns=game.offline_spawn_points("red")
	var trapped=Vector3(-33.79163,5.056424,-30.38234)
	check(ruin_spawns.size()>90 and ruin_spawns.all(func(point):return point.distance_to(trapped)>.5),"Ruins retains its source team spawns while rejecting the reproduced half-metre navigation island")
	game.running=false
	game.queue_free();await frames();var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-026-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));file.close();print("MOBILE_026_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
