extends CharacterBody2D
class_name Retainer

enum State { IDLE, MOVE, WORK, REST }

@export var move_speed: float = 100.0
@export var data: RetainerData

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

var current_state: State = State.IDLE
var target_grid_pos: Vector2i = Vector2i(-1, -1)
var target_position_cache: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	if data == null:
		data = RetainerData.new()
		
	# Set up navigation agent
	# Relaxing distance constraints to avoid getting stuck near target
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	
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

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target
	target_position_cache = movement_target
	current_state = State.MOVE

func _process_idle() -> void:
	# Periodically check for work
	if Engine.get_physics_frames() % 60 == 0: # Check every 1 second approx
		find_work()

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
	
	velocity = new_velocity
	move_and_slide()
	
	# Flip sprite
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _process_work() -> void:
	# Simulate work duration (e.g. 1 second)
	# We can't use await in _process loop easily without state guards, 
	# but since we transition state, it is fine to await once then transition.
	# However, _process is called every frame.
	# Better to do the await in a separate function call from set_state or use a flag.
	pass

func _process_rest() -> void:
	pass

# Called when entering WORK state
func start_working():
	await get_tree().create_timer(1.0).timeout
	perform_task()
	set_state(State.IDLE)

func set_state_work():
	current_state = State.WORK
	start_working()

func set_state(new_state: State) -> void:
	var old_state = current_state
	current_state = new_state
	print("Retainer: State changed from ", State.keys()[old_state], " to ", State.keys()[new_state])
	
	if new_state == State.IDLE:
		find_work()
	elif new_state == State.REST:
		set_movement_target(home_position)
	elif new_state == State.WORK:
		start_working()

func find_work() -> void:
	# Logic to find dry crops via World
	var world = get_parent()
	if world.has_method("get_nearest_dry_crop"):
		var grid_pos = world.get_nearest_dry_crop(global_position)
		if grid_pos != Vector2i(-1, -1):
			print("Retainer: Found work at ", grid_pos)
			target_grid_pos = grid_pos
			# Convert grid to world pos
			var world_pos = world.tile_map.map_to_local(grid_pos)
			set_movement_target(world_pos)
		else:
			print("Retainer: No work found")
			pass

func perform_task() -> void:
	var world = get_parent()
	if world.has_method("water_crop"):
		world.water_crop(target_grid_pos)
