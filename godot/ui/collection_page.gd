extends RefCounted
const Art = preload("res://ui/source_theme.gd")
const Layout = preload("res://ui/source_layout.gd")
const SourceCard=preload("res://ui/source_item_card.gd")
const Quality=preload("res://scripts/item_quality.gd")
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
var swipe
var role_picker

func normalized(value):return str(value).to_lower().replace("ı","i").replace("İ","i")
func title(entry):return entry.get("name",str(entry.get("source","")).get_file().get_basename())
func refresh_grid(scrolling=false):refresh_native_grid(scrolling)
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
	var heading=ColorRect.new();heading.position=Vector2(354,61);heading.size=Vector2(419,27);heading.color=Color.BLACK;heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(heading)
	ui.text(ui.content,"DÜKKAN" if ui.collection_shop else "ENVANTER",Vector2(366,62),Vector2(180,25),18)
	ui.button(ui.content,"ENVANTERE GEÇ" if ui.collection_shop else "MAĞAZAYA GEÇ",Vector2(548,62),Vector2(220,25),switch_collection_mode)
	build_categories()
	if ui.page=="Dövmeler":
		role_picker=ui.map_picker(ui.content,Vector2(788,122),Vector2(208,27))
		for row in [["Tüm bölgeler","all"],["Sırt / Gövde","body"],["Sol kol","left"],["Sağ kol","right"]]:
			role_picker.add_item(row[0]);role_picker.set_item_metadata(role_picker.item_count-1,row[1])
			if ui.filter_id==row[1]:role_picker.select(role_picker.item_count-1)
		role_picker.item_selected.connect(func(index):ui.filter_id=role_picker.get_item_metadata(index);ui.offset=0;refresh_grid())
	var quality=ui.map_picker(ui.content,Vector2(779,90),Vector2(217,25));quality.add_item("Kalite · Tümü");quality.set_item_metadata(0,"all")
	for value in Quality.COLORS:
		quality.add_item(value);quality.set_item_metadata(quality.item_count-1,value)
		if ui.quality_id==value:quality.select(quality.item_count-1)
	quality.item_selected.connect(func(index):ui.quality_id=quality.get_item_metadata(index);ui.offset=0;refresh_grid())
	search=LineEdit.new();search.text=ui.search_query;search.position=Vector2(779,63);search.size=Vector2(217,22);search.placeholder_text="Ara…";ui.content.add_child(search)
	search.set_meta("navigation_input","collection_search")
	search.text_changed.connect(func(value):ui.search_query=value;ui.offset=0;refresh_grid())
	grid=Control.new();grid.position=Vector2(366,154);grid.size=Vector2(630,351);grid.clip_contents=true;ui.content.add_child(grid)
	page_label=ui.text(ui.content,"",Vector2(788,509),Vector2(208,20),11);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	ui.button(ui.content,"▲",Vector2(999,154),Vector2(20,24),func():ui.offset=maxi(0,ui.offset-9);refresh_grid())
	ui.button(ui.content,"▼",Vector2(999,480),Vector2(20,24),func():ui.offset=mini(int((maxi(1,entries.size())-1)/9)*9,ui.offset+9);refresh_grid())
	swipe=load("res://ui/swipe_grid.gd").new();swipe.page=self;swipe.position=grid.position;swipe.size=grid.size;ui.content.add_child(swipe)
	details=Control.new();details.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(details)
	if ui.page=="Envanter":build_loadouts()
	if ui.page=="power" and not ui.collection_shop:build_power_slots()
	refresh_grid()

