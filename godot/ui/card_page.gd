extends RefCounted
const Art=preload("res://ui/source_theme.gd")
var ui
var entries=[]
var filtered=[]
var grid:Control
var detail:Control
var search:LineEdit
var page_label:Label
var group=ButtonGroup.new()

func build():
	var section=ui.native("interface/card/cardsection",ui.content)
	section.show_only(["BackGround"])
	ui.trace("interface/card/carditem");ui.trace("interface/card/cardpropertysheet")
	# These are the actual source faces, not an owned-account card list. Baked
	# ranks on the artwork are part of the preview; no rank/stat is granted.
	for key in Art.catalog().textures:
		if not key.begins_with("wt_interface/chr_card/cc_card_"):continue
		var info=Art.catalog().textures[key]
		if info.width<255 or info.height<419:continue
		entries.append({"source":key,"asset":info.asset,"name":key.get_file().trim_prefix("cc_card_").trim_suffix(".dtx").replace("_"," ")})
	entries.sort_custom(func(a,b):return a.source<b.source)
	ui.text(ui.content,"KART ÖNİZLEMESİ",Vector2(20,82),Vector2(310,25),14)
	for i in range(3):
		var value=["all","n","m"][i]
		ui.button(ui.content,["Tümü","Normal","Master"][i],Vector2(364+i*90,122),Vector2(86,27),func():ui.filter_id=value;ui.offset=0;refresh())
	search=LineEdit.new();search.position=Vector2(778,82);search.size=Vector2(220,25);search.placeholder_text="Kart ara…";search.text=ui.search_query;search.set_meta("navigation_input","card_search");search.text_changed.connect(func(value):ui.search_query=value;ui.offset=0;refresh());ui.content.add_child(search)
	grid=Control.new();grid.position=Vector2(364,154);grid.size=Vector2(634,516);ui.content.add_child(grid)
	detail=Control.new();detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(detail)
	page_label=ui.text(ui.content,"",Vector2(550,702),Vector2(270,28),12);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.button(ui.content,"Önceki",Vector2(364,702),Vector2(120,28),func():ui.offset=maxi(0,ui.offset-8);refresh())
	ui.button(ui.content,"Sonraki",Vector2(878,702),Vector2(120,28),func():ui.offset=mini(int((maxi(1,filtered.size())-1)/8)*8,ui.offset+8);refresh())
	refresh()

func refresh():
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	filtered=entries.filter(func(row):
		var name=row.source.get_file()
		return (ui.filter_id=="all" or name.contains("_%s_" % ui.filter_id)) and (search.text.is_empty() or row.name.to_lower().contains(search.text.to_lower()))
	)
	ui.offset=clampi(int(ui.offset/8)*8,0,int((maxi(1,filtered.size())-1)/8)*8)
	if ui.selected.is_empty() or not filtered.has(ui.selected):ui.selected=filtered[ui.offset] if not filtered.is_empty() else {}
	for i in range(mini(8,filtered.size()-ui.offset)):
		var entry=filtered[ui.offset+i];var region=Rect2(0,0,255,419)
		var node=Art.atlas_button(grid,entry.source,[region,region,region],Vector2(i%4,int(i/4))*Vector2(160,260),Vector2(154,254),func():ui.selected=entry;refresh())
		node.toggle_mode=true;node.button_group=group;node.set_pressed_no_signal(entry==ui.selected);node.set_meta("entry",entry);node.tooltip_text=entry.name
		if entry==ui.selected:Art.sprite(node,"wt_interface/character_card/cc_chr_slot_bar.dtx",Vector2.ZERO,Vector2(154,254),Rect2(0,0,154,256))
	page_label.text="%d / %d  ·  %d kart" % [int(ui.offset/8)+1,maxi(1,int(ceil(float(filtered.size())/8))),filtered.size()]
	for child in detail.get_children():detail.remove_child(child);child.queue_free()
	if not ui.selected.is_empty():Art.sprite(detail,ui.selected.source,Vector2(62,125),Vector2(226,372),Rect2(0,0,255,419))
	ui.paragraph(detail,"Önizleme\n\nKart envanteri ve geliştirme hizmeti bağlı değil. Bu görünüm kart veya özellik kazandırmaz.",Vector2(28,554),Vector2(285,132),12)
	ui.button(detail,"Kartı kullan",Vector2(40,700),Vector2(270,28),func():pass,false)
