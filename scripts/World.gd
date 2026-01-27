extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var crops_layer: TileMapLayer = $CropsLayer
@onready var player: Player = $Player

# Dictionary to store active crops: { Vector2i: { "data": CropData, "age": int, "watered": bool } }
var active_crops: Dictionary = {}

# Preload crop data (for prototype)
var millet_data = preload("res://scripts/CropData.gd").new()

func _ready() -> void:
	millet_data.crop_name = "Millet"
	millet_data.days_to_grow = 1
	
	GameEvents.day_advanced.connect(_on_day_advanced)
	
	# Setup initial map for testing (3x3 grid)
	setup_test_map()

func setup_test_map() -> void:
	# Center is Public (1,0 atlas coords), surrounding is Private (0,0 atlas coords)
	# Using source_id 0
	var center = Vector2i(5, 5)
	for x in range(-1, 2):
		for y in range(-1, 2):
			var coords = center + Vector2i(x, y)
			var atlas_coords = Vector2i(0, 0) # Private
			if x == 0 and y == 0:
				atlas_coords = Vector2i(1, 0) # Public
			
			tile_map.set_cell(coords, 0, atlas_coords)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = tile_map.local_to_map(mouse_pos)
		handle_interaction(grid_pos)

func handle_interaction(grid_pos: Vector2i) -> void:
	# Check if there is a crop
	if active_crops.has(grid_pos):
		harvest_crop(grid_pos)
	else:
		plant_crop(grid_pos)

func plant_crop(grid_pos: Vector2i) -> void:
	# Check if valid ground
	var tile_data = tile_map.get_cell_tile_data(grid_pos)
	if tile_data:
		active_crops[grid_pos] = {
			"data": millet_data,
			"age": 0,
			"watered": true # Auto water for prototype
		}
		# Visual feedback: place a "seed" tile (using same texture for now, maybe different color mod later)
		crops_layer.set_cell(grid_pos, 0, Vector2i(0,0)) # Placeholder visual
		print("Planted at ", grid_pos)

func harvest_crop(grid_pos: Vector2i) -> void:
	var crop_info = active_crops[grid_pos]
	if crop_info["age"] >= crop_info["data"].days_to_grow:
		# Check ownership
		var tile_data = tile_map.get_cell_tile_data(grid_pos)
		var is_public = tile_data.get_custom_data("is_public_field")
		
		GameEvents.crop_harvested.emit(is_public)
		Global.add_item(is_public)
		
		# Remove crop
		active_crops.erase(grid_pos)
		crops_layer.erase_cell(grid_pos)
		print("Harvested!")
	else:
		print("Not ready yet. Age: ", crop_info["age"])

func _on_day_advanced(new_day: int) -> void:
	print("Day Advanced to ", new_day)
	for pos in active_crops:
		var info = active_crops[pos]
		if info["watered"]:
			info["age"] += 1
			info["watered"] = false # Reset water status
			# Update visual if needed
