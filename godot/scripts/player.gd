extends CharacterBody3D

var game
var is_wolf = false
var yaw = 0.0
var pitch = -0.12
var third_person = false
var human: Node3D
var wolf: Node3D
var camera: Camera3D
var pivot: Node3D
var camera_arm: SpringArm3D
var shot_cooldown = 0.0
var action_time = 0.0
var anim: AnimationPlayer
var current_clip = ""
var move_axis = Vector2.ZERO
var body_shape: CollisionShape3D
var capsule: CapsuleShape3D
var crouching = false
var wolf_running = false
var wolf_run_armed = false
var movement_clock = 0.0
var last_forward_press = -10.0
var forward_held = false
var movement_speed = 0.0
var normal_run_toggled = false
var viewmodel: Node3D
var weapon_anim: AnimationPlayer
var weapon_info = {}
var weapon_clip = ""
var weapon_action_time = 0.0
var auxiliary_magazines = []
var mutation_id="normal"
var claw_trail
var source_events
var pending_strong=false
var character_info:Dictionary:
	get:return game.character_info if game!=null else {}
var guard_remaining=0.0
var cloak_remaining=0.0
var mutation_energy=100.0
var fire_sound: AudioStreamPlayer
var reload_sound: AudioStreamPlayer
var roar_effect
var rolling = false
var roll_elapsed = 0.0
var roll_duration = 0.65
var roll_cooldown = 0.0
var roll_direction = Vector3.ZERO
var roll_travel=0.0
const ROLL_DISTANCE=3.0
var roll_base = Transform3D.IDENTITY
var wall_holding = false
var wall_hold_remaining = 0.0
var wall_hold_cooldown = 0.0
var wall_hold_normal = Vector3.ZERO
var air_attacking = false
var air_attack_elapsed = 0.0
var air_attack_duration = 0.0
var air_attack_direction = Vector3.ZERO
var air_attack_hit = false

func _ready():
	collision_layer = 1
	collision_mask = 3
	var shape = CollisionShape3D.new()
	body_shape = shape
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	human = load(game.character_info.human.asset).instantiate()
	wolf = load(game.character_info.wolf.asset).instantiate()
	for model in [human, wolf]:
		model.scale *= 1.6
		model.rotation.y = PI
		add_child(model)
	wolf.visible = false
	human.visible = false
	pivot = Node3D.new()
	pivot.position.y = 1.55
	pivot.rotation.x = pitch
	add_child(pivot)
	camera_arm = SpringArm3D.new()
	camera_arm.collision_mask = 1
	camera_arm.margin = 0.2
	camera_arm.add_excluded_object(get_rid())
	pivot.add_child(camera_arm)
	camera = Camera3D.new()
	camera.fov = 74
	camera.near = 0.08
	camera_arm.add_child(camera)
	camera.current = true
	weapon_info = JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/ak47/weapon.json"))
	viewmodel = load("res://assets/weapons/ak47/viewmodel.glb").instantiate()
	var weapon_pos = weapon_info.godotPosition
	viewmodel.position = Vector3(weapon_pos[0], weapon_pos[1], weapon_pos[2])

	viewmodel.scale.z *= -1
	camera.add_child(viewmodel)
	weapon_anim = viewmodel.find_children("*", "AnimationPlayer", true, false)[0]
	for clip in ["idle", "walk"]:
		weapon_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for mesh in viewmodel.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fire_sound = AudioStreamPlayer.new()
	fire_sound.bus = "WolfWeapons"
	fire_sound.stream = load(weapon_info.sounds.fire.asset)
	fire_sound.volume_db = -12
	fire_sound.max_polyphony = 4
	add_child(fire_sound)
	reload_sound = AudioStreamPlayer.new()
	reload_sound.bus = "WolfWeapons"
	reload_sound.stream = load(weapon_info.sounds.reload.asset)
	reload_sound.volume_db = -14
	add_child(reload_sound)
	apply_camera_form()
	choose_animation_player()
	play_clip("idle")
	apply_tattoos()
	roar_effect = Node3D.new();roar_effect.set_script(preload("res://scripts/roar_effect.gd"));roar_effect.player = self;add_child(roar_effect)
	claw_trail=Node3D.new();claw_trail.set_script(preload("res://scripts/claw_trail.gd"));claw_trail.player=self;add_child(claw_trail)
	source_events=Node.new();source_events.set_script(preload("res://scripts/actor_source_events.gd"));source_events.actor=self;add_child(source_events)

