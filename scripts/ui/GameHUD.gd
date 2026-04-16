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
@onready var intelligence_bar: ProgressBar = %IntelligenceBar
@onready var beauty_bar: ProgressBar = %BeautyBar

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
	_setup_monetization_button()

	var start_age := 0
	if GameManager.character:
		start_age = GameManager.character.age
	_add_year_separator(start_age)
	_process_next_event()

func _setup_monetization_button() -> void:
	var mon_btn := Button.new()
	if AdManager.has_premium:
		mon_btn.text = "+$10k (VIP)"
	else:
		mon_btn.text = "🎥 " + tr("WATCH_AD_MONEY") + " (+$10k)"
	
	mon_btn.custom_minimum_size = Vector2(160, 45)
	
	var b_style := ThemeSetup.make_flat_box(Color("#4CAF50"), 10, 10, 8)
	mon_btn.add_theme_stylebox_override("normal", b_style)
	mon_btn.add_theme_font_size_override("font_size", 16)
	mon_btn.add_theme_color_override("font_color", Color.WHITE)
	
	mon_btn.pressed.connect(func():
		mon_btn.disabled = true
		AdManager.show_rewarded_ad("money")
	)

	AdManager.rewarded_ad_completed.connect(func(reward_type: String):
		if reward_type == "money":
			GameManager.character.money += 10000
			SaveManager.auto_save(GameManager.character)
			_update_money(GameManager.character)
			_add_log_entry("💰 " + tr("WATCH_AD_MONEY") + ": +$10k!", "💰")
			mon_btn.disabled = false
			if AdManager.has_premium:
				mon_btn.text = "+$10k (VIP)"
	)

	# Colocar na HeaderPanel -> TopRow
	var top_row = $MainVBox/HeaderPanel/HeaderVBox/TopRow
	top_row.add_child(mon_btn)
	top_row.move_child(mon_btn, 2) # Fica após o título



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
	var header_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY, 0, 20, 14)
	header_panel.add_theme_stylebox_override("panel", header_style)

	var title_label := $MainVBox/HeaderPanel/HeaderVBox/TopRow/TitleLabel
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.WHITE)

	btn_menu.add_theme_font_size_override("font_size", 36)
	btn_menu.add_theme_color_override("font_color", Color.WHITE)

	avatar_label.add_theme_font_size_override("font_size", 48)
	avatar_label.custom_minimum_size = Vector2(64, 64)

	char_name.add_theme_font_size_override("font_size", 30)
	char_name.add_theme_color_override("font_color", Color.WHITE)

	phase_label.add_theme_font_size_override("font_size", 22)
	phase_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color.WHITE)

	money_sub_label.add_theme_font_size_override("font_size", 18)
	money_sub_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))


func _style_nav_bar() -> void:
	var nav_panel := $MainVBox/BottomSection/NavBar
	var nav_style := ThemeSetup.make_flat_box(ThemeSetup.BG_DARK, 0, 0, 6)
	nav_panel.add_theme_stylebox_override("panel", nav_style)

	var nav_buttons := [btn_phase, btn_assets, btn_relationships, btn_activities]
	for btn in nav_buttons:
		btn.custom_minimum_size = Vector2(70, 70)
		var circle := StyleBoxFlat.new()
		circle.bg_color = ThemeSetup.PRIMARY
		circle.set_corner_radius_all(35)
		btn.add_theme_stylebox_override("normal", circle)
		var hover := StyleBoxFlat.new()
		hover.bg_color = ThemeSetup.PRIMARY.lightened(0.15)
		hover.set_corner_radius_all(35)
		btn.add_theme_stylebox_override("hover", hover)
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = ThemeSetup.PRIMARY.darkened(0.2)
		pressed.set_corner_radius_all(35)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_font_size_override("font_size", 32)

	btn_age.custom_minimum_size = Vector2(90, 90)
	var age_normal := StyleBoxFlat.new()
	age_normal.bg_color = Color("#4CAF50")
	age_normal.set_corner_radius_all(45)
	btn_age.add_theme_stylebox_override("normal", age_normal)
	var age_hover := StyleBoxFlat.new()
	age_hover.bg_color = Color("#66BB6A")
	age_hover.set_corner_radius_all(45)
	btn_age.add_theme_stylebox_override("hover", age_hover)
	var age_pressed := StyleBoxFlat.new()
	age_pressed.bg_color = Color("#388E3C")
	age_pressed.set_corner_radius_all(45)
	btn_age.add_theme_stylebox_override("pressed", age_pressed)
	btn_age.add_theme_font_size_override("font_size", 42)
	btn_age.add_theme_color_override("font_color", Color.WHITE)

	var nav_labels := [lbl_phase,
		$MainVBox/BottomSection/NavBar/NavHBox/TabAssets/LblAssets,
		$MainVBox/BottomSection/NavBar/NavHBox/TabAge/LblAge,
		$MainVBox/BottomSection/NavBar/NavHBox/TabRelationships/LblRelationships,
		$MainVBox/BottomSection/NavBar/NavHBox/TabActivities/LblActivities]
	for lbl in nav_labels:
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)


