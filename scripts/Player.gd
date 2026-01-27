extends CharacterBody2D

class_name Player

const SPEED = 100.0

# Simple FSM
enum State { IDLE, RUN, TOOL_USE }
var current_state = State.IDLE

@onready var sprite = $Sprite2D
@onready var selection_sprite = $SelectionSprite

var tile_map_ref: TileMapLayer

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
	
	# Visual feedback
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		
	update_selection_box()
	
	# Interaction
	if Input.is_action_just_pressed("ui_accept"): # Default Enter/Space
		interact()

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

func interact() -> void:
	# This will be handled by the World script via signal or direct call
	# For now, we just emit a signal or call a global function
	# But in Godot 4, it's better to let the World handle the input mapping to tiles
	pass
