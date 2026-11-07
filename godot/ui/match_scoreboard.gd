extends Control
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const VideoLayout=preload("res://scripts/video_layout.gd")
var game
var manual=false
var canvas
var panel
var rows={}
var scores={}
var reward_values=[]
var signature=""
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=50
	resized.connect(arrange);build()
func auto_showing():
	var d=game.destruction
	return d.enabled and d.phase=="between" and d.wait<=maxf(0,float(d.tuning.betweenRoundsSeconds)-1.0)
func build():
	for child in get_children():remove_child(child);child.queue_free()
	rows.clear();scores.clear();reward_values.clear()
	canvas=Control.new();canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(canvas)
	var at=VideoLayout.SCOREBOARD
	Art.sprite(canvas,"wt_interface/gamestatewindow/pl_tab_back.dtx",at,Vector2(780,512),Rect2(0,0,780,512))
	panel=Layout.new();canvas.add_child(panel);panel.configure("interface/gamestatewindow",Vector2(780,512));panel.position=at
	panel.show_only(["RoomTitle","ChannelName","CurrentMission","RedTeam","BlueTeam"])
	for team in ["red","blue"]:
		var x=6 if team=="red" else 389
		Art.sprite(canvas,"wt_interface/gamestatewindow/pl_tab_"+team+"_back.dtx",at+Vector2(x,30),Vector2(381,56),Rect2(0,0,381,56))
		var score=Art.label("0",Vector2(40,24),20);score.position=at+Vector2(352 if team=="red" else 395,34);score.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;canvas.add_child(score);scores[team]=score
	for y in [422,444,468,490]:
		var number=Art.label("0",Vector2(140,18),12);number.position=at+Vector2(200,y);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;canvas.add_child(number);reward_values.append(number)
	Art.sprite(canvas,"wt_interface/gamestatewindow/pl_tab_icon_guide.dtx",at+Vector2(0,530),Vector2(780,32),Rect2(0,0,780,32))
	arrange();signature="";refresh_rows()
func arrange():
	if not is_instance_valid(canvas):return
	canvas.size=Vector2(1024,768);canvas.scale=get_viewport_rect().size/Vector2(1024,768)
func refresh_rows():
	var roster=game.match_roster.values().filter(func(r):return not r.get("removed",false))
	var current=JSON.stringify(roster.map(func(r):return [r.id,r.team]))
	if current!=signature:
		for row in rows.values():row.queue_free()
		rows.clear();signature=current
		for team in ["red","blue"]:
			var members=roster.filter(func(r):return r.team==team)
			for i in range(members.size()):
				var row=Layout.new();canvas.add_child(row);row.configure("interface/gameuserinfo",Vector2(375,35));row.position=VideoLayout.SCOREBOARD+Vector2(9 if team=="red" else 392,86+i*35)
				row.show_only(["BackGround","UserNumber","NickName","Point","Dead","slash"]);row.set_value("UserNumber",i+1);rows[members[i].id]=row
	for member in roster:
		if member.id=="player":member.kills=game.kills;member.deaths=game.deaths
		var row=rows[member.id];row.set_value("NickName",member.name);row.set_value("Point",member.kills);row.set_value("Dead",member.deaths)
		row.find_widget("NickName").add_theme_color_override("font_color",Color(.8,.8,.8))
		var alive=game.health>0 if member.id=="player" else game.enemies.get_children().any(func(bot):return game.actor_alive(bot) and bot.roster_id==member.id)
		row.modulate=Color.WHITE if alive else Color(.55,.55,.55,1)
	panel.set_value("RoomTitle",game.local_room.get("title","Yerel Oda"));panel.set_value("ChannelName",game.preview_name);panel.set_value("CurrentMission",("Yıkım · %d Kazanma" % game.destruction.limit) if game.destruction.enabled else "%d Puan" % game.target_score())
	for team in scores:scores[team].text=str(game.destruction.wins[team] if game.destruction.enabled else game.team_score(team))
	var start=game.match_wallet_start
	reward_values[0].text=str(maxi(0,int(game.wallet.gold)-int(start.get("gold",game.wallet.gold))))
	reward_values[1].text=str(maxi(0,int(game.wallet.gp)-int(start.get("gp",game.wallet.gp))))
	reward_values[2].text=str(int(game.wallet.gold));reward_values[3].text="—"
func _process(_delta):
	visible=game.running and not game.menu_open and not game.application_suspended and not game.selection_active and (manual or auto_showing())
	if visible:refresh_rows()
