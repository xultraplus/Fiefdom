extends Control

@onready var retainer_list_container: VBoxContainer = $HBoxContainer/LeftPanel/ScrollContainer/VBoxContainer
# Updated path due to TabContainer
@onready var map_grid_container: GridContainer = $HBoxContainer/RightPanel/封地概览/GridContainer
@onready var market_panel: VBoxContainer = $HBoxContainer/RightPanel/市场
@onready var food_label: Label = $HBoxContainer/RightPanel/市场/FoodLabel
@onready var crop_label: Label = $HBoxContainer/RightPanel/市场/CropLabel
@onready var money_label: Label = $HBoxContainer/RightPanel/市场/MoneyLabel

var retainer_item_scene = preload("res://scenes/RetainerItem.tscn")
var map_grid_item_script = preload("res://scripts/MapGridItem.gd")

# Six Arts UI References
@onready var stats_container: VBoxContainer = $HBoxContainer/RightPanel/君子六艺/StatsContainer

func _ready() -> void:
	refresh_retainers()
	setup_map_grid()
	setup_market()
	setup_six_arts()
	setup_tech()

func setup_tech() -> void:
	var tech_container = $HBoxContainer/RightPanel/科技/TechContainer
	if tech_container:
		tech_container.get_node("IrrigationButton").pressed.connect(_on_unlock_irrigation)
		tech_container.get_node("BowButton").pressed.connect(_on_unlock_bow)

func _on_unlock_irrigation() -> void:
	if Global.player_stats.get_stat(PlayerStats.Art.LITERACY)["level"] >= 3:
		Global.tech_unlocked["irrigation"] = true
		print("Irrigation Unlocked!")
		$HBoxContainer/RightPanel/科技/TechContainer/IrrigationButton.disabled = true
		$HBoxContainer/RightPanel/科技/TechContainer/IrrigationButton.text = "已解锁水利 (Unlocked)"
	else:
		print("Not enough Literacy level! Need Lv.3")

func _on_unlock_bow() -> void:
	if Global.player_stats.get_stat(PlayerStats.Art.ARCHERY)["level"] >= 2:
		Global.tech_unlocked["composite_bow"] = true
		print("Composite Bow Unlocked!")
		$HBoxContainer/RightPanel/科技/TechContainer/BowButton.disabled = true
		$HBoxContainer/RightPanel/科技/TechContainer/BowButton.text = "已解锁复合弓 (Unlocked)"
	else:
		print("Not enough Archery level! Need Lv.2")

func setup_six_arts() -> void:
	# Connect buttons
	var actions = $HBoxContainer/RightPanel/君子六艺/Actions
	if actions:
		actions.get_node("ReadButton").pressed.connect(_on_read_pressed)
		actions.get_node("WorshipButton").pressed.connect(_on_worship_pressed)
	
	# Initial update
	update_stats_ui()
	
	# Connect signals
	Global.player_stats.xp_changed.connect(_on_xp_changed)
	Global.player_stats.level_up.connect(_on_level_up)

func update_stats_ui() -> void:
	if not stats_container: return
	
	# Clear existing (or update if we had fixed nodes, but dynamic is safer for now if we didn't create them in scene)
	# Actually, let's assume we created them in the scene for simplicity, or we can generate them here.
	# Generating them is safer as I don't want to mess up the .tscn file too much.
	
	for child in stats_container.get_children():
		child.queue_free()
		
	for i in range(6): # 0 to 5
		var stat = Global.player_stats.get_stat(i)
		var stat_name = Global.player_stats.get_art_name(i)
		
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat_name
		name_label.custom_minimum_size.x = 100
		hbox.add_child(name_label)
		
		var progress = ProgressBar.new()
		progress.max_value = stat["max_xp"]
		progress.value = stat["xp"]
		progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.custom_minimum_size.y = 20
		progress.show_percentage = false
		hbox.add_child(progress)
		
		var level_label = Label.new()
		level_label.text = "Lv. " + str(stat["level"])
		hbox.add_child(level_label)
		
		stats_container.add_child(hbox)

func _on_read_pressed() -> void:
	# Reading increases Literacy (书)
	Global.player_stats.add_xp(PlayerStats.Art.LITERACY, 10)
	print("Reading book...")

func _on_worship_pressed() -> void:
	# Worship increases Rites (礼)
	Global.player_stats.add_xp(PlayerStats.Art.RITES, 10)
	print("Worshipping...")

func _on_xp_changed(art_name: String, xp: int, max_xp: int) -> void:
	update_stats_ui()

func _on_level_up(art_name: String, level: int) -> void:
	update_stats_ui()
	# Maybe show a popup or floating text?


func _process(delta: float) -> void:
	# Ideally use signals, but for prototype polling is fine for UI
	if visible:
		update_market_ui()

func refresh_retainers() -> void:
	# Clear existing
	for child in retainer_list_container.get_children():
		child.queue_free()
		
	# Add from Global
	for r in Global.retainers:
		var item = retainer_item_scene.instantiate()
		retainer_list_container.add_child(item)
		item.setup(r)
	
	update_market_ui()

func setup_map_grid() -> void:
	# Assuming 3x3 map for prototype
	map_grid_container.columns = 3
	
	for y in range(-1, 2):
		for x in range(-1, 2):
			var grid_pos = Vector2i(x, y) + Vector2i(5, 5) # Offset as per World.gd setup
			var item = ColorRect.new()
			item.custom_minimum_size = Vector2(50, 50)
			item.set_script(map_grid_item_script)
			item.grid_pos = grid_pos
			item.retainer_dropped.connect(_on_retainer_assigned)
			
			# Check if public/private
			if x == 0 and y == 0:
				item.color = Color.GOLD # Public
			else:
				item.color = Color.FOREST_GREEN # Private
				
			map_grid_container.add_child(item)

func setup_market() -> void:
	market_panel.get_node("SellButton").pressed.connect(_on_sell_pressed)
	market_panel.get_node("BuyFoodButton").pressed.connect(_on_buy_food_pressed)
	market_panel.get_node("ConvertButton").pressed.connect(_on_convert_pressed)

func update_market_ui() -> void:
	food_label.text = "粮仓: " + str(Global.food_storage)
	crop_label.text = "作物库存: " + str(Global.player_inventory)
	money_label.text = "铜钱: " + str(Global.money)

func _on_sell_pressed() -> void:
	if Global.player_inventory > 0:
		Global.player_inventory -= 1
		Global.money += 5
		update_market_ui()
		GameEvents.money_changed.emit(Global.money)

func _on_buy_food_pressed() -> void:
	if Global.money >= 5:
		Global.money -= 5
		Global.food_storage += 1
		update_market_ui()
		GameEvents.money_changed.emit(Global.money)

func _on_convert_pressed() -> void:
	Global.convert_inventory_to_food(1)
	update_market_ui()

func _on_retainer_assigned(grid_pos: Vector2i, data: RetainerData) -> void:
	print("Assigned ", data.name, " to ", grid_pos)
	# Notify World or Update Logic
	# For prototype, we just print. Ideally, we signal World to update the Retainer's target.
	# But ManagementPanel is UI. 
	# Let's emit a signal that Main/World can listen to.
	GameEvents.retainer_assigned.emit(data, grid_pos)
