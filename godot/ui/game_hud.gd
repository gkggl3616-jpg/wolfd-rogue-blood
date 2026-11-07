extends Control
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const Radar=preload("res://ui/local_radar.gd")
const Feedback=preload("res://ui/combat_feedback.gd")
const VideoLayout=preload("res://scripts/video_layout.gd")
class AimReticle extends Control:
	func _draw():
		var center=Vector2(16,16)
		for i in range(4):
			var axis=Vector2.from_angle(PI*i/2)
			draw_line(center+axis*4,center+axis*10,Color("7cec65"),1.5,true)
		draw_circle(center,1,Color.WHITE)
class RoundButton extends Button:
	func _has_point(point):
		var scale=get_global_transform().get_scale().abs()
		var padding=Vector2(maxf(0,48/maxf(.01,scale.x)-size.x),maxf(0,48/maxf(.01,scale.y)-size.y))*.5
		return Rect2(-padding,size+padding*2).has_point(point)
	func _draw():
		var center=size*0.5;var radius=minf(size.x,size.y)*0.5-1
		draw_circle(center,radius,Color(0.035,0.045,0.05,0.65 if not is_pressed() else 0.9))
		draw_arc(center,radius,0,TAU,48,Color(0.7,0.76,0.77,0.6),1.2,true)
var game
var health_view
var weapon_view
var timer_view
var score_view
var score:Label
var weapon_name:Label
var preview_name:Label
var map_name:Label
var power_buttons=[]
var power_counts=[]
var power_icons=[]
var extra_hp
var sp_display
var swap_view:TextureRect
var round_title:Label
var ready_view:TextureRect
var turn_result:Label
var own_name:Label
var other_name:Label
var death_count:Label
var slots=[]
var slot_icons=[]
var slot_ids=[]
var menu:Button
var inventory:Button
var cross:Control
var last_state=[]
var pc_layer:Control
var radar
var feedback
var class_icon:TextureRect
var scoreboard_button
var feed:Label
var feed_layer
var feed_signature=""
var opposition_icon
var guide:Label
var scope:ColorRect
var spectator_label:Label
var spectator_buttons=[]
var award_label:Label

func part(key,dimensions,keep):
	var view=Layout.new();pc_layer.add_child(view);view.configure(key,dimensions)
	view.show_only(keep)
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

