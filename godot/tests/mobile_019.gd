extends SceneTree
const Art=preload("res://ui/source_theme.gd")
var checks=0
var failures=[]
var game
func ensure(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=4):
 for i in range(n):await process_frame
func _initialize():call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false);game.book.offline_edition=true;game.sync_collection();game.book.acquire_all()
 game.show_library("Karakterler");var ui=game.library_panel;ui.preview_wolf=true
 for id in ["pair-model0","pair-model1"]:
  ui.replace_preview(game.book.characters.filter(func(row):return row.id==id)[0]);await frames()
  var bodies=ui.preview_model.find_children("*","MeshInstance3D",true,false).filter(func(mesh):return "body" in str(mesh.name).to_lower() and not str(mesh.name).to_lower().begins_with("tattoo"))
  ensure(not bodies.is_empty(),"Reboot wolf contains original body surfaces: "+id)
  for mesh in bodies:
   for surface in range(mesh.mesh.get_surface_count()):ensure(mesh.get_active_material(surface).transparency!=BaseMaterial3D.TRANSPARENCY_ALPHA,"Reboot body writes depth instead of blended self-sorting: "+id)
  var animator=ui.preview_model.find_children("*","AnimationPlayer",true,false)[0];animator.seek(animator.get_animation("idle").length*0.9,true)
  var skeleton=ui.preview_model.find_children("*","Skeleton3D",true,false)[0];skeleton.force_update_all_bone_transforms()
  ensure(skeleton.get_bone_global_pose(skeleton.get_bone_count()-1).origin.is_finite(),"Late idle preserves finite original skin pose: "+id)
 var profile=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mobile-import-profile.json"))
 ensure(profile.skinnedMeshes.vertexCompression==false and profile.skinnedMeshes.generatedLods==false and profile.skinnedMeshes.sourceGlbsModified==false,"Mobile skin import disables compressed attributes/LODs without changing admitted source GLBs")
 for dimensions in [Vector2i(800,450),Vector2i(1280,720),Vector2i(2712,1220)]:
  root.size=dimensions;await frames();ui.safe_insets=Vector4(24,6,28,8);ui.refresh();await frames()
  var strip=ui.get_node("ResponsiveHeader");var navigation=[]
  for link in ui.links.values():
   if link.get_parent()==strip and link.visible:navigation.append(link)
  ensure(navigation.all(func(button):return ui.usable_rect().encloses(button.get_global_rect())),"All visible toolbar targets fit safe area: "+str(dimensions))
  var sizes=navigation.map(func(button):return (root.get_final_transform()*button.get_global_rect()).size.x)
  ensure(sizes.all(func(width):return width>=44),"Expanded header retains finger-sized targets: "+str(dimensions))
  if dimensions.x>2500:ensure(sizes.all(func(width):return width>=85),"X7 Pro resolution scales toolbar icons up instead of leaving fixed tiny pixels")
 root.size=Vector2i(1280,720);await frames();ui.safe_insets=Vector4.ZERO
 game.inbox.state.messages=[]
 for kind in ["character","weapon","power"]:
  var id="pair-model48" if kind=="character" else ("19002" if kind=="power" else game.book.weapons.filter(func(row):return row.get("available",false))[0].id)
  game.inbox.enqueue(game.inbox.state,kind,id,"QA",1,"art019-"+kind)
 ui.navigate("gifts");await frames();var helper=ui.detail_helper
 for gift in game.inbox.state.messages:
  var art=helper.artwork(gift)
  if gift.kind=="character":ensure(art.region.size.x==288,"Special-edition portrait trims transparent atlas padding before filling gift card")
  ensure(art.region.has_area(),"Gift artwork crops actual original atlas region: "+gift.kind)
  var card=helper.cards.filter(func(node):return node.get_meta("gift_id","")==gift.id)[0];var picture=card.get_node("GiftArtwork")
  ensure(picture.texture is AtlasTexture and picture.size==Vector2(198,69),"Gift image fills its complete allocated image area: "+gift.kind)
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 await frames(30);game.player.action_time=0;var p=game.player
 for id in ["19002","19502"]:
  game.inbox.state.powerCounts[id]=3;game.equip_power_item(id)
 game.source_hud.refresh_from_game()
 ensure(root.get_visible_rect().encloses(game.source_hud.extra_hp.get_global_rect()),"Extra-health readout stays fully above phone bottom edge")
 for i in range(2):
  ensure(game.source_hud.power_icons[i].texture is AtlasTexture and game.source_hud.power_buttons[i].size==Vector2(56,56),"Heal/energy target uses full cropped source artwork and readable circular size: "+str(i))
 ensure(not game.touch.buttons[5].visible and game.touch.buttons[11].visible,"Only cross-marked wolf run target is removed; separate roll remains")
 p.shot_cooldown=0;game.attack();ensure(p.current_clip=="attack" and is_equal_approx(p.anim.speed_scale,1.15),"First claw uses real left-hand source animation at +15 percent")
 ensure(is_equal_approx(p.shot_cooldown,0.55/1.15),"Claw hit interval matches 15 percent increased rate")
 p.shot_cooldown=0;game.attack();ensure(p.current_clip=="attack_right" and p.anim.has_animation("attack_right"),"Second claw uses separately imported real UMFi2 right-hand animation")
 ensure(not game.clientfx.animation_record(p,"attack_right").is_empty(),"Right-hand attack dispatches its own original sound/trail event record")
 p.shot_cooldown=0;game.attack();ensure(p.current_clip=="attack","Third claw alternates back to left hand")
 ensure(p.begin_roar(),"Roar interrupts normal claw without waiting for cooldown");await frames(30)
 for i in range(3):
  ensure(p.begin_roar() and p.anim.current_animation_position<0.001 and p.extra_health<=game.max_extra_health(),"Each press restarts howl; interrupted howls cannot accumulate shield: "+str(i));await frames(2)
 var seconds=p.anim.get_animation("roar").length;p.roar_effect.advance(seconds+0.1)
 ensure(not p.roar_effect.active and p.extra_health==game.max_extra_health(),"Completed normal howl restores current character and equipment YP capacity")
 var hp=game.health;game.take_damage(50);ensure(game.health==hp and p.extra_health==game.max_extra_health()-50,"Damage consumes YP before ordinary HP")
 game.take_damage(game.max_extra_health()-50+21);ensure(game.health==hp-21 and p.extra_health<=game.max_extra_health(),"Damage beyond remaining YP correctly reaches health")
 ensure(p.begin_roar(),"Roar immediately restarts after completion");p.roar_effect.advance(seconds+0.1);p.restore_howl_health();ensure(p.extra_health==game.max_extra_health(),"Repeated completion replenishes capacity without stacking")
 p.switch_form(true);ensure(p.extra_health==0,"Transformation clears temporary wolf health")
 ensure(game.game_audio.desired_music()=="","Active match has source ambience and effects without lobby music")
 game.pause_game();ensure(game.game_audio.desired_music()=="","Pausing a match does not switch to lobby music")
 game.show_home();game.pc_panel.navigate("room");ensure(game.game_audio.desired_music().ends_with("game.ogg"),"Waiting room uses original room/ready track")
 game.pc_panel.navigate("lobby");ensure(game.game_audio.desired_music().ends_with("lobby.ogg"),"Lobby list uses original lobby track")
 ensure(game.game_audio.master_limiter.ceiling_db==-1.0,"Simultaneous voices and weapon effects have a master peak limiter")
 game.queue_free();await frames()
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-019-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"physicalAndroidDeviceTested":false},"  ")+"\n");f.close();print("MOBILE_019_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
