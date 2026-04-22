class_name BabyPhaseSystem extends RefCounted

static func process(character: Character, rng: RandomNumberGenerator, event_queue: Array) -> void:
	if not character or character.age >= 18:
		return
		
	# Chance de adoção de pet invisível na família se não tiver
	if character.pets.size() == 0 and rng.randf() < 0.05:
		var nomes_pet = ["Rex", "Toby", "Luna", "Mel", "Bolinha"]
		character.pets.append({"name": nomes_pet[rng.randi() % nomes_pet.size()], "type": "Dog", "affinity": 50, "depressed": false})
		_trigger_forced_event(event_queue, "family_adopted_pet")
		
	# EFEITO BORBOLETA POSITIVO (Saúde, Paz e Sucesso) através do pet
	if character.family_status == "Casados" and character.pets.size() > 0 and not character.pets[0].get("depressed", false):
		character.family_stress_level = max(0, character.family_stress_level - 10)
		character.mother_happiness = min(100, character.mother_happiness + 5)
		character.father_happiness = min(100, character.father_happiness + 5)
		
	# ADOÇÃO: Pai/Mãe solo sob estresse extremo pode colocar o bebê para adoção
	if character.family_status in ["Pai Solo", "Mãe Solo"]:
		var solo_stress := character.family_stress_level
		var solo_happiness: int
		if character.family_status == "Pai Solo":
			solo_happiness = character.father_happiness
		else:
			solo_happiness = character.mother_happiness
		# Quanto maior o estresse e menor a felicidade, maior a chance
		if solo_stress >= 70 and solo_happiness <= 30 and character.age <= 2:
			var adoption_chance := (solo_stress - 70) * 0.008 + (30 - solo_happiness) * 0.005
			if rng.randf() < adoption_chance:
				character.emotional_tags.append("Adotado")
				character.trauma = min(100, character.trauma + 40)
				character.happiness = max(0, character.happiness - 30)
				character.family_status = "Adotado"
				_trigger_forced_event(event_queue, "baby_put_for_adoption")
				return  # Sai cedo — fim do processamento desta fase

	# CONSEQÜÊNCIAS GRAVES DOS PAIS (IDADE 0-2 e além)
	if character.family_status == "Casados" and character.family_stress_level >= 80:
		# Há chance de Agressão Doméstica
		if rng.randf() < 0.15:
			if character.mother_luck > 75: # Mãe deu a sorte de alguém ajudar
				_trigger_forced_event(event_queue, "family_abuse_extreme_saved")
				character.family_status = "Divorciados" # Menos pior que morte
			else: # Sem Sorte = Tragédia Total
				_trigger_forced_event(event_queue, "family_abuse_extreme_arrest")
				character.family_status = "Pai Preso"
				# Piora financeira pela perda do provedor e trauma
				character.family_hidden_wealth *= 0.3
				character.trauma = min(100, character.trauma + 50)
				if character.pets.size() > 0:
					character.pets[0]["depressed"] = true
		# Há chance de Divórcio
		elif rng.randf() < 0.3:
			_trigger_forced_event(event_queue, "family_divorce_stress")
			character.family_status = "Divorciados"
			character.emotional_tags.append("Lares Separados")
			character.family_hidden_wealth *= 0.5
			
	# ACIDENTES DO BEBÊ (Idades 0 a 3), TERAPIAS E CUIDADOS
	if character.age <= 3:
		# Doenças da Infância e Qualidade de Vida (Alimentação/Cólica/Fraldas)
		var sickness_chance = 0.10
		if character.family_hidden_wealth < 2000:
			sickness_chance = 0.35 # Leite de pior qualidade, menos higiene, cólicas extremas
		elif character.family_hidden_wealth > 20000:
			sickness_chance = 0.05 # Tudo premium, dificil pegar infecções
		
		if rng.randf() < sickness_chance:
			if character.family_hidden_wealth < 2000:
				character.health = max(0, character.health - rng.randi_range(10, 20)) # Cólicas dolorosas, diarreia
				character.family_stress_level += 20 # Choro constante por dor agrava a casa
				_trigger_forced_event(event_queue, "baby_poor_health_colic")
			else:
				character.health = max(0, character.health - rng.randi_range(5, 10)) # Apenas um resfriado leve
				character.family_stress_level += 5
				_trigger_forced_event(event_queue, "baby_rich_health_cold")

		# Acidente de Azar: Queda do Berço, engasgar, etc.
		var acidente_chance = 0.05
		if character.luck < 30: acidente_chance = 0.15 # Muito azarado
		elif character.luck > 70: acidente_chance = 0.01 # Pura Sorte
		
		if rng.randf() < acidente_chance:
			character.health = max(0, character.health - rng.randi_range(10, 30))
			character.family_stress_level += 25 # Pais entram em panico e estresse de culpa
			character.mother_happiness = max(0, character.mother_happiness - 10)
			
			# Socorro Médico Oculto (Depende do Dinheiro da Família)
			if character.family_hidden_wealth >= 5000:
				character.family_hidden_wealth -= 1000 # Pais pagaram médico particular / hospital bom
				character.health = min(100, character.health + rng.randi_range(15, 30)) # Curado sem sequelas
				_trigger_forced_event(event_queue, "baby_random_accident_cured")
			else:
				# Pode ir pro postinho ou SUS, com chance de não resolver direito
				if character.mother_luck < 50:
					character.trauma += 10
				_trigger_forced_event(event_queue, "baby_random_accident_poor")
			
	# Terapias e Intervenções Profissionais Passivas (Bancadas Pelos Pais)
	if character.family_hidden_wealth >= 3000:
		# Terapia Infantil
		if character.trauma > 30 and character.age > 2:
			if rng.randf() < 0.3: # Pais percebem que você não tá normal e bancam psicólogo
				character.family_hidden_wealth -= 500
				character.trauma = max(0, character.trauma - 20)
				_trigger_forced_event(event_queue, "parents_paid_therapy_child")
				
		# Terapia de Casal
		if character.family_status == "Casados" and character.family_stress_level > 60 and character.family_stress_level < 80:
			if rng.randf() < 0.25: # Em vias de se odiarem, mas tentam salvar (Terapia de Casal)
				character.family_hidden_wealth -= 800
				character.family_stress_level = max(0, character.family_stress_level - 40)
				character.mother_happiness += 10
				character.father_happiness += 10
				_trigger_forced_event(event_queue, "parents_couple_therapy")

	# LOGICA GERAL DE PETS (Travessura x Raiva x Adestramento)
	if character.pets.size() > 0:
		for i in range(character.pets.size()):
			var pet = character.pets[i]
			
			# O animal é passível de negligência gerada de forma independente e aleatória
			var care_penalty = 0
			if rng.randf() < 0.15: care_penalty += 10 # Dia que esqueceram de botar comida direito
			if rng.randf() < 0.20: care_penalty += 15 # Falta de passeios
			
			pet["affinity"] = max(0, pet.get("affinity", 50) - roundi(care_penalty / 2.0)) # Negligência baixa a afinidade lentamente

			var pet_agressivo = pet.get("depressed", false) or pet.get("affinity", 50) < 30

			# Chance Passiva de Travessura (Destruir móveis, fugir de casa para a rua e voltar sujo)
			if rng.randf() < 0.10 or (rng.randf() < 0.30 and care_penalty > 10): 
				character.family_stress_level += rng.randi_range(5, 15)
				_trigger_forced_event(event_queue, "pet_mischief_mess") # Animal aprontou e causou stress
				
				# Contramedida Natural dos Pais Ricos para um cão travesso = ADESTRADOR
				if character.family_hidden_wealth >= 2000 and rng.randf() < 0.1:
					character.family_hidden_wealth -= 600
					pet["affinity"] = 80 # Adestrador conserta comportamento
					pet["depressed"] = false
					_trigger_forced_event(event_queue, "pet_trainer_hired")
				
			# O animal pode, ao invés de só travessura, ATACAR se as condições da casa estiverem destrutivas
			if pet_agressivo:
				if rng.randf() < 0.05: # 5% de chance do cachorro/gato morder/atacar agressivamente
					character.health = max(0, character.health - rng.randi_range(10, 40))
					character.trauma = min(100, character.trauma + 30) # Ganha trauma
					character.family_stress_level += 30
					
					if rng.randf() < 0.5: # 50% de chance da família doar o gato/cão depois do ataque
						character.pets.remove_at(i)
						_trigger_forced_event(event_queue, "pet_attacked_and_donated")
						break # Sai do loop se doou o bicho
					else:
						_trigger_forced_event(event_queue, "pet_attacked_retained")

static func _trigger_forced_event(event_queue: Array, event_id: String) -> void:
	var ev = EventManager.get_event_by_id(event_id)
	if ev:
		event_queue.append(ev)
