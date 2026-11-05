extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Card=preload("res://ui/source_item_card.gd")
var ui
func build():
	if ui.page=="missions":missions()
	else:pass_page()
func claim(id):
	var result=ui.game.claim_career(id)
	if result.ok:ui.refresh()
	else:ui.show_error(result.error)
func missions():
	var view=ui.native("interface/wolfpass/wolfpassmissiondlg",ui.content,Vector2(110,100),Vector2(805,568));view.show_only(["MissionDlgbackGround","OKButton"]);view.bind_action("OKButton",ui.go_back)
	ui.text(ui.content,"YEREL GÖREVLER",Vector2(140,151),Vector2(740,35),24,Art.GOLD)
	var index=0
	for mission in ui.game.career.MISSIONS:
		var at=Vector2(130,211+index*68);var done=ui.game.career.state.claimed.get(mission.id,false);var count=int(ui.game.career.state.totals[mission.stat])
		var row=Card.create(ui.content,at,Vector2(765,62),func():pass);row.disabled=true
		ui.text(row,mission.name,Vector2(12,6),Vector2(540,25),17)
		ui.text(row,"%d / %d · %d yerel nakit" % [mini(count,int(mission.goal)),int(mission.goal),int(mission.cash)],Vector2(12,33),Vector2(540,23),13)
		ui.button(ui.content,"Alındı" if done else "Ödülü al",at+Vector2(588,17),Vector2(162,30),func():claim(mission.id),not done and count>=int(mission.goal));index+=1
	ui.text(ui.content,"Bu cihazdaki ilerleme · Görevler bir kez ödül verir",Vector2(140,570),Vector2(740,25),13)
func pass_page():
	var view=ui.native("interface/wolfpass/wolfpassdlg",ui.content,Vector2(37,66),Vector2(950,750));view.scale.y=0.9
	view.show_only(["backGround","WolfPassImg","WolfPassSeasonName","WolfPassSeasonDate","WolfPassGuidePopUpBtn","OKButton","WolfPremiumPassBuyBtn","PassMissionButton","WolfPassExpBG","EXPGageBG","EXPGage","EXPText","Level","PrevButton","NextButton","PassRewardLevelBG","PassRewardFree","PassRewardPremium"])
	view.set_value("WolfPassSeasonName","YEREL WOLF PASS");view.set_value("WolfPassSeasonDate","Süre sınırı olmayan yerel deneme");view.set_value("Level",mini(10,int(ui.game.wallet.gp)/100));view.set_value("EXPText","%d GP" % int(ui.game.wallet.gp))
	view.find_widget("EXPGage").hide();view.find_widget("EXPGageBG").hide()
	var gauge=ProgressBar.new();gauge.position=Vector2(8,21);gauge.size=Vector2(222,11);gauge.show_percentage=false
	gauge.value=100 if int(ui.game.wallet.gp)>=1000 else int(ui.game.wallet.gp)%100;view.find_widget("WolfPassExpBG").add_child(gauge)
	view.bind_action("OKButton",ui.go_back);view.bind_action("PassMissionButton",func():ui.navigate("missions"))
	view.bind_action("WolfPassGuidePopUpBtn",func():ui.confirm("Yerel Wolf Pass","Her 100 yerel GP bir seviyedir. Ücretsiz ödüller bir kez alınır. PC sezon ödül tablosu ve Premium hesabı bu sürüme bağlı değildir.",func():pass))
	view.bind_action("WolfPremiumPassBuyBtn",func():ui.show_error("Premium hesap hizmeti bağlı değil; satın alma yapılmadı."))
	for i in range(1,6):
		var level=ui.pass_page*5+i;var at=Vector2(98+(i-1)*168,443);var id="pass-%d" % level
		for name in ["PassRewardLevelNum%d"%i,"PassRewardLevel%d"%i,"FreeWolfPassItemButton%d"%i,"PremiumWolfPassItemButton%d"%i]:
			var widget=view.find_widget(name)
			if widget:widget.show()
		view.set_value("PassRewardLevel%d"%i,level)
		var button=view.find_widget("FreeWolfPassItemButton%d"%i);var done=ui.game.career.state.claimed.get(id,false)
		view.bind_action("FreeWolfPassItemButton%d"%i,func():claim(id));button.disabled=done or int(ui.game.wallet.gp)<level*100
		ui.text(button,"%d yerel nakit\n%s" % [50+level*5,"Alındı" if done else "Ödülü al"],Vector2(7,23),Vector2(154,60),16).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var premium=view.find_widget("PremiumWolfPassItemButton%d"%i);premium.disabled=true
		ui.text(premium,"Çevrimiçi Premium",Vector2(7,33),Vector2(154,45),13).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	view.bind_action("PrevButton",func():ui.pass_page=maxi(0,ui.pass_page-1);ui.refresh());view.bind_action("NextButton",func():ui.pass_page=mini(1,ui.pass_page+1);ui.refresh())
	ui.text(view,"Yerel GP ve nakit ödülleri · Özgün PC sezon fiyatı/ödül oranı değildir",Vector2(26,672),Vector2(900,24),12)
