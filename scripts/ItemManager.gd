extends Node

var crops: Dictionary = {}

func _ready() -> void:
	_init_crops()

func _init_crops() -> void:
	# Millet (黍)
	var millet = CropData.new()
	millet.crop_name = "黍"
	millet.days_to_grow = 2
	millet.sell_price = 5
	var millet_stages: Array[Vector2i] = [Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)]
	millet.stages_atlas_coords = millet_stages
	crops["millet"] = millet

	# Sorghum (稷)
	var sorghum = CropData.new()
	sorghum.crop_name = "稷"
	sorghum.days_to_grow = 3
	sorghum.sell_price = 7
	var sorghum_stages: Array[Vector2i] = [Vector2i(0,3), Vector2i(1,3), Vector2i(2,3)]
	sorghum.stages_atlas_coords = sorghum_stages
	crops["sorghum"] = sorghum

	# Rice (稻) - Water Crop
	var rice = CropData.new()
	rice.crop_name = "稻"
	rice.days_to_grow = 4
	rice.sell_price = 12
	var rice_stages: Array[Vector2i] = [Vector2i(0,4), Vector2i(1,4), Vector2i(2,4)]
	rice.stages_atlas_coords = rice_stages
	rice.is_water_crop = true
	crops["rice"] = rice

	# Wheat (麦)
	var wheat = CropData.new()
	wheat.crop_name = "麦"
	wheat.days_to_grow = 3
	wheat.sell_price = 8
	var wheat_stages: Array[Vector2i] = [Vector2i(0,5), Vector2i(1,5), Vector2i(2,5)]
	wheat.stages_atlas_coords = wheat_stages
	crops["wheat"] = wheat

	# Beans (菽) - Restores Fertility
	var beans = CropData.new()
	beans.crop_name = "菽"
	beans.days_to_grow = 2
	beans.sell_price = 4
	var beans_stages: Array[Vector2i] = [Vector2i(0,6), Vector2i(1,6), Vector2i(2,6)]
	beans.stages_atlas_coords = beans_stages
	beans.restores_fertility = true
	crops["beans"] = beans

	# Mulberry (桑) - Perennial
	var mulberry = CropData.new()
	mulberry.crop_name = "桑"
	mulberry.days_to_grow = 5
	mulberry.sell_price = 15
	var mulberry_stages: Array[Vector2i] = [Vector2i(0,7), Vector2i(1,7), Vector2i(2,7)]
	mulberry.stages_atlas_coords = mulberry_stages
	mulberry.is_perennial = true
	crops["mulberry"] = mulberry

	# Hemp (麻)
	var hemp = CropData.new()
	hemp.crop_name = "麻"
	hemp.days_to_grow = 2
	hemp.sell_price = 6
	var hemp_stages: Array[Vector2i] = [Vector2i(0,8), Vector2i(1,8), Vector2i(2,8)]
	hemp.stages_atlas_coords = hemp_stages
	crops["hemp"] = hemp

func get_crop(id: String) -> CropData:
	return crops.get(id)
