extends Control

## GameHUD — BitLife-style main gameplay screen

# Header
@onready var avatar_label: Label = %AvatarLabel
@onready var char_name: Label = %CharName
@onready var phase_label: Label = %PhaseLabel
@onready var money_label: Label = %MoneyLabel
@onready var money_sub_label: Label = %MoneySubLabel
@onready var btn_menu: Button = %BtnMenu

# Feed
@onready var event_feed: ScrollContainer = %EventFeed
@onready var feed_vbox: VBoxContainer = %FeedVBox

# Nav bar
@onready var btn_phase: Button = %BtnPhase
@onready var lbl_phase: Label = %LblPhase
@onready var btn_assets: Button = %BtnAssets
@onready var btn_age: Button = %BtnAge
@onready var btn_relationships: Button = %BtnRelationships
@onready var btn_activities: Button = %BtnActivities

# Stats
@onready var happiness_bar: ProgressBar = %HappinessBar
@onready var health_bar: ProgressBar = %HealthBar
@onready var social_bar: ProgressBar = %SocialBar
@onready var morality_bar: ProgressBar = %MoralityBar

var _event_popup_scene: PackedScene = preload("res://scenes/popups/EventPopup.tscn")
var _pause_menu_scene: PackedScene = preload("res://scenes/popups/PauseMenu.tscn")
var _current_year_logged: int = -1


func _ready() -> void:
	_style_header()
	_style_nav_bar()
	_style_stats()
	_localize_ui()
	_connect_signals()
	_update_display()

	var start_age := 0
	if GameManager.character:
		start_age = GameManager.character.age
	_add_year_separator(start_age)
	_process_next_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()
		get_viewport().set_input_as_handled()


func _open_pause_menu() -> void:
	if get_tree().paused:
		return
	var pause := _pause_menu_scene.instantiate()
	pause.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause)


func _on_achievement_unlocked(_id: String, text_key: String, icon: String) -> void:
	_add_log_entry("🏆 " + tr("ACHIEVEMENT_UNLOCKED") + ": " + icon + " " + tr(text_key), "🏆")


# ── STYLING ──

func _style_header() -> void:
	var header_panel := $MainVBox/HeaderPanel
	var header_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY, 0, 16, 10)
	header_panel.add_theme_stylebox_override("panel", header_style)

	var title_label := $MainVBox/HeaderPanel/HeaderVBox/TopRow/TitleLabel
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)

	btn_menu.add_theme_font_size_override("font_size", 24)
	btn_menu.add_theme_color_override("font_color", Color.WHITE)

	avatar_label.add_theme_font_size_override("font_size", 32)

	char_name.add_theme_font_size_override("font_size", 20)
	char_name.add_theme_color_override("font_color", Color.WHITE)

	phase_label.add_theme_font_size_override("font_size", 14)
	phase_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color.WHITE)

	money_sub_label.add_theme_font_size_override("font_size", 11)
	money_sub_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))


