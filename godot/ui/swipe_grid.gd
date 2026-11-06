extends Control
var page
var finger=-1
var start=Vector2.ZERO
var start_scroll=0.0
var scroll=0.0
var dragging=false
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _input(event):
	if page==null or not is_instance_valid(page.ui):return
	if page.ui.modal!=null:
		finger=-1;dragging=false;return
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger>=0 or not get_global_rect().has_point(event.position):return
			finger=event.index;start=event.position;start_scroll=scroll;dragging=false;get_viewport().set_input_as_handled()
		elif event.index==finger:
			if not dragging:
				for cell in page.grid.get_children():
					if cell is BaseButton and not cell.disabled and cell.get_global_rect().has_point(event.position):cell.button_pressed=true;cell.pressed.emit();break
			finger=-1;dragging=false;get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==finger:
		var travel=(event.position.y-start.y)/maxf(0.1,page.ui.canvas.scale.y*page.ui.content.scale.y)
		if absf(travel)>12:dragging=true
		if dragging:page.scroll_to(start_scroll-travel)
		get_viewport().set_input_as_handled()
