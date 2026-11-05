extends RefCounted
const Art = preload("res://ui/source_theme.gd")
const Layout = preload("res://ui/source_layout.gd")
const SourceCard=preload("res://ui/source_item_card.gd")
const ROOT = "wt_interface/inven_shop/"
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
var native_mode = true
var loadout_tabs = []
var equipped_cards = []
var loadout_cards = {}
var category_tabs = []
var filter_tabs = []
var info_tab = "description"
var portraits = {}
var role_picker

func normalized(value):return str(value).to_lower().replace("ı","i").replace("İ","i")
func title(entry):return entry.get("name",str(entry.get("source","")).get_file().get_basename())
func refresh_grid():refresh_native_grid()
func show_details():show_native_details()
func update(delta):
	if not is_instance_valid(preview_sprite) or effect_frames.is_empty():return
	effect_time+=delta
	var path=effect_frames[int(effect_time*effect_fps)%effect_frames.size()]
	if preview_sprite.get_meta("frame_path","")!=path:preview_sprite.texture=load(path);preview_sprite.set_meta("frame_path",path)

func tab(source,region,at,dimensions,selected,callback):
	var regions=[region,Rect2(region.position+Vector2(0,27),region.size),Rect2(region.position+Vector2(0,54),region.size)]
	var node=Art.atlas_button(ui.content,source,regions,at,dimensions,callback)
	node.toggle_mode=true;node.set_pressed_no_signal(selected)
	return node

func plate(parent,at,dimensions):
	var panel=Panel.new();panel.position=at;panel.size=dimensions;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new();style.bg_color=Color(0.025,0.045,0.05,0.86);style.border_color=Color("505b5e");style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel);return panel

func build_native():
	portraits=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/character-portraits.json")).portraits
	ui.trace("interface/shoppropertypage");ui.trace("interface/itemlistbuttonex")
	var section=ui.native("section/shop" if ui.page=="Mağaza" else "section/inventory",ui.content)
	for node in section.controls:node.visible=node.get_meta("source_record").name in ["WeaponState","Inventory"]
	build_categories()
	if ui.page=="Dövmeler":
		role_picker=ui.map_picker(ui.content,Vector2(788,122),Vector2(208,27))
		for row in [["Tüm bölgeler","all"],["Sırt / Gövde","body"],["Sol kol","left"],["Sağ kol","right"]]:
			role_picker.add_item(row[0]);role_picker.set_item_metadata(role_picker.item_count-1,row[1])
			if ui.filter_id==row[1]:role_picker.select(role_picker.item_count-1)
		role_picker.item_selected.connect(func(index):ui.filter_id=role_picker.get_item_metadata(index);ui.offset=0;refresh_grid())
	search=LineEdit.new();search.text=ui.search_query;search.position=Vector2(779,63);search.size=Vector2(217,22);search.placeholder_text="Ara…";ui.content.add_child(search)
	search.set_meta("navigation_input","collection_search")
	search.text_changed.connect(func(value):ui.search_query=value;ui.offset=0;refresh_grid())
	grid=Control.new();grid.position=Vector2(366,154);grid.size=Vector2(630,351);ui.content.add_child(grid)
	page_label=ui.text(ui.content,"",Vector2(788,509),Vector2(208,20),11);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	ui.button(ui.content,"▲",Vector2(999,154),Vector2(20,24),func():ui.offset=maxi(0,ui.offset-9);refresh_grid())
	ui.button(ui.content,"▼",Vector2(999,480),Vector2(20,24),func():ui.offset=mini(int((maxi(1,entries.size())-1)/9)*9,ui.offset+9);refresh_grid())
	details=Control.new();details.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(details)
	if ui.page=="Envanter":build_loadouts()
	refresh_grid()

