extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const VideoLayout=preload("res://scripts/video_layout.gd")
class RoomCountdown extends Control:
	var game
	var digits
	var go
	func _ready():
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=100
		digits=Art.texture("wt_interface/battleroom/br_loading_num.dtx");go=Art.texture("wt_interface/battleroom/br_loading_num_go.dtx")
	func _process(_delta):
		visible=game.match_flow.phase=="countdown";queue_redraw()
	func _draw():
		var left=game.match_flow.countdown
		var center=VideoLayout.ROOM_COUNTDOWN
		if left<=.5:
			if go!=null:draw_texture_rect_region(go,Rect2(center-Vector2(32,16),Vector2(64,32)),Rect2(0,0,64,32))
		elif digits!=null:draw_texture_rect_region(digits,Rect2(center-Vector2(14,22),Vector2(28,44)),Rect2(0,(clampi(ceili(left-.5),1,3)-1)*50,24,48))
var ui
func countdown():
	var node=RoomCountdown.new();node.game=ui.game;ui.canvas.add_child(node)
func loading():
	var flow=ui.game.match_flow;var data=flow.room_snapshot
	var view=ui.native("section/load",ui.content)
	view.show_only(["MapAirView","ModeInfoBg","ModeText","ModeName","MissionText","Mission","CharacterText","Character"])
	view.find_widget("MapAirView").texture=Art.atlas(flow.loading_art(),Rect2(0,0,1024,768))
	var name="Eğitim Arenası" if int(data.get("map",0))==0 else ui.game.map_catalog.map_record(int(data.map)).get("displayName","")
	ui.text(ui.content,name,Vector2(513,322),Vector2(511,69),30,Art.GOLD)
	var rules=preload("res://scripts/source_match_rules.gd").new();rules.configure(data)
	view.set_value("ModeName",ui.game.map_catalog.mode_name(int(data.get("mode",0))) if rules.enabled else ("Kurt Savaşı" if int(data.get("mode",0))==ui.game.WOLF_BATTLE else "Yerel Eğitim"))
	view.set_value("Mission",("%d Kazanma" % rules.goal) if rules.round_based else "%d Puan" % rules.goal)
	view.set_value("Character","İnsan / Kurt" if rules.form_lock=="mixed" else ("Kurt" if rules.form_lock=="wolf" else "İnsan"))
	ui.text(ui.content,name+" yükleniyor…",Vector2(112,703),Vector2(800,35),15).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
