extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Card=preload("res://ui/source_item_card.gd")
var ui
var grid
var entries=[]
var swipe
var details
var counter
func build():
 ui.collection_shop=true
 var section=ui.native("section/shop",ui.content);section.show_only(["WeaponState","Inventory"])
 ui.text(ui.content,"KAYNAK SETLER",Vector2(366,65),Vector2(600,26),18,Art.GOLD)
 ui.button(ui.content,"Mağaza",Vector2(366,103),Vector2(140,28),func():ui.navigate("Mağaza"))
 ui.button(ui.content,"Tüm setler",Vector2(518,103),Vector2(140,28),func():ui.set_filter_item="";ui.refresh())
 var search=LineEdit.new();search.position=Vector2(670,103);search.size=Vector2(326,28);search.placeholder_text="Set veya içerik ara…";ui.content.add_child(search);search.text=ui.search_query
 search.text_changed.connect(func(value):ui.search_query=value;ui.offset=0;refresh_grid())
 grid=Control.new();grid.position=Vector2(366,154);grid.size=Vector2(630,351);grid.clip_contents=true;ui.content.add_child(grid)
 swipe=preload("res://ui/swipe_grid.gd").new();swipe.page=self;swipe.position=grid.position;swipe.size=grid.size;ui.content.add_child(swipe)
 counter=ui.text(ui.content,"",Vector2(366,510),Vector2(630,24),12)
 details=Control.new();ui.content.add_child(details);refresh_grid()
func refresh_grid(scrolling=false):
 entries=ui.game.source_sets.items.filter(func(item):return (ui.set_filter_item=="" or item.members.any(func(member):return member.id==ui.set_filter_item)) and (ui.search_query=="" or (item.name+" "+str(item.members)).to_lower().contains(ui.search_query.to_lower())))
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 ui.offset=clampi(int(ui.offset/3)*3,0,maxi(0,ceili(entries.size()/3.0)-3)*3)
 if not scrolling:swipe.scroll=ui.offset/3.0*117
 for i in range(mini(12,entries.size()-ui.offset)):
  var item=entries[ui.offset+i];var cell=Card.create(grid,Vector2(i%3,int(i/3))*Vector2(210,117),Vector2(209,115),func():ui.selected=item;show_details())
  cell.set_meta("row_y",int(i/3)*117);cell.position.y-=fmod(swipe.scroll,117)
  for j in range(mini(3,item.members.size())):Art.sprite(cell,item.members[j].icon,Vector2(3+j*68,3),Vector2(65,66)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  ui.text(cell,item.name,Vector2(4,74),Vector2(201,18),12);ui.text(cell,price_text(item.offers[0]),Vector2(4,95),Vector2(201,17),11,Art.GOLD)
 if ui.selected.is_empty() or not entries.has(ui.selected):ui.selected=entries[0] if not entries.is_empty() else {}
 counter.text="%d kaynak set · İçeriğin tamamı kullanıma hazır" % entries.size()
 if not scrolling:show_details()
func scroll_to(value):
 var maximum=maxf(0,ceili(entries.size()/3.0)*117-351);swipe.scroll=clampf(value,0,maximum);ui.offset=int(swipe.scroll/117)*3;refresh_grid(true)
func show_details():
 for node in details.get_children():details.remove_child(node);node.queue_free()
 if ui.selected.is_empty():return
 var item=ui.selected
 ui.text(details,item.name,Vector2(16,104),Vector2(320,60),18,Art.GOLD)
 for i in range(mini(8,item.members.size())):
  var member=item.members[i];var at=Vector2(15+(i%2)*162,180+int(i/2)*122)
  Art.sprite(details,member.icon,at,Vector2(155,78)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;ui.paragraph(details,member.name,at+Vector2(0,80),Vector2(155,36),11)
 var text="SET İÇERİĞİ\n"
 for member in item.members:text+="• "+member.name+"\n"
 text+="\nHer bileşenden 1 adet kalıcı yerel kopya. Hediye kutusunda ayrı ayrı onaylanır."
 var list=RichTextLabel.new();list.position=Vector2(674,548);list.size=Vector2(326,190);list.add_theme_font_size_override("normal_font_size",12);list.text=text;details.add_child(list)
 var picker=ui.map_picker(details,Vector2(366,650),Vector2(290,30))
 for offer in item.offers:picker.add_item(price_text(offer))
 ui.button(details,"SETİ SATIN AL",Vector2(366,710),Vector2(290,28),func():
  var offer=item.offers[picker.selected];var request="set-%d-%d" % [Time.get_ticks_usec(),randi()]
  ui.confirm("SET SATIN AL",item.name+"\n"+price_text(offer)+"\n%d bileşen · 1'er kalıcı yerel kopya\nHediye kutusuna gönderilecek." % item.members.size(),func():
   var result=ui.game.buy_source_set(item.id,offer.currency,request)
   if result.ok:ui.navigate("gifts")
   else:ui.show_error(result.error)
  ,func():pass)
 )
func price_text(offer):return "%d %s" % [int(offer.price),{"cash":"Nakit","gold":"Altın","kp":"KP"}.get(offer.currency,offer.currency)]
