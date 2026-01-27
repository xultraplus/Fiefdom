extends CharacterBody2D

var data: VisitorData

@onready var sprite = $Sprite2D

func setup(p_data: VisitorData) -> void:
	data = p_data
	if sprite:
		sprite.modulate = data.portrait_color

func interact() -> void:
	if data:
		print("Interacting with ", data.name)
		GameEvents.visitor_interacted.emit(data)
