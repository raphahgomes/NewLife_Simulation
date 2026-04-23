class_name FameSystem
extends RefCounted

## FameSystem — handles fame gain, loss, and related event modifiers

# Fame tiers
const TIER_UNKNOWN := 0      # 0–9
const TIER_LOCAL := 10       # 10–29
const TIER_REGIONAL := 30    # 30–49
const TIER_NATIONAL := 50    # 50–74
const TIER_WORLD := 75       # 75–100

# Fame events by category and their fame deltas
const FAME_EVENTS := {
	"viral_content":        {"fame_delta": 12, "condition": "age >= 13"},
	"major_career_award":   {"fame_delta": 20, "condition": "career_level >= 3"},
	"scandal":              {"fame_delta": 15, "condition": "fame >= 20"},  # fame spike but morality -15
	"scandal_recovery":     {"fame_delta": -10, "condition": "fame >= 10"},
	"criminal_arrest":      {"fame_delta": 8,  "condition": "criminal_record"},
	"music_hit":            {"fame_delta": 18, "condition": "talent_music >= 4"},
	"sports_champion":      {"fame_delta": 22, "condition": "talent_sport >= 5"},
	"best_seller":          {"fame_delta": 16, "condition": "talent_reading >= 4"},
	"art_exhibition":       {"fame_delta": 10, "condition": "talent_art >= 3"},
	"political_speech":     {"fame_delta": 14, "condition": "charisma >= 70"},
	"forgotten":            {"fame_delta": -5, "condition": "fame >= 10"},   # annual passive decay
}

const FAME_TIER_KEYS := {
	TIER_UNKNOWN:  "FAME_TIER_UNKNOWN",
	TIER_LOCAL:    "FAME_TIER_LOCAL",
	TIER_REGIONAL: "FAME_TIER_REGIONAL",
	TIER_NATIONAL: "FAME_TIER_NATIONAL",
	TIER_WORLD:    "FAME_TIER_WORLD",
}


static func get_tier(character: Character) -> int:
	var f := character.fame
	if f >= TIER_WORLD: return TIER_WORLD
	if f >= TIER_NATIONAL: return TIER_NATIONAL
	if f >= TIER_REGIONAL: return TIER_REGIONAL
	if f >= TIER_LOCAL: return TIER_LOCAL
	return TIER_UNKNOWN


static func get_tier_name_key(character: Character) -> String:
	return FAME_TIER_KEYS.get(get_tier(character), "FAME_TIER_UNKNOWN")


static func grant_fame(character: Character, event_id: String) -> Dictionary:
	if not FAME_EVENTS.has(event_id):
		return {}
	var ev := FAME_EVENTS[event_id] as Dictionary
	var delta: int = ev.get("fame_delta", 0)
	var old_tier := get_tier(character)
	character.fame = clampi(character.fame + delta, 0, 100)
	var new_tier := get_tier(character)
	var result := {"fame_delta": delta, "new_fame": character.fame}
	if new_tier > old_tier:
		result["tier_up"] = true
		result["tier_key"] = get_tier_name_key(character)
	if event_id == "scandal":
		character.morality = clampi(character.morality - 15, 0, 100)
		result["morality_delta"] = -15
	return result


static func process_year(character: Character, rng: RandomNumberGenerator) -> Dictionary:
	# Annual fame decay when famous
	if character.fame >= TIER_LOCAL:
		var decay := rng.randi_range(0, 3)
		character.fame = maxi(0, character.fame - decay)

	# Chance of random fame event based on career/talents
	var roll := rng.randf()
	if character.career_level >= 3 and roll < 0.08:
		return grant_fame(character, "major_career_award")
	if character.fame >= TIER_NATIONAL and roll < 0.05:
		return grant_fame(character, "scandal")
	if HobbySystem.get_level(character, "music") >= 4 and roll < 0.06:
		return grant_fame(character, "music_hit")
	if HobbySystem.get_level(character, "sport") >= 5 and roll < 0.07:
		return grant_fame(character, "sports_champion")
	if character.charisma >= 70 and roll < 0.04:
		return grant_fame(character, "political_speech")
	return {}


## Modifies event weight based on fame (famous people get different events)
static func get_event_weight_modifier(character: Character, event_category: String) -> float:
	var tier := get_tier(character)
	if tier >= TIER_NATIONAL:
		match event_category:
			"social": return 1.3
			"career": return 1.4
			"crime": return 0.7  # fewer petty crimes, more scrutiny
	elif tier >= TIER_REGIONAL:
		match event_category:
			"career": return 1.2
	return 1.0
