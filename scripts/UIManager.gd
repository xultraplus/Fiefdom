extends CanvasLayer

@onready var day_label: Label = $Control/DayLabel
@onready var inventory_label: Label = $Control/InventoryLabel
@onready var king_label: Label = $Control/KingLabel
@onready var stamina_label: Label = $Control/StaminaLabel
@onready var sleep_button: Button = $Control/SleepButton
@onready var manage_button: Button = $Control/ManageButton
@onready var fader: ColorRect = $Control/Fader

var management_panel_scene = preload("res://scenes/ManagementPanel.tscn")
var management_panel_instance: Control

func _ready() -> void:
	# Connect global signals
	GameEvents.day_advanced.connect(_on_day_advanced)
	GameEvents.crop_harvested.connect(_on_crop_harvested)
	GameEvents.stamina_changed.connect(_on_stamina_changed)
	
	# Connect button
	sleep_button.pressed.connect(_on_sleep_pressed)
	manage_button.pressed.connect(_on_manage_pressed)
	
	GameEvents.game_over.connect(_on_game_over)
	
	update_ui()

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

func update_ui() -> void:
	day_label.text = "第 " + str(Global.current_day) + " 天"
	inventory_label.text = "铜钱: " + str(Global.money) + " | 背包: " + str(Global.player_inventory)
	king_label.text = "声望: " + str(Global.reputation) + " | 国库: " + str(Global.king_storage)
	stamina_label.text = "体力: " + str(Global.current_stamina) + "/" + str(Global.max_stamina)
