extends Control

## GameHUD — Main gameplay screen

@onready var char_name: Label = %CharName
@onready var age_phase: Label = %AgePhase
@onready var health_bar: ProgressBar = %"MainLayout/StatsContainer/HealthBar/Bar"
@onready var happiness_bar: ProgressBar = %"MainLayout/StatsContainer/HappinessBar/Bar"
@onready var money_label: Label = %"MainLayout/StatsContainer/MoneyBar/Value"
@onready var relations_bar: ProgressBar = %"MainLayout/StatsContainer/RelationsBar/Bar"
@onready var morality_bar: ProgressBar = %"MainLayout/StatsContainer/MoralityBar/Bar"
@onready var event_text: RichTextLabel = %EventText
@onready var btn_advance: Button = %BtnAdvanceYear
@onready var btn_social: Button = %BtnSocial
@onready var btn_family: Button = %BtnFamily
@onready var btn_school_work: Button = %BtnSchoolWork
@onready var btn_health: Button = %BtnHealth
@onready var btn_finance: Button = %BtnFinance
@onready var btn_crime: Button = %BtnCrime

var _event_popup_scene: PackedScene = preload("res://scenes/popups/EventPopup.tscn")


func _ready() -> void:
	_connect_signals()
	_update_display()
	_localize_buttons()

	# Process any pending events from game start
	_process_next_event()


func _connect_signals() -> void:
	btn_advance.pressed.connect(_on_advance_year)
	btn_social.pressed.connect(func(): _show_category_actions("social"))
	btn_family.pressed.connect(func(): _show_category_actions("family"))
	btn_school_work.pressed.connect(func(): _show_category_actions("school"))
	btn_health.pressed.connect(func(): _show_category_actions("health"))
	btn_finance.pressed.connect(func(): _show_category_actions("finance"))
	btn_crime.pressed.connect(func(): _show_category_actions("crime"))

	GameManager.character_died.connect(_on_character_died)
	GameManager.year_advanced.connect(_on_year_advanced)
	GameManager.phase_changed.connect(_on_phase_changed)


func _localize_buttons() -> void:
	btn_social.text = tr("SOCIAL")
	btn_family.text =tr("FAMILY")
	btn_health.text = tr("HEALTH")
	btn_finance.text = tr("FINANCE")
	btn_crime.text = tr("CRIME")
	btn_advance.text = tr("AGE_PLUS")

	# Update school/work label based on phase
	_update_school_work_label()


func _update_display() -> void:
	var c := GameManager.character
	if c == null:
		return

	char_name.text = c.get_full_name()
	age_phase.text = tr("AGE") + " " + str(c.age) + " · " + tr(c.get_phase_name()) + " · " + c.country

	# Stats
	_set_bar_safe("health", c.health)
	_set_bar_safe("happiness", c.happiness)
	_set_bar_safe("relations", c.get_relationship_average())
	_set_bar_safe("morality", c.morality)

	# Money display
	if money_label:
		if c.money >= 1_000_000:
			money_label.text = "$" + str(snappedf(c.money / 1_000_000.0, 0.1)) + "M"
		elif c.money >= 1_000:
			money_label.text = "$" + str(snappedf(c.money / 1_000.0, 0.1)) + "K"
		else:
			money_label.text = "$" + str(int(c.money))

	_update_school_work_label()
	_update_action_visibility()


func _set_bar_safe(bar_name: String, value: float) -> void:
	match bar_name:
		"health":
			if health_bar: health_bar.value = value
		"happiness":
			if happiness_bar: happiness_bar.value = value
		"relations":
			if relations_bar: relations_bar.value = value
		"morality":
			if morality_bar: morality_bar.value = value


func _update_school_work_label() -> void:
	var c := GameManager.character
	if c == null or btn_school_work == null:
		return
	match c.life_phase:
		Character.LifePhase.BABY, Character.LifePhase.CHILD:
			btn_school_work.text = tr("SCHOOL")
		Character.LifePhase.TEEN:
			btn_school_work.text = tr("SCHOOL_WORK")
		_:
			btn_school_work.text = tr("WORK")


func _update_action_visibility() -> void:
	var c := GameManager.character
	if c == null:
		return
	# Hide crime for babies and children
	if btn_crime:
		btn_crime.visible = c.age >= 13
	# Hide finance for babies
	if btn_finance:
		btn_finance.visible = c.age >= 8


func _on_advance_year() -> void:
	GameManager.advance_year()


func _on_year_advanced(_age: int) -> void:
	_update_display()
	_process_next_event()


func _on_phase_changed(_new_phase: Character.LifePhase) -> void:
	_update_display()


func _on_character_died(character: Character) -> void:
	get_tree().change_scene_to_file("res://scenes/screens/LifeSummary.tscn")


func _process_next_event() -> void:
	var event := GameManager.get_next_event()
	if event == null:
		# No more events; show idle text
		if event_text:
			event_text.text = tr("NO_EVENTS_THIS_YEAR")
		return

	# Show event text in the card
	if event_text:
		event_text.text = tr(event.text_key)

	# If event has choices, show popup
	if not event.choices.is_empty():
		_show_event_popup(event)


func _show_event_popup(event: EventData) -> void:
	var popup := _event_popup_scene.instantiate()
	popup.setup(event)
	popup.choice_made.connect(_on_event_choice_made.bind(event))
	add_child(popup)


func _on_event_choice_made(choice_index: int, event: EventData) -> void:
	GameManager.apply_event_choice(event, choice_index)
	_update_display()

	# Process next event if any
	if GameManager.has_pending_events():
		# Small delay for readability
		await get_tree().create_timer(0.3).timeout
		_process_next_event()


func _show_category_actions(category: String) -> void:
	# For now, trigger a random event from this category
	# TODO: Replace with proper action menus per category
	var event := EventManager.get_random_event(GameManager.character)
	if event and event.category == category:
		if event_text:
			event_text.text = tr(event.text_key)
		if not event.choices.is_empty():
			_show_event_popup(event)
