extends RefCounted
const Art=preload("res://ui/source_theme.gd")
var ui
func build(view):
	var data=ui.game.local_room;var slots=clampi(int(data.get("capacity",16))/2,1,8)
	for team in ["red","blue"]:
		var old=view.find_widget("RedTeam" if team=="red" else "BlueTeam");old.hide()
		var scroll=ScrollContainer.new();scroll.name="RoomRoster"+team;scroll.position=old.position;scroll.size=old.size;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;ui.content.add_child(scroll)
		var column=VBoxContainer.new();column.add_theme_constant_override("separation",0);column.custom_minimum_size.x=294;scroll.add_child(column)
		var members=[]
		if team==data.team:members.append({"name":ui.game.profile_name,"owner":true,"bot":false})
		for i in range(ui.game.bot_limit(team)):members.append({"name":"BOT %d" % (i+1),"owner":false,"bot":true})
		for i in range(8):
			var host=Button.new();host.flat=true;host.disabled=true;host.custom_minimum_size=Vector2(294,44);column.add_child(host)
			var row=ui.native("interface/fielduserbutton",host,Vector2.ZERO,Vector2(294,44));row.show_only(["NickName","UserState"])
			var bar=row.find_widget("UserState");bar.texture=Art.atlas("wt_interface/battleroom/br_bar_"+team+".dtx",Rect2(0,88 if i>=slots else 0,294,44))
			bar.modulate=Color.WHITE if i>=slots else (Color("692e39") if team=="red" else Color("264f62"))
			if i>=members.size():row.set_value("NickName","");continue
			var member=members[i];host.set_meta("room_member",member.duplicate());row.set_value("NickName",member.name)
			ui.text(host,"ODA SAHİBİ" if member.owner else "BOT · HAZIR",Vector2(79,5),Vector2(175,15),10,Art.GOLD if member.owner else Color("a9bdc4"))
			if member.owner:
				host.disabled=false;host.tooltip_text="Oyuncu bilgileri";host.pressed.connect(func():ui.navigate("profile"))
				var rank=ui.game.ranks.current(int(ui.game.wallet.gp));Art.sprite(host,rank.asset,Vector2(40,8),Vector2(28,28))
			else:ui.text(host,"BOT",Vector2(39,12),Vector2(32,20),10)