func choose_animation_player():
	var model = wolf if is_wolf else human
	var players = model.find_children("*", "AnimationPlayer", true, false)
	anim = players[0] if not players.is_empty() else null
	current_clip = ""
	if anim:
		for name in anim.get_animation_list():
			if name in ["idle", "run", "crouch", "crouch_run", "wolf_run", "wall_hold"]:
				anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR

func play_clip(clip):
	if anim and anim.has_animation(clip) and current_clip != clip:
		anim.play(clip, 0.12)
		current_clip = clip

func play_weapon_clip(clip, duration = 0.0):
	for magazine in auxiliary_magazines:
		if is_instance_valid(magazine):magazine.visible=clip=="reload"
	if weapon_anim and weapon_anim.has_animation(clip):
		weapon_anim.play(clip, 0.06)
		weapon_clip = clip
		weapon_action_time = duration

func collect_auxiliary_magazines(model):
	var meshes=model.find_children("*","MeshInstance3D",true,false)
	if not meshes.any(func(mesh):return str(mesh.name).to_upper().contains("_MAG")):return []
	return meshes.filter(func(mesh):return str(mesh.name).to_upper()=="MAG")

func play_weapon_sound(action):
	if game.test_mode:
		return
	if action == "fire" and fire_sound.stream:
		fire_sound.play()
	elif action == "reload" and reload_sound.stream:
		reload_sound.play()

func prepare_library_weapon(item):
	var model_info=game.book.models.get(item.get("model",""),{})
	if model_info.get("engineImported")!=true or item.get("available")!=true:return {}
	if not ResourceLoader.exists(item.get("asset","")):return {}
	var packed=load(item.asset) as PackedScene
	if packed==null:return {}
	var next_viewmodel=packed.instantiate()
	var players=next_viewmodel.find_children("*","AnimationPlayer",true,false)
	if players.is_empty():next_viewmodel.free();return {}
	var tuning=item.get("gameplayTuning",{})
	for key in ["capacity","fireInterval","reloadSeconds","damage"]:
		var number=tuning.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0:
			next_viewmodel.free();return {}
	if tuning.fireInterval<=0:next_viewmodel.free();return {}
	var sounds={}
	for action in ["fire","reload"]:
		var path=item.get("sounds",{}).get(action,"")
		if path!="" and not ResourceLoader.exists(path):next_viewmodel.free();return {}
		sounds[action]=load(path) if path!="" else null
	var meshes=next_viewmodel.find_children("*","MeshInstance3D",true,false);var names={};var material_changes=[]
	for mesh in meshes:names[str(mesh.name)]=true
	for mesh in meshes:
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(mesh.mesh.get_surface_count()):
			var material=mesh.mesh.surface_get_material(surface)
			if material and material.resource_name.begins_with("slot_"):
				var slot=material.resource_name.trim_prefix("slot_")
				if item.get("skins",{}).has(slot):
					if not ResourceLoader.exists(item.skins[slot]):next_viewmodel.free();return {}
					var custom=material.duplicate();custom.albedo_texture=load(item.skins[slot]);material_changes.append({"mesh":mesh,"surface":surface,"material":custom})
		var name=str(mesh.name);var dash=name.rfind("-")
		if dash>0 and name.substr(dash+1).is_valid_int() and names.has(name.substr(0,dash)):mesh.hide()
	return {"model":next_viewmodel,"animation":players[0],"sounds":sounds,"materials":material_changes,"info":{"name":item.name,"category":item.category,"shotsPerClip":int(tuning.capacity),"fireIntervalMs":float(tuning.fireInterval)*1000,"reloadSeconds":float(tuning.reloadSeconds),"damage":int(tuning.damage),"sourceStatsVerified":false}}

