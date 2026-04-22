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

static func _trigger_forced_event(event_queue: Array, event_id: String) -> void:
	var ev = EventManager.get_event_by_id(event_id)
	if ev:
		event_queue.append(ev)
