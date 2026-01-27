extends CanvasLayer

@onready var day_label: Label = $Control/DayLabel
@onready var inventory_label: Label = $Control/InventoryLabel
@onready var king_label: Label = $Control/KingLabel
@onready var stamina_label: Label = $Control/StaminaLabel
@onready var sleep_button: Button = $Control/SleepButton
@onready var fader: ColorRect = $Control/Fader

func _ready() -> void:
	# Connect global signals
	GameEvents.day_advanced.connect(_on_day_advanced)
	GameEvents.crop_harvested.connect(_on_crop_harvested)
	GameEvents.stamina_changed.connect(_on_stamina_changed)
	
	# Connect button
	sleep_button.pressed.connect(_on_sleep_pressed)
	
	update_ui()

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
	day_label.text = "Day: " + str(Global.current_day)
	inventory_label.text = "My Money: " + str(Global.money) + " | Items: " + str(Global.player_inventory)
	king_label.text = "Reputation: " + str(Global.reputation) + " | King's Treasury: " + str(Global.king_storage)
	stamina_label.text = "Stamina: " + str(Global.current_stamina) + "/" + str(Global.max_stamina)