func apply_prepared_weapon(prepared):
	if is_instance_valid(viewmodel):camera.remove_child(viewmodel);viewmodel.queue_free()
	viewmodel=prepared.model;viewmodel.position=Vector3(0.19,-0.37,-0.72);viewmodel.scale.z*=-1;camera.add_child(viewmodel)
	auxiliary_magazines=collect_auxiliary_magazines(viewmodel)
	for change in prepared.materials:change.mesh.set_surface_override_material(change.surface,change.material)
	weapon_anim=prepared.animation
	for clip in ["idle","walk"]:
		if weapon_anim.has_animation(clip):weapon_anim.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
	weapon_info=prepared.info
	fire_sound.stop();reload_sound.stop();fire_sound.stream=prepared.sounds.fire;reload_sound.stream=prepared.sounds.reload
	weapon_clip="";weapon_action_time=0;viewmodel.visible=not is_wolf;play_weapon_clip("idle")

func equip_library_weapon(item):
	var prepared=prepare_library_weapon(item)
	if prepared.is_empty():return false
	apply_prepared_weapon(prepared);return true

func prepare_character(info):
	var models=[]
	for form in ["human","wolf"]:
		var path=info.get(form,{}).get("asset","")
		if not ResourceLoader.exists(path):
			for model in models:model.free()
			return []
		var packed=load(path) as PackedScene
		var next_model=packed.instantiate() if packed else null
		if not next_model is Node3D:
			if is_instance_valid(next_model):next_model.free()
			for model in models:model.free()
			return []
		var players=next_model.find_children("*","AnimationPlayer",true,false)
		if players.is_empty() or not players[0].has_animation("idle"):
			next_model.free()
			for model in models:model.free()
			return []
		models.append(next_model)
	return models

func apply_prepared_character(models):
	reset_locomotion()
	if is_instance_valid(roar_effect):roar_effect.stop()
	for model in [human,wolf]:remove_child(model);model.queue_free()
	human=models[0];wolf=models[1]
	for model in [human,wolf]:model.scale*=1.6;model.rotation.y=PI;add_child(model)
	human.hide();wolf.visible=is_wolf;choose_animation_player();action_time=0;play_clip("idle");apply_tattoos()
	if mutation_id!="normal":
		var next=prepare_mutation(mutation_id)
		if next:apply_mutation(next,mutation_id)

func prepare_mutation(id):
	var record=game.mutations.model(id,game.local_room.get("team","blue"))
	var path=game.character_info.wolf.asset if id=="normal" else record.get("asset","")
	if path=="" or not ResourceLoader.exists(path):return null
	var scene=load(path) as PackedScene
	if scene==null:return null
	var model=scene.instantiate();var animations=model.find_children("*","AnimationPlayer",true,false)
	if animations.is_empty() or not animations[0].has_animation("idle"):model.free();return null
	return model
func apply_mutation(model,id):
	var fraction=float(game.health)/maxi(1,game.max_health())
	reset_locomotion();cancel_cloak();guard_remaining=0
	if is_instance_valid(roar_effect):roar_effect.stop()
	remove_child(wolf);wolf.queue_free();wolf=model;mutation_id=id;wolf.scale*=1.6;wolf.rotation.y=PI;add_child(wolf);wolf.visible=is_wolf
	# Apply the source idle pose before the first rendered frame. These meshes
	# have a different bind posture from their explicit animation donors.
	var initial_animator=wolf.find_children("*","AnimationPlayer",true,false)[0]
	initial_animator.play("idle",0);initial_animator.advance(0)
	game.health=maxi(1,mini(game.max_health(),roundi(fraction*game.max_health())))
	choose_animation_player();current_clip="";play_clip("idle");apply_tattoos()
func begin_guard():
	if not game.is_combat_active() or not is_wolf or mutation_id!="guardian" or mutation_energy<40 or guard_remaining>0:return false
	mutation_energy-=40;guard_remaining=3;game.announce("Gardiyan savunması");return true
func begin_cloak():
	if not game.is_combat_active() or not is_wolf or mutation_id!="ghost" or mutation_energy<40 or cloak_remaining>0:return false
	mutation_energy-=40;cloak_remaining=5
	for mesh in wolf.find_children("*","MeshInstance3D",true,false):mesh.transparency=0.65
	game.announce("Hayalet · Hareketsizken gizlen");return true
