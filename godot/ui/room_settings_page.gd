extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Rules=preload("res://scripts/source_match_rules.gd")
var ui
var room_view
var view
var families={}
var family
var variant
var capacity
var allies
var enemies
var difficulty
var maps
var team
var goal
var clock
var draft={}
func picker(name):
 var node=view.find_widget(name);node.disabled=false;node.fit_to_longest_item=false;node.clear();node.add_theme_font_size_override("font_size",10);return node
func build():
 draft=ui.room_draft
 for name in ["FieldName","GameMode","GameOption","MapName","MaxChars","MissionObject","RoundTime","Password","CurrentMap"]:
  var old=room_view.find_widget(name)
  if old:old.hide()
 ui.links.StartGame.disabled=true;ui.links.ChangeRule.disabled=true
 view=ui.native("interface/changefielddialog",ui.content)
 var title=view.find_widget("FieldNameEditBox");title.editable=true;title.text=draft.title;ui.room_title=title
 title.set_meta("navigation_input","room_title");title.text_changed.connect(func(value):draft.title=value;ui.room_draft.title=value)
 var password=view.find_widget("PasswordEditBox");password.editable=false;password.placeholder_text="—";password.tooltip_text="Çevrimdışı odada şifre kullanılmaz."
 family=picker("ModeTypeComboBox");variant=picker("GameOptionComboBox");variant.size.x=105
 var modes=[{"id":0,"name":"Botlu Eğitim · Yerel"},{"id":ui.game.LocalHunt.MODE,"name":"Kurt Avı Modu · Yerel"},{"id":ui.game.LocalTutorial.MODE,"name":"Öğretici Modu · Yerel"},{"id":ui.game.WOLF_BATTLE,"name":"Kurt Savaşı · Yerel"}]
 for row in ui.game.map_catalog.data.modes:modes.append({"id":int(row.id),"name":row.displayName})
 for row in modes:
  var base=row.name.get_slice(" · ",0)
  if not families.has(base):families[base]=[];family.add_item(base)
  families[base].append(row)
 var selected_family=0
 for i in range(family.item_count):
  if families[family.get_item_text(i)].any(func(row):return row.id==int(draft.mode)):selected_family=i
 family.select(selected_family);family.item_selected.connect(func(_i):fill_variants())
 variant.item_selected.connect(func(_i):draft.mode=variant.get_selected_id();fill_rules())
 team=picker("TeamComboBox");team.add_item("Mavi Takım",0);team.add_item("Kırmızı Takım",1);team.select(1 if draft.get("team","blue")=="red" else 0)
 team.item_selected.connect(func(i):draft.team="red" if i==1 else "blue")
 capacity=picker("MaxCharsComboBox")
 for n in range(2,17,2):capacity.add_item("%d Oyuncu" % n,n)
 for i in range(capacity.item_count):
  if capacity.get_item_id(i)==int(draft.get("capacity",16)):capacity.select(i)
 capacity.item_selected.connect(func(_i):draft.capacity=capacity.get_selected_id();fill_bot_limits())
 maps=picker("MapComboBox");maps.size.x=365;maps.size.y=24
 maps.item_selected.connect(func(_i):draft.map=maps.get_selected_id();refresh_photo())
 ui.button(ui.content,"▣",Vector2(978,377),Vector2(42,24),func():show_maps())
 goal=picker("MissionObjectComboBox");clock=picker("RoundTimeComboBox")
 goal.item_selected.connect(func(_i):draft.pointGoal=goal.get_selected_id())
 clock.item_selected.connect(func(_i):draft.matchSeconds=clock.get_selected_id())
 for name in ["TeamChangeRoleOption","GamingEnter","Observe"]:
  var button=view.find_widget(name);button.disabled=true;button.tooltip_text="Bu seçenek çevrimiçi oda hizmetinde kullanılır."
 for name in ["ClassLowerLimited","ClassLimited","WeaponOptionCombobox"]:
  var option=picker(name);option.add_item("Moda göre" if name=="WeaponOptionCombobox" else "Kapalı");option.disabled=true
 var cover=ColorRect.new();cover.position=Vector2(611,430);cover.size=Vector2(407,96);cover.color=Color("202b30");cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.content.add_child(cover)
 ui.text(ui.content,"BOTLAR",Vector2(619,438),Vector2(100,22),12,Art.GOLD)
 difficulty=ui.map_picker(ui.content,Vector2(752,435),Vector2(250,26))
 for level in ["easy","normal","hard"]:
  difficulty.add_item(ui.game.BotRules.LEVELS[level].name);difficulty.set_item_metadata(difficulty.item_count-1,level)
  if level==draft.get("botDifficulty","normal"):difficulty.select(difficulty.item_count-1)
 difficulty.item_selected.connect(func(_i):draft.botDifficulty=difficulty.get_selected_metadata())
 allies=ui.map_picker(ui.content,Vector2(619,477),Vector2(184,26));enemies=ui.map_picker(ui.content,Vector2(817,477),Vector2(184,26))
 allies.item_selected.connect(func(i):draft.allyBots=i);enemies.item_selected.connect(func(i):draft.enemyBots=i)
 view.bind_action("Confirm",apply);view.bind_action("Cancel",ui.go_back)
 ui.links.PLOK=view.find_widget("Confirm");ui.links.PLCancel=view.find_widget("Cancel");ui.links.Confirm=ui.links.PLOK;ui.links.Cancel=ui.links.PLCancel
 ui.room_mode=variant;ui.room_map=maps;ui.room_goal=goal;ui.room_time=clock;ui.room_difficulty=difficulty;ui.room_form=team;ui.room_allies=allies;ui.room_enemies=enemies
 fill_variants()
