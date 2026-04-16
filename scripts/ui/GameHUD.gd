extends Control

## GameHUD — Main gameplay screen (BitLife-style life log)

@onready var avatar_label: Label = %AvatarLabel
@onready var char_name: Label = %CharName
@onready var age_phase: Label = %AgePhase
@onready var health_bar: ProgressBar = %HealthBar
@onready var happiness_bar: ProgressBar = %HappinessBar
@onready var money_label: Label = %MoneyLabel
@onready var social_bar: ProgressBar = %SocialBar
@onready var morality_bar: ProgressBar = %MoralityBar
@onready var log_scroll: ScrollContainer = %LogScroll
@onready var log_entries: VBoxContainer = %LogEntries
@onready var btn_advance: Button = %BtnAdvanceYear
@onready var btn_social: Button = %BtnSocial
@onready var btn_family: Button = %BtnFamily
@onready var btn_school_work: Button = %BtnSchoolWork
@onready var btn_health: Button = %BtnHealth
@onready var btn_finance: Button = %BtnFinance
@onready var btn_crime: Button = %BtnCrime

var _event_popup_scene: PackedScene = preload("res://scenes/popups/EventPopup.tscn")
var _current_year_logged: int = -1


func _ready() -> void:
	_style_bars()
	_style_advance_button()
	_style_action_buttons()
	_connect_signals()
	_localize_buttons()
	_update_display()

	var start_age := 0
	if GameManager.character:
		start_age = GameManager.character.age
	_add_year_separator(start_age)
	_process_next_event()


# ── STYLING ──

func _style_bars() -> void:
	_color_bar(health_bar, ThemeSetup.COLOR_HEALTH)
	_color_bar(happiness_bar, ThemeSetup.COLOR_HAPPINESS)
	_color_bar(social_bar, ThemeSetup.COLOR_SOCIAL)
	_color_bar(morality_bar, ThemeSetup.COLOR_MORALITY)


func _color_bar(bar: ProgressBar, color: Color) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("fill", ThemeSetup.make_bar_fill(color))
	bar.add_theme_stylebox_override("background", ThemeSetup.make_bar_bg())


func _style_advance_button() -> void:
	if btn_advance == null:
		return
	var normal := ThemeSetup.make_flat_box(ThemeSetup.ACCENT_DARK, 16, 24, 14)
	var hover := ThemeSetup.make_flat_box(ThemeSetup.ACCENT, 16, 24, 14)
	var pressed := ThemeSetup.make_flat_box(ThemeSetup.ACCENT.darkened(0.15), 16, 24, 14)
	btn_advance.add_theme_stylebox_override("normal", normal)
	btn_advance.add_theme_stylebox_override("hover", hover)
	btn_advance.add_theme_stylebox_override("pressed", pressed)
	btn_advance.add_theme_font_size_override("font_size", 20)


func _style_action_buttons() -> void:
	var button_colors := {
		btn_social: Color("#1565C0"),
		btn_family: Color("#7B1FA2"),
		btn_school_work: Color("#00695C"),
		btn_health: Color("#C62828"),
		btn_finance: Color("#2E7D32"),
		btn_crime: Color("#37474F"),
	}
	for btn in button_colors:
		if btn == null:
			continue
		var base_color: Color = button_colors[btn]
		var normal := ThemeSetup.make_flat_box(base_color, 12, 12, 8)
		var hover := ThemeSetup.make_flat_box(base_color.lightened(0.15), 12, 12, 8)
		var pressed := ThemeSetup.make_flat_box(base_color.darkened(0.1), 12, 12, 8)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_font_size_override("font_size", 14)


# ── SIGNALS ──

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
	btn_social.text = "👥 " + tr("SOCIAL")
	btn_family.text = "👨‍👩‍👧 " + tr("FAMILY")
	btn_health.text = "❤️ " + tr("HEALTH")
	btn_finance.text = "💰 " + tr("FINANCE")
	btn_crime.text = "🔪 " + tr("CRIME")
	btn_advance.text = tr("AGE_PLUS")
	_update_school_work_label()


# ── DISPLAY ──

func _update_display() -> void:
	var c := GameManager.character
	if c == null:
		return

	# Header
	char_name.text = c.get_full_name()
	char_name.add_theme_font_size_override("font_size", 24)

	age_phase.text = tr("AGE") + " " + str(c.age) + " · " + tr(c.get_phase_name()) + " · " + c.country
	age_phase.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
	age_phase.add_theme_font_size_override("font_size", 14)

	# Avatar
	_update_avatar(c)

	# Stats
	if health_bar: health_bar.value = c.health
	if happiness_bar: happiness_bar.value = c.happiness
	if social_bar: social_bar.value = c.get_relationship_average()
	if morality_bar: morality_bar.value = c.morality

	# Money
	if money_label:
		money_label.add_theme_color_override("font_color", ThemeSetup.COLOR_MONEY)
		money_label.add_theme_font_size_override("font_size", 18)
		if c.money >= 1_000_000:
			money_label.text = "$ " + str(snappedf(c.money / 1_000_000.0, 0.1)) + "M"
		elif c.money >= 1_000:
			money_label.text = "$ " + str(snappedf(c.money / 1_000.0, 0.1)) + "K"
		else:
			money_label.text = "$ " + str(int(c.money))

	_update_school_work_label()
	_update_action_visibility()


