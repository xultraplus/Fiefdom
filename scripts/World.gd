extends Node2D

signal seed_selected(seed_id: String)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var crops_layer: TileMapLayer = $CropsLayer
@onready var player: Player = $Player

# Dictionary to store active crops: { Vector2i: { "data": CropData, "age": int, "watered": bool } }
var active_crops: Dictionary:
	get: return Global.active_crops

var retainer_instances: Dictionary = {} # RetainerData -> Retainer Node

# Preload crop data (for prototype)
# var millet_data = preload("res://scripts/CropData.gd").new() # Use ItemManager instead
var current_seed_id: String = "millet"

var floating_text_scene = preload("res://scenes/FloatingText.tscn")
var retainer_scene = preload("res://scenes/Retainer.tscn")
var visitor_scene = preload("res://scenes/Visitor.tscn")
var enemy_scene = preload("res://scenes/Enemy.tscn")
var active_visitors: Array = []

func _ready() -> void:
	# millet_data.crop_name = "黍" ... # Moved to ItemManager

	GameEvents.day_advanced.connect(_on_day_advanced)
	GameEvents.retainer_assigned.connect(_on_retainer_assigned)
	GameEvents.retainer_recruited.connect(_on_retainer_recruited)

	# Setup initial map for testing (3x3 grid)
	setup_test_map()

	# Initialize first well field if none exists
	if Global.well_fields.is_empty():
		Global.add_well_field(Vector2i(5, 5))
		Global.well_fields[0]["is_unlocked"] = true  # First field is already ready
		Global.well_fields[0]["reclamation_progress"] = 4
		print("Initialized first well field at (5, 5)")

	# Setup Navigation (Runtime generation for prototype)
	setup_navigation()

	# Inject dependency
	player.tile_map_ref = tile_map

	setup_wilderness_entrance()

	# Spawn retainers from Global
	for r_data in Global.retainers:
		spawn_retainer(r_data)

	# Restore crop visuals
	restore_crops_visuals()

	# Enemy Spawner
	var timer = Timer.new()
	timer.wait_time = 30.0 # Every 30 seconds
	timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	timer.autostart = true
	add_child(timer)

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemy.type = randi() % 2 # Random type
	# Random position (edge of map logic is simplified here)
	var angle = randf() * TAU
	var dist = 500
	enemy.global_position = Vector2(cos(angle), sin(angle)) * dist
	add_child(enemy)
	print("Enemy spawned: ", enemy.type)

func get_random_crop_pos() -> Vector2i:
	if active_crops.is_empty():
		return Vector2i(-1, -1)
	var keys = active_crops.keys()
	return keys[randi() % keys.size()]

func destroy_crop(grid_pos: Vector2i) -> void:
	if active_crops.has(grid_pos):
		active_crops.erase(grid_pos)
		crops_layer.erase_cell(grid_pos)
		spawn_floating_text(grid_pos, "作物被毁!", Color.RED)

func get_crop_world_pos(grid_pos: Vector2i) -> Vector2:
	return tile_map.map_to_local(grid_pos)

func restore_crops_visuals() -> void:
	for grid_pos in active_crops:
		var info = active_crops[grid_pos]
		# Ensure data is valid (might need to re-link Resource if it wasn't saved properly, 
		# but since Global persists in memory, it should be fine)
		if info.has("data") and info["data"] != null:
			var stage_idx = min(info["age"], info["data"].stages_atlas_coords.size() - 1)
			var atlas_coords = info["data"].stages_atlas_coords[stage_idx]
			crops_layer.set_cell(grid_pos, 0, atlas_coords)
			# print("Restored crop at ", grid_pos)

func setup_wilderness_entrance() -> void:
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 50)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_wilderness_entered)
	area.global_position = Vector2(400, 0) # Right edge
	add_child(area)
	
	# Visual
	var rect = ColorRect.new()
	rect.size = Vector2(50, 50)
	rect.position = Vector2(-25, -25)
	rect.color = Color(0.5, 0.2, 0.2, 0.5) # Reddish
	area.add_child(rect)
	
	# Label
	var label = Label.new()
	label.text = "野外 (Wilderness)"
	label.position = Vector2(-40, -40)
	area.add_child(label)

