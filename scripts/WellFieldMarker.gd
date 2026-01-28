extends Node2D
class_name WellFieldMarker

# Visual marker for well-field boundaries
@onready var tile_map: TileMapLayer = get_parent()

var border_lines: Array[Line2D] = []

func _ready() -> void:
	if not tile_map:
		print("Error: WellFieldMarker must be child of TileMapLayer!")
		return

	# Create markers for all well fields
	refresh_markers()

	GameEvents.well_field_added.connect(_on_well_field_added)
	GameEvents.well_field_reclaimed.connect(_on_well_field_reclaimed)

func refresh_markers() -> void:
	# Clear existing markers
	for line in border_lines:
		if is_instance_valid(line):
			line.queue_free()
	border_lines.clear()

	# Create new markers
	for field_data in Global.well_fields:
		_create_field_marker(field_data)

func _create_field_marker(field_data: Dictionary) -> void:
	var center = field_data["center_pos"]
	var field_id = field_data["field_id"]

	# Create a 3x3 border around the well field
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = _get_field_color(field_id)
	line.z_index = 50  # Draw above tiles but below UI

	# Calculate the 4 corners of the 3x3 area
	var top_left = center + Vector2i(-1, -1)
	var top_right = center + Vector2i(1, -1)
	var bottom_left = center + Vector2i(-1, 1)
	var bottom_right = center + Vector2i(1, 1)

	# Convert to world positions
	var p1 = tile_map.map_to_local(top_left)
	var p2 = tile_map.map_to_local(top_right)
	var p3 = tile_map.map_to_local(bottom_right)
	var p4 = tile_map.map_to_local(bottom_left)

	# Add points to create a rectangle
	line.add_point(p1)
	line.add_point(p2)
	line.add_point(p3)
	line.add_point(p4)
	line.add_point(p1)  # Close the loop

	# Add to scene
	add_child(line)
	border_lines.append(line)

	# Add field ID label
	var label = Label.new()
	label.text = "#%d" % field_id
	label.position = tile_map.map_to_local(center)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 51
	add_child(label)
	border_lines.append(label)

	# Add public field marker (center tile)
	var public_marker = ColorRect.new()
	var center_pos = tile_map.map_to_local(center)
	var cell_size = tile_map.get_tileset().tile_size
	public_marker.position = center_pos - Vector2(cell_size.x * 0.5, cell_size.y * 0.5)
	public_marker.size = cell_size
	public_marker.color = Color(1, 0.8, 0, 0.3)  # Golden color for public field
	public_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	public_marker.z_index = 49
	add_child(public_marker)
	border_lines.append(public_marker)

func _get_field_color(field_id: int) -> Color:
	# Different colors for different well fields
	var colors = [
		Color(0, 1, 0, 0.8),    # Green
		Color(0, 0, 1, 0.8),    # Blue
		Color(1, 0, 1, 0.8),    # Magenta
		Color(1, 1, 0, 0.8),    # Yellow
		Color(0, 1, 1, 0.8),    # Cyan
		Color(1, 0.5, 0, 0.8),  # Orange
		Color(0.5, 0, 1, 0.8),  # Purple
		Color(1, 0, 0.5, 0.8),  # Pink
		Color(0.5, 1, 0, 0.8),  # Lime
	]
	if field_id < colors.size():
		return colors[field_id]
	return Color(1, 1, 1, 0.8)

func _on_well_field_added(field_id: int) -> void:
	if field_id < Global.well_fields.size():
		_create_field_marker(Global.well_fields[field_id])

func _on_well_field_reclaimed(field_id: int, progress: int) -> void:
	# Update visual to show reclamation progress
	print("Field %d reclamation progress: %d/4" % [field_id, progress])
	# TODO: Add progress indicator

func _exit_tree() -> void:
	for line in border_lines:
		if is_instance_valid(line):
			line.queue_free()
	border_lines.clear()
