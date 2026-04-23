class_name Character
extends Resource

## Character data model — holds all state for one life

# === Identity ===
@export var first_name: String = ""
@export var last_name: String = ""
@export var gender: String = "male"  # "male", "female"
@export var country: String = "BR"
@export var birth_year: int = 2000
@export var age: int = 0
@export var alive: bool = true
@export var cause_of_death: String = ""

# === Life Phase ===
enum LifePhase { BABY, CHILD, TEEN, ADULT, ELDER }
@export var life_phase: LifePhase = LifePhase.BABY

# === Core Attributes (0–100) ===
@export var health: int = 80
@export var intelligence: int = 50
@export var charisma: int = 50
@export var appearance: int = 50
@export var temperament: int = 50  # low = aggressive, high = calm
@export var luck: int = 50

# === Dynamic Stats (0–100) ===
@export var happiness: int = 70
@export var morality: int = 50
@export var mental_stability: int = 70
@export var stress: int = 0       # 0 = calm, 100 = breakdown
@export var sanity: int = 100     # 0 = breakdown, 100 = healthy

# === Criminal Record ===
@export var criminal_record: bool = false

# === Fame ===
@export var fame: int = 0  # 0 = unknown, 100 = world-famous

# === Psychosocial & Early Development (0-100) ===
@export var attachment_profile: int = 50 # 0 = Insecure/Avoidant, 100 = Secure
@export var cognitive_development: int = 50 # Brain mapping during 0-2 years
@export var trauma: int = 0 # 0 = Healthy, 100 = Extreme PTSD/Trauma

# === Finances ===
@export var money: float = 0.0
@export var salary: float = 0.0
@export var debt: float = 0.0
@export var credit_score: int = 500  # 0–1000
@export var assets_value: float = 0.0

# === Social Class & Hidden Economy ===
enum SocialClass { LOW, MIDDLE, HIGH }
@export var social_class: SocialClass = SocialClass.MIDDLE
@export var family_hidden_wealth: float = 5000.0 # Renda dos pais/família que determina a vida da criança
@export var family_stress_level: float = 0.0 # 0 a 100. Quanto mais alto, maior risco de divórcio/violência
@export var family_sanity: float = 100.0 # Cai conforme problemas financeiros/ações ruins do bebê
@export var family_status: String = "Casados" # Casados, Divorciados, Órfão
@export var emotional_tags: Array = [] # Ex: ["Ressentido", "Mimado", "Violento"]

# === SISTEMA OCULTO 0-12 ANOS: STATUS PAIS E PETS ===
@export var parents_depressed: bool = false
@export var mother_luck: int = 50 # Determina se ajudam a mãe em crises de violência
@export var father_luck: int = 50
@export var mother_age: int = 25
@export var father_age: int = 27
@export var mother_health: int = 80
@export var father_health: int = 80
@export var mother_happiness: int = 70
@export var father_happiness: int = 70
@export var mother_fertility: int = 80 # Cai drasticamente com a idade > 35
@export var father_fertility: int = 80 # Cai com a idade > 40
@export var siblings_count: int = 0
@export var dead_siblings: int = 0
@export var pets: Array = [] # Elementos: {"name": "Rex", "type": "Dog", "affinity": 50, "depressed": false}

# === Talents ===
@export var talents: Dictionary = {}

# === Traits ===
@export var traits: Array[String] = []

# === Career ===
@export var current_career: String = ""  # career id or empty
@export var career_years: int = 0
@export var career_level: int = 0  # 0 = entry, 1 = mid, 2 = senior, 3 = executive

# === Education ===
enum Education { NONE, PRIMARY, SECONDARY, TECHNICAL, COLLEGE, POSTGRAD }
@export var education: Education = Education.NONE
@export var school_performance: int = 50  # 0–100

# === Relationships ===
@export var relationships: Array[Resource] = []

# === History ===
@export var event_log: Array[Dictionary] = []
# Each entry: { "age": int, "text_key": String, "category": String }

# === Anti-repetition ===
@export var seen_events: Array[String] = []

# === Inventory / Assets ===
@export var inventory: Array[Dictionary] = []

# === Seed ===
@export var world_seed: int = 0

# === Lifetime Statistics ===
@export var statistics: Dictionary = {
	"total_events": 0,
	"total_choices": 0,
	"max_money": 0.0,
	"min_money": 0.0,
	"careers_held": 0,
	"promotions": 0,
	"relationships_started": 0,
	"traits_gained": 0,
}

# === Computed Properties ===

func has_trait(trait_name: String) -> bool:
	return traits.has(trait_name)

func get_phase_name() -> String:
	match life_phase:
		LifePhase.BABY: return "BABY"
		LifePhase.CHILD: return "CHILD"
		LifePhase.TEEN: return "TEEN"
		LifePhase.ADULT: return "ADULT"
		LifePhase.ELDER: return "ELDER"
	return "UNKNOWN"