func build_categories():
	ui.trace("interface/equipmentpropertysheet")
	# Inventory tabs have their own atlas and two distinct rows. The shop's
	# FIRSAT/GÜNLÜK tabs do not belong over the inventory title.
	var categories=[["Envanter",Rect2(0,0,65,25)],["power",Rect2(67,0,65,25)],["Karakterler",Rect2(134,0,65,25)],["equipment",Rect2(0,112,65,25)],["Efektler",Rect2(67,112,65,25)]]
	for i in range(categories.size()):
		var entry=categories[i];var selected=ui.page==entry[0] or (entry[0]=="power" and ui.page=="Dövmeler") or (entry[0]=="Envanter" and ui.page=="Mağaza")
		var node=tab(ROOT+"shop_iv_tab_02_01.dtx",entry[1],Vector2(366+i*82,90),Vector2(80,25),selected,func():
			if entry[0]=="equipment":ui.navigate("Kutular")
			elif entry[0]==ui.page:ui.refresh()
			else:ui.navigate(entry[0])
		)
		node.tooltip_text=["Silah","Güç / Dövme","Karakter","Ekipman","Özel efektler"][i]
		category_tabs.append(node)
	var rows=[]
	var source=ROOT+"is_store_list_tab_02.dtx"
	if ui.page in ["Envanter","Mağaza"]:
		rows=[["all",Rect2(0,0,84,27)],["primary",Rect2(84,0,84,27)],["pistol",Rect2(168,0,84,27)],["knife",Rect2(0,122,84,27)],["grenade",Rect2(84,122,84,27)]]
	elif ui.page in ["power","Dövmeler"]:
		source=ROOT+"is_store_list_tab_02_01.dtx"
		rows=[["power",Rect2(0,0,84,27)],["bag",Rect2(84,0,84,27)],["Dövmeler",Rect2(168,0,84,27)],["claw",Rect2(0,122,84,27)],["other",Rect2(84,122,84,27)]]
	elif ui.page=="Karakterler":
		source=ROOT+"is_store_list_tab_02_02.dtx";rows=[["all",Rect2(0,0,84,27)],["red",Rect2(84,0,84,27)],["blue",Rect2(168,0,84,27)],["common",Rect2(0,122,84,27)]]
	for i in range(rows.size()):
		var entry=rows[i];var selected=ui.filter_id==entry[0] or ui.page==entry[0]
		var r=entry[1]
		var node=Art.atlas_button(ui.content,source,[r,Rect2(r.position+Vector2(0,27),r.size),Rect2(r.position+Vector2(0,54),r.size)],Vector2(366+i*84,122),Vector2(84,27),func():
			if ui.page in ["Envanter","Mağaza"]:ui.filter_id=entry[0];ui.offset=0;ui.refresh()
			elif entry[0] in ["power","Dövmeler"]:ui.navigate(entry[0])
			elif entry[0]=="all":ui.filter_id="all";refresh_grid()
			else:ui.show_error("Bu alt kategori için doğrulanmış kullanılabilir kayıt yok.")
		)
		node.toggle_mode=true;node.set_pressed_no_signal(selected)
		filter_tabs.append(node)

func card(parent,entry,at,selected=false):
	var template=Art.catalog().layouts["interface/equiplistbox"].widgets[1]
	var factory=Layout.new();var cell=factory.create_widget(template);factory.free()
	cell.position=at;cell.size=Vector2(209,115);cell.disabled=false;cell.toggle_mode=true;parent.add_child(cell);cell.set_pressed_no_signal(selected);cell.set_meta("entry",entry)
	var icon=entry.get("icon",entry.get("texture",""))
	if ui.page=="Karakterler":icon=portraits.get(entry.id,{}).get("asset","")
	if icon!="":
		var region=Rect2(0,0,210,75) if ui.page in ["Envanter","Mağaza"] or (ui.page=="Karakterler" and portraits.get(entry.id,{}).get("kind")=="source_icon") else Rect2()
		Art.sprite(cell,icon,Vector2(2,2),Vector2(205,72),region).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.text(cell,title(entry),Vector2(4,76),Vector2(201,16),12)
	return cell

