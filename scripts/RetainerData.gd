extends Resource
class_name RetainerData

@export var name: String = "无名氏"
@export var profession: String = "农夫" # Peasant, Scholar, etc.
@export var portrait: Texture2D

# 门客学派
enum School {
	NONE,       # 无学派（普通流民）
	CONFUCIAN,  # 儒家
	MOHIST,     # 墨家
	LEGALIST,   # 法家
	AGRARIAN,   # 农家
	MILITARY    # 兵家
}
@export var school: School = School.NONE

# Attributes
@export_range(0, 100) var hunger: float = 0.0
@export_range(0, 100) var loyalty: float = 100.0
@export_range(0.1, 5.0) var efficiency: float = 1.0

func _init(p_name = "无名氏", p_prof = "农夫", p_school = School.NONE):
	name = p_name
	profession = p_prof
	school = p_school

# 获取学派名称
func get_school_name() -> String:
	match school:
		School.NONE: return "流民"
		School.CONFUCIAN: return "儒家"
		School.MOHIST: return "墨家"
		School.LEGALIST: return "法家"
		School.AGRARIAN: return "农家"
		School.MILITARY: return "兵家"
		_: return "未知"

# 获取学派特质描述
func get_school_ability() -> String:
	match school:
		School.CONFUCIAN: return "忠诚光环：周围门客忠诚度+30%"
		School.MOHIST: return "自动修缮：自动修复建筑耐久"
		School.LEGALIST: return "法家之治：税收效率+20%"
		School.AGRARIAN: return "耕作专家：作物产量+50%"
		School.MILITARY: return "主动防御：自动攻击入侵敌人"
		_: return "无特殊能力"

# 应用学派特质（返回效率加成）
func apply_school_ability() -> Dictionary:
	var bonus = {
		"efficiency": 1.0,
		"special": null
	}

	match school:
		School.CONFUCIAN:
			bonus["efficiency"] = 1.0
			bonus["special"] = "loyalty_aura"
		School.MOHIST:
			bonus["efficiency"] = 1.2  # 墨家工巧，效率+20%
			bonus["special"] = "auto_repair"
		School.LEGALIST:
			bonus["efficiency"] = 1.15  # 法家组织，效率+15%
			bonus["special"] = "tax_bonus"
		School.AGRARIAN:
			bonus["efficiency"] = 1.5  # 农家专精，效率+50%
			bonus["special"] = "crop_bonus"
		School.MILITARY:
			bonus["efficiency"] = 1.3  # 兵家纪律，效率+30%
			bonus["special"] = "auto_defend"
		_:
			bonus["efficiency"] = 1.0

	return bonus

# 随机生成门客
static func generate_random() -> RetainerData:
	var names = ["子路", "颜回", "子贡", "冉有", "子夏", "子游", "曾子", "子张"]
	var professions = ["士人", "农夫", "工匠", "商人"]
	var schools = [School.CONFUCIAN, School.MOHIST, School.AGRARIAN, School.MILITARY]

	var retainer = RetainerData.new()
	retainer.name = names.pick_random()
	retainer.profession = professions.pick_random()
	retainer.school = schools.pick_random()
	retainer.loyalty = randi_range(50, 100)
	retainer.efficiency = randf_range(0.8, 1.5)

	return retainer
