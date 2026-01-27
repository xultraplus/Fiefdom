extends CharacterBody2D
class_name Retainer

enum State { IDLE, MOVE, WORK, REST }

@export var move_speed: float = 100.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

var current_state: State = State.IDLE
var target_node: Node2D = null
var target_position_cache: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set up navigation agent
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	
	# Initial home position (spawn point)
	home_position = global_position
	
	# Start looking for work
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.MOVE:
			_process_move(delta)
		State.WORK:
			_process_work()
		State.REST:
			_process_rest()

func set_state(new_state: State) -> void:
	current_state = new_state
	print("Retainer State: ", State.keys()[new_state])
	
	if new_state == State.IDLE:
		# Try to find work immediately
		find_work()
	elif new_state == State.REST:
		# Go home
		set_movement_target(home_position)

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target
	target_position_cache = movement_target
	current_state = State.MOVE

func _process_idle() -> void:
	# Periodically check for work? Or handled by event/signal?
	# For now, just wait. The find_work() is called on enter state.
	pass

func _process_move(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		if target_position_cache == home_position:
			set_state(State.IDLE) # Or stay RESTing?
		else:
			set_state(State.WORK)
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	var new_velocity: Vector2 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized() * move_speed
	
	# Avoidance (optional for now, can be added later)
	# if navigation_agent.avoidance_enabled:
	# 	navigation_agent.set_velocity(new_velocity)
	# else:
	velocity = new_velocity
	move_and_slide()
	
	# Flip sprite
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _process_work() -> void:
	# Simulate work duration
	# In a real game, play animation, then trigger effect
	# For prototype, we just finish immediately or wait a timer
	
	# Assuming we arrived at a crop tile
	# We need to notify the World/Crop that we watered it
	
	# Use a timer or just instant for now? 
	# Let's use a simple timer simulation
	await get_tree().create_timer(1.0).timeout
	
	# Perform action
	perform_task()
	
	# Return to idle
	set_state(State.IDLE)

func _process_rest() -> void:
	pass

func find_work() -> void:
	# Logic to find dry crops
	# We can access the World or use Groups
	var dry_crops = get_tree().get_nodes_in_group("dry_crops")
	if dry_crops.size() > 0:
		# Find the closest one
		var closest_crop = dry_crops[0]
		var min_dist = global_position.distance_squared_to(closest_crop.global_position)
		
		for crop in dry_crops:
			var dist = global_position.distance_squared_to(crop.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_crop = crop
		
		target_node = closest_crop
		set_movement_target(closest_crop.global_position)
	else:
		# No work, maybe wander or stay idle
		pass

func perform_task() -> void:
	if is_instance_valid(target_node):
		if target_node.has_method("water"):
			target_node.water()
		elif target_node.has_method("on_interact"): # Fallback
			target_node.on_interact()