func _style_stats() -> void:
	var stats_panel := $MainVBox/BottomSection/StatsPanel
	var stats_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 0, 20, 10)
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	var bars := [happiness_bar, health_bar, social_bar, morality_bar, intelligence_bar, beauty_bar]
	for bar in bars:
		if bar:
			bar.custom_minimum_size = Vector2(0, 32)

	_color_bar(happiness_bar, ThemeSetup.COLOR_HAPPINESS)
	_color_bar(health_bar, ThemeSetup.COLOR_HEALTH)
	_color_bar(social_bar, ThemeSetup.COLOR_SOCIAL)
	_color_bar(morality_bar, ThemeSetup.COLOR_MORALITY)
	_color_bar(intelligence_bar, Color("#8E24AA")) # purple
	_color_bar(beauty_bar, Color("#E91E63")) # pink

	var stat_labels := [
		$MainVBox/BottomSection/StatsPanel/StatsVBox/HappinessRow/LblHappiness,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/HealthRow/LblHealth,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/SocialRow/LblSocial,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/MoralityRow/LblMorality,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/IntelligenceRow/LblIntelligence,
		$MainVBox/BottomSection/StatsPanel/StatsVBox/BeautyRow/LblBeauty]
	for lbl in stat_labels:
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
		lbl.custom_minimum_size = Vector2(170, 0)


func _localize_ui() -> void:
	$MainVBox/BottomSection/NavBar/NavHBox/TabAssets/LblAssets.text = tr("ASSETS")
	$MainVBox/BottomSection/NavBar/NavHBox/TabAge/LblAge.text = tr("AGE")
	$MainVBox/BottomSection/NavBar/NavHBox/TabRelationships/LblRelationships.text = tr("RELATIONSHIPS")
	$MainVBox/BottomSection/NavBar/NavHBox/TabActivities/LblActivities.text = tr("ACTIVITIES")
	$MainVBox/BottomSection/StatsPanel/StatsVBox/HappinessRow/LblHappiness.text = tr("HAPPINESS") + " 😄"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/HealthRow/LblHealth.text = tr("HEALTH") + " ❤️"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/SocialRow/LblSocial.text = tr("SOCIAL") + " 👥"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/MoralityRow/LblMorality.text = tr("MORALITY") + " ⚖️"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/IntelligenceRow/LblIntelligence.text = tr("INTELLIGENCE") + " 🧠"
	$MainVBox/BottomSection/StatsPanel/StatsVBox/BeautyRow/LblBeauty.text = tr("BEAUTY") + " ✨"
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
	btn_relationships.pressed.connect(_show_relationships_list)
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
	_animate_bar(intelligence_bar, c.intelligence)
	_animate_bar(beauty_bar, c.appearance)


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
	sep.add_theme_font_size_override("font_size", 24)
	sep.add_theme_color_override("font_color", Color("#4CAF50"))
	feed_vbox.add_child(sep)