func is_cloaked():return cloak_remaining>0 and Vector2(velocity.x,velocity.z).length()<0.3
func cancel_cloak():
	cloak_remaining=0
	if is_instance_valid(wolf):
		for mesh in wolf.find_children("*","MeshInstance3D",true,false):mesh.transparency=0

func load_character(info):
	var models=prepare_character(info)
	if models.is_empty():return false
	apply_prepared_character(models);return true

func apply_tattoos():
	for mesh in wolf.find_children("*", "MeshInstance3D", true, false):
		var name = str(mesh.name).to_lower()
		if not name.begins_with("tattoo"): continue
		var role = "body" if "body" in name else ("left" if name.ends_with("_l") else "right")
		preload("res://scripts/tattoo_uv.gd").apply(mesh,game.book.tattoo_uv_transpose(role,game.book.selected_tattoos.get(role,"")))
		if not game.book.selected_tattoos.has(role) or not game.book.tattoo_matches_role(role, game.book.selected_tattoos[role]): mesh.hide();continue
		var material = StandardMaterial3D.new();material.albedo_texture = load(game.book.selected_tattoos[role]);material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode = BaseMaterial3D.CULL_DISABLED;material.roughness = 0.7
		material.render_priority=game.book.tattoo_render_priority(game.book.selected_tattoos[role])
		mesh.material_override = material;mesh.show()
	game.health=mini(game.health,game.max_health())
	if is_instance_valid(roar_effect): roar_effect.bind_tattoos()

func begin_roar():
	if rolling or air_attacking or wall_holding: return false
	if action_time > 0 or not anim or not anim.has_animation("roar"): return false
	var seconds = anim.get_animation("roar").length
	if not roar_effect.begin(seconds): return false
	reset_locomotion();play_clip("roar");action_time = seconds;return true

func _exit_tree():
	if is_instance_valid(fire_sound):
		fire_sound.stop()
	if is_instance_valid(reload_sound):
		reload_sound.stop()

func look(delta: Vector2):
	if not game.is_combat_active():
		return
	var sensitivity = float(game.book.settings.sensitivity)
	yaw -= delta.x * 0.0032 * sensitivity
	pitch = clampf(pitch - delta.y * 0.0032 * sensitivity * (-1.0 if game.book.settings.get("invert_y",false) else 1.0), -0.85, 0.65)
	rotation.y = yaw
	pivot.rotation.x = pitch

func switch_form(force=false):
	if not game.running or game.menu_open:
		return
	if game.hunt.active and not force:return
	if (int(game.local_room.get("mode",0))==game.WOLF_BATTLE or (game.match_rules.enabled and game.match_rules.form_lock!="mixed")) and not force:return
	if not is_wolf and not force and not game.tutorial.active and game.round_selection_enabled:
		game.open_round_selection("wolf",true);return
	var fraction=float(game.health)/maxi(1,game.max_health())
	is_wolf = not is_wolf
	if is_instance_valid(source_events):source_events.reset()
	game.game_audio.play_at("root/wt_snd/player/wolf_changetowolf.wav" if is_wolf else "root/wt_snd/player/wolf_changetohuman.wav",global_position,false)
	game.clientfx.play("ChangeCharEffect",self)
	cancel_cloak();guard_remaining=0;game.health=maxi(1,mini(game.max_health(),roundi(fraction*game.max_health())))
	end_roll()
	if is_instance_valid(roar_effect): roar_effect.stop()
	reset_locomotion()
	apply_camera_form()
	game.reloading = 0.0
	reload_sound.stop()
	weapon_action_time = 0
	human.visible = not is_wolf and third_person
	wolf.visible = is_wolf
	if viewmodel:
		viewmodel.visible = not is_wolf
	choose_animation_player()
	action_time = 0.3/maxf(1,1+float(game.gear_stats().get("transformPercent",0))/100.0)
	game.announce("Kurt formu" if is_wolf else "İnsan formu")
	game.update_hud()