func build_categories():
	ui.trace("interface/equipmentpropertysheet")
	# Inventory tabs have their own atlas and two distinct rows. The shop's
	# FIRSAT/GÜNLÜK tabs do not belong over the inventory title.
	var categories=[["Envanter",Rect2(0,0,65,25)],["power",Rect2(67,0,65,25)],["Karakterler",Rect2(134,0,65,25)],["equipment",Rect2(0,112,65,25)],["Efektler",Rect2(67,112,65,25)]]
	if ui.collection_shop:categories.append(["Setler",Rect2(67,112,65,25)])
	for i in range(categories.size()):
		var entry=categories[i];var selected=ui.page==entry[0] or (entry[0]=="power" and ui.page=="Dövmeler") or (entry[0]=="Envanter" and ui.page=="Mağaza")
		var node=tab(ROOT+"shop_iv_tab_02_01.dtx",entry[1],Vector2(366+i*(68 if ui.collection_shop else 82),90),Vector2(66 if ui.collection_shop else 80,25),selected,func():
			if entry[0]=="equipment":ui.navigate("Kutular")
			elif entry[0]==ui.page:ui.refresh()
			else:ui.navigate("Mağaza" if entry[0]=="Envanter" and ui.collection_shop else entry[0])
		)
		if entry[0]=="Setler":
			var cover=ColorRect.new();cover.size=node.size;cover.color=Color("303539");cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;node.add_child(cover)
			ui.text(node,"SETLER",Vector2.ZERO,node.size,12,Art.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		node.tooltip_text=["Silah","Güç / Dövme","Karakter","Ekipman","Özel efektler","Setler"][i]
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
			elif ui.page=="power":ui.filter_id="all" if entry[0]=="power" else entry[0];ui.offset=0;refresh_grid()
			elif ui.page=="Karakterler":ui.filter_id=entry[0];ui.offset=0;refresh_grid()
			elif entry[0]=="all":ui.filter_id="all";refresh_grid()
			else:ui.show_error("Bu alt kategori için doğrulanmış kullanılabilir kayıt yok.")
		)
		node.toggle_mode=true;node.set_pressed_no_signal(selected)
		filter_tabs.append(node)

func card(parent,entry,at,selected=false):
	var template=Art.catalog().layouts["interface/equiplistbox"].widgets[1]
	var factory=Layout.new();var cell=factory.create_widget(template);factory.free()
	cell.position=at;cell.size=Vector2(209,115);cell.disabled=false;cell.toggle_mode=true;parent.add_child(cell);cell.set_pressed_no_signal(selected);cell.set_meta("entry",entry)
	var shade=ColorRect.new();shade.position=Vector2(2,2);shade.size=Vector2(205,111);shade.color=Quality.COLORS[Quality.label(entry)]*Color(1,1,1,0.35);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(shade)
	var icon=entry.get("icon",entry.get("texture",""))
	if ui.page=="Karakterler":icon=portraits.get(entry.id,{}).get("asset","")
	if icon!="":
		var region=Rect2(0,0,210,75) if ui.page in ["Envanter","Mağaza"] else Rect2()
		if ui.page=="Karakterler":region=portrait_region(entry.id)
		if entry.has("iconRegion"):var r=entry.iconRegion;region=Rect2(r[0],r[1],r[2],r[3])
		var fallback=ui.page=="Karakterler" and portraits.get(entry.id,{}).get("kind")=="rendered_model_preview"
		if fallback:
			region=Rect2(Art.texture(icon).get_image().get_used_rect())
			Art.sprite(cell,icon,Vector2(82,2),Vector2(123,72),Rect2(region.position,Vector2(region.size.x,region.size.x))).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Art.sprite(cell,icon,Vector2(2,2),Vector2(75,72) if fallback else Vector2(205,72),region).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.text(cell,title(entry),Vector2(4,76),Vector2(201,16),12)
	return cell

