extends SceneTree
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func ensure(value,description):
	checks+=1
	if not value:failures+=1;push_error("COMBAT_FAIL "+description)
	else:print("PASS "+description)
func frames(count):
	for i in range(count):await process_frame
func airborne():
	game.player.reset_combat();Input.action_release("aim");Input.action_release("forward")
	game.player.position=Vector3(0,3,0);game.player.velocity=Vector3.ZERO;game.player.rotation.y=0;game.player.yaw=0
	Input.action_press("forward");await frames(2)
	game.player.wolf_running=true;game.player.shot_cooldown=0
func run():
	root.size=Vector2i(1280,720)
	game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames(3)
	game.start_round();game.spawn_clock=10000;await frames(3)
	var rifle=game.book.weapon(game.book.slots.primary)
	var previous_slots=game.book.slots.duplicate();var model=game.player.viewmodel
	game.book.models[rifle.model].engineImported=false
	ensure(not game.equip_item_from_ui(rifle,"secondary_primary") and game.book.slots==previous_slots and game.player.viewmodel==model,"invalid model cannot save a new slot or replace the working weapon")
	game.book.models[rifle.model].engineImported=true
	game.book.persistent=true;game.book.save_blocked=true
	ensure(not game.equip_item_from_ui(rifle,"secondary_primary") and game.book.slots==previous_slots and game.player.viewmodel==model,"failed equipment save frees the staged model and preserves live/disk intent")
	game.book.persistent=false;game.book.save_blocked=false
	var character=game.book.characters.filter(func(row):return row.get("available")==true)[0]
	var old_human=game.player.human;var old_choice=game.book.selected_character;var old_asset=character.human.asset
	character.human.asset="res://missing-character.glb"
	ensure(not game.select_library_character(character) and game.player.human==old_human and game.book.selected_character==old_choice,"missing character asset cannot save a choice or remove the working model")
	character.human.asset=old_asset;game.book.persistent=true;game.book.save_blocked=true
	ensure(not game.select_library_character(character) and game.player.human==old_human and game.book.selected_character==old_choice,"failed character save discards both staged forms without changing the player")
	game.book.persistent=false;game.book.save_blocked=false
	var other=game.book.weapons.filter(func(row):return row.category=="rifle" and row.get("available")==true and row.id!=rifle.id)[0]
	game.book.acquire(other.id);game.ammo=7;game.reserve=19
	ensure(game.equip_item_from_ui(other,"secondary_primary") and game.book.slots.primary==rifle.id and game.book.slots.secondary_primary==other.id,"second primary equips independently of the first")
	game.ammo=3;game.reserve=11;game.cycle_primary()
	ensure(game.current_weapon_id==rifle.id and game.ammo==7 and game.reserve==19,"cycling back to primary preserves its ammunition")
	game.cycle_primary()
	ensure(game.current_weapon_id==other.id and game.ammo==3 and game.reserve==11,"cycling to second primary preserves its separate ammunition")
	ensure(not game.book.equip(game.book.slots.pistol,"secondary_primary"),"pistol cannot overwrite a main-weapon slot")
	game.player.position=Vector3(0,0.1,0);game.player.velocity=Vector3.ZERO
	game.spawn_enemy();var enemy=game.enemies.get_child(0);enemy.position=Vector3(0,0.1,-1.2);enemy.set_physics_process(false)
	var wall=game.block(Vector3(0,1,-0.6),Vector3(4,2,0.2),"576371");await frames(3)
	var health=game.health;enemy.attack_clock=0;enemy._physics_process(0)
	ensure(game.health==health,"enemy melee cannot pass through a wall")
	wall.get_parent().remove_child(wall);wall.queue_free();await frames(2);enemy._physics_process(0)
	ensure(game.health==health-8,"enemy melee still hits an unobstructed nearby player")
	game.player.switch_form();game.player.action_time=0
	game.player.begin_roar();game.player.shot_cooldown=0;game.attack()
	ensure(enemy.health==100,"a roar cannot simultaneously deal a claw attack")
	game.player.roar_effect.stop();game.equipment.equip_power(19601)
	game.player.reset_combat();game.player.position=Vector3(0,0.1,0);await frames(3);game.player.wolf_running=true
	ensure(not game.strong_attack(),"airborne strong attack cannot start on the ground")
	await airborne();game.equipment.equip_power(0)
	ensure(not game.strong_attack(),"airborne strong attack requires the equipped source power item")
	game.equipment.equip_power(19601);game.player.wolf_running=false
	ensure(not game.strong_attack(),"jumping without wolf run cannot start the special attack")
	game.player.wolf_running=true
	var library=game.player.anim.get_animation_library("");var clip=library.get_animation("airborne_attack");library.remove_animation("airborne_attack")
	ensure(not game.strong_attack(),"missing source animation never falls back to an unrelated move")
	library.add_animation("airborne_attack",clip)
	await airborne();enemy.position=Vector3(0,2,-4);enemy.health=100;await frames(1);game.player.wolf_running=true
	var touch=InputEventScreenTouch.new();touch.index=9;touch.position=game.touch.buttons[6].position;touch.pressed=true;Input.parse_input_event(touch);await frames(3)
	ensure(game.player.air_attacking and game.player.current_clip=="airborne_attack","wolf's contextual touch button starts the actual airborne source animation")
	ensure(enemy.health==100,"special attack waits for its hit window")
	await frames(24)
	ensure(enemy.health==20,"airborne attack applies one real line-of-sight hit during motion")
	await frames(40)
	ensure(enemy.health==20 and not game.player.air_attacking,"holding strong attack does not repeat damage or stay stuck after landing")
	touch.pressed=false;Input.parse_input_event(touch)
	await airborne();enemy.position=Vector3(0,2,-4);enemy.health=100
	ensure(game.strong_attack(),"special attack can start after resetting the round action state")
	await frames(4);game.pause_game();await frames(2)
	ensure(not game.player.air_attacking,"opening pause cancels an unfinished airborne hit")
	game.resume();await frames(32)
	ensure(enemy.health==100,"resuming cannot deliver a cancelled delayed hit")
	game.player.action_time=5;game.player.shot_cooldown=5;game.start_round();game.spawn_clock=10000
	ensure(game.player.action_time==0 and game.player.shot_cooldown==0,"new round clears previous attack/cooldown state")
	game.player.set_physics_process(false);game.set_process(false)
	for character_row in game.book.characters:
		if character_row.get("available")!=true:continue
		ensure(game.select_library_character(character_row) and game.player.anim.has_animation("airborne_attack"),"source airborne clip imports for "+character_row.id)
		var source_clip=game.player.anim.get_animation("airborne_attack")
		game.player.anim.play("airborne_attack");game.player.anim.seek(source_clip.length*0.35,true)
		var skeleton=game.player.wolf.find_children("*","Skeleton3D",true,false)[0]
		var finite=true
		for bone in range(skeleton.get_bone_count()):finite=finite and skeleton.get_bone_global_pose(bone).is_finite()
		ensure(finite,"source attack pose has finite bone transforms for "+character_row.id)
		await frames(1)
	Input.action_release("forward");Input.action_release("aim");game.queue_free();await frames(3)
	print("COMBAT_CONTINUATION_QA checks=%d failures=%d" % [checks,failures]);quit(0 if failures==0 else 1)