func apply_camera_form():
	third_person = is_wolf
	camera_arm.spring_length = 3.4 if is_wolf else 0.0
	# Match the reference's centered, lower-screen wolf. Raise the entire arm
	# so its collision sweep follows the actual camera, including low ceilings.
	camera_arm.position.y = 0.55 if is_wolf else 0.0
	camera.position = Vector3.ZERO if is_wolf else Vector3(0, 0.03, -0.06)
	human.visible = false
	wolf.visible = is_wolf

func is_scoped():return not is_wolf and weapon_info.get("category","")=="sniper" and Input.is_action_pressed("aim")

func toggle_camera():
	apply_camera_form()

func reset_locomotion():
	end_roll()
	end_wall_hold()
	end_air_attack()
	wolf_running = false
	wolf_run_armed = false
	last_forward_press = -10.0
	forward_held = false
	move_axis = Vector2.ZERO
	normal_run_toggled = false

func register_forward_press():
	var gap = movement_clock - last_forward_press
	last_forward_press = movement_clock
	if gap <= float(game.equipment.rules.mobileAdaptation.doubleTapSeconds) and can_wolf_run():
		wolf_running = true
		last_forward_press = -10.0
		game.announce("Kurt koşusu")

func can_wolf_run():
	return is_wolf and game.equipment.has_wolf_ability() and not crouching and game.running and not game.menu_open and anim!=null and anim.has_animation("wolf_run")

func _physics_process(delta):
	if not game.is_combat_active():
		reset_locomotion()
		velocity.x = 0
		velocity.z = 0
		return
	wall_hold_cooldown = maxf(0, wall_hold_cooldown - delta)
	if wall_holding and advance_wall_hold(delta):
		return
	if not game.menu_open: roll_cooldown = maxf(0, roll_cooldown - delta)
	movement_clock += delta
	shot_cooldown = maxf(0, shot_cooldown - delta)
	action_time = maxf(0, action_time - delta)
	weapon_action_time = maxf(0, weapon_action_time - delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	var axis = Input.get_vector("left", "right", "forward", "backward") + move_axis
	axis = axis.limit_length(1.0)
	if is_instance_valid(roar_effect) and roar_effect.active:axis=Vector2.ZERO
	var forward_now = axis.y < -0.65
	if forward_now and not forward_held:
		register_forward_press()
	forward_held = forward_now
	if not can_wolf_run():wolf_run_armed=false
	if wolf_run_armed and forward_now and can_wolf_run():wolf_running=true
	if not can_wolf_run() or not forward_now or Input.is_action_pressed("crouch"):
		wolf_running = false
	var direction = (transform.basis * Vector3(axis.x, 0, axis.y)).normalized()
	guard_remaining=maxf(0,guard_remaining-delta);cloak_remaining=maxf(0,cloak_remaining-delta);mutation_energy=minf(100,mutation_energy+delta*8)
	if cloak_remaining<=0 or axis.length()>0.1:cancel_cloak()
	var speed = float(game.mutations.profile(mutation_id).speed)*game.wolf_speed_multiplier() if is_wolf else 4.1
	if wolf_running:
		speed *= float(game.equipment.rules.mobileAdaptation.wolfRunMultiplier)
	elif (Input.is_action_pressed("sprint") or normal_run_toggled) and axis.length() > 0.1:
		speed *= float(game.equipment.rules.mobileAdaptation.normalSprintMultiplier)
	if Input.is_action_just_pressed("roll"): begin_roll()
	if rolling:
		direction=roll_direction;speed=ROLL_DISTANCE/maxf(0.1,roll_duration)
	if air_attacking:
		direction=air_attack_direction;speed=float(game.equipment.rules.mobileAdaptation.airAttackSpeed)
	crouching = Input.is_action_pressed("crouch") or rolling
	if not crouching and capsule.height < 1.8:
		var clearance = PhysicsShapeQueryParameters3D.new()
		var standing = CapsuleShape3D.new()
		standing.height = 1.8
		standing.radius = 0.36
		clearance.shape = standing
		clearance.transform = global_transform.translated_local(Vector3(0, 0.9, 0))
		clearance.exclude = [get_rid()]
		clearance.collision_mask = 1
		crouching = not get_world_3d().direct_space_state.intersect_shape(clearance, 1).is_empty()
	capsule.height = 1.2 if crouching else 1.8
	body_shape.position.y = capsule.height * 0.5
	pivot.position.y = lerpf(pivot.position.y, 1.05 if crouching else 1.55, delta * 14)
	if crouching and not rolling:
		speed *= 0.5
	movement_speed = speed if rolling or air_attacking or axis.length() > 0.1 else 0.0
	if Input.is_action_just_pressed("jump") and is_on_floor() and ( not crouching or rolling):
		velocity.y = 6.3
		if not rolling: play_clip("jump");action_time = 0.55
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 28)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 28)
	var before_roll=global_position
	if rolling:
		var remaining=maxf(0,ROLL_DISTANCE-roll_travel)
		var flat=Vector2(velocity.x,velocity.z).limit_length(remaining/maxf(delta,0.0001))
		velocity.x=flat.x;velocity.z=flat.y
	move_and_slide()
	if rolling:roll_travel+=Vector2(global_position.x-before_roll.x,global_position.z-before_roll.z).length()
	advance_roll(delta)
	advance_air_attack(delta)
	if Input.is_action_just_pressed("transform"):
		switch_form()
	if Input.is_action_just_pressed("reload"):
		game.reload_weapon()
	if is_wolf and Input.is_action_just_pressed("aim"):game.strong_attack()
	if Input.is_action_pressed("fire") and shot_cooldown <= 0:
		game.attack()
	if action_time <= 0:
		play_clip("wolf_run" if wolf_running else (("crouch_run" if axis.length() > 0.15 else "crouch") if crouching else ("run" if axis.length() > 0.15 else "idle")))
	if not is_wolf and weapon_action_time <= 0:
		var next_weapon_clip = "walk" if axis.length() > 0.15 and weapon_anim.has_animation("walk") else "idle"
		if weapon_clip != next_weapon_clip:
			play_weapon_clip(next_weapon_clip)
	if is_instance_valid(viewmodel):viewmodel.visible=not is_wolf and not is_scoped()
	camera.fov = lerpf(camera.fov, 70.0 if is_wolf else (18.0 if is_scoped() else (53.0 if Input.is_action_pressed("aim") else 74.0)), minf(1,delta * 10))

