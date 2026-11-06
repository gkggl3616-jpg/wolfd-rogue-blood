extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
static func create(parent,at,dimensions,callback):
	var factory=Layout.new();var template=Art.catalog().layouts["interface/equiplistbox"].widgets[1]
	var node=factory.create_widget(template);factory.free();node.position=at;node.size=dimensions;node.disabled=false;parent.add_child(node);node.pressed.connect(callback)
	return node
