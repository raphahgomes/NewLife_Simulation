extends Node

## GameManager — Central singleton that controls game flow

signal game_started
signal year_advanced(age: int)
signal character_died(character: Character)
signal phase_changed(new_phase: Character.LifePhase)
signal event_triggered(event: EventData)

var character: Character = null
var is_game_active: bool = false
var current_year_events: Array[EventData] = []

# Queue of events waiting to be shown to the player
var _event_queue: Array[EventData] = []
var _current_event: EventData = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _careers_data: Array = []


func _ready() -> void:
	_load_careers()


# === Game Flow ===

func start_new_life(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = randi()
	_rng.seed = seed_value

	character = _generate_character(seed_value)
	is_game_active = true
	_event_queue.clear()
	_current_event = null

	SaveManager.auto_save(character)
	game_started.emit()

	# Trigger initial baby event
	_trigger_events_for_year()


func advance_year() -> void:
	if not is_game_active or character == null or not character.alive:
		return

	character.age += 1

	# Update life phase
	var new_phase := character.get_life_phase_for_age(character.age)
	if new_phase != character.life_phase:
		character.life_phase = new_phase
		phase_changed.emit(new_phase)

	# Age relationships
	for rel in character.relationships:
		if rel is Relationship:
			rel.person_age += 1
			rel.years_known += 1

	# Apply natural aging
	AttributeSystem.apply_aging(character)

	# Process education progression
	_process_education()

	# Process career progression
	_process_career_progression()

	# Apply career income/expenses
	_process_finances()

	# Process relationships (romance, family deaths, etc.)
	_process_relationships()

	# Check for death
	if _check_death():
		character.alive = false
		character.cause_of_death = _determine_cause_of_death()
		is_game_active = false
		character.add_event_log("EVENT_DEATH", "death")
		SaveManager.save_completed_life(character)
		character_died.emit(character)
		return

	# Trigger events for this year
	_trigger_events_for_year()

	year_advanced.emit(character.age)
	SaveManager.auto_save(character)


func apply_event_choice(event: EventData, choice_index: int) -> Dictionary:
	if choice_index < 0 or choice_index >= event.choices.size():
		return {}

	var choice: Dictionary = event.choices[choice_index]
	var results := {}

	# Apply stat effects
	var effects: Dictionary = choice.get("effects", {})
	for stat_name in effects:
		var amount: int = effects[stat_name]
		AttributeSystem.modify_stat(character, stat_name, amount)
		results[stat_name] = amount

	# Apply money effect
	var money_effect: float = choice.get("money_effect", 0.0)
	if money_effect != 0.0:
		character.money += money_effect
		results["money"] = money_effect

	# Apply morality effect
	var morality_effect: int = choice.get("morality_effect", 0)
	if morality_effect != 0:
		AttributeSystem.modify_stat(character, "morality", morality_effect)
		results["morality"] = morality_effect

	# Apply relationship effects
	var rel_effects: Dictionary = choice.get("relationship_effects", {})
	for rel_type_name in rel_effects:
		var rel_changes: Dictionary = rel_effects[rel_type_name]
		_apply_relationship_effects(rel_type_name, rel_changes)

	# Trait chances
	var trait_chance_data = choice.get("trait_chance", {})
	if trait_chance_data is Dictionary:
		if trait_chance_data.has("trait") and trait_chance_data.has("chance"):
			# Format: {"trait": "brave", "chance": 0.15}
			var t_name: String = trait_chance_data["trait"]
			var t_chance: float = float(trait_chance_data["chance"])
			if _rng.randf() < t_chance:
				character.add_trait(t_name)
				results["new_trait"] = t_name
		else:
			# Format: {"trait_name": chance}
			for trait_name in trait_chance_data:
				var chance: float = float(trait_chance_data[trait_name])
				if _rng.randf() < chance:
					character.add_trait(trait_name)
					results["new_trait"] = trait_name

	# Update statistics
	character.statistics["total_events"] += 1
	character.statistics["total_choices"] += 1
	if results.has("new_trait"):
		character.statistics["traits_gained"] += 1

	# Log event
	character.add_event_log(event.text_key, event.category)
	character.seen_events.append(event.id)

	# Queue followup event
	var followup: String = choice.get("followup_event", "")
	if followup != "":
		var followup_event := EventManager.get_event_by_id(followup)
		if followup_event != null:
			_event_queue.push_front(followup_event)

	return results


func get_next_event() -> EventData:
	if _event_queue.is_empty():
		return null
	_current_event = _event_queue.pop_front()
	return _current_event


func has_pending_events() -> bool:
	return not _event_queue.is_empty()


# === Private Methods ===

func _generate_character(seed_value: int) -> Character:
	var c := Character.new()
	c.world_seed = seed_value

	# Use sub-agent for name generation (loaded from JSON)
	var names_data := _load_names()
	var country: String = ["BR", "US"][_rng.randi_range(0, 1)]
	c.country = country

	var gender: String = ["male", "female"][_rng.randi_range(0, 1)]
	c.gender = gender

	var lang := "pt_BR" if country == "BR" else "en"
	var gender_key := "male_first" if gender == "male" else "female_first"

	if names_data.has(lang):
		var lang_names: Dictionary = names_data[lang]
		var first_names: Array = lang_names.get(gender_key, ["Alex"])
		var last_names: Array = lang_names.get("last", ["Silva"])
		c.first_name = first_names[_rng.randi_range(0, first_names.size() - 1)]
		c.last_name = last_names[_rng.randi_range(0, last_names.size() - 1)]
	else:
		c.first_name = "Alex"
		c.last_name = "Smith"

	# Attributes with variance
	c.health = clampi(_rng.randi_range(60, 100), 0, 100)
	c.intelligence = clampi(_rng.randi_range(20, 80), 0, 100)
	c.charisma = clampi(_rng.randi_range(20, 80), 0, 100)
	c.appearance = clampi(_rng.randi_range(20, 80), 0, 100)
	c.temperament = clampi(_rng.randi_range(20, 80), 0, 100)
	c.luck = clampi(_rng.randi_range(10, 90), 0, 100)
	c.happiness = clampi(_rng.randi_range(50, 90), 0, 100)
	c.morality = 50
	c.mental_stability = clampi(_rng.randi_range(50, 85), 0, 100)

	# Social class based on luck
	if c.luck > 70:
		c.social_class = Character.SocialClass.HIGH
		c.money = _rng.randf_range(50000, 200000)
	elif c.luck > 35:
		c.social_class = Character.SocialClass.MIDDLE
		c.money = _rng.randf_range(5000, 50000)
	else:
		c.social_class = Character.SocialClass.LOW
		c.money = _rng.randf_range(0, 5000)

	# Initial traits (1–2) — use valid IDs from traits.json
	var all_traits: Array[String] = [
		"introvert", "extrovert", "brave", "creative",
		"lazy", "athletic", "bookworm", "anxious",
		"charismatic", "compassionate", "ambitious", "romantic",
		"hardworking", "rebel", "sensitive", "optimistic",
		"pessimistic", "lucky", "unlucky", "genius",
		"clumsy", "beautiful", "funny", "calm",
		"stubborn", "generous", "honest", "risk_taker"
	]
	var num_traits := _rng.randi_range(1, 2)
	var available := all_traits.duplicate()
	for i in num_traits:
		if available.is_empty():
			break
		var idx := _rng.randi_range(0, available.size() - 1)
		c.traits.append(available[idx])
		available.remove_at(idx)

	# Generate family
	_generate_family(c)

	c.birth_year = 2026 - c.age  # current year
	c.age = 0
	c.life_phase = Character.LifePhase.BABY

	return c


func _generate_family(c: Character) -> void:
	var names_data := _load_names()
	var lang := "pt_BR" if c.country == "BR" else "en"
	var lang_names: Dictionary = names_data.get(lang, {})
	var male_names: Array = lang_names.get("male_first", ["Carlos"])
	var female_names: Array = lang_names.get("female_first", ["Maria"])
	var last_names: Array = lang_names.get("last", [c.last_name])

	# Father
	var father := Relationship.new()
	father.rel_type = Relationship.RelType.FATHER
	father.person_name = male_names[_rng.randi_range(0, male_names.size() - 1)] + " " + c.last_name
	father.person_age = _rng.randi_range(22, 40)
	father.person_gender = "male"
	father.affection = _rng.randi_range(40, 90)
	father.respect = _rng.randi_range(40, 80)
	father.trust = _rng.randi_range(40, 85)
	c.relationships.append(father)

	# Mother
	var mother := Relationship.new()
	mother.rel_type = Relationship.RelType.MOTHER
	var mother_last: String = last_names[_rng.randi_range(0, last_names.size() - 1)]
	mother.person_name = female_names[_rng.randi_range(0, female_names.size() - 1)] + " " + mother_last
	mother.person_age = _rng.randi_range(20, 38)
	mother.person_gender = "female"
	mother.affection = _rng.randi_range(50, 95)
	mother.respect = _rng.randi_range(40, 80)
	mother.trust = _rng.randi_range(50, 90)
	c.relationships.append(mother)

	# Siblings (0–3)
	var num_siblings := _rng.randi_range(0, 3)
	for i in num_siblings:
		var sib := Relationship.new()
		sib.rel_type = Relationship.RelType.SIBLING
		var sib_gender: String = ["male", "female"][_rng.randi_range(0, 1)] as String
		sib.person_gender = sib_gender
		var sib_names: Array = male_names if sib_gender == "male" else female_names
		sib.person_name = sib_names[_rng.randi_range(0, sib_names.size() - 1)] + " " + c.last_name
		sib.person_age = _rng.randi_range(0, 15)
		sib.affection = _rng.randi_range(30, 80)
		sib.respect = _rng.randi_range(30, 70)
		sib.trust = _rng.randi_range(30, 75)
		c.relationships.append(sib)


var _names_cache: Dictionary = {}

func _load_names() -> Dictionary:
	if not _names_cache.is_empty():
		return _names_cache

	var result := {}
	for lang in ["pt_BR", "en"]:
		var filename := "names_ptbr.json" if lang == "pt_BR" else "names_en.json"
		var path := "res://data/names/" + filename
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			var json_text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				result[lang] = parsed
	_names_cache = result
	return result


func _trigger_events_for_year() -> void:
	# Determine number of events this year based on phase
	var num_events: int
	match character.life_phase:
		Character.LifePhase.BABY:
			num_events = _rng.randi_range(1, 2)
		Character.LifePhase.CHILD:
			num_events = _rng.randi_range(1, 3)
		Character.LifePhase.TEEN:
			num_events = _rng.randi_range(2, 3)
		Character.LifePhase.ADULT:
			num_events = _rng.randi_range(1, 3)
		Character.LifePhase.ELDER:
			num_events = _rng.randi_range(1, 2)
		_:
			num_events = 1

	current_year_events.clear()
	for i in num_events:
		var event := EventManager.get_random_event(character)
		if event != null:
			current_year_events.append(event)
			_event_queue.append(event)
			event_triggered.emit(event)


func _process_finances() -> void:
	if character.salary > 0:
		# Monthly salary × 12, minus estimated expenses
		var annual_income := character.salary * 12.0
		var expense_ratio: float
		match character.social_class:
			Character.SocialClass.LOW: expense_ratio = 0.9
			Character.SocialClass.MIDDLE: expense_ratio = 0.7
			Character.SocialClass.HIGH: expense_ratio = 0.5
			_: expense_ratio = 0.7
		var expenses := annual_income * expense_ratio
		character.money += annual_income - expenses

	# Track money extremes
	if character.money > character.statistics["max_money"]:
		character.statistics["max_money"] = character.money
	if character.money < character.statistics["min_money"]:
		character.statistics["min_money"] = character.money

	# Debt interest
	if character.debt > 0:
		character.debt *= 1.08  # 8% annual interest
		character.money -= character.debt * 0.1  # minimum payment

	# Credit score adjustment
	if character.debt <= 0 and character.money > 0:
		character.credit_score = mini(character.credit_score + 5, 1000)
	elif character.debt > character.money * 2:
		character.credit_score = maxi(character.credit_score - 10, 0)


func _check_death() -> bool:
	if character.age < 1:
		return false

	# Base death probability increases with age
	var base_chance: float = 0.0
	if character.age > 80:
		base_chance = 0.08 + (character.age - 80) * 0.02
	elif character.age > 60:
		base_chance = 0.01 + (character.age - 60) * 0.003
	elif character.age > 40:
		base_chance = 0.002
	else:
		base_chance = 0.0005

	# Health modifier
	if character.health < 20:
		base_chance *= 3.0
	elif character.health < 40:
		base_chance *= 1.5

	# Mental stability modifier
	if character.mental_stability < 15:
		base_chance *= 1.5

	# Luck modifier
	base_chance *= (1.0 - character.luck / 200.0)

	return _rng.randf() < base_chance


func _determine_cause_of_death() -> String:
	if character.health < 20:
		return "ILLNESS"
	elif character.age > 85:
		return "OLD_AGE"
	elif character.mental_stability < 15:
		return "COMPLICATIONS"
	else:
		return "NATURAL_CAUSES"


func _apply_relationship_effects(rel_type_name: String, changes: Dictionary) -> void:
	for rel in character.relationships:
		if rel is Relationship and rel.get_type_name().to_lower() == rel_type_name.to_lower():
			if changes.has("affection"):
				rel.modify_affection(int(changes["affection"]))
			if changes.has("respect"):
				rel.modify_respect(int(changes["respect"]))
			if changes.has("trust"):
				rel.modify_trust(int(changes["trust"]))


# === Career System ===

func _load_careers() -> void:
	var path := "res://data/careers/careers.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		_careers_data = parsed.get("careers", [])


func get_available_careers() -> Array:
	var available: Array = []
	for career in _careers_data:
		if _can_pursue_career(career):
			available.append(career)
	return available


func _can_pursue_career(career: Dictionary) -> bool:
	if character == null:
		return false
	if character.age < career.get("min_age", 100):
		return false

	# Check education requirement
	var edu_map := {
		"NONE": Character.Education.NONE,
		"PRIMARY": Character.Education.PRIMARY,
		"SECONDARY": Character.Education.SECONDARY,
		"TECHNICAL": Character.Education.TECHNICAL,
		"COLLEGE": Character.Education.COLLEGE,
		"POSTGRAD": Character.Education.POSTGRAD
	}
	var min_edu_name: String = career.get("min_education", "NONE")
	var min_edu: int = edu_map.get(min_edu_name, 0)
	if character.education < min_edu:
		return false

	# Check required stats
	var req_stats: Dictionary = career.get("required_stats", {})
	for stat_name in req_stats:
		var req_val: int = int(req_stats[stat_name])
		var char_val: int = _get_character_stat(stat_name)
		if char_val < req_val:
			return false

	return true


func _get_character_stat(stat_name: String) -> int:
	match stat_name:
		"health": return character.health
		"intelligence": return character.intelligence
		"charisma": return character.charisma
		"appearance": return character.appearance
		"temperament": return character.temperament
		"luck": return character.luck
		"happiness": return character.happiness
		"morality": return character.morality
		"mental_stability": return character.mental_stability
	return 0


func hire_career(career_id: String) -> bool:
	for career in _careers_data:
		if career.get("id", "") == career_id and _can_pursue_career(career):
			character.current_career = career_id
			character.career_years = 0
			character.career_level = 0
			character.statistics["careers_held"] += 1
			var salary_range: Array = career.get("salary_range", [20000, 30000])
			character.salary = _rng.randf_range(float(salary_range[0]), float(salary_range[0]) + (float(salary_range[1]) - float(salary_range[0])) * 0.3)
			character.add_event_log("EVENT_CAREER_HIRED", "career")
			return true
	return false


func _process_career_progression() -> void:
	if character.current_career == "" or character.salary <= 0:
		return

	character.career_years += 1

	# Promotion chance every 3–5 years based on intelligence + charisma
	if character.career_years >= 3 and character.career_level < 3:
		var promo_chance := 0.1 + (character.intelligence + character.charisma) / 600.0
		if character.has_trait("ambitious"):
			promo_chance += 0.1
		if character.has_trait("hardworking"):
			promo_chance += 0.08
		if character.has_trait("lazy"):
			promo_chance -= 0.1

		if _rng.randf() < promo_chance:
			character.career_level += 1
			character.career_years = 0
			character.statistics["promotions"] += 1
			var raise_pct := 0.15 + character.career_level * 0.1
			character.salary *= (1.0 + raise_pct)
			character.add_event_log("EVENT_PROMOTION", "career")

	# Small annual raise
	character.salary *= 1.03


# === Education System ===

func _process_education() -> void:
	match character.life_phase:
		Character.LifePhase.CHILD:
			if character.age == 6 and character.education < Character.Education.PRIMARY:
				character.education = Character.Education.PRIMARY
				character.add_event_log("EVENT_START_SCHOOL", "school")
		Character.LifePhase.TEEN:
			if character.age == 13 and character.education < Character.Education.SECONDARY:
				character.education = Character.Education.SECONDARY
				character.add_event_log("EVENT_START_SECONDARY", "school")
		Character.LifePhase.ADULT:
			# College/Technical at 18 based on school_performance
			if character.age == 18 and character.education == Character.Education.SECONDARY:
				if character.school_performance >= 60:
					character.education = Character.Education.COLLEGE
					character.add_event_log("EVENT_START_COLLEGE", "school")
				elif character.school_performance >= 35:
					character.education = Character.Education.TECHNICAL
					character.add_event_log("EVENT_START_TECHNICAL", "school")
			# Postgrad at 23 if college + high intelligence
			if character.age == 23 and character.education == Character.Education.COLLEGE:
				if character.intelligence >= 65 and character.school_performance >= 70:
					character.education = Character.Education.POSTGRAD
					character.add_event_log("EVENT_START_POSTGRAD", "school")

	# School performance changes
	if character.life_phase in [Character.LifePhase.CHILD, Character.LifePhase.TEEN]:
		var change := _rng.randi_range(-3, 5)
		if character.has_trait("bookworm"):
			change += 3
		if character.has_trait("lazy"):
			change -= 3
		if character.has_trait("genius"):
			change += 4
		character.school_performance = clampi(character.school_performance + change, 0, 100)


# === Romance / Marriage / Children ===

func _process_relationships() -> void:
	# Auto-try career when turning 18 with no career
	if character.age == 18 and character.current_career == "":
		_try_auto_career()

	# Chance for romance events in teen/adult phases
	if character.life_phase == Character.LifePhase.ADULT:
		_process_romance()

	# Age-related death for parents
	for rel in character.relationships:
		if rel is Relationship and rel.alive:
			if rel.rel_type in [Relationship.RelType.FATHER, Relationship.RelType.MOTHER, Relationship.RelType.GRANDPARENT]:
				if rel.person_age > 70:
					var death_chance: float = 0.02 + (rel.person_age - 70) * 0.015
					if _rng.randf() < death_chance:
						rel.alive = false
						character.happiness = clampi(character.happiness - 15, 0, 100)
						character.mental_stability = clampi(character.mental_stability - 10, 0, 100)
						character.add_event_log("EVENT_RELATIVE_DIED", "family")


func _process_romance() -> void:
	# Check if already has a spouse
	var has_spouse := false
	for rel in character.relationships:
		if rel is Relationship and rel.rel_type == Relationship.RelType.SPOUSE and rel.alive:
			has_spouse = true
			break

	if not has_spouse and character.age >= 20:
		# Chance to meet a romantic partner
		var romance_chance := 0.08 + character.charisma / 500.0
		if character.has_trait("romantic"):
			romance_chance += 0.05
		if character.has_trait("introvert"):
			romance_chance -= 0.03
		if _rng.randf() < romance_chance:
			_create_romantic_partner()


func _create_romantic_partner() -> void:
	var names_data := _load_names()
	var lang := "pt_BR" if character.country == "BR" else "en"
	var lang_names: Dictionary = names_data.get(lang, {})
	var partner_gender := "female" if character.gender == "male" else "male"
	var name_list: Array = lang_names.get("male_first" if partner_gender == "male" else "female_first", ["Alex"])
	var last_names: Array = lang_names.get("last", ["Silva"])

	var partner := Relationship.new()
	partner.rel_type = Relationship.RelType.ROMANTIC
	partner.person_gender = partner_gender
	partner.person_name = name_list[_rng.randi_range(0, name_list.size() - 1)] + " " + last_names[_rng.randi_range(0, last_names.size() - 1)]
	partner.person_age = character.age + _rng.randi_range(-5, 5)
	partner.affection = _rng.randi_range(40, 70)
	partner.respect = _rng.randi_range(40, 70)
	partner.trust = _rng.randi_range(40, 70)
	character.relationships.append(partner)
	character.statistics["relationships_started"] += 1
	character.add_event_log("EVENT_MET_PARTNER", "social")


func try_marry() -> bool:
	for rel in character.relationships:
		if rel is Relationship and rel.rel_type == Relationship.RelType.ROMANTIC and rel.alive:
			if rel.get_overall() >= 60:
				rel.rel_type = Relationship.RelType.SPOUSE
				character.happiness = clampi(character.happiness + 15, 0, 100)
				character.add_event_log("EVENT_GOT_MARRIED", "family")
				return true
	return false


func try_have_child() -> bool:
	var has_spouse := false
	for rel in character.relationships:
		if rel is Relationship and rel.rel_type == Relationship.RelType.SPOUSE and rel.alive:
			has_spouse = true
			break
	if not has_spouse:
		return false
	if character.age < 20 or character.age > 50:
		return false

	var names_data := _load_names()
	var lang := "pt_BR" if character.country == "BR" else "en"
	var lang_names: Dictionary = names_data.get(lang, {})
	var child_gender: String = ["male", "female"][_rng.randi_range(0, 1)]
	var name_list: Array = lang_names.get("male_first" if child_gender == "male" else "female_first", ["Alex"])

	var child := Relationship.new()
	child.rel_type = Relationship.RelType.CHILD
	child.person_gender = child_gender
	child.person_name = name_list[_rng.randi_range(0, name_list.size() - 1)] + " " + character.last_name
	child.person_age = 0
	child.affection = _rng.randi_range(70, 95)
	child.respect = _rng.randi_range(50, 70)
	child.trust = _rng.randi_range(60, 85)
	character.relationships.append(child)
	character.happiness = clampi(character.happiness + 10, 0, 100)
	character.money -= 2000
	character.add_event_log("EVENT_HAD_CHILD", "family")
	return true


func _try_auto_career() -> void:
	var available := get_available_careers()
	if available.is_empty():
		return
	# Pick a random available career (weighted toward matching stats)
	var best_career: Dictionary = available[_rng.randi_range(0, available.size() - 1)]
	hire_career(best_career.get("id", ""))
