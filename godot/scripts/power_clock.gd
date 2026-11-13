extends RefCounted
# Native pack counters share fractional HP, but keep independent tick phases.
# Video evidence: 150 * .98^n displays 147,144,141,138,135,132,130,127.
var health_fraction=0.0
var energy_clock=0.0
var healing_clock=0.0
func clear():health_fraction=0;energy_clock=0;healing_clock=0
func precise_health(game):
	return float(game.health)+(health_fraction if game.health>0 and game.health<game.max_health() else 0.0)
func store_health(game,value):
	value=clampf(value,1.0,float(game.max_health()))
	game.health=floori(value+0.000001);health_fraction=maxf(0,value-game.health)
func heal(game,amount):store_health(game,precise_health(game)+amount)
func spend(game,fraction):store_health(game,precise_health(game)*(1.0-fraction))
func advance(game,delta):
	if delta<=0 or not is_finite(delta):return
	var left=delta;var value=precise_health(game)
	while left>0.000001 and (game.booster_remaining>0 or game.healing_remaining>0):
		var energy=game.booster_remaining>0;var healing=game.healing_remaining>0
		var energy_tick=maxf(.01,float(game.booster_tuning.get("tickSeconds",1)))
		var healing_tick=maxf(.01,game.healing_tick_seconds)
		var until_energy=minf(game.booster_remaining,maxf(0,energy_tick-energy_clock)) if energy else INF
		var until_heal=minf(game.healing_remaining,maxf(0,healing_tick-healing_clock)) if healing else INF
		var step=minf(left,minf(until_energy,until_heal))
		if energy:energy_clock+=step;game.booster_remaining=maxf(0,game.booster_remaining-step)
		if healing:healing_clock+=step;game.healing_remaining=maxf(0,game.healing_remaining-step)
		left=maxf(0,left-step)
		if energy and energy_clock>=energy_tick-.000001:
			energy_clock=maxf(0,energy_clock-energy_tick)
			value=maxf(1,value*(1.0-float(game.booster_tuning.get("healthDrainPercentPerTick",0))/100.0))
		if healing and healing_clock>=healing_tick-.000001:
			healing_clock=maxf(0,healing_clock-healing_tick);value=minf(game.max_health(),value+game.healing_regen_per_tick)
	store_health(game,value)
