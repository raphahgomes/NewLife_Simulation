extends Control

## MainMenu — Entry point of the game

@onready var btn_new_life: Button = %BtnNewLife
@onready var btn_continue: Button = %BtnContinue
@onready var btn_past_lives: Button = %BtnPastLives
@onready var btn_settings: Button = %BtnSettings


func _ready() -> void:
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