func build_loadouts():
	loadout_tabs.clear();equipped_cards.clear()
	for i in range(5):
		var node=tab(ROOT+"shop_iv_tab_02.dtx",Rect2(0,0,82,27),Vector2(8+i*68,123),Vector2(67,27),ui.game.book.active_loadout==i,func():
			if ui.game.book.select_loadout(i):ui.game.equip_slot("primary");ui.refresh()
			else:ui.show_error("Ekipman seti kaydedilemedi.")
		)
		var caption=ui.text(node,ui.game.book.loadout_names[i],Vector2(2,3),Vector2(63,20),11);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
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
	var source=ui.game.book.weapons if ui.page in ["Mağaza","Envanter"] else (ui.game.book.characters if ui.page=="Karakterler" else (ui.game.book.tattoos if ui.page=="Dövmeler" else ((ui.game.equipment.rules.items+ui.game.power_catalog.items) if ui.page=="power" else ui.game.book.effects)))
	for row in source:
		if ui.quality_id!="all" and Quality.label(row)!=ui.quality_id:continue
		if ui.page=="Karakterler" and ui.filter_id in ["red","blue","common"] and row.get("sourceTeam","common")!=ui.filter_id:continue
		if ui.page=="power" and ui.filter_id not in ["all","power"] and row.get("category","other")!=ui.filter_id:continue
		if ui.page=="Dövmeler" and ui.filter_id!="all" and row.role!=ui.filter_id:continue
		if ui.page in ["Mağaza","Envanter"]:
			if row.get("engineImported")!=true or row.get("available")!=true:continue
			if not ui.collection_shop and not ui.game.book.owned.get(row.id,false):continue
			if ui.filter_id=="special" and row.category not in ["knife","grenade","rocket","launcher"]:continue
			if ui.filter_id not in ["all","special"] and ui.game.book.slot_for(row.category)!=ui.filter_id:continue
		if ui.page=="Karakterler" and row.get("available")!=true:continue
		if ui.game.book.offline_edition and not ui.collection_shop and ui.page in ["Karakterler","Dövmeler","power"] and not ui.game.collection_owned(row.id):continue
		if not ui.search_query.is_empty() and not normalized(title(row)+" "+str(row.get("sourceId",""))).contains(normalized(ui.search_query)):continue
		rows.append(row)
	if ui.page=="Dövmeler":
		var unique={}
		for row in rows:
			var key=row.get("canonicalId",row.id)
			if not unique.has(key) or row.id==key:unique[key]=row
		rows=unique.values()
	if ui.page=="Dövmeler" and ui.filter_id=="all":
		var families={}
		for row in rows:
			var key=row.get("setKey",row.id)
			if not families.has(key):families[key]={}
			if not families[key].has(row.role):families[key][row.role]=[]
			families[key][row.role].append(row)
		var grouped=[]
		var keys=families.keys()
		keys.sort_custom(func(a,b):
			var ac=families[a].has("left") and families[a].has("body") and families[a].has("right")
			var bc=families[b].has("left") and families[b].has("body") and families[b].has("right")
			return ac if ac!=bc else a<b
		)
		for key in keys:
			var count=0
			for role in families[key]:count=maxi(count,families[key][role].size())
			for index in range(count):
				for role in ["left","body","right"]:
					var items=families[key].get(role,[])
					grouped.append(items[index] if index<items.size() else {"id":"empty-"+key+role+str(index),"name":{"left":"Sol kol","body":"Sırt","right":"Sağ kol"}[role]+" · Bu sette yok","role":role,"placeholder":true})
		return grouped
	return rows

func scroll_to(value):
	var maximum=maxf(0,ceili(entries.size()/3.0)*117.0-351.0)
	swipe.scroll=clampf(value,0,maximum)
	var index=int(swipe.scroll/117)*3
	if index!=ui.offset:ui.offset=index;refresh_grid(true)
	else:
		for cell in grid.get_children():cell.position.y=float(cell.get_meta("row_y",0))-fmod(swipe.scroll,117.0)

