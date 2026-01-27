extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var crops_layer: TileMapLayer = $CropsLayer
@onready var player: Player = $Player

# Dictionary to store active crops: { Vector2i: { "data": CropData, "age": int, "watered": bool } }
var active_crops: Dictionary = {}

# Preload crop data (for prototype)
var millet_data = preload("res://scripts/CropData.gd").new()
var floating_text_scene = preload("res://scenes/FloatingText.tscn")
var retainer_scene = preload("res://scenes/Retainer.tscn")

func _ready() -> void:
	millet_data.crop_name = "Millet"
	millet_data.days_to_grow = 2
	var stages: Array[Vector2i] = [Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)]
	millet_data.stages_atlas_coords = stages
	
	GameEvents.day_advanced.connect(_on_day_advanced)
	
	# Setup initial map for testing (3x3 grid)
	setup_test_map()
	
	# Setup Navigation (Runtime generation for prototype)
	setup_navigation()
	
	# Inject dependency
	player.tile_map_ref = tile_map
	
	# Spawn a test retainer
	spawn_retainer()

func setup_navigation() -> void:
	var nav_region = NavigationRegion2D.new()
	var nav_poly = NavigationPolygon.new()
	var outline = PackedVector2Array([Vector2(-500, -500), Vector2(500, -500), Vector2(500, 500), Vector2(-500, 500)])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)
	# Force update?
	# nav_region.bake_navigation_polygon() # Not needed if we set it directly? Wait, in Godot 4.x baking is usually async or required.
	# But creating a NavigationPolygon manually usually works if we assign it. 
	# Actually, NavigationRegion2D needs to be part of the tree.
	
	print("Navigation Setup Complete")

func spawn_retainer() -> void:
	var retainer = retainer_scene.instantiate()
	retainer.global_position = Vector2(100, 100)
	add_child(retainer)

func get_nearest_dry_crop(from_pos: Vector2) -> Vector2i:
	var nearest_pos = Vector2i(-1, -1)
	var min_dist = 999999.0
	
	for grid_pos in active_crops:
		var info = active_crops[grid_pos]
		if not info["watered"]:
			var world_pos = tile_map.map_to_local(grid_pos)
			var dist = from_pos.distance_squared_to(world_pos)
			if dist < min_dist:
				min_dist = dist
				nearest_pos = grid_pos
	
	return nearest_pos

func water_crop(grid_pos: Vector2i) -> void:
	if active_crops.has(grid_pos):
		var info = active_crops[grid_pos]
		if not info["watered"]:
			info["watered"] = true
			spawn_floating_text(grid_pos, "Watered", Color.CYAN)
			print("Crop watered at ", grid_pos)

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
		# Check tile state
		var atlas_coords = tile_map.get_cell_atlas_coords(grid_pos)
		if atlas_coords.y == 0: # Raw soil
			till_soil(grid_pos, atlas_coords)
		elif atlas_coords.y == 1: # Tilled soil
			plant_crop(grid_pos)

func till_soil(grid_pos: Vector2i, current_atlas_coords: Vector2i) -> void:
	if Global.current_stamina < 2:
		spawn_floating_text(grid_pos, "No Stamina!", Color.RED)
		print("Not enough stamina to till!")
		return
		
	Global.current_stamina -= 2
	GameEvents.stamina_changed.emit(Global.current_stamina)
	
	# Change to tilled version (y=1)
	var new_atlas_coords = Vector2i(current_atlas_coords.x, 1)
	tile_map.set_cell(grid_pos, 0, new_atlas_coords)
	spawn_floating_text(grid_pos, "Tilled", Color.WHITE)
	print("Tilled at ", grid_pos)

func plant_crop(grid_pos: Vector2i) -> void:
	if Global.current_stamina < 2:
		spawn_floating_text(grid_pos, "No Stamina!", Color.RED)
		print("Not enough stamina to plant!")
		return

	# Check if valid ground
	var tile_data = tile_map.get_cell_tile_data(grid_pos)
	if tile_data:
		Global.current_stamina -= 2
		GameEvents.stamina_changed.emit(Global.current_stamina)
		
		active_crops[grid_pos] = {
			"data": millet_data,
			"age": 0,
			"watered": false 
		}
		# Visual feedback: place seed
		var seed_coords = millet_data.stages_atlas_coords[0]
		crops_layer.set_cell(grid_pos, 0, seed_coords)
		spawn_floating_text(grid_pos, "Planted", Color.GREEN)
		print("Planted at ", grid_pos)

func harvest_crop(grid_pos: Vector2i) -> void:
	if Global.current_stamina < 3:
		spawn_floating_text(grid_pos, "No Stamina!", Color.RED)
		print("Not enough stamina!")
		return

	var crop_info = active_crops[grid_pos]
	if crop_info["age"] >= crop_info["data"].days_to_grow:
		Global.current_stamina -= 3
		GameEvents.stamina_changed.emit(Global.current_stamina)
		
		# Check ownership
		var tile_data = tile_map.get_cell_tile_data(grid_pos)
		var is_public = tile_data.get_custom_data("is_public_field")
		
		GameEvents.crop_harvested.emit(is_public)
		Global.add_item(is_public)
		
		# Remove crop
		active_crops.erase(grid_pos)
		crops_layer.erase_cell(grid_pos)
		
		if is_public:
			spawn_floating_text(grid_pos, "Public Harvest!", Color.GOLD)
		else:
			spawn_floating_text(grid_pos, "Harvested!", Color.GREEN)
		print("Harvested!")
	else:
		spawn_floating_text(grid_pos, "Not Ready", Color.GRAY)
		print("Not ready yet. Age: ", crop_info["age"])

func spawn_floating_text(grid_pos: Vector2i, text: String, color: Color) -> void:
	var instance = floating_text_scene.instantiate()
	instance.text = text
	instance.modulate = color
	# Convert grid pos to global pos (center of tile)
	var world_pos = tile_map.map_to_local(grid_pos)
	instance.global_position = world_pos - Vector2(20, 20) # Offset slightly
	add_child(instance)

func _on_day_advanced(new_day: int) -> void:
	print("Day Advanced to ", new_day)
	for pos in active_crops:
		var info = active_crops[pos]
		if info["watered"]:
			info["age"] += 1
			info["watered"] = false # Reset water status
			
			# Update visual
			var stage_idx = min(info["age"], info["data"].stages_atlas_coords.size() - 1)
			var atlas_coords = info["data"].stages_atlas_coords[stage_idx]
			crops_layer.set_cell(pos, 0, atlas_coords)
