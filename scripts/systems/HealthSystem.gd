class_name HealthSystem extends RefCounted

## HealthSystem — Manages diseases, addiction, fitness, mental health
## Called by GameManager.process_health() each year

enum DiseaseType {
	COLD, FLU, DIABETES, HYPERTENSION, CANCER, DEPRESSION, ANXIETY,
	ADDICTION_ALCOHOL, ADDICTION_DRUGS, OBESITY, HEART_DISEASE, STROKE
}

const DISEASE_DATA := {
	"cold":              {"text_key": "DISEASE_COLD",        "icon": "🤧", "severity": 1, "annual_cost": 100.0,   "health_drain": 5,  "treatment_cost": 300.0},
	"flu":               {"text_key": "DISEASE_FLU",         "icon": "🤒", "severity": 1, "annual_cost": 200.0,   "health_drain": 8,  "treatment_cost": 500.0},
	"diabetes":          {"text_key": "DISEASE_DIABETES",    "icon": "💉", "severity": 3, "annual_cost": 3000.0,  "health_drain": 3,  "treatment_cost": 5000.0},
	"hypertension":      {"text_key": "DISEASE_HYPERTENSION","icon": "🩺", "severity": 2, "annual_cost": 1500.0,  "health_drain": 2,  "treatment_cost": 2000.0},
	"cancer":            {"text_key": "DISEASE_CANCER",      "icon": "🔴", "severity": 5, "annual_cost": 20000.0, "health_drain": 15, "treatment_cost": 60000.0},
	"depression":        {"text_key": "DISEASE_DEPRESSION",  "icon": "😞", "severity": 3, "annual_cost": 2000.0,  "health_drain": 2,  "treatment_cost": 4000.0},
	"anxiety":           {"text_key": "DISEASE_ANXIETY",     "icon": "😰", "severity": 2, "annual_cost": 1500.0,  "health_drain": 1,  "treatment_cost": 3000.0},
	"addiction_alcohol": {"text_key": "DISEASE_ALCOHOLISM",  "icon": "🍺", "severity": 3, "annual_cost": 2500.0,  "health_drain": 5,  "treatment_cost": 8000.0},
	"addiction_drugs":   {"text_key": "DISEASE_ADDICTION",   "icon": "💊", "severity": 4, "annual_cost": 5000.0,  "health_drain": 8,  "treatment_cost": 12000.0},
	"obesity":           {"text_key": "DISEASE_OBESITY",     "icon": "⚖️",  "severity": 2, "annual_cost": 2000.0,  "health_drain": 3,  "treatment_cost": 5000.0},
	"heart_disease":     {"text_key": "DISEASE_HEART",       "icon": "💔", "severity": 4, "annual_cost": 8000.0,  "health_drain": 5,  "treatment_cost": 25000.0},
	"stroke":            {"text_key": "DISEASE_STROKE",      "icon": "🧠", "severity": 5, "annual_cost": 15000.0, "health_drain": 10, "treatment_cost": 40000.0},
}


static func process_year(character: Character, rng: RandomNumberGenerator, event_queue: Array) -> void:
	var diseases: Array = character.inventory.filter(func(i): return i is Dictionary and i.get("category") == "disease")

	# Random new disease chance
	_try_contract_disease(character, rng, event_queue, diseases)

	# Apply existing disease effects
	for disease_item in diseases:
		var d := disease_item as Dictionary
		var disease_id: String = d.get("id", "")
		var ddata := DISEASE_DATA.get(disease_id, {}) as Dictionary
		if ddata.is_empty():
			continue
		var drain: int = ddata.get("health_drain", 0)
		character.health = clampi(character.health - drain, 0, 100)
		var cost: float = ddata.get("annual_cost", 0.0)
		# Poor people can't afford treatment → extra drain
		if character.money < cost:
			character.health = clampi(character.health - 3, 0, 100)
		else:
			character.money -= cost

	# Stress → mental health cascade
	if character.stress >= 80:
		character.mental_stability = clampi(character.mental_stability - 5, 0, 100)
		character.sanity = clampi(character.sanity - 3, 0, 100)
		if not has_disease(character, "anxiety") and rng.randf() < 0.15:
			add_disease(character, "anxiety")
			FamilyEconomySystem._trigger_forced_event(event_queue, "adult_anxiety_onset")

	if character.mental_stability <= 20 and not has_disease(character, "depression"):
		if rng.randf() < 0.20:
			add_disease(character, "depression")


static func treat_disease(character: Character, disease_id: String) -> Dictionary:
	var ddata := DISEASE_DATA.get(disease_id, {}) as Dictionary
	if ddata.is_empty():
		return {"error": "unknown"}
	var cost: float = ddata.get("treatment_cost", 0.0)
	if character.money < cost:
		return {"error": "no_money", "needed": cost}
	character.money -= cost
	var removed := remove_disease(character, disease_id)
	if removed:
		character.health = clampi(character.health + 15, 0, 100)
		return {"success": true, "cost": cost}
	return {"error": "not_sick"}


static func has_disease(character: Character, disease_id: String) -> bool:
	for item in character.inventory:
		if item is Dictionary and item.get("category") == "disease" and item.get("id") == disease_id:
			return true
	return false


static func add_disease(character: Character, disease_id: String) -> void:
	if has_disease(character, disease_id):
		return
	var ddata := DISEASE_DATA.get(disease_id, {}) as Dictionary
	if ddata.is_empty():
		return
	character.inventory.append({
		"id": disease_id,
		"category": "disease",
		"name_key": ddata.get("text_key", ""),
		"icon": ddata.get("icon", "🤒"),
		"severity": ddata.get("severity", 1),
	})


static func remove_disease(character: Character, disease_id: String) -> bool:
	for i in character.inventory.size():
		var item := character.inventory[i] as Dictionary
		if item.get("category") == "disease" and item.get("id") == disease_id:
			character.inventory.remove_at(i)
			return true
	return false


static func get_active_diseases(character: Character) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in character.inventory:
		if item is Dictionary and item.get("category") == "disease":
			result.append(item)
	return result


# ── Private ──

static func _try_contract_disease(character: Character, rng: RandomNumberGenerator, event_queue: Array, current_diseases: Array) -> void:
	if current_diseases.size() >= 3:
		return  # Already sick enough

	var base_chance := 0.05

	# Age increases disease risk
	if character.age > 50: base_chance += 0.08
	if character.age > 65: base_chance += 0.10

	# Low health = more vulnerable
	if character.health < 40: base_chance += 0.08

	# Traits
	if character.has_trait("unhealthy"): base_chance += 0.05
	if character.has_trait("athletic"):  base_chance -= 0.03

	if rng.randf() > base_chance:
		return

	# Pick a random age-appropriate disease
	var pool := _get_disease_pool(character)
	if pool.is_empty():
		return
	var disease_id: String = pool[rng.randi_range(0, pool.size() - 1)]
	if not has_disease(character, disease_id):
		add_disease(character, disease_id)
		var ddata := DISEASE_DATA[disease_id] as Dictionary
		if ddata.get("severity", 1) >= 3:
			FamilyEconomySystem._trigger_forced_event(event_queue, "health_serious_diagnosis")


static func _get_disease_pool(character: Character) -> Array[String]:
	var pool: Array[String] = ["cold", "flu"]
	if character.age >= 18:
		pool.append_array(["hypertension", "anxiety", "depression"])
	if character.age >= 30:
		pool.append_array(["diabetes", "obesity"])
	if character.age >= 45:
		pool.append_array(["heart_disease", "cancer"])
	if character.age >= 55:
		pool.append_array(["stroke"])
	return pool