func refresh_native_grid(scrolling=false):
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	entries=native_rows()
	ui.offset=clampi(int(ui.offset/3)*3,0,maxi(0,ceili(entries.size()/3.0)-3)*3)
	if not scrolling:swipe.scroll=ui.offset/3.0*117
	if ui.selected.is_empty() or not entries.has(ui.selected):ui.selected={}
	if ui.selected.is_empty():
		for row in entries:
			if not row.get("placeholder",false):ui.selected=row;break
	var group=ButtonGroup.new()
	for i in range(mini(12,entries.size()-ui.offset)):
		var entry=entries[ui.offset+i];var cell=card(grid,entry,Vector2(i%3,int(i/3))*Vector2(210,117),entry==ui.selected)
		cell.set_meta("row_y",int(i/3)*117);cell.position.y-=fmod(swipe.scroll,117.0)
		cell.disabled=entry.get("placeholder",false)
		cell.button_group=group
		if ui.page=="power" and not ui.collection_shop:
			var count=int(ui.game.inbox.state.powerCounts.get(ui.game.item_key(entry.id),0))
			var equipped=str(entry.id) in ui.game.inbox.state.powerSlots.values() or (str(entry.id) in ["19601","19601.0"] and ui.game.equipment.has_wolf_ability())
			ui.text(cell,"Kullanılıyor" if equipped else ("Kalan adet: %d" % count if str(entry.id) not in ["19601","19601.0"] else "Kullanılabilir"),Vector2(4,94),Vector2(201,16),11,Color("c4cccf"))
		if not ui.collection_shop and ui.page in ["Envanter","Mağaza"] and entry.id in ui.game.book.slots.values():ui.text(cell,"Kullanılıyor",Vector2(4,94),Vector2(201,16),11,Color("c4cccf"))
		if ui.collection_shop and not entry.get("placeholder",false):
			var offers=ui.game.shop_offers(entry.id)
			ui.text(cell,price_text(offers[0]) if not offers.is_empty() else no_price_text(entry.id),Vector2(4,94),Vector2(201,16),11,Color("e8cc73"))
		cell.pressed.connect(func():ui.selected=entry;show_details())
	page_label.text="%d / %d  ·  %d eşya" % [int(ui.offset/9)+1,maxi(1,int(ceil(float(entries.size())/9))),entries.filter(func(row):return not row.get("placeholder",false)).size()]
	if not scrolling:show_details()

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
	var icon=portraits.get(entry.get("id",""),{}).get("asset","") if ui.page=="Karakterler" else entry.get("icon",entry.get("texture",""))
	var info_region=Rect2()
	if entry.has("iconRegion"):var r=entry.iconRegion;info_region=Rect2(r[0],r[1],r[2],r[3])
	if icon!="":Art.sprite(details,icon,Vector2(376,571),Vector2(270,121),(portrait_region(entry.id) if ui.page=="Karakterler" else Rect2(0,0,210,75)) if ui.page in ["Envanter","Mağaza","Karakterler"] else info_region).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
			var tuning=weapon_tuning(entry)
			copy="YEREL OYUN\nHasar: %d\nŞarjör: %d\nAtış aralığı: %.3f sn\nŞarjör değiştirme: %.2f sn" % [int(tuning.damage),int(tuning.capacity),float(tuning.fireInterval),float(tuning.reloadSeconds)]
			if entry.has("sourceDetails"):
				var original=entry.sourceDetails
				copy+="\n\nPC EŞYA BİLGİSİ\nMod: %s\nAğırlık: %s\nMühimmat: %s" % [original.modeText,original.weightText,original.magazineText]
		if copy=="":copy="Açıklama bulunmuyor."
		if info_tab=="properties":weapon_properties(entry)
		else:body(copy)
		action_use(entry)
		if ui.page=="Mağaza":
			ui.paragraph(details,title(entry),Vector2(16,119),Vector2(320,35),14)
			Art.sprite(details,entry.icon,Vector2(16,175),Vector2(320,230)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ui.paragraph(details,"Mağazadan al; hediye kutusunda onaylayıp envantere aktar.",Vector2(18,433),Vector2(310,45),12)
	elif ui.page=="Karakterler":build_character(entry)
	elif ui.page=="Dövmeler":build_tattoo(entry)
	elif ui.page=="power":build_power(entry)
	else:
		preview_sprite=Art.sprite(details,entry.frames[0],Vector2(20,190),Vector2(310,280));preview_sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		effect_frames=entry.frames;effect_fps=float(entry.fps);effect_time=0
		ui.paragraph(details,"Efekt önizlemesi.",Vector2(674,577),Vector2(328,100),12)

	if ui.collection_shop:build_purchase(entry)

func build_character(entry):
	ui.trace("interface/charequipmentpage")
	build_team_buttons(true)
	character_heading()
	ui.preview_angle=-0.12
	ui.build_preview(Vector2(2,145),Vector2(350,596),entry)
	var icon=portraits.get(entry.id,{}).get("asset","")
	Art.sprite(details,icon,Vector2(272,78),Vector2(66,86),Rect2(0,0,73,75)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.button(details,"N",Vector2(273,165),Vector2(31,23),func():ui.preview_wolf=false;ui.replace_preview(entry))
	ui.button(details,"M",Vector2(306,165),Vector2(31,23),func():ui.preview_wolf=true;ui.replace_preview(entry))
	ui.button(details,"İnsan / Kurt",Vector2(174,710),Vector2(160,28),func():ui.preview_wolf=not ui.preview_wolf;ui.replace_preview(entry))
	ui.button(details,"Karakteri kullan",Vector2(366,710),Vector2(146,28),func():
		if ui.game.select_library_character(entry):ui.refresh();ui.show_error("Karakter seçimi kaydedildi.")
		else:ui.show_error("Karakter kaydedilemedi.")
	)
	ui.button(details,"AT",Vector2(516,710),Vector2(140,28),func():ui.confirm("KARAKTER","Çevrimdışı kaynak koleksiyonu kalıcıdır; karakter silinmez.",func():pass))
	var count=ui.game.book.characters.filter(func(row):return row.get("available",false) and ui.game.book.owns(row.id)).size()
	var total=ui.game.book.characters.filter(func(row):return row.get("available",false)).size()
	ui.text(details,"Karakter Slotu %d / %d" % [count,total],Vector2(789,125),Vector2(207,22),11,Color("8bb7b1"))
	ui.content.move_child(details,ui.content.get_child_count()-1)
	var copy=entry.name+"\n\n"+("Envanterde" if ui.game.collection_owned(entry.id) else "Mağaza önizlemesi")+"\nİnsan/kurt görünümünü N/M düğmeleriyle değiştir."
	if info_tab=="properties":
		copy="KAYNAK KARAKTER PUANLARI\n"
		var stats=entry.get("sourceStats",{})
		for form in ["human","wolf"]:
			if not stats.has(form):continue
			copy+="\n"+("İNSAN" if form=="human" else "KURT")+"\n"
			var names=["Baş zırhı","Gövde zırhı","Kol zırhı","Bacak zırhı","Fazladan YP","Özel saldırı direnci","Hız"] if form=="human" else ["Saldırı menzili","Saldırı hasarı","Dönüşüm hızı","Fazladan YP","Zırh","Hız"]
			for i in range(names.size()):copy+=names[i]+": +%d\n" % stats[form].values[i]
			copy+="GP: +%%%d · Altın: +%%%d\n" % [stats[form].gpPercent,stats[form].goldPercent]
		copy+="\nKaynak puanlarıdır. Bölgesel zırh etkileri yerel savaşta henüz uygulanmıyor."
	body(copy)

func build_tattoo(entry):
	build_team_buttons(false)
	character_heading()
	var known=entry.role in ["body","left","right"]
	ui.preview_wolf=true;ui.build_preview(Vector2(2,148),Vector2(350,592),ui.game.book.character_for_team(ui.preview_team))
	var shown=ui.game.book.selected_tattoos.duplicate()
	if known:shown[entry.role]=entry.texture
	for mesh in ui.preview_model.find_children("*","MeshInstance3D",true,false):
		var name=str(mesh.name).to_lower()
		if not name.begins_with("tattoo"):continue
		var role="body" if "body" in name else ("left" if name.ends_with("_l") else "right")
		preload("res://scripts/tattoo_uv.gd").apply(mesh,ui.game.book.tattoo_uv_transpose(role,shown.get(role,"")))
		if not shown.has(role) or not ui.game.book.tattoo_matches_role(role,shown[role]):mesh.hide();continue
		var material=StandardMaterial3D.new();material.albedo_texture=load(shown[role]);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=0.7
		material.render_priority=ui.game.book.tattoo_render_priority(shown[role])
		mesh.material_override=material;mesh.show()
	var copy="Bölge: "+{"body":"Gövde","left":"Sol kol","right":"Sağ kol"}.get(entry.role,"Belirsiz")+"\n"+entry.description
	var bonuses=entry.get("appliedBonuses",{})
	for key in bonuses:
		if float(bonuses[key])!=0:copy+="\n"+ui.game.book.stat_labels.get(key,key)+": +%"+str(bonuses[key])
	body(copy)
	ui.button(details,"Tak" if known else "Bölge belirsiz",Vector2(366,710),Vector2(290,28),func():
		if ui.game.book.set_tattoo(entry.role,entry.texture,entry.id):ui.game.player.apply_tattoos();ui.refresh();ui.show_error("Dövme kaydedildi.")
		else:ui.show_error("Dövme kaydedilemedi.")
	,known)
	ui.button(details,"Dövmeyi çıkar",Vector2(664,710),Vector2(348,28),func():
		if ui.game.book.set_tattoo(entry.role,""):ui.game.player.apply_tattoos();ui.show_error("Dövme çıkarıldı.");ui.refresh()
		else:ui.show_error("Dövme çıkarılamadı.")
	,known)

	for node in details.get_children():
		if node is RichTextLabel:node.size.y=126
	ui.content.move_child(details,ui.content.get_child_count()-1)

func build_power_slots():
	var slots=[["support","İlkyardım"],["energy","Enerji"],["bag","Çanta"],["claw","Pençe"],["ability","Yetenek"]]
	for i in range(slots.size()):
		var key=slots[i][0];var entry=ui.game.power_item(ui.game.inbox.state.powerSlots.get(key,""))
		if key=="ability" and ui.game.equipment.has_wolf_ability():entry=ui.game.equipment.rules.items[0]
		var cell=card(ui.content,entry if not entry.is_empty() else {"name":slots[i][1]+" · Boş","icon":""},Vector2(117,154+i*117))
		ui.text(ui.content,slots[i][1],Vector2(8,167+i*117),Vector2(102,22),12,Color("94a2a6"))
		if not entry.is_empty():
			ui.text(cell,"Kullanılıyor",Vector2(4,94),Vector2(201,16),11)
			cell.pressed.connect(func():ui.selected=entry;show_details())

func build_power(entry):
	ui.trace("interface/abilityequipmentpage")
	if ui.collection_shop:
		build_team_buttons(false);character_heading()
		ui.preview_wolf=true
		ui.build_preview(Vector2(2,148),Vector2(350,592),ui.game.book.character_for_team(ui.preview_team))
	if str(entry.id) in ["19601","19601.0"]:
		body(entry.description)
		var equipped=ui.game.equipment.has_wolf_ability()
		ui.button(details,"Güç slotuna tak" if not equipped else "Takılı · Çıkar",Vector2(366,710),Vector2(290,28),func():
			if not ui.game.equipment.equip_power(0 if equipped else 19601):ui.show_error("Güç slotu kaydedilemedi.");return
			ui.game.player.reset_locomotion();ui.refresh()
		)
		return
	var count=int(ui.game.inbox.state.powerCounts.get(ui.game.item_key(entry.id),0));var equipped=ui.game.inbox.state.powerSlots.get(entry.slot,"")==entry.id
	var copy=entry.description
	if info_tab=="properties":
		var tuning=entry.mobileTuning
		copy="YEREL MAÇ\n"
		match entry.slot:
			"support":copy+="YP yenileme: +%d\nRaunt başına: %d\nAnında iyileştirme" % [tuning.heal,tuning.usesPerRound]
			"energy":copy+="Süre: %d sn\nHasar: +%%%d\nHız: +%%%d\nMevcut YP maliyeti: %%%d" % [tuning.seconds,roundi((tuning.damageMultiplier-1)*100),roundi((tuning.speedMultiplier-1)*100),roundi(tuning.healthCostFraction*100)]
			"bag":copy+="Hedef başına GP: +%%%d" % roundi(tuning.localGpBonus*100)
			"claw":copy+="Hasar: +%d / +%%%d\nMenzil: +%.2f / +%%%d" % [tuning.get("damageBonus",0),tuning.get("damagePercent",0),tuning.get("rangeBonus",0),tuning.get("rangePercent",0)]
		copy+="\nKalan adet: %d" % count
	body(copy)
	ui.button(details,"Takılı · Çıkar" if equipped else "Kullan",Vector2(366,710),Vector2(140,28),func():
		if equipped:
			var pending=ui.game.inbox.state.duplicate(true);pending.powerSlots.erase(entry.slot)
			if ui.game.save_wallet(null,null,null,pending):ui.game.inbox.state=pending;ui.refresh()
			else:ui.show_error("Ekipman kaydedilemedi.")
		elif ui.game.equip_power_item(entry.id):ui.refresh()
		else:ui.show_error("Önce hediye kutusundan eşyayı al.")
	,count>0 or equipped)

func select_relative(direction):
	if entries.is_empty():return
	var index=posmod(entries.find(ui.selected)+direction,entries.size())
	ui.selected=entries[index];ui.offset=int(index/9)*9;refresh_grid()

func body(copy):
	var node=RichTextLabel.new();node.text=copy;node.position=Vector2(674,577);node.size=Vector2(328,149);node.fit_content=false;node.scroll_active=true
	node.add_theme_font_override("normal_font",Art.font());node.add_theme_font_size_override("normal_font_size",12);details.add_child(node)

func weapon_tuning(entry):
	var tuning=entry.gameplayTuning.duplicate(true)
	var native=ui.game.player.native_weapon_rules.get(entry.id,{})
	if native.is_empty():return tuning
	tuning.capacity=native.capacity;tuning.fireInterval=native.fireIntervalMs/1000.0;tuning.damage=native.baseDamage if native.baseDamage>0 else native.splashDamage
	var motion=ui.game.player.weapon_motion.catalog.get(entry.model,{});var alias=ui.game.book.models.get(entry.model,{}).get("clips",{}).get("reload","Reload")
	var clip=motion.get("animations",{}).get(alias,{})
	if clip.has("durationMs"):tuning.reloadSeconds=clip.durationMs/1000.0
	tuning.perShell=str(native.ammoName).to_lower()=="supas" and motion.get("animations",{}).has("Reload2");tuning.native=true
	return tuning

func weapon_properties(entry):
	var tuning=weapon_tuning(entry)
	ui.text(details,"TEMEL ÖZELLİKLER" if tuning.get("native",false) else "YEREL ÖZELLİKLER",Vector2(674,571),Vector2(328,20),11,Art.GOLD)
	var rows=[["TEMEL HASAR" if tuning.get("native",false) else "HASAR",float(tuning.damage),250.0],["ŞARJÖR",float(tuning.capacity),100.0],["ATIŞ / SN",1.0/float(tuning.fireInterval),20.0],["TEK MERMİ (SN)" if tuning.get("perShell",false) else "DOLUM (SN)",float(tuning.reloadSeconds),6.0]]
	for i in range(rows.size()):
		var row=rows[i];var y=601+i*29
		ui.text(details,row[0],Vector2(674,y),Vector2(115,21),11)
		var bar=ProgressBar.new();bar.position=Vector2(790,y+5);bar.size=Vector2(151,9);bar.max_value=row[2];bar.value=row[1];bar.show_percentage=false;details.add_child(bar)
		ui.text(details,"%.1f" % row[1],Vector2(947,y),Vector2(59,21),12,Color("9ae2d6"))

func build_team_buttons(filter_characters):
	for i in range(2):
		var team="red" if i==0 else "blue"
		var region=Rect2(48,0,30,31) if i==0 else Rect2(83,0,25,31)
		var button=Art.atlas_button(details,ROOT+"iv_ch_tab.dtx",[region,Rect2(region.position+Vector2(0,31),region.size),Rect2(region.position+Vector2(0,62),region.size)],Vector2(41+i*36,119),Vector2(32,29),func():
			ui.preview_team=team
			if filter_characters:ui.filter_id=team;ui.offset=0;refresh_grid()
			else:show_details()
		)
		button.tooltip_text="Kırmızı takım" if i==0 else "Mavi takım"
		button.toggle_mode=true;button.set_pressed_no_signal((ui.selected.get("sourceTeam",ui.preview_team) if filter_characters else ui.preview_team)==team)
		button.set_meta("source_team",team)

func character_heading():
	var cover=ColorRect.new();cover.position=Vector2(0,61);cover.size=Vector2(344,31);cover.color=Color.BLACK;cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;details.add_child(cover)
	Art.sprite(details,ROOT+"iv_ch_top.dtx",Vector2(0,61),Vector2(256,32))
	ui.button(details,"GÜÇ+",Vector2(0,90),Vector2(84,27),func():ui.navigate("power"))

func price_text(offer):return "%d %s" % [int(offer.price),{"gold":"Altın","cash":"Nakit","kp":"KP"}.get(offer.currency,offer.currency)]
func switch_collection_mode():
	ui.collection_shop=not ui.collection_shop
	ui.navigate(("Mağaza" if ui.collection_shop else "Envanter") if ui.page in ["Mağaza","Envanter"] else ui.page)
func build_purchase(entry):
	for node in details.get_children():
		if node.position.y>=710:details.remove_child(node);node.queue_free()
	var offers=ui.game.shop_offers(entry.id)
	var owned=ui.game.collection_owned(entry.id)
	if owned and ui.game.shop_catalog.items.get(ui.game.item_key(entry.id),{}).get("kind","")!="power":
		ui.button(details,"Envanterde · Kullan",Vector2(366,710),Vector2(290,28),func():ui.collection_shop=false;ui.navigate("Envanter" if ui.page=="Mağaza" else ui.page))
		return
	if offers.is_empty():
		var linked=ui.game.shop_catalog.items.get(ui.game.item_key(entry.id),{}).get("relatedSets",[])
		ui.button(details,"İçeren setleri göster" if not linked.is_empty() else no_price_text(entry.id),Vector2(366,710),Vector2(290,28),func():ui.set_filter_item=ui.game.item_key(entry.id);ui.navigate("Setler"),not linked.is_empty())
		return
	var picker=ui.map_picker(details,Vector2(366,671),Vector2(290,29))
	for offer in offers:picker.add_item(price_text(offer))
	ui.text(details,"1 adet · Kalıcı yerel kullanım",Vector2(366,641),Vector2(290,25),12)
	ui.button(details,"SATIN AL",Vector2(366,710),Vector2(290,28),func():
		var offer=offers[picker.selected];var request="purchase-%d-%d" % [Time.get_ticks_usec(),randi()]
		ui.confirm("SATIN AL",title(entry)+"\n"+price_text(offer)+"\n1 adet · Kalıcı yerel kullanım\nHediye kutusuna gönderilecek.",func():
			var result=ui.game.buy_shop(entry.id,offer.currency,request)
			if result.ok:ui.navigate("gifts")
			else:ui.show_error(result.error)
		,func():pass)
	)

func portrait_region(id):
	var rect=portraits.get(id,{}).get("region",[0,0,210,75]);return Rect2(rect[0],rect[1],rect[2],rect[3])

func no_price_text(id):
	var item=ui.game.shop_catalog.items.get(ui.game.item_key(id),{})
	if not item.get("relatedSets",[]).is_empty():return "Set içinde alınabilir"
	return "Kaynak tabloda fiyat yok" if not item.get("sourceOffsets",[]).is_empty() else "Kaynak satış kaydı yok"