func _add_log_entry(text: String, icon: String = "📌") -> void:
	var entry := RichTextLabel.new()
	entry.bbcode_enabled = true
	entry.fit_content = true
	entry.scroll_active = false
	entry.text = icon + "  " + text
	entry.add_theme_font_size_override("normal_font_size", 22)
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
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.06
	panel.anchor_bottom = 0.94
	var panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = tr("ACTIVITIES")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox.add_child(title)

	# Phase info label
	var phase_info := Label.new()
	phase_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_info.add_theme_font_size_override("font_size", 18)
	phase_info.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
	vbox.add_child(phase_info)

	var activities := _get_phase_activities(c)
	phase_info.text = _get_phase_description(c)

	for act in activities:
		var btn := Button.new()
		btn.text = act["label"]
		btn.custom_minimum_size = Vector2(0, 68)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 14, 16, 12)
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 14, 16, 12)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)

		if act.has("disabled") and act["disabled"]:
			btn.disabled = true
			btn.add_theme_color_override("font_color", ThemeSetup.TEXT_HINT)
			btn.tooltip_text = act.get("tooltip", "")
		else:
			var cat: String = act["category"]
			btn.pressed.connect(func():
				overlay.queue_free()
				_show_category_actions(cat)
			)
		vbox.add_child(btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	var btn_close := Button.new()
	btn_close.text = "✕ " + tr("CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 56)
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_style := ThemeSetup.make_flat_box(Color("#C62828"), 14, 16, 12)
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_close)

	bg.gui_input.connect(func(event_input: InputEvent):
		if event_input is InputEventMouseButton and event_input.pressed:
			overlay.queue_free()
	)

	add_child(overlay)


func _get_phase_activities(c: Character) -> Array:
	var activities := []

	match c.life_phase:
		Character.LifePhase.BABY:
			# Babies have almost no actions — life just happens
			activities.append({"label": "😴 " + tr("ACT_SLEEP"), "category": "health"})
			activities.append({"label": "😭 " + tr("ACT_CRY"), "category": "social"})
			activities.append({"label": "🧸 " + tr("ACT_PLAY_BABY"), "category": "social", "disabled": c.age < 1, "tooltip": tr("TOO_YOUNG")})

		Character.LifePhase.CHILD:
			# Children: school, play, family
			activities.append({"label": "📚 " + tr("ACT_SCHOOL"), "category": "school"})
			activities.append({"label": "🎮 " + tr("ACT_PLAY"), "category": "social"})
			activities.append({"label": "👨‍👩‍👧 " + tr("ACT_FAMILY_TIME"), "category": "family"})
			activities.append({"label": "🎨 " + tr("ACT_HOBBIES"), "category": "social"})
			activities.append({"label": "⚽ " + tr("ACT_SPORTS"), "category": "health"})
			activities.append({"label": "📖 " + tr("ACT_READ"), "category": "school"})
			# Locked items for kids
			activities.append({"label": "🔒 " + tr("ACT_WORK"), "category": "school", "disabled": true, "tooltip": tr("NEED_AGE_16")})
			activities.append({"label": "🔒 " + tr("ACT_DATING"), "category": "social", "disabled": true, "tooltip": tr("NEED_AGE_13")})

		Character.LifePhase.TEEN:
			# Teens: school, social, part-time job, dating, small crimes
			activities.append({"label": "📚 " + tr("ACT_SCHOOL"), "category": "school"})
			activities.append({"label": "👫 " + tr("ACT_SOCIAL"), "category": "social"})
			activities.append({"label": "💕 " + tr("ACT_DATING"), "category": "social"})
			activities.append({"label": "⚽ " + tr("ACT_SPORTS"), "category": "health"})
			activities.append({"label": "🎨 " + tr("ACT_HOBBIES"), "category": "social"})
			activities.append({"label": "📖 " + tr("ACT_READ"), "category": "school"})
			activities.append({"label": "💪 " + tr("ACT_GYM"), "category": "health"})
			activities.append({"label": "👨‍👩‍👧 " + tr("ACT_FAMILY_TIME"), "category": "family"})
			if c.age >= 16:
				activities.append({"label": "💼 " + tr("ACT_PART_TIME"), "category": "finance"})
			else:
				activities.append({"label": "🔒 " + tr("ACT_PART_TIME"), "category": "finance", "disabled": true, "tooltip": tr("NEED_AGE_16")})
			activities.append({"label": "🔪 " + tr("ACT_CRIME"), "category": "crime"})
			activities.append({"label": "🔒 " + tr("ACT_DRIVE"), "category": "social", "disabled": c.age < 16, "tooltip": tr("NEED_AGE_16")})

		Character.LifePhase.ADULT:
			# Adults: full range of actions
			if c.current_career != "":
				activities.append({"label": "💼 " + tr("ACT_WORK"), "category": "finance"})
			else:
				activities.append({"label": "🔍 " + tr("ACT_JOB_SEARCH"), "category": "finance"})
			if c.education < Character.Education.POSTGRAD and c.age <= 35:
				activities.append({"label": "🎓 " + tr("ACT_STUDY"), "category": "school"})
			activities.append({"label": "👫 " + tr("ACT_SOCIAL"), "category": "social"})
			activities.append({"label": "💕 " + tr("ACT_DATING"), "category": "social"})
			activities.append({"label": "💍 " + tr("ACT_MARRIAGE"), "category": "family"})
			activities.append({"label": "👶 " + tr("ACT_HAVE_CHILD"), "category": "family"})
			activities.append({"label": "💪 " + tr("ACT_GYM"), "category": "health"})
			activities.append({"label": "🏥 " + tr("ACT_DOCTOR"), "category": "health"})
			activities.append({"label": "🎨 " + tr("ACT_HOBBIES"), "category": "social"})
			activities.append({"label": "✈️ " + tr("ACT_TRAVEL"), "category": "social"})
			activities.append({"label": "🏠 " + tr("ACT_BUY_HOUSE"), "category": "finance"})
			activities.append({"label": "🚗 " + tr("ACT_BUY_CAR"), "category": "finance"})
			activities.append({"label": "💰 " + tr("ACT_INVEST"), "category": "finance"})
			activities.append({"label": "👨‍👩‍👧 " + tr("ACT_FAMILY_TIME"), "category": "family"})
			activities.append({"label": "🔪 " + tr("ACT_CRIME"), "category": "crime"})
			activities.append({"label": "🍺 " + tr("ACT_NIGHTLIFE"), "category": "social"})
			activities.append({"label": "🧘 " + tr("ACT_MEDITATE"), "category": "health"})

		Character.LifePhase.ELDER:
			# Elders: retirement, health focus, legacy
			activities.append({"label": "🏖️ " + tr("ACT_RETIREMENT"), "category": "social"})
			activities.append({"label": "🏥 " + tr("ACT_DOCTOR"), "category": "health"})
			activities.append({"label": "💊 " + tr("ACT_MEDICINE"), "category": "health"})
			activities.append({"label": "👨‍👩‍👧 " + tr("ACT_FAMILY_TIME"), "category": "family"})
			activities.append({"label": "🧘 " + tr("ACT_MEDITATE"), "category": "health"})
			activities.append({"label": "🎨 " + tr("ACT_HOBBIES"), "category": "social"})
			activities.append({"label": "✈️ " + tr("ACT_TRAVEL"), "category": "social"})
			activities.append({"label": "📖 " + tr("ACT_READ"), "category": "school"})
			activities.append({"label": "🏠 " + tr("ACT_GARDEN"), "category": "health"})
			activities.append({"label": "📝 " + tr("ACT_WILL"), "category": "finance"})
			activities.append({"label": "💰 " + tr("ACT_INVEST"), "category": "finance"})

	return activities


func _get_phase_description(c: Character) -> String:
	match c.life_phase:
		Character.LifePhase.BABY:
			return tr("PHASE_DESC_BABY")
		Character.LifePhase.CHILD:
			return tr("PHASE_DESC_CHILD")
		Character.LifePhase.TEEN:
			return tr("PHASE_DESC_TEEN")
		Character.LifePhase.ADULT:
			return tr("PHASE_DESC_ADULT")
		Character.LifePhase.ELDER:
			return tr("PHASE_DESC_ELDER")
	return ""


# ── RELATIONSHIPS ──

func _show_relationships_list() -> void:
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
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.06
	panel.anchor_bottom = 0.94
	var panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "💕 " + tr("RELATIONSHIPS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox.add_child(title)

	if c.relationships.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("REL_NO_RELATIONSHIPS")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
		vbox.add_child(empty_label)
	else:
		for rel in c.relationships:
			if rel is Relationship:
				var btn := Button.new()
				var emoji := _get_rel_emoji(rel)
				var type_str := tr(rel.get_type_name())
				var status := "" if rel.alive else " 💀"
				btn.text = emoji + " " + rel.person_name + " (" + type_str + ")" + status
				btn.custom_minimum_size = Vector2(0, 72)
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.clip_text = false
				var btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 14, 16, 12)
				btn.add_theme_stylebox_override("normal", btn_style)
				var hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 14, 16, 12)
				btn.add_theme_stylebox_override("hover", hover_style)
				btn.add_theme_font_size_override("font_size", 22)
				btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

				if rel.alive:
					var bound_rel := rel
					btn.pressed.connect(func():
						overlay.queue_free()
						_show_person_actions(bound_rel)
					)
				else:
					btn.disabled = true
					btn.add_theme_color_override("font_color", ThemeSetup.TEXT_HINT)

				vbox.add_child(btn)

				var bar := ProgressBar.new()
				bar.value = rel.get_overall()
				bar.custom_minimum_size = Vector2(0, 16)
				bar.show_percentage = false
				bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bar.add_theme_stylebox_override("fill", ThemeSetup.make_bar_fill(ThemeSetup.COLOR_SOCIAL))
				bar.add_theme_stylebox_override("background", ThemeSetup.make_bar_bg())
				vbox.add_child(bar)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var btn_close := Button.new()
	btn_close.text = "✕ " + tr("CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 56)
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_style := ThemeSetup.make_flat_box(Color("#C62828"), 14, 16, 12)
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_close)

	bg.gui_input.connect(func(event_input: InputEvent):
		if event_input is InputEventMouseButton and event_input.pressed:
			overlay.queue_free()
	)

	add_child(overlay)


