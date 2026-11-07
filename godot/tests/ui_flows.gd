extends SceneTree
const Layout=preload("res://ui/source_layout.gd")
var checks=0
var failures=0
var game

func _initialize():call_deferred("run")
func ensure(value,description):
	checks+=1
	if not value:failures+=1;push_error("UI_FLOW_FAIL "+description)
	else:print("PASS "+description)
func frames(count=3):
	for _i in range(count):await process_frame
func click(node):
	if not is_instance_valid(node):ensure(false,"expected clickable control exists");return
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	# parse_input_event receives window pixels, including after canvas_items
	# expands the logical viewport for a resized 4:3 window.
	event.position=node.get_viewport().get_final_transform()*node.get_global_rect().get_center();event.pressed=true
	Input.parse_input_event(event);await frames(1);event.pressed=false;Input.parse_input_event(event);await frames()
func native_button(ui,name):
	for view in ui.content.get_children():
		if view is Layout:
			var candidate=view.find_widget(name)
			if candidate is BaseButton:return candidate
	return null

func await_match_start():
	var deadline=Time.get_ticks_msec()+20000
	while game.match_flow.starting() and Time.get_ticks_msec()<deadline:
		game.match_flow.advance_start(1);await frames(1);OS.delay_msec(5)

func run():
	root.size=Vector2i(1280,720)
	game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	var ui=game.pc_panel
	ensure(ui.page=="entry" and "section/title" in ui.source_layouts,"entry uses original title source")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768)]:
		root.size=dimensions;await frames()
		# Godot canvas_items stretching exposes logical viewport coordinates.
		var logical=ui.get_viewport_rect().size
		ensure(is_equal_approx(logical.x/logical.y,float(dimensions.x)/dimensions.y),"logical viewport matches the actual display aspect: "+str(dimensions))
		ensure(ui.canvas.scale.is_equal_approx(logical/Vector2(1024,768)) and ui.canvas.position.is_zero_approx(),"PC reference canvas fills the display on both axes: "+str(dimensions))
	root.size=Vector2i(1280,720);await frames()
	await click(ui.links["Yerel oturuma devam"])
	ensure(ui.page=="servers","title action opens source server screen")
	await click(ui.links["Server"])
	ensure(ui.page=="lobby" and "section/battle" in ui.source_layouts,"local server action reaches native lobby")
	var local_profile=game.profile_name;game.profile_name="QA panel profile";await frames()
	ensure(ui.profile_label.text==game.profile_name,"header name follows live profile changes alongside wallet values")
	game.profile_name=local_profile
	await click(ui.links["CreateBattle"])
	ensure(ui.page=="create_room","original CreateBattle button opens room dialog")
	ui.room_title.text="QA Yerel Oda"
	ui.room_title.grab_focus();ui.room_title.caret_column=5
	root.size=Vector2i(1024,768);await frames()
	ensure(ui.room_title.text=="QA Yerel Oda" and ui.room_title.has_focus() and ui.room_title.caret_column==5,"keyboard/viewport resizing retains the room draft and text caret")
	root.size=Vector2i(1280,720);await frames()
	ensure(ui.room_difficulty.item_count==3,"room exposes easy, normal and hard bot profiles")
	ui.room_difficulty.select(2);ui.room_difficulty.item_selected.emit(2)
	await click(ui.links["PLOK"])
	ensure(ui.page=="room" and game.local_room.title=="QA Yerel Oda" and game.local_room.mode==0,"room dialog retains actual local room values")
	ensure(game.local_room.botDifficulty=="hard","selected bot difficulty is retained by the real room")
	await click(ui.links["ChangeTeam"])
	ensure(game.local_room.team=="red","native change-team button updates local roster")
	await click(ui.links["ChangeRule"]);await click(ui.links["PLOK"])
	ensure(game.local_room.team=="red" and game.local_room.title=="QA Yerel Oda","editing room rules preserves the actual title and selected team")
	await click(ui.links["StartGame"])
	await await_match_start()
	ensure(game.running and not game.menu_open,"training starts through native room action")
	ensure(game.bot_difficulty=="hard","StartGame applies the selected difficulty to this match")
	ensure(game.source_hud.health_view.find_widget("HealthPoint").is_visible_in_tree(),"source health digits remain visible through their background parent")
	ensure(game.message.size.x>=600,"centered round messages retain a readable line width")
	game.spawn_clock=1000;game.pause_game();await frames();ui=game.pc_panel
	ensure(native_button(ui,"GameComeBack")!=null,"pause exposes the original Continue action")
	ensure(not game.menu_backdrop.visible,"pause preserves the rendered game behind its native window")
	await click(ui.links["Option"])
	ensure(ui.page=="Ayarlar" and "interface/soundpropertypage" in ui.source_layouts,"native pause option opens source sound page")
	var original=game.book.settings.duplicate(true)
	var slider=ui.detail_helper.widgets.music_volume
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=slider.get_global_rect().position+Vector2(slider.get_global_rect().size.x*0.25,3);event.pressed=true
	Input.parse_input_event(event);await frames(1);event.pressed=false;Input.parse_input_event(event);await frames()
	ensure(ui.settings_dirty and is_equal_approx(ui.settings_draft.music_volume,0.25) and game.book.settings==original,"native slider edits a draft without mutating live preferences")
	var history=ui.history.duplicate()
	ui.go_back();await frames()
	ensure(ui.page=="Ayarlar" and ui.modal!=null and ui.history==history,"dirty back opens source confirmation without consuming history")
	ui.go_back();await frames()
	ensure(ui.modal==null and ui.history==history and ui.settings_dirty,"closing confirmation keeps the dirty draft and history")
	ui.go_back();await frames()
	var dialog=ui.modal.get_child(1)
	await click(dialog.find_widget("CancelButton"))
	ensure(ui.page=="pause" and game.book.settings==original and ui.history.size()==history.size()-1,"discard returns once and leaves live settings unchanged")
	await click(ui.links["Option"])
	ui.detail_helper.widgets.music_volume.value=37
	ui.detail_helper.widgets.weapons_volume.value=62
	game.book.persistent=true;game.book.save_blocked=true
	await click(ui.detail_helper.native_window.find_widget("Confirm"))
	ensure(ui.page=="Ayarlar" and ui.settings_dirty and game.book.settings==original,"failed settings save keeps page and rolls back every live value")
	game.book.persistent=false;game.book.save_blocked=false
	await click(ui.detail_helper.native_window.find_widget("Confirm"))
	ensure(ui.page=="pause" and is_equal_approx(game.book.settings.music_volume,0.37) and is_equal_approx(game.book.settings.weapons_volume,0.62),"Confirm applies independent source sound controls together")
	game.book.settings.directions=true;game.apply_settings()
	await click(ui.links["Option"])
	await click(ui.detail_helper.native_tabs.find_widget("Control"))
	ensure("interface/controlpropertypage1" in ui.source_layouts,"original control tab opens its own native layout")
	ui.detail_helper.widgets.sensitivity.value=100
	await click(ui.detail_helper.native_page.find_widget("InvertYAxis Enable"))
	await click(ui.links["Joystick"])
	ensure(not ui.settings_draft.directions and game.book.settings.directions and game.touch.direction_buttons,"joystick selection edits only the draft of an existing four-button profile")
	await click(ui.detail_helper.native_window.find_widget("Confirm"))
	ensure(game.book.settings.invert_y and is_equal_approx(game.book.settings.sensitivity,3.0),"source control widgets apply invert-Y and bounded mobile sensitivity")
	ensure(not game.book.settings.directions and not game.touch.direction_buttons,"Confirm switches an existing profile to joystick without clearing its equipment")
	await click(ui.links["GameComeBack"])
	ensure(not game.menu_open and game.pc_panel==null and game.library_panel==null,"Continue removes menu without leaving a blocking layer")
	game.show_library("Envanter");await frames();ui=game.library_panel
	ensure(ui.detail_helper.grid.position==Vector2(366,154) and ui.detail_helper.capacity==9,"inventory preserves source three by three grid geometry")
	ensure(ui.detail_helper.grid.get_child(0).button_pressed,"initial item selection uses the original selected atlas state")
	await click(ui.detail_helper.filter_tabs[3])
	ensure(ui.detail_helper.entries.all(func(entry):return entry.category=="knife") and ui.filter_id=="knife","visible BIÇAK tab actually filters knives")
	await click(ui.detail_helper.filter_tabs[0])
	ensure(ui.detail_helper.entries.size()==4,"TÜMÜ restores the real four-item starter inventory")
	var equipped=game.current_weapon_id;game.ammo=7;game.reserve=19
	ensure(ui.detail_helper.loadout_tabs.size()==5 and ui.detail_helper.loadout_tabs.all(func(node):return node.position.y==123),"five real loadouts use the reference's horizontal tab row")
	ensure(ui.detail_helper.equipped_cards.size()==4 and ui.detail_helper.equipped_cards.all(func(node):return node.position.x==117),"active loadout weapons use the left reference column")
	await click(ui.detail_helper.loadout_tabs[1])
	ensure(game.book.active_loadout==1,"horizontal equipment tab selects the second real loadout")
	if game.current_weapon_id==equipped:ensure(game.ammo==7 and game.reserve==19,"loadout selection cannot refill shared weapon ammunition")
	await click(ui.detail_helper.loadout_cards.secondary_primary)
	ensure(ui.target_primary_slot=="secondary_primary","empty second-main card selects its real target slot")
	ui.selected=game.book.weapon(game.book.slots.primary);ui.detail_helper.show_details()
	await click(ui.links["Tak"])
	ensure(game.book.slots.secondary_primary==game.book.slots.primary,"Kullan equips the selected primary weapon into the chosen second slot")
	ensure(game.ammo==7 and game.reserve==19,"assigning the same weapon to another slot cannot refill ammunition")
	await click(ui.links["Diğer"]);await click(ui.links["Kartlar"])
	ensure(ui.page=="Kartlar" and ui.detail_helper.grid.get_child_count()==8,"source card icon opens the four-column two-row card browser")
	ensure(ui.links["Kartı kullan"].disabled,"previewing source card art never grants ownership or stats")
	ui.detail_helper.search.text="re";ui.detail_helper.search.text_changed.emit("re");ui.detail_helper.search.grab_focus();ui.detail_helper.search.caret_column=1
	var card_choice=ui.selected
	root.size=Vector2i(1024,768);await frames()
	ensure(ui.detail_helper.search.text=="re" and ui.detail_helper.search.has_focus() and ui.detail_helper.search.caret_column==1 and ui.selected==card_choice,"keyboard resizing preserves card search, caret and selection")
	root.size=Vector2i(1280,720);await frames()
	var last_card_page=int((ui.detail_helper.filtered.size()-1)/8)*8;ui.offset=last_card_page;ui.detail_helper.refresh()
	await click(ui.links["Sonraki"])
	ensure(ui.offset==last_card_page,"next on the last card page cannot shift into overlapping partial pages")
	ui.detail_helper.search.text="zz__nonexistent__zz";ui.detail_helper.search.text_changed.emit(ui.detail_helper.search.text);await frames()
	ensure(ui.detail_helper.filtered.is_empty() and ui.selected.is_empty(),"empty card search removes its stale selection")
	ui.navigate("Mağaza");await frames()
	ui.detail_helper.search.text="zz__nonexistent__zz";ui.detail_helper.search.text_changed.emit(ui.detail_helper.search.text);await frames()
	ensure(ui.detail_helper.entries.is_empty() and ui.selected.is_empty(),"search empties cards and selection without stale detail")
	ui.navigate("Karakterler");await frames()
	ui.detail_helper.select_relative(1);await frames()
	ensure(ui.content.find_children("*","SubViewport",true,false).size()==1,"character changes replace the preview viewport")
	ensure((Vector2(ui.preview_view.size)-ui.preview_container.size*ui.canvas.scale*ui.content.scale).abs().x<1.1 and (Vector2(ui.preview_view.size)-ui.preview_container.size*ui.canvas.scale*ui.content.scale).abs().y<1.1,"3D preview compensates independently stretched PC coordinates")
	ensure(ui.detail_helper.grid.get_children().all(func(cell):return cell.get_children().any(func(child):return child is TextureRect and child.texture!=null)),"all visible character cards display their own portrait or model preview")
	ui.detail_helper.search.text="zz__nonexistent__zz";ui.detail_helper.search.text_changed.emit(ui.detail_helper.search.text);await frames()
	ensure(ui.preview_container==null,"empty character search removes the previous model preview")
	await click(ui.links["Diğer"])
	ensure(ui.modal!=null,"extra sections use a source dialog without covering native lobby labels")
	await click(ui.links["Dövmeler"])
	ensure(ui.page=="Dövmeler" and ui.modal==null,"tattoo collection is reachable from the visible navigation")
	var unknown={"id":"unbound-test","name":"Unbound fixture","role":"unknown","texture":"res://assets/items/wolf-dash.png","description":"Test-only unsupported role"};ui.selected=unknown;ui.detail_helper.show_details()
	ensure(ui.links["Bölge belirsiz"].disabled,"unproved tattoo UV roles remain unequippable")
	ui.navigate("power");await frames()
	var icon=ui.detail_helper.grid.get_child(0).get_children().filter(func(node):return node is TextureRect)[0]
	ensure(icon.size.x<=205 and icon.size.y<=72,"large source ability image stays inside its card")
	var body=ui.detail_helper.details.get_children().filter(func(node):return node is RichTextLabel)[0]
	ensure(not body.fit_content and body.scroll_active and body.get_rect().end.y<=738,"long item text scrolls inside the lower details panel")
	ensure(ui.detail_helper.entries.size()==game.power_catalog.items.size()+game.equipment.rules.items.size() and ui.content.find_children("*","BaseButton",true,false).size()>=5,"power page shows five real equipment slots and seven usable item records")
	ui.close_menu();await frames()
	ensure(not game.menu_open and game.library_panel==null,"closing collection resumes without orphaned menu")
	game.show_home();root.size=Vector2i(1024,768);game.show_front_screen("servers");await frames()
	ensure(game.pc_panel.page=="servers" and game.pc_panel.is_inside_tree(),"resize followed by immediate screen replacement cannot rebuild the detached previous menu")
	game.show_home();ui=game.pc_panel;ui.navigate("create_room");await frames()
	ensure(ui.room_map.item_count==35,"offline room offers all 34 real maps plus the training arena")
	for index in range(ui.room_map.item_count):
		if ui.room_map.get_item_id(index)==84:
			ui.room_map.select(index);ui.room_map.item_selected.emit(index)
	await click(ui.links["PLOK"])
	ensure(game.local_room.map==84 and ui.links.has("StartGame") and not ui.links["StartGame"].disabled,"native room retains and enables the selected offline map")
	if not ui.links.has("StartGame"):game.queue_free();await frames();quit(1);return
	await click(ui.links["StartGame"])
	await await_match_start()
	ensure(game.running and game.offline_map_number==84 and is_instance_valid(game.active_map),"native StartGame opens the actual source map with local rules")
	game.spawn_clock=1000;game.end_round("QA tamamlandı");await frames();ui=game.pc_panel
	var results=ui.content.get_children().filter(func(node):return node is Layout)[0]
	ensure(not results.find_widget("RedResult").visible,"unfinished or lost rounds cannot display the source victory badge")
	await click(ui.links["Confirm"]);await frames();ui=game.pc_panel
	ensure(ui.page=="room","source result confirmation returns to its room")
	await click(ui.links["StartGame"])
	await await_match_start()
	ensure(game.running and game.offline_map_number==84 and game.kills==0,"result retry keeps the selected real map")
	game.queue_free();await frames()
	print("UI_FLOWS_QA checks=%d failures=%d" % [checks,failures]);quit(0 if failures==0 else 1)