func begin_roll():
	if wall_holding or rolling or air_attacking or roll_cooldown > 0 or not is_wolf or not is_on_floor() or game.menu_open or not game.running or action_time > 0: return false
	if not anim or not anim.has_animation("special_attack"): return false
	var axis = (Input.get_vector("left", "right", "forward", "backward") + move_axis).limit_length(1)
	var keep_sprint = normal_run_toggled
	reset_locomotion();roar_effect.stop()
	normal_run_toggled = keep_sprint
	roll_direction = (transform.basis * Vector3(axis.x, 0, axis.y)).normalized() if axis.length() > 0.15 else Vector3.ZERO
	if axis.length()<=0.15:velocity.x=0;velocity.z=0
	roll_duration = anim.get_animation("special_attack").length
	roll_base = wolf.transform;rolling = true;roll_elapsed = 0;roll_travel=0;roll_cooldown = roll_duration + 0.45;action_time = roll_duration;play_clip("special_attack");return true

func advance_roll(delta):
	if not rolling: return
	if not is_wolf or game.menu_open or not game.running: end_roll();return
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_normal().dot(roll_direction) < - 0.5: end_roll();return
	roll_elapsed += delta
	if roll_elapsed >= roll_duration or roll_travel>=ROLL_DISTANCE-0.001: end_roll();return



func end_roll():
	if not rolling: return
	rolling = false;roll_elapsed = 0;velocity.x=0;velocity.z=0;wolf.transform = roll_base;action_time = 0