func get_full_name() -> String:
	return first_name + " " + last_name

func get_life_phase_for_age(a: int) -> LifePhase:
	if a <= 3:
		return LifePhase.BABY
	elif a <= 12:
		return LifePhase.CHILD
	elif a <= 17:
		return LifePhase.TEEN
	elif a <= 64:
		return LifePhase.ADULT
	else:
		return LifePhase.ELDER

func get_net_worth() -> float:
	return money + assets_value - debt

func get_relationship_average() -> float:
	if relationships.is_empty():
		return 0.0
	var total := 0.0
	for rel in relationships:
		if rel is Relationship:
			total += (rel.affection + rel.respect + rel.trust) / 3.0
	return total / relationships.size()

func add_event_log(text_key: String, category: String) -> void:
	event_log.append({
		"age": age,
		"text_key": text_key,
		"category": category
	})

func add_trait(trait_name: String) -> void:
	if not has_trait(trait_name):
		traits.append(trait_name)

func remove_trait(trait_name: String) -> void:
	traits.erase(trait_name)

func to_save_dict() -> Dictionary:
	var rel_dicts: Array[Dictionary] = []
	for rel in relationships:
		if rel is Relationship:
			rel_dicts.append(rel.to_save_dict())
	return {
		"first_name": first_name,
		"last_name": last_name,
		"gender": gender,
		"country": country,
		"birth_year": birth_year,
		"age": age,
		"alive": alive,
		"cause_of_death": cause_of_death,
		"life_phase": life_phase,
		"health": health,
		"intelligence": intelligence,
		"charisma": charisma,
		"appearance": appearance,
		"temperament": temperament,
		"luck": luck,
		"happiness": happiness,
		"morality": morality,
		"mental_stability": mental_stability,
		"attachment_profile": attachment_profile,
		"cognitive_development": cognitive_development,
		"trauma": trauma,
		"money": money,
		"salary": salary,
		"debt": debt,
		"credit_score": credit_score,
		"assets_value": assets_value,
		"inventory": inventory,
		"social_class": social_class,
		"traits": traits,
		"current_career": current_career,
		"career_years": career_years,
		"career_level": career_level,
		"education": education,
		"school_performance": school_performance,
		"relationships": rel_dicts,
		"event_log": event_log,
		"seen_events": seen_events,
		"world_seed": world_seed,
		"statistics": statistics
	}

static func from_save_dict(d: Dictionary) -> Character:
	var c := Character.new()
	c.first_name = d.get("first_name", "")
	c.last_name = d.get("last_name", "")
	c.gender = d.get("gender", "male")
	c.country = d.get("country", "BR")
	c.birth_year = d.get("birth_year", 2000)
	c.age = d.get("age", 0)
	c.alive = d.get("alive", true)
	c.cause_of_death = d.get("cause_of_death", "")
	c.life_phase = d.get("life_phase", LifePhase.BABY)
	c.health = d.get("health", 80)
	c.intelligence = d.get("intelligence", 50)
	c.charisma = d.get("charisma", 50)
	c.appearance = d.get("appearance", 50)
	c.temperament = d.get("temperament", 50)
	c.luck = d.get("luck", 50)
	c.happiness = d.get("happiness", 70)
	c.morality = d.get("morality", 50)
	c.mental_stability = d.get("mental_stability", 70)
	c.attachment_profile = d.get("attachment_profile", 50)
	c.cognitive_development = d.get("cognitive_development", 50)
	c.trauma = d.get("trauma", 0)
	c.money = d.get("money", 0.0)
	c.salary = d.get("salary", 0.0)
	c.debt = d.get("debt", 0.0)
	c.credit_score = d.get("credit_score", 500)
	c.assets_value = d.get("assets_value", 0.0)
	
	var inv_array: Array = d.get("inventory", [])
	c.inventory = []
	for i in inv_array:
		c.inventory.append(i as Dictionary)
		
	c.social_class = d.get("social_class", SocialClass.MIDDLE)
	c.traits = Array(d.get("traits", []), TYPE_STRING, "", null)
	c.current_career = d.get("current_career", "")
	c.career_years = d.get("career_years", 0)
	c.career_level = d.get("career_level", 0)
	c.education = d.get("education", Education.NONE)
	c.school_performance = d.get("school_performance", 50)
	c.event_log = Array(d.get("event_log", []), TYPE_DICTIONARY, "", null)
	c.seen_events = Array(d.get("seen_events", []), TYPE_STRING, "", null)
	c.world_seed = d.get("world_seed", 0)
	var saved_stats: Dictionary = d.get("statistics", {})
	for key in c.statistics:
		if saved_stats.has(key):
			c.statistics[key] = saved_stats[key]
	# Relationships loaded separately
	var rel_dicts: Array = d.get("relationships", [])
	for rd in rel_dicts:
		c.relationships.append(Relationship.from_save_dict(rd))
	return c
