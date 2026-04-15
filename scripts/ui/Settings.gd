extends Control

## Settings — Language, sound, font size

@onready var language_option: OptionButton = %LanguageOption
@onready var sound_slider: HSlider = %SoundSlider
@onready var font_size_slider: HSlider = %FontSizeSlider
@onready var btn_back: Button = %BtnBack

const SETTINGS_PATH := "user://settings.json"

var _languages := {
	"en": "English",
	"pt_BR": "Português (BR)"
}


func _ready() -> void:
	# Populate language dropdown
	var idx := 0
	var current_locale := TranslationServer.get_locale()
	for code in _languages:
		language_option.add_item(_languages[code], idx)
		language_option.set_item_metadata(idx, code)
		if code == current_locale:
			language_option.selected = idx
		idx += 1

	# Load saved settings
	_load_settings()

	# Connect signals
	language_option.item_selected.connect(_on_language_changed)
	sound_slider.value_changed.connect(_on_sound_changed)
	font_size_slider.value_changed.connect(_on_font_size_changed)
	btn_back.pressed.connect(_on_back)


func _on_language_changed(index: int) -> void:
	var code: String = language_option.get_item_metadata(index)
	TranslationServer.set_locale(code)
	_save_settings()


func _on_sound_changed(value: float) -> void:
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	_save_settings()


func _on_font_size_changed(_value: float) -> void:
	# Font size will be applied through theme overrides
	_save_settings()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _save_settings() -> void:
	var data := {
		"locale": TranslationServer.get_locale(),
		"sound_volume": sound_slider.value,
		"font_size": font_size_slider.value
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data is Dictionary:
		if data.has("locale"):
			TranslationServer.set_locale(data["locale"])
		if data.has("sound_volume"):
			sound_slider.value = data["sound_volume"]
		if data.has("font_size"):
			font_size_slider.value = data["font_size"]
