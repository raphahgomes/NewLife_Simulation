extends Node

## AttributeSystem — Handles stat modifications, aging effects, and trait interactions


func modify_stat(character: Character, stat_name: String, amount: int) -> void:
	match stat_name:
		"health":
			character.health = clampi(character.health + amount, 0, 100)
		"intelligence":
			character.intelligence = clampi(character.intelligence + amount, 0, 100)
		"charisma":
			character.charisma = clampi(character.charisma + amount, 0, 100)
		"appearance":
			character.appearance = clampi(character.appearance + amount, 0, 100)
		"temperament":
			character.temperament = clampi(character.temperament + amount, 0, 100)
		"luck":
			character.luck = clampi(character.luck + amount, 0, 100)
		"happiness":
			character.happiness = clampi(character.happiness + amount, 0, 100)
		"morality":
			character.morality = clampi(character.morality + amount, 0, 100)
		"mental_stability":
			character.mental_stability = clampi(character.mental_stability + amount, 0, 100)
		"school_performance":
			character.school_performance = clampi(character.school_performance + amount, 0, 100)


func apply_aging(character: Character) -> void:
	# Natural health decline after 40
	if character.age > 60:
		character.health = clampi(character.health - 3, 0, 100)
		character.appearance = clampi(character.appearance - 2, 0, 100)
	elif character.age > 40:
		character.health = clampi(character.health - 1, 0, 100)
		character.appearance = clampi(character.appearance - 1, 0, 100)

	# Natural intelligence growth in youth, decline in elders
	if character.age < 25:
		character.intelligence = clampi(character.intelligence + 1, 0, 100)
	elif character.age > 70:
		character.intelligence = clampi(character.intelligence - 1, 0, 100)

	# Apply trait effects
	_apply_trait_effects(character)

	# Relationship decay (if not maintained)
	for rel in character.relationships:
		if rel is Relationship and not rel.is_close:
			rel.modify_affection(-2)
			rel.modify_trust(-1)

	# Happiness drift toward baseline based on traits
	var happiness_target := 50
	if character.has_trait("extrovert"):
		happiness_target += 5
	if character.has_trait("introvert"):
		happiness_target -= 3
	if character.has_trait("anxious"):
		happiness_target -= 5
	if character.has_trait("compassionate"):
		happiness_target += 3

	# Drift toward target slowly
	if character.happiness > happiness_target + 5:
		character.happiness = clampi(character.happiness - 2, 0, 100)
	elif character.happiness < happiness_target - 5:
		character.happiness = clampi(character.happiness + 2, 0, 100)


var _traits_data: Dictionary = {}  # id -> effects dict

func _load_traits_data() -> void:
	if not _traits_data.is_empty():
		return
	var path := "res://data/traits/traits.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		for trait_dict in parsed.get("traits", []):
			var tid: String = trait_dict.get("id", "")
			if tid != "":
				_traits_data[tid] = trait_dict.get("effects", {})


func _apply_trait_effects(character: Character) -> void:
	_load_traits_data()
	for trait_name in character.traits:
		var effects: Dictionary = _traits_data.get(trait_name, {})
		for stat_name in effects:
			# Apply a fraction of the effect each year (effects are per-year bonuses)
			var amount: int = int(effects[stat_name])
			modify_stat(character, stat_name, amount)


## Calculate the probability of success for a given stat check
func success_chance(character: Character, stat_name: String, difficulty: int) -> float:
	var stat_value: int = 50
	match stat_name:
		"health": stat_value = character.health
		"intelligence": stat_value = character.intelligence
		"charisma": stat_value = character.charisma
		"appearance": stat_value = character.appearance
		"temperament": stat_value = character.temperament
		"luck": stat_value = character.luck

	# Base chance = stat / (stat + difficulty), with luck modifier
	var base: float = float(stat_value) / float(stat_value + difficulty)
	var luck_bonus: float = character.luck / 500.0  # 0 to 0.2
	return clampf(base + luck_bonus, 0.01, 0.99)
