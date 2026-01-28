extends Node

# Event Manager for handling historical events (初税亩, etc.)
var event_panel_scene = preload("res://scenes/EventPanel.tscn")

func _ready() -> void:
	# Connect to day advancement to check for events
	GameEvents.day_advanced.connect(_on_day_advanced)

func _on_day_advanced(new_day: int) -> void:
	_check_tax_reform_event()

# Check if tax reform event should trigger
func _check_tax_reform_event() -> void:
	# Only trigger once
	if Global.tax_reform_choice != Global.TaxReformChoice.NONE:
		return

	# Condition 1: Year 3 (approximately day 3*24 = 72, assuming 24 solar terms per year)
	var game_year = ceil(Global.current_day / 24.0)
	if game_year < 3:
		return

	# Condition 2: Rank is at least Da_Fu
	if Global.current_rank < Global.Rank.DA_FU:
		return

	# Condition 3: Public field contribution is sufficient (king_storage check)
	var total_public_harvest = Global.king_storage
	var total_private_harvest = Global.player_inventory
	if total_public_harvest == 0:
		return

	# Check if public contribution is at least 30% of total
	var public_ratio = float(total_public_harvest) / float(total_public_harvest + total_private_harvest)
	if public_ratio < 0.3:
		return

	# All conditions met, trigger the event!
	trigger_tax_reform_event()

func trigger_tax_reform_event() -> void:
	print("Tax Reform Event Triggered!")
	GameEvents.tax_reform_triggered.emit()

	# Show event dialog
	var event_panel = event_panel_scene.instantiate()
	get_tree().current_scene.add_child(event_panel)

	var event_data = _get_tax_reform_event_data()
	event_panel.setup(event_data)

	# Connect to choice made signal
	event_panel.choice_selected.connect(_on_tax_reform_choice)

func _get_tax_reform_event_data() -> Dictionary:
	return {
		"title": "国君密诏",
		"speaker": "国君使者",
		"text": "
		卿拜手：国君有密诏。

		周边诸侯（齐、晋）已行'初税亩'之制，
		废井田，按亩收税，府库充盈。

		寡人有意效仿，卿以为如何？

		此乃国之大事，望卿慎思。
		",
		"choices": [
			{
				"text": "支持改革（法家路线）",
				"description": "
				所有公田变为私田，不再强制上缴。
				改为20%固定税率。

				收益：金钱收入暴增300%
				代价：周礼评分降至下下，儒门客离去
				",
				"choice_type": Global.TaxReformChoice.REFORMED
			},
			{
				"text": "坚守传统（儒家路线）",
				"description": "
				保持井田制不变。

				收益：周礼评分保持上上，国君赏赐稀有礼物
				代价：失去改革的金钱暴增
				",
				"choice_type": Global.TaxReformChoice.TRADITIONAL
			},
			{
				"text": "拖延观望（暂缓决定）",
				"description": "
				表面支持，实际推迟实施。
				每月需缴纳100铜钱研究经费。

				1年后国君将失去耐心，强制要求站队。
				",
				"choice_type": Global.TaxReformChoice.DELAYED
			}
		]
	}

func _on_tax_reform_choice(choice: Global.TaxReformChoice) -> void:
	print("Tax reform choice made: ", choice)
	Global.tax_reform_choice = choice
	Global.tax_reform_year = ceil(Global.current_day / 24.0)
	GameEvents.tax_reform_choice_made.emit(choice)

	# Apply consequences based on choice
	match choice:
		Global.TaxReformChoice.REFORMED:
			_apply_reform_consequences()
		Global.TaxReformChoice.TRADITIONAL:
			_apply_traditional_consequences()
		Global.TaxReformChoice.DELAYED:
			_apply_delayed_consequences()

func _apply_reform_consequences() -> void:
	print("Applying reform consequences...")
	Global.tax_rate = 0.2  # 20% tax rate
	Global.zhou_li_score = "下下"

	#儒家门客忠诚度下降
	for retainer in Global.retainers:
		if retainer.school == RetainerData.School.CONFUCIAN:
			retainer.loyalty -= 50
			if retainer.loyalty <= 0:
				print("儒家门客 ", retainer.name, " 因不满改革而离去！")
				# TODO: Remove from array

	# TODO: Visual update - change all public field tiles to private
	print("所有公田已改为私田！税率20%")

func _apply_traditional_consequences() -> void:
	print("Applying traditional consequences...")
	Global.zhou_li_score = "上上"

	#儒家门客忠诚度上升
	for retainer in Global.retainers:
		if retainer.school in [RetainerData.School.CONFUCIAN, RetainerData.School.MOHIST]:
			retainer.loyalty += 30

	#法家门客无法招募（设置标志）
	# TODO: Add 'can_recruit_legalist' flag to Global
	print("坚守井田制！周礼评分：上上")

func _apply_delayed_consequences() -> void:
	print("Delaying decision...")
	print("每月需缴纳100铜钱研究经费，1年后必须站队")
	# TODO: Add monthly cost check in World.gd or Global.gd

# Check for conditional events (e.g., Confucius visit only for traditional route)
func check_conditional_events() -> void:
	if Global.tax_reform_choice == Global.TaxReformChoice.TRADITIONAL:
		# Trigger special events for traditional route
		pass
	elif Global.tax_reform_choice == Global.TaxReformChoice.REFORMED:
		# Trigger special events for reform route
		pass
