extends CharacterBody2D

class_name Player

const SPEED = 100.0

# Simple FSM
enum State { IDLE, RUN, TOOL_USE }
var current_state = State.IDLE

@onready var sprite = $Sprite2D
@onready var selection_sprite = $SelectionSprite
@onready var camera = $Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 5.0

var arrow_scene = preload("res://scenes/Arrow.tscn")

var tile_map_ref: TileMapLayer

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Get input direction
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var direction_y = Input.get_axis("ui_up", "ui_down")
	var direction = Vector2(direction_x, direction_y).normalized()
	
	if direction:
		velocity = direction * SPEED
		current_state = State.RUN
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE

	move_and_slide()
	
	# Camera Shake
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	
	# Visual feedback
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		
	update_selection_box()
	
	# Interaction
	if Input.is_action_just_pressed("ui_accept"): # Default Enter/Space
		interact()
	
	if Input.is_action_just_pressed("ui_cancel"): # Escape/Right Click? No, ui_cancel is usually Esc.
		pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		shoot_arrow(get_global_mouse_position())

func shoot_arrow(target_pos: Vector2) -> void:
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = (target_pos - global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	get_parent().add_child(arrow)
	print("Fired arrow!")

func update_selection_box() -> void:
	if tile_map_ref:
		# Use TileMap logic for accurate coordinate conversion (handles negative coords and offsets)
		var mouse_pos = get_global_mouse_position()
		# Convert mouse global pos to local pos relative to TileMap
		var local_mouse_pos = tile_map_ref.to_local(mouse_pos)
		var grid_pos = tile_map_ref.local_to_map(local_mouse_pos)
		
		# map_to_local returns the CENTER of the tile in Godot 4
		var tile_center_pos = tile_map_ref.map_to_local(grid_pos)
		# Convert back to global
		selection_sprite.global_position = tile_map_ref.to_global(tile_center_pos)
		
		var tile_data = tile_map_ref.get_cell_tile_data(grid_pos)
		if tile_data:
			var is_public = tile_data.get_custom_data("is_public_field")
			if is_public:
				selection_sprite.modulate = Color.GOLD
			else:
				selection_sprite.modulate = Color.GREEN
		else:
			selection_sprite.modulate = Color.WHITE
	else:
		# Fallback: Grid snapping (assuming 16x16 tiles)
		var mouse_pos = get_global_mouse_position()
		# Use floor() for correct negative coordinate handling
		var grid_pos = Vector2i(floor(mouse_pos.x / 16.0), floor(mouse_pos.y / 16.0))
		# Add (8,8) offset because Sprite is centered
		selection_sprite.global_position = Vector2(grid_pos * 16) + Vector2(8, 8)

func apply_shake(strength: float = 5.0) -> void:
	shake_strength = strength

func interact() -> void:
	# Check for nearby interactables (Visitors)
	var interactables = get_tree().get_nodes_in_group("interactable")
	var nearest_node = null
	var min_dist = 60.0 # Pixel distance

	for node in interactables:
		var dist = global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_node = node
	
	if nearest_node and nearest_node.has_method("interact"):
		nearest_node.interact()
		return
		
	# Fallback: Tile interaction if needed (currently handled by World mouse input)
	pass