func _update_avatar(c: Character) -> void:
	if avatar_label == null:
		return
	var emoji := "👶"
	match c.life_phase:
		Character.LifePhase.BABY:
			emoji = "👶"
		Character.LifePhase.CHILD:
			emoji = "🧒"
		Character.LifePhase.TEEN:
			emoji = "🧑" if c.gender == "male" else "👧"
		Character.LifePhase.ADULT:
			emoji = "👨" if c.gender == "male" else "👩"
		Character.LifePhase.ELDER:
			emoji = "👴" if c.gender == "male" else "👵"
	avatar_label.text = emoji


func _update_school_work_label() -> void:
	var c := GameManager.character
	if c == null or btn_school_work == null:
		return
	match c.life_phase:
		Character.LifePhase.BABY, Character.LifePhase.CHILD:
			btn_school_work.text = "📚 " + tr("SCHOOL")
		Character.LifePhase.TEEN:
			btn_school_work.text = "📚 " + tr("SCHOOL_WORK")
		_:
			btn_school_work.text = "💼 " + tr("WORK")


func _update_action_visibility() -> void:
	var c := GameManager.character
	if c == null:
		return
	if btn_crime:
		btn_crime.visible = c.age >= 13
	if btn_finance:
		btn_finance.visible = c.age >= 8


# ── LIFE LOG ──

func _add_year_separator(age: int) -> void:
	if _current_year_logged == age:
		return
	_current_year_logged = age

	var sep := Label.new()
	sep.text = "── " + tr("AGE") + " " + str(age) + " ──"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", 13)
	sep.add_theme_color_override("font_color", ThemeSetup.PRIMARY)
	log_entries.add_child(sep)


func _add_log_entry(text: String, icon: String = "📌") -> void:
	var entry_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeSetup.BG_CARD_LIGHT
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	entry_panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = icon + "  " + text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	entry_panel.add_child(lbl)

	log_entries.add_child(entry_panel)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if log_scroll:
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


# ── EVENT HANDLING ──

func _on_advance_year() -> void:
	GameManager.advance_year()


func _on_year_advanced(age: int) -> void:
	_add_year_separator(age)
	_update_display()
	_process_next_event()


func _on_phase_changed(_new_phase: Character.LifePhase) -> void:
	_update_display()


func _on_character_died(_character: Character) -> void:
	get_tree().change_scene_to_file("res://scenes/screens/LifeSummary.tscn")


func _process_next_event() -> void:
	var event := GameManager.get_next_event()
	if event == null:
		_add_log_entry(tr("NO_EVENTS_THIS_YEAR"), "🌙")
		return

	_add_log_entry(tr(event.text_key), _get_event_icon(event))

	if not event.choices.is_empty():
		_show_event_popup(event)


func _get_event_icon(event: EventData) -> String:
	var key := event.text_key.to_lower()
	if "sick" in key or "health" in key or "cold" in key:
		return "🤒"
	elif "school" in key or "test" in key or "exam" in key:
		return "📚"
	elif "friend" in key or "social" in key or "crush" in key:
		return "💬"
	elif "money" in key or "job" in key or "business" in key or "promotion" in key:
		return "💼"
	elif "crime" in key or "shoplifting" in key or "fraud" in key:
		return "⚠️"
	elif "baby" in key or "crawl" in key or "tantrum" in key or "funny" in key:
		return "👶"
	elif "marry" in key or "marriage" in key or "divorce" in key:
		return "💍"
	elif "pet" in key or "animal" in key:
		return "🐾"
	elif "party" in key:
		return "🎉"
	elif "drug" in key:
		return "💊"
	elif "die" in key or "death" in key:
		return "⚰️"
	elif "retire" in key:
		return "🏖️"
	elif "hobby" in key:
		return "🎨"
	elif "bully" in key:
		return "😠"
	elif "talent" in key or "sport" in key:
		return "⭐"
	elif "parent" in key or "family" in key:
		return "👨‍👩‍👧"
	else:
		return "📌"


func _show_event_popup(event: EventData) -> void:
	var popup := _event_popup_scene.instantiate()
	popup.setup(event)
	popup.choice_made.connect(_on_event_choice_made.bind(event))
	add_child(popup)


func _on_event_choice_made(choice_index: int, event: EventData) -> void:
	# Log what the player chose
	if choice_index < event.choices.size():
		var choice: Dictionary = event.choices[choice_index]
		var choice_text := tr(choice.get("text_key", ""))
		if choice_text != "" and choice_text != choice.get("text_key", ""):
			_add_log_entry(choice_text, "👉")

	GameManager.apply_event_choice(event, choice_index)
	_update_display()

	if GameManager.has_pending_events():
		await get_tree().create_timer(0.3).timeout
		_process_next_event()


func _show_category_actions(category: String) -> void:
	# Map button categories to event categories
	var event_categories: Array[String] = []
	match category:
		"social": event_categories = ["social"]
		"family": event_categories = ["family"]
		"school": event_categories = ["school"]
		"health": event_categories = ["health"]
		"finance": event_categories = ["finance", "career"]
		"crime": event_categories = ["crime"]

	var event: EventData = null
	for cat in event_categories:
		event = EventManager.get_random_event_by_category(GameManager.character, cat)
		if event != null:
			break

	if event == null:
		_add_log_entry(tr("NO_EVENTS_AVAILABLE"), "🚫")
		return

	GameManager.character.seen_events.append(event.id)
	_add_log_entry(tr(event.text_key), _get_event_icon(event))
	if not event.choices.is_empty():
		_show_event_popup(event)
