extends Control

## PauseMenu — In-game pause overlay with save, settings, and quit options

@onready var title_label: Label = %Title
@onready var btn_resume: Button = %BtnResume
@onready var btn_save: Button = %BtnSave
@onready var btn_settings: Button = %BtnSettings
@onready var btn_stats: Button = %BtnStats
@onready var btn_main_menu: Button = %BtnMainMenu
@onready var btn_quit: Button = %BtnQuit
@onready var save_feedback: Label = %SaveFeedback


func _ready() -> void:
	_localize()
	_style_buttons()
	btn_resume.pressed.connect(_on_resume)
	btn_save.pressed.connect(_on_save)
	btn_settings.pressed.connect(_on_settings)
	btn_stats.pressed.connect(_on_stats)
	btn_main_menu.pressed.connect(_on_main_menu)
	btn_quit.pressed.connect(_on_quit)
	save_feedback.text = ""
	get_tree().paused = true


func _localize() -> void:
	title_label.text = tr("PAUSE_TITLE")
	btn_resume.text = tr("PAUSE_RESUME")
	btn_save.text = tr("PAUSE_SAVE")
	btn_settings.text = tr("PAUSE_SETTINGS")
	btn_stats.text = tr("PAUSE_STATS")
	btn_main_menu.text = tr("PAUSE_MAIN_MENU")
	btn_quit.text = tr("PAUSE_QUIT")


func _style_buttons() -> void:
	var buttons := [btn_resume, btn_save, btn_settings, btn_stats, btn_main_menu, btn_quit]
	var colors := [
		Color("#2E7D32"),  # Resume - green
		Color("#1565C0"),  # Save - blue
		Color("#6A1B9A"),  # Settings - purple
		Color("#00838F"),  # Stats - teal
		Color("#E65100"),  # Main Menu - orange
		Color("#B71C1C"),  # Quit - red
	]
	for i in buttons.size():
		var btn: Button = buttons[i]
		var color: Color = colors[i]
		if btn == null:
			continue
		var normal := ThemeSetup.make_flat_box(color, 12, 16, 10)
		var hover := ThemeSetup.make_flat_box(color.lightened(0.2), 12, 16, 10)
		var pressed := ThemeSetup.make_flat_box(color.darkened(0.15), 12, 16, 10)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_font_size_override("font_size", 18)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
		get_viewport().set_input_as_handled()


func _on_resume() -> void:
	get_tree().paused = false
	queue_free()


func _on_save() -> void:
	if GameManager.character:
		SaveManager.auto_save(GameManager.character)
		save_feedback.text = tr("SAVE_SUCCESS")
		save_feedback.modulate = Color.GREEN
		var tween := create_tween()
		tween.tween_property(save_feedback, "modulate:a", 0.0, 2.0).set_delay(1.0)


func _on_settings() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/screens/Settings.tscn")
	queue_free()


func _on_stats() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/screens/Statistics.tscn")
	queue_free()


func _on_main_menu() -> void:
	if GameManager.character:
		SaveManager.auto_save(GameManager.character)
	get_tree().paused = false
	GameManager.is_game_active = false
	SceneTransition.change_scene("res://scenes/screens/MainMenu.tscn")
	queue_free()


func _on_quit() -> void:
	if GameManager.character:
		SaveManager.auto_save(GameManager.character)
	get_tree().quit()
