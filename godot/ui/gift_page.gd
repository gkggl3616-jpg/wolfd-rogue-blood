extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Card=preload("res://ui/source_item_card.gd")
var ui
var tab="received"
var page=0
var cards=[]
var view
var art_cache={}
func build():
	var background=ui.native("section/inventory",ui.content);background.show_only(["WeaponState","Inventory"])
	view=ui.native("interface/giftbox",ui.content,Vector2(190,83),Vector2(643,625))
	view.show_only(["GiftBox","ExitButton","Received","Sended","PrevButton","NextButton"])
	view.bind_action("ExitButton",ui.go_back)
	view.bind_action("Received",func():tab="received";page=0;render())
	view.bind_action("Sended",func():tab="sent";page=0;render())
	view.bind_action("PrevButton",func():page=maxi(0,page-1);render())
	view.bind_action("NextButton",func():page+=1;render())
	ui.button(ui.content,"Alınanların geçmişi",Vector2(590,111),Vector2(220,26),func():tab="history";page=0;render())
	render()
func rows():
	if tab=="sent":return []
	var result=ui.game.inbox.state.messages.filter(func(row):return (row.status=="accepted") if tab=="history" else row.status=="pending")
	result.reverse();return result
func artwork(gift):
	var cache_key=gift.kind+":"+gift.item
	if art_cache.has(cache_key):return art_cache[cache_key]
	var entry={}
	match gift.kind:
		"box":entry=ui.game.boxes.box(gift.item)
		"power":entry=ui.game.power_item(gift.item)
		"weapon":entry=ui.game.book.weapon(gift.item)
		"tattoo":
			for row in ui.game.book.tattoos:
				if row.id==gift.item:entry=row;break
		"character":entry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/character-portraits.json")).portraits.get(gift.item,{})
	var region=entry.get("region",entry.get("iconRegion",[0,0,210,75] if gift.kind in ["weapon","power"] else []))
	var result={"asset":entry.get("icon",entry.get("asset",entry.get("texture","wt_interface/all/a_lb_icon_gift.dtx"))),"region":Rect2(region[0],region[1],region[2],region[3]) if region.size()==4 else Rect2()}
	if gift.kind=="character":
		var texture=Art.texture(result.asset)
		if texture:
			var occupied=Rect2(texture.get_image().get_used_rect());var trimmed=result.region.intersection(occupied) if result.region.has_area() else occupied
			if trimmed.has_area():result.region=trimmed
	art_cache[cache_key]=result;return result
func render():
	for node in cards:node.get_parent().remove_child(node);node.queue_free()
	cards.clear();var entries=rows();var pages=maxi(1,ceili(entries.size()/12.0));page=clampi(page,0,pages-1)
	var counter=ui.text(view,"%d / %d" % [page+1,pages],Vector2(282,591),Vector2(69,27),14);counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cards.append(counter)
	for i in range(mini(12,entries.size()-page*12)):
		var gift=entries[page*12+i];var cell=Card.create(view,Vector2(3+(i%3)*211,58+int(i/3)*118),Vector2(209,116),func():confirm_gift(gift));cards.append(cell);cell.set_meta("gift_id",gift.id)
		var art=artwork(gift)
		var picture=Art.sprite(cell,art.asset,Vector2(5,4),Vector2(198,69),art.region);picture.name="GiftArtwork";picture.stretch_mode=TextureRect.STRETCH_SCALE
		var date=Time.get_date_string_from_unix_time(int(gift.created)).replace("-",".")
		ui.text(cell,date,Vector2(6,4),Vector2(190,19),11)
		ui.text(cell,gift.name,Vector2(5,77),Vector2(199,18),12)
		var left=int(gift.expires-Time.get_unix_time_from_system())
		ui.text(cell,"Alındı" if gift.status=="accepted" else ("Süresi doldu" if left<=0 else "%d gün kaldı · ×%d" % [ceili(left/86400.0),gift.amount]),Vector2(5,96),Vector2(199,18),11,Color("c7d0d0"))
	if entries.is_empty():
		var empty=ui.paragraph(view,"Gönderilen hediye yok. Çevrimiçi hediye gönderme bağlı değil." if tab=="sent" else "Hediye bulunmuyor.",Vector2(40,236),Vector2(563,120),18);cards.append(empty)
	var copy=ui.paragraph(view,"Hediyeyi seçip onaylayınca envanterine aktarılır.\nAlınmayan yerel hediyeler 7 gün sonra sona erer.",Vector2(95,548),Vector2(470,43),12);copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cards.append(copy)
func confirm_gift(gift):
	if gift.status=="accepted":ui.confirm(gift.name,"Envantere aktarıldı.\nGönderen: "+gift.sender,func():pass);return
	if gift.expires<=Time.get_unix_time_from_system():ui.show_error("Hediyenin süresi doldu.");return
	ui.confirm("HEDİYEYİ AL",gift.name+" ×%d\nGönderen: %s\nEnvanterine aktarılsın mı?" % [int(gift.amount),gift.sender],func():
		var result=ui.game.accept_gift(gift.id)
		if result.ok:render();ui.show_error("Hediye envanterine aktarıldı.")
		else:ui.show_error(result.error)
	,func():pass)
