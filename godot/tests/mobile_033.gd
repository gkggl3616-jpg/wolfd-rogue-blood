extends SceneTree
const Native=preload("res://ui/source_layout.gd")
const Info=preload("res://ui/room_info.gd")
var game
var ui
var checks=0
var failures=[]
var captures=[]
var output=""
func _initialize():
	var args=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0];DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func frames(count=5):
	for i in range(count):await process_frame
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func layout(id):
	for node in ui.content.find_children("*","Control",true,false):
		if node is Native and node.layout_id==id:return node
	return null
func capture(name):
	if output=="":return
	await frames();await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image();var path=output.path_join(name+".png");var result=image.save_png(path)
	check(result==OK,"Save actual room capture: "+name);captures.append({"path":path,"width":image.get_width(),"height":image.get_height()})
func run():
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);ui=game.pc_panel
	var maps=game.map_catalog.maps_for_mode(1010,true)
	game.local_room=game.local_rooms.commit({"title":"Kurt Odası","mode":1010,"map":int(maps[0].number),"capacity":6,"allyBots":1,"enemyBots":2,"team":"blue","matchSeconds":600,"pointGoal":100},true)
	ui.navigate("room");await frames();var view=layout("section/field");var display=ui.room_presentation
	check(view.find_widget("PowerMasterRoomTitle").is_visible_in_tree(),"Source manager-room title is visible")
	check(view.find_widget("MaxChars").text=="3 vs 3" and view.find_widget("RoundTime").text=="10 dakika","Selected capacity and time use PC formatting")
	check(view.find_widget("RedTeamType").texture.region==Rect2(0,0,26,26) and Info.values(game,game.local_room).form=="wolf","Comparison room uses its actual selected wolf rule")
	check(ui.links["Bot ve maç ayarları"]==ui.links.ChangeRule,"Room settings use the native action without an extra lower-left button")
	var roster=ui.content.find_child("RoomRosterblue",false,false)
	check(roster.get_child(0).get_meta("room_member").name==game.profile_name and roster.get_child(1).get_meta("room_member").name==game.bot_roster.identity(game,"blue",0).name,"Source rows bind real player and bot identities")
	var initial_count=ui.room_chat_logs[display.room_key].size()
	check(initial_count==4 and display.log_view.get_parsed_text().contains("[Bot]"),"Room event log contains actual configuration and roster events")
	var initial_title=game.local_room.title;ui.refresh();await frames();display=ui.room_presentation
	check(ui.room_chat_logs[display.room_key].size()==initial_count,"Viewport rebuilds do not duplicate room events")
	display.submit("<test> [color=red]yerel[/color]");check(display.log_view.get_parsed_text().contains("[color=red]yerel[/color]"),"Local messages stay literal and cannot inject markup")
	var before=ui.room_chat_logs[display.room_key].size();display.channel_buttons.clan.pressed.emit();display.submit("not sent")
	check(not display.input.editable and display.log_view.get_parsed_text()=="" and ui.room_chat_logs[display.room_key].size()==before,"Clan channel never fabricates service messages or accepts local sends")
	display.channel_buttons.shout.pressed.emit();check(not display.input.editable and display.channel_buttons.shout.button_pressed,"Source shouting tab selects its own real unavailable channel")
	display.channel_buttons.all.pressed.emit();check(display.input.editable and display.log_view.get_parsed_text().contains("<test>"),"All channel restores the local event history")
	ui.room_chat_logs[display.room_key].pop_back();display.render_log()
	await capture("wolf-room-1280")
	ui.links.Diğer.pressed.emit();await frames();check(ui.modal!=null and ui.links.has("Bot ve maç ayarları"),"Header menu still exposes bot settings");ui.close_modal()
	ui.links.ChangeRule.pressed.emit();await frames();view=layout("section/field")
	check(not view.find_widget("WeaponOptionText").is_visible_in_tree() and not view.find_widget("RedTeamType").is_visible_in_tree() and ui.room_presentation.find_child("RoomShowcase0",false,false)==null,"Editable room settings replace their read-only text/icons and hide showcase cards")
	check(ui.detail_helper.variant.clip_text,"Narrow source variant picker clips long Turkish captions")
	await capture("native-room-settings");ui.links.PLCancel.pressed.emit();await frames()
	check(ui.page=="room" and game.local_room.title==initial_title,"Cancel room settings keeps the actual room intact")
	ui.links.RoomShowcase1.pressed.emit();await frames();check(ui.page=="Kutular" and ui.selected.id=="wolf","Showcase action opens the real local box selection")
	await capture("showcase-opens-local-boxes");ui.navigate("room");await frames()
	game.local_room.mode=3001;game.local_room.swapRoles=true;game.local_room=game.local_rooms.commit(game.local_room);ui.refresh();await frames();view=layout("section/field")
	check(view.find_widget("TeamRoleChangeOption").is_visible_in_tree() and view.find_widget("TeamRoleChangeOption").texture.region.position.y==38,"Room role-swap checkbox binds to the source widget and actual rule")
	game.local_room.swapRoles=false;ui.refresh();await frames();view=layout("section/field");check(view.find_widget("TeamRoleChangeOption").texture.region.position.y==0,"Disabled role swap clears its visual check")
	await capture("destruction-room-rule-state")
	game.local_room.mode=1000;game.local_room.capacity=8;game.local_room.allyBots=3;game.local_room.enemyBots=4;game.local_room=game.local_rooms.commit(game.local_room);ui.refresh();await frames();await capture("mixed-room-eight-players")
	for dimensions in [Vector2i(960,540),Vector2i(2160,992),Vector2i(1024,768)]:
		root.size=dimensions;await frames();display=ui.room_presentation
		check(ui.links.Envanter.size==Vector2(32,32) and ui.get_node("ResponsiveHeader").size==Vector2(1024,58),"Toolbar artwork keeps source size: "+str(dimensions))
		var clip=display.get_node("RoomTickerClip");check(clip.clip_contents and clip.position.y==750,"Local green footer remains clipped to source band: "+str(dimensions))
		await capture("room-"+str(dimensions.x)+"x"+str(dimensions.y))
	for i in range(100):display.append("actual local test event "+str(i),Color.WHITE)
	check(ui.room_chat_logs[display.room_key].size()==80,"Session history stays bounded")
	game.local_room={"mode":0,"map":0,"team":"blue"};ui.refresh();await frames();check(ui.room_presentation.log_view.get_parsed_text().contains("Yerel Oda"),"Legacy untitled local rooms render the source room without missing-field errors")
	game.local_room.mode=99999;ui.refresh();await frames();check(ui.links.StartGame.disabled and ui.room_presentation.log_view.get_parsed_text().contains("önizlemesi"),"Unsupported offline modes keep their actual explanation visible beside the preview action")
	var report={"checks":checks,"passed":failures.is_empty(),"failures":failures,"captures":captures,"rendering":RenderingServer.get_current_rendering_method(),"physicalAndroidDeviceTested":false,"scope":"Room style, source geometry, local events/channel isolation, real box navigation, role-rule state and viewport resizing"}
	var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-033-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  ")+"\n");f.close()
	game.queue_free();await frames();print("MOBILE_033_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
