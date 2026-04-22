class_name CharacterGenerator
extends RefCounted

static var _names_cache: Dictionary = {}

static func generate_character(seed_value: int) -> Character:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var c := Character.new()
	c.world_seed = seed_value

	# Use sub-agent for name generation (loaded from JSON)
	var names_data := _load_names()
	
	var is_preset = rng.randf() < 0.05
	
	if is_preset:
		var presets = [
			{"fn":"Liana", "ln":"Ross", "g":"female", "co":"US", "ts":{"music":1.5}, "cha":95, "app":85, "int":60},
			{"fn":"Karisson", "ln":"Ford", "g":"male", "co":"US", "ts":{"acting":1.5}, "cha":90, "app":80, "int":70},
			{"fn":"Alberta", "ln":"Monteclaro", "g":"female", "co":"BR", "ts":{"science":1.5}, "cha":50, "app":60, "int":95},
			{"fn":"Juliana", "ln":"Picos", "g":"female", "co":"BR", "ts":{"business":1.5}, "cha":95, "app":85, "int":75}
		]
		var p = presets[rng.randi_range(0, presets.size() - 1)]
		c.first_name = p["fn"]
		c.last_name = p["ln"]
		c.gender = p["g"]
		c.country = p["co"]
		c.health = clampi(rng.randi_range(70, 100), 0, 100)
		c.intelligence = clampi(p["int"] + rng.randi_range(-5, 5), 0, 100)
		c.charisma = clampi(p["cha"] + rng.randi_range(-5, 5), 0, 100)
		c.appearance = clampi(p["app"] + rng.randi_range(-5, 5), 0, 100)
		c.temperament = clampi(rng.randi_range(40, 80), 0, 100)
		c.luck = clampi(rng.randi_range(70, 100), 0, 100)
		c.talents = p["ts"]
	else:
		var country: String = ["BR", "US"][rng.randi_range(0, 1)]
		c.country = country
		var gender: String = ["male", "female"][rng.randi_range(0, 1)]
		c.gender = gender

		var lang := "pt_BR" if country == "BR" else "en"
		var gender_key := "male_first" if gender == "male" else "female_first"

		if names_data.has(lang):
			var lang_names: Dictionary = names_data[lang]
			var first_names: Array = lang_names.get(gender_key, ["Alex"])
			var last_names: Array = lang_names.get("last", ["Silva"])
			c.first_name = first_names[rng.randi_range(0, first_names.size() - 1)]
			c.last_name = last_names[rng.randi_range(0, last_names.size() - 1)]
		else:
			c.first_name = "Alex"
			c.last_name = "Smith"

		# Attributes with variance
		c.health = clampi(rng.randi_range(60, 100), 0, 100)
		c.intelligence = clampi(rng.randi_range(20, 80), 0, 100)
		c.charisma = clampi(rng.randi_range(20, 80), 0, 100)
		c.appearance = clampi(rng.randi_range(20, 80), 0, 100)
		c.temperament = clampi(rng.randi_range(20, 80), 0, 100)
		c.luck = clampi(rng.randi_range(10, 90), 0, 100)
		
		# Assign random talents
		var available_talents = ["music", "sports", "science", "writing", "acting", "business", "art", "social"]
		var num_talents = rng.randi_range(1, 2)
		for _i in range(num_talents):
			var t = available_talents[rng.randi_range(0, available_talents.size() - 1)]
			c.talents[t] = rng.randf_range(1.1, 1.5)

	c.happiness = clampi(rng.randi_range(50, 90), 0, 100)
	c.morality = 50
	c.mental_stability = clampi(rng.randi_range(50, 85), 0, 100)
	c.attachment_profile = 50
	c.cognitive_development = 50
	c.trauma = 0

	# === INIT SISTEMA OCULTO 0-12 ANOS: PAIS REALISTAS ===
	# Idades mais comuns de primeiro filho
	var is_teen_pregnancy = rng.randf() < 0.05
	if is_teen_pregnancy:
		c.mother_age = rng.randi_range(16, 19)
		c.father_age = rng.randi_range(16, 21)
	else:
		c.mother_age = rng.randi_range(20, 39)
		c.father_age = rng.randi_range(20, 45)
		
	# Mães mais velhas tendem a ter fertilidade reduzida desde o começo e mais dinheiro
	c.mother_fertility = clampi(100 - (max(0, c.mother_age - 30) * 3), 10, 100)
	c.father_fertility = clampi(100 - (max(0, c.father_age - 35) * 2), 10, 100)
	
	# Saúde emocional e biológica
	c.mother_health = clampi(rng.randi_range(50, 100) - max(0, c.mother_age-35), 0, 100)
	c.father_health = clampi(rng.randi_range(50, 100) - max(0, c.father_age-40), 0, 100)
	c.mother_happiness = clampi(rng.randi_range(40, 90), 0, 100)
	c.father_happiness = clampi(rng.randi_range(40, 90), 0, 100)
	c.parents_depressed = rng.randf() < 0.1 # 10% de já nascerem com depressão pós-parto/geral
	c.pets = []
	
	# Social class based on luck
	if c.luck > 70:
		c.social_class = Character.SocialClass.HIGH
		c.money = 0.0
		c.family_hidden_wealth = rng.randf_range(50000, 200000)
		c.family_stress_level = rng.randf_range(0, 20)
	elif c.luck > 35:
		c.social_class = Character.SocialClass.MIDDLE
		c.money = 0.0
		c.family_hidden_wealth = rng.randf_range(5000, 50000)
		c.family_stress_level = rng.randf_range(10, 40)
	else:
		c.social_class = Character.SocialClass.LOW
		c.money = 0.0
		c.family_hidden_wealth = rng.randf_range(0, 5000)
		c.family_stress_level = rng.randf_range(30, 80) # Pobres nascem mais estressados

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
	var num_traits := rng.randi_range(1, 2)
	var available := all_traits.duplicate()
	for i in num_traits:
		if available.is_empty():
			break
		var idx := rng.randi_range(0, available.size() - 1)
		c.traits.append(available[idx])
		available.remove_at(idx)

	# Generate family
	_generate_family(c, rng)

	c.birth_year = 2026 - c.age  # current year
	c.age = 0
	c.life_phase = Character.LifePhase.BABY

	return c