func _on_wilderness_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Entering Wilderness...")
		get_tree().change_scene_to_file("res://scenes/Wilderness.tscn")

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

func spawn_retainer(data: RetainerData) -> void:
	var retainer = retainer_scene.instantiate()
	retainer.data = data
	retainer.global_position = Vector2(100, 100) # Spawn point
	add_child(retainer)
	retainer_instances[data] = retainer

func _on_retainer_assigned(data: RetainerData, grid_pos: Vector2i) -> void:
	if retainer_instances.has(data):
		var retainer = retainer_instances[data]
		retainer.assigned_area = grid_pos
		retainer.set_state(retainer.State.IDLE) # Trigger logic update
		print("World: Assigned ", data.name, " to ", grid_pos)

func _on_retainer_recruited(data: RetainerData) -> void:
	spawn_retainer(data)
	spawn_floating_text(Vector2i(5,5), "新门客加入！", Color.GOLD)
	print("World: Recruited ", data.name)

func is_crop_dry(grid_pos: Vector2i) -> bool:
	if active_crops.has(grid_pos):
		return not active_crops[grid_pos]["watered"]
	return false

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
			spawn_floating_text(grid_pos, "已浇水", Color.CYAN)
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
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: current_seed_id = "millet"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 黍", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_2: current_seed_id = "sorghum"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 稷", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_3: current_seed_id = "rice"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 稻", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_4: current_seed_id = "wheat"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 麦", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_5: current_seed_id = "beans"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 菽", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_6: current_seed_id = "mulberry"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 桑", Color.WHITE); seed_selected.emit(current_seed_id)
			KEY_7: current_seed_id = "hemp"; spawn_floating_text(tile_map.local_to_map(get_global_mouse_position()), "选种: 麻", Color.WHITE); seed_selected.emit(current_seed_id)

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

func spawn_particles(pos: Vector2, color: Color) -> void:
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.amount = 10
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.finished.connect(particles.queue_free)
	add_child(particles)

func till_soil(grid_pos: Vector2i, current_atlas_coords: Vector2i) -> void:
	if Global.current_stamina < 2:
		spawn_floating_text(grid_pos, "体力不足！", Color.RED)
		print("Not enough stamina to till!")
		return
		
	Global.current_stamina -= 2
	GameEvents.stamina_changed.emit(Global.current_stamina)
	
	# Change to tilled version (y=1)
	var new_atlas_coords = Vector2i(current_atlas_coords.x, 1)
	tile_map.set_cell(grid_pos, 0, new_atlas_coords)
	spawn_floating_text(grid_pos, "已开垦", Color.WHITE)
	spawn_particles(tile_map.map_to_local(grid_pos), Color(0.6, 0.5, 0.3)) # Dirt color
	print("Tilled at ", grid_pos)

func plant_crop(grid_pos: Vector2i) -> void:
	if Global.current_stamina < 2:
		spawn_floating_text(grid_pos, "体力不足！", Color.RED)
		print("Not enough stamina to plant!")
		return

	# Check if valid ground
	var tile_data = tile_map.get_cell_tile_data(grid_pos)
	if tile_data:
		var crop_data = ItemManager.get_crop(current_seed_id)
		if not crop_data:
			return
			
		# Check constraints (Placeholder for water check)
		if crop_data.is_water_crop:
			# TODO: Check if tile is water
			pass

		Global.current_stamina -= 2
		GameEvents.stamina_changed.emit(Global.current_stamina)
		
		active_crops[grid_pos] = {
			"id": current_seed_id,
			"data": crop_data,
			"age": 0,
			"watered": false 
		}
		# Visual feedback: place seed
		var seed_coords = crop_data.stages_atlas_coords[0]
		crops_layer.set_cell(grid_pos, 0, seed_coords)
		spawn_floating_text(grid_pos, "已播种: " + crop_data.crop_name, Color.GREEN)
		spawn_particles(tile_map.map_to_local(grid_pos), Color(0.2, 0.8, 0.2)) # Green seed
		print("Planted ", crop_data.crop_name, " at ", grid_pos)

