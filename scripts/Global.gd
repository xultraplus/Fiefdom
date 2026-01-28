extends Node

# Global state manager
var current_day: int = 1
var player_inventory: int = 0 # Simple counter for Phase 1
var king_storage: int = 0
var money: int = 0
var reputation: int = 0
var max_stamina: int = 100
var current_stamina: int = 100

# Phase 2: Economy & Retainers
var food_storage: int = 10 # Initial food
var retainers: Array[RetainerData] = []
var days_without_contribution: int = 0

# Phase 3: RPG Stats
var player_stats: PlayerStats

var active_crops: Dictionary = {}

# Phase 3: Rank & Tech
enum Rank {
	XIA_SHI,        # 下士（初始爵位）
	ZHONG_SHI,      # 中士
	SHANG_SHI,      # 上士
	DA_FU,          # 大夫
	QING            # 卿
}
var current_rank: Rank = Rank.XIA_SHI
var rank_names: Dictionary = {
	Rank.XIA_SHI: "下士",
	Rank.ZHONG_SHI: "中士",
	Rank.SHANG_SHI: "上士",
	Rank.DA_FU: "大夫",
	Rank.QING: "卿"
}

var tech_unlocked: Dictionary = {
	"irrigation": false,
	"composite_bow": false
}

# Well-Field System (井田制扩展)
var well_fields: Array[Dictionary] = []  # 存储所有井田数据
var max_well_fields: int = 1  # 当前爵位允许的最大井田数量

# Tax Reform System (初税亩改革)
enum TaxReformChoice {
	NONE,           # 未选择（游戏初期）
	DELAYED,        # 拖延观望
	REFORMED,       # 支持改革（法家路线）
	TRADITIONAL     # 坚守传统（儒家路线）
}
var tax_reform_choice: TaxReformChoice = TaxReformChoice.NONE
var tax_reform_year: int = 0  # 改革发生的年份
var tax_rate: float = 0.0  # 改革后的税率（0.0-1.0，默认0表示未改革）
var zhou_li_score: String = "中"  # 周礼评分（上上/上中/中上/中/中下/下中/下下）

const SOLAR_TERMS = [
	"立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
	"立夏", "小满", "芒种", "夏至", "小暑", "大暑",
	"立秋", "处暑", "白露", "秋分", "寒露", "霜降",
	"立冬", "小雪", "大雪", "冬至", "小寒", "大寒"
]

# Quest System
var current_quest: String = "任务: 向国库上缴 10 份黍 (0/10)"
var quest_target: int = 10
var quest_progress: int = 0
var quest_completed: bool = false

func _ready() -> void:
	# Initialize Player Stats
	player_stats = PlayerStats.new()
	
	# Add a default retainer for testing
	retainers.append(RetainerData.new("墨家弟子", "农夫"))

func get_current_solar_term() -> String:
	var idx = (current_day - 1) % 24
	return SOLAR_TERMS[idx]

func restore_stamina() -> void:
	current_stamina = max_stamina
	print("Stamina Restored")

	# Daily consumption
	consume_food()

	# Apply CONFUCIAN loyalty aura (儒家忠诚光环)
	_apply_confucian_loyalty_aura()

	# Check contribution
	days_without_contribution += 1
	if days_without_contribution >= 3:
		reputation -= 20
		print("Warning: Reputation decreased due to lack of contribution! Current: ", reputation)
		GameEvents.reputation_changed.emit(reputation)

# Apply儒家忠诚光环（每天提升其他门客忠诚度）
func _apply_confucian_loyalty_aura() -> void:
	var confucian_count = 0
	for retainer in retainers:
		if retainer.school == RetainerData.School.CONFUCIAN:
			confucian_count += 1

	if confucian_count > 0:
		var loyalty_boost = confucian_count * 0.3  # 每个儒家门客提升30%
		print("儒家忠诚光环：提升 %d%% 忠诚度" % (loyalty_boost * 100))
		for retainer in retainers:
			if retainer.school != RetainerData.School.CONFUCIAN:
				retainer.loyalty = min(100, retainer.loyalty + loyalty_boost * 10)

