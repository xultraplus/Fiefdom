extends Node2D

@onready var exit_area = $ExitArea

func _ready() -> void:
	exit_area.body_entered.connect(_on_exit_entered)

func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Returning to Fiefdom...")
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
