extends RefCounted
const MODE=900002
const STEPS=["Joystick ile birkaç adım ilerle","Zıpla düğmesine bas","Kurt formuna dönüş","Kükre düğmesini kullan","Takla düğmesini kullan","Pençe ile saldır","İnsan formuna dön","Şarjörünü yenile"]
var active=false
var step=0
var origin=Vector3.ZERO
var previous_attacks=0
func begin(position,attacks):active=true;step=0;origin=position;previous_attacks=attacks
func hint():return "%d / %d · %s" % [mini(step+1,STEPS.size()),STEPS.size(),STEPS[mini(step,STEPS.size()-1)]]
func advance(game):
	if not active or step>=STEPS.size():return false
	var player=game.player
	var done=false
	match step:
		0:done=Vector2(player.position.x-origin.x,player.position.z-origin.z).length()>2.5
		1:done=player.velocity.y>1 and not player.is_on_floor()
		2:done=player.is_wolf
		3:done=player.roar_effect.active
		4:done=player.rolling
		5:done=game.match_stats.attacks>previous_attacks
		6:done=not player.is_wolf
		7:done=game.reloading>0
	if done:
		step+=1;previous_attacks=game.match_stats.attacks
		if step==7:game.ammo=maxi(0,game.weapon_capacity()-1)
	return step>=STEPS.size()
