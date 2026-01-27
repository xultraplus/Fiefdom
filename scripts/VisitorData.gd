extends Resource
class_name VisitorData

enum School { CONFUCIAN, MOHIST, TAOIST, MERCHANT }

@export var name: String = "Visitor"
@export var school: School = School.CONFUCIAN
@export var dialogue_id: String = "default"
@export var portrait_color: Color = Color.WHITE

func get_school_name() -> String:
	match school:
		School.CONFUCIAN: return "儒家 (Confucian)"
		School.MOHIST: return "墨家 (Mohist)"
		School.TAOIST: return "道家 (Taoist)"
		School.MERCHANT: return "商贾 (Merchant)"
	return "Unknown"
