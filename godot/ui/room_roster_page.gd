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
			var row=ui.native("interface/fielduserbutton",host,Vector2.ZERO,Vector2(294,44));row.show_only(["NickName","UserState"])
			var bar=row.find_widget("UserState");bar.texture=Art.atlas("wt_interface/battleroom/br_bar_"+team+".dtx",Rect2(0,88 if i>=slots else 0,294,44));bar.modulate=Color.WHITE
			if i<slots:bar.modulate.a=.64
			if i>=members.size():row.set_value("NickName","");continue
			var member=members[i];host.set_meta("room_member",member.duplicate());row.set_value("NickName",member.name)
			Art.sprite(row,"wt_interface/battleroom/br_bar_deco.dtx",Vector2.ZERO,Vector2(294,44),Rect2(0,0,294,44)).modulate.a=.20
			if member.owner:
				Art.sprite(row,"wt_interface/battleroom/br_bar_master_"+team+".dtx",Vector2(74,7),Vector2(37,25),Rect2(74,0,48,34))
			# Re-add text above the native state overlay. Bot status is local, never a fake rank/ping.
			row.move_child(row.find_widget("NickName"),row.get_child_count()-1)
			if member.owner:
				host.disabled=false;host.tooltip_text="Oda sahibi · Oyuncu bilgileri";host.pressed.connect(func():ui.navigate("profile"))
				var rank=ui.game.ranks.current(int(ui.game.wallet.gp));Art.sprite(host,rank.asset,Vector2(40,8),Vector2(28,28));row.find_widget("NickName").add_theme_color_override("font_color",Art.GOLD)
			else:
				ui.text(host,"BOT",Vector2(8,15),Vector2(30,15),10,Color("91a6a8"))
				Art.sprite(host,"wt_interface/battleroom/br_bar_status.dtx",Vector2(42,10),Vector2(32,8),Rect2(0,0,84,20))
				var character=ui.game.book.characters.filter(func(entry):return entry.id==member.characterId)
				if not character.is_empty():
					var caption=str(character[0].get("name",member.characterId))
					row.set_value("PrideName",caption.get_slice(" - ",0).get_slice("·",0).strip_edges());row.find_widget("PrideName").show();row.find_widget("PrideName").add_theme_font_size_override("font_size",12);host.tooltip_text=caption+" · Yerel bot"
				row.find_widget("NickName").add_theme_color_override("font_color",Color("d0d379") if team=="blue" else Color("dfcc75"))
