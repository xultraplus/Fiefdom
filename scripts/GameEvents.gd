extends Node

# Signal Bus for decoupled communication
signal crop_harvested(is_public: bool)
signal day_advanced(new_day: int)
signal stamina_changed(new_amount: int)
signal money_changed(amount: int)
signal reputation_changed(amount: int)
