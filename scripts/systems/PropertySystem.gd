class_name PropertySystem extends RefCounted

## PropertySystem — Handles houses, cars, investments for the character.
## Properties are stored as dicts in character.inventory with "category": "property"|"vehicle"|"investment"

# ── Property Templates ──
const PROPERTIES := [
	{"id": "studio_apt",    "name_key": "PROP_STUDIO",    "icon": "🏠", "category": "property",    "price": 80000.0,   "monthly_cost": 400.0,  "value_trend": 0.04, "min_age": 18},
	{"id": "apartment",     "name_key": "PROP_APT",       "icon": "🏢", "category": "property",    "price": 180000.0,  "monthly_cost": 800.0,  "value_trend": 0.05, "min_age": 18},
	{"id": "house",         "name_key": "PROP_HOUSE",     "icon": "🏡", "category": "property",    "price": 350000.0,  "monthly_cost": 1200.0, "value_trend": 0.06, "min_age": 18},
	{"id": "mansion",       "name_key": "PROP_MANSION",   "icon": "🏰", "category": "property",    "price": 1500000.0, "monthly_cost": 5000.0, "value_trend": 0.07, "min_age": 25},
	{"id": "used_car",      "name_key": "PROP_USED_CAR",  "icon": "🚗", "category": "vehicle",     "price": 15000.0,   "monthly_cost": 200.0,  "value_trend": -0.08,"min_age": 18},
	{"id": "new_car",       "name_key": "PROP_NEW_CAR",   "icon": "🚙", "category": "vehicle",     "price": 60000.0,   "monthly_cost": 600.0,  "value_trend": -0.12,"min_age": 18},
	{"id": "luxury_car",    "name_key": "PROP_LUX_CAR",   "icon": "🏎️", "category": "vehicle",     "price": 300000.0,  "monthly_cost": 2000.0, "value_trend": -0.06,"min_age": 21},
	{"id": "stocks",        "name_key": "PROP_STOCKS",    "icon": "📈", "category": "investment",  "price": 1000.0,    "monthly_cost": 0.0,    "value_trend": 0.10, "min_age": 18},
	{"id": "savings",       "name_key": "PROP_SAVINGS",   "icon": "🏦", "category": "investment",  "price": 500.0,     "monthly_cost": 0.0,    "value_trend": 0.04, "min_age": 16},
	{"id": "crypto",        "name_key": "PROP_CRYPTO",    "icon": "₿",  "category": "investment",  "price": 500.0,     "monthly_cost": 0.0,    "value_trend": 0.30, "min_age": 18},
]


static func buy(character: Character, property_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var template := _find_template(property_id)
	if template.is_empty():
		return {"error": "not_found"}

	var price: float = template["price"]
	if character.money < price:
		return {"error": "no_money", "needed": price}

	character.money -= price
	character.assets_value += price

	var item := {
		"id": property_id,
		"category": template["category"],
		"name_key": template["name_key"],
		"icon": template["icon"],
		"current_value": price,
		"monthly_cost": template["monthly_cost"],
		"value_trend": template["value_trend"],
		"bought_at_age": character.age,
	}
	character.inventory.append(item)
	character.happiness = clampi(character.happiness + 10, 0, 100)
	return {"success": true, "item": item}


static func sell(character: Character, property_id: String) -> Dictionary:
	for i in character.inventory.size():
		var item := character.inventory[i] as Dictionary
		if item.get("id", "") == property_id:
			var val: float = item.get("current_value", 0.0)
			character.money += val
			character.assets_value -= val
			character.inventory.remove_at(i)
			return {"success": true, "sold_for": val}
	return {"error": "not_owned"}


static func process_year(character: Character, rng: RandomNumberGenerator) -> float:
	var total_cost := 0.0
	for item in character.inventory:
		var d := item as Dictionary
		# Drift value
		var trend: float = d.get("value_trend", 0.0)
		var volatility := rng.randf_range(-0.05, 0.05)
		var new_val: float = d["current_value"] * (1.0 + trend + volatility)
		d["current_value"] = maxf(100.0, new_val)
		# Monthly costs → annual
		total_cost += d.get("monthly_cost", 0.0) * 12.0

	character.assets_value = _sum_assets(character)
	return total_cost


static func get_available_to_buy(character: Character) -> Array[Dictionary]:
	var owned_ids := _owned_ids(character)
	var result: Array[Dictionary] = []
	for t in PROPERTIES:
		if t["min_age"] <= character.age and not owned_ids.has(t["id"]):
			result.append(t)
	return result


static func get_owned(character: Character) -> Array[Dictionary]:
	return character.inventory.filter(func(i): return i is Dictionary and i.has("current_value"))


# ── Private ──

static func _find_template(id: String) -> Dictionary:
	for t in PROPERTIES:
		if t["id"] == id:
			return t
	return {}


static func _owned_ids(character: Character) -> Array:
	var ids := []
	for item in character.inventory:
		ids.append(item.get("id", ""))
	return ids


static func _sum_assets(character: Character) -> float:
	var total := 0.0
	for item in character.inventory:
		total += (item as Dictionary).get("current_value", 0.0)
	return total
