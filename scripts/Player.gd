extends CharacterBody2D

class_name Player

const SPEED = 100.0

# Simple FSM
enum State { IDLE, RUN, TOOL_USE }
var current_state = State.IDLE

@onready var sprite = $Sprite2D
@onready var selection_sprite = $SelectionSprite

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
	# Grid snapping (assuming 16x16 tiles)
	var mouse_pos = get_global_mouse_position()
	var grid_pos = Vector2i(mouse_pos) / 16
	selection_sprite.global_position = Vector2(grid_pos * 16)

func interact() -> void:
	# This will be handled by the World script via signal or direct call
	# For now, we just emit a signal or call a global function
	# But in Godot 4, it's better to let the World handle the input mapping to tiles
	pass
