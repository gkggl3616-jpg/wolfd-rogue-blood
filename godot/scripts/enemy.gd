extends CharacterBody3D

var game
var health = 100
var attack_clock = 0.0
var anim: AnimationPlayer
var moving = false
var active_clip = ""
var navigator: NavigationAgent3D
var path_clock = 0.0

func _ready():
	collision_layer = 2
	collision_mask = 1
	set_meta("enemy", true)
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.9
	collider.shape = capsule
	collider.position.y = 0.95
	add_child(collider)
	if game.offline_map_number != 0:
		navigator = NavigationAgent3D.new()
		navigator.path_desired_distance = 0.6
		navigator.target_desired_distance = 1.3
		navigator.radius = 0.42
		navigator.height = 1.9
		add_child(navigator)
		navigator.set_navigation_map(game.offline_navigation_map)
	var body = load(game.character_info.wolf.asset).instantiate()
	body.scale *= 1.6
	body.rotation.y = PI
	add_child(body)
	var players = body.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		anim = players[0]
		for clip in ["idle", "run"]:
			anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var indicator = Label3D.new()
	indicator.text = "HEDEF"
	indicator.position.y = 2.25
	indicator.font_size = 32
	indicator.modulate = Color("f47867")
	indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(indicator)

func _physics_process(delta):
	if not game.running or game.menu_open:
		return
	attack_clock -= delta
	if game.offline_map_number != 0 and position.y < game.preview_spawn.y - 150:
		queue_free();return
	var offset = game.player.global_position - global_position
	offset.y = 0
	var distance = offset.length()
	if distance > 1.65:
		var dir = offset.normalized()
		if is_instance_valid(navigator):
			path_clock -= delta
			if path_clock <= 0:
				navigator.target_position = game.player.global_position
				path_clock = 0.5
			var next = navigator.get_next_path_position() - global_position
			next.y = 0
			dir = next.normalized() if not navigator.is_navigation_finished() else Vector3.ZERO
		velocity.x = dir.x * (3.3 if is_instance_valid(navigator) else 1.6)
		velocity.z = dir.z * (3.3 if is_instance_valid(navigator) else 1.6)
		if offset.length() > 0.1:
			look_at(global_position + offset)
		play("run")
	else:
		velocity.x = 0
		velocity.z = 0
		if attack_clock <= 0:
			var query=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,game.player.global_position+Vector3.UP,1,[get_rid()])
			var hit=get_world_3d().direct_space_state.intersect_ray(query)
			if hit and hit.collider==game.player:
				game.take_damage(8);attack_clock=1.1;play("attack")
			else:play("idle")
		elif attack_clock < 0.3:
			play("idle")
	if not is_on_floor():
		velocity.y -= 20 * delta
	move_and_slide()

func play(clip):
	if anim and active_clip != clip:
		anim.play(clip, 0.12)
		active_clip = clip

func damage(amount):
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		game.enemy_defeated()
		queue_free()