func _style_nav_bar() -> void:
	var nav_panel := $MainVBox/BottomSection/NavBar
	var nav_style := ThemeSetup.make_flat_box(ThemeSetup.BG_DARK, 0, 0, 6)
	nav_panel.add_theme_stylebox_override("panel", nav_style)

	var nav_buttons := [btn_phase, btn_assets, btn_relationships, btn_activities]
	for btn in nav_buttons:
		var circle := StyleBoxFlat.new()
		circle.bg_color = ThemeSetup.PRIMARY
		circle.set_corner_radius_all(25)
		btn.add_theme_stylebox_override("normal", circle)
		var hover := StyleBoxFlat.new()
		hover.bg_color = ThemeSetup.PRIMARY.lightened(0.15)
		hover.set_corner_radius_all(25)
		btn.add_theme_stylebox_override("hover", hover)
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = ThemeSetup.PRIMARY.darkened(0.2)
		pressed.set_corner_radius_all(25)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_font_size_override("font_size", 22)

	var age_normal := StyleBoxFlat.new()
	age_normal.bg_color = Color("#4CAF50")
	age_normal.set_corner_radius_all(34)
	btn_age.add_theme_stylebox_override("normal", age_normal)
	var age_hover := StyleBoxFlat.new()
	age_hover.bg_color = Color("#66BB6A")
	age_hover.set_corner_radius_all(34)
	btn_age.add_theme_stylebox_override("hover", age_hover)
	var age_pressed := StyleBoxFlat.new()
	age_pressed.bg_color = Color("#388E3C")
	age_pressed.set_corner_radius_all(34)
	btn_age.add_theme_stylebox_override("pressed", age_pressed)
	btn_age.add_theme_font_size_override("font_size", 32)
	btn_age.add_theme_color_override("font_color", Color.WHITE)

	var nav_labels := [lbl_phase,
		$MainVBox/BottomSection/NavBar/NavHBox/TabAssets/LblAssets,
		$MainVBox/BottomSection/NavBar/NavHBox/TabAge/LblAge,
		$MainVBox/BottomSection/NavBar/NavHBox/TabRelationships/LblRelationships,
		$MainVBox/BottomSection/NavBar/NavHBox/TabActivities/LblActivities]
	for lbl in nav_labels:
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)


func _style_stats() -> void:
	var stats_panel := $MainVBox/BottomSection/StatsPanel
	var stats_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 0, 16, 8)
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	_color_bar(happiness_bar, ThemeSetup.COLOR_HAPPINESS)
	_color_bar(health_bar, ThemeSetup.COLOR_HEALTH)
	_color_bar(social_bar, ThemeSetup.COLOR_SOCIAL)
	_color_bar(morality_bar, ThemeSetup.COLOR_MORALITY)

	var stat_labels := [
		$MainVBox/BottomSection/StatsPanel/StatsVBox/HappinessRow/LblHappiness,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/HealthRow/LblHealth,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/SocialRow/LblSocial,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/MoralityRow/LblMorality]
	for lbl in stat_labels:
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)


func _localize_ui() -> void:
	$MainVBox/BottomSection/NavBar/NavHBox/TabAssets/LblAssets.text = tr("ASSETS")
	$MainVBox/BottomSection/NavBar/NavHBox/TabAge/LblAge.text = tr("AGE")
	$MainVBox/BottomSection/NavBar/NavHBox/TabRelationships/LblRelationships.text = tr("RELATIONSHIPS")
	$MainVBox/BottomSection/NavBar/NavHBox/TabActivities/LblActivities.text = tr("ACTIVITIES")
	$MainVBox/BottomSection/StatsPanel/StatsVBox/HappinessRow/LblHappiness.text = tr("HAPPINESS") + " 😄"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/HealthRow/LblHealth.text = tr("HEALTH") + " ❤️"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/SocialRow/LblSocial.text = tr("SOCIAL") + " 👥"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/MoralityRow/LblMorality.text = tr("MORALITY") + " ⚖️"
	money_sub_label.text = tr("BANK_BALANCE")


func _color_bar(bar: ProgressBar, color: Color) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("fill", ThemeSetup.make_bar_fill(color))
	bar.add_theme_stylebox_override("background", ThemeSetup.make_bar_bg())


