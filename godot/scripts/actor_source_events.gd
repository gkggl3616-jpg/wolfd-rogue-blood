extends Node
# Animation key strings are parsed as a fixed vocabulary, never executed as code.
var actor
var game
var system
var marker=""
var last_clip=""
var last_time=-0.001
var last_record={}
var passives={}
var history=[]
var was_floor=true
var last_vertical=0.0
func _ready():game=actor.game;system=game.clientfx
func reset():
	system.stop_actor(actor);passives={};last_clip="";last_time=-0.001;marker=""
	if actor==game.player and is_instance_valid(actor.claw_trail):actor.claw_trail.clear()
func stop_roar():
	var info=system.model_record(actor);var name=info.get("effects",{}).get("ClientFXOnce3","")
	for node in system.group_instances(actor,name):node.queue_free()
func restart_roar():
	game.game_audio.stop_actor_voice(actor);stop_roar();last_clip="";last_time=-0.001;last_record={}
	if is_instance_valid(actor.claw_trail):actor.claw_trail.clear()
func has_spline():return str(system.animation_record(actor,str(actor.anim.current_animation))).to_lower().contains("spline") if is_instance_valid(actor.anim) else false
func _process(_delta):
	if not game.is_match_active() or not game.actor_alive(actor):
		if marker!="":reset()
		return
	var floor_now=actor.is_on_floor()
	if not was_floor and floor_now and last_vertical< -2:game.game_audio.voice(actor,1)
	if was_floor and not floor_now and actor.velocity.y>1:game.game_audio.voice(actor,3)
	was_floor=floor_now;last_vertical=actor.velocity.y
	if not is_instance_valid(actor.anim) or actor.anim.current_animation=="":return
	var info=system.model_record(actor);var identity=str(info.get("definition",""))+":"+str(actor.anim.get_instance_id())
	if identity!=marker:
		reset();marker=identity
		if game.game_audio.actor_form(actor)=="wolf":system.install_strong(actor)
	var clip=str(actor.anim.current_animation);var time=actor.anim.current_animation_position
	if clip!=last_clip:
		if last_clip=="roar":stop_roar()
		if actor==game.player and is_instance_valid(actor.claw_trail):actor.claw_trail.clear()
		last_clip=clip;last_time=-0.001;last_record=system.animation_record(actor,clip)
	elif time+0.001<last_time:
		dispatch_range(last_time,float(last_record.get("durationMs",0))/1000.0);last_time=-0.001
	dispatch_range(last_time,time);last_time=time
func dispatch_range(low,high):
	for event in last_record.get("events",[]):
		var time=float(event.timeMs)/1000.0
		if time>low and time<=high+0.0001:
			for key in str(event.key).split(";"):
				if key.strip_edges()!="":dispatch(key.strip_edges())
func dispatch(key):
	history.append(key)
	if history.size()>64:history.pop_front()
	var tokens=key.split(" ",false);var operation=tokens[0].to_lower();var effects=system.model_record(actor).get("effects",{})
	if operation=="show_attachfx" and tokens.size()>1:
		var slot=tokens[1];var name=effects.get("ClientFX"+slot,"")
		if name!="" and (not is_instance_valid(passives.get(slot)) or passives[slot].is_queued_for_deletion()):passives[slot]=system.play(name,actor,null,true)
	elif operation=="hide_attachfx" and tokens.size()>1:
		var node=passives.get(tokens[1])
		if is_instance_valid(node):node.queue_free()
		passives.erase(tokens[1])
	elif operation=="create_attachfx" and tokens.size()>1:
		var name=effects.get("ClientFXOnce"+tokens[1],"")
		if name!="":system.play(name,actor)
	elif operation=="fx" and tokens.size()>1:system.play(tokens[1],actor)
	elif operation=="fire_key" and last_clip=="strong_attack" and actor==game.player and actor.pending_strong:
		actor.pending_strong=false;game.wolf_melee_hit(roundi(float(game.mutations.profile(actor.mutation_id).damage)*1.4),2.8,"Güçlü pençe")
	elif operation=="wolfcrysnd":game.game_audio.voice(actor,2)
	elif operation=="sound_key" and tokens.size()>2:game.game_audio.natural_sound(actor,int(tokens[1]),int(tokens[2]))
	elif operation=="footstep_key" and Vector2(actor.velocity.x,actor.velocity.z).length()>0.1:game.game_audio.footstep(actor)
	elif operation=="spline" and tokens.size()>2 and actor==game.player and actor.is_wolf:actor.claw_trail.source_window(int(tokens[1]),int(tokens[2])!=0)
