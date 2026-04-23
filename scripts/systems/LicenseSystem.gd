class_name LicenseSystem extends RefCounted

## LicenseSystem — Text-based license exams (driver, pilot, etc.)
## Licenses stored in character.inventory with category "license"

const LICENSES := {
	"drivers": {
		"name_key": "LIC_DRIVERS",
		"icon": "🚗",
		"min_age": 18,
		"fee": 1500.0,
		"questions": [
			{"q": "LIC_Q_SPEED_LIMIT",    "a": 0, "options": ["LIC_A_60", "LIC_A_80", "LIC_A_100", "LIC_A_120"]},
			{"q": "LIC_Q_RED_LIGHT",      "a": 1, "options": ["LIC_A_SLOW", "LIC_A_STOP", "LIC_A_YIELD", "LIC_A_HONK"]},
			{"q": "LIC_Q_DUI",            "a": 2, "options": ["LIC_A_OK_ONE", "LIC_A_OK_TWO", "LIC_A_ILLEGAL", "LIC_A_DEPENDS"]},
			{"q": "LIC_Q_SEATBELT",       "a": 0, "options": ["LIC_A_ALWAYS", "LIC_A_HIGHWAY", "LIC_A_OPTIONAL", "LIC_A_BACK_ONLY"]},
			{"q": "LIC_Q_YIELD_ROUNDABOUT","a": 1, "options": ["LIC_A_INSIDE", "LIC_A_ENTERING", "LIC_A_LEFT", "LIC_A_RIGHT"]},
		],
		"pass_score": 4,
	},
	"motorcycle": {
		"name_key": "LIC_MOTORCYCLE",
		"icon": "🏍️",
		"min_age": 18,
		"fee": 1200.0,
		"questions": [
			{"q": "LIC_Q_HELMET",         "a": 0, "options": ["LIC_A_ALWAYS", "LIC_A_HIGHWAY", "LIC_A_OPTIONAL", "LIC_A_NIGHT"]},
			{"q": "LIC_Q_MOTO_LANE",      "a": 1, "options": ["LIC_A_CAR_LANE", "LIC_A_BETWEEN", "LIC_A_SIDEWALK", "LIC_A_ANY"]},
			{"q": "LIC_Q_MOTO_DIST",      "a": 2, "options": ["LIC_A_2M", "LIC_A_5M", "LIC_A_10M", "LIC_A_15M"]},
			{"q": "LIC_Q_WET_ROAD",       "a": 3, "options": ["LIC_A_SAME", "LIC_A_FASTER", "LIC_A_SLOWER", "LIC_A_STOP"]},
			{"q": "LIC_Q_MOTO_NIGHT",     "a": 0, "options": ["LIC_A_HEADLIGHT", "LIC_A_HAZARD", "LIC_A_NONE", "LIC_A_FLASHLIGHT"]},
		],
		"pass_score": 4,
	},
	"pilot": {
		"name_key": "LIC_PILOT",
		"icon": "✈️",
		"min_age": 17,
		"fee": 80000.0,
		"questions": [
			{"q": "LIC_Q_VFR",            "a": 0, "options": ["LIC_A_VISUAL", "LIC_A_RADIO", "LIC_A_VERTICAL", "LIC_A_VECTOR"]},
			{"q": "LIC_Q_MAYDAY",         "a": 2, "options": ["LIC_A_HELLO", "LIC_A_HELP", "LIC_A_EMERGENCY", "LIC_A_LANDING"]},
			{"q": "LIC_Q_METAR",          "a": 1, "options": ["LIC_A_MAP", "LIC_A_WEATHER", "LIC_A_CHECKLIST", "LIC_A_RADAR"]},
			{"q": "LIC_Q_STALL",          "a": 3, "options": ["LIC_A_BRAKE", "LIC_A_CLIMB", "LIC_A_TURN", "LIC_A_LOWER_NOSE"]},
			{"q": "LIC_Q_ALTIMETER",      "a": 0, "options": ["LIC_A_ALTITUDE", "LIC_A_SPEED", "LIC_A_FUEL", "LIC_A_TEMP"]},
		],
		"pass_score": 4,
	},
}


static func attempt_exam(character: Character, license_id: String, answers: Array[int]) -> Dictionary:
	var lic := LICENSES.get(license_id, {}) as Dictionary
	if lic.is_empty():
		return {"error": "unknown_license"}

	if character.age < lic["min_age"]:
		return {"error": "too_young"}

	if has_license(character, license_id):
		return {"error": "already_have"}

	var fee: float = lic["fee"]
	if character.money < fee:
		return {"error": "no_money", "needed": fee}

	character.money -= fee  # Fee paid regardless

	var questions: Array = lic["questions"]
	var score := 0
	var pass_score: int = lic["pass_score"]

	for i in mini(answers.size(), questions.size()):
		if answers[i] == questions[i]["a"]:
			score += 1

	if score >= pass_score:
		# Grant license
		character.inventory.append({
			"id": license_id,
			"category": "license",
			"name_key": lic["name_key"],
			"icon": lic["icon"],
			"obtained_age": character.age,
		})
		character.happiness = clampi(character.happiness + 8, 0, 100)
		return {"passed": true, "score": score, "total": questions.size()}
	else:
		character.happiness = clampi(character.happiness - 5, 0, 100)
		return {"passed": false, "score": score, "total": questions.size(), "fee_lost": fee}


static func has_license(character: Character, license_id: String) -> bool:
	for item in character.inventory:
		if item is Dictionary and item.get("category") == "license" and item.get("id") == license_id:
			return true
	return false


static func get_available_licenses(character: Character) -> Array[String]:
	var result: Array[String] = []
	for lid in LICENSES:
		var lic := LICENSES[lid] as Dictionary
		if character.age >= lic["min_age"] and not has_license(character, lid):
			result.append(lid)
	return result
