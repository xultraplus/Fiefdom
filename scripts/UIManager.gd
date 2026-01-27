extends CanvasLayer

@onready var day_label: Label = $Control/DayLabel
@onready var inventory_label: Label = $Control/InventoryLabel
@onready var king_label: Label = $Control/KingLabel
@onready var stamina_label: Label = $Control/StaminaLabel
@onready var sleep_button: Button = $Control/SleepButton
@onready var manage_button: Button = $Control/ManageButton
@onready var fader: ColorRect = $Control/Fader

var management_panel_scene = preload("res://scenes/ManagementPanel.tscn")
var dialogue_scene = preload("res://scenes/DialoguePanel.tscn")
var management_panel_instance: Control
var settings_panel_instance: Panel
var quest_label: Label
var hotbar_label: Label
var stamina_bar: ProgressBar

func _ready() -> void:
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
	
	# Connect button
	sleep_button.pressed.connect(_on_sleep_pressed)
	manage_button.pressed.connect(_on_manage_pressed)
	
	GameEvents.game_over.connect(_on_game_over)
	
	# Add Menu Button
	var menu_btn = Button.new()
	menu_btn.text = "设置 (Menu)"
	menu_btn.position = Vector2(550, 10) # Top right
	menu_btn.pressed.connect(_on_menu_pressed)
	$Control.add_child(menu_btn)
	
	# Pre-instantiate settings panel
	var settings_script = load("res://scripts/SettingsPanel.gd")
	settings_panel_instance = settings_script.new()
	settings_panel_instance.visible = false
	$Control.add_child(settings_panel_instance)
	
	# Quest Label
	quest_label = Label.new()
	quest_label.position = Vector2(10, 80)
	quest_label.add_theme_color_override("font_color", Color.YELLOW)
	$Control.add_child(quest_label)
	
	# Hotbar Label (Placeholder for actual hotbar icons)
	hotbar_label = Label.new()
	hotbar_label.position = Vector2(250, 330) # Bottom center-ish
	hotbar_label.text = "当前种子: 黍 (1)"
	$Control.add_child(hotbar_label)
	
	# Stamina Bar
	stamina_bar = ProgressBar.new()
	stamina_bar.position = Vector2(10, 300)
	stamina_bar.custom_minimum_size = Vector2(150, 20)
	stamina_bar.max_value = 100
	stamina_bar.value = 100
	stamina_bar.show_percentage = false
	# Add stylebox override if needed, but default is fine for prototype
	$Control.add_child(stamina_bar)
	# Hide old label if redundant, or keep it
	stamina_label.visible = false
	
	update_ui()

func _on_seed_selected(seed_id: String) -> void:
	var crop = ItemManager.get_crop(seed_id)
	if crop:
		hotbar_label.text = "当前种子: " + crop.crop_name

func _on_menu_pressed() -> void:
	settings_panel_instance.visible = not settings_panel_instance.visible
	if settings_panel_instance.visible:
		settings_panel_instance.move_to_front()

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

func _on_reputation_changed(_new_amount: int) -> void:
	update_ui()
	# Optional: floating text or animation for penalty?
	if _new_amount < Global.reputation: # Wait, Global.reputation is already updated
		pass

func update_ui() -> void:
	day_label.text = "第 " + str(Global.current_day) + " 天"
	inventory_label.text = "铜钱: " + str(Global.money) + " | 背包: " + str(Global.player_inventory)
	king_label.text = "声望: " + str(Global.reputation) + " | 国库: " + str(Global.king_storage)
	# stamina_label.text = "体力: " + str(Global.current_stamina) + "/" + str(Global.max_stamina)
	if stamina_bar:
		stamina_bar.max_value = Global.max_stamina
		stamina_bar.value = Global.current_stamina
		
	if quest_label:
		quest_label.text = Global.current_quest