func _animate_bar(bar: ProgressBar, target: float) -> void:
	if bar == null:
		return
	var tween := create_tween()
	tween.tween_property(bar, "value", target, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


# ── SIGNALS ──

func _connect_signals() -> void:
	btn_menu.pressed.connect(_open_pause_menu)
	btn_age.pressed.connect(_on_advance_year)
	btn_phase.pressed.connect(func(): _show_category_actions("social"))
	btn_assets.pressed.connect(func(): _show_category_actions("finance"))
	btn_relationships.pressed.connect(func(): _show_category_actions("family"))
	btn_activities.pressed.connect(_show_activities_menu)

	GameManager.character_died.connect(_on_character_died)
	GameManager.year_advanced.connect(_on_year_advanced)
	GameManager.phase_changed.connect(_on_phase_changed)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


# ── DISPLAY ──

func _update_display() -> void:
	var c := GameManager.character
	if c == null:
		return

	char_name.text = c.get_full_name()
	phase_label.text = tr(c.get_phase_name())

	_update_avatar(c)

	lbl_phase.text = tr(c.get_phase_name())
	btn_phase.text = _get_phase_emoji(c)

	_update_money(c)

	_animate_bar(happiness_bar, c.happiness)
	_animate_bar(health_bar, c.health)
	_animate_bar(social_bar, c.get_relationship_average())
	_animate_bar(morality_bar, c.morality)


func _update_avatar(c: Character) -> void:
	if avatar_label == null:
		return
	avatar_label.text = _get_phase_emoji(c)


func _get_phase_emoji(c: Character) -> String:
	match c.life_phase:
		Character.LifePhase.BABY:
			return "👶"
		Character.LifePhase.CHILD:
			return "🧒"
		Character.LifePhase.TEEN:
			return "🧑" if c.gender == "male" else "👧"
		Character.LifePhase.ADULT:
			return "👨" if c.gender == "male" else "👩"
		Character.LifePhase.ELDER:
			return "👴" if c.gender == "male" else "👵"
	return "👶"


func _update_money(c: Character) -> void:
	if money_label == null:
		return
	if c.money >= 1_000_000:
		money_label.text = "$" + str(snappedf(c.money / 1_000_000.0, 0.1)) + "M"
	elif c.money >= 1_000:
		money_label.text = "$" + str(snappedf(c.money / 1_000.0, 0.1)) + "K"
	else:
		money_label.text = "$" + str(int(c.money))


# ── LIFE LOG ──

func _add_year_separator(age: int) -> void:
	if _current_year_logged == age:
		return
	_current_year_logged = age

	var sep := Label.new()
	sep.text = tr("AGE") + ": " + str(age)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sep.add_theme_font_size_override("font_size", 16)
	sep.add_theme_color_override("font_color", Color("#4CAF50"))
	feed_vbox.add_child(sep)


func _add_log_entry(text: String, icon: String = "📌") -> void:
	var entry := RichTextLabel.new()
	entry.bbcode_enabled = true
	entry.fit_content = true
	entry.scroll_active = false
	entry.text = icon + "  " + text
	entry.add_theme_font_size_override("normal_font_size", 14)
	entry.add_theme_color_override("default_color", Color("#333333"))

	feed_vbox.add_child(entry)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if event_feed:
		event_feed.scroll_vertical = int(event_feed.get_v_scroll_bar().max_value)


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
	SceneTransition.change_scene("res://scenes/screens/LifeSummary.tscn")


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
	var event_categories: Array[String] = []
	match category:
		"social": event_categories = ["social"]
		"family": event_categories = ["social", "family"]
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


func _show_activities_menu() -> void:
	var c := GameManager.character
	if c == null:
		return

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(280, 0)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("ACTIVITIES")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox.add_child(title)

	var activities := []
	if c.age < 18:
		activities.append({"label": "📚 " + tr("SCHOOL"), "category": "school"})
	else:
		activities.append({"label": "💼 " + tr("WORK"), "category": "school"})
	activities.append({"label": "❤️ " + tr("HEALTH"), "category": "health"})
	if c.age >= 13:
		activities.append({"label": "🔪 " + tr("CRIME"), "category": "crime"})

	for act in activities:
		var btn := Button.new()
		btn.text = act["label"]
		btn.custom_minimum_size = Vector2(0, 48)
		var btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 12, 12, 8)
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 12, 12, 8)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
		var cat: String = act["category"]
		btn.pressed.connect(func():
			overlay.queue_free()
			_show_category_actions(cat)
		)
		vbox.add_child(btn)

	var btn_close := Button.new()
	btn_close.text = "✕ " + tr("CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 42)
	var close_style := ThemeSetup.make_flat_box(Color("#C62828"), 12, 12, 8)
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_close)

	bg.gui_input.connect(func(event_input: InputEvent):
		if event_input is InputEventMouseButton and event_input.pressed:
			overlay.queue_free()
	)

	add_child(overlay)