static func generate_custom_character(config: Dictionary, seed_value: int) -> Character:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var c := Character.new()
	c.world_seed = seed_value

	c.first_name = config.get("first_name", "Alex")
	c.last_name = config.get("last_name", "Silva")
	c.gender = config.get("gender", "male")
	c.country = config.get("country", "BR")

	# Attributes from config
	c.health = clampi(config.get("health", 50), 0, 100)
	c.intelligence = clampi(config.get("intelligence", 50), 0, 100)
	c.charisma = clampi(config.get("charisma", 50), 0, 100)
	c.appearance = clampi(config.get("appearance", 50), 0, 100)
	c.temperament = clampi(config.get("temperament", 50), 0, 100)
	c.luck = clampi(config.get("luck", 50), 0, 100)
	c.happiness = clampi(rng.randi_range(50, 90), 0, 100)
	c.morality = 50
	c.mental_stability = clampi(rng.randi_range(50, 85), 0, 100)
	c.attachment_profile = 50
	c.cognitive_development = 50
	c.trauma = 0

	# Social class from config
	var social_class_idx: int = config.get("social_class", 1)
	match social_class_idx:
		0:
			c.social_class = Character.SocialClass.LOW
			c.money = rng.randf_range(0, 5000)
		1:
			c.social_class = Character.SocialClass.MIDDLE
			c.money = rng.randf_range(5000, 50000)
		_:
			c.social_class = Character.SocialClass.HIGH
			c.money = rng.randf_range(50000, 200000)

	# Initial traits (1–2)
	var all_traits: Array[String] = [
		"introvert", "extrovert", "brave", "creative",
		"lazy", "athletic", "bookworm", "anxious",
		"charismatic", "compassionate", "ambitious", "romantic",
		"hardworking", "rebel", "sensitive", "optimistic",
		"pessimistic", "lucky", "unlucky", "genius",
		"clumsy", "beautiful", "funny", "calm",
		"stubborn", "generous", "honest", "risk_taker"
	]
	var num_traits := rng.randi_range(1, 2)
	var available := all_traits.duplicate()
	for i in num_traits:
		if available.is_empty():
			break
		var idx := rng.randi_range(0, available.size() - 1)
		c.traits.append(available[idx])
		available.remove_at(idx)

	# Generate family with custom settings
	var parents_mode: int = config.get("parents", 0)
	var sibling_count: int = config.get("siblings", 0)
	_generate_custom_family(c, parents_mode, sibling_count, rng)

	# Set family_status based on parent configuration
	match parents_mode:
		0: c.family_status = "Casados"
		1: c.family_status = "Pai Solo"
		2: c.family_status = "Mãe Solo"
		3: c.family_status = "Órfão"

	c.birth_year = 2026
	c.age = 0
	c.life_phase = Character.LifePhase.BABY

	return c


