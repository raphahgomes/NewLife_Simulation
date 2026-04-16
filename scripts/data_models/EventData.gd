class_name EventData
extends Resource

## Represents one event loaded from JSON

@export var id: String = ""
@export var phases: Array[String] = []  # e.g. ["CHILD", "TEEN"]
@export var age_min: int = 0
@export var age_max: int = 100
@export var category: String = ""  # school, family, health, social, crime, career, finance, random
@export var weight: int = 10  # higher = more likely to appear
@export var conditions: Dictionary = {}
# Conditions may include: min_X, max_X for attributes, has_trait, has_career, etc.

@export var text_key: String = ""  # localization key for the event description
@export var choices: Array[Dictionary] = []
# Each choice: {
#   "text_key": String,
#   "effects": { "health": int, "happiness": int, ... },
#   "relationship_effects": { "type": { "affection": int, ... } },
#   "trait_chance": { "trait_name": float },
#   "followup_event": String (optional),
#   "money_effect": float (optional),
#   "morality_effect": int (optional)
# }

static func from_dict(d: Dictionary) -> EventData:
	var e := EventData.new()
	e.id = d.get("id", "")
	var raw_phases: Array = d.get("phases", d.get("phase", []))
	e.phases = Array(raw_phases, TYPE_STRING, "", null)
	var age_range: Array = d.get("age_range", [])
	if age_range.size() >= 2:
		e.age_min = int(age_range[0])
		e.age_max = int(age_range[1])
	else:
		e.age_min = int(d.get("age_min", 0))
		e.age_max = int(d.get("age_max", 100))
	e.category = d.get("category", "")
	e.weight = d.get("weight", 10)
	e.conditions = d.get("conditions", {})
	e.text_key = d.get("text_key", "")
	e.choices = Array(d.get("choices", []), TYPE_DICTIONARY, "", null)
	return e

func matches_character(character: Character) -> bool:
	# Check phase
	var phase_name: String = character.get_phase_name()
	if not phases.is_empty() and not phases.has(phase_name):
		return false

	# Check age range
	if character.age < age_min or character.age > age_max:
		return false

	# Check conditions
	for key in conditions:
		var val = conditions[key]
		match key:
			"min_health": if character.health < val: return false
			"max_health": if character.health > val: return false
			"min_intelligence": if character.intelligence < val: return false
			"max_intelligence": if character.intelligence > val: return false
			"min_charisma": if character.charisma < val: return false
			"max_charisma": if character.charisma > val: return false
			"min_appearance": if character.appearance < val: return false
			"max_appearance": if character.appearance > val: return false
			"min_happiness": if character.happiness < val: return false
			"max_happiness": if character.happiness > val: return false
			"min_morality": if character.morality < val: return false
			"max_morality": if character.morality > val: return false
			"min_money": if character.money < val: return false
			"max_money": if character.money > val: return false
			"has_trait":
				if val is String:
					if not character.has_trait(val): return false
				elif val is Array:
					var has_any := false
					for t in val:
						if character.has_trait(t):
							has_any = true
							break
					if not has_any: return false
			"not_trait":
				if val is String:
					if character.has_trait(val): return false
				elif val is Array:
					for t in val:
						if character.has_trait(t): return false
			"has_career":
				if val is bool:
					if val and character.current_career == "": return false
					if not val and character.current_career != "": return false
				else:
					if character.current_career != val: return false
			"no_career":
				if val and character.current_career != "": return false
			"min_education":
				if character.education < val: return false
			"social_class":
				if character.social_class != val: return false

	return true
