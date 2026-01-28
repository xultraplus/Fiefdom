extends Node

# Signal Bus for decoupled communication
signal crop_harvested(is_public: bool)
signal day_advanced(new_day: int)
signal stamina_changed(new_amount: int)
signal money_changed(amount: int)
signal reputation_changed(amount: int)

# Phase 2 Signals
signal retainer_assigned(data: RetainerData, grid_pos: Vector2i)
signal game_over()

# Phase 3 Signals
signal visitor_interacted(data: VisitorData)
signal retainer_recruited(data: RetainerData)

# Phase 4+ Signals: Well-Field & Tax Reform
signal rank_changed(new_rank: Global.Rank)
signal well_field_added(field_id: int)
signal well_field_reclaimed(field_id: int, progress: int)
signal tax_reform_triggered()  # 初税亩事件触发
signal tax_reform_choice_made(choice: Global.TaxReformChoice)
