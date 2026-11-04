extends RefCounted
const Art = preload("res://ui/source_theme.gd")
var ui
var grid: Control
var details: Control
var search: LineEdit
var entries = []
var page_label: Label
var capacity = 9
var preview_sprite: TextureRect
var effect_frames = []
var effect_time = 0.0
var effect_fps = 15.0

func normalized(value):return str(value).to_lower().replace("ı","i").replace("İ","i")

func refresh_grid():
	refresh_native_grid()

func show_details():
	show_native_details()

func update(delta):
	if not is_instance_valid(preview_sprite) or effect_frames.is_empty():return
	effect_time+=delta
	var path=effect_frames[int(effect_time*effect_fps)%effect_frames.size()]
	if preview_sprite.get_meta("frame_path","")!=path:preview_sprite.texture=load(path);preview_sprite.set_meta("frame_path",path)

var native_mode=false
var native_slots
var native_tabs

func build_native():
	native_mode=true
	ui.trace("interface/shoppropertypage");ui.trace("interface/itemlistbuttonex")
	var section=ui.native("section/shop" if ui.page=="Mağaza" else "section/inventory",ui.content)
	for node in section.controls:
		node.visible=node.get_meta("source_record").name in ["WeaponState","Inventory"]
	native_tabs=ui.native("interface/shoppropertysheet",ui.content)
	# These legacy source control names no longer match the embedded atlas text:
	# tabs read FIRSAT / GUNLUK / SILAH / GUC+ / KRKTR / EKIPMAN.
	# Never turn the first two service tabs into rifle/pistol filters.
	for name in ["MainWeapon","SubWeapon"]:native_tabs.find_widget(name).tooltip_text="Özgün mağaza hizmeti bağlı değil."
	native_tabs.bind_action("SpecialWeapon",func():
		if ui.page not in ["Mağaza","Envanter"]:ui.navigate("Envanter")
		else:ui.filter_id="all";ui.offset=0;refresh_grid()
	)
	native_tabs.bind_action("Avility",func():ui.navigate("power"));native_tabs.bind_action("ExItem",func():ui.navigate("Karakterler"));native_tabs.bind_action("Best",func():ui.navigate("Envanter"))
	search=LineEdit.new();search.text=ui.search_query;search.position=Vector2(770,75);search.size=Vector2(230,25);search.placeholder_text="Ara…";ui.content.add_child(search)
	search.text_changed.connect(func(value):ui.search_query=value;ui.offset=0;refresh_grid())
	grid=Control.new();grid.position=Vector2(366,154);grid.size=Vector2(630,351);ui.content.add_child(grid);capacity=9
	page_label=ui.text(ui.content,"",Vector2(568,714),Vector2(230,28),14);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(ui.content,"Önceki",Vector2(366,708),Vector2(145,30),func():ui.offset=maxi(0,ui.offset-9);refresh_grid())
	ui.button(ui.content,"Sonraki",Vector2(850,708),Vector2(145,30),func():ui.offset=mini(maxi(0,entries.size()-1),ui.offset+9);refresh_grid())
	details=Control.new();ui.content.add_child(details)
	if ui.page=="Envanter":
		ui.trace("interface/equiplistbox");ui.trace("interface/equipmentbutton")
		native_slots=ui.native("interface/equiplistbox",ui.content,Vector2(14,154))
		for i in range(5):
			var button=native_slots.find_widget("EquipButton",i);button.disabled=false;button.set_pressed_no_signal(ui.game.book.active_loadout==i)
			var content=LayoutForCard(button)
			content.set_value("EquipmentName","EKİPMAN %d" % (i+1))
			for pair in [["MainWeaponName","primary"],["SubWeaponName","pistol"],["CloseWeaponName","knife"],["SpecialWeaponName","grenade"]]:
				content.set_value(pair[0],ui.game.book.weapon(ui.game.book.loadouts[i].get(pair[1],"")).get("name","Boş"),0 if pair[0]=="SpecialWeaponName" else null)
			button.pressed.connect(func():
				if ui.game.book.select_loadout(i):ui.game.equip_slot("primary");ui.refresh()
				else:ui.show_error("Ekipman seti kaydedilemedi.")
			)
	refresh_grid()

func LayoutForCard(parent):
	var Layout=preload("res://ui/source_layout.gd")
	var view=Layout.new();parent.add_child(view);view.configure("interface/equipmentbutton",Vector2(209,115))
	for i in range(view.records.size()):view.controls[i].visible=view.records[i].name in ["EquipmentName","MainWeaponName","SubWeaponName","CloseWeaponName","SpecialWeaponName"]
	return view

func native_rows():
	var rows=[]
	var source=ui.game.book.weapons if ui.page in ["Mağaza","Envanter"] else (ui.game.book.characters if ui.page=="Karakterler" else (ui.game.book.tattoos if ui.page=="Dövmeler" else ui.game.book.effects))
	for row in source:
		if ui.page in ["Mağaza","Envanter"]:
			if row.get("engineImported")!=true or row.get("available")!=true:continue
			if ui.page=="Envanter" and not ui.game.book.owned.get(row.id,false):continue
			if ui.filter_id=="special" and row.category not in ["knife","grenade","rocket","launcher"]:continue
			if ui.filter_id not in ["all","special"] and ui.game.book.slot_for(row.category)!=ui.filter_id:continue
		if ui.page=="Karakterler" and row.get("available")!=true:continue
		var name=row.get("name",str(row.get("source","")).get_file().get_basename())
		if not ui.search_query.is_empty() and not normalized(name+" "+str(row.get("sourceId",""))).contains(normalized(ui.search_query)):continue
		rows.append(row)
	return rows