func build_loadouts():
	loadout_tabs.clear();equipped_cards.clear()
	for i in range(5):
		var node=tab(ROOT+"shop_iv_tab_02.dtx",Rect2(0,0,82,27),Vector2(8+i*68,123),Vector2(67,27),ui.game.book.active_loadout==i,func():
			if ui.game.book.select_loadout(i):ui.game.equip_slot("primary");ui.refresh()
			else:ui.show_error("Ekipman seti kaydedilemedi.")
		)
		var caption=ui.text(node,"SET %d" % (i+1),Vector2(2,3),Vector2(63,20),11);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		node.tooltip_text="Ekipman seti %d" % (i+1);loadout_tabs.append(node)
	var slots=[["primary","BİRİNCİ"],["secondary_primary","YEDEK"],["pistol","İKİNCİ"],["knife","BIÇAK"],["grenade","BOMBA"]]
	for i in range(slots.size()):
		var slot=slots[i];var at=Vector2(117,154+i*117)
		ui.text(ui.content,slot[1],Vector2(8,at.y+13),Vector2(102,18),11,Color("94a2a6"))
		var entry=ui.game.book.weapon(ui.game.book.slots.get(slot[0],""))
		if entry.is_empty():
			if slot[0]=="secondary_primary":
				var empty=card(ui.content,{"name":"Boş yedek ana silah","icon":""},at,ui.target_primary_slot==slot[0]);loadout_cards[slot[0]]=empty
				empty.pressed.connect(func():choose_primary_slot("secondary_primary"))
			continue
		var cell=card(ui.content,entry,at);equipped_cards.append(cell)
		loadout_cards[slot[0]]=cell
		if slot[0] in ["primary","secondary_primary"]:cell.set_pressed_no_signal(ui.target_primary_slot==slot[0])
		ui.text(cell,"Kullanılıyor",Vector2(4,94),Vector2(201,16),11,Color("c4cccf"))
		cell.pressed.connect(func():
			ui.selected=entry
			if slot[0] in ["primary","secondary_primary"]:choose_primary_slot(slot[0])
			else:show_details()
		)

func choose_primary_slot(slot):
	ui.target_primary_slot=slot
	for key in ["primary","secondary_primary"]:
		if loadout_cards.has(key):loadout_cards[key].set_pressed_no_signal(key==slot)
	show_details()

func native_rows():
	var rows=[]
	var source=ui.game.book.weapons if ui.page in ["Mağaza","Envanter"] else (ui.game.book.characters if ui.page=="Karakterler" else (ui.game.book.tattoos if ui.page=="Dövmeler" else (ui.game.equipment.rules.items if ui.page=="power" else ui.game.book.effects)))
	for row in source:
		if ui.page=="Dövmeler" and ui.filter_id!="all" and row.role!=ui.filter_id:continue
		if ui.page in ["Mağaza","Envanter"]:
			if row.get("engineImported")!=true or row.get("available")!=true:continue
			if ui.page=="Envanter" and not ui.game.book.owned.get(row.id,false):continue
			if ui.filter_id=="special" and row.category not in ["knife","grenade","rocket","launcher"]:continue
			if ui.filter_id not in ["all","special"] and ui.game.book.slot_for(row.category)!=ui.filter_id:continue
		if ui.page=="Karakterler" and row.get("available")!=true:continue
		if not ui.search_query.is_empty() and not normalized(title(row)+" "+str(row.get("sourceId",""))).contains(normalized(ui.search_query)):continue
		rows.append(row)
	return rows

func refresh_native_grid():
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	entries=native_rows()
	ui.offset=clampi(int(ui.offset/9)*9,0,int((maxi(1,entries.size())-1)/9)*9)
	if ui.selected.is_empty() or not entries.has(ui.selected):ui.selected=entries[ui.offset] if not entries.is_empty() else {}
	var group=ButtonGroup.new()
	for i in range(mini(9,entries.size()-ui.offset)):
		var entry=entries[ui.offset+i];var cell=card(grid,entry,Vector2(i%3,int(i/3))*Vector2(210,117),entry==ui.selected)
		cell.button_group=group
		if ui.page in ["Envanter","Mağaza"] and entry.id in ui.game.book.slots.values():ui.text(cell,"Kullanılıyor",Vector2(4,94),Vector2(201,16),11,Color("c4cccf"))
		cell.pressed.connect(func():ui.selected=entry;show_details())
	page_label.text="%d / %d  ·  %d eşya" % [int(ui.offset/9)+1,maxi(1,int(ceil(float(entries.size())/9))),entries.size()]
	show_details()

func action_use(entry,at=Vector2(366,710),dimensions=Vector2(290,28)):
	var enabled=true
	if ui.page=="Mağaza":enabled=ui.game.book.owned.get(entry.id,false)
	var button=Art.atlas_button(details,ROOT+"is_inven_button_use.dtx",[Rect2(0,0,241,28),Rect2(0,28,241,28),Rect2(0,56,241,28),Rect2(0,112,241,28)],at,dimensions,func():
		var slot=ui.target_primary_slot if ui.game.book.slot_for(entry.category)=="primary" else ""
		if ui.game.equip_item_from_ui(entry,slot):ui.refresh()
		else:ui.show_error("Ekipman yüklenemedi veya kaydedilemedi.")
	)
	button.disabled=not enabled;button.tooltip_text=("Yedek ana silah yuvasına tak" if ui.target_primary_slot=="secondary_primary" and ui.game.book.slot_for(entry.category)=="primary" else "Kullan") if enabled else "Satın alma hizmeti bağlı değil";ui.links["Tak"]=button

