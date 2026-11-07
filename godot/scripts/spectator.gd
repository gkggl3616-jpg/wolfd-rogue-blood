extends Node3D
var game
var active=false
var target
var camera:Camera3D
func _ready():
 camera=Camera3D.new();camera.near=0.08;camera.fov=74;add_child(camera)
func candidates():
 return game.enemies.get_children().filter(func(actor):return game.actor_alive(actor) and actor.team==game.local_room.get("team","blue"))
func begin():
 active=true;target=null
 game.player.reset_combat();game.touch.reset();game.player.collision_layer=0
 game.player.human.hide();game.player.wolf.hide();game.player.viewmodel.hide()
 camera.global_transform=game.player.camera.global_transform;camera.make_current();cycle(1)
func cycle(direction):
 if not active:return
 var actors=candidates()
 if actors.is_empty():target=null;return
 var current=actors.find(target)
 target=actors[posmod(current+direction,actors.size())] if current>=0 else actors[0]
 update_camera()
func stop():
 active=false;target=null
 if is_instance_valid(game.player):
  game.player.collision_layer=1;game.player.camera.make_current();game.player.apply_camera_form()
 if is_instance_valid(camera):camera.current=false
func update_camera():
 if not game.actor_alive(target):return
 var eye=target.global_position+Vector3.UP*1.55
 var desired=eye+target.global_basis.z*3.4+Vector3.UP*0.6
 var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,desired,1,[target.get_rid(),game.player.get_rid()]))
 camera.global_position=hit.position+hit.normal*0.15 if not hit.is_empty() else desired
 if camera.global_position.distance_to(eye)>0.1:camera.look_at(eye-target.global_basis.z*3)
func _process(_delta):
 if not active:return
 if not game.running:stop();return
 if game.menu_open or game.application_suspended:return
 if not game.actor_alive(target):cycle(1)
 update_camera()
