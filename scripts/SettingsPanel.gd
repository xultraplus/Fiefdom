extends Panel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(300, 250)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 10) # Margin
	add_child(vbox)
	
	var label = Label.new()
	label.text = "系统设置 (Settings)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Save/Load
	var save_btn = Button.new()
	save_btn.text = "保存游戏 (Save)"
	save_btn.pressed.connect(func(): Global.save_game())
	vbox.add_child(save_btn)
	
	var load_btn = Button.new()
	load_btn.text = "读取游戏 (Load)"
	load_btn.pressed.connect(func(): Global.load_game())
	vbox.add_child(load_btn)
	
	# Volume
	var vol_label = Label.new()
	vol_label.text = "音量 (Volume)"
	vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	vol_slider.min_value = 0
	vol_slider.max_value = 1
	vol_slider.step = 0.1
	vol_slider.value = 1.0 # Default
	vol_slider.value_changed.connect(_on_volume_changed)
	vbox.add_child(vol_slider)
	
	# Fullscreen
	var fs_btn = CheckButton.new()
	fs_btn.text = "全屏 (Fullscreen)"
	fs_btn.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fs_btn)
	
	var close_btn = Button.new()
	close_btn.text = "关闭 (Close)"
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
