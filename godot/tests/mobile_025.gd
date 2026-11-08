extends SceneTree
var game
var checks=0
var failures=[]
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(n=4):
	for i in range(n):await process_frame
func _initialize():call_deferred("run")
func key(code,echoed=false):
	var event=InputEventKey.new();event.physical_keycode=code;event.pressed=true;event.echo=echoed;game._input(event)
func run():
	game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(65);game.player.set_physics_process(false);game.spawn_clock=10000
	var p=game.player;game.inbox.state.powerCounts={"19001":1,"19002":1,"19501":1,"19502":1,"16018":1};game.inbox.state.powerSlots.claw="16018";game.equip_power_item("19502");game.equip_power_item("19002")
	p.claw_trail.refresh_glow();check(p.claw_trail.glow.is_empty(),"Owning purple claw and energy pack does not start FT")
	p.action_time=0;p.move_axis=Vector2.UP;p._physics_process(.1);var base_speed=p.movement_speed;var hp=game.health;p.extra_health=80
	key(KEY_T);p._physics_process(.1);p.claw_trail.refresh_glow();await frames()
	check(game.health==hp-ceili(hp*.25),"T deducts the cash pack's immediate 25 percent health cost")
	check(p.extra_health==80,"FT health trade cannot silently spend or refill the separate howl pool")
	check(p.movement_speed>base_speed and is_equal_approx(p.movement_speed/base_speed,1.15),"FT speeds actual movement using the explicit mobile speed adapter")
	check(is_equal_approx(p.anim.speed_scale,1.15),"Existing locomotion clip speeds up without needing a clip change")
	check(p.claw_trail.glow.size()==2,"Successful T activation creates both original hand effects")
	check(game.inbox.state.powerCounts["19502"]==1,"Repeatedly usable energy preserves the equipped owned pack")
	check(is_equal_approx(game.wolf_damage_multiplier(),1.2) and is_equal_approx(game.wolf_damage_multiplier("strong"),1.5),"Source cash energy distinguishes normal plus 20 and strong plus 50 percent")
	hp=game.health;key(KEY_T);key(KEY_T,true);check(game.health==hp and game.inbox.state.powerCounts["19502"]==1,"Active boost and key echo cannot stack the cost or effect")
	game.inbox.state.powerSlots.claw="";p.claw_trail.refresh_glow();check(p.claw_trail.glow.size()==2,"Changing claw does not switch off active FT")
	game.source_hud.refresh_from_game();var energy_button=game.source_hud.power_buttons.filter(func(b):return b.get_meta("power_slot")=="energy")[0]
	check(energy_button.disabled,"Active FT button is disabled rather than accepting repeated charges")
	key(KEY_F);check(game.health==game.max_health() and p.extra_health==80 and game.healing_uses["19002"]==1,"F heals actual health with a separate per-life limit and leaves howl health untouched")
	check(game.inbox.state.powerCounts["19002"]==1,"Using first aid preserves the owned reusable pack")
	check(not game.use_power("support"),"Full health rejects first aid without spending another use")
	game.health=20;check(game.use_power("support") and game.healing_uses["19002"]==2,"Cash first aid supports the source two uses per life")
	game.health=20;check(not game.use_power("support") and game.inbox.state.powerCounts["19002"]==1,"Exhausted per-life first aid does not consume the owned pack")
	game.advance_power_effects(15);p._physics_process(.1);p.claw_trail.refresh_glow();await frames()
	check(game.booster_remaining==0 and p.claw_trail.glow.is_empty() and is_equal_approx(p.movement_speed,base_speed),"Expiration removes speed and hand effects together")
	check(game.healing_remaining==0 and game.health==87,"Independent native healing ticks and proportional FT drain preserve fractional HP through their full windows")
	game.inbox.state.powerSlots.claw="16018";p.claw_trail.refresh_glow();check(p.claw_trail.glow.is_empty(),"Purple claw remains visually ordinary after FT expires")
	check(game.use_power("energy") and game.inbox.state.powerCounts["19502"]==1,"Expired energy can be activated again from the same owned pack")
	p.reset_combat();check(game.booster_remaining==0 and game.healing_remaining==0,"Resetting combat clears all temporary power effects")
	game.health=1;check(not game.use_power("energy") and game.health==1,"Energy cannot kill a one-health player or consume the pack")
	game.health=game.max_health();game.equip_power_item("19501");hp=game.health;check(game.use_power("energy") and game.health==hp-ceili(hp*.5),"Gold energy uses its distinct 50 percent immediate cost")
	check(is_equal_approx(game.wolf_damage_multiplier(),1.1) and is_equal_approx(game.wolf_damage_multiplier("strong"),1.25),"Gold energy has source plus 10 normal and plus 25 strong damage")
	game.clear_power_effects();game.healing_uses.clear();game.equip_power_item("19001");game.health=1;check(game.use_power("support") and game.health==51,"Gold first aid restores 50 health")
	game.health=1;check(not game.use_power("support"),"Gold first aid has one use per life")
	game.clear_power_effects();game.equip_power_item("19502");game.health=game.max_health();game.use_power("energy")
	game.pause_game();hp=game.health;game.advance_power_effects(5);key(KEY_T);check(game.health==hp and game.booster_remaining==10,"Pause freezes the effect clock and rejects power inputs")
	game.resume();game.local_room.mode=0;p.switch_form(true);check(not p.is_wolf and game.booster_remaining==0,"Leaving wolf form clears FT instead of giving a free carried boost")
	check(not game.use_power("energy"),"Human form cannot activate FT")
	p.switch_form(true);game.health=game.max_health();game.use_power("energy");p.extra_health=0;game.take_damage(10000);check(game.booster_remaining==0 and game.healing_remaining==0,"Actual death cancels FT and healing before respawn or spectating")
	game.show_home();game.local_room={"mode":game.WOLF_BATTLE,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames();p.set_physics_process(false)
	check(game.healing_uses.is_empty() and game.inbox.state.powerCounts["19502"]==1,"New life resets its use budget without inventing or spending owned packs")
	game.local_room.mode=0;p.switch_form(true)
	var ak=game.book.weapons.filter(func(row):return row.get("available",false) and str(game.book.models.get(row.model,{}).get("source","")).to_lower().ends_with("wt_pv_akei47.ltb"))[0]
	game.book.acquire(ak.id);check(game.equip_library_weapon(ak) and not p.muzzle_record.is_empty(),"AK-47 maps to its verified source model and Flash socket")
	check(p.muzzle_record.get("sockets",{}).has("breach") and p.muzzle_socket_transform("Flash").origin.distance_to(p.muzzle_socket_transform("breach").origin)>.1,"Flash and breach use their distinct original weapon sockets")
	check(p.update_muzzle_anchor() and p.muzzle_anchor.global_position.is_finite() and p.muzzle_anchor.global_position.distance_to(p.camera.global_position)<4,"Converted Flash socket stays on the real viewmodel")
	game.reloading=0;game.ammo=game.weapon_capacity();p.shot_cooldown=0;game.attack()
	check(not p.muzzle_anchor.get_children().is_empty() and p.muzzle_anchor.get_child(0).group=="AK-47_PV_Muzz","Actual gunfire plays the original source muzzle group at the weapon socket")
	game.clientfx.clear();await frames();game.ammo=0;p.shot_cooldown=0;game.attack();await frames(1)
	check(p.muzzle_anchor.get_child_count()==0,"Empty magazine cannot create a muzzle flash")
	game.queue_free();await frames();var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-025-validation.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"failures":failures},"  "));file.close();print("MOBILE_025_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