func harvest_crop(grid_pos: Vector2i) -> void:
	if Global.current_stamina < 3:
		spawn_floating_text(grid_pos, "体力不足！", Color.RED)
		print("Not enough stamina!")
		return

	var crop_info = active_crops[grid_pos]
	var crop_data = crop_info["data"]
	
	if crop_info["age"] >= crop_data.days_to_grow:
		Global.current_stamina -= 3
		GameEvents.stamina_changed.emit(Global.current_stamina)
		
		# Check ownership
		var tile_data = tile_map.get_cell_tile_data(grid_pos)
		var is_public = tile_data.get_custom_data("is_public_field")
		
		GameEvents.crop_harvested.emit(is_public)
		Global.add_item(is_public)
		
		# Add XP hook
		Global.player_stats.add_xp(PlayerStats.Art.MATH, 5)
		
		if is_public:
			spawn_floating_text(grid_pos, "上缴国库！", Color.GOLD)
			spawn_particles(tile_map.map_to_local(grid_pos), Color.GOLD)
		else:
			spawn_floating_text(grid_pos, "收获！", Color.GREEN)
			spawn_particles(tile_map.map_to_local(grid_pos), Color.GREEN)
		
		# Handle Special Properties
		if crop_data.restores_fertility:
			spawn_floating_text(grid_pos + Vector2i(0, -1), "肥力恢复", Color.GREEN)
			# Logic to restore fertility
		
		if crop_data.is_perennial:
			# Reset age to stage 1 (not 0, assuming stage 0 is seed, 1 is small plant)
			crop_info["age"] = 1
			crop_info["watered"] = false
			var atlas_coords = crop_data.stages_atlas_coords[1]
			crops_layer.set_cell(grid_pos, 0, atlas_coords)
			print("Harvested Perennial!")
		else:
			# Remove crop
			active_crops.erase(grid_pos)
			crops_layer.erase_cell(grid_pos)
			print("Harvested!")
	else:
		spawn_floating_text(grid_pos, "未成熟", Color.GRAY)
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
	
	var term = Global.get_current_solar_term()
	spawn_floating_text(Vector2i(5,5), "节气: " + term, Color.CYAN)
	
	match term:
		"春分":
			spawn_floating_text(Vector2i(5,6), "祭祀盛典: 声望获取加倍", Color.GOLD)
		"大暑":
			spawn_floating_text(Vector2i(5,6), "大旱: 作物需水量增加", Color.ORANGE)

	# Visitor Logic
	for v in active_visitors:
		if is_instance_valid(v):
			v.queue_free()
	active_visitors.clear()
	
	if randf() < 0.7:
		spawn_visitor()
	
	for pos in active_crops:
		var info = active_crops[pos]
		if info["watered"]:
			info["age"] += 1
			info["watered"] = false # Reset water status
			
			# Update visual
			var stage_idx = min(info["age"], info["data"].stages_atlas_coords.size() - 1)
			var atlas_coords = info["data"].stages_atlas_coords[stage_idx]
			crops_layer.set_cell(pos, 0, atlas_coords)

func spawn_visitor() -> void:
	var data = VisitorData.new()
	data.name = "访客 " + str(randi() % 100)
	data.school = randi() % 4
	
	# Random color based on school
	match data.school:
		VisitorData.School.CONFUCIAN: data.portrait_color = Color(0.4, 0.4, 1.0) # Blue
		VisitorData.School.MOHIST: data.portrait_color = Color(0.2, 0.2, 0.2) # Black/Grey
		VisitorData.School.TAOIST: data.portrait_color = Color(0.8, 0.8, 1.0) # White/Cyan
		VisitorData.School.MERCHANT: data.portrait_color = Color(1.0, 0.8, 0.2) # Gold
	
	var visitor = visitor_scene.instantiate()
	visitor.setup(data)
	# Spawn near left edge
	visitor.global_position = Vector2(50, 200) 
	add_child(visitor)
	active_visitors.append(visitor)
	print("Visitor spawned: ", data.name)
