extends Resource
class_name RetainerData

@export var name: String = "Unnamed"
@export var profession: String = "Farmer" # Peasant, Scholar, etc.
@export var portrait: Texture2D

# Attributes
@export_range(0, 100) var hunger: float = 0.0
@export_range(0, 100) var loyalty: float = 100.0
@export_range(0.1, 5.0) var efficiency: float = 1.0

func _init(p_name = "Unnamed", p_prof = "Farmer"):
	name = p_name
	profession = p_prof