func begin_wall_hold():
	if wall_holding or rolling or wall_hold_cooldown > 0 or not wolf_running or not can_wolf_run(): return false
	if is_on_floor() or not is_on_wall() or not anim or not anim.has_animation("wall_hold"): return false
	var normal = get_wall_normal()
	if absf(normal.y) > 0.25: return false
	wall_holding = true
	wall_hold_normal = normal
	wall_hold_remaining = float(game.equipment.rules.mobileAdaptation.wallHoldSeconds)
	wall_hold_cooldown = wall_hold_remaining + float(game.equipment.rules.mobileAdaptation.wallHoldCooldownSeconds)
	wolf_running = false
	normal_run_toggled = false
	velocity = Vector3.ZERO
	play_clip("wall_hold")
	action_time = wall_hold_remaining
	return true

func advance_wall_hold(delta):
	var axis = Input.get_vector("left", "right", "forward", "backward") + move_axis
	if not is_wolf or not game.equipment.has_wolf_ability() or axis.y >= -0.65 or Input.is_action_pressed("crouch") or not is_on_wall() or is_on_floor():
		end_wall_hold()
		return false
	wall_hold_remaining -= delta
	if wall_hold_remaining <= 0:
		end_wall_hold()
		return false
	if Input.is_action_just_pressed("jump"):
		var normal = wall_hold_normal
		end_wall_hold()
		velocity = normal * float(game.equipment.rules.mobileAdaptation.wallJumpPush)
		velocity.y = 6.3
		play_clip("jump")
		action_time = 0.55
		move_and_slide()
		return true
	# Maintain actual collision contact; never teleport or disable the collider.
	velocity = -wall_hold_normal * 0.4
	move_and_slide()
	return true

func end_wall_hold():
	if not wall_holding: return
	wall_holding = false
	wall_hold_remaining = 0
	wall_hold_normal = Vector3.ZERO
	action_time = 0

func begin_air_attack():
	if game.application_suspended or not can_wolf_run() or not wolf_running or is_on_floor():return false
	if air_attacking or rolling or wall_holding or shot_cooldown>0 or roar_effect.active:return false
	if not anim.has_animation("airborne_attack"):return false
	air_attack_duration=anim.get_animation("airborne_attack").length
	if air_attack_duration<=0:return false
	air_attacking=true;air_attack_hit=false;air_attack_elapsed=0
	air_attack_direction=-global_basis.z;wolf_running=false;normal_run_toggled=false
	shot_cooldown=air_attack_duration+float(game.equipment.rules.mobileAdaptation.airAttackRecovery)
	action_time=air_attack_duration;current_clip="";play_clip("airborne_attack")
	return true

func advance_air_attack(delta):
	if not air_attacking:return
	if not is_wolf or game.menu_open or not game.running or not game.equipment.has_wolf_ability():end_air_attack();return
	air_attack_elapsed+=delta
	if not air_attack_hit and air_attack_elapsed>=air_attack_duration*float(game.equipment.rules.mobileAdaptation.airAttackHitFraction):
		air_attack_hit=true
		game.wolf_melee_hit(int(game.equipment.rules.mobileAdaptation.airAttackDamage),float(game.equipment.rules.mobileAdaptation.airAttackRange),"Havada güçlü saldırı")
	if air_attack_elapsed>=air_attack_duration or is_on_floor():end_air_attack()

func end_air_attack():
	if not air_attacking:return
	air_attacking=false;air_attack_elapsed=0;air_attack_hit=false;air_attack_direction=Vector3.ZERO;action_time=0

func reset_combat():
	pending_strong=false
	cancel_cloak();guard_remaining=0;mutation_energy=100
	reset_locomotion();shot_cooldown=0;action_time=0;weapon_action_time=0;roll_cooldown=0;wall_hold_cooldown=0
	if is_instance_valid(roar_effect):roar_effect.stop();roar_effect.cooldown=0
	current_clip="";play_clip("idle")

func begin_ground_strong():
	if not game.is_combat_active() or not is_wolf or not is_on_floor() or action_time>0 or rolling or air_attacking or wall_holding:return false
	if not game.clientfx.install_strong(self):return false
	reset_locomotion();roar_effect.stop();pending_strong=true;current_clip="";play_clip("strong_attack");action_time=anim.get_animation("strong_attack").length;shot_cooldown=action_time;return true
