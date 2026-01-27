extends Area2D

var speed = 400
var direction = Vector2.RIGHT
var damage = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Auto destroy after 2 seconds if no collision
	get_tree().create_timer(2.0).timeout.connect(queue_free)
	
	# Tech Effect
	if Global.tech_unlocked.get("composite_bow", false):
		damage = 25
		speed = 600
		$ColorRect.color = Color(1, 0.5, 0, 1) # Orange arrow

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body is TileMapLayer:
		queue_free()
