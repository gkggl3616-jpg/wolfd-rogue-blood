extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const VideoLayout=preload("res://scripts/video_layout.gd")
var ui
var view
var selection
var confirm
var ids=[]
var reason="etc"
func build():
	view=ui.native("interface/kickwindow",ui.content,VideoLayout.KICK_WINDOW,Vector2(400,377))
	view.show_only(["BackGround","MyTeam","teamList","KickReasonGroupBox","illegalProgram","Bug","abuse","etc","Confirm","CancelButton","Exit"])
	view.find_widget("MyTeam").texture=Art.texture("wt_interface/gamemenu/playkick/"+str(ui.game.local_room.get("team","blue"))+"_kicktitle.dtx")
	selection=view.find_widget("teamList")
	for row in ui.game.match_roster.values():
		if row.id=="player" or row.team!=ui.game.local_room.get("team","blue") or row.get("removed",false):continue
		ids.append(row.id);selection.add_item(row.name)
	confirm=view.find_widget("Confirm");confirm.disabled=true
	selection.item_selected.connect(func(_index):confirm.disabled=false)
	view.bind_action("Confirm",func():
		var selected=selection.get_selected_items()
		if selected.is_empty():return
		if ui.game.remove_local_bot(ids[selected[0]],reason):ui.navigate("pause",false)
		else:ui.show_error("Seçilen bot artık bu yerel takımda değil.")
	)
	for key in ["CancelButton","Exit"]:view.bind_action(key,func():ui.navigate("pause",false))
	for key in ["Confirm","CancelButton","Exit"]:ui.links[key]=view.find_widget(key)
	var group=ButtonGroup.new()
	for key in ["illegalProgram","Bug","abuse","etc"]:
		var button=view.find_widget(key);button.toggle_mode=true;button.button_group=group;view.bind_action(key,func():reason=key)
	view.find_widget("etc").set_pressed_no_signal(true)
	view.find_widget("Exit").set_meta("close_art_size",Vector2(36,36)) # Hit target stays 48 screen pixels; the source title remains clear.
	confirm.disabled=true
	var hint=ui.text(ui.content,"Seçilen bot bu yerel\nodadan çıkarılır.",VideoLayout.KICK_WINDOW+Vector2(218,216),Vector2(160,48),12);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
