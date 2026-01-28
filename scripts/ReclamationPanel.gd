extends Control

signal well_field_requested(center_pos: Vector2i)

@onready var title_label = $Panel/TitleLabel
@onready var rank_label = $Panel/RankLabel
@onready var fields_label = $Panel/FieldsLabel
@onready var cost_label = $Panel/CostLabel
@onready var reclaim_button = $Panel/ReclaimButton
@onready var close_button = $Panel/CloseButton
@onready var info_label = $Panel/InfoLabel
@onready var validity_label = $Panel/ValidityLabel

var tile_map: TileMapLayer
var mouse_pos: Vector2
var highlight_rect: ColorRect
var current_grid_pos: Vector2i
var is_position_valid: bool = false

func setup(tile_map_ref: TileMapLayer) -> void:
	tile_map = tile_map_ref
	_create_highlight_rect()
	_update_ui()
	set_process(true)

func _create_highlight_rect() -> void:
	# Create a semi-transparent highlight rectangle for the 3x3 area
	highlight_rect = ColorRect.new()
	highlight_rect.color = Color(0, 1, 0, 0.3)  # Green with transparency
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.z_index = 100  # Draw on top
	get_tree().current_scene.add_child(highlight_rect)
	highlight_rect.visible = false

func _process(_delta: float) -> void:
	if not visible or not tile_map:
		highlight_rect.visible = false
		return

	# Get current mouse position in grid coordinates
	mouse_pos = get_global_mouse_position()
	current_grid_pos = tile_map.local_to_map(mouse_pos)

	# Validate position
	is_position_valid = _validate_position(current_grid_pos)

	# Update highlight
	_update_highlight()

	# Update info labels
	info_label.text = "鼠标位置: (%d, %d)" % [current_grid_pos.x, current_grid_pos.y]
	if is_position_valid:
		validity_label.text = "✓ 此处可以开垦"
		validity_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		validity_label.text = "✗ 此处不适合开垦（需要3x3空地）"
		validity_label.add_theme_color_override("font_color", Color(1, 0, 0))

func _update_highlight() -> void:
	if not highlight_rect:
		return

	# Calculate world position of the 3x3 area
	var top_left = current_grid_pos + Vector2i(-1, -1)
	var world_pos = tile_map.map_to_local(top_left)
	var cell_size = tile_map.get_tileset().tile_size

	# Position and size the highlight rectangle
	highlight_rect.position = world_pos - Vector2(cell_size.x * 0.5, cell_size.y * 0.5)
	highlight_rect.size = cell_size * 3  # 3x3 area
	highlight_rect.visible = true

	# Change color based on validity
	if is_position_valid:
		highlight_rect.color = Color(0, 1, 0, 0.3)  # Green
	else:
		highlight_rect.color = Color(1, 0, 0, 0.3)  # Red

func _exit_tree() -> void:
	if highlight_rect and is_instance_valid(highlight_rect):
		highlight_rect.queue_free()

func _update_ui() -> void:
	var current_rank = Global.current_rank
	var max_fields = Global.max_well_fields
	var current_fields = Global.well_fields.size()

	title_label.text = "开垦新井田"
	rank_label.text = "当前爵位: %s" % Global.rank_names.get(current_rank, "未知")
	fields_label.text = "井田数量: %d / %d" % [current_fields, max_fields]

	# Calculate reclamation cost
	var cost_money = 100 * (current_rank + 1)
	var cost_food = 50 * (current_rank + 1)
	var cost_retainers = 3

	cost_label.text = "开垦消耗:\n铜钱: %d\n粮食: %d\n门客工时: %d天" % [cost_money, cost_food, cost_retainers]

	# Enable/disable reclaim button
	if current_fields >= max_fields:
		reclaim_button.disabled = true
		reclaim_button.text = "已达到爵位上限"
		info_label.text = "提升爵位以解锁更多井田"
	else:
		reclaim_button.disabled = false
		reclaim_button.text = "开垦新井田"

func _on_reclaim_button_pressed() -> void:
	if not tile_map:
		print("Error: No tile map reference!")
		return

	# Use current grid position (from _process)
	var grid_pos = current_grid_pos

	# Calculate cost
	var cost_money = 100 * (Global.current_rank + 1)
	var cost_food = 50 * (Global.current_rank + 1)

	# Check if player has enough resources
	if Global.money < cost_money:
		info_label.text = "铜钱不足！需要 %d" % cost_money
		return

	if Global.food_storage < cost_food:
		info_label.text = "粮食不足！需要 %d" % cost_food
		return

	if Global.retainers.size() < 3:
		info_label.text = "门客不足！需要 3 人"
		return

	# Check if position is valid
	if not _validate_position(grid_pos):
		info_label.text = "此处不适合开垦（需要3x3空地）"
		return

	# Deduct resources
	Global.money -= cost_money
	Global.food_storage -= cost_food

	# Add new well field
	if Global.add_well_field(grid_pos):
		info_label.text = "开垦成功！井田 ID: %d，位置(%d, %d)" % [Global.well_fields.size(), grid_pos.x, grid_pos.y]
		GameEvents.well_field_added.emit(Global.well_fields.size() - 1)
		_update_ui()
	else:
		info_label.text = "开垦失败：无法添加更多井田"

func _validate_position(center_pos: Vector2i) -> bool:
	# Check if 3x3 area is clear
	for x in range(-1, 2):
		for y in range(-1, 2):
			var coords = center_pos + Vector2i(x, y)
			# Check if tile exists at this position
			var tile_data = tile_map.get_cell_tile_data(coords)
			if tile_data == null:
				return false
			# TODO: Add terrain type checking (plains only)
	return true

func _on_close_button_pressed() -> void:
	queue_free()
