extends CharacterBody2D

enum Type { WILD_DOG, SCOUT }
enum State { IDLE, PATROL, CHASE, ATTACK, EAT }

@export var type: Type = Type.WILD_DOG
var state: State = State.IDLE

var health = 20
var speed = 40
var player_ref: Node2D = null
var target_crop_pos: Vector2i = Vector2i(-1, -1)
var world_ref: Node2D = null # Reference to World for accessing crops
var attack_cooldown: float = 0.0
var attack_range: float = 30.0
var original_color: Color = Color.WHITE

@onready var sprite = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D # Assuming added
# If no NavAgent, we use simple movement for now

var arrow_scene = preload("res://scenes/Arrow.tscn")

func _ready() -> void:
	add_to_group("enemies")
	_setup_stats()
	world_ref = get_parent() # Assuming spawned as child of World
	
	# Initial state
	state = State.PATROL

func _setup_stats() -> void:
	match type:
		Type.WILD_DOG:
			health = 10
			speed = 80
			attack_range = 30.0
			original_color = Color(0.6, 0.4, 0.2) # Brown
		Type.SCOUT:
			health = 30
			speed = 50
			attack_range = 150.0
			original_color = Color(0.8, 0.2, 0.2) # Red
	
	sprite.modulate = original_color

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if randf() < 0.01:
				state = State.PATROL
		
		State.PATROL:
			# Simple random movement or patrol logic
			if velocity == Vector2.ZERO:
				var random_dir = Vector2(randf()-0.5, randf()-0.5).normalized()
				velocity = random_dir * (speed * 0.5)
			
			if randf() < 0.01:
				state = State.IDLE
				
			# Check for crops (Wild Dog)
			if type == Type.WILD_DOG and randf() < 0.05:
				_find_crop()
				
		State.CHASE:
			if player_ref:
				var dir = (player_ref.global_position - global_position).normalized()
				velocity = dir * speed
				
				var dist = global_position.distance_to(player_ref.global_position)
				if dist <= attack_range:
					state = State.ATTACK
			else:
				state = State.PATROL
				
		State.EAT:
			if target_crop_pos != Vector2i(-1, -1):
				# Move towards crop
				if world_ref and world_ref.has_method("get_crop_world_pos"):
					var target_pos = world_ref.get_crop_world_pos(target_crop_pos)
					var dir = (target_pos - global_position).normalized()
					velocity = dir * speed
					
					if global_position.distance_to(target_pos) < 10:
						world_ref.destroy_crop(target_crop_pos)
						target_crop_pos = Vector2i(-1, -1)
						state = State.PATROL
			else:
				state = State.PATROL
				
		State.ATTACK:
			velocity = Vector2.ZERO
			if player_ref:
				var dist = global_position.distance_to(player_ref.global_position)
				if dist > attack_range * 1.2:
					state = State.CHASE
				else:
					_perform_attack()
			else:
				state = State.PATROL

	move_and_slide()
	
	# Flip sprite
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _find_crop() -> void:
	if world_ref and world_ref.has_method("get_random_crop_pos"):
		target_crop_pos = world_ref.get_random_crop_pos()
		if target_crop_pos != Vector2i(-1, -1):
			state = State.EAT
			# In a real implementation, we would pathfind to the crop

func _perform_attack() -> void:
	if attack_cooldown <= 0:
		attack_cooldown = 2.0
		if type == Type.SCOUT:
			# Shoot arrow
			var arrow = arrow_scene.instantiate()
			arrow.global_position = global_position
			var dir = (player_ref.global_position - global_position).normalized()
			arrow.direction = dir
			arrow.rotation = dir.angle()
			get_parent().add_child(arrow)
			print("Scout shoots arrow!")
		else:
			# Melee
			if player_ref.has_method("take_damage"):
				# player_ref.take_damage(5) # Player doesn't have take_damage yet
				print("Wild Dog bites!")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		state = State.CHASE
		# Call for help?

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		# Don't immediately lose target, maybe keep chasing for a bit
		# For now, lose target
		player_ref = null
		state = State.PATROL

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy hit! Health: ", health)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", original_color, 0.1)
	# Should reset to type color
	
	if health <= 0:
		die()

func die() -> void:
	print("Enemy died!")
	# Grant XP
	Global.player_stats.add_xp(PlayerStats.Art.ARCHERY, 20)
	Global.money += 2 
	queue_free()
