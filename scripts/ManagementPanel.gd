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

func _ready() -> void:
	refresh_retainers()
	setup_map_grid()
	setup_market()

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
