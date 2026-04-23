class_name HobbySystem extends RefCounted

## HobbySystem — Tracks hobby progression and effects
## Hobbies are stored in character.talents dict: { hobby_id: level }

enum HobbyType {
	MUSIC,
	ART,
	SPORT,
	COOKING,
	READING,
	GAMING,
	CODING,
	DANCE,
}

const HOBBY_DATA := {
	"music":   {"name_key": "HOBBY_MUSIC",   "icon": "🎵", "stat": "charisma",    "level_stat": "intelligence", "min_age": 5},
	"art":     {"name_key": "HOBBY_ART",     "icon": "🎨", "stat": "appearance",  "level_stat": "intelligence", "min_age": 5},
	"sport":   {"name_key": "HOBBY_SPORT",   "icon": "⚽", "stat": "health",      "level_stat": "intelligence", "min_age": 5},
	"cooking": {"name_key": "HOBBY_COOKING", "icon": "🍳", "stat": "happiness",   "level_stat": "intelligence", "min_age": 8},
	"reading": {"name_key": "HOBBY_READING", "icon": "📖", "stat": "intelligence","level_stat": "intelligence", "min_age": 5},
	"gaming":  {"name_key": "HOBBY_GAMING",  "icon": "🎮", "stat": "happiness",   "level_stat": "intelligence", "min_age": 7},
	"coding":  {"name_key": "HOBBY_CODING",  "icon": "💻", "stat": "intelligence","level_stat": "intelligence", "min_age": 10},
	"dance":   {"name_key": "HOBBY_DANCE",   "icon": "💃", "stat": "charisma",    "level_stat": "health",       "min_age": 5},
}

const LEVEL_NAMES := ["Beginner", "Amateur", "Intermediate", "Advanced", "Expert", "Master"]
const LEVEL_KEYS  := ["HOBBY_LVL_BEGINNER","HOBBY_LVL_AMATEUR","HOBBY_LVL_INTERMEDIATE","HOBBY_LVL_ADVANCED","HOBBY_LVL_EXPERT","HOBBY_LVL_MASTER"]


static func practice(character: Character, hobby_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var result := {}
	if not HOBBY_DATA.has(hobby_id):
		return result

	var data := HOBBY_DATA[hobby_id] as Dictionary
	var current_level: int = character.talents.get(hobby_id, 0)

	# Add XP / progress
	var xp_key := hobby_id + "_xp"
	var xp: int = character.talents.get(xp_key, 0) + rng.randi_range(8, 18)

	var xp_needed := 10 + current_level * 15
	if xp >= xp_needed and current_level < 5:
		current_level += 1
		xp = 0
		result["leveled_up"] = true
		result["new_level"] = current_level
		result["new_level_key"] = LEVEL_KEYS[current_level]
	character.talents[hobby_id] = current_level
	character.talents[xp_key] = xp

	# Stat benefit
	var stat: String = data["stat"]
	var gain := 1 + current_level / 2
	result["stat"] = stat
	result["gain"] = gain
	result["happiness_gain"] = 2

	var target_val: int = character.get(stat) if character.get(stat) != null else 50
	character.set(stat, clampi(target_val + gain, 0, 100))
	character.happiness = clampi(character.happiness + 2, 0, 100)

	# Possible trait gain at high levels
	if current_level >= 4 and rng.randf() < 0.05:
		var trait_map := {"music": "musical", "art": "artistic", "sport": "athletic",
			"cooking": "culinary", "reading": "bookworm", "coding": "tech_savvy",
			"dance": "graceful", "gaming": "gamer"}
		var trait_name: String = trait_map.get(hobby_id, "")
		if trait_name != "" and not character.has_trait(trait_name):
			character.add_trait(trait_name)
			result["new_trait"] = trait_name

	return result


static func get_hobbies_for_age(age: int) -> Array[String]:
	var available: Array[String] = []
	for hid in HOBBY_DATA:
		if age >= HOBBY_DATA[hid]["min_age"]:
			available.append(hid)
	return available


static func get_level(character: Character, hobby_id: String) -> int:
	return character.talents.get(hobby_id, 0)


static func get_level_name_key(level: int) -> String:
	return LEVEL_KEYS[clampi(level, 0, 5)]


static func get_icon(hobby_id: String) -> String:
	return HOBBY_DATA.get(hobby_id, {}).get("icon", "🎯")
