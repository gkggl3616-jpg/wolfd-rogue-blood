extends SceneTree
const Book=preload("res://scripts/content_book.gd")
const Game=preload("res://scripts/game.gd")
const Equipment=preload("res://scripts/equipment.gd")
const Store=preload("res://scripts/atomic_store.gd")
var checks=0
var failures=[]
var game
func ensure(value,label):
 checks+=1
 if not value:failures.append(label);push_error(label)
func frames(n=3):
 for i in range(n):await process_frame
func physics(n=3):
 for i in range(n):await physics_frame
func _initialize():call_deferred("run")
func run():
 var folder="user://shop017-%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(folder)
 var ledger=Game.new();ledger.message=Label.new();ledger.wallet_storage_path=folder+"/wallet.json";ledger.book=Book.new(false,"",true);ledger.equipment=Equipment.new(false);ledger.shop_catalog.currencyPolicy.unlimited=[]
 ledger.sync_collection()
 ensure(ledger.book.weapons.filter(func(row):return ledger.book.owns(row.id)).size()==4,"Fresh offline player owns one weapon per starting slot, never all 903")
 ensure(ledger.book.characters.filter(func(row):return ledger.book.owns(row.id)).size()==2,"Fresh profile has only its red and blue default character")
 ensure(ledger.book.tattoos.filter(func(row):return ledger.book.owns(row.id)).size()==3,"Fresh profile has exactly one tattoo per body region")
 ensure(ledger.inbox.state.powerCounts.size()==5 and ledger.inbox.state.powerCounts.values().all(func(n):return n==1),"One starter per power slot, with finite counts")
 ensure(ledger.wallet.values().all(func(n):return n==0),"No automatic unlimited cash, KP, gold or GP")
 ensure(ledger.book.settings.directions,"Direction buttons are the new default")
 var before=ledger.inbox.state.duplicate(true);ledger.sync_collection();ensure(ledger.inbox.state==before,"Reopening cannot repeat the starter allowance")
 var candidate=ledger.book.weapons.filter(func(row):return row.get("available",false) and not ledger.book.owns(row.id) and not ledger.shop_offers(row.id).is_empty())[0]
 var offer=ledger.shop_offers(candidate.id)[0]
 ensure(not ledger.book.equip(candidate.id),"Unbought weapon cannot be equipped by bypassing the UI")
 var tattoo=ledger.book.tattoos.filter(func(row):return not ledger.book.owns(row.id) and row.role=="body")[0]
 ensure(not ledger.book.set_tattoo("body",tattoo.texture,tattoo.id),"Unbought tattoo cannot grant a power")
 var character=ledger.book.characters.filter(func(row):return row.get("available",false) and not ledger.book.owns(row.id))[0]
 ensure(not ledger.book.choose_character(character.id),"Unbought character cannot be equipped")
 ensure(not ledger.buy_shop(candidate.id,offer.currency,"insufficient").ok,"Insufficient funds cannot produce a gift")
 ledger.wallet[offer.currency]=int(offer.price)*3
 var bytes=FileAccess.get_file_as_bytes(ledger.wallet_storage_path);var initial=ledger.wallet.duplicate()
 DirAccess.make_dir_absolute(ledger.wallet_storage_path+".pending")
 ensure(not ledger.buy_shop(candidate.id,offer.currency,"blocked").ok and ledger.wallet==initial and ledger.inbox.state.messages.is_empty(),"Failed atomic purchase retains money and creates no item")
 ensure(FileAccess.get_file_as_bytes(ledger.wallet_storage_path)==bytes,"Failed purchase preserves durable ledger bytes")
 DirAccess.remove_absolute(ledger.wallet_storage_path+".pending")
 ensure(ledger.buy_shop(candidate.id,offer.currency,"buy-1").ok and ledger.wallet[offer.currency]==initial[offer.currency]-int(offer.price),"Purchase spends the exact selected original-table price")
 ensure(not ledger.collection_owned(candidate.id) and ledger.inbox.pending_count()==1,"Purchased item waits in gift box before inventory admission")
 var spent=ledger.wallet.duplicate();ensure(ledger.buy_shop(candidate.id,offer.currency,"buy-1").get("duplicate",false) and ledger.wallet==spent and ledger.inbox.state.messages.size()==1,"Replayed purchase never charges or grants twice")
 ensure(not ledger.buy_shop(candidate.id,offer.currency,"buy-2").ok,"Already pending permanent item cannot be purchased twice")
 var gift=ledger.inbox.state.messages[0].id
 DirAccess.make_dir_absolute(ledger.wallet_storage_path+".pending")
 ensure(not ledger.accept_gift(gift).ok and not ledger.collection_owned(candidate.id),"Failed gift acceptance cannot unlock an item")
 DirAccess.remove_absolute(ledger.wallet_storage_path+".pending")
 ensure(ledger.accept_gift(gift).ok and ledger.collection_owned(candidate.id) and ledger.book.equip(candidate.id),"Explicit gift acceptance unlocks and equips the purchased weapon")
 ensure(not ledger.accept_gift(gift).ok and ledger.wallet==spent,"Repeated acceptance cannot duplicate a permanent entitlement")
 var reopened=Game.new();reopened.message=Label.new();reopened.wallet_storage_path=ledger.wallet_storage_path;reopened.book=Book.new(false,"",true);reopened.equipment=Equipment.new(false);reopened.shop_catalog.currencyPolicy.unlimited=[];reopened.load_wallet();reopened.sync_collection()
 ensure(reopened.collection_owned(candidate.id) and reopened.wallet==spent,"Accepted purchase and balance survive process restart")
 ensure(not reopened.buy_shop("unknown","cash","fake").ok and not reopened.buy_shop(candidate.id,"fake","currency").ok,"Unknown item and forged currency are rejected")
 for kind in ["character","tattoo","power"]:
  var choices=ledger.shop_catalog.items.values().filter(func(item):return item.kind==kind and not item.offers.is_empty() and not ledger.collection_owned(item.id))
  if kind=="character":choices=choices.filter(func(item):return ledger.book.characters.any(func(entry):return entry.id==item.id and entry.get("available",false)))
  var item=choices[0];var price=item.offers[0];ledger.wallet[price.currency]=int(price.price)+2000
  ensure(ledger.buy_shop(item.id,price.currency,"typed-"+kind).ok and ledger.inbox.state.messages[-1].kind==kind,"Typed shop purchase produces the matching "+kind+" gift")
  ensure(ledger.accept_gift(ledger.inbox.state.messages[-1].id).ok and ledger.collection_owned(item.id),"Accepting purchased "+kind+" admits only the acquired item")
 ledger.boxes.state.counts.mystery=1
 var opened=ledger.box_action("open","mystery","ownership-box")
 ensure(opened.ok and ledger.collection_owned(opened.reward.rewardId),"Revealed box tattoo is admitted to the same authoritative ownership ledger")
 var revealed=opened.reward;ensure(ledger.book.set_tattoo(revealed.role,revealed.texture,revealed.rewardId),"Box reward equips its exact tattoo identity even when multiple items share a texture")
 ledger.inbox.state.entitlements.erase(revealed.rewardId);ledger.sync_collection()
 ensure(ledger.inbox.state.entitlements.has(revealed.rewardId) and ledger.collection_owned(revealed.rewardId),"Legacy validated box history migrates into durable entitlements before journal eviction")
 var all={}
 for row in ledger.book.weapons:all[row.id]=true
 var legacy_path=folder+"/legacy.json";Store.write_json(legacy_path,{"schemaVersion":2,"owned":all,"settings":{"directions":false},"character":ledger.book.characters.filter(func(entry):return entry.get("available",false) and not ledger.book.owns(entry.id))[0].id})
 var migrated=Book.new(true,legacy_path,true);migrated.apply_entitlements(ledger.inbox.state.entitlements)
 ensure(migrated.weapons.filter(func(row):return migrated.owns(row.id)).size()==5 and migrated.owns(candidate.id),"Migration drops old automatic all-unlock while preserving confirmed purchases")
 ensure(migrated.settings.directions and migrated.selected_character=="","Old offline controls migrate once and unowned selected character is cleared")
 ensure(migrated.set_setting("directions",false) and not Book.new(true,legacy_path,true).settings.directions,"Explicit later control preference survives schema-three reopening")
 var unlimited=Game.new();unlimited.message=Label.new();unlimited.wallet_storage_path=folder+"/unlimited-wallet.json";unlimited.book=Book.new(false,"",true);unlimited.equipment=Equipment.new(false);unlimited.sync_collection()
 ensure(unlimited.is_unlimited_currency("cash") and unlimited.is_unlimited_currency("kp") and not unlimited.is_unlimited_currency("gold") and not unlimited.is_unlimited_currency("gp"),"User-requested unlimited allowance applies only to local Nakit and KP")
 ensure(unlimited.wallet_text("cash")=="∞" and unlimited.wallet_text("kp")=="∞" and unlimited.wallet_text("gold")=="0","Unlimited currencies display an infinity marker while gold and GP stay finite")
 ensure(unlimited.book.weapons.filter(func(entry):return unlimited.book.owns(entry.id)).size()==4,"Unlimited currency never auto-unlocks the item catalogue")
 var cash_item=unlimited.book.weapons.filter(func(entry):return entry.get("available",false) and not unlimited.collection_owned(entry.id) and unlimited.shop_offers(entry.id).any(func(price):return price.currency=="cash"))[0]
 unlimited.wallet.cash=0
 ensure(unlimited.buy_shop(cash_item.id,"cash","infinite-cash").ok and unlimited.wallet.cash==1000000000 and not unlimited.collection_owned(cash_item.id),"Unlimited cash purchase succeeds even after a zero legacy balance and still requires gift acceptance")
 ensure(unlimited.accept_gift(unlimited.inbox.state.messages[-1].id).ok and unlimited.collection_owned(cash_item.id),"Unlimited-currency item enters inventory only on explicit gift acceptance")
 unlimited.wallet.kp=0
 ensure(unlimited.buy_shop("19601","kp","infinite-kp").ok and unlimited.wallet.kp==1000000000,"KP price is displayed but unlimited KP is not consumed")
 var unspent=unlimited.wallet.duplicate()
 ensure(unlimited.box_action("buy","mystery","infinite-box").ok and unlimited.wallet==unspent,"Buying a box also preserves unlimited cash")
 var pending=unlimited.inbox.state.duplicate(true);var cash_gift=unlimited.inbox.enqueue(pending,"cash","cash","Nakit ödülü",50,"infinite-reward","Sistem");unlimited.inbox.state=pending
 ensure(unlimited.accept_gift(cash_gift.id).ok and unlimited.wallet.cash==1000000000,"Cash reward is accepted without an overflow failure under unlimited allowance")
 var old_wallet=unlimited.wallet.duplicate();var old_box=unlimited.inbox.state.duplicate(true);DirAccess.make_dir_absolute(unlimited.wallet_storage_path+".pending")
 ensure(not unlimited.buy_shop("19602","kp","infinite-failure").ok and unlimited.wallet==old_wallet and unlimited.inbox.state==old_box,"Unlimited currency does not bypass atomic-save failure or grant an unsaved item")
 DirAccess.remove_absolute(unlimited.wallet_storage_path+".pending")
 unlimited.wallet.gold=250;unlimited.wallet.gp=42;unlimited.save_wallet()
 var infinite_reopen=Game.new();infinite_reopen.message=Label.new();infinite_reopen.wallet_storage_path=unlimited.wallet_storage_path;infinite_reopen.book=Book.new(false,"",true);infinite_reopen.equipment=Equipment.new(false);infinite_reopen.load_wallet();infinite_reopen.sync_collection()
 ensure(infinite_reopen.wallet_text("cash")=="∞" and infinite_reopen.wallet_text("kp")=="∞" and infinite_reopen.wallet.gold==250 and infinite_reopen.wallet.gp==42 and infinite_reopen.collection_owned(cash_item.id),"Restart retains unlimited-currency mode, finite progression and purchased ownership together")
 for source in [unlimited,infinite_reopen]:source.message.free();source.free()
 for source in [ledger,reopened]:source.message.free();source.free()
 game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
 game.book=Book.new(false,"",true);game.sync_collection();game.apply_settings()
 game.show_library("Envanter");ensure(game.library_panel.detail_helper.entries.size()==4,"Inventory screen contains only the four owned weapons")
 game.library_panel.detail_helper.switch_collection_mode();ensure(game.library_panel.page=="Mağaza" and game.library_panel.detail_helper.entries.size()==903,"Shop switch exposes the full imported weapon catalogue")
 game.library_panel.detail_helper.switch_collection_mode();ensure(game.library_panel.page=="Envanter" and game.library_panel.detail_helper.loadout_tabs.size()==5 and game.library_panel.detail_helper.entries.size()==4,"Switching back restores owned inventory and all five equipment tabs")
 game.library_panel.navigate("Mağaza")
 game.library_panel.navigate("power");ensure(is_instance_valid(game.library_panel.preview_model) and game.library_panel.detail_helper.equipped_cards.is_empty(),"Power shop shows the large real wolf preview instead of inventory slot placeholders")
 game.library_panel.navigate("Dövmeler");ensure(game.library_panel.detail_helper.entries.filter(func(row):return not row.get("placeholder",false)).size()==816,"Shop shows every distinct tattoo, with older same-art gold OG aliases consolidated")
 game.library_panel.collection_shop=false;game.library_panel.refresh();ensure(game.library_panel.detail_helper.entries.filter(func(row):return not row.get("placeholder",false)).size()==3,"Tattoo inventory excludes unbought family members")
 game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 await physics(30);await frames()
 ensure(game.touch.direction_buttons and game.touch.buttons.slice(7,11).all(func(button):return button.visible),"Four circular direction targets replace the default joystick")
 game.equipment.equip_power(0);await frames();ensure(not game.touch.buttons[5].visible,"Wolf-run button hides without equipped ability")
 ensure(game.equip_power_item("19601"),"Owned starter wolf ability can be equipped")
 await frames();ensure(not game.touch.buttons[5].visible,"Requested redundant wolf-run target remains removed with equipped ability")
 game.touch.buttons[5].pressed.emit();await physics(2);ensure(game.player.wolf_run_armed and not game.player.wolf_running,"Run button arms the ability without moving a stationary wolf")
 Input.action_press("forward");await physics(2);ensure(game.player.wolf_running,"Forward input starts the armed four-legged wolf run")
 Input.action_release("forward");await physics(2);game.player.reset_locomotion()
 Input.action_press("forward");await physics(2);Input.action_release("forward");await physics(2);Input.action_press("forward");await physics(2)
 ensure(game.player.wolf_running,"Double forward tap starts wolf run using the source ability rule")
 Input.action_release("forward");await physics(2);game.equipment.equip_power(0);await physics(2);await frames()
 ensure(not game.player.wolf_running and not game.player.wolf_run_armed and not game.touch.buttons[5].visible,"Removing the ability stops wolf run and removes its button")
 # Position and orientation are independent: a cry socket must not rotate
 # the ground ring onto its side, and nested hand effects must travel with it.
 var row=game.book.characters.filter(func(entry):return entry.id=="pair-model48")[0];game.book.owned[row.id]=true;game.book.choose_character(row.id);game.local_room.team=row.sourceTeam;game.start_round();game.spawn_clock=10000
 if not game.player.is_wolf:game.player.switch_form(true)
 await frames(25)
 var fx=game.clientfx.play("Howling_Fire_1",game.player);await frames(2)
 var ring=fx.parts.filter(func(part):return part.spec.type=="LTBModel")[0].node
 ensure(ring.global_basis.y.normalized().dot(Vector3.UP)>.99,"Cry socket no longer tilts the original ground-ring model sideways")
 ensure(Vector2(ring.global_position.x-game.player.global_position.x,ring.global_position.z-game.player.global_position.z).length()<.7,"Roar ground-ring offset stays under the actor rather than left of its neck")
 var projectile=game.clientfx.play("Fireball_SE",game.player);await frames(3)
 var nested=game.clientfx.active.filter(func(node):return is_instance_valid(node) and node.depth==1)[0];var part=nested.parts[0].node;var point=part.global_position
 game.player.set_physics_process(false);game.player.position.x+=2;await frames(3)
 ensure(absf(part.global_position.x-point.x-2)<.1,"Nested fixed fly effect follows the moving hand reference instead of freezing in world space")
 game.queue_free();await frames()
 var f=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/shop-controls-017-validation.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  ")+"\n");f.close();print("SHOP_CONTROLS_017_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
