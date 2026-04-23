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
var _toast_queue: Array[Dictionary] = []
var _toast_active: bool = false


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
	# Não processa eventos automaticamente ao entrar no HUD —
	# eventos só aparecem ao avançar o ano ou realizar atividades.

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
	_enqueue_toast(icon, tr(text_key))


func _enqueue_toast(icon: String, text: String) -> void:
	_toast_queue.append({"icon": icon, "text": text})
	if not _toast_active:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_active = false
		return
	_toast_active = true
	var data := _toast_queue.pop_front() as Dictionary

	var toast := PanelContainer.new()
	toast.anchor_left = 0.05
	toast.anchor_right = 0.95
	toast.anchor_top = 0.0
	toast.anchor_bottom = 0.0
	toast.offset_top = 24.0
	toast.offset_bottom = 90.0
	var ts := ThemeSetup.make_flat_box(Color("#F57F17"), 12, 12, 10)
	toast.add_theme_stylebox_override("panel", ts)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	toast.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = data["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 34)
	hbox.add_child(icon_lbl)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var top_lbl := Label.new()
	top_lbl.text = "🏆 " + tr("ACHIEVEMENT_UNLOCKED")
	top_lbl.add_theme_font_size_override("font_size", 16)
	top_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(top_lbl)

	var name_lbl := Label.new()
	name_lbl.text = data["text"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	add_child(toast)

	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	await tween.finished
	toast.queue_free()
	_show_next_toast()


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


func _update_bar_color(bar: ProgressBar, value: float, base_color: Color) -> void:
	if bar == null:
		return
	var c: Color
	if value >= 60:
		c = base_color
	elif value >= 30:
		c = base_color.lerp(Color("#FFC107"), (60.0 - value) / 30.0)
	else:
		c = Color("#F44336")
	bar.add_theme_stylebox_override("fill", ThemeSetup.make_bar_fill(c))


# ── SIGNALS ──

func _connect_signals() -> void:
	btn_menu.pressed.connect(_open_pause_menu)
	btn_age.pressed.connect(_on_advance_year)
	btn_phase.pressed.connect(_show_achievements_overlay)
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

	lbl_phase.text = tr("ACHIEVEMENTS")
	btn_phase.text = "🏆"

	_update_money(c)

	_animate_bar(happiness_bar, c.happiness)
	_animate_bar(health_bar, c.health)
	_animate_bar(social_bar, c.get_relationship_average())
	_animate_bar(morality_bar, c.morality)
	_animate_bar(intelligence_bar, c.intelligence)
	_animate_bar(beauty_bar, c.appearance)

	_update_bar_color(happiness_bar, c.happiness, ThemeSetup.COLOR_HAPPINESS)
	_update_bar_color(health_bar, c.health, ThemeSetup.COLOR_HEALTH)
	_update_bar_color(social_bar, c.get_relationship_average(), ThemeSetup.COLOR_SOCIAL)
	_update_bar_color(morality_bar, c.morality, ThemeSetup.COLOR_MORALITY)
	_update_bar_color(intelligence_bar, c.intelligence, Color("#8E24AA"))
	_update_bar_color(beauty_bar, c.appearance, Color("#E91E63"))


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


# Applies affection delta to all relationships matching given types and logs each reaction.
# reactions = [ {rel_types: [RelType,...], affection: int, reaction_text: String, emoji: String} ]
func _apply_present_reactions(reactions: Array) -> void:
	var c := GameManager.character
	for rule in reactions:
		var types: Array = rule.get("rel_types", [])
		var aff_delta: int = rule.get("affection", 0)
		var reaction_text: String = rule.get("reaction_text", "")
		var emoji: String = rule.get("emoji", "💬")
		for rel in c.relationships:
			if not (rel is Relationship) or not rel.alive:
				continue
			if types.is_empty() or rel.rel_type in types:
				var before: int = rel.affection
				rel.modify_affection(aff_delta)
				var diff: int = rel.affection - before
				var diff_str := ("+" if diff >= 0 else "") + str(diff)
				var rel_emoji := _get_rel_emoji(rel)
				_add_log_entry(rel_emoji + " [b]" + rel.person_name + "[/b] — " + reaction_text + "  ❤️ " + diff_str, emoji)


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

	if event.log_only or event.choices.is_empty():
		if not event.choices.is_empty():
			var results := GameManager.apply_event_choice(event, 0)
			_add_choice_result_summary(results)
		if GameManager.has_pending_events():
			await get_tree().create_timer(0.2).timeout
			_process_next_event()
		return

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

	var results := GameManager.apply_event_choice(event, choice_index)
	_update_display()
	_add_choice_result_summary(results)

	if GameManager.has_pending_events():
		await get_tree().create_timer(0.3).timeout
		_process_next_event()


func _add_choice_result_summary(results: Dictionary) -> void:
	var parts: Array[String] = []
	var stat_icons := {
		"happiness": "😄", "health": "❤️", "intelligence": "🧠",
		"charisma": "💬", "appearance": "✨", "morality": "⚖️",
		"trauma": "💔", "mental_stability": "🧘", "attachment_profile": "🤝",
		"cognitive_development": "🔬", "temperament": "🌡️", "money": "💰"
	}
	for key in results:
		if key == "new_trait":
			var trait_key := "TRAIT_" + (results[key] as String).to_upper()
			parts.append("🌟 " + tr("NEW_TRAIT") + ": " + tr(trait_key))
			continue
		var val := int(results[key])
		if val == 0:
			continue
		var icon: String = stat_icons.get(key, "")
		if icon.is_empty():
			continue
		var sign := "+" if val > 0 else ""
		parts.append(icon + " " + sign + str(val))
	if not parts.is_empty():
		_add_log_entry("  ".join(parts), "📊")


func _handle_specific_activity(act_id: String) -> void:
	var c := GameManager.character
	match act_id:
		"baby_cry_loud":
			c.family_stress_level += 15
			c.morality = clampi(c.morality + 2, 0, 100)
			_add_log_entry(tr("LOG_BABY_CRY_LOUD"), "😭")
			_apply_present_reactions([
				{
					"rel_types": [Relationship.RelType.FATHER, Relationship.RelType.MOTHER],
					"affection": -5,
					"reaction_text": tr("REL_REACT_CRY_PARENT"),
					"emoji": "😤"
				},
				{
					"rel_types": [Relationship.RelType.SIBLING],
					"affection": -3,
					"reaction_text": tr("REL_REACT_CRY_SIBLING"),
					"emoji": "😒"
				}
			])
			# Pai/Mãe solo com estresse crítico → pode colocar para adoção
			var is_single_parent := c.family_status in ["Pai Solo", "Mãe Solo"]
			if is_single_parent and c.family_stress_level >= 80:
				var solo_happy: int = c.father_happiness if c.family_status == "Pai Solo" else c.mother_happiness
				if solo_happy <= 25:
					var adoption_ev := EventManager.get_event_by_id("baby_put_for_adoption")
					if adoption_ev != null:
						_show_event_popup(adoption_ev)
						return
			# Choro ignorado pelo stress geral
			if c.family_stress_level >= 40:
				var ignored_ev := EventManager.get_event_by_id("baby_ignored_cry")
				if ignored_ev != null:
					_show_event_popup(ignored_ev)
					return
			_update_display()
		"baby_smile":
			c.family_stress_level = max(0, c.family_stress_level - 15)
			c.charisma = clampi(c.charisma + 2, 0, 100)
			_add_log_entry(tr("LOG_BABY_SMILE"), "😊")
			_apply_present_reactions([
				{
					"rel_types": [Relationship.RelType.FATHER, Relationship.RelType.MOTHER],
					"affection": 8,
					"reaction_text": tr("REL_REACT_SMILE_PARENT"),
					"emoji": "🥰"
				},
				{
					"rel_types": [Relationship.RelType.SIBLING],
					"affection": 5,
					"reaction_text": tr("REL_REACT_SMILE_SIBLING"),
					"emoji": "😄"
				}
			])
			_update_display()
		"baby_bite":
			c.family_stress_level += 30
			c.trauma = clampi(c.trauma + 5, 0, 100)
			_add_log_entry(tr("LOG_BABY_BITE"), "🦷")
			_apply_present_reactions([
				{
					"rel_types": [Relationship.RelType.FATHER, Relationship.RelType.MOTHER, Relationship.RelType.SIBLING],
					"affection": -15,
					"reaction_text": tr("REL_REACT_BITE"),
					"emoji": "😠"
				}
			])
			_update_display()
		"baby_sleep_well":
			c.health = clampi(c.health + 5, 0, 100)
			_add_log_entry(tr("LOG_BABY_SLEEP_WELL"), "😴")
			_apply_present_reactions([
				{
					"rel_types": [Relationship.RelType.FATHER, Relationship.RelType.MOTHER],
					"affection": 4,
					"reaction_text": tr("REL_REACT_SLEEP_PARENT"),
					"emoji": "😌"
				}
			])
			_update_display()
		"school":
			var act_study := func():
				c.intelligence = clampi(c.intelligence + 4, 0, 100)
				c.happiness = clampi(c.happiness - 3, 0, 100)
				_add_log_entry(tr("LOG_STUDY_HARD"), "📚")
				_update_display()
			var act_slack := func():
				c.intelligence = clampi(c.intelligence - 3, 0, 100)
				c.happiness = clampi(c.happiness + 4, 0, 100)
				_add_log_entry(tr("LOG_SLACK_OFF"), "💤")
				_update_display()
			var act_socialize := func():
				c.happiness = clampi(c.happiness + 2, 0, 100)
				_add_log_entry(tr("LOG_SCHOOL_SOCIALIZE"), "💬")
				_update_display()
			_show_custom_menu("📚 " + tr("ACT_SCHOOL"), tr("CHOOSE_ACTION"), [
				{"label": "📖 " + tr("ACT_SCHOOL_STUDY_HARD") + " (+Int, -Hap)", "action": act_study},
				{"label": "💤 " + tr("ACT_SCHOOL_SLACK_OFF") + " (-Int, +Hap)", "action": act_slack},
				{"label": "👫 " + tr("ACT_SCHOOL_SOCIALIZE") + " (+Soc)", "action": act_socialize},
			])
		"crime":
			var act_shoplift := func():
				c.morality = clampi(c.morality - 5, 0, 100)
				var success := randf() > 0.4
				if success:
					c.money += randi_range(20, 100)
					_add_log_entry(tr("LOG_SHOPLIFT_SUCCESS"), "💰")
				else:
					c.happiness -= 10
					_add_log_entry(tr("LOG_SHOPLIFT_CAUGHT"), "🚨")
				_update_display()
			var act_gta := func():
				c.morality = clampi(c.morality - 15, 0, 100)
				var success := randf() > 0.7
				if success:
					c.money += randi_range(1000, 5000)
					_add_log_entry(tr("LOG_GTA_SUCCESS"), "💰")
				else:
					c.happiness -= 30
					_add_log_entry(tr("LOG_GTA_CAUGHT"), "🚨")
				_update_display()
			_show_custom_menu("🔪 " + tr("ACT_CRIME"), tr("CHOOSE_ACTION"), [
				{"label": "🕵️ " + tr("ACT_CRIME_SHOPLIFT"), "action": act_shoplift},
				{"label": "🚘 " + tr("ACT_CRIME_GRAND_THEFT"), "disabled": c.age < 14, "action": act_gta},
			])
		"health", "gym", "doctor":
			var act_gym := func():
				c.money -= 20
				c.health = clampi(c.health + 3, 0, 100)
				c.appearance = clampi(c.appearance + 2, 0, 100)
				_add_log_entry(tr("LOG_GYM_WORKOUT"), "💪")
				_update_display()
			var act_meditate := func():
				c.health = clampi(c.health + 1, 0, 100)
				c.happiness = clampi(c.happiness + 3, 0, 100)
				_add_log_entry(tr("LOG_MEDITATE"), "🧘")
				_update_display()
			var act_doctor := func():
				c.money -= 100
				c.health = clampi(c.health + 10, 0, 100)
				_add_log_entry(tr("LOG_DOCTOR"), "👨‍⚕️")
				_update_display()
			_show_custom_menu("🏥 " + tr("HEALTH"), tr("CHOOSE_ACTION"), [
				{"label": "💪 " + tr("ACT_GYM_WORKOUT") + " ($20)", "disabled": c.money < 20, "action": act_gym},
				{"label": "🧘 " + tr("ACT_MEDITATE") + " (Free)", "action": act_meditate},
				{"label": "👨‍⚕️ " + tr("ACT_DOCTOR_CHECKUP") + " ($100)", "disabled": c.money < 100, "action": act_doctor},
			])
		_:
			_show_category_actions(act_id)

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
			var cat: String = act.get("category", "")
			var act_id: String = act.get("action_id", cat)
			btn.pressed.connect(func():
				overlay.queue_free()
				_handle_specific_activity(act_id)
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


func _show_custom_menu(title: String, subtitle: String, choices: Array) -> void:
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

	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 28)
	t_lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox.add_child(t_lbl)

	if subtitle != "":
		var st_lbl := Label.new()
		st_lbl.text = subtitle
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_lbl.add_theme_font_size_override("font_size", 20)
		st_lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
		vbox.add_child(st_lbl)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	for choice in choices:
		var btn := Button.new()
		btn.text = choice["label"]
		btn.custom_minimum_size = Vector2(0, 68)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 14, 16, 12)
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 14, 16, 12)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
		
		if choice.has("disabled") and choice["disabled"]:
			btn.disabled = true
			btn.add_theme_color_override("font_color", ThemeSetup.TEXT_HINT)
		else:
			var bound_cb: Callable = choice["action"]
			btn.pressed.connect(func():
				overlay.queue_free()
				bound_cb.call()
			)
		vbox.add_child(btn)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
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
			# Ações exclusivas e vitais do modo Bebê ("Borboleta")
			activities.append({"label": "😭 Chorar Alto", "action_id": "baby_cry_loud", "tooltip": "Aumenta o estresse da família"})
			activities.append({"label": "😊 Sorrir / Dar Alegria", "action_id": "baby_smile", "tooltip": "Tenta aliviar o estresse da família"})
			activities.append({"label": "🦷 Morder / Causar Caos", "action_id": "baby_bite", "tooltip": "Aumenta trauma e explode o estresse"})
			activities.append({"label": "😴 Dormir nas horas exatas", "action_id": "baby_sleep_well", "tooltip": "Melhora sua própria saúde"})

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
		"talk":
			var act_talk_casual := func():
				rel.modify_affection(3)
				c.happiness = clampi(c.happiness + 1, 0, 100)
				_add_log_entry(tr("LOG_TALK_CASUAL").replace("{name}", rel.person_name), "💬")
				_update_display()
			var act_talk_deep := func():
				rel.modify_affection(5)
				rel.modify_respect(3)
				c.happiness = clampi(c.happiness + 2, 0, 100)
				_add_log_entry(tr("LOG_TALK_DEEP").replace("{name}", rel.person_name), "🗣️")
				_update_display()
			var act_talk_gossip := func():
				rel.modify_affection(2)
				c.morality = clampi(c.morality - 3, 0, 100)
				_add_log_entry(tr("LOG_TALK_GOSSIP").replace("{name}", rel.person_name), "🤫")
				_update_display()
			_show_custom_menu("💬 " + tr("REL_TALK") + " - " + rel.person_name, tr("CHOOSE_ACTION"), [
				{"label": "🗣️ " + tr("REL_TALK_CASUAL") + " (+Affection)", "action": act_talk_casual},
				{"label": "🧠 " + tr("REL_TALK_DEEP") + " (+Aff, +Respect)", "action": act_talk_deep},
				{"label": "🤫 " + tr("REL_TALK_GOSSIP") + " (+Aff, -Morality)", "action": act_talk_gossip},
			])
			return
		"gift":
			var act_chocolate := func():
				c.money -= 15
				rel.modify_affection(5)
				_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_CHOCOLATE")), "🍫")
				_update_display()
			var act_book := func():
				c.money -= 30
				rel.modify_affection(8)
				_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_BOOK")), "📖")
				_update_display()
			var act_watch := func():
				c.money -= 200
				rel.modify_affection(20)
				_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_WATCH")), "⌚")
				_update_display()
			var act_car := func():
				c.money -= 25000
				rel.modify_affection(100)
				_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_CAR")), "🚗")
				_update_display()
			_show_custom_menu("🎁 " + tr("REL_GIFT") + " - " + rel.person_name, tr("CHOOSE_GIFT"), [
				{"label": "🍫 " + tr("GIFT_CHOCOLATE") + " ($15)", "disabled": c.money < 15, "action": act_chocolate},
				{"label": "📖 " + tr("GIFT_BOOK") + " ($30)", "disabled": c.money < 30, "action": act_book},
				{"label": "⌚ " + tr("GIFT_WATCH") + " ($200)", "disabled": c.money < 200, "action": act_watch},
				{"label": "🚗 " + tr("GIFT_CAR") + " ($25000)", "disabled": c.money < 25000, "action": act_car},
			])
			return
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


