class_name CrimeSystem extends RefCounted

## CrimeSystem — Handles all criminal activity logic
## Called by GameHUD when player chooses crime actions.

enum CrimeType {
	SHOPLIFTING,
	PICKPOCKET,
	BURGLARY,
	ASSAULT,
	DRUG_DEALING,
	FRAUD,
	CAR_THEFT,
	MURDER,
}

enum CrimeResult {
	SUCCESS,
	CAUGHT,
	ESCAPED_INJURED,
}

static func attempt_crime(
	character: Character,
	crime: CrimeType,
	rng: RandomNumberGenerator
) -> Dictionary:
	var result := {}

	var base_success := _base_success_rate(crime)
	# Luck, intelligence and morality influence outcome
	var bonus := (character.luck - 50) * 0.003 + (character.intelligence - 50) * 0.002
	# Traits that affect crime
	if character.has_trait("cunning"): bonus += 0.08
	if character.has_trait("brave"): bonus += 0.05
	if character.has_trait("reckless"): bonus -= 0.05
	if character.criminal_record: bonus -= 0.05  # police more alert

	var final_rate := clampf(base_success + bonus, 0.05, 0.95)
	var roll := rng.randf()

	if roll < final_rate:
		result["outcome"] = CrimeResult.SUCCESS
		result["money"] = _loot_value(crime, rng)
		result["morality_delta"] = _morality_cost(crime)
		# Trait gain chance
		if rng.randf() < 0.08:
			result["new_trait"] = "cunning"
	elif roll < final_rate + 0.25:
		# Escaped but possibly injured
		result["outcome"] = CrimeResult.ESCAPED_INJURED
		result["health_delta"] = -rng.randi_range(5, 20)
		result["morality_delta"] = _morality_cost(crime)
		result["money"] = 0
	else:
		# Caught
		result["outcome"] = CrimeResult.CAUGHT
		result["money"] = 0
		result["morality_delta"] = _morality_cost(crime)
		result["fine"] = _fine_amount(crime)
		result["happiness_delta"] = -rng.randi_range(10, 25)
		result["criminal_record"] = true
		# Prison chance for serious crimes
		if crime in [CrimeType.BURGLARY, CrimeType.DRUG_DEALING, CrimeType.FRAUD, CrimeType.CAR_THEFT, CrimeType.MURDER]:
			result["prison_years"] = _prison_sentence(crime, character, rng)

	return result


static func apply_result(character: Character, result: Dictionary) -> void:
	var money_gain: float = float(result.get("money", 0))
	if money_gain > 0:
		character.money += money_gain

	var fine: float = float(result.get("fine", 0))
	if fine > 0:
		character.money = maxf(0, character.money - fine)
		character.debt += maxf(0, fine - character.money)

	var health_d: int = result.get("health_delta", 0)
	if health_d != 0:
		character.health = clampi(character.health + health_d, 0, 100)

	var morality_d: int = result.get("morality_delta", 0)
	if morality_d != 0:
		character.morality = clampi(character.morality + morality_d, 0, 100)

	var happiness_d: int = result.get("happiness_delta", 0)
	if happiness_d != 0:
		character.happiness = clampi(character.happiness + happiness_d, 0, 100)

	if result.get("criminal_record", false):
		character.criminal_record = true

	if result.has("new_trait") and not character.has_trait(result["new_trait"]):
		character.add_trait(result["new_trait"])

	# Prison ages the character forward
	var prison_years: int = result.get("prison_years", 0)
	if prison_years > 0:
		character.age += prison_years
		character.happiness = clampi(character.happiness - 30, 0, 100)
		character.mental_stability = clampi(character.mental_stability - 20, 0, 100)
		if not character.has_trait("traumatized"):
			character.add_trait("traumatized")


# ── Private helpers ──

static func _base_success_rate(crime: CrimeType) -> float:
	match crime:
		CrimeType.SHOPLIFTING:   return 0.75
		CrimeType.PICKPOCKET:    return 0.65
		CrimeType.BURGLARY:      return 0.50
		CrimeType.ASSAULT:       return 0.60
		CrimeType.DRUG_DEALING:  return 0.55
		CrimeType.FRAUD:         return 0.45
		CrimeType.CAR_THEFT:     return 0.40
		CrimeType.MURDER:        return 0.30
	return 0.50


static func _loot_value(crime: CrimeType, rng: RandomNumberGenerator) -> float:
	match crime:
		CrimeType.SHOPLIFTING:   return rng.randi_range(20, 150)
		CrimeType.PICKPOCKET:    return rng.randi_range(50, 300)
		CrimeType.BURGLARY:      return rng.randi_range(500, 3000)
		CrimeType.ASSAULT:       return rng.randi_range(100, 500)
		CrimeType.DRUG_DEALING:  return rng.randi_range(200, 2000)
		CrimeType.FRAUD:         return rng.randi_range(1000, 10000)
		CrimeType.CAR_THEFT:     return rng.randi_range(5000, 20000)
		CrimeType.MURDER:        return 0.0
	return 0.0


static func _fine_amount(crime: CrimeType) -> float:
	match crime:
		CrimeType.SHOPLIFTING:   return 500.0
		CrimeType.PICKPOCKET:    return 1000.0
		CrimeType.BURGLARY:      return 5000.0
		CrimeType.ASSAULT:       return 3000.0
		CrimeType.DRUG_DEALING:  return 8000.0
		CrimeType.FRAUD:         return 20000.0
		CrimeType.CAR_THEFT:     return 15000.0
		CrimeType.MURDER:        return 0.0
	return 500.0


static func _morality_cost(crime: CrimeType) -> int:
	match crime:
		CrimeType.SHOPLIFTING:   return -3
		CrimeType.PICKPOCKET:    return -5
		CrimeType.BURGLARY:      return -10
		CrimeType.ASSAULT:       return -12
		CrimeType.DRUG_DEALING:  return -15
		CrimeType.FRAUD:         return -18
		CrimeType.CAR_THEFT:     return -12
		CrimeType.MURDER:        return -40
	return -5


static func _prison_sentence(crime: CrimeType, character: Character, rng: RandomNumberGenerator) -> int:
	var base := 0
	match crime:
		CrimeType.BURGLARY:      base = rng.randi_range(1, 3)
		CrimeType.DRUG_DEALING:  base = rng.randi_range(2, 6)
		CrimeType.FRAUD:         base = rng.randi_range(2, 8)
		CrimeType.CAR_THEFT:     base = rng.randi_range(1, 4)
		CrimeType.MURDER:        base = rng.randi_range(10, 25)
	# Good lawyer can reduce
	if character.money > 50000:
		base = max(1, base - rng.randi_range(0, 2))
	return base


static func get_crime_name_key(crime: CrimeType) -> String:
	match crime:
		CrimeType.SHOPLIFTING:   return "CRIME_SHOPLIFTING"
		CrimeType.PICKPOCKET:    return "CRIME_PICKPOCKET"
		CrimeType.BURGLARY:      return "CRIME_BURGLARY"
		CrimeType.ASSAULT:       return "CRIME_ASSAULT"
		CrimeType.DRUG_DEALING:  return "CRIME_DRUG_DEALING"
		CrimeType.FRAUD:         return "CRIME_FRAUD"
		CrimeType.CAR_THEFT:     return "CRIME_CAR_THEFT"
		CrimeType.MURDER:        return "CRIME_MURDER"
	return "CRIME_UNKNOWN"
