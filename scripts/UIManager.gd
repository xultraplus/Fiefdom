extends CanvasLayer

@onready var day_label: Label = $Control/DayLabel
@onready var inventory_label: Label = $Control/InventoryLabel
@onready var king_label: Label = $Control/KingLabel
@onready var stamina_label: Label = $Control/StaminaLabel
@onready var sleep_button: Button = $Control/SleepButton
@onready var manage_button: Button = $Control/ManageButton
@onready var fader: ColorRect = $Control/Fader

var rank_label: Label
var money_label: Label
var reputation_label: Label
var well_field_label: Label
var quest_label: Label
var stamina_bar: ProgressBar
var reclaim_button: Button
var settings_button: Button
var debug_button: Button

var management_panel_scene = preload("res://scenes/ManagementPanel.tscn")
var dialogue_scene = preload("res://scenes/DialoguePanel.tscn")
var reclamation_panel_scene = preload("res://scenes/ReclamationPanel.tscn")
var debug_panel_scene = preload("res://scenes/DebugPanel.tscn")
var management_panel_instance: Control
var settings_panel_instance: Panel
var debug_panel_instance: Panel
var hotbar_label: Label

func _ready() -> void:
	# Dynamically create additional UI elements for new features
	_create_extended_ui()

	# Increase font sizes for better readability
	_increase_font_sizes()

	# Connect global signals
	GameEvents.day_advanced.connect(_on_day_advanced)
	GameEvents.crop_harvested.connect(_on_crop_harvested)
	GameEvents.stamina_changed.connect(_on_stamina_changed)
	GameEvents.visitor_interacted.connect(_on_visitor_interacted)
	GameEvents.reputation_changed.connect(_on_reputation_changed)

	# Connect World signals
	var world = get_node_or_null("../World")
	if world:
		if world.has_signal("seed_selected"):
			world.seed_selected.connect(_on_seed_selected)

	# Connect existing buttons
	sleep_button.pressed.connect(_on_sleep_pressed)
	manage_button.pressed.connect(_on_manage_pressed)

	GameEvents.game_over.connect(_on_game_over)

	# Pre-instantiate settings panel
	var settings_script = load("res://scripts/SettingsPanel.gd")
	settings_panel_instance = settings_script.new()
	settings_panel_instance.visible = false
	$Control.add_child(settings_panel_instance)

	# Add debug panel (only in debug builds)
	if OS.has_feature("debug") or OS.is_debug_build():
		debug_panel_instance = debug_panel_scene.instantiate()
		$Control.add_child(debug_panel_instance)
		# Add debug button manually since it's not in the original scene
		_create_debug_button()
	else:
		debug_button = null

	# Create reclaim and settings buttons
	_create_action_buttons()

	update_ui()

func _create_extended_ui() -> void:
	# Create rank label
	rank_label = Label.new()
	rank_label.position = Vector2(10, 40)
	rank_label.add_theme_font_size_override("font_size", 16)
	$Control.add_child(rank_label)

	# Create money label (separate from inventory for better layout)
	money_label = Label.new()
	money_label.position = Vector2(10, 70)
	money_label.add_theme_font_size_override("font_size", 16)
	$Control.add_child(money_label)

	# Create well field label
	well_field_label = Label.new()
	well_field_label.position = Vector2(10, 100)
	well_field_label.add_theme_font_size_override("font_size", 14)
	$Control.add_child(well_field_label)

	# Create stamina bar if it doesn't exist
	if not has_node("Control/StaminaBar"):
		stamina_bar = ProgressBar.new()
		stamina_bar.position = Vector2(10, 300)
		stamina_bar.custom_minimum_size = Vector2(180, 20)
		stamina_bar.max_value = 100
		stamina_bar.value = 100
		stamina_bar.show_percentage = false
		stamina_bar.add_theme_font_size_override("font_size", 12)
		$Control.add_child(stamina_bar)

