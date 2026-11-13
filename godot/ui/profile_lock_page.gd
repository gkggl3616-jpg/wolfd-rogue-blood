extends RefCounted
const Art=preload("res://ui/source_theme.gd")
var ui
var view
var digits=""
var old_pin=""
var pending_pin=""
var phase="unlock"
var remove_lock=false
var slots=[]
var notice
func build():
	var lock=ui.game.profile_lock
	phase="unlock" if not lock.unlocked else ("current" if lock.is_enabled() else "new")
	view=ui.native("interface/wolfsecondpassword",ui.content)
	view.show_only(["BackGround","Secret_0","Secret_1","Secret_2","Secret_3","CancelBtn","OKBtn","CallSignBG","CallSign_InPut"])
	var background=view.find_widget("BackGround")
	var title_plate=ColorRect.new();title_plate.color=Color("282c2c");title_plate.position=Vector2(3,3);title_plate.size=Vector2(390,23);background.add_child(title_plate)
	ui.text(background,"YEREL PROFİL ŞİFRESİ",Vector2(12,5),Vector2(370,24),17)
	notice=ui.paragraph(background,"",Vector2(20,37),Vector2(354,54),13)
	for i in range(4):
		var label=ui.text(background,"",Vector2(15+i*92,119),Vector2(89,55),35);label.hide();slots.append(label)
	var keypad_plate=ColorRect.new();keypad_plate.color=Color("515756");keypad_plate.position=Vector2(19,207);keypad_plate.size=Vector2(362,130);background.add_child(keypad_plate)
	var numbers=["0","1","2","3","4","5","6","7","8","9"];numbers.shuffle();numbers.append_array(["←","Sil"])
	for i in range(numbers.size()):
		var value=numbers[i]
		var button=Art.atlas_button(background,"wt_interface/password/pw_numbar.dtx",[Rect2(0,0,60,60),Rect2(0,64,60,60),Rect2(0,128,60,60)],Vector2(20+(i%6)*60,211+int(i/6)*53),Vector2(56,46),func():press(value))
		ui.text(button,value,Vector2(0,7),Vector2(56,36),23,Color("313838")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		ui.links[value]=button
	view.bind_action("OKBtn",submit);view.bind_action("CancelBtn",func():ui.go_back() if lock.unlocked else ui.navigate("entry"))
	ui.links.PIN_OK=view.find_widget("OKBtn")
	var callsign=view.find_widget("CallSign_InPut");callsign.editable=false;callsign.text=ui.game.profile_name
	ui.text(background,"Bu cihazdaki profil · İsteğe bağlı kilit",Vector2(25,352),Vector2(345,24),12)
	if lock.unlocked and lock.is_enabled():
		ui.button(background,"Kilidi kaldır",Vector2(24,415),Vector2(345,26),func():remove_lock=true;phase="current";digits="";refresh())
	refresh()
func press(value):
	if value=="Sil":digits=""
	elif value=="←":digits=digits.left(maxi(0,digits.length()-1))
	elif digits.length()<4:digits+=value
	refresh()
func refresh():
	for i in range(slots.size()):view.find_widget("Secret_%d" % i).visible=i<digits.length()
	var captions={"unlock":"Devam etmek için 4 haneli şifreni gir.","current":"Mevcut şifreni gir.","new":"Yeni 4 haneli şifreni seç.","repeat":"Yeni şifreni tekrar gir."}
	notice.text="Şifre kaydı okunamadı; mevcut kayıt korunuyor." if ui.game.profile_lock.blocked else captions[phase]
func submit():
	var lock=ui.game.profile_lock
	if not lock.valid_pin(digits):notice.text="Dört rakam gerekli.";return
	if phase in ["unlock","current"]:
		if not lock.verify(digits):digits="";refresh();notice.text="Şifre yanlış veya bekleme süresi etkin.";return
		if phase=="unlock":digits="";ui.navigate("servers");return
		if remove_lock:
			if lock.disable(digits):digits="";ui.go_back()
			else:notice.text="Kilit değişikliği kaydedilemedi."
			return
		old_pin=digits;digits="";phase="new"
	elif phase=="new":pending_pin=digits;digits="";phase="repeat"
	else:
		if digits!=pending_pin:digits="";pending_pin="";phase="new";refresh();notice.text="Şifreler eşleşmedi; yeniden seç.";return
		if lock.configure(digits,old_pin):digits="";pending_pin="";old_pin="";ui.go_back();return
		notice.text="Şifre kaydedilemedi; önceki kilit korunuyor.";return
	refresh()