func _show_person_actions(rel: Relationship) -> void:
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
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.06
	panel.anchor_bottom = 0.94
	var panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var emoji := _get_rel_emoji(rel)
	var title := Label.new()
	title.text = emoji + " " + rel.person_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = tr(rel.get_type_name()) + " • " + tr("AGE") + ": " + str(rel.person_age)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
	vbox.add_child(subtitle)

	var stats := [
		[tr("REL_AFFECTION"), rel.affection, ThemeSetup.COLOR_HAPPINESS],
		[tr("REL_RESPECT"), rel.respect, ThemeSetup.COLOR_SOCIAL],
		[tr("REL_TRUST"), rel.trust, ThemeSetup.COLOR_MORALITY]
	]
	for stat in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.text = stat[0]
		lbl.custom_minimum_size = Vector2(140, 0)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
		row.add_child(lbl)
		var bar := ProgressBar.new()
		bar.value = stat[1]
		bar.custom_minimum_size = Vector2(0, 24)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = true
		bar.add_theme_font_size_override("font_size", 16)
		bar.add_theme_stylebox_override("fill", ThemeSetup.make_bar_fill(stat[2]))
		bar.add_theme_stylebox_override("background", ThemeSetup.make_bar_bg())
		row.add_child(bar)
		vbox.add_child(row)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	var choose := Label.new()
	choose.text = tr("REL_CHOOSE_ACTION")
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose.add_theme_font_size_override("font_size", 20)
	choose.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
	vbox.add_child(choose)

	var actions := []
	if c.life_phase == Character.LifePhase.BABY:
		actions = [
			{"label": "😭 " + tr("REL_CRY"), "effect": "cry"},
			{"label": "👶 " + tr("REL_PLAY_BABY"), "effect": "play_baby"}
		]
	else:
		actions = [
			{"label": "💬 " + tr("REL_TALK"), "effect": "talk"},
			{"label": "🤗 " + tr("REL_SPEND_TIME"), "effect": "spend_time"},
			{"label": "😊 " + tr("REL_COMPLIMENT"), "effect": "compliment"},
			{"label": "😡 " + tr("REL_ARGUE"), "effect": "argue"},
		]
		if c.money >= 50:
			actions.append({"label": "🎁 " + tr("REL_GIFT") + " ()", "effect": "gift"})
		if rel.rel_type in [Relationship.RelType.FATHER, Relationship.RelType.MOTHER, Relationship.RelType.SPOUSE]:
			actions.append({"label": "💰 " + tr("REL_ASK_MONEY"), "effect": "ask_money"})

	for act in actions:
		var btn := Button.new()
		btn.text = act["label"]
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 14, 16, 12)
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 14, 16, 12)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
		var bound_effect: String = act["effect"]
		btn.pressed.connect(func():
			overlay.queue_free()
			_apply_rel_action(rel, bound_effect)
		)
		vbox.add_child(btn)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var btn_back := Button.new()
	btn_back.text = "← " + tr("BACK")
	btn_back.custom_minimum_size = Vector2(0, 56)
	btn_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 14, 16, 12)
	btn_back.add_theme_stylebox_override("normal", back_style)
	btn_back.add_theme_font_size_override("font_size", 22)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.pressed.connect(func():
		overlay.queue_free()
		_show_relationships_list()
	)
	vbox.add_child(btn_back)

	var btn_close := Button.new()
	btn_close.text = "✕ " + tr("CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 56)
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_style := ThemeSetup.make_flat_box(Color("#C62828"), 14, 16, 12)
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_close)

	bg.gui_input.connect(func(event_input: InputEvent):
		if event_input is InputEventMouseButton and event_input.pressed:
			overlay.queue_free()
	)

	add_child(overlay)


