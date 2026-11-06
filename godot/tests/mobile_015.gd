extends SceneTree
const Book=preload("res://scripts/content_book.gd")
const Quality=preload("res://scripts/item_quality.gd")
var failures=[]
var checks=0
var game
func ensure(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=3):
 for i in range(n):await process_frame
func touch(node,index,point,pressed):
 var e=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=pressed;node._input(e)
 if pressed and node==game.touch:node._unhandled_input(e)
func drag(node,index,point,relative):
 var e=InputEventScreenDrag.new();e.index=index;e.position=point;e.relative=relative;node._input(e)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720)
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
 game.set_process(false);game.book.offline_edition=true;game.book.acquire_all()
 var available=game.book.characters.filter(func(row):return row.get("available",false))
 ensure(available.size()>100 and available.all(func(row):return row.get("sourceTeam","") in ["red","blue"]),"Available models retain exact source team identities")
 var path="user://team-015-"+str(Time.get_ticks_usec())+".json"
 var book=Book.new(true,path,true);book.acquire_all();var chosen={}
 for team in ["red","blue"]:
  var row=available.filter(func(item):return item.sourceTeam==team)[-1];chosen[team]=row
  ensure(book.choose_character(row.id),"Save independent "+team+" character")
 var reopened=Book.new(true,path,true)
 for team in chosen:ensure(reopened.character_for_team(team).id==chosen[team].id,"Reload correct "+team+" source model")
 var tattoos=book.tattoos.filter(func(row):return row.get("appliedBonuses",{}).get("damagePercent",0)>0 and row.role=="body")
 ensure(not tattoos.is_empty(),"Source tattoos have independently decoded performance")
 var tattoo=tattoos[0];ensure(book.set_tattoo("body",tattoo.texture,tattoo.id),"Equip explicit item ID and UV role")
 reopened=Book.new(true,path,true)
 ensure(reopened.selected_tattoo_ids.get("body")==tattoo.id and reopened.tattoo_bonuses().damagePercent==tattoo.appliedBonuses.damagePercent,"Power identity survives shared-image save/reload")
 ensure(not book.set_tattoo("left",tattoo.texture,tattoo.id),"An item cannot grant its bonus in a different UV slot")
 book.set_tattoo("body","");ensure(book.tattoo_bonuses().damagePercent==0,"Unequip removes item bonus")
 DirAccess.remove_absolute(path)
 ensure(game.power_catalog.items.filter(func(item):return item.get("sourceId",0)>=16011 and item.get("sourceId",0)<=16020).size()==10,"Ten explicit PC claw descriptions match source binary records")
 game.book.selected_characters={"red":chosen.red.id,"blue":chosen.blue.id}
 for team in ["red","blue"]:
  game.local_room={"mode":0,"map":0,"team":team};ensure(game.start_round(),"Start "+team+" arena")
  ensure(game.character_info.id==chosen[team].id,"Player uses selected source team mesh")
  game.spawn_enemy("human");await frames()
  var bots=game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())
  ensure(not bots.is_empty() and bots[0].team!=team and bots[0].position.z*(1 if team=="blue" else -1)<0,"Opposing bot starts in its own half")
  game.menu_open=true
 game.local_room={"mode":0,"map":0,"team":"blue"};game.start_round();game.spawn_clock=10000
 for i in range(10):await physics_frame
 if not game.player.is_wolf:game.player.switch_form(true)
 game.player.action_time=0;game.player.move_axis=Vector2.ZERO
 ensure(game.player.begin_roll() and game.player.roll_direction==Vector3.ZERO,"Idle roll does not invent forward movement")
 var before=game.player.position
 for i in range(8):await physics_frame
 ensure(Vector2(game.player.position.x-before.x,game.player.position.z-before.z).length()<0.05,"Stationary roll stays in place")
 game.player.end_roll();game.player.action_time=0;game.player.move_axis=Vector2(0,-1)
 ensure(game.player.roar_effect.begin(1.0),"Roar begins")
 before=game.player.position
 for i in range(5):await physics_frame
 ensure(not game.player.roar_effect.aura.visible and game.player.roar_effect.light.light_energy==0,"Roar never displays the unrelated purple circle")
 ensure(Vector2(game.player.position.x-before.x,game.player.position.z-before.z).length()<0.05,"Roar locks translation")
 game.player.roar_effect.stop();game.player.move_axis=Vector2.ZERO
 game.inbox.state.powerCounts["16020"]=1 # Explicit accepted-item test fixture, not an offline catalogue grant.
 ensure(game.equip_power_item("16020"),"Owned source claw equips without inventing online ownership")
 ensure(game.gear_stats().damagePercent==20 and game.gear_stats().rangePercent==10,"Equipped claw applies its own source percentages")
 ensure(game.player.claw_trail.begin(),"Source claw ribbon binds to actual four endpoint bones")
 await frames(2);ensure(game.player.claw_trail.meshes.size()==2,"Both hands render independent source trail ribbons")
 game.player.claw_trail.clear()
 if game.player.is_wolf:game.player.switch_form(true)
 game.touch.resize()
 var fire=game.touch.buttons.filter(func(row):return row.action=="fire")[0].position
 before=Vector3(game.player.yaw,game.player.pitch,0)
 touch(game.touch,41,fire,true);drag(game.touch,41,fire+Vector2(30,-12),Vector2(30,-12))
 ensure(Input.is_action_pressed("fire") and game.player.yaw!=before.x,"Holding fire and dragging also changes aim")
 touch(game.touch,41,fire,false);ensure(not Input.is_action_pressed("fire"),"Fire drag releases cleanly")
 game.show_library("Dövmeler");await frames();var ui=game.library_panel
 var helper=ui.detail_helper
 ensure(helper.entries.filter(func(row):return not row.get("placeholder",false)).size()==game.book.tattoos.size(),"Family grouping retains every tattoo, including duplicate named variants")
 for i in range(0,helper.entries.size(),3):
  ensure(helper.entries[i].role=="left" and helper.entries[i+1].role=="body" and helper.entries[i+2].role=="right","Tattoo family stays left/body/right")
 var selected=ui.selected.id;var swipe=helper.swipe;var at=swipe.get_global_rect().get_center()
 touch(swipe,42,at,true);drag(swipe,42,at-Vector2(0,140),Vector2(0,-140));touch(swipe,42,at-Vector2(0,140),false)
 ensure(swipe.scroll>100 and ui.selected.id==selected,"Swipe scrolls continuously without accidentally equipping/selecting")
 for dimensions in [Vector2i(1280,720),Vector2i(2160,992),Vector2i(2400,1080)]:
  root.size=dimensions;await frames();ui.safe_insets=Vector4(25,9,31,15);ui.refresh();await frames()
  var safe=ui.usable_rect();var rect=ui.canvas.get_global_rect()
  ensure(safe.encloses(rect.grow(-0.1)),"Safe-area canvas stays inside phone "+str(dimensions))
  ensure(ui.preview_container.get_global_rect().end.x<=safe.end.x and ui.preview_container.get_global_rect().end.y<=safe.end.y,"Full wolf preview stays inside safe viewport")
 ui.safe_insets=Vector4.ZERO;ui.navigate("Envanter");await frames();helper=ui.detail_helper
 for quality in Quality.COLORS:
  ui.quality_id=quality;ui.offset=0;helper.refresh_grid()
  ensure(helper.entries.all(func(row):return Quality.label(row)==quality),"Quality filter matches literal source tier "+quality)
 ui.quality_id="all";ui.navigate("Karakterler");await frames()
 ui.filter_id="red";ui.offset=0;ui.detail_helper.refresh_grid();ensure(ui.detail_helper.entries.all(func(row):return row.sourceTeam=="red"),"Red filter never substitutes blue models")
 ui.filter_id="blue";ui.offset=0;ui.detail_helper.refresh_grid();ensure(ui.detail_helper.entries.all(func(row):return row.sourceTeam=="blue"),"Blue filter never substitutes red models")
 game.queue_free();await frames()
 var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"physicalAndroidDeviceTested":false}
 var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-015-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
 print("MOBILE_015_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
