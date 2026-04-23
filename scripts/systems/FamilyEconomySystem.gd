class_name FamilyEconomySystem extends RefCounted

static func process(character: Character, rng: RandomNumberGenerator, event_queue: Array) -> void:
	if not character or character.age >= 18:
		return
	
	# Recuperação natural de stress com o tempo
	if character.family_status == "Casados":
		character.family_stress_level = max(0, character.family_stress_level - 5)
		
		# Cura e Terapia (Se a saúde mental melhorar e stress baixar muito, pais saem da depressão)
		if character.parents_depressed and character.family_stress_level < 20:
			if rng.randf() < 0.2: # 20% de chance no ano de superarem lutos/problemas
				character.parents_depressed = false
				character.family_stress_level = 0
				character.mother_happiness = min(100, character.mother_happiness + 30)
				_trigger_forced_event(event_queue, "family_healed_depression")
		
		# Prosperidade Profissional Oculta (Família Feliz = Promoções e mais Dinheiro)
		if character.family_stress_level < 10 and not character.parents_depressed:
			if rng.randf() < 0.1: # 10% de chance do pai ou mãe ser promovido
				character.family_hidden_wealth *= 1.3 # Renda da casa sobe 30%
				character.mother_happiness = min(100, character.mother_happiness + 20)
				character.emotional_tags.append("Familia Prospera")
				_trigger_forced_event(event_queue, "family_parent_promotion")
		
		# Envelhece os pais
		character.mother_age += 1
		character.father_age += 1
		
		# Curva de Fertilidade Realista
		if character.mother_age > 35:
			character.mother_fertility = max(0, character.mother_fertility - rng.randi_range(3, 8))
		if character.father_age > 40:
			character.father_fertility = max(0, character.father_fertility - rng.randi_range(1, 4))
		
		# ========================================================
		# GRAVIDEZ, INFERTILIDADE E PERDA (Depressão ou Irmãos)
		# ========================================================
		var wants_baby = false
		if character.mother_happiness > 40 and character.family_stress_level < 50:
			wants_baby = rng.randf() < 0.15 # 15% de chance de querer engravidar no ano
			
		if wants_baby and not character.parents_depressed:
			# Chance Biológica = Média da fertilidade dos dois convertida em decimal x saude
			var bio_chance = ((character.mother_fertility + character.father_fertility) / 200.0) * (character.mother_health / 100.0)
			
			if rng.randf() < bio_chance:
				# Engravidou! Calcula Risco de Aborto Espontâneo baseado em stress, saude e idade
				var miscarriage_risk = 0.10 
				if character.mother_age >= 35: miscarriage_risk += 0.15 # Idade avançada
				if character.mother_health < 50: miscarriage_risk += 0.15 # Baixa saúde
				if character.family_stress_level > 60: miscarriage_risk += 0.10 # Ambiente estressante
				
				if rng.randf() < miscarriage_risk:
					# Aborto Espontâneo Realista
					character.parents_depressed = true
					character.mother_happiness -= 40 # Cai drasticamente
					character.mother_health -= 15
					character.family_stress_level += 40 # Abalados fortemente
					character.dead_siblings += 1
					_trigger_forced_event(event_queue, "family_miscarriage")
				else:
					# Nascimento Saudável
					character.siblings_count += 1
					character.family_stress_level += 20 # Trabalho natural de bebê novo
					character.mother_happiness = min(100, character.mother_happiness + 15)
					_trigger_forced_event(event_queue, "family_new_sibling")
			else:
				# Tentativa Falha (Se for culpa de idade, gera estresse e frustração)
				if character.mother_age >= 35 or character.father_age >= 40:
					character.mother_happiness -= 5
					character.parents_depressed = rng.randf() < 0.05 # Ligeira chance de depressão por infertilidade
					character.family_stress_level += 5
					
	# Consequências econômicas sentidas na infância
	if character.family_hidden_wealth < 1000 and character.age >= 6:
		if rng.randf() < 0.4:
			_trigger_forced_event(event_queue, "family_poverty_work")

	# === SPRINT 5: BUTTERFLY EFFECT OCULTO ===

	# Estresse alto → risco de violência doméstica
	if character.family_stress_level >= 80 and character.age <= 12:
		if rng.randf() < 0.25:
			_trigger_forced_event(event_queue, "family_domestic_violence")
			character.trauma = clampi(character.trauma + 20, 0, 100)
			character.emotional_tags.append("trauma_infancia")
			if not character.emotional_tags.has("ansioso"):
				character.emotional_tags.append("ansioso")

	# Riqueza cai → mudança de escola / perda da casa
	if character.family_hidden_wealth < 0 and character.age >= 6:
		_trigger_forced_event(event_queue, "family_lost_home")
		character.family_hidden_wealth = 500.0  # Reset mínimo para não gerar loop

	# Família divorciada → renda cai 50% se mãe não trabalha
	if character.family_status == "Divorciados":
		character.family_hidden_wealth *= 0.5
		if character.family_stress_level < 60:
			character.family_stress_level += 10.0

	# Pais deprimidos → negligência
	if character.parents_depressed and character.age <= 12:
		if rng.randf() < 0.30:
			_trigger_forced_event(event_queue, "family_neglect")
			character.attachment_profile = clampi(character.attachment_profile - 10, 0, 100)

	# Stress adulto: aplica nas próprias stats do personagem se adulto
	if character.age >= 18:
		var stress_gain := 0
		if character.debt > 10000: stress_gain += 5
		if character.salary < 1000: stress_gain += 5
		if character.relationships.is_empty(): stress_gain += 3
		character.stress = clampi(character.stress + stress_gain, 0, 100)
		# Sanidade cai com stress crônico
		if character.stress >= 70:
			character.sanity = clampi(character.sanity - 2, 0, 100)
		elif character.stress <= 20:
			character.sanity = clampi(character.sanity + 1, 0, 100)
			character.stress = clampi(character.stress - 3, 0, 100)


static func _trigger_forced_event(event_queue: Array, event_id: String) -> void:
	var ev = EventManager.get_event_by_id(event_id)
	if ev:
		event_queue.append(ev)
