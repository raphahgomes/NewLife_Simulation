class_name CombatSystem extends RefCounted

## CombatSystem — Turn-based text fights.
## Called from GameHUD or event resolution when a fight breaks out.

enum TargetZone { FACE, BODY, LEGS }
enum FightOutcome { PLAYER_WIN, PLAYER_LOSE, DRAW, ESCAPED }

const ZONE_NAMES := {
	TargetZone.FACE: "COMBAT_FACE",
	TargetZone.BODY: "COMBAT_BODY",
	TargetZone.LEGS: "COMBAT_LEGS",
}

# Returns a fully-resolved fight summary.
# opponent: { "name": str, "strength": int, "health": int, "aggression": float }
static func resolve_fight(
	character: Character,
	opponent: Dictionary,
	player_zone: TargetZone,
	rng: RandomNumberGenerator
) -> Dictionary:
	var result := {}

	var player_str := _calc_strength(character)
	var opp_str: int = opponent.get("strength", 50)
	var opp_hp: int  = opponent.get("health", 100)

	# Player attack
	var player_dmg := _damage(player_str, player_zone, rng)
	opp_hp -= player_dmg

	# Opponent counter-attack (random zone)
	var opp_zone := TargetZone.values()[rng.randi_range(0, 2)]
	var opp_dmg := _damage(opp_str, opp_zone, rng)
	var player_hp_after := character.health - opp_dmg

	result["player_damage_dealt"] = player_dmg
	result["player_damage_taken"] = opp_dmg
	result["zone_hit_key"] = ZONE_NAMES[player_zone]
	result["opponent_zone_hit_key"] = ZONE_NAMES[opp_zone]

	if opp_hp <= 0 and player_hp_after > 0:
		result["outcome"] = FightOutcome.PLAYER_WIN
		result["money_gained"] = int(opponent.get("money", 0))
		result["morality_delta"] = -8
		result["health_final"] = clampi(player_hp_after, 1, 100)
		if rng.randf() < 0.05:
			result["new_trait"] = "fighter"
	elif player_hp_after <= 0:
		result["outcome"] = FightOutcome.PLAYER_LOSE
		result["health_final"] = rng.randi_range(5, 20)  # Hospitalized
		result["morality_delta"] = 0
		result["hospital_cost"] = float(rng.randi_range(500, 3000))
	else:
		# Both still standing — draw/escape
		result["outcome"] = FightOutcome.DRAW
		result["health_final"] = clampi(player_hp_after, 1, 100)
		result["morality_delta"] = -3

	# Prison risk if public fight
	if opponent.get("is_public", false):
		var prison_roll := rng.randf()
		if result["outcome"] == FightOutcome.PLAYER_WIN and prison_roll < 0.20:
			result["arrested"] = true
			result["prison_years"] = 1
			result["criminal_record"] = true
		elif result["outcome"] == FightOutcome.PLAYER_LOSE and prison_roll < 0.10:
			result["arrested"] = true  # Arrested while hospitalised
			result["prison_years"] = 0
			result["criminal_record"] = true

	return result


static func apply_result(character: Character, result: Dictionary) -> void:
	character.health = result.get("health_final", character.health)

	var morality_d: int = result.get("morality_delta", 0)
	character.morality = clampi(character.morality + morality_d, 0, 100)

	var money_gained: int = result.get("money_gained", 0)
	if money_gained > 0:
		character.money += money_gained

	var hospital_cost: float = result.get("hospital_cost", 0.0)
	if hospital_cost > 0:
		character.money = maxf(0, character.money - hospital_cost)

	if result.get("criminal_record", false):
		character.criminal_record = true

	if result.get("arrested", false):
		var years: int = result.get("prison_years", 0)
		if years > 0:
			character.age += years
			character.happiness = clampi(character.happiness - 25, 0, 100)

	if result.has("new_trait") and not character.has_trait(result["new_trait"]):
		character.add_trait(result["new_trait"])


# ── Private ──

static func _calc_strength(character: Character) -> int:
	var base := (character.health + character.temperament) / 2
	if character.has_trait("athletic"): base += 10
	if character.has_trait("fighter"):  base += 8
	if character.has_trait("weak"):     base -= 10
	return clampi(base, 10, 100)


static func _damage(strength: int, zone: TargetZone, rng: RandomNumberGenerator) -> int:
	var base := rng.randi_range(5, 20) + strength / 10
	match zone:
		TargetZone.FACE: base += 5   # More damage but riskier
		TargetZone.BODY: base += 2   # Balanced
		TargetZone.LEGS: base -= 2   # Less damage but safer
	return maxi(1, base)


static func generate_opponent(age: int, context: String, rng: RandomNumberGenerator) -> Dictionary:
	var name := "Unknown"
	var strength := rng.randi_range(30, 70)
	var money := rng.randi_range(0, 200)
	var is_public := false

	match context:
		"bar_fight":
			name = tr("OPPONENT_DRUNK")
			strength = rng.randi_range(40, 75)
			is_public = true
		"robbery":
			name = tr("OPPONENT_ROBBER")
			strength = rng.randi_range(50, 80)
			money = rng.randi_range(100, 500)
		"school_bully":
			name = tr("OPPONENT_BULLY")
			strength = rng.randi_range(30, 60)
			is_public = true
		"gang":
			name = tr("OPPONENT_GANG")
			strength = rng.randi_range(60, 90)
			money = rng.randi_range(500, 2000)

	return {"name": name, "strength": strength, "health": 100, "money": money, "is_public": is_public}
