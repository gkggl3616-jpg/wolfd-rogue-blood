extends Control
const Art=preload("res://ui/source_theme.gd")
var game
var kind="human"
var remaining=10.0
var caption
var canvas
var card_buttons=[]
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=45
	resized.connect(build);build()
func build():
	for child in get_children():remove_child(child);child.queue_free()
	card_buttons.clear();canvas=Control.new();canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.size=Vector2(1024,768);canvas.scale=get_viewport_rect().size/Vector2(1024,768);add_child(canvas)
	caption=Art.label("",Vector2(960,36),18,Color("c29346"));caption.position=Vector2(32,315);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;canvas.add_child(caption)
	var values=["normal","power","guardian","ghost"] if kind=="wolf" else [1,2,3,4]
	for i in range(4):
		var value=values[i];var button=Button.new();button.position=Vector2(15+i*250,357);button.size=Vector2(244,194);button.flat=false;button.theme=Art.theme();canvas.add_child(button);card_buttons.append(button)
		var style=StyleBoxFlat.new();style.bg_color=Color(0.015,0.015,0.015,0.81);style.border_color=Color("895b32");style.set_border_width_all(2);button.add_theme_stylebox_override("normal",style)
		var label=Art.label("",Vector2(218,29),16,Color("c6a769"));label.position=Vector2(12,4);button.add_child(label)
		var cost=Art.label("0",Vector2(25,28),15,Color("c6a769"));cost.position=Vector2(211,4);button.add_child(cost)
		if kind=="human":
			cost.text=str(game.loadout_sp_cost(value));button.disabled=game.loadout_sp_cost(value)>game.match_sp
			label.text=game.book.loadout_names[value];var lines=[]
			for slot in ["primary","secondary_primary","pistol","knife","grenade"]:
				var entry=game.book.weapon(game.book.loadouts[value].get(slot,""))
				if not entry.is_empty():lines.append(entry.name)
			var copy=Art.label("\n".join(lines),Vector2(223,145),14,Color("c6a769"));copy.position=Vector2(10,40);button.add_child(copy)
			button.pressed.connect(func():game.choose_round_loadout(value))
		else:
			var profile=game.mutations.profile(value);label.text=profile.name;cost.text="0" if value=="normal" else "100";button.disabled=value!="normal" and game.match_sp<100
			var icon="res://assets/mutations/normal-blue.png" if value=="normal" else game.mutations.model(value,game.local_room.get("team","blue")).get("portrait","")
			Art.sprite(button,icon,Vector2(116,37),Vector2(123,151)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			for row in range(4):
				var title=Art.label(["GÜÇ","ENERJİ","BAĞIR","HIZ"][row],Vector2(92,22),13,Color("bba982"));title.position=Vector2(10,45+row*27);button.add_child(title)
				for n in range(int(profile.bars[row])):
					var bar=ColorRect.new();bar.color=Color("b67b36");bar.position=Vector2(90+n*7,53+row*27);bar.size=Vector2(5,10);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(bar)
			if profile.guard or profile.cloak:
				var ability=Art.label("SAVUNMA" if profile.guard else "SAKLAN",Vector2(105,22),12,Color("bba982"));ability.position=Vector2(10,159);button.add_child(ability)
			button.pressed.connect(func():game.choose_round_mutation(value))
	var standard=Art.button(canvas,"Standart" if kind=="human" else "Mevcut seçimle devam",Vector2(337,573),Vector2(350,34),func():game.choose_round_loadout(0) if kind=="human" else game.finish_round_selection())
	standard.tooltip_text="Standart ekipman ücretsiz. Diğer setlerin SP bedeli yerel uyarlamadır."
func _process(delta):
	visible=game.running and not game.menu_open
	if not game.running:game.close_round_selection();return
	if game.menu_open or game.application_suspended:return
	remaining=maxf(0,remaining-delta)
	caption.text=("Mutasyon Seçimi: Bu rauntta kullanacağınız kurt türünü seçin. " if kind=="wolf" else "Ekipman Seçimi: Bu rauntta kullanacağınız ekipman setini seçin. ")+str(ceili(remaining))
	if remaining<=0:game.finish_round_selection()
