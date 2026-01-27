extends Node

# Global state manager
var current_day: int = 1
var player_inventory: int = 0 # Simple counter for Phase 1
var king_storage: int = 0
var money: int = 0
var reputation: int = 0

func _ready() -> void:
	pass

func add_item(is_public: bool) -> void:
	if is_public:
		king_storage += 1
		reputation += 10
		print("Added to King's Treasury. Reputation: ", reputation)
	else:
		player_inventory += 1
		money += 5
		print("Added to Player Inventory. Money: ", money)
