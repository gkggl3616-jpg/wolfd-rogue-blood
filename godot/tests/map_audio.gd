extends SceneTree

const MapAudio = preload("res://scripts/map_audio.gd")
const Audio = preload("res://scripts/game_audio.gd")
const Book = preload("res://scripts/content_book.gd")
class PlayerDouble extends RefCounted:
	var camera: Camera3D
class GameDouble extends RefCounted:
	var book
	var game_audio
	var player = PlayerDouble.new()
	var running = true
	var menu_open = false
	var application_suspended = false
	var test_mode = true
var checks = 0
var failures = 0

func _initialize(): call_deferred("run")
func ensure(value, description):
	checks += 1
	if not value: failures += 1;push_error("FAIL " + description)
	else: print("PASS " + description)

func check_original_sounds(audio):
	for original in [["am_bell",39936],["am_hawk",38528]]:
		var source=audio.sounds["root/wt_snd/mapsound/"+original[0]+".wav"]
		ensure(source.container=="user_supplied_pc_rar" and FileAccess.get_sha256(source.asset)==source.sourceSha256,"original RAR sound bytes replace the differing container version: "+original[0])
		var stream=load(source.asset) as AudioStreamWAV
		ensure(stream!=null and stream.mix_rate==22050 and is_equal_approx(stream.get_length(),float(original[1])/22050.0),"imported original PCM duration is retained: "+original[0])

func run():
	var game = GameDouble.new()
	game.book = Book.new(false)
	game.game_audio = Audio.new();game.game_audio.game = game;root.add_child(game.game_audio)
	check_original_sounds(game.game_audio)
	var world = Node3D.new();root.add_child(world)
	game.player.camera = Camera3D.new();world.add_child(game.player.camera)
	var total = 0
	var missing = []
	var expected_total=0;var expected_missing=0;var original_total=0;var original_missing=[]
	var original=[1,2,26,31,44,46,50,57,58,59,65,72,82,83,84,92,97,100,110]
	var maps = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/previews.json"))
	for map in maps:
		var audio = MapAudio.new();audio.game = game;audio.map_number = int(map.number);world.add_child(audio)
		total += audio.emitters.size()
		for item in audio.missing:missing.append({"map":int(map.number),"source":item.source})
		if int(map.number) in original:original_total+=audio.emitters.size();original_missing.append_array(audio.missing)
		var objects = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/%d-objects.json" % int(map.number)))
		var sources = objects.filter(func(row): return row.get("type") == "SoundFX")
		ensure(audio.emitters.size() + audio.missing.size() == sources.size(), "map %d accounts for every source sound without substitutions" % int(map.number))
		for source in sources:
			var key="root/"+str(source.properties.get("Sound","")).replace("\\","/").to_lower().trim_prefix("root/")
			if game.game_audio.sounds.has(key) and ResourceLoader.exists(game.game_audio.sounds[key].asset):expected_total+=1
			else:expected_missing+=1
		for emitter in audio.emitters:
			ensure(emitter.audio.bus == &"WolfEffects" and emitter.audio.stream != null, "source sound uses effects channel: " + emitter.source)
			# Exercise the actual playback/pause state, not a stopped test double.
			emitter.audio.play()
			await process_frame
			game.player.camera.global_position = emitter.audio.global_position
			audio._process(0)
			ensure(is_equal_approx(emitter.audio.volume_db, linear_to_db(maxf(0.0001, emitter.volume))), "source inner-radius volume is applied")
			game.menu_open = true;audio._process(0)
			ensure(emitter.audio.stream_paused, "map sound pauses with menu")
			game.menu_open = false
		world.remove_child(audio);audio.queue_free()
		await process_frame
	ensure(original_total==43 and original_missing.size()==3,"Original 19 maps retain 43 exact source sounds and three unresolved objects")
	ensure(total==expected_total and missing.size()==expected_missing,"All 34 maps account for their own available/missing source sounds")
	ensure(original_missing.all(func(row): return row.source.ends_with("am_fire_sm_loop.wav")), "missing fire-loop is never replaced by another sound")
	ensure(world.get_child_count() == 1, "changing maps releases all old sound nodes")
	world.queue_free();game.game_audio.queue_free()
	game=null
	# The audio mixer has a real-time buffer even under fixed-fps simulation.
	await process_frame
	OS.delay_msec(250)
	await process_frame
	var proof=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/map-audio-validation-015.json"),FileAccess.WRITE);proof.store_string(JSON.stringify({"passed":failures==0,"checks":checks,"boundEmitters":total,"missing":missing},"  ")+"\n");proof.close()
	print("MAP_AUDIO_QA checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
