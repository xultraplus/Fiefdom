extends Resource
class_name RetainerData

@export var name: String = "无名氏"
@export var profession: String = "农夫" # Peasant, Scholar, etc.
@export var portrait: Texture2D

# Attributes
@export_range(0, 100) var hunger: float = 0.0
@export_range(0, 100) var loyalty: float = 100.0
@export_range(0.1, 5.0) var efficiency: float = 1.0

func _init(p_name = "无名氏", p_prof = "农夫"):
	name = p_name
	profession = p_prof