func refresh_native_grid():
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	entries=native_rows()
	if ui.offset>=entries.size():ui.offset=int((maxi(1,entries.size())-1)/9)*9
	if ui.selected.is_empty() or not entries.has(ui.selected):ui.selected=entries[ui.offset] if not entries.is_empty() else {}
	var group=ButtonGroup.new()
	var Layout=preload("res://ui/source_layout.gd")
	var template=Art.catalog().layouts["interface/equiplistbox"].widgets[1]
	for i in range(mini(9,entries.size()-ui.offset)):
		var entry=entries[ui.offset+i];var factory=Layout.new();var cell=factory.create_widget(template);factory.free()
		cell.position=Vector2(i%3,int(i/3))*Vector2(210,117);cell.size=Vector2(209,115);cell.disabled=false;cell.toggle_mode=true;cell.button_group=group;grid.add_child(cell)
		cell.set_meta("entry",entry);cell.set_pressed_no_signal(entry==ui.selected)
		var icon=entry.get("icon",entry.get("texture",""))
		if icon!="":Art.sprite(cell,icon,Vector2(0,0),Vector2(209,75)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var info=Layout.new();cell.add_child(info);info.configure("interface/itemlistbuttonex",Vector2(210,117));info.set_value("ItemName",entry.get("name",str(entry.get("source","")).get_file().get_basename()))
		cell.pressed.connect(func():ui.selected=entry;show_details())
	page_label.text="%d / %d · %d kayıt" % [int(ui.offset/9)+1,maxi(1,int(ceil(float(entries.size())/9))),entries.size()]
	show_details()

func show_native_details():
	for child in details.get_children():details.remove_child(child);child.queue_free()
	effect_frames=[];preview_sprite=null
	if ui.selected.is_empty():ui.clear_preview();return
	var entry=ui.selected
	if ui.page=="Envanter":
		ui.text(details,entry.name,Vector2(366,550),Vector2(410,30),17)
		ui.button(details,"Tak",Vector2(814,542),Vector2(180,30),func():
			if ui.game.equip_item_from_ui(entry):ui.refresh()
			else:ui.show_error("Ekipman yüklenemedi veya kaydedilemedi.")
		)
	elif ui.page=="Mağaza":
		ui.paragraph(details,entry.name,Vector2(16,118),Vector2(320,48),18)
		Art.sprite(details,entry.icon,Vector2(16,184),Vector2(320,210)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ui.paragraph(details,"Özgün fiyat ve satın alma hizmeti doğrulanmadı. Ücretsiz ekleme, gerçek satın alma olarak gösterilmez.",Vector2(20,445),Vector2(300,120),16)
		ui.button(details,"Tak" if ui.game.book.owned.get(entry.id,false) else "Satın alma bağlı değil",Vector2(30,645),Vector2(290,32),func():
			if ui.game.equip_item_from_ui(entry):ui.refresh()
		,ui.game.book.owned.get(entry.id,false))
	elif ui.page=="Karakterler":
		var raw=ui.native("interface/charequipmentpage",details)
		for i in range(raw.records.size()):raw.controls[i].visible=raw.records[i].name in ["BackGround","TeamButtonGroupBox","Red","Blue","charEQLeftArrow","charEQRightArrow","charEQNameBg","CharEQName"]
		raw.set_value("CharEQName",entry.name)
		# Original red/blue team controls cannot stand in for human/wolf forms.
		for team in ["Red","Blue"]:raw.find_widget(team).tooltip_text="Özgün takım-karakter eşlemesi doğrulanmadı."
		raw.bind_action("charEQLeftArrow",func():select_relative(-1))
		raw.bind_action("charEQRightArrow",func():select_relative(1))
		ui.build_preview(Vector2(14,200),Vector2(326,430),entry)
		ui.button(details,"İnsan / Kurt önizlemesi",Vector2(40,645),Vector2(280,28),func():ui.preview_wolf=not ui.preview_wolf;ui.replace_preview(entry))
		ui.button(details,"Karakteri kullan",Vector2(40,690),Vector2(280,32),func():
			if ui.game.select_library_character(entry):ui.show_error("Karakter seçimi kaydedildi.")
			else:ui.show_error("Karakter kaydedilemedi.")
		)
	elif ui.page=="Dövmeler":
		ui.text(details,entry.name,Vector2(16,120),Vector2(320,40),18)
		Art.sprite(details,entry.texture,Vector2(20,185),Vector2(310,220)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var known=entry.role in ["body","left","right"]
		ui.paragraph(details,"Kaynak bölge: "+str(entry.role)+"\n"+entry.description,Vector2(20,425),Vector2(310,195),15)
		ui.button(details,"Tak" if known else "Bölge belirsiz",Vector2(40,650),Vector2(280,32),func():
			if ui.game.book.set_tattoo(entry.role,entry.texture):ui.game.player.apply_tattoos();ui.show_error("Dövme kaydedildi.")
			else:ui.show_error("Dövme kaydedilemedi.")
		,known)
		ui.button(details,"Dövmeyi çıkar",Vector2(40,694),Vector2(280,32),func():
			if ui.game.book.set_tattoo("body",""):ui.game.player.apply_tattoos();ui.show_error("Dövme çıkarıldı.")
		)
	else:
		preview_sprite=Art.sprite(details,entry.frames[0],Vector2(20,200),Vector2(310,280));preview_sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		effect_frames=entry.frames;effect_fps=float(entry.fps);effect_time=0
		ui.paragraph(details,"Kaynak sprite önizlemesi. Tam efekt grafiği henüz aktarılmadı.",Vector2(20,520),Vector2(310,95),16)

func select_relative(direction):
	if entries.is_empty():return
	var index=posmod(entries.find(ui.selected)+direction,entries.size())
	ui.selected=entries[index];ui.offset=int(index/9)*9;refresh_grid()
