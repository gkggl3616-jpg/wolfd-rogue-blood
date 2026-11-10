extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Rules=preload("res://scripts/source_match_rules.gd")
static func values(game,room):
	var rules=Rules.new();rules.configure(room)
	var mode=int(room.get("mode",0));var title=game.map_catalog.mode_name(mode)
	if mode==0:title="Botlu Eğitim"
	elif mode==game.WOLF_BATTLE:title="Kurt Savaşı"
	elif mode==game.LocalHunt.MODE:title="Kurt Avı"
	elif mode==game.LocalTutorial.MODE:title="Öğretici Mod"
	return {"mode":title.get_slice(" · ",0).trim_suffix(" Modu"),"map":"Eğitim Arenası" if int(room.get("map",0))==0 else game.map_catalog.map_record(int(room.map)).get("displayName",""),"capacity":"%d Oyuncu" % int(room.get("capacity",16)),"goal":("%d %s" % [rules.goal,"Kazanma" if rules.round_based else "Puan"]) if rules.enabled else ("3 Raunt" if mode==game.LocalHunt.MODE else "10 Hedef"),"time":"%d:%02d" % [rules.seconds/60,rules.seconds%60],"weapon":"Ağır Silahsız" if mode in [1000,3000,3020] else (rules.title() if mode in [1022,1023,1024,1025,1026] else ("Kurt Modu" if rules.form_lock=="wolf" or mode==game.WOLF_BATTLE else "Tümü")),"form":rules.form_lock if rules.enabled else ("wolf" if mode==game.WOLF_BATTLE else "mixed"),"rounds":rules.round_based}
static func bind(game,view,room,lobby=false):
	var data=values(game,room)
	view.set_value("CurrentRoomName" if lobby else "FieldName",room.get("title","Yerel Oda"));view.set_value("CurrentMapName" if lobby else "MapName",data.map)
	for pair in [["GameMode","mode"],["MaxChars","capacity"],["MissionObject","goal"],["RoundTime","time"],["WeaponOptionText","weapon"]]:view.set_value(pair[0],data[pair[1]])
	var option=view.find_widget("GameOption")
	if option:
		var names={1000:"noheavy",1001:"normal",1010:"normal",1020:"normal",1021:"normal",1022:"granade",1023:"knife",1024:"pistol",1025:"sniper",1026:"heavy",3000:"noheavy",3001:"normal",3020:"noheavy",3021:"normal"}
		option.texture=Art.atlas("wt_interface/makeroom/mr_mode_"+str(names.get(int(room.get("mode",0)),"normal"))+".dtx",Rect2(0,0,26,26))
	var weapon=view.find_widget("WeaponOptionImg")
	if weapon:weapon.texture=option.texture if option else null
	for pair in [["DownClassLimit",0],["UpClassLimit",game.ranks.catalog.ranks.size()-1]]:
		var emblem=view.find_widget(pair[0])
		if emblem:emblem.texture=Art.texture(game.ranks.catalog.ranks[pair[1]].asset);emblem.tooltip_text="Rütbe sınırı yok"
	var picture=view.find_widget("CurrentMap")
	if picture:picture.texture=Art.map_photo(game.map_catalog,int(room.get("map",0)))
	if not lobby:view.set_value("Password","••••" if room.get("passwordDigest","")!="" else "")
	for name in ["RedTeamType","BlueTeamType"]:
		var icon=view.find_widget(name)
		if icon:icon.texture=Art.atlas("wt_interface/makeroom/mr_mode_"+("w" if data.form=="wolf" else ("h_w" if data.form=="mixed" else "h"))+("_r.dtx" if name=="RedTeamType" else "_b.dtx"),Rect2(0,0,26,26))
	var role=view.find_widget("TeamRoleChangeOption" if lobby else "TeamChangeRoleOption")
	if role:role.texture=Art.atlas("wt_interface/all/a_check.dtx",Rect2(0,38 if data.rounds and room.get("swapRoles",true) else 0,18,18))
	for name in ["GamingEnter","Observe"]:
		var flag=view.find_widget(name)
		if flag:flag.texture=Art.atlas("wt_interface/all/a_check.dtx",Rect2(0,0,18,18))
static func visible_fields(lobby=false):
	return ["CurrentMap","CurrentMapName","CurrentRoomName","GameMode","GameOption","RedTeamType","VS","BlueTeamType","WeaponOptionImg","WeaponOptionText","DownClassLimit","UpClassLimit","MissionObject","RoundTime","MaxChars","TeamRoleChangeOption","GamingEnter","Observe"] if lobby else ["Password","GameOption","RedTeamType","VS","BlueTeamType","WeaponOptionImg","WeaponOptionText","DownClassLimit","UpClassLimit","TeamChangeRoleOption","GamingEnter","Observe"]