static func _generate_custom_family(c: Character, parents_mode: int, sibling_count: int, rng: RandomNumberGenerator) -> void:
	var names_data := _load_names()
	var lang := "pt_BR" if c.country == "BR" else "en"
	var lang_names: Dictionary = names_data.get(lang, {})
	var male_names: Array = lang_names.get("male_first", ["Carlos"])
	var female_names: Array = lang_names.get("female_first", ["Maria"])
	var last_names: Array = lang_names.get("last", [c.last_name])

	# parents_mode: 0=both, 1=father_only, 2=mother_only, 3=orphan
	if parents_mode == 0:
		# Both parents
		var mother := Relationship.new()
		mother.rel_type = Relationship.RelType.MOTHER
		mother.person_name = female_names[rng.randi_range(0, female_names.size() - 1)] + " " + last_names[rng.randi_range(0, last_names.size() - 1)]
		mother.person_age = rng.randi_range(20, 38)
		mother.person_gender = "female"
		mother.affection = rng.randi_range(50, 95)
		mother.respect = rng.randi_range(40, 80)
		mother.trust = rng.randi_range(50, 90)
		c.relationships.append(mother)

		var father := Relationship.new()
		father.rel_type = Relationship.RelType.FATHER
		father.person_name = male_names[rng.randi_range(0, male_names.size() - 1)] + " " + c.last_name
		father.person_age = rng.randi_range(22, 40)
		father.person_gender = "male"
		father.affection = rng.randi_range(40, 90)
		father.respect = rng.randi_range(40, 80)
		father.trust = rng.randi_range(40, 85)
		c.relationships.append(father)
	elif parents_mode == 1:
		# Father only
		var father := Relationship.new()
		father.rel_type = Relationship.RelType.FATHER
		father.person_name = male_names[rng.randi_range(0, male_names.size() - 1)] + " " + c.last_name
		father.person_age = rng.randi_range(22, 40)
		father.person_gender = "male"
		father.affection = rng.randi_range(50, 95)
		father.respect = rng.randi_range(40, 80)
		father.trust = rng.randi_range(50, 90)
		c.relationships.append(father)
	elif parents_mode == 2:
		# Mother only
		var mother := Relationship.new()
		mother.rel_type = Relationship.RelType.MOTHER
		mother.person_name = female_names[rng.randi_range(0, female_names.size() - 1)] + " " + last_names[rng.randi_range(0, last_names.size() - 1)]
		mother.person_age = rng.randi_range(20, 38)
		mother.person_gender = "female"
		mother.affection = rng.randi_range(50, 95)
		mother.respect = rng.randi_range(40, 80)
		mother.trust = rng.randi_range(50, 90)
		c.relationships.append(mother)
	# parents_mode == 3: orphan — no parents

	# Siblings
	for i in sibling_count:
		var sib := Relationship.new()
		sib.rel_type = Relationship.RelType.SIBLING
		var sib_gender: String = ["male", "female"][rng.randi_range(0, 1)]
		sib.person_gender = sib_gender
		var sib_names: Array = male_names if sib_gender == "male" else female_names
		sib.person_name = sib_names[rng.randi_range(0, sib_names.size() - 1)] + " " + c.last_name
		sib.person_age = rng.randi_range(1, 15)
		sib.affection = rng.randi_range(30, 80)
		sib.respect = rng.randi_range(30, 70)
		sib.trust = rng.randi_range(30, 75)
		if parents_mode == 3:
			sib.context = "orphanage"
		c.relationships.append(sib)


static func _generate_family(c: Character, rng: RandomNumberGenerator) -> void:
	var names_data := _load_names()
	var lang := "pt_BR" if c.country == "BR" else "en"
	var lang_names: Dictionary = names_data.get(lang, {})
	var male_names: Array = lang_names.get("male_first", ["Carlos"])
	var female_names: Array = lang_names.get("female_first", ["Maria"])
	var last_names: Array = lang_names.get("last", [c.last_name])

	# Father
	var father := Relationship.new()
	father.rel_type = Relationship.RelType.FATHER
	father.person_name = male_names[rng.randi_range(0, male_names.size() - 1)] + " " + c.last_name
	father.person_age = rng.randi_range(22, 40)
	father.person_gender = "male"
	father.affection = rng.randi_range(40, 90)
	father.respect = rng.randi_range(40, 80)
	father.trust = rng.randi_range(40, 85)
	c.relationships.append(father)

	# Mother
	var mother := Relationship.new()
	mother.rel_type = Relationship.RelType.MOTHER
	var mother_last: String = last_names[rng.randi_range(0, last_names.size() - 1)]
	mother.person_name = female_names[rng.randi_range(0, female_names.size() - 1)] + " " + mother_last
	mother.person_age = rng.randi_range(20, 38)
	mother.person_gender = "female"
	mother.affection = rng.randi_range(50, 95)
	mother.respect = rng.randi_range(40, 80)
	mother.trust = rng.randi_range(50, 90)
	c.relationships.append(mother)

	# Siblings (0–3)
	var num_siblings := rng.randi_range(0, 3)
	for i in num_siblings:
		var sib := Relationship.new()
		sib.rel_type = Relationship.RelType.SIBLING
		var sib_gender: String = ["male", "female"][rng.randi_range(0, 1)] as String
		sib.person_gender = sib_gender
		var sib_names: Array = male_names if sib_gender == "male" else female_names
		sib.person_name = sib_names[rng.randi_range(0, sib_names.size() - 1)] + " " + c.last_name
		sib.person_age = rng.randi_range(0, 15)
		sib.affection = rng.randi_range(30, 80)
		sib.respect = rng.randi_range(30, 70)
		sib.trust = rng.randi_range(30, 75)
		c.relationships.append(sib)


static func _load_names() -> Dictionary:
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
