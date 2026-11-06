extends Node3D
# Compatibility/status adapter. Actual FX start at the source animation's
# create_attachfx/FX key, rather than being forced at the beginning of the roar.
var player
var active_group=""
var parts=[]
func begin():
	stop()
	active_group=player.game.clientfx.model_record(player).get("effects",{}).get("ClientFXOnce3","")
func stop():
	if active_group!="":
		for node in player.game.clientfx.group_instances(player,active_group):node.queue_free()
	active_group="";parts=[]
func _process(_delta):
	parts=[]
	if active_group!="":
		for node in player.game.clientfx.group_instances(player,active_group):parts.append_array(node.parts)
