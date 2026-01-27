extends ColorRect

var grid_pos: Vector2i
signal retainer_dropped(grid_pos: Vector2i, data: RetainerData)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is RetainerData

func _drop_data(at_position: Vector2, data: Variant) -> void:
	print("Dropped ", data.name, " on grid ", grid_pos)
	retainer_dropped.emit(grid_pos, data)
	# Visual feedback
	color = Color.GOLD # Flash or change color
