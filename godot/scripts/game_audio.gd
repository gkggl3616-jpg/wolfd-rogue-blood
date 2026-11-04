extends Node

const BUSES = {"music_volume": "WolfMusic", "effects_volume": "WolfEffects", "weapons_volume": "WolfWeapons", "ui_volume": "WolfUI"}
var game
var sounds = {}
var ui: AudioStreamPlayer
var music: AudioStreamPlayer
var music_key = ""
var last_played = ""
var suspended = false

func _ready():
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
	if suspended: return
	var key = "root/wt_snd/background/game.ogg" if game.running and not game.menu_open else "root/wt_snd/background/lobby.ogg"
	if key == music_key: return
	music_key = key
	music.stop()
	if sounds.has(key) and not game.test_mode:
		music.stream = load(sounds[key].asset).duplicate()
		if music.stream is AudioStreamOggVorbis: music.stream.loop = true
		music.play()

func _exit_tree():
	if get_tree() and get_tree().node_added.is_connected(on_node_added):
		get_tree().node_added.disconnect(on_node_added)
	ui.stop()
	music.stop()
