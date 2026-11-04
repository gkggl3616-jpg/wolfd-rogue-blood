extends CharacterBody3D

var game
var fuse = 2.0
var kind = "grenade"
var damage_amount = 90

func _ready():
	collision_layer = 4;collision_mask = 1
	add_collision_exception_with(game.player)
	var shape = CollisionShape3D.new(); var sphere = SphereShape3D.new();sphere.radius = 0.12;shape.shape = sphere;add_child(shape)
	var mesh = MeshInstance3D.new(); var model = SphereMesh.new();model.radius = 0.12;model.height = 0.24;mesh.mesh = model
	mesh.material_override = game.material("566b4c");add_child(mesh)

func _physics_process(delta):
	if not game.running or game.menu_open: return
	fuse -= delta
	velocity.y -= 12 * delta
	var collision = move_and_collide(velocity * delta)
	if collision: velocity = velocity.bounce(collision.get_normal()) * 0.4
	if fuse <= 0:
		game.explode(global_position, damage_amount, kind)
		queue_free()
