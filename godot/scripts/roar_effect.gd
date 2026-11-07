extends Node3D

var player
var active = false
var elapsed = 0.0
var duration = 1.5
var intensity = 0.0
var cooldown = 0.0
var audio: AudioStreamPlayer3D
var aura: AnimatedSprite3D
var light: OmniLight3D
var materials = []
var source_effect

func _ready():
	audio = AudioStreamPlayer3D.new();audio.stream = load("res://assets/abilities/wolf-roar.wav");audio.volume_db = -12;audio.max_distance = 24;add_child(audio)
	aura = AnimatedSprite3D.new();aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED;aura.pixel_size = 0.007;aura.position = Vector3(0, 1.15, 0);aura.shaded = false;aura.modulate = Color(0.65, 0.28, 1, 0);add_child(aura)
	var frames = SpriteFrames.new();frames.set_animation_loop("default", true)
	for entry in player.game.book.effects:
		if entry.source.ends_with("/psychocry/psychocry.spr"):
			for path in entry.frames: frames.add_frame("default", load(path))
			frames.set_animation_speed("default", entry.fps);break
	aura.sprite_frames = frames;aura.hide()
	light = OmniLight3D.new();light.position = Vector3(0, 1.1, 0.1);light.light_color = Color(0.62, 0.22, 1);light.omni_range = 2.8;light.shadow_enabled = false;light.light_energy = 0;add_child(light)
	source_effect=Node3D.new();source_effect.set_script(preload("res://scripts/source_roar.gd"));source_effect.player=player;add_child(source_effect)
	bind_tattoos()

func bind_tattoos():
	materials.clear()
	for mesh in player.wolf.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name).to_lower().begins_with("tattoo") and mesh.visible and mesh.material_override is StandardMaterial3D:
			var material = mesh.material_override;material.emission_enabled = true;material.emission_texture = material.albedo_texture;material.emission = Color.WHITE;material.emission_energy_multiplier = 0;materials.append(material)

func begin(seconds):
	if not player.is_wolf or player.game.menu_open or not player.game.running: return false
	stop();cooldown=0
	duration = maxf(0.1, seconds);elapsed = 0;active = true;cooldown = 0;bind_tattoos();aura.hide()
	source_effect.begin()
	return true

func stop():
	if is_instance_valid(source_effect):source_effect.stop()
	active = false;elapsed = 0;intensity = 0;audio.stop();aura.stop();aura.hide();light.light_energy = 0
	for material in materials: material.emission_energy_multiplier = 0

func advance(delta):
	if not player.game.menu_open: cooldown = maxf(0, cooldown - delta)
	if not active: return
	if not player.is_wolf or not player.game.is_combat_active(): stop();return
	player.advance_howl_health(minf(delta,maxf(0,duration-elapsed)));elapsed += delta
	if elapsed >= duration:
		player.restore_howl_health();stop();return
	var phase = elapsed / duration
	intensity = sin(PI * phase) * (0.85 + 0.15 * sin(elapsed * 22))
	for material in materials: material.emission_energy_multiplier = intensity * 0.45
	aura.modulate.a = intensity * 0.65;aura.scale = Vector3.ONE * (0.65 + phase * 0.5);light.light_energy = 0

func _process(delta): advance(delta)
