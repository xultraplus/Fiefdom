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

func _ready() -> void:
	# Add a default retainer for testing
	retainers.append(RetainerData.new("墨家弟子", "农夫"))

func restore_stamina() -> void:
	current_stamina = max_stamina
	print("Stamina Restored")
	
	# Daily consumption
	consume_food()
	
	# Check contribution
	days_without_contribution += 1
	if days_without_contribution >= 3:
		trigger_game_over()

func trigger_game_over() -> void:
	print("GAME OVER: Retainer revolt or King's wrath!")
	GameEvents.game_over.emit()

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
	else:
		player_inventory += 1 # This is "Raw Crop"
		money += 5
		print("Added to Player Inventory. Money: ", money)
		
func convert_inventory_to_food(amount: int) -> void:
	if player_inventory >= amount:
		player_inventory -= amount
		food_storage += amount # 1 crop = 1 food unit
		print("Converted ", amount, " crops to food.")
