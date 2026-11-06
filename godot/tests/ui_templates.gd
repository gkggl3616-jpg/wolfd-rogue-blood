extends SceneTree
const Layout=preload("res://ui/source_layout.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func ensure(value,description):
	checks+=1
	if not value:failures+=1;push_error("UI_TEMPLATE_FAIL "+description)
func run():
	var data=Layout.read_catalog()
	ensure(data.layouts.size()==365,"all 365 source layouts are present")
	var widgets=0
	var unresolved=[]
	var kinds={}
	for id in data.layouts:
		var view=Layout.new();view.textures_enabled=false;root.add_child(view)
		ensure(view.configure(id),"layout configures: "+id)
		widgets+=view.controls.size()
		ensure(view.unsupported_types.is_empty(),"no silent unsupported widget types in "+id)
		for i in range(view.records.size()):
			var record=view.records[i];var node=view.controls[i];kinds[record.type.to_lower()]=true
			ensure(node.get_meta("adapter","")!="","explicit adapter for "+record.name)
			var parent=record.get("parentIndex")
			if parent!=null:ensure(node.get_parent()==view.controls[int(parent)],"exact source parent binding: "+record.name)
			elif not str(view.field(record,"parent","")).is_empty():ensure(not node.visible,"unresolved parents stay hidden rather than guessed")
		for row in view.unresolved_parents:unresolved.append({"layout":id,"parent":row.parent,"widget":row.widget})
		root.remove_child(view);view.free()
	ensure(widgets==4934,"all source records create runtime controls")
	ensure(kinds.size()==99,"all 99 native widget types have adapters")
	ensure(unresolved.size()==1 and unresolved[0].layout=="section/shop" and unresolved[0].parent=="30001","only unproved cross-screen Display/30001 remains explicit")
	var options=Layout.new();options.textures_enabled=false;root.add_child(options);options.configure("interface/graphicpropertypage")
	ensure(options.caption(options.find_widget("HIGH QUALITY").get_meta("source_record"))=="Yüksek","UI caption 705 is not resolved from tooltip table")
	var source_slider=options.find_widget("Gamma")
	ensure(source_slider is Range and source_slider.has_method("set_at"),"source sliders have actual range/drag behavior")
	source_slider.editable=true;source_slider.set_at(Vector2(source_slider.size.x*0.5,0))
	ensure(is_equal_approx(source_slider.value,50),"source slider maps pointer position to declared range")
	options.queue_free();await process_frame
	print("UI_TEMPLATES_QA checks=%d failures=%d widgets=%d types=%d unresolved=%d" % [checks,failures,widgets,kinds.size(),unresolved.size()])
	quit(0 if failures==0 else 1)