func consume_food() -> void:
	var consumption = retainers.size() * 1
	if food_storage >= consumption:
		food_storage -= consumption
		print("Food consumed: ", consumption, ". Remaining: ", food_storage)
	else:
		food_storage = 0
		print("Not enough food! Retainers are starving.")
		# Handle loyalty drop or leave logic here
		for r in retainers:
			r.loyalty -= 20
			if r.loyalty <= 0:
				print("Retainer ", r.name, " has left!")
				# In a real game, remove from array safely. For prototype, just print.

func add_item(is_public: bool) -> void:
	# If tax reform is active, all fields are taxed at a fixed rate
	if tax_reform_choice == TaxReformChoice.REFORMED:
		player_inventory += 1
		var tax_amount = 1 * tax_rate
		money += 5 * (1.0 - tax_rate)  # Player gets (100% - tax_rate)
		print("Added to Player Inventory. After tax (%.0f%%): Money: %.2f" % [tax_rate * 100, money])
		return

	# Calculate yield bonus from AGRARIAN school retainers
	var yield_bonus = 1.0
	for retainer in retainers:
		if retainer.school == RetainerData.School.AGRARIAN:
			yield_bonus += 0.5  # Each agrarian retainer adds 50% bonus
	print("Yield bonus: %.0f%%" % [(yield_bonus - 1.0) * 100])

	# Traditional well-field system
	if is_public:
		# Apply LEGALIST tax bonus for public fields
		var tax_multiplier = 1.0
		if tax_reform_choice == TaxReformChoice.TRADITIONAL:
			for retainer in retainers:
				if retainer.school == RetainerData.School.LEGALIST:
					tax_multiplier += 0.2  # Legalist adds 20% reputation bonus

		var amount = 1
		king_storage += amount
		var reputation_gain = ceil(10 * tax_multiplier)
		reputation += reputation_gain
		days_without_contribution = 0 # Reset fail counter
		print("Added to King's Treasury. Reputation: ", reputation, " (bonus: +%d)" % (reputation_gain - 10))

		# Quest Logic
		if not quest_completed:
			quest_progress += 1
			current_quest = "任务: 向国库上缴 10 份黍 (" + str(quest_progress) + "/" + str(quest_target) + ")"
			if quest_progress >= quest_target:
				quest_completed = true
				current_quest = "任务完成！获得 50 声望"
				reputation += 50
				print("Quest Completed!")
				GameEvents.reputation_changed.emit(reputation)
	else:
		# Apply AGRARIAN yield bonus
		var amount = ceil(1 * yield_bonus)
		player_inventory += amount
		money += 5 * amount
		print("Added to Player Inventory. Amount: %d (bonus: %.0f%%), Money: %d" % [amount, (yield_bonus - 1.0) * 100, money])
		
func convert_inventory_to_food(amount: int) -> void:
	if player_inventory >= amount:
		player_inventory -= amount
		food_storage += amount # 1 crop = 1 food unit
		print("Converted ", amount, " crops to food.")

func check_rank_up() -> bool:
	var promoted = false
	var old_rank = current_rank

	match current_rank:
		Rank.XIA_SHI:
			if reputation >= 100 and zhou_li_score in ["上上", "上中", "中上", "中"]:
				current_rank = Rank.ZHONG_SHI
				promoted = true
		Rank.ZHONG_SHI:
			if reputation >= 500 and _has_any_six_art_level(5):
				current_rank = Rank.SHANG_SHI
				promoted = true
		Rank.SHANG_SHI:
			if reputation >= 2000 and tax_reform_choice != TaxReformChoice.NONE:
				current_rank = Rank.DA_FU
				promoted = true
		Rank.DA_FU:
			if reputation >= 10000 and _all_six_arts_level(10):
				current_rank = Rank.QING
				promoted = true

	if promoted:
		_update_max_well_fields()
		print("Promoted to ", rank_names[current_rank], "!")
		GameEvents.rank_changed.emit(current_rank)

	return promoted

