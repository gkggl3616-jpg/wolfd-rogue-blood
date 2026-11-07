extends SceneTree
const Game=preload("res://scripts/game.gd")
const Store=preload("res://scripts/atomic_store.gd")
const Book=preload("res://scripts/content_book.gd")
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func ensure(value,caption):
	checks+=1
	if not value:failures.append(caption);push_error("ROUND_EQUIPMENT_FAIL "+caption)
func frames(n=3):
	for i in range(n):await process_frame
func run():
	var directory="user://equipment-gifts-%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(directory)
	var ledger=Game.new();ledger.wallet_storage_path=directory+"/wallet.json";ledger.message=Label.new()
	ledger.seed_gifts();ensure(ledger.inbox.pending_count()==2 and ledger.inbox.state.powerCounts.is_empty(),"welcome supplies wait for explicit acceptance")
	ledger.seed_gifts();ensure(ledger.inbox.pending_count()==2,"welcome delivery cannot repeat")
	var first=ledger.inbox.state.messages[0].id
	DirAccess.make_dir_absolute(ledger.wallet_storage_path+".pending")
	var original=FileAccess.get_file_as_bytes(ledger.wallet_storage_path)
	ensure(not ledger.accept_gift(first).ok and ledger.inbox.state.powerCounts.is_empty(),"failed atomic save cannot grant a supply")
	ensure(FileAccess.get_file_as_bytes(ledger.wallet_storage_path)==original,"failed acceptance preserves durable pending message")
	DirAccess.remove_absolute(ledger.wallet_storage_path+".pending")
	ensure(ledger.accept_gift(first).ok and ledger.inbox.state.powerCounts["19002"]==3,"accepting grants exactly the received quantity")
	ensure(not ledger.accept_gift(first).ok and ledger.inbox.state.powerCounts["19002"]==3,"double acceptance cannot duplicate inventory")
	ledger.inbox.state.messages[1].created=Time.get_unix_time_from_system()-8*86400;ledger.inbox.state.messages[1].expires=Time.get_unix_time_from_system()-1
	ensure(not ledger.accept_gift(ledger.inbox.state.messages[1].id).ok,"expired pending item cannot be claimed")
	ledger.grant_money("cash",500,"QA")
	ensure(ledger.buy_power("19502","energy-1").ok and ledger.wallet.cash==450,"power purchase uses its real local price")
	ensure(ledger.buy_power("19502","energy-1").get("duplicate",false) and ledger.wallet.cash==450,"repeated purchase does not spend twice")
	ensure(ledger.inbox.state.powerCounts.get("19502",0)==0,"unaccepted purchase cannot be equipped or consumed")
	ensure(not ledger.equip_power_item("19502"),"power slot refuses unaccepted item")
	var energy=ledger.inbox.state.messages[-1].id
	ensure(ledger.accept_gift(energy).ok and ledger.equip_power_item("19502"),"accepted supply can be equipped")
	ensure(ledger.box_action("buy","mystery","box-1").ok and ledger.boxes.state.counts.get("mystery",0)==0,"box purchase enters gift inbox first")
	ensure(not ledger.box_action("open","mystery","box-early").ok,"unaccepted box cannot be opened")
	ensure(ledger.accept_gift(ledger.inbox.state.messages[-1].id).ok and ledger.box_action("open","mystery","box-open").ok,"accepted box opens exactly once")
	ledger.career.state.totals.matches=1;var cash=ledger.wallet.cash
	ensure(ledger.claim_career("first").ok and ledger.wallet.cash==cash,"mission is delivered without immediate cash grant")
	ensure(ledger.accept_gift(ledger.inbox.state.messages[-1].id).ok and ledger.wallet.cash==cash+100,"mission cash enters wallet only after acceptance")
	var reload=Game.new();reload.wallet_storage_path=ledger.wallet_storage_path;reload.load_wallet()
	ensure(int(reload.inbox.state.powerCounts.get("19002",0))==3 and int(reload.inbox.state.powerCounts.get("19502",0))==1 and reload.inbox.state.powerSlots==ledger.inbox.state.powerSlots and reload.inbox.state.messages.size()==ledger.inbox.state.messages.size() and reload.inbox.state.messages[0].status=="accepted" and int(reload.boxes.state.counts.get("mystery",-1))==0 and reload.wallet==ledger.wallet,"messages, slots, supplies, boxes and wallet reload together")
	var invalid=ledger.inbox.state.duplicate(true);invalid.messages.append(invalid.messages[0]);ensure(not ledger.inbox.valid(invalid),"duplicate stored gift IDs are rejected")
	var book=Book.new(true,directory+"/book.json");ensure(book.select_mutation("guardian") and Book.new(true,book.storage_path).wolf_mutation=="guardian","mutation choice persists")
	ensure(not book.select_mutation("fake"),"unknown mutation is rejected")
	ledger.message.free();ledger.free();reload.free()
	root.size=Vector2i(1280,720);var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	for row in game.mutations.catalog.models:
		ensure(FileAccess.get_sha256(row.asset)==row.sha256,"mutation model matches source-derived checksum: "+row.id+row.team)
		var model=load(row.asset).instantiate();game.add_child(model);var animator=model.find_children("*","AnimationPlayer",true,false)[0];var skeleton=model.find_children("*","Skeleton3D",true,false)[0]
		for clip in ["idle","run","jump","attack","roar","airborne_attack"]:
			ensure(animator.has_animation(clip) and animator.get_animation(clip).length>0,"both teams retain real source motion: "+row.id+row.team+clip)
			animator.play(clip);animator.advance(minf(0.3,animator.get_animation(clip).length*0.5))
			var finite=true
			for bone in range(skeleton.get_bone_count()):
				var pose=skeleton.get_bone_global_pose(bone);finite=finite and pose.origin.is_finite() and pose.origin.length()<10000 and pose.basis.determinant()>0.001
			ensure(finite,"source animation has bounded finite skeleton: "+row.id+row.team+clip)
		model.get_parent().remove_child(model);model.free()
	game.local_room={"mode":0,"map":0,"team":"blue"};ensure(game.start_round(true) and game.selection_active,"interactive match begins with the equipment selector")
	game.set_process(false);game.player.set_physics_process(false);game.spawn_clock=1000
	var remaining=game.time_left;var health=game.health;game._process(1);game.take_damage(8);game.attack()
	ensure(game.time_left==remaining and game.health==health and game.match_stats.attacks==0,"selection freezes combat, bot damage and match time")
	var panel=game.selection_panel;game.menu_open=true;var clock=panel.remaining;panel._process(1);ensure(panel.remaining==clock,"menu pauses selection countdown")
	game.menu_open=false;game.application_suspended=true;panel._process(1);ensure(panel.remaining==clock,"background pauses selection countdown")
	game.application_suspended=false;ensure(game.choose_round_loadout(2) and game.book.active_loadout==2 and not game.selection_active,"equipment card really selects the saved set")
	ensure(game.book.loadout_names==["Standart","SLH 1","SLH 2","SLH 3","SLH 4"],"five loadout tabs match the supplied reference")
	game.health=60;game.player.switch_form();ensure(game.selection_active and not game.player.is_wolf,"transform requests a mutation choice")
	game.match_sp=10000 # Fund the paid-mutation fixture; fresh-match zero SP is covered by mobile_021.
	for id in ["power","guardian","ghost","normal"]:
		if not game.selection_active:game.open_round_selection("wolf")
		ensure(game.choose_round_mutation(id) and game.player.mutation_id==id,"choice installs source mutation body: "+id)
		ensure(is_equal_approx(game.player.wolf.rotation.y,PI),"mutation keeps the verified in-game forward orientation: "+id)
		var model=game.player.wolf;var skeleton=model.find_children("*","Skeleton3D",true,false)[0]
		ensure(absf(skeleton.get_bone_pose_rotation(0).dot(Quaternion(0,1,0,0)))>0.99,"source idle posture is applied before rendering: "+id)
		var clips=model.find_children("*","AnimationPlayer",true,false)[0]
		for name in ["idle","run","jump","attack","roar"]:ensure(clips.has_animation(name),"source mutation has actual "+id+" "+name)
		ensure(absf(float(game.health)/game.max_health()-0.6)<0.02,"mutation changes preserve health fraction: "+id)
		for mesh in model.find_children("*","MeshInstance3D",true,false):ensure(mesh.get_aabb().size.is_finite() and mesh.get_aabb().size.length()<1000,"finite source model bounds: "+id)
	game.open_round_selection("wolf");game.choose_round_mutation("guardian");game.health=100;ensure(game.player.begin_guard(),"guardian activates finite-energy defense")
	game.take_damage(8);ensure(game.health==96 and game.player.mutation_energy==60,"guardian defense reduces received damage and spends energy")
	game.open_round_selection("wolf");game.choose_round_mutation("ghost");ensure(game.player.begin_cloak() and game.player.is_cloaked(),"ghost cloak activates when stationary")
	game.spawn_enemy("human");await frames();var bot=game.enemies.get_children().filter(func(x):return not x.is_queued_for_deletion())[-1];bot.set_physics_process(false);bot.position=game.player.position+Vector3(0,0,-8)
	ensure(not bot.can_see_player(),"distant bot perception respects ghost concealment")
	game.wolf_melee_hit(1,1,"QA");ensure(not game.player.is_cloaked(),"attacking breaks concealment")
	game.inbox.state.powerCounts={"19002":3,"19502":3};ensure(game.equip_power_item("19002") and game.equip_power_item("19502"),"accepted supplies attach to distinct power slots")
	game.health=20;ensure(game.use_power("support") and game.health==game.max_health() and game.inbox.state.powerCounts["19002"]==2,"healing is capped by mutation health and consumes one charge")
	ensure(not game.use_power("support") and game.inbox.state.powerCounts["19002"]==2,"full health does not consume a charge")
	ensure(game.use_power("energy") and game.booster_remaining==10 and game.health<game.max_health(),"energy trades actual health for a timed boost")
	ensure(not game.use_power("energy") and game.inbox.state.powerCounts["19502"]==2,"active energy boost cannot consume another charge")
	game.open_round_selection("wolf");game.selection_panel._process(11);ensure(not game.selection_active,"countdown expiry resumes without changing selection")
	game.show_home();game.pc_panel.navigate("power");var ui=game.pc_panel;ensure(ui.detail_helper.entries.size()==game.power_catalog.items.size()+game.equipment.rules.items.size(),"power inventory contains real existing dash plus six new supplies")
	ui.filter_id="bag";ui.detail_helper.refresh_grid();ensure(ui.detail_helper.entries.size()==1 and ui.detail_helper.entries[0].id=="13006","bag tab filters real bag items")
	ui.filter_id="claw";ui.detail_helper.refresh_grid();ensure(ui.detail_helper.entries.size()==game.power_catalog.items.filter(func(row):return row.slot=="claw").size(),"claw tab contains claws while wolf ability stays in other powers")
	ui.navigate("gifts");ensure("interface/giftbox" in ui.source_layouts and ui.detail_helper.view!=null,"gift page uses the PC gift window")
	for link in ["Etkinlikler","Sıralama","Mağaza","Envanter","Klan","Hediyeler","Arkadaşlar","Profil","Web","Ayarlar","Geri","Diğer"]:ensure(ui.links.has(link),"toolbar route exists: "+link)
	ensure(not ui.links.has("WOLF\nPASS") and not ui.links.has("‹ KLAN ZİNCİRİ ›"),"removed pass and chain toolbar controls stay absent")
	game.local_room={"mode":game.WOLF_BATTLE,"map":0};ensure(game.start_round(true) and game.player.is_wolf and game.selection_panel.kind=="wolf","wolf battle starts with mutation choice")
	game.close_round_selection();game.player.switch_form();ensure(game.player.is_wolf,"wolf battle cannot switch into human form")
	game.spawn_enemy();await frames();ensure(game.enemies.get_children().filter(func(x):return not x.is_queued_for_deletion())[-1].kind=="wolf","wolf battle spawns wolf opposition")
	game.show_home();ensure(not game.selection_active,"leaving match clears selection")
	var report={"checks":checks,"failures":failures,"passed":failures.is_empty(),"physicalAndroidDeviceTested":false,"sourcePcNumericStatsVerified":false};var file=FileAccess.open("res://../docs/round-equipment-gift-validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
	game.queue_free();await frames();print("ROUND_EQUIPMENT_QA ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
