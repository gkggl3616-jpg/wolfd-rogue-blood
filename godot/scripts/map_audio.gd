extends Node3D

# Object positions and start/loop/volume/pitch flags come from the source DAT.
# The inner/outer falloff below is a mobile linear adaptation, not a recovered
# LithTech attenuation curve. Unsupported source filters are reported explicitly.
var game
var map_number = 0
var emitters = []
var missing = []
var unsupported_filters = []

func _ready():
	var path = "res://assets/maps/%d-objects.json" % map_number
	if not FileAccess.file_exists(path): return
	var rows = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not rows is Array: return
	for row in rows:
		if row.get("type") != "SoundFX": continue
		var props = row.get("properties", {})
		var source = str(props.get("Sound", "")).replace("\\", "/").to_lower()
		var key = "root/" + source.trim_prefix("root/")
		var entry = game.game_audio.sounds.get(key, {})
		if entry.is_empty() or not ResourceLoader.exists(entry.get("asset", "")):
			missing.append({"source": source, "name": props.get("Name", ""), "reason": "source_audio_missing"})
			continue
		var stream = load(entry.asset).duplicate()
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if props.get("Loop", false) else AudioStreamWAV.LOOP_DISABLED
			stream.loop_begin = 0
			stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
		elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = bool(props.get("Loop", false))
		var audio = AudioStreamPlayer3D.new()
		audio.stream = stream
		audio.bus = "WolfEffects"
		audio.pitch_scale = clampf(float(props.get("PitchShift", 1)), 0.01, 4.0)
		audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		audio.panning_strength = 0.0 if props.get("Ambient", false) else 1.0
		var pos = props.get("Pos", [0, 0, 0])
		audio.position = Vector3(float(pos[0]), float(pos[1]), -float(pos[2])) * 0.016
		var outer = maxf(0.01, float(props.get("OuterRadius", 1000)) * 0.016)
		var inner = clampf(float(props.get("InnerRadius", 0)) * 0.016, 0, outer)
		audio.max_distance = outer
		audio.volume_db = -80
		add_child(audio)
		emitters.append({"audio": audio, "inner": inner, "outer": outer, "volume": clampf(float(props.get("Volume", 100)) / 100.0, 0, 1), "source": source, "startOn": props.get("StartOn", true)})
		if props.get("Filter", "UnFiltered") != "UnFiltered":
			unsupported_filters.append(props.get("Filter"))
		if props.get("StartOn", true) and not game.test_mode:
			audio.play()

func _process(_delta):
	var paused = game.menu_open or not game.running or game.application_suspended
	for entry in emitters:
		var audio = entry.audio
		audio.stream_paused = paused
		if paused: continue
		var distance = audio.global_position.distance_to(game.player.camera.global_position)
		var weight = 1.0 if distance <= entry.inner else clampf((entry.outer - distance) / maxf(0.001, entry.outer - entry.inner), 0, 1)
		audio.volume_db = linear_to_db(maxf(0.0001, entry.volume * weight))

func _exit_tree():
	for entry in emitters:
		entry.audio.stop()
		entry.audio.stream = null
	emitters.clear()
