extends RefCounted
const Art = preload("res://ui/source_theme.gd")
const Layout = preload("res://ui/source_layout.gd")
var ui
var source_controls = {}
var widgets = {}

func changed(key,value):
	ui.settings_draft[key]=value;ui.settings_dirty=ui.settings_draft!=ui.game.book.settings

func apply():
	if not ui.game.book.update_settings(ui.settings_draft):
		ui.show_error("Ayarlar kaydedilemedi. Oyun tercihleri değiştirilmedi.");return false
	ui.settings_dirty=false;ui.game.apply_settings();ui.show_error("Ayarlar kaydedildi.");return true

var native_window
var native_tabs
var native_page

func build_native():
	ui.trace("interface/gameoption");ui.trace("interface/optionpropertysheet")
	if ui.settings_draft.is_empty():ui.settings_draft=ui.game.book.settings.duplicate(true)
	native_window=ui.native("interface/gameoption",ui.content,Vector2(252,128),Vector2(520,512))
	for i in range(native_window.records.size()):native_window.controls[i].visible=native_window.records[i].name in ["BackGround","Exit","Confirm"]
	native_window.bind_action("Exit",ui.go_back)
	native_window.bind_action("Confirm",func():
		if apply():ui.go_back()
	)
	native_tabs=ui.native("interface/optionpropertysheet",ui.content,Vector2(252,128),Vector2(520,512))
	for entry in [["Graphic","Görüntü"],["Control","Kontrol"],["Sound","Ses"],["TheOthers","Diğer"]]:
		var pair=entry
		native_tabs.bind_action(pair[0],func():ui.settings_tab=pair[1];ui.refresh())
	native_tabs.bind_action("Default",func():ui.confirm("Varsayılan ayarlar","Varsayılan değerleri yükle? Kaydetmek için Tamam'a bas.",func():ui.settings_draft=ui.game.book.default_settings();ui.settings_dirty=true;ui.refresh()))
	var source="interface/soundpropertypage" if ui.settings_tab=="Ses" else ("interface/controlpropertypage1" if ui.settings_tab=="Kontrol" else ("interface/theotherspropertypage" if ui.settings_tab=="Diğer" else "interface/graphicpropertypage"))
	native_page=ui.native(source,ui.content,Vector2(252,128),Vector2(520,512))
	if ui.settings_tab=="Ses":
		for entry in [["MusicVolume","MusicOff","music_volume"],["EffectVolume","EffectSoundOff","effects_volume"],["BattleVolume","BattleSoundOff","weapons_volume"],["DecisionVolume","DecisionSoundOff","ui_volume"]]:
			var row=entry
			var slider=native_page.find_widget(row[0]);var mute=native_page.find_widget(row[1])
			slider.editable=true;slider.value=float(ui.settings_draft[row[2]])*100;widgets[row[2]]=slider
			mute.disabled=false;mute.set_pressed_no_signal(float(ui.settings_draft[row[2]])<=0.001)
			slider.value_changed.connect(func(value):changed(row[2],value/100.0);mute.set_pressed_no_signal(value<=0.1))
			mute.toggled.connect(func(value):slider.value=0 if value else 100)
	elif ui.settings_tab=="Kontrol":
		var slider=native_page.find_widget("MouseSensitivity");slider.editable=true;slider.value=(float(ui.settings_draft.sensitivity)-0.2)/2.8*99+1;widgets.sensitivity=slider
		slider.value_changed.connect(func(value):changed("sensitivity",0.2+(value-1)/99.0*2.8))
		for entry in [["InvertYAxis Enable",true],["InvertYAxis Disable",false]]:
			var row=entry;var button=native_page.find_widget(row[0]);button.disabled=false;button.set_pressed_no_signal(ui.settings_draft.invert_y==row[1]);button.pressed.connect(func():changed("invert_y",row[1]))
		for control in native_page.controls:
			if control.get_meta("source_record").name=="Control":control.tooltip_text="Kaynak komut / alan kimliği eşlemesi henüz doğrulanmadı."
	elif ui.settings_tab=="Görüntü":
		for entry in [["Shadow LowQuality",true],["Shadow Disable",false]]:
			var row=entry;var button=native_page.find_widget(row[0]);button.disabled=false;button.set_pressed_no_signal(ui.settings_draft.shadows==row[1]);button.pressed.connect(func():changed("shadows",row[1]))
		var resolution=native_page.find_widget("ScreenSizeComboBox")
		resolution.disabled=false;resolution.add_item("Otomatik",0)
		resolution.tooltip_text="Kaynak PC arayüzü ekrana yayılır; 3B karakter oranı korunur."
		native_page.find_widget("Gamma").tooltip_text="Özgün gamma eğrisi doğrulanmadı; sahte ayar uygulanmaz."
	else:
		for control in native_page.controls:
			if control is LineEdit:control.editable=false;control.placeholder_text="Bağlı değil"