func _create_action_buttons() -> void:
	# Create reclaim button
	reclaim_button = Button.new()
	reclaim_button.text = "开垦 (R)"
	reclaim_button.position = Vector2(180, 10)
	reclaim_button.custom_minimum_size = Vector2(100, 30)
	reclaim_button.add_theme_font_size_override("font_size", 14)
	$Control.add_child(reclaim_button)
	reclaim_button.pressed.connect(_on_reclaim_pressed)

	# Create settings button
	settings_button = Button.new()
	settings_button.text = "设置 (ESC)"
	settings_button.position = Vector2(290, 10)
	settings_button.custom_minimum_size = Vector2(100, 30)
	settings_button.add_theme_font_size_override("font_size", 14)
	$Control.add_child(settings_button)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_seed_selected(seed_id: String) -> void:
	var crop = ItemManager.get_crop(seed_id)
	if crop:
		print("当前种子: ", crop.crop_name)
		# TODO: Display selected seed in UI if needed

func _on_visitor_interacted(data: VisitorData) -> void:
	var dialog = dialogue_scene.instantiate()
	$Control.add_child(dialog)
	
	var options = ["论道 (Talk)", "交易 (Trade)", "招募 (Recruit - Need 20 Rep)", "送客 (Dismiss)"]
	var text = "在下" + data.name + "，乃" + data.get_school_name() + "门人。"
	dialog.setup(data.name, text, options)
	dialog.option_selected.connect(_on_dialog_option.bind(data))

func _on_dialog_option(index: int, data: VisitorData) -> void:
	print("Option selected: ", index)
	match index:
		0: # Talk
			Global.player_stats.add_xp(PlayerStats.Art.LITERACY, 10)
			Global.reputation += 5
			update_ui()
			print("Talked with visitor. Gained Literacy XP.")
		1: # Trade
			# Simple trade: 5 money -> 1 item (Gift)
			if Global.money >= 5:
				Global.money -= 5
				Global.player_inventory += 1
				update_ui()
				print("Traded with visitor.")
			else:
				print("Not enough money.")
		2: # Recruit
			if Global.reputation >= 20:
				Global.reputation -= 20
				var retainer_data = RetainerData.new(data.name, "士人")
				Global.retainers.append(retainer_data)
				GameEvents.retainer_recruited.emit(retainer_data)
				update_ui()
				print("Recruited visitor!")
				# Remove visitor from world logic would need reference, 
				# but currently Visitor.gd doesn't auto-remove on interaction.
				# We should probably emit a signal to remove the visitor or just handle it here if we had ref.
				# Since we only have 'data', we rely on World logic or just assume Visitor stays until day end?
				# Better: Find the visitor node and queue_free it.
				_remove_visitor_by_data(data)
			else:
				print("Not enough reputation.")
		3: # Dismiss
			print("Visitor dismissed.")
			_remove_visitor_by_data(data)

func _remove_visitor_by_data(data: VisitorData) -> void:
	var visitors = get_tree().get_nodes_in_group("interactable")
	for v in visitors:
		if v.get("data") == data:
			v.queue_free()
			break

func _on_game_over() -> void:
	var label = Label.new()
	label.text = "游戏结束：褫夺封地\n(连续3天未上缴)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.RED)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	$Control.add_child(bg)
	$Control.add_child(label)

	# Disable input
	sleep_button.disabled = true
	manage_button.disabled = true
	reclaim_button.disabled = true
	settings_button.disabled = true

func _on_manage_pressed() -> void:
	if management_panel_instance == null:
		management_panel_instance = management_panel_scene.instantiate()
		$Control.add_child(management_panel_instance)
		management_panel_instance.get_node("CloseButton").pressed.connect(_on_close_management)
	else:
		management_panel_instance.visible = true
		if management_panel_instance.has_method("refresh_retainers"):
			management_panel_instance.refresh_retainers()

func _on_close_management() -> void:
	if management_panel_instance:
		management_panel_instance.visible = false

