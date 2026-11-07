extends Node

const BUSES = {"music_volume": "WolfMusic", "effects_volume": "WolfEffects", "weapons_volume": "WolfWeapons", "ui_volume": "WolfUI"}
var game
var sounds = {}
var ui: AudioStreamPlayer
var music: AudioStreamPlayer
var music_key = ""
var last_played = ""
var suspended = false
var master_limiter:AudioEffectHardLimiter

func _ready():
	master_limiter=AudioEffectHardLimiter.new();master_limiter.ceiling_db=-1.0;AudioServer.add_bus_effect(0,master_limiter)
	for bus_name in BUSES.values():
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	if FileAccess.file_exists("res://assets/shared_media/catalog.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/shared_media/catalog.json"))
		sounds = data.get("sounds", {}) if data is Dictionary else {}
	ui = AudioStreamPlayer.new()
	ui.bus = "WolfUI"
	ui.max_polyphony = 4
	ui.volume_db = -16
	add_child(ui)
	music = AudioStreamPlayer.new()
	music.bus = "WolfMusic"
	music.volume_db = -23
	add_child(music)
	get_tree().node_added.connect(on_node_added)
	apply_settings()

func apply_settings():
	var master = float(game.book.settings.volume)
	AudioServer.set_bus_mute(0, master <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, master)))
	for key in BUSES:
		var index = AudioServer.get_bus_index(BUSES[key])
		var volume = float(game.book.settings[key])
		AudioServer.set_bus_mute(index, suspended or volume <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, volume)))

func set_suspended(value):
	suspended = value
	if value:
		ui.stop()
	music.stream_paused = value
	apply_settings()

func on_node_added(node):
	if node is BaseButton:
		node.pressed.connect(func(): play_ui("root/wt_snd/interface/lower_menu_click.wav"))
	elif node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		if node.bus == &"Master":
			node.bus = &"WolfEffects"

func play_ui(key):
	if suspended or not sounds.has(key): return false
	last_played = key
	if not game.test_mode:
		ui.stream = load(sounds[key].asset)
		ui.play()
	return true

func _process(_delta):
	for audio in active_voices:
		if is_instance_valid(audio):audio.stream_paused=suspended or (game.menu_open and not audio.get_meta("allow_menu",false))
	if suspended: return
	var key=desired_music()
	if key == music_key: return
	music_key = key
	music.stop()
	if sounds.has(key) and not game.test_mode:
		music.stream = load(sounds[key].asset).duplicate()
		if music.stream is AudioStreamOggVorbis: music.stream.loop = true
		music.play()

func desired_music():
	if game.running:return ""
	var panel=game.library_panel if is_instance_valid(game.library_panel) else game.pc_panel
	var page=panel.page if is_instance_valid(panel) else "lobby"
	return "root/wt_snd/background/game.ogg" if page in ["room","create_room","room_settings"] else "root/wt_snd/background/lobby.ogg"

func _exit_tree():
	for i in range(AudioServer.get_bus_effect_count(0)-1,-1,-1):
		if AudioServer.get_bus_effect(0,i)==master_limiter:AudioServer.remove_bus_effect(0,i)
	if get_tree() and get_tree().node_added.is_connected(on_node_added):
		get_tree().node_added.disconnect(on_node_added)
	ui.stop()
	music.stop()

var source_data={}
var event_history=[]
var active_voices=[]
func gameplay_sources():
	if source_data.is_empty():source_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/source.json"))
	return source_data
func actor_form(actor):return ("wolf" if actor.is_wolf else "human") if actor==game.player else actor.kind
func actor_definition(actor):
	var form=actor_form(actor)
	if actor==game.player and form=="wolf" and actor.mutation_id!="normal":return game.mutations.model(actor.mutation_id,game.local_room.get("team","blue")).get("definition","Model2")
	return actor.character_info.get(form,{}).get("sourceDefinition","Model0" if form=="human" else "Model2")
func voice_keys(actor,event):
	var form=actor_form(actor);var models=gameplay_sources().voices[form]
	var model=str(actor_definition(actor)).trim_prefix("Model")
	var row=models.get(model,{}).get(str(event),models.get("0" if form=="human" else "65535",{}).get(str(event),{}))
	return row.get("keys",[])
