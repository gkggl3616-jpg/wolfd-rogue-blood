extends TextureButton
# Preserve PC art coordinates, but offer phone-sized hit targets. Unbound,
# disabled source controls must not intercept active controls underneath them.
func close_control():return str(name).to_lower() in ["exit","exitbutton","close","closebutton"]
func target_rect():
 var pixels=(get_viewport().get_final_transform()*get_global_transform_with_canvas()).get_scale().abs()
 var screen=get_viewport().get_visible_rect().size*get_viewport().get_final_transform().get_scale().abs()
 var density=maxf(1,minf(screen.x/1280.0,screen.y/720.0))
 var minimum=Vector2.ONE*(48.0*density)/pixels
 var expanded=Vector2(maxf(size.x,minimum.x),maxf(size.y,minimum.y))
 return Rect2(Vector2(size.x-expanded.x,0),expanded) if close_control() else Rect2((size-expanded)*0.5,expanded)
func _has_point(point):return not disabled and target_rect().has_point(point)
func _draw():
 if not close_control() or disabled:return
 var area=target_rect()
 if has_meta("close_art_size"):
  var art_size=get_meta("close_art_size");area.size=area.size.min(art_size);area.position=Vector2(size.x-area.size.x,0)
 draw_style_box(close_style(),area)
 var a=area.position+area.size*0.35;var b=area.end-area.size*0.35
 draw_line(a,b,Color.WHITE,2.2,true);draw_line(Vector2(a.x,b.y),Vector2(b.x,a.y),Color.WHITE,2.2,true)
func close_style():
 var style=StyleBoxFlat.new();style.bg_color=Color("30383d");style.border_color=Color("9eabad");style.set_border_width_all(1);style.set_corner_radius_all(3);return style
