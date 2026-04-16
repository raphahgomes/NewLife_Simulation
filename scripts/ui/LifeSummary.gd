extends Control

## LifeSummary — Shows summary after character dies

@onready var name_label: Label = %NameLabel
@onready var life_span: Label = %LifeSpan
@onready var career_label: Label = %CareerLabel
@onready var wealth_label: Label = %WealthLabel
@onready var education_label: Label = %EducationLabel
@onready var cause_label: Label = %CauseLabel
@onready var traits_label: Label = %TraitsLabel
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var btn_new_life: Button = %BtnNewLife


func _ready() -> void:
	var c := GameManager.character
	if c == null:
		return

	_populate(c)

	btn_new_life.text = tr("NEW_LIFE")
	btn_new_life.pressed.connect(_on_new_life)
	
	_add_monetization_options(c)


func _add_monetization_options(c: Character) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	btn_new_life.get_parent().add_child(hbox)
	btn_new_life.get_parent().move_child(hbox, btn_new_life.get_index())
	
	var btn_revive := Button.new()
	var revive_label = "🎥 " + tr("REVIVE_AD")
	if AdManager.has_premium:
		revive_label = "💎 " + tr("REV_VIP_SKIP")
	
	btn_revive.text = revive_label
	btn_revive.custom_minimum_size = Vector2(250, 60)
	var style1 := ThemeSetup.make_flat_box(ThemeSetup.COLOR_HEALTH, 14, 16, 12)
	btn_revive.add_theme_stylebox_override("normal", style1)
	btn_revive.add_theme_font_size_override("font_size", 22)
	btn_revive.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(btn_revive)
	
	btn_revive.pressed.connect(func():
		btn_revive.disabled = true
		AdManager.show_rewarded_ad("revive")
	)

	if not AdManager.has_premium:
		var btn_premium := Button.new()
		btn_premium.text = tr("BUY_PREMIUM")
		btn_premium.custom_minimum_size = Vector2(300, 60)
		var style_vip := ThemeSetup.make_flat_box(Color("#9c27b0"), 14, 16, 12)
		btn_premium.add_theme_stylebox_override("normal", style_vip)
		btn_premium.add_theme_font_size_override("font_size", 18)
		btn_premium.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(btn_premium)
		
		btn_premium.pressed.connect(func():
			AdManager.buy_premium()
			btn_premium.queue_free()
			btn_revive.text = "💎 " + tr("REV_VIP_SKIP")
		)
	
	AdManager.rewarded_ad_completed.connect(func(reward_type: String):
		if reward_type == "revive":
			c.alive = true
			c.health = 50
			c.cause_of_death = ""
			GameManager.save_game()
			SceneTransition.change_scene("res://scenes/screens/GameHUD.tscn")
	)

	# Check for children
	var children: Array[Relationship] = []
	for rel in c.relationships:
		if rel is Relationship and rel.rel_type == Relationship.RelType.CHILD and rel.alive:
			children.append(rel)
			
	if children.size() > 0:
		var btn_legacy := Button.new()
		btn_legacy.text = "👑 " + tr("PLAY_AS_CHILD")
		btn_legacy.custom_minimum_size = Vector2(250, 60)
		var style2 := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 14, 16, 12)
		btn_legacy.add_theme_stylebox_override("normal", style2)
		btn_legacy.add_theme_font_size_override("font_size", 22)
		btn_legacy.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(btn_legacy)
		
		btn_legacy.pressed.connect(func():
			_show_child_selection(c, children)
		)

func _show_child_selection(c: Character, children: Array[Relationship]) -> void:
	var popup := AcceptDialog.new()
	popup.title = tr("SELECT_CHILD")
	popup.size = Vector2(400, 400)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	popup.add_child(vbox)
	
	for child in children:
		var btn := Button.new()
		btn.text = child.person_name + " (" + str(child.person_age) + " " + tr("YEARS") + ")"
		btn.custom_minimum_size = Vector2(0, 50)
		var style3 := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 12, 16, 12)
		btn.add_theme_stylebox_override("normal", style3)
		btn.add_theme_font_size_override("font_size", 20)
		vbox.add_child(btn)
		btn.pressed.connect(func():
			GameManager.start_legacy_life(c, child)
			popup.queue_free()
			SceneTransition.change_scene("res://scenes/screens/GameHUD.tscn")
		)
	
	add_child(popup)
	popup.popup_centered()


func _populate(c: Character) -> void:
	name_label.text = c.get_full_name()
	life_span.text = str(c.birth_year) + " – " + str(c.birth_year + c.age) + " (" + str(c.age) + " " + tr("YEARS") + ")"

	career_label.text = tr("CAREER") + ": " + (tr("CAREER_" + c.current_career.to_upper()) if c.current_career != "" else tr("NONE"))
	wealth_label.text = tr("NET_WORTH") + ": $" + str(int(c.get_net_worth()))

	var edu_names := {
		Character.Education.NONE: "NONE",
		Character.Education.PRIMARY: "PRIMARY",
		Character.Education.SECONDARY: "SECONDARY",
		Character.Education.TECHNICAL: "TECHNICAL",
		Character.Education.COLLEGE: "COLLEGE",
		Character.Education.POSTGRAD: "POSTGRAD"
	}
	education_label.text = tr("EDUCATION") + ": " + tr(edu_names.get(c.education, "NONE"))
	cause_label.text = tr("CAUSE_OF_DEATH") + ": " + tr(c.cause_of_death)

	if c.traits.is_empty():
		traits_label.text = tr("TRAITS") + ": —"
	else:
		var trait_names: Array[String] = []
		for t in c.traits:
			trait_names.append(tr("TRAIT_" + t.to_upper()))
		traits_label.text = tr("TRAITS") + ": " + ", ".join(trait_names)

	# Timeline
	for child in timeline_container.get_children():
		child.queue_free()

	for entry in c.event_log:
		var label := Label.new()
		label.text = "🔹 " + tr("AGE") + " " + str(entry.get("age", 0)) + " — " + tr(entry.get("text_key", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		timeline_container.add_child(label)


func _on_new_life() -> void:
	SaveManager.delete_auto_save()
	SceneTransition.change_scene("res://scenes/screens/MainMenu.tscn")