func play_at(key,where=Vector3.ZERO,spatial=true,bus="WolfEffects",volume=-12.0,allow_menu=false):
	if suspended or not sounds.has(key):return false
	var entry=sounds[key]
	if not ResourceLoader.exists(entry.asset):return false
	event_history.append({"key":key,"position":where,"spatial":spatial,"bus":bus,"allowMenu":allow_menu})
	if event_history.size()>128:event_history.pop_front()
	if game.test_mode:return true
	active_voices=active_voices.filter(func(n):return is_instance_valid(n) and not n.is_queued_for_deletion())
	if active_voices.size()>=32:active_voices.pop_front().queue_free()
	var audio=AudioStreamPlayer3D.new() if spatial else AudioStreamPlayer.new()
	audio.set_meta("allow_menu",allow_menu);audio.bus=bus;audio.volume_db=volume;audio.stream=load(entry.asset)
	if spatial:audio.position=where;audio.max_distance=38
	add_child(audio);active_voices.append(audio);audio.finished.connect(audio.queue_free);audio.play();return true
func stop_actor_voice(actor,event=2):
	for node in active_voices:
		if is_instance_valid(node) and node.get_meta("voice_actor",0)==actor.get_instance_id() and node.get_meta("voice_event",-1)==event:
			node.stop();node.queue_free()
func voice(actor,event):
	var keys=voice_keys(actor,event)
	if keys.is_empty():return false
	if event==2:stop_actor_voice(actor,event)
	var played=play_at(keys.pick_random(),actor.global_position,actor!=game.player,"WolfEffects",-12,event==0)
	if played and not game.test_mode:
		active_voices[-1].set_meta("voice_actor",actor.get_instance_id());active_voices[-1].set_meta("voice_event",event)
	return played
func natural_sound(actor,weapon,slot):
	var bank=gameplay_sources().weaponSounds.get(str(weapon),{}).get("sounds",[]);var index=int(slot)-10
	if index<0 or index>=bank.size() or bank[index].key=="":return false
	return play_at(bank[index].key,actor.global_position,actor!=game.player)
func footstep(actor):
	var form=actor_form(actor);var surface="cement"
	var space=actor.get_world_3d().direct_space_state
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*0.3,actor.global_position-Vector3.UP*0.7,1,[actor.get_rid()]))
	if hit:
		var parent=hit.collider.get_parent()
		if parent is MeshInstance3D and parent.mesh and parent.mesh.get_surface_count()>0:
			var material=parent.get_active_material(0);var name=str(material.resource_name).to_lower() if material else ""
			for kind in ["metal","wood","glass","stone","snow","water","grass","rubber","cloth","cement"]:
				if kind in name:surface="steel" if kind=="metal" else kind;break
	var suffix="a" if randi()%2==0 else "b"
	return play_at("root/wt_snd/player/footstep/%s/%s_%s_footstep%s.wav" % [form,form,surface,suffix],actor.global_position,actor!=game.player,"WolfEffects",-20)
func match_sound(event):return play_at("root/wt_snd/interface/msg_"+event+".wav",Vector3.ZERO,false,"WolfEffects",-12,true)
func stop_room_countdown():
	for node in active_voices:
		if is_instance_valid(node) and node.has_meta("room_countdown"):node.stop();node.queue_free()
	active_voices=active_voices.filter(func(node):return is_instance_valid(node) and not node.is_queued_for_deletion())
func room_countdown(number):
	stop_room_countdown()
	var played=play_at("root/wt_snd/interface/count_%d.wav" % clampi(number,0,3),Vector3.ZERO,false,"WolfEffects",-12,true)
	if played and not game.test_mode:active_voices[-1].set_meta("room_countdown",number)
	return played
func clear_match_voices():
	for node in active_voices:
		# The source GO clip is 1.32 seconds: loading/round setup may complete
		# sooner. Preserve its ending; cancellation stops it explicitly.
		if is_instance_valid(node) and node.get_meta("room_countdown",-1)!=0:node.stop();node.queue_free()
	active_voices=active_voices.filter(func(node):return is_instance_valid(node) and not node.is_queued_for_deletion())
