class_name Relationship
extends Resource

## Represents a relationship between the player character and another person

enum RelType {
	FATHER, MOTHER, SIBLING, SPOUSE, CHILD,
	FRIEND, COWORKER, BOSS, ROMANTIC, ENEMY,
	GRANDPARENT, UNCLE_AUNT, COUSIN, OTHER
}

@export var rel_type: RelType = RelType.FRIEND
@export var person_name: String = ""
@export var person_age: int = 0
@export var person_gender: String = "male"
@export var alive: bool = true

# Relationship bars (0–100)
@export var affection: int = 50
@export var respect: int = 50
@export var trust: int = 50

# Status
@export var is_close: bool = true  # actively in contact
@export var years_known: int = 0

func get_overall() -> float:
	return (affection + respect + trust) / 3.0

func get_type_name() -> String:
	match rel_type:
		RelType.FATHER: return "FATHER"
		RelType.MOTHER: return "MOTHER"
		RelType.SIBLING: return "SIBLING"
		RelType.SPOUSE: return "SPOUSE"
		RelType.CHILD: return "CHILD"
		RelType.FRIEND: return "FRIEND"
		RelType.COWORKER: return "COWORKER"
		RelType.BOSS: return "BOSS"
		RelType.ROMANTIC: return "ROMANTIC"
		RelType.ENEMY: return "ENEMY"
		RelType.GRANDPARENT: return "GRANDPARENT"
		RelType.UNCLE_AUNT: return "UNCLE_AUNT"
		RelType.COUSIN: return "COUSIN"
		RelType.OTHER: return "OTHER"
	return "UNKNOWN"

func modify_affection(amount: int) -> void:
	affection = clampi(affection + amount, 0, 100)

func modify_respect(amount: int) -> void:
	respect = clampi(respect + amount, 0, 100)

func modify_trust(amount: int) -> void:
	trust = clampi(trust + amount, 0, 100)

func to_save_dict() -> Dictionary:
	return {
		"rel_type": rel_type,
		"person_name": person_name,
		"person_age": person_age,
		"person_gender": person_gender,
		"alive": alive,
		"affection": affection,
		"respect": respect,
		"trust": trust,
		"is_close": is_close,
		"years_known": years_known
	}

static func from_save_dict(d: Dictionary) -> Relationship:
	var r := Relationship.new()
	r.rel_type = d.get("rel_type", RelType.FRIEND)
	r.person_name = d.get("person_name", "")
	r.person_age = d.get("person_age", 0)
	r.person_gender = d.get("person_gender", "male")
	r.alive = d.get("alive", true)
	r.affection = d.get("affection", 50)
	r.respect = d.get("respect", 50)
	r.trust = d.get("trust", 50)
	r.is_close = d.get("is_close", true)
	r.years_known = d.get("years_known", 0)
	return r
