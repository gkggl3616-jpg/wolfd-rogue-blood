extends Control
# Source 1024x768 coordinates stay fixed. Touch hit areas are larger than the art.
const Art=preload("res://ui/source_theme.gd")
class SourceProgress extends ProgressBar:
	func _get_minimum_size():return Vector2.ZERO
var ui
var buttons=[]
var touch_owner=-1
var pressed_button
var origin=Vector2.ZERO
func build():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var back=ColorRect.new();back.color=Color("15191b");back.size=Vector2(1024,58);back.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(back)
	var rank=ui.game.ranks.current(int(ui.game.wallet.gp))
	ui.rank_background=Art.sprite(self,rank.background,Vector2(8,9),Vector2(32,32));ui.rank_image=Art.sprite(self,rank.asset,Vector2(8,9),Vector2(32,32));ui.last_rank_gp=-1
	ui.profile_label=ui.text(self,ui.game.profile_name,Vector2(46,3),Vector2(224,18),13)
	ui.gp_header_bar=SourceProgress.new();ui.gp_header_bar.show_percentage=false;ui.gp_header_bar.add_theme_font_size_override("font_size",1);add_child(ui.gp_header_bar)
	var base=StyleBoxFlat.new();base.bg_color=Color("333a3d");ui.gp_header_bar.add_theme_stylebox_override("background",base)
	var fill=StyleBoxFlat.new();fill.bg_color=Color("89989a");ui.gp_header_bar.add_theme_stylebox_override("fill",fill)
	ui.gp_header_bar.position=Vector2(46,25);ui.gp_header_bar.size=Vector2(224,7)
	ui.gp_header_label=ui.text(self,"",Vector2(46,35),Vector2(224,16),10,Color("bfc7c9"))
	ui.wallet_label=Control.new();ui.wallet_label.name="CurrencyPanel";ui.wallet_label.position=Vector2(285,2);ui.wallet_label.size=Vector2(139,54);add_child(ui.wallet_label)
	for i in range(4):
		ui.text(ui.wallet_label,["ALTIN:","KP:","NAKİT:","JT:"][i],Vector2(2,i*13),Vector2(49,13),10,Color("c2c8ca"))
		var value=ui.text(ui.wallet_label,"",Vector2(51,i*13),Vector2(83,13),10);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;ui.currency_values[["gold","kp","cash","jt"][i]]=value
	var entries=[["Etkinlikler","events","event"],["Sıralama","ranking","ranking"],["Mağaza","Mağaza","shop"],["Envanter","Envanter","inven"],["Klan","clan","pride"],["Hediyeler","gifts","gift"],["Arkadaşlar","friends","msg"],["Profil","profile","record"],["Web","web","web"],["Ayarlar","Ayarlar","option"],["Geri","back","back"]]
	for i in range(entries.size()):
		var entry=entries[i];var button=Art.icon_button(self,"wt_interface/all/a_lb_icon_%s.dtx" % entry[2],Vector2(650+i*33,4),entry[0],func():
			if entry[1]=="back":ui.go_back()
			else:ui.navigate(entry[1]))
		if entry[2]=="pride":
			button.texture_normal=null;button.texture_hover=null;button.texture_pressed=null;button.texture_disabled=null
			Art.sprite(button,"wt_interface/all/a_lb_icon_pride.dtx",Vector2(4,0),Vector2(24,24),Rect2(68,0,32,32))
			var caption=ui.text(button,"KLAN",Vector2(0,23),Vector2(32,9),7,Color("aab6b9"));caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.size=Vector2(32,32);button.stretch_mode=TextureButton.STRETCH_SCALE;ui.links[entry[0]]=button;buttons.append(button)
		if entry[1]==ui.page:button.self_modulate=Color("ffe36a")
		if entry[1]=="gifts" and ui.game.inbox.pending_count()>0:ui.text(button,str(ui.game.inbox.pending_count()),Vector2(27,0),Vector2(20,14),10,Art.GOLD)
	var more=preload("res://ui/touch_button.gd").new();more.position=Vector2(602,9);more.size=Vector2(29,36);more.ignore_texture_size=true;more.tooltip_text="Bot ve maç ayarları" if ui.page in ["create_room","room"] else "Diğer menüler";add_child(more);more.pressed.connect(ui.choose_section);ui.links["Diğer"]=more;buttons.append(more)
	for i in range(3):
		var line=ColorRect.new();line.position=Vector2(6,9+i*7);line.size=Vector2(17,2);line.color=Color("b4c0c3");line.mouse_filter=Control.MOUSE_FILTER_IGNORE;more.add_child(line)
	var power=Button.new();power.hide();add_child(power);power.pressed.connect(func():ui.navigate("power"));ui.links["Güç"]=power
	set_meta("source_canvas",Vector2(1024,768));set_meta("source_header_height",58)
func nearest(point):
	var best=null;var distance=INF
	for button in buttons:
		if not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:continue
		var local=button.get_global_transform_with_canvas().affine_inverse()*point
		if not button.target_rect().has_point(local):continue
		var value=point.distance_squared_to(button.get_global_rect().get_center())
		if value<distance:best=button;distance=value
	return best
func _input(event):
	if not is_visible_in_tree() or ui.modal!=null:return
	# Godot also synthesizes a mouse release for touch. Only the owned touch
	# sequence may invoke a toolbar action; otherwise a canceled drag can click.
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		if nearest(event.position)!=null:get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_owner>=0:return
			var button=nearest(event.position)
			if button==null:return
			touch_owner=event.index;pressed_button=button;origin=event.position;get_viewport().set_input_as_handled()
		elif event.index==touch_owner:
			var button=pressed_button;touch_owner=-1;pressed_button=null;get_viewport().set_input_as_handled()
			var pixels=get_viewport().get_final_transform().get_scale().abs()
			if is_instance_valid(button) and nearest(event.position)==button and ((event.position-origin)*pixels).length()<18:button.pressed.emit()
	elif event is InputEventScreenDrag and event.index==touch_owner:
		if event.position.distance_to(origin)>18:pressed_button=null
func _notification(what):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:touch_owner=-1;pressed_button=null