# Helper: Check if any six art stat reaches level
func _has_any_six_art_level(required_level: int) -> bool:
	for art in PlayerStats.Art.values():
		if player_stats.get_level(art) >= required_level:
			return true
	return false

# Helper: Check if all six arts reach level
func _all_six_arts_level(required_level: int) -> bool:
	for art in PlayerStats.Art.values():
		if player_stats.get_level(art) < required_level:
			return false
	return true

# Update max well fields based on rank
func _update_max_well_fields() -> void:
	match current_rank:
		Rank.XIA_SHI: max_well_fields = 1
		Rank.ZHONG_SHI: max_well_fields = 2
		Rank.SHANG_SHI: max_well_fields = 4
		Rank.DA_FU: max_well_fields = 9
		Rank.QING: max_well_fields = 16
		_: max_well_fields = 1

# Well-Field Management Functions
func add_well_field(center_pos: Vector2i) -> bool:
	if well_fields.size() >= max_well_fields:
		print("Cannot add more well fields. Max: ", max_well_fields)
		return false

	# Check if this position overlaps with existing fields
	for field in well_fields:
		var existing_center = field["center_pos"]
		if existing_center.distance_to(center_pos) < 4:  # 3x3 fields need at least 1 gap
			print("Too close to existing field!")
			return false

	var new_field = {
		"field_id": well_fields.size(),
		"center_pos": center_pos,
		"is_unlocked": false,
		"reclamation_progress": 0,  # 0-4, where 4 = fully reclaimed
		"assigned_retainers": []
	}
	well_fields.append(new_field)
	return true

func advance_reclamation(field_id: int) -> bool:
	if field_id < 0 or field_id >= well_fields.size():
		return false

	var field = well_fields[field_id]
	if field["reclamation_progress"] < 4:
		field["reclamation_progress"] += 1
		if field["reclamation_progress"] >= 4:
			field["is_unlocked"] = true
			print("Well field ", field_id, " is now ready for planting!")
		return true
	return false

func get_well_field(field_id: int) -> Dictionary:
	if field_id >= 0 and field_id < well_fields.size():
		return well_fields[field_id]
	return {}

func save_game() -> void:
	var save_dict = {
		"current_day": current_day,
		"money": money,
		"player_inventory": player_inventory,
		"food_storage": food_storage,
		"reputation": reputation,
		"active_crops": {},
		"current_rank": current_rank,
		"well_fields": well_fields,
		"tax_reform_choice": tax_reform_choice,
		"tax_reform_year": tax_reform_year,
		"tax_rate": tax_rate,
		"zhou_li_score": zhou_li_score
	}
	
	for pos in active_crops:
		var info = active_crops[pos]
		# Convert Vector2i key to String for JSON
		var key = str(pos.x) + "," + str(pos.y)
		save_dict["active_crops"][key] = {
			"id": info.get("id", "millet"), # Fallback
			"age": info["age"],
			"watered": info["watered"]
		}
	
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_dict))
	print("Game Saved")

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		current_day = data.get("current_day", 1)
		money = data.get("money", 0)
		player_inventory = data.get("player_inventory", 0)
		food_storage = data.get("food_storage", 10)
		reputation = data.get("reputation", 0)
		current_rank = data.get("current_rank", Rank.XIA_SHI)
		well_fields = data.get("well_fields", [])
		tax_reform_choice = data.get("tax_reform_choice", TaxReformChoice.NONE)
		tax_reform_year = data.get("tax_reform_year", 0)
		tax_rate = data.get("tax_rate", 0.0)
		zhou_li_score = data.get("zhou_li_score", "中")

		active_crops.clear()
		var crops_data = data.get("active_crops", {})
		for key in crops_data:
			var split = key.split(",")
			var pos = Vector2i(int(split[0]), int(split[1]))
			var info = crops_data[key]
			var id = info.get("id", "millet")
			var crop_data = ItemManager.get_crop(id)

			if crop_data:
				active_crops[pos] = {
					"id": id,
					"data": crop_data,
					"age": info["age"],
					"watered": info["watered"]
				}

		_update_max_well_fields()
		get_tree().reload_current_scene()
		print("Game Loaded")
