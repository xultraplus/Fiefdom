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
enum Rank { LOWER_SCHOLAR, MIDDLE_SCHOLAR, UPPER_SCHOLAR }
var current_rank: Rank = Rank.LOWER_SCHOLAR

var tech_unlocked: Dictionary = {
	"irrigation": false,
	"composite_bow": false
}

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
	
	# Check contribution
	days_without_contribution += 1
	if days_without_contribution >= 3:
		reputation -= 20
		print("Warning: Reputation decreased due to lack of contribution! Current: ", reputation)
		GameEvents.reputation_changed.emit(reputation)

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
	if is_public:
		king_storage += 1
		reputation += 10
		days_without_contribution = 0 # Reset fail counter
		print("Added to King's Treasury. Reputation: ", reputation)
		
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
		player_inventory += 1 # This is "Raw Crop"
		money += 5
		print("Added to Player Inventory. Money: ", money)
		
func convert_inventory_to_food(amount: int) -> void:
	if player_inventory >= amount:
		player_inventory -= amount
		food_storage += amount # 1 crop = 1 food unit
		print("Converted ", amount, " crops to food.")

func check_rank_up() -> bool:
	if current_rank == Rank.LOWER_SCHOLAR:
		if reputation >= 100 and king_storage >= 50:
			current_rank = Rank.MIDDLE_SCHOLAR
			print("Promoted to Middle Scholar!")
			return true
	return false

func save_game() -> void:
	var save_dict = {
		"current_day": current_day,
		"money": money,
		"player_inventory": player_inventory,
		"food_storage": food_storage,
		"reputation": reputation,
		"active_crops": {}
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
		
		get_tree().reload_current_scene()
		print("Game Loaded")
