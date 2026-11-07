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
	var shade=ColorRect.new();shade.position=Vector2(0,267);shade.size=Vector2(1024,240);shade.color=Color(0,0,0,.58);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(shade)
	var objective=Art.label("",Vector2(960,25),13,Color("b99a50"));objective.position=Vector2(32,278);objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;canvas.add_child(objective)
	if game.destruction.enabled:objective.text="Saldırı: Bombayı A/B alanına yerleştir." if game.destruction.attacker_team==game.local_room.get("team","blue") else "Savunma: Alanları koru ve bombayı çöz."
	else:objective.text="Kurt Savaşı" if game.player.is_wolf else "Ekipmanını seç ve maça hazırlan."
	caption=Art.label("",Vector2(960,36),18,Color("c29346"));caption.position=Vector2(32,315);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;canvas.add_child(caption)
	var viewport=ScrollContainer.new();viewport.position=Vector2(120,352);viewport.size=Vector2(791,139);viewport.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;viewport.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;canvas.add_child(viewport)
	var cards=HBoxContainer.new();cards.add_theme_constant_override("separation",5);viewport.add_child(cards)
	var values=["normal","power","guardian","ghost"] if kind=="wolf" else [0,1,2,3,4]
	for i in range(values.size()):
		var value=values[i];var button=Button.new();button.custom_minimum_size=Vector2(194,139);button.size=Vector2(194,139);button.flat=false;button.theme=Art.theme();cards.add_child(button);card_buttons.append(button)
		var style=StyleBoxFlat.new();style.bg_color=Color(0.015,0.015,0.015,0.81);style.border_color=Color("895b32");style.set_border_width_all(2);button.add_theme_stylebox_override("normal",style)
		var label=Art.label("",Vector2(158,24),13,Color("c6a769"));label.position=Vector2(8,3);button.add_child(label)
		var cost=Art.label("0",Vector2(25,24),13,Color("c6a769"));cost.position=Vector2(163,3);cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;button.add_child(cost)
		if kind=="human":
			cost.text=str(game.loadout_sp_cost(value));button.disabled=game.loadout_sp_cost(value)>game.match_sp
			label.text=game.book.loadout_names[value];var lines=[]
			for slot in ["primary","secondary_primary","pistol","knife","grenade"]:
				var entry=game.book.weapon((game.book.starter_slots if value==0 else game.book.loadouts[value]).get(slot,""))
				if not entry.is_empty():lines.append(entry.name)
			var copy=Art.label("\n".join(lines),Vector2(178,103),11,Color("c6a769"));copy.position=Vector2(8,29);copy.clip_text=true;button.add_child(copy)
			button.pressed.connect(func():game.choose_round_loadout(value))
		else:
			var profile=game.mutations.profile(value);label.text=profile.name;cost.text=str(game.economy.mutation_cost(value));button.disabled=game.match_sp<game.economy.mutation_cost(value)
			var icon="res://assets/mutations/normal-blue.png" if value=="normal" else game.mutations.model(value,game.local_room.get("team","blue")).get("portrait","")
			Art.sprite(button,icon,Vector2(98,25),Vector2(90,111)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			for row in range(4):
				var title=Art.label(["GÜÇ","ENERJİ","BAĞIR","HIZ"][row],Vector2(62,17),10,Color("bba982"));title.position=Vector2(8,29+row*17);button.add_child(title)
				for n in range(int(profile.bars[row])):
					var bar=ColorRect.new();bar.color=Color("b67b36");bar.position=Vector2(66+n*4,35+row*17);bar.size=Vector2(3,7);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(bar)
			if profile.guard or profile.cloak:
				var ability=Art.label("SAVUNMA" if profile.guard else "SAKLAN",Vector2(88,17),10,Color("bba982"));ability.position=Vector2(8,115);button.add_child(ability)
			button.pressed.connect(func():game.choose_round_mutation(value))
func _process(delta):
	visible=game.running and not game.menu_open
	if not game.running:game.close_round_selection();return
	if game.menu_open or game.application_suspended:return
	remaining=game.destruction.wait if game.destruction.enabled and game.destruction.phase=="prepare" else maxf(0,remaining-delta)
	caption.text=("Mutasyon Seçimi: Bu rauntta kullanacağınız kurt türünü seçin. " if kind=="wolf" else "Ekipman Seçimi: Bu rauntta kullanacağınız ekipman setini seçin. ")+str(ceili(remaining))
	if remaining<=0:game.finish_round_selection()