func _show_achievements_overlay() -> void:
	var all_ach: Array = AchievementManager.get_all_achievements()

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	var panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var vbox_outer := VBoxContainer.new()
	vbox_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox_outer)

	var title := Label.new()
	title.text = "🏆 " + tr("ACHIEVEMENTS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
	vbox_outer.add_child(title)

	var unlocked_count := AchievementManager.get_unlocked_count()
	var total_count := all_ach.size()
	var progress_lbl := Label.new()
	progress_lbl.text = str(unlocked_count) + " / " + str(total_count) + " " + tr("ACHIEVEMENTS_UNLOCKED")
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 18)
	progress_lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
	vbox_outer.add_child(progress_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_outer.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for ach in all_ach:
		var id: String = ach.get("id", "")
		var is_unlocked: bool = AchievementManager.is_unlocked(id)
		var icon: String = ach.get("icon", "🏅")
		var text_key: String = ach.get("text_key", "")

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_bg := Color("#1E1E2E") if not is_unlocked else Color("#1B5E20")
		var card_style := ThemeSetup.make_flat_box(card_bg, 10, 14, 10)
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		var icon_lbl := Label.new()
		icon_lbl.text = icon if is_unlocked else "🔒"
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 36)
		card_vbox.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = tr(text_key) if is_unlocked else "???"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else ThemeSetup.TEXT_HINT)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(name_lbl)

		grid.add_child(card)

	var sep := HSeparator.new()
	vbox_outer.add_child(sep)

	var btn_close := Button.new()
	btn_close.text = "✕ " + tr("CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 56)
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_style := ThemeSetup.make_flat_box(Color("#C62828"), 14, 16, 12)
	btn_close.add_theme_stylebox_override("normal", close_style)
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color.WHITE)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox_outer.add_child(btn_close)

	bg.gui_input.connect(func(event_input: InputEvent):
		if event_input is InputEventMouseButton and event_input.pressed:
			overlay.queue_free()
	)

	add_child(overlay)


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
