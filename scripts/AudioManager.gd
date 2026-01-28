extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_sfx_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect to game events
	GameEvents.rank_changed.connect(_on_rank_changed)
	GameEvents.tax_reform_triggered.connect(_on_tax_reform_triggered)
	GameEvents.well_field_added.connect(_on_well_field_added)

	# Create Audio Buses if they don't exist (Code only approach for prototype)
	# Usually better to do in Editor, but here we do it in code.
	# We will just assume Master bus exists.
	# We can create sub-buses: Music, SFX

	if AudioServer.get_bus_count() == 1: # Only Master
		var music_bus_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(music_bus_idx, "Music")
		AudioServer.set_bus_send(music_bus_idx, "Master")

		var sfx_bus_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")

	# Setup Players
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	ui_sfx_player = AudioStreamPlayer.new()
	ui_sfx_player.bus = "SFX"
	add_child(ui_sfx_player)

func play_bgm(stream: AudioStream, fade_time: float = 1.0) -> void:
	if bgm_player.stream == stream:
		return

	if bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func():
			bgm_player.stream = stream
			bgm_player.play()
			bgm_player.volume_db = 0.0 # Reset?
			# Actually we want to fade in
		)
	else:
		bgm_player.stream = stream
		bgm_player.play()

func play_sfx(stream: AudioStream) -> void:
	# For overlapping SFX, we might need a pool, but for now single player is fine for simple stuff
	# Or instantiate temporary players
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

# Play UI sound effect (button clicks, etc.)
func play_ui_sfx(pitch: float = 1.0) -> void:
	ui_sfx_player.pitch_scale = pitch
	if ui_sfx_player.stream == null:
		# Create a simple beep sound
		var stream = AudioStreamGenerator.new()
		stream.buffer_length = 0.1
		stream.mix_rate = 44100
		ui_sfx_player.stream = stream
	ui_sfx_player.play()

# Play event sound (rank up, special events)
func play_event_sound(event_type: String) -> void:
	match event_type:
		"rank_up":
			# Ascending tone
			_play_tone_sequence([440, 554, 659], 0.1)  # A4, C#5, E5 (A major chord)
		"event_triggered":
			# Dramatic chord
			_play_tone_sequence([220, 277, 330, 440], 0.2)  # A3, C#4, E4, A4
		"well_field_added":
			# Pleasant notification
			_play_tone_sequence([523, 659], 0.15)  # C5, E5
		"tax_reform":
			# Serious tone
			_play_tone_sequence([196, 196, 220], 0.3)  # G3, G3, A3

func _play_tone_sequence(frequencies: Array, duration: float) -> void:
	for i in range(frequencies.size()):
		var delay = i * duration
		var timer = get_tree().create_timer(delay)
		timer.timeout.connect(_play_tone.bind(frequencies[i], duration))

func _play_tone(frequency: float, duration: float) -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"

	# Create a simple tone using AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.buffer_length = duration
	generator.mix_rate = 44100
	player.stream = generator

	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

	# Fill the buffer with a sine wave
	await get_tree().process_frame
	var playback = player.get_stream_playback()
	var frames_needed = generator.mix_rate * duration

	for i in range(frames_needed):
		var time = float(i) / generator.mix_rate
		var phase = 2.0 * PI * frequency * time
		var amplitude = sin(phase) * 0.3

		# Create stereo audio frame
		var frame: Vector2 = Vector2(amplitude, amplitude)
		playback.push_frame(frame)

# Event handlers
func _on_rank_changed(new_rank: Global.Rank) -> void:
	print("Audio: Playing rank up sound!")
	play_event_sound("rank_up")

func _on_tax_reform_triggered() -> void:
	print("Audio: Playing tax reform event sound!")
	play_event_sound("tax_reform")

func _on_well_field_added(field_id: int) -> void:
	print("Audio: Playing well field added sound!")
	play_event_sound("well_field_added")
