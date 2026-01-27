extends Control

var data: RetainerData

@onready var name_label: Label = $NameLabel
@onready var job_label: Label = $JobLabel
@onready var icon: TextureRect = $Icon

func setup(p_data: RetainerData) -> void:
	data = p_data
	name_label.text = data.name
	job_label.text = data.profession
	# icon.texture = data.portrait # Todo

func _get_drag_data(at_position: Vector2) -> Variant:
	print("Dragging retainer: ", data.name)
	
	# Create preview
	var preview = Label.new()
	preview.text = data.name
	set_drag_preview(preview)
	
	return data