func show_native_details():
	for child in details.get_children():details.remove_child(child);child.queue_free()
	effect_frames=[];preview_sprite=null
	ui.clear_preview()
	if ui.selected.is_empty():return
	var entry=ui.selected
	plate(details,Vector2(366,540),Vector2(290,164));plate(details,Vector2(664,564),Vector2(348,174))
	ui.text(details,title(entry),Vector2(372,544),Vector2(278,22),12)
	var icon=entry.get("icon",entry.get("texture",""))
	if icon!="":Art.sprite(details,icon,Vector2(376,571),Vector2(270,121),Rect2(0,0,210,75) if ui.page in ["Envanter","Mağaza"] else Rect2()).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.trace("interface/iteminfopropertysheet")
	# This supplied Turkish atlas has 27px normal/hover/selected rows. The old
	# attribute file still describes 25px rows and cuts the selected caption.
	for i in range(2):
		var value="description" if i==0 else "properties"
		var node=Art.atlas_button(details,ROOT+"is_store_weponinfo_tab.dtx",[Rect2(i*84,0,84,27),Rect2(i*84,27,84,27),Rect2(i*84,54,84,27)],Vector2(664+i*84,540),Vector2(84,27),func():info_tab=value;show_details())
		node.toggle_mode=true;node.set_pressed_no_signal(info_tab==value)
	if ui.page in ["Envanter","Mağaza"]:
		var copy=entry.get("description","")
		if info_tab=="properties":
			var tuning=entry.gameplayTuning
			copy="YEREL OYUN\nHasar: %d\nŞarjör: %d\nAtış aralığı: %.3f sn\nŞarjör değiştirme: %.2f sn" % [int(tuning.damage),int(tuning.capacity),float(tuning.fireInterval),float(tuning.reloadSeconds)]
			if entry.has("sourceDetails"):
				var original=entry.sourceDetails
				copy+="\n\nPC EŞYA BİLGİSİ\nMod: %s\nAğırlık: %s\nMühimmat: %s" % [original.modeText,original.weightText,original.magazineText]
		if copy=="":copy="Açıklama bulunmuyor."
		body(copy)
		action_use(entry)
		if ui.page=="Mağaza":
			ui.paragraph(details,title(entry),Vector2(16,119),Vector2(320,35),14)
			Art.sprite(details,entry.icon,Vector2(16,175),Vector2(320,230)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ui.paragraph(details,"Çevrimdışı koleksiyon · Bu cihazda kullanılabilir." if ui.game.book.offline_edition else "Satın alma hizmeti bağlı değil.",Vector2(18,433),Vector2(310,45),12)
	elif ui.page=="Karakterler":build_character(entry)
	elif ui.page=="Dövmeler":build_tattoo(entry)
	elif ui.page=="power":build_power(entry)
	else:
		preview_sprite=Art.sprite(details,entry.frames[0],Vector2(20,190),Vector2(310,280));preview_sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		effect_frames=entry.frames;effect_fps=float(entry.fps);effect_time=0
		ui.paragraph(details,"Efekt önizlemesi.",Vector2(674,577),Vector2(328,100),12)

func build_character(entry):
	var raw=ui.native("interface/charequipmentpage",details)
	raw.show_only(["BackGround","TeamButtonGroupBox","Red","Blue","charEQLeftArrow","charEQRightArrow","charEQNameBg","CharEQName"])
	raw.set_value("CharEQName",entry.name)
	for team in ["Red","Blue"]:raw.find_widget(team).tooltip_text="Bu görünümde takım seçimi kullanılamıyor."
	raw.bind_action("charEQLeftArrow",func():select_relative(-1));raw.bind_action("charEQRightArrow",func():select_relative(1))
	ui.build_preview(Vector2(14,200),Vector2(326,430),entry)
	ui.button(details,"İnsan / Kurt",Vector2(40,645),Vector2(280,28),func():ui.preview_wolf=not ui.preview_wolf;ui.replace_preview(entry))
	ui.button(details,"Karakteri kullan",Vector2(40,690),Vector2(280,28),func():
		if ui.game.select_library_character(entry):ui.show_error("Karakter seçimi kaydedildi.")
		else:ui.show_error("Karakter kaydedilemedi.")
	)
	ui.paragraph(details,"Karakter önizlemesi\n\nÖzellik bilgisi kullanılamıyor.",Vector2(674,577),Vector2(328,130),12)

func build_tattoo(entry):
	var known=entry.role in ["body","left","right"]
	ui.preview_wolf=true;ui.build_preview(Vector2(14,154),Vector2(326,405),ui.game.character_info)
	var shown=ui.game.book.selected_tattoos.duplicate()
	if known:shown[entry.role]=entry.texture
	for mesh in ui.preview_model.find_children("*","MeshInstance3D",true,false):
		var name=str(mesh.name).to_lower()
		if not name.begins_with("tattoo"):continue
		var role="body" if "body" in name else ("left" if name.ends_with("_l") else "right")
		if not shown.has(role) or not ui.game.book.tattoo_matches_role(role,shown[role]):mesh.hide();continue
		var material=StandardMaterial3D.new();material.albedo_texture=load(shown[role]);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=0.7
		mesh.material_override=material;mesh.show()
	body("Bölge: "+{"body":"Gövde","left":"Sol kol","right":"Sağ kol"}.get(entry.role,"Belirsiz")+"\n"+entry.description+"\n\nBu yerel sürümde dövme görünümü uygulanır; PC istatistik bonusu doğrulanmadı.")
	ui.text(details,"Önizlemeyi sürükleyerek çevir",Vector2(25,561),Vector2(310,24),12)
	for i in range(3):
		var role=["body","left","right"][i];var at=Vector2(18+i*106,593);var texture=ui.game.book.selected_tattoos.get(role,"")
		var button=SourceCard.create(details,at,Vector2(100,72),func():
			if texture=="":return
			for row in ui.game.book.tattoos:
				if row.texture==texture:ui.selected=row;show_details();break
		)
		if texture!="":Art.sprite(button,texture,Vector2(3,3),Vector2(94,48)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ui.text(button,["Sırt","Sol kol","Sağ kol"][i],Vector2(3,50),Vector2(94,20),12).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(details,"Tak" if known else "Bölge belirsiz",Vector2(366,710),Vector2(290,28),func():
		if ui.game.book.set_tattoo(entry.role,entry.texture):ui.game.player.apply_tattoos();ui.show_error("Dövme kaydedildi.")
		else:ui.show_error("Dövme kaydedilemedi.")
	,known)
	ui.button(details,"Dövmeyi çıkar",Vector2(40,694),Vector2(280,28),func():
		if ui.game.book.set_tattoo(entry.role,""):ui.game.player.apply_tattoos();ui.show_error("Dövme çıkarıldı.");ui.refresh()
		else:ui.show_error("Dövme çıkarılamadı.")
	,known)

func build_power(entry):
	body(entry.description)
	ui.trace("interface/abilityequipmentpage")
	ui.preview_wolf=true;ui.build_preview(Vector2(14,154),Vector2(326,490),ui.game.character_info)
	var equipped=ui.game.equipment.has_wolf_ability()
	ui.button(details,"Güç slotuna tak" if not equipped else "Takılı · Çıkar",Vector2(366,710),Vector2(290,28),func():
		if not ui.game.equipment.equip_power(0 if equipped else 19601):ui.show_error("Güç slotu kaydedilemedi.");return
		ui.game.player.reset_locomotion();ui.refresh()
	)
	ui.paragraph(details,"Koşarken zıpla, GÜÇLÜ düğmesine bas.",Vector2(20,654),Vector2(310,38),12)

func select_relative(direction):
	if entries.is_empty():return
	var index=posmod(entries.find(ui.selected)+direction,entries.size())
	ui.selected=entries[index];ui.offset=int(index/9)*9;refresh_grid()

func body(copy):
	var node=RichTextLabel.new();node.text=copy;node.position=Vector2(674,577);node.size=Vector2(328,149);node.fit_content=false;node.scroll_active=true
	node.add_theme_font_override("normal_font",Art.font());node.add_theme_font_size_override("normal_font_size",12);details.add_child(node)
