extends Control

## MainMenu — Entry point of the game

@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var btn_new_life: Button = %BtnNewLife
@onready var btn_continue: Button = %BtnContinue
@onready var btn_past_lives: Button = %BtnPastLives
@onready var btn_settings: Button = %BtnSettings


func _ready() -> void:
	_style_title()
	_style_new_life_button()

	# Localize buttons
	btn_new_life.text = tr("NEW_LIFE")
	btn_continue.text = tr("CONTINUE")
	btn_past_lives.text = tr("PAST_LIVES")
	btn_settings.text = tr("SETTINGS")

	# Show/hide continue based on save
	btn_continue.visible = SaveManager.has_auto_save()

	# Connect signals
	btn_new_life.pressed.connect(_on_new_life)
	btn_continue.pressed.connect(_on_continue)
	btn_past_lives.pressed.connect(_on_past_lives)
	btn_settings.pressed.connect(_on_settings)


func _style_title() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", ThemeSetup.PRIMARY)
	if subtitle_label:
		subtitle_label.add_theme_font_size_override("font_size", 22)
		subtitle_label.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)


func _style_new_life_button() -> void:
	if btn_new_life == null:
		return
	var normal := ThemeSetup.make_flat_box(ThemeSetup.ACCENT_DARK, 16, 24, 16)
	var hover := ThemeSetup.make_flat_box(ThemeSetup.ACCENT, 16, 24, 16)
	var pressed := ThemeSetup.make_flat_box(ThemeSetup.ACCENT.darkened(0.15), 16, 24, 16)
	btn_new_life.add_theme_stylebox_override("normal", normal)
	btn_new_life.add_theme_stylebox_override("hover", hover)
	btn_new_life.add_theme_stylebox_override("pressed", pressed)
	btn_new_life.add_theme_font_size_override("font_size", 22)


func _on_new_life() -> void:
	GameManager.start_new_life()
	get_tree().change_scene_to_file("res://scenes/screens/GameHUD.tscn")


func _on_continue() -> void:
	var character := SaveManager.load_auto_save()
	if character:
		GameManager.character = character
		GameManager.is_game_active = true
		get_tree().change_scene_to_file("res://scenes/screens/GameHUD.tscn")


func _on_past_lives() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/PastLives.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")
