extends RefCounted
const Art=preload("res://ui/source_theme.gd")
var ui
func build(view):
	var data=ui.game.local_room;var slots=clampi(int(data.get("capacity",16))/2,1,8)
	for team in ["red","blue"]:
		var old=view.find_widget("RedTeam" if team=="red" else "BlueTeam");old.hide()
		var column=Control.new();column.name="RoomRoster"+team;column.position=old.position;column.size=Vector2(294,352);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(column)
		var members=[]
		if team==data.team:members.append({"name":ui.game.profile_name,"owner":true,"bot":false})
		for i in range(ui.game.bot_limit(team)):
			var identity=ui.game.bot_roster.identity(ui.game,team,i);members.append({"name":identity.name,"owner":false,"bot":true,"id":identity.id,"characterId":identity.characterId,"weaponId":identity.weaponId})
		for i in range(8):
			var host=Button.new();host.flat=true;host.disabled=true;host.position=Vector2(0,i*44);host.size=Vector2(294,44);column.add_child(host)
			var backing=ColorRect.new();backing.size=host.size;backing.color=Color(.055,.065,.075,.88);backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;host.add_child(backing)
			var row=ui.native("interface/fielduserbutton",host,Vector2.ZERO,Vector2(294,44));row.show_only(["NickName","UserState"])
			var bar=row.find_widget("UserState");bar.texture=Art.atlas("wt_interface/battleroom/br_bar_"+team+".dtx",Rect2(0,88 if i>=slots else 0,294,44));bar.modulate=Color.WHITE
			if i>=members.size():row.set_value("NickName","");continue
			var member=members[i];host.set_meta("room_member",member.duplicate());row.set_value("NickName",member.name)
			var state="master" if member.owner else "ready"
			Art.sprite(row,"wt_interface/battleroom/br_bar_"+state+"_"+team+".dtx",Vector2.ZERO,Vector2(294,44),Rect2(0,0,294,44))
			# Re-add text above the native state overlay. Bot status is local, never a fake rank/ping.
			row.move_child(row.find_widget("NickName"),row.get_child_count()-1)
			if member.owner:
				host.disabled=false;host.tooltip_text="Oda sahibi · Oyuncu bilgileri";host.pressed.connect(func():ui.navigate("profile"))
				var rank=ui.game.ranks.current(int(ui.game.wallet.gp));Art.sprite(host,rank.asset,Vector2(40,8),Vector2(28,28));row.find_widget("NickName").add_theme_color_override("font_color",Art.GOLD)
			else:
				ui.text(host,"BOT",Vector2(40,13),Vector2(33,18),11,Color("b8c9cf"));ui.text(host,"HAZIR",Vector2(79,5),Vector2(175,15),10,Color("b8c9cf"))