func round_button(dimensions):
	var button=RoundButton.new();button.flat=true;button.focus_mode=Control.FOCUS_NONE;button.size=dimensions;button.custom_minimum_size=dimensions
	for state in ["normal","hover","pressed","focus","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	return button

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	scope=ColorRect.new();scope.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scope.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var scope_material=ShaderMaterial.new();scope_material.shader=preload("res://ui/sniper_scope.gdshader");scope.material=scope_material;scope.hide();add_child(scope)
	feedback=Feedback.new();feedback.game=game;add_child(feedback)
	pc_layer=Control.new();pc_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(pc_layer)
	health_view=part("interface/hudplayer",Vector2(100,71),["HPBack","HealthPoint","CryHealthPoint"])
	# Original HP/YP plate and both original digit displays retain their geometry.
	health_view.find_widget("HPBack").self_modulate.a=1
	health_view.find_widget("HealthPoint").modulate=Color("f32639")
	extra_hp=health_view.find_widget("CryHealthPoint")
	weapon_view=part("interface/hudweapon",Vector2(116,128),["WeaponBack","WeaponPoint","CurrentBullet","MaxBullet"])
	sp_display=weapon_view.find_widget("WeaponPoint");sp_display.size.x=61
	weapon_name=Art.label("",Vector2(115,22),16);weapon_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;pc_layer.add_child(weapon_name)
	score_view=part("interface/hudscore",Vector2(312,64),["Mode","RedTeamScore","BlueTeamScore"])
	var background=Art.sprite(score_view,"wt_interface/play/common/pl_score.dtx",Vector2.ZERO,Vector2(312,60),Rect2(0,0,312,60))
	background.modulate=Color("748294");score_view.move_child(background,0)
	for row in [[5,Color("602832")],[255,Color("214554")]]:
		var plate=ColorRect.new();plate.color=row[1];plate.position=Vector2(row[0],5);plate.size=Vector2(55,55);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;score_view.add_child(plate)
	class_icon=Art.sprite(score_view,"res://assets/ui/form-icons/human.png",Vector2(5,5),Vector2(55,55))
	opposition_icon=Art.sprite(score_view,"res://assets/ui/form-icons/human.png",Vector2(255,5),Vector2(55,55))
	var mode_label=score_view.find_widget("Mode");mode_label.position=Vector2(60,5);mode_label.size=Vector2(190,19)
	var kills=score_view.find_widget("RedTeamScore");kills.position=Vector2(98,28);kills.size=Vector2(45,23);kills.alignment=3;kills.modulate=Color("f32639")
	var goal=score_view.find_widget("BlueTeamScore");goal.position=Vector2(177,28);goal.size=Vector2(45,23);goal.alignment=3;goal.modulate=Color("59c1e4")
	var slash=Art.label(">",Vector2(18,23),18);slash.position=Vector2(148,27);slash.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;score_view.add_child(slash)
	score=Art.label("",Vector2(80,25),18);score.tooltip_text="Öldürme";pc_layer.add_child(score)
	death_count=Art.label("",Vector2(80,25),18);death_count.tooltip_text="Ölüm";pc_layer.add_child(death_count)
	own_name=Art.label("",Vector2(120,18),10,Color("62bce9"));own_name.size.x=112;own_name.clip_text=true;pc_layer.add_child(own_name)
	other_name=Art.label("Rakip botlar",Vector2(150,18),10,Color("df4c45"));other_name.size.x=140;other_name.clip_text=true;pc_layer.add_child(other_name)
	timer_view=part("interface/hudtimer",Vector2(86,41),["Colon","Minute","Second"])
	var minute=timer_view.find_widget("Minute");minute.position=Vector2(0,4);minute.size=Vector2(32,23);minute.alignment=2
	var second=timer_view.find_widget("Second");second.position=Vector2(48,4);second.size=Vector2(32,23);second.alignment=1
	var colon=timer_view.find_widget("Colon");colon.text=":";colon.position=Vector2(32,-1);colon.size=Vector2(16,32);colon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	preview_name=Art.label("",Vector2(500,23),12,Art.GOLD);preview_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(preview_name)
	map_name=Art.label("",Vector2(155,20),10,Color("c6cecf"));pc_layer.add_child(map_name)
	radar=Radar.new();radar.game=game;radar.size=Vector2(128,128);pc_layer.add_child(radar)
	cross=AimReticle.new();cross.size=Vector2(32,32);cross.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(cross);game.crosshair=cross
	menu=round_button(Vector2(42,42));menu.tooltip_text="Menü";menu.pressed.connect(game.pause_game);pc_layer.add_child(menu)
	inventory=round_button(Vector2(42,42));inventory.tooltip_text="Envanter";inventory.pressed.connect(func():game.show_library("Envanter"));pc_layer.add_child(inventory)
	Art.sprite(menu,"wt_interface/all/a_lb_icon_option.dtx",Vector2(9,9),Vector2(24,24),Rect2(4,0,24,22))
	Art.sprite(inventory,"wt_interface/all/a_lb_icon_inven.dtx",Vector2(9,9),Vector2(24,24),Rect2(4,0,24,22))
	game.gui_touch_blockers.append(menu);game.gui_touch_blockers.append(inventory)
	scoreboard_button=round_button(Vector2(42,42));scoreboard_button.tooltip_text="Maç durumu";scoreboard_button.pressed.connect(func():game.open_interface("scoreboard"));pc_layer.add_child(scoreboard_button)
	Art.sprite(scoreboard_button,"wt_interface/all/a_lb_icon_record.dtx",Vector2(9,9),Vector2(24,24),Rect2(4,0,24,22));game.gui_touch_blockers.append(scoreboard_button)
	feed=Art.label("",Vector2(365,122),12);feed.hide();pc_layer.add_child(feed)
	feed_layer=Control.new();feed_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;pc_layer.add_child(feed_layer)
	guide=Art.label("",Vector2(700,44),16,Art.GOLD);guide.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(guide)
	var number=0
	for slot in ["primary","pistol","knife","grenade"]:
		var button=round_button(Vector2(44,44))
		button.set_meta("source_scale",0.72)
		button.tooltip_text="Ana silahlar arasında geç" if slot=="primary" else {"pistol":"Tabanca","knife":"Bıçak","grenade":"Bomba"}[slot]
		button.pressed.connect(func():
			if slot=="primary":game.cycle_primary()
			else:game.equip_slot(slot)
		)
		var icon=Art.sprite(button,"",Vector2(4,9),Vector2(36,24));icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var key=Art.label(str([1,2,5,4][number]),Vector2(10,14),8,Color("c1b77e"));key.position=Vector2(18,29);button.add_child(key)
		pc_layer.add_child(button);slots.append(button);slot_icons.append(icon);slot_ids.append(slot);game.gui_touch_blockers.append(button);number+=1
	for slot in ["support","energy"]:
		var button=round_button(Vector2(56,56));button.set_meta("source_scale",0.9);button.pressed.connect(func():game.use_power(slot));button.set_meta("power_slot",slot);pc_layer.add_child(button);game.gui_touch_blockers.append(button);power_buttons.append(button)
		var image=Art.sprite(button,"",Vector2(7,8),Vector2(42,30));image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;power_icons.append(image)
		var count=Art.label("",Vector2(42,14),11);count.position=Vector2(7,39);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.add_child(count);power_counts.append(count)
	spectator_label=Art.label("",Vector2(500,30),16,Art.GOLD);spectator_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(spectator_label)
	award_label=Art.label("",Vector2(320,100),16,Art.GOLD);award_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;award_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;pc_layer.add_child(award_label)
	for direction in [-1,1]:
		var button=round_button(Vector2(52,52));button.text="‹" if direction<0 else "›";button.add_theme_font_size_override("font_size",30);button.add_theme_color_override("font_color",Color.WHITE);button.tooltip_text="Önceki takım arkadaşı" if direction<0 else "Sonraki takım arkadaşı";button.pressed.connect(func():game.spectator.cycle(direction));pc_layer.add_child(button);game.gui_touch_blockers.append(button);spectator_buttons.append(button)
	swap_view=Art.sprite(pc_layer,"wt_interface/play/pl_change.dtx",Vector2.ZERO,Vector2.ONE,Rect2(0,0,804,604));swap_view.hide()
	round_title=Art.label("",Vector2(312,36),28,Color.WHITE);round_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(round_title)
	ready_view=Art.sprite(pc_layer,"wt_interface/play/pl_round_ready.dtx",Vector2.ZERO,Vector2(256,64))
	turn_result=Art.label("",Vector2(440,52),36,Art.GOLD);turn_result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pc_layer.add_child(turn_result)
	resized.connect(arrange);arrange();refresh_from_game()

func arrange():
	if not is_instance_valid(menu):return
	var dimensions=get_viewport_rect().size
	scope.material.set_shader_parameter("aspect",dimensions.x/maxf(1,dimensions.y))
	var factor=dimensions/Vector2(1024,768)
	pc_layer.scale=factor;pc_layer.size=Vector2(1024,768)
	var native=pc_layer.size
	health_view.position=VideoLayout.point("health",native)
	weapon_view.position=VideoLayout.point("weapon",native);weapon_name.position=weapon_view.position+Vector2(-25,59)
	score_view.position=VideoLayout.point("score",native)
	timer_view.position=VideoLayout.point("timer",native)
	score.position=VideoLayout.point("own_kills",native);death_count.position=VideoLayout.point("own_deaths",native)
	own_name.position=VideoLayout.point("own_name",native);other_name.position=VideoLayout.point("other_name",native)
	preview_name.position=Vector2(native.x*0.5-250,8)
	map_name.position=VideoLayout.point("map_name",native);radar.position=VideoLayout.point("radar",native);radar.size=VideoLayout.measure(Vector2(116,84),native)
	menu.position=Vector2(native.x*0.05,7);inventory.position=Vector2(native.x*0.05+48,7);scoreboard_button.position=Vector2(native.x*0.05+96,7)
	feed.position=VideoLayout.point("feed",native);feed_layer.position=feed.position;feed_layer.scale=Vector2(.84,1)
	guide.position=VideoLayout.point("guide",native);guide.size=VideoLayout.measure(Vector2(350,22),native)
	spectator_label.position=VideoLayout.point("spectator",native);spectator_label.size=VideoLayout.measure(Vector2(250,16),native)
	award_label.position=VideoLayout.point("awards",native);award_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	for i in range(spectator_buttons.size()):
		var button=spectator_buttons[i];button.scale=Vector2.ONE*(dimensions.y/720.0)/factor
		button.position=Vector2(dimensions.x*.5+(-290 if i==0 else 290),dimensions.y*.85)/factor-button.size*button.scale/2
	for i in range(slots.size()):slots[i].position=Vector2(native.x*0.5-108+i*52,native.y-39)
	for i in range(power_buttons.size()):power_buttons[i].position=VideoLayout.point("support" if i==0 else "energy",native)
	swap_view.position=VideoLayout.measure(Vector2(70,40),native);swap_view.size=VideoLayout.measure(Vector2(500,280),native)
	round_title.position=Vector2(native.x*.5-156,VideoLayout.measure(Vector2(0,36),native).y)
	ready_view.position=Vector2(native.x*.5-128,VideoLayout.measure(Vector2(0,60),native).y)
	turn_result.position=Vector2(native.x*.5-220,VideoLayout.measure(Vector2(0,60),native).y)
	for row in layout_targets():
		var key=row[0];var button=row[1];var custom=preload("res://scripts/control_layout.gd");var standard=Vector2.ONE*float(button.get_meta("source_scale",1.0))*(dimensions.y/720.0)/factor;var weight=standard*custom.scale_for(game.book.control_layout,key)
		var base=(button.position+button.size*standard/2)*factor;button.scale=weight
		button.position=custom.center(game.book.control_layout,key,base,dimensions,maxf(button.size.x*weight.x*factor.x,button.size.y*weight.y*factor.y)/2)/factor-button.size*weight/2
	cross.position=dimensions*0.5-Vector2(16,16)

func layout_targets():
	var rows=[["menu",menu],["inventory",inventory],["scoreboard",scoreboard_button]]
	for i in range(slots.size()):rows.append(["slot_"+slot_ids[i],slots[i]])
	for i in range(power_buttons.size()):rows.append([["support","energy"][i],power_buttons[i]])
	return rows

func refresh_from_game():
	visible=game.running and not game.menu_open
	if not is_instance_valid(game.player):return
	for i in range(power_buttons.size()):
		var button=power_buttons[i];var id=game.inbox.state.powerSlots.get(button.get_meta("power_slot"),"");var count=int(game.inbox.state.powerCounts.get(id,0))
		button.visible=not game.spectator.active and game.player.is_wolf and id!="";button.disabled=count<=0 or not game.is_combat_active();power_counts[i].text=str(count)
		var item=game.power_item(id);button.tooltip_text=item.get("name","")
		if power_icons[i].get_meta("power_id","unset")!=id:
			var region=item.get("iconRegion",[0,0,210,75]);power_icons[i].texture=Art.atlas(item.get("icon",""),Rect2(region[0],region[1],region[2],region[3]));power_icons[i].set_meta("power_id",id)
	weapon_view.set_value("WeaponPoint",game.match_sp)
	swap_view.visible=game.destruction.enabled and game.destruction.phase=="swap"
	var turn_state=game.destruction.phase if game.destruction.enabled else ""
	round_title.visible=turn_state in ["prepare","between"];ready_view.visible=turn_state=="prepare" or (game.selection_active and not game.selection_transform);turn_result.visible=turn_state=="between"
	round_title.text="Raunt %d" % game.destruction.number
	turn_result.text="KAZANDIK" if game.destruction.last_winner==game.local_room.get("team","blue") else "KAYBETTİK"
	if game.destruction.enabled and turn_state!="combat":game.message.visible=false
	var watching=game.spectator.active
	var watched=game.spectator.target if watching and game.actor_alive(game.spectator.target) else null
	spectator_label.visible=watching
	spectator_label.text="İZLENİYOR · "+watched.display_name if watched!=null else "Yaşayan takım arkadaşı yok · Tur sonu bekleniyor"
	for button in spectator_buttons:button.visible=watching;button.disabled=game.spectator.candidates().size()<2
	award_label.text="\n".join(game.economy.awards.map(func(row):return row.label+"  +%d SP" % row.amount))
	if game.destruction.enabled:
		var turn=game.destruction
		guide.text="RAUNT %d · %s" % [turn.number,turn.role(game.local_room.get("team","blue"))]
		if turn.phase=="prepare":guide.text+=" · HAZIR %d" % ceili(turn.wait)
		elif turn.phase=="swap":guide.text="SAVUNMA VE SALDIRI DEĞİŞİMİ · %d" % ceili(turn.wait)
		elif turn.phase=="between":guide.text+=" · "+("KAZANDIK" if turn.last_winner==game.local_room.get("team","blue") else "KAYBETTİK")
		elif turn.planted:guide.text+=" · BOMBA %02d" % ceili(turn.fuse)
		elif turn.dropped:guide.text+=" · Bomba yerde"
		elif turn.carrier==game.player:guide.text+=" · Bombayı taşıyorsun"
		if turn.progress>0:guide.text+=" · %s %d%%" % ["ÇÖZÜLÜYOR" if turn.planted else "KURULUYOR",int(100*turn.progress/float(turn.tuning.defuseSeconds if turn.planted else turn.tuning.plantSeconds))]
	extra_hp.value=str(game.player.extra_health);extra_hp.visible=game.player.is_wolf and not watching
	cross.visible=visible and not game.player.is_wolf and not watching
	scope.visible=visible and not watching and game.player.is_scoped();cross.visible=cross.visible and not scope.visible
	refresh_feed()
	guide.visible=(game.destruction.enabled and game.destruction.phase!="swap") or game.tutorial.active or (game.hunt.active and game.hunt.phase=="intermission")
	if not game.destruction.enabled:guide.text=game.tutorial.hint() if game.tutorial.active else ("Yeni raunt: %d" % ceili(game.hunt.intermission))
	var state=[game.health,game.ammo,game.reserve,int(game.time_left),game.kills,game.current_weapon_id,game.reloading>0,game.exploring,game.player.is_wolf,game.preview_name,game.equipped_slots().duplicate(),game.hunt.active,game.hunt.round_number,game.hunt.round_kills,game.tutorial.active,game.deaths,game.team_frags.duplicate(),game.target_score(),game.match_rules.enabled,game.destruction.wins.duplicate(),game.destruction.number]
	state.append(watched.get_instance_id() if watched!=null else 0)
	if watched!=null:state.append_array([watched.health,watched.ammo,watched.reserve,watched.reload_remaining>0])
	state.append(watching)
	if state==last_state:return
	last_state=state
	health_view.set_value("HealthPoint",watched.health if watched!=null else game.health)
	health_view.find_widget("HealthPoint").modulate=Color.WHITE if (watched.kind=="wolf" if watched!=null else game.player.is_wolf) else Color("f32639")
	score.text=str(game.kills);death_count.text=str(game.deaths);own_name.text=game.profile_name
	weapon_view.visible=true
	weapon_view.set_value("CurrentBullet",watched.ammo if watched!=null and watched.kind=="human" else (game.ammo if not watching and not game.player.is_wolf else 0));weapon_view.set_value("MaxBullet",watched.reserve if watched!=null and watched.kind=="human" else (game.reserve if not watching and not game.player.is_wolf else 0))
	weapon_name.text="" if game.player.is_wolf else ("ŞARJÖR…" if game.reloading>0 else game.player.weapon_info.get("name",""))
	if watched!=null:weapon_name.text=watched.weapon_data.get("name","Tüfek") if watched.kind=="human" else "KURT"
	var seconds=maxi(0,int(game.time_left));timer_view.set_value("Minute","%02d" % int(seconds/60));timer_view.set_value("Second","%02d" % (seconds%60))
	var blue=game.local_room.get("team","blue")=="blue"
	score_view.set_value("RedTeamScore",game.team_score("red"));score_view.set_value("BlueTeamScore",game.team_score("blue"));score_view.set_value("Mode",("Ölüm Oyunu   %d Puan" % game.target_score()) if game.match_rules.enabled else "Yerel Eğitim   10 Puan")
	if game.destruction.enabled:
		score_view.set_value("Mode","Yıkım · %d Tur" % game.destruction.limit);score_view.set_value("RedTeamScore",game.destruction.wins.red);score_view.set_value("BlueTeamScore",game.destruction.wins.blue)
	if game.hunt.active:
		score_view.set_value("RedTeamScore",game.hunt.round_kills);score_view.set_value("BlueTeamScore",game.LocalHunt.TARGET);score_view.set_value("Mode","Kurt Avı · %d/3" % game.hunt.round_number)
	if int(game.local_room.get("mode",0))==game.WOLF_BATTLE:score_view.set_value("Mode","Kurt Savaşı")
	if game.tutorial.active:score_view.set_value("Mode","Öğretici Mod")
	class_icon.texture=Art.texture("res://assets/ui/form-icons/wolf.png" if game.player.is_wolf else "res://assets/ui/form-icons/human.png")
	opposition_icon.texture=class_icon.texture
	timer_view.visible=not game.exploring and not game.tutorial.active and (not game.destruction.enabled or game.destruction.phase=="combat");score_view.visible=not game.exploring
	preview_name.visible=game.exploring;preview_name.text=game.preview_name+" · GEZİNTİ"
	map_name.text=game.preview_name
	for i in range(slots.size()):
		slots[i].visible=not watching and not game.player.is_wolf
		var id=game.equipped_slots().get(slot_ids[i],"")
		var entry=game.book.weapon(id)
		slot_icons[i].texture=Art.atlas(entry.get("icon",""),Rect2(0,0,210,75))
		slots[i].modulate=Color.WHITE if id==game.current_weapon_id else Color(0.8,0.85,0.85,0.5)

func _process(_delta):refresh_from_game()

func refresh_feed():
	var signature=JSON.stringify(game.kill_feed.map(func(row):return [row.attacker,row.target,row.get("weaponId",""),row.get("headshot",false)]))
	if signature==feed_signature:return
	feed_signature=signature
	for child in feed_layer.get_children():feed_layer.remove_child(child);child.queue_free()
	for i in range(mini(5,game.kill_feed.size())):
		var entry=game.kill_feed[i];var y=i*28
		var left=Art.label(entry.attacker,Vector2(130,25),12,Color("e43148") if entry.get("attackerTeam","blue")=="red" else Color("66c8ef"));left.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;left.position=Vector2(0,y);feed_layer.add_child(left)
		var item=game.book.weapon(entry.get("weaponId",""));var source=item.get("icon","wt_interface/killsystemmessage/pl_k_wolf.dtx")
		var icon=Art.sprite(feed_layer,source,Vector2(136,y+2),Vector2(91,21),Rect2(0,0,210,75) if not item.is_empty() else Rect2());icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.modulate=left.get_theme_color("font_color")
		var shader=Shader.new();shader.code="shader_type canvas_item; void fragment(){COLOR=vec4(COLOR.rgb,texture(TEXTURE,UV).a*COLOR.a);}";var material=ShaderMaterial.new();material.shader=shader;icon.material=material
		var right=Art.label(entry.target,Vector2(130,25),12,Color("e43148") if entry.get("targetTeam","red")=="red" else Color("66c8ef"));right.position=Vector2(233,y);feed_layer.add_child(right)
		if entry.get("headshot",false):
			var head=Art.label("☠",Vector2(20,22),14,Color("e8c889"));head.position=Vector2(214,y);feed_layer.add_child(head)
