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
	apply_camera_form()
	choose_animation_player()
	play_clip("idle")

func choose_animation_player():
	var model = wolf if is_wolf else human
	var players = model.find_children("*", "AnimationPlayer", true, false)
	anim = players[0] if not players.is_empty() else null
	current_clip = ""
	if anim:
		for name in anim.get_animation_list():
			if name in ["idle", "run", "crouch", "crouch_run"]:
				anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR

func play_clip(clip):
	if anim and anim.has_animation(clip) and current_clip != clip:
		anim.play(clip, 0.12)
		current_clip = clip

func look(delta: Vector2):
	if not game.running or game.menu_open:
		return
	yaw -= delta.x * 0.0032
	pitch = clampf(pitch - delta.y * 0.0032, -0.85, 0.65)
	rotation.y = yaw
	pivot.rotation.x = pitch

func switch_form():
	if not game.running or game.menu_open:
		return
	is_wolf = not is_wolf
	apply_camera_form()
	game.reloading = 0.0
	human.visible = not is_wolf and third_person
	wolf.visible = is_wolf
	choose_animation_player()
	action_time = 0.3
	game.announce("Kurt formu" if is_wolf else "İnsan formu")
	game.update_hud()

func apply_camera_form():
	third_person = is_wolf
	camera_arm.spring_length = 3.4 if is_wolf else 0.0
	camera.position = Vector3(0.4,0.35,0) if is_wolf else Vector3(0,0.03,-0.06)
	human.visible = false
	wolf.visible = is_wolf

func toggle_camera():
	apply_camera_form()

func _physics_process(delta):
	shot_cooldown = maxf(0, shot_cooldown - delta)
	action_time = maxf(0, action_time - delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	if not game.running or game.menu_open:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	var axis = Input.get_vector("left", "right", "forward", "backward") + move_axis
	axis = axis.limit_length(1.0)
	var direction = (transform.basis * Vector3(axis.x, 0, axis.y)).normalized()
	var speed = 6.0 if is_wolf else 4.1
	if Input.is_action_pressed("sprint"):
		speed *= 1.3
	crouching = Input.is_action_pressed("crouch")
	if not crouching and capsule.height < 1.8:
		var clearance = PhysicsShapeQueryParameters3D.new()
		var standing = CapsuleShape3D.new()
		standing.height = 1.8
		standing.radius = 0.36
		clearance.shape = standing
		clearance.transform = global_transform.translated_local(Vector3(0,0.9,0))
		clearance.exclude = [get_rid()]
		clearance.collision_mask = 1
		crouching = not get_world_3d().direct_space_state.intersect_shape(clearance,1).is_empty()
	capsule.height = 1.2 if crouching else 1.8
	body_shape.position.y = capsule.height * 0.5
	pivot.position.y = lerpf(pivot.position.y,1.05 if crouching else 1.55,delta*14)
	if crouching:
		speed *= 0.5
	if Input.is_action_just_pressed("jump") and is_on_floor() and not crouching:
		velocity.y = 6.3
		play_clip("jump")
		action_time = 0.55
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 28)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 28)
	move_and_slide()
	if Input.is_action_just_pressed("transform"):
		switch_form()
	if Input.is_action_just_pressed("reload"):
		game.reload_weapon()
	if Input.is_action_pressed("fire") and shot_cooldown <= 0:
		game.attack()
	if action_time <= 0:
		play_clip(("crouch_run" if axis.length()>0.15 else "crouch") if crouching else ("run" if axis.length() > 0.15 else "idle"))
	camera.fov = lerpf(camera.fov, 53.0 if Input.is_action_pressed("aim") and not is_wolf else 74.0, delta * 10)