func _apply_rel_action(rel: Relationship, effect: String) -> void:
	var c := GameManager.character
	match effect:
		"cry":
			rel.modify_affection(-2)
			c.happiness = clampi(c.happiness - 2, 0, 100)
			_add_log_entry(tr("REL_RESULT_CRY").replace("{name}", rel.person_name), "😭")
		"play_baby":
			rel.modify_affection(8)
			c.happiness = clampi(c.happiness + 6, 0, 100)
			_add_log_entry(tr("REL_RESULT_PLAY_BABY").replace("{name}", rel.person_name), "👶")
		"talk":
			rel.modify_affection(5)
			c.happiness = clampi(c.happiness + 3, 0, 100)
			_add_log_entry(tr("REL_RESULT_TALK").replace("{name}", rel.person_name), "💬")
		"spend_time":
			rel.modify_affection(10)
			rel.modify_respect(5)
			c.happiness = clampi(c.happiness + 5, 0, 100)
			_add_log_entry(tr("REL_RESULT_SPEND_TIME").replace("{name}", rel.person_name), "🤗")
		"compliment":
			rel.modify_affection(5)
			rel.modify_trust(3)
			c.happiness = clampi(c.happiness + 2, 0, 100)
			_add_log_entry(tr("REL_RESULT_COMPLIMENT").replace("{name}", rel.person_name), "😊")
		"argue":
			rel.modify_affection(-10)
			rel.modify_trust(-5)
			c.happiness = clampi(c.happiness - 5, 0, 100)
			_add_log_entry(tr("REL_RESULT_ARGUE").replace("{name}", rel.person_name), "😡")
		"gift":
			rel.modify_affection(15)
			c.money -= 50
			_add_log_entry(tr("REL_RESULT_GIFT").replace("{name}", rel.person_name), "🎁")
		"ask_money":
			if rel.affection > 40:
				var amount := randi_range(20, 200)
				c.money += amount
				rel.modify_affection(-3)
				_add_log_entry(tr("REL_RESULT_ASK_MONEY_OK").replace("{name}", rel.person_name).replace("{amount}", str(amount)), "💰")
			else:
				rel.modify_affection(-5)
				_add_log_entry(tr("REL_RESULT_ASK_MONEY_NO").replace("{name}", rel.person_name), "😒")
	_update_display()


func _get_rel_emoji(rel: Relationship) -> String:
	match rel.rel_type:
		Relationship.RelType.FATHER: return "👨"
		Relationship.RelType.MOTHER: return "👩"
		Relationship.RelType.SIBLING:
			return "👦" if rel.person_gender == "male" else "👧"
		Relationship.RelType.SPOUSE: return "💑"
		Relationship.RelType.CHILD: return "👶"
		Relationship.RelType.FRIEND: return "🧑"
		Relationship.RelType.ROMANTIC: return "💕"
		Relationship.RelType.COWORKER: return "👔"
		Relationship.RelType.BOSS: return "🧑‍💼"
		Relationship.RelType.ENEMY: return "😠"
		Relationship.RelType.GRANDPARENT:
			return "👴" if rel.person_gender == "male" else "👵"
		Relationship.RelType.UNCLE_AUNT:
			return "🧔" if rel.person_gender == "male" else "👩"
		Relationship.RelType.COUSIN: return "🧑"
	return "👤"
