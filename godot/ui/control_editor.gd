extends Control
const Layout=preload("res://scripts/control_layout.gd")
const Art=preload("res://ui/source_theme.gd")
var ui
var draft={}
const TITLES={"fire":"Saldırı","jump":"Zıpla","crouch":"Çömel","reload":"Şarjör / Kükreme","transform":"İnsan / Kurt","sprint":"Koşu","aim":"Nişan / Güçlü saldırı","forward":"▲","backward":"▼","left":"◀","right":"▶","roll":"Takla","support":"Can yenile","energy":"Enerji","menu":"Menü","inventory":"Envanter","scoreboard":"Skor tablosu","interact":"Bomba","slot_primary":"Ana silah","slot_pistol":"Tabanca","slot_knife":"Bıçak","slot_grenade":"Bomba slotu"}
var selected="fire"
var handles={}
var dragging=""
var finger=-1
var slider
var title
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 draft=ui.game.book.control_layout.duplicate(true)
 var saved=ui.game.book.control_layout;ui.game.book.control_layout={}
 ui.game.touch.resize();ui.game.source_hud.arrange()
 var shade=ColorRect.new();shade.color=Color(0.025,0.04,0.06,0.95);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
 var roots=[]
 for b in ui.game.touch.buttons:roots.append([b.action,b.position,Vector2.ONE*(64 if b.action=="fire" else 54)*ui.game.touch.ui_scale,b.get_child(1).texture])
 for row in ui.game.source_hud.layout_targets():
  var b=row[1];var tex=b.find_children("*","TextureRect",true,false);roots.append([row[0],b.get_global_rect().get_center(),b.get_global_rect().size,tex[0].texture if not tex.is_empty() else null])
 ui.game.book.control_layout=saved;ui.game.touch.resize();ui.game.source_hud.arrange()
 for row in roots:
  var key=row[0];var button=Button.new();button.flat=true;button.focus_mode=Control.FOCUS_NONE;add_child(button);button.set_meta("base_center",row[1]);button.set_meta("base_size",row[2]);button.tooltip_text=TITLES.get(key,key)
  var image=TextureRect.new();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=row[3];image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.add_child(image)
  if image.texture==null:
   var caption=Art.label(TITLES.get(key,key),button.size,12);caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;button.add_child(caption)
  button.gui_input.connect(func(event):handle_input(key,event));button.draw.connect(func():button.draw_circle(button.size/2,minf(button.size.x,button.size.y)/2,Color(0.5,0.75,0.9,0.22)));handles[key]=button
 title=Art.label("Düğmeyi seç ve sürükle · Boyutunu aşağıdan ayarla",Vector2(size.x-270,40),20);title.position=Vector2(260,8);add_child(title)
 var bar=HBoxContainer.new();bar.position=Vector2(260,52);bar.size=Vector2(size.x-24,52);add_child(bar)
 for entry in [["Kaydet",save],["İptal",ui.go_back],["Varsayılan",reset_layout]]:
  var b=Button.new();b.text=entry[0];b.custom_minimum_size=Vector2(90,48);b.pressed.connect(entry[1]);bar.add_child(b)
 slider=HSlider.new();slider.min_value=0.6;slider.max_value=2;slider.step=0.05;slider.custom_minimum_size=Vector2(180,48);bar.add_child(slider);slider.value_changed.connect(func(value):set_row(selected,null,value))
 select("fire");arrange()
func select(key):
 selected=key;slider.set_value_no_signal(Layout.scale_for(draft,key));title.text="%s · Boyut %%%d · Sürükleyerek taşı" % [TITLES.get(key,key),roundi(slider.value*100)]
func set_row(key,where=null,factor=-1):
 var b=handles[key];var center=b.position+b.size/2 if where==null else where;var weight=Layout.scale_for(draft,key) if factor<0 else factor
 draft[key]=[clampf(center.x/size.x,0,1),clampf(center.y/size.y,0,1),weight];arrange();select(key)
func arrange():
 for key in handles:
  var b=handles[key];b.size=b.get_meta("base_size")*Layout.scale_for(draft,key);b.position=Layout.center(draft,key,b.get_meta("base_center"),size,maxf(b.size.x,b.size.y)/2)-b.size/2;b.queue_redraw()
func handle_input(key,event):
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:select(key);dragging=key
  else:dragging=""
 elif event is InputEventMouseMotion and dragging==key:set_row(key,get_global_mouse_position())
 elif event is InputEventScreenTouch:
  if event.pressed and finger<0:select(key);dragging=key;finger=event.index
  elif not event.pressed and event.index==finger:dragging="";finger=-1
 elif event is InputEventScreenDrag and event.index==finger:set_row(key,handles[key].get_global_transform()*event.position)
func reset_layout():draft={};arrange();select(selected)
func save():
 if ui.game.book.set_control_layout(draft):ui.game.touch.resize();ui.game.source_hud.arrange();ui.go_back()
 else:title.text="Kaydedilemedi. Önceki düzen korundu."
