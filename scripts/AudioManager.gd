extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_sfx_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
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