func _on_reclaim_pressed() -> void:
	var reclamation_panel = reclamation_panel_scene.instantiate()
	$Control.add_child(reclamation_panel)

	# Get reference to tile map from World
	var world = get_tree().current_scene.get_node_or_null("World")
	if world and world.has_node("TileMapLayer"):
		var tile_map = world.get_node("TileMapLayer")
		reclamation_panel.setup(tile_map)
	else:
		print("Warning: Could not find TileMapLayer for reclamation panel")

func _on_settings_pressed() -> void:
	settings_panel_instance.visible = not settings_panel_instance.visible
	if settings_panel_instance.visible:
		settings_panel_instance.move_to_front()

func _on_debug_pressed() -> void:
	if debug_panel_instance:
		debug_panel_instance.visible = not debug_panel_instance.visible
		if debug_panel_instance.visible:
			debug_panel_instance.move_to_front()

func _on_sleep_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(fader, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		Global.current_day += 1
		Global.restore_stamina()
		GameEvents.day_advanced.emit(Global.current_day)
		update_ui()
	)
	tween.tween_property(fader, "color:a", 0.0, 0.5)

func _on_day_advanced(_day: int) -> void:
	update_ui()

func _on_crop_harvested(_is_public: bool) -> void:
	update_ui()

func _on_stamina_changed(_new_amount: int) -> void:
	update_ui()

func _on_reputation_changed(_new_amount: int) -> void:
	update_ui()
	# Optional: floating text or animation for penalty?
	if _new_amount < Global.reputation: # Wait, Global.reputation is already updated
		pass

func update_ui() -> void:
	# Update all labels
	if day_label and is_instance_valid(day_label):
		day_label.text = "第 %d 天" % Global.current_day

	if rank_label and is_instance_valid(rank_label):
		var rank_name = Global.rank_names.get(Global.current_rank, "未知")
		rank_label.text = "爵位: %s" % rank_name

	if money_label and is_instance_valid(money_label):
		money_label.text = "铜钱: %d" % Global.money

	if inventory_label and is_instance_valid(inventory_label):
		inventory_label.text = "背包: %d" % Global.player_inventory

	if reputation_label and is_instance_valid(reputation_label):
		reputation_label.text = "声望: %d" % Global.reputation

	if king_label and is_instance_valid(king_label):
		king_label.text = "国库: %d" % Global.king_storage

	if well_field_label and is_instance_valid(well_field_label):
		well_field_label.text = "井田: %d/%d" % [Global.well_fields.size(), Global.max_well_fields]

	# Update stamina bar
	if stamina_bar and is_instance_valid(stamina_bar):
		stamina_bar.max_value = Global.max_stamina
		stamina_bar.value = Global.current_stamina

	# Update quest
	if quest_label and is_instance_valid(quest_label):
		quest_label.text = Global.current_quest

func _create_debug_button() -> void:
	debug_button = Button.new()
	debug_button.text = "Debug (H)"
	debug_button.position = Vector2(400, 10)
	debug_button.custom_minimum_size = Vector2(100, 30)
	debug_button.add_theme_font_size_override("font_size", 14)
	$Control.add_child(debug_button)
	debug_button.pressed.connect(_on_debug_pressed)

func _increase_font_sizes() -> void:
	# Increase font sizes for existing labels in the .tscn file
	if day_label and is_instance_valid(day_label):
		day_label.add_theme_font_size_override("font_size", 16)

	if inventory_label and is_instance_valid(inventory_label):
		inventory_label.add_theme_font_size_override("font_size", 16)

	if king_label and is_instance_valid(king_label):
		king_label.add_theme_font_size_override("font_size", 16)

	if stamina_label and is_instance_valid(stamina_label):
		stamina_label.add_theme_font_size_override("font_size", 14)

	if sleep_button and is_instance_valid(sleep_button):
		sleep_button.add_theme_font_size_override("font_size", 16)

	if manage_button and is_instance_valid(manage_button):
		manage_button.add_theme_font_size_override("font_size", 16)
