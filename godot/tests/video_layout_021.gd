extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=4):
 for i in range(n):await process_frame
func close_to(a,b,tolerance=0.003):return a.distance_to(b)<tolerance
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.player.set_physics_process(false)
 for dimensions in [Vector2i(1280,720),Vector2i(2160,992),Vector2i(800,450)]:
  root.size=dimensions;await frames();game.source_hud.arrange();game.touch.resize();var size=game.source_hud.get_viewport_rect().size;var hud=game.source_hud
  check(close_to(hud.health_view.global_position/size,Vector2(8.0/640,324.0/360)),"HP plate matches video bottom-left at "+str(dimensions))
  check(close_to(hud.weapon_view.global_position/size,Vector2(563.0/640,316.0/360)),"SP and ammo share source bottom-right plate at "+str(dimensions))
  check(close_to(hud.radar.global_position/size,Vector2(521.0/640,8.0/360)) and close_to(hud.radar.get_global_rect().size/size,Vector2(116.0/640,84.0/360)),"Radar retains measured top-right rectangle at "+str(dimensions))
  check(absf(hud.score_view.get_global_rect().get_center().x/size.x-.5)<.005,"Score strip stays top-center")
  check(hud.extra_hp==hud.health_view.find_widget("CryHealthPoint") and hud.sp_display==hud.weapon_view.find_widget("WeaponPoint"),"YP and SP use their original source digit widgets")
  for row in hud.layout_targets():
   var scale=row[1].get_global_transform().get_scale().abs();check(absf(scale.x-scale.y)<.01,"Mobile button remains circular: "+row[0])
  var hp=Rect2(size*Vector2(8.0/640,324.0/360),size*Vector2(63.0/640,36.0/360))
  var ammo=Rect2(size*Vector2(563.0/640,316.0/360),size*Vector2(77.0/640,44.0/360))
  var body=Rect2(size*Vector2(.38,.38),size*Vector2(.25,.52))
  for button in game.touch.buttons:
   var radius=(38 if button.action=="fire" else 34)*button.scale.x;var rect=Rect2(button.position-Vector2.ONE*radius,Vector2.ONE*radius*2)
   check(not rect.intersects(hp) and not rect.intersects(ammo) and not rect.intersects(body),"Default touch target leaves source information and central body clear: "+button.action)
  for i in range(game.touch.buttons.size()):
   for j in range(i+1,game.touch.buttons.size()):
    var a=game.touch.buttons[i];var b=game.touch.buttons[j];var ra=(38 if a.action=="fire" else 34)*a.scale.x;var rb=(38 if b.action=="fire" else 34)*b.scale.x
    check(a.position.distance_to(b.position)>=ra+rb,"Default touch targets cannot overlap: "+a.action+" / "+b.action)
 root.size=Vector2i(1280,720);await frames();game.open_round_selection("human");await frames()
 var panel=game.selection_panel
 check(panel.card_buttons.size()==5 and panel.card_buttons[0].position.x==0,"Five sets remain accessible with source Standard first")
 var card=panel.card_buttons[0].get_global_rect();check(close_to(card.position/Vector2(1280,720),Vector2(75.0/640,165.0/360)) and absf(card.size.x/1280-121.0/640)<.004,"Equipment cards match the video row, width and margins")
 check(panel.card_buttons[4].get_global_rect().position.x>1100,"Extra fifth preset scrolls beyond the four source columns")
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/video-layout-021-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures,"referenceVideos":["1aLtBA24fugZ04CYmRADJls8D40z33vBj","1dWltFGibelqf2i_8XReiOvH5_MS5pVse"]},"  "));f.close()
 game.queue_free();await frames();print("VIDEO_LAYOUT_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
func _initialize():call_deferred("run")