func fill_variants():
 variant.clear();var rows=families[family.get_item_text(family.selected)]
 for row in rows:
  var suffix=row.name.trim_prefix(family.get_item_text(family.selected)).trim_prefix(" · ")
  variant.add_item(suffix if suffix!="" else "Normal",int(row.id))
  if int(row.id)==int(draft.mode):variant.select(variant.item_count-1)
 draft.mode=variant.get_selected_id();fill_rules()
func fill_rules():
 maps.clear();var local=ui.game.is_local_mode(int(draft.mode))
 if local:maps.add_item("Eğitim Arenası",0)
 for row in (ui.game.map_catalog.offline_maps() if local else ui.game.map_catalog.maps_for_mode(int(draft.mode))):maps.add_item(row.displayName,int(row.number))
 for i in range(maps.item_count):
  if maps.get_item_id(i)==int(draft.map):maps.select(i)
 if maps.item_count:draft.map=maps.get_selected_id()
 goal.clear();clock.clear();var rules=Rules.new();rules.configure(draft)
 goal.disabled=not rules.enabled;clock.disabled=not rules.enabled
 if rules.enabled:
  for row in rules.record.goals:
   goal.add_item("%d Puan" % int(row.points),int(row.points))
   if int(row.points)==rules.goal:goal.select(goal.item_count-1)
  for row in rules.record.times:
   clock.add_item("%d dakika" % (int(row.seconds)/60),int(row.seconds))
   if int(row.seconds)==rules.seconds:clock.select(clock.item_count-1)
  draft.pointGoal=rules.goal;draft.matchSeconds=rules.seconds
 else:goal.add_item("Yerel kural");clock.add_item("90 saniye")
 fill_bot_limits();refresh_photo()
func fill_bot_limits():
 if allies==null:return
 var per_team=int(capacity.get_selected_id()/2);var selected_allies=int(draft.get("allyBots",0));var selected_enemies=int(draft.get("enemyBots",4));allies.clear();enemies.clear()
 var tutorial=int(draft.mode)==ui.game.LocalTutorial.MODE
 for i in range(1 if tutorial else mini(4,per_team-1)+1):allies.add_item("Dost: %d" % i,i)
 for i in range(1 if tutorial else mini(4,per_team)+1):enemies.add_item("Rakip: %d" % i,i)
 allies.select(mini(selected_allies,allies.item_count-1));enemies.select(mini(selected_enemies,enemies.item_count-1));draft.allyBots=allies.selected;draft.enemyBots=enemies.selected
func refresh_photo():view.find_widget("SelectMap").texture=Art.map_photo(ui.game.map_catalog,int(draft.map))
func show_maps():
 ui.room_map=maps;var desktop=load("res://ui/pc_screens.gd").new();desktop.ui=ui;desktop.map_gallery()
func apply():
 var title=view.find_widget("FieldNameEditBox").text.strip_edges()
 if title.length()<2 or maps.item_count==0:ui.show_error("Oda adı ve moda uygun harita gerekli.");return
 draft.title=title;draft.capacity=capacity.get_selected_id();draft.playerForm="wolf" if int(draft.mode)==ui.game.LocalHunt.MODE and draft.team=="red" else "human"
 ui.game.local_room=draft.duplicate(true);ui.navigate("room")
