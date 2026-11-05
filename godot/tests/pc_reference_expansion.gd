extends SceneTree
const Lock=preload("res://scripts/profile_lock.gd")
const Store=preload("res://scripts/atomic_store.gd")
const Layout=preload("res://ui/source_layout.gd")
var checks=0
var failures=[]
var game
func _initialize():call_deferred("run")
func ensure(value,caption):
	checks+=1
	if not value:failures.append(caption);push_error("PC_REFERENCE_FAIL "+caption)
func frames(count=4):
	for i in range(count):await process_frame
func run():
	var directory="user://pc-reference-qa-%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(directory)
	var path=directory+"/pin.json";var lock=Lock.new(true,path)
	ensure(lock.unlocked and not lock.is_enabled(),"existing profiles do not acquire a mandatory PIN")
	for invalid in ["123","12345"," 123","+123","12a4"]:ensure(not lock.configure(invalid),"PIN accepts exactly four ASCII digits: "+invalid)
	ensure(lock.configure("0246"),"PIN configuration is durable")
	var saved=Store.read_json(path).data
	ensure(not saved.has("pin") and saved.salt.length()==32 and saved.digest.length()==64,"PIN file stores salt/digest, not the entered code")
	lock=Lock.new(true,path);ensure(not lock.unlocked and not lock.verify("0000"),"reopening the profile requires the configured PIN")
	ensure(lock.verify("0246") and lock.unlocked,"correct PIN unlocks the local profile")
	ensure(not lock.configure("1357","9999"),"changing a PIN requires its current value")
	var original=FileAccess.get_file_as_bytes(path);DirAccess.make_dir_absolute(path+".pending")
	ensure(not lock.configure("1357","0246") and FileAccess.get_file_as_bytes(path)==original,"failed PIN save preserves the old credential")
	DirAccess.remove_absolute(path+".pending")
	ensure(lock.configure("1357","0246") and not Lock.new(true,path).verify("0246"),"successful PIN rotation invalidates the previous code")
	for i in range(5):lock.verify("9999")
	ensure(not lock.verify("1357"),"five wrong attempts trigger the local retry delay")
	lock.retry_at=0;ensure(lock.disable("1357") and Lock.new(true,path).unlocked,"removing the optional lock survives reopening")
	Store.write_json(path,{"version":99});var corrupt=Lock.new(true,path)
	ensure(corrupt.blocked and not corrupt.unlocked and not corrupt.configure("1111"),"unrecognized lock data is preserved and fails closed")
	var ledger=load("res://scripts/game.gd").new();ledger.wallet_storage_path=directory+"/wallet.json";ledger.message=Label.new()
	ensure(not ledger.box_action("buy","mystery","empty").ok and ledger.boxes.state.counts.is_empty(),"insufficient funds cannot create a box")
	ensure(ledger.grant_money("cash",500,"QA"),"local test balance is durably granted")
	ensure(ledger.box_action("buy","mystery","purchase-1").ok and ledger.wallet.cash==400,"one purchase spends the configured local amount")
	ensure(ledger.box_action("buy","mystery","purchase-1").get("duplicate",false) and ledger.wallet.cash==400 and ledger.boxes.state.counts.mystery==1,"repeated purchase request cannot spend twice")
	original=FileAccess.get_file_as_bytes(ledger.wallet_storage_path);DirAccess.make_dir_absolute(ledger.wallet_storage_path+".pending")
	ensure(not ledger.box_action("open","mystery","open-failure").ok and ledger.boxes.state.counts.mystery==1 and ledger.boxes.state.history.is_empty(),"failed opening save consumes no box and grants no reward")
	ensure(FileAccess.get_file_as_bytes(ledger.wallet_storage_path)==original,"failed opening leaves the entire previous wallet/box record intact")
	DirAccess.remove_absolute(ledger.wallet_storage_path+".pending")
	var result=ledger.box_action("open","mystery","open-1")
	ensure(result.ok and ledger.boxes.state.counts.mystery==0 and ledger.boxes.state.history.size()==1,"opening consumes one box and durably records one actual cosmetic")
	ensure(ledger.box_action("open","mystery","open-1").get("duplicate",false) and ledger.boxes.state.history.size()==1,"repeated reveal cannot grant a second cosmetic")
	ensure(not ledger.box_action("open","mystery","open-empty").ok,"empty inventory cannot be opened")
	var reopened=load("res://scripts/game.gd").new();reopened.wallet_storage_path=ledger.wallet_storage_path;reopened.load_wallet()
	ensure(reopened.wallet.cash==400 and reopened.boxes.state.history[0].rewardId==result.reward.rewardId,"balance, count and reward survive process-style reload together")
	var bad=ledger.boxes.state.duplicate(true);bad.history[0].texture="res://not-a-reward.png"
	ensure(not ledger.boxes.valid_state(bad),"saved reward paths must match the real allowed cosmetic")
	ensure(ledger.grant_money("gp",10,"QA") and Store.read_json(ledger.wallet_storage_path).data.localBoxes.history.size()==1,"later wallet grants retain the box journal")
	ensure(not ledger.claim_career("first").ok and not ledger.claim_career("pass-1").ok,"unearned mission and pass rewards cannot be claimed")
	ledger.career.state.totals.matches=1
	DirAccess.make_dir_absolute(ledger.wallet_storage_path+".pending");var before=ledger.wallet.cash
	ensure(not ledger.claim_career("first").ok and ledger.wallet.cash==before and not ledger.career.state.claimed.has("first"),"failed reward save changes neither balance nor claim state")
	DirAccess.remove_absolute(ledger.wallet_storage_path+".pending")
	ensure(ledger.claim_career("first").ok and ledger.wallet.cash==before+100,"earned local mission pays its actual durable reward")
	ensure(not ledger.claim_career("first").ok and ledger.wallet.cash==before+100,"mission cannot pay twice")
	ledger.grant_money("gp",90,"QA")
	ensure(ledger.claim_career("pass-1").ok and not ledger.claim_career("pass-1").ok,"earned pass tier is an exactly-once local claim")
	ensure(not ledger.claim_career("pass-0").ok and not ledger.claim_career("pass-11").ok,"pass tier bounds reject fabricated rewards")
	reopened.load_wallet();ensure(reopened.career.state.claimed.get("first",false) and reopened.career.state.claimed.get("pass-1",false),"reward claims survive reopening alongside the box journal")
	ledger.message.free();ledger.free();reopened.free()
	root.size=Vector2i(1280,720);game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	ensure(game.map_catalog.photos.size()==19,"all 19 selected maps have exact-source photos")
	for number in game.map_catalog.photos:
		var photo=game.map_catalog.photo(number)
		ensure(not game.map_catalog.map_record(number).is_empty() and FileAccess.get_sha256(photo.asset)==photo.sha256,"map photo has the selected map identity and verified PNG: "+str(number))
	ensure(game.ranks.current(0).name=="Gönüllü Er" and game.ranks.current(99).name=="Gönüllü Er" and game.ranks.current(100).name=="Acemi Er","local rank changes exactly at the defined GP boundary")
	ensure(game.ranks.catalog.ranks.size()==62 and game.ranks.catalog.ranks.all(func(row):return row.name!="GM"),"source rank catalogue excludes the privileged GM badge")
	for role in ["left","right"]:
		var arm=game.book.tattoos.filter(func(row):return row.role==role)[0]
		ensure(arm.has("roleEvidence") and game.book.set_tattoo(role,arm.texture),"explicit PC slot labels unlock actual "+role+" arm tattoos")
	game.player.apply_tattoos()
	for mesh_name in ["Tattoo_Arm_L","Tattoo_Arm_R"]:
		var meshes=game.player.wolf.find_children(mesh_name,"MeshInstance3D",true,false)
		ensure(meshes.size()==1 and meshes[0].visible and meshes[0].material_override is StandardMaterial3D,"source UV surface really receives the selected tattoo: "+mesh_name)
	for box in game.boxes.catalog.boxes:
		ensure(not box.rewards.is_empty() and box.rewards.all(func(row):return game.book.tattoo_matches_role(row.role,row.texture)),"every selectable box has real usable cosmetic outcomes: "+box.id)
	game.pc_panel.navigate("pin");var pin_ui=game.pc_panel.detail_helper
	ensure("interface/wolfsecondpassword" in game.pc_panel.source_layouts and pin_ui.slots.size()==4,"PIN uses the source four-slot dialog")
	for digit in ["2","4","6","8"]:pin_ui.press(digit)
	pin_ui.submit()
	for digit in ["2","4","6","8"]:pin_ui.press(digit)
	pin_ui.submit();ensure(game.profile_lock.is_enabled(),"actual keypad UI can configure an optional local PIN")
	game.show_home();game.pc_panel.navigate("create_room");var ui=game.pc_panel
	var mode_index=-1
	for i in range(ui.room_mode.item_count):
		if ui.room_mode.get_item_id(i)==game.LocalHunt.MODE:mode_index=i
	ensure(mode_index>=0,"room picker separates the new local hunt from original catalog-only modes")
	ensure("interface/createfield" in ui.source_layouts and not "section/prideladder/prideladdercreateroomdialog" in ui.source_layouts,"detailed PC reference uses the ordinary room creator rather than the clan-ladder dialog")
	ui.room_mode.select(mode_index);ui.room_mode.item_selected.emit(mode_index)
	ensure(ui.room_map.item_count==20 and ui.room_form.visible,"local hunt retains all 19 selected maps and an actual form selector")
	ui.links["▣"].pressed.emit()
	ensure(ui.modal!=null and ui.modal.find_children("*","TextureRect",true,false).any(func(node):return node.texture!=null),"map gallery renders source photos as selectable map buttons")
	ui.close_modal();game.local_room={"title":"QA Av","mode":game.LocalHunt.MODE,"map":84,"playerForm":"wolf","botDifficulty":"hard","team":"blue"}
	ensure(game.start_round(),"hunt starts on the selected real source map")
	game.spawn_clock=1000;await frames(10);game.set_process(false);game.player.set_physics_process(false)
	ensure(game.player.is_wolf and game.hunt.enemy_kind()=="human","wolf-side hunt creates human opposition")
	game.player.switch_form();ensure(game.player.is_wolf,"hunt cannot bypass its fixed team form")
	game.spawn_enemy();var bot=game.enemies.get_child(0);bot.brain_enabled=false
	ensure(bot.kind=="human" and bot.health==100 and bot.profile.name=="Zor","selected bot difficulty and equal health apply in hunt")
	game.finish_hunt_round(true);var wins=game.hunt.wins;game.finish_hunt_round(true)
	ensure(game.hunt.wins==wins and game.hunt.phase=="intermission","duplicate final-hit callbacks cannot win a round twice")
	var health=game.health;game.take_damage(8);ensure(game.health==health,"intermission blocks late incoming damage")
	game.pause_game_menu();var countdown=game.hunt.intermission;game._process(1);ensure(game.hunt.intermission==countdown,"menu freezes the next-round countdown")
	game.resume();game.advance_hunt(3.1);ensure(game.hunt.round_number==2 and game.health==100 and game.hunt.phase=="combat","next hunt round restores a playable state")
	game.take_damage(100);ensure(game.hunt.losses==1 and game.running,"death loses one hunt round without skipping directly to final results")
	game.advance_hunt(3.1);game.finish_hunt_round(true)
	ensure(not game.running and game.last_result.wins==2 and game.last_result.losses==1,"three-round hunt produces the actual final score")
	game.local_room={"title":"QA Öğretici","mode":game.LocalTutorial.MODE,"map":0}
	ensure(game.start_round() and game.tutorial.active and not game.hunt.active,"tutorial is a distinct playable local mode")
	game.spawn_clock=0;game._process(0.2);ensure(game.enemies.get_children().all(func(node):return node.is_queued_for_deletion()),"tutorial does not spawn unrelated random combat bots")
	game.player.position.x+=3;game._process(0.1);ensure(game.tutorial.step==1,"tutorial advances after actual player displacement")
	game.player.set_physics_process(true);await frames(20)
	Input.action_press("jump");await frames(2);Input.action_release("jump");game._process(0.01)
	ensure(game.tutorial.step==2,"tutorial jump step requires actual airborne motion")
	game.player.switch_form();game._process(0.01);ensure(game.tutorial.step==3,"tutorial requires the actual wolf transformation")
	game.player.action_time=0;game.player.begin_roar();game._process(0.01);ensure(game.tutorial.step==4,"tutorial observes the real roar state")
	game.player.roar_effect.stop();game.player.action_time=0;await frames(90)
	game.player.begin_roll();game._process(0.01);ensure(game.tutorial.step==5,"tutorial observes the actual collision-checked roll")
	game.player.end_roll();game.player.action_time=0;game.attack();game._process(0.01);ensure(game.tutorial.step==6,"tutorial observes an actual claw action")
	game.player.switch_form();game._process(0.01);ensure(game.tutorial.step==7 and game.ammo<game.weapon_capacity(),"tutorial supplies one used cartridge for the reload exercise")
	game.reload_weapon();game._process(0.01);ensure(not game.running and game.last_result.title=="Öğretici tamamlandı","all eight actual exercises finish the tutorial")
	game.local_room={"mode":0,"map":0};game.start_round();game.spawn_clock=1000;game.player.position=Vector3(0,0.1,5);game.player.set_physics_process(false)
	game.spawn_enemy("human");await frames(5)
	var target=game.enemies.get_children().filter(func(node):return not node.is_queued_for_deletion())[-1];target.brain_enabled=false;target.set_physics_process(false);target.position=Vector3(0,0.1,0);await frames(3)
	var skeleton=target.body.find_children("*","Skeleton3D",true,false)[0];var head=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("Bip01 Head")).origin
	ensure(target.is_head_hit(head) and not target.is_head_hit(target.position+Vector3.UP*0.5),"headshot region follows the real source head bone")
	game.player.camera.look_at(head);game.player.shot_cooldown=0;game.attack()
	ensure(game.match_stats.headshots==1 and game.match_stats.damage==mini(100,int(game.player.weapon_info.damage)*2),"actual head-aimed physics shot records the configured local multiplier and real damage")
	var sniper=game.book.weapons.filter(func(row):return row.category=="sniper" and row.get("available",false))[0];game.book.acquire(sniper.id)
	ensure(game.equip_library_weapon(sniper),"real imported sniper model can be equipped for scoped aim")
	Input.action_press("aim");game.player._physics_process(0.2);game.source_hud.refresh_from_game()
	ensure(game.source_hud.scope.visible and game.player.camera.fov<30 and not game.player.viewmodel.visible,"scoped aim hides the viewmodel and displays actual circular zoom")
	Input.action_release("aim");game.player._physics_process(0.2);game.source_hud.refresh_from_game()
	ensure(not game.source_hud.scope.visible and game.player.viewmodel.visible,"releasing aim restores the ordinary weapon view")
	var unknown=game.book.tattoos.filter(func(row):return row.role=="unknown")[0];ensure(not game.book.set_tattoo("body",unknown.texture),"new tattoo equipment still rejects unverified UV roles")
	game.show_library("Dövmeler");ui=game.library_panel;ensure(ui.detail_helper.role_picker.item_count==4,"wolf inventory exposes real body/left/right region filtering")
	ui.detail_helper.role_picker.select(1);ui.detail_helper.role_picker.item_selected.emit(1)
	ensure(ui.detail_helper.entries.all(func(row):return row.role=="body"),"body filter never mixes arm or unresolved tattoo entries")
	ui.preview_input(__drag_event());ensure(not is_zero_approx(ui.preview_angle),"preview drag rotates the actual source model")
	ui.navigate("wolfpass");ensure("interface/wolfpass/wolfpassdlg" in ui.source_layouts,"pass uses the native PC reward-track dialog")
	ui.navigate("missions");ensure("interface/wolfpass/wolfpassmissiondlg" in ui.source_layouts,"local mission progress uses the PC mission dialog")
	game.show_home();game.pc_panel.navigate("create_room");ensure(game.pc_panel.room_draft.team=="blue" and game.pc_panel.room_title.text=="Yerel Oda","minimal older room data receives safe title/team defaults in the source creator")
	game.queue_free();await frames()
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"sourceMapPhotos":19,"sourceRanks":62,"explicitSourceArmTattoos":59,"physicalAndroidDeviceTested":false,"originalPcRulesEquivalenceValidated":false}
	var file=FileAccess.open(ProjectSettings.globalize_path("res://../docs/pc-reference-expansion-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	print("PC_REFERENCE_EXPANSION_QA ",checks," checks; failures=",failures);quit(0 if failures.is_empty() else 1)
func __drag_event():
	game.library_panel.preview_drag=true
	var event=InputEventMouseMotion.new();event.relative=Vector2(50,0);return event
