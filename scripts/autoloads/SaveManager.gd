extends Node

## SaveManager — Handles saving and loading game state

const SAVE_DIR := "user://saves/"
const AUTO_SAVE_FILE := "autosave.json"
const COMPLETED_LIVES_FILE := "user://completed_lives.json"
const SETTINGS_FILE := "user://settings.json"
const MAX_SAVE_SLOTS := 5

var _settings_cache: Dictionary = {}


func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_load_settings_cache()


# === Auto Save ===

func auto_save(character: Character) -> void:
	_save_to_file(SAVE_DIR + AUTO_SAVE_FILE, character)


func load_auto_save() -> Character:
	return _load_from_file(SAVE_DIR + AUTO_SAVE_FILE)


func has_auto_save() -> bool:
	return FileAccess.file_exists(SAVE_DIR + AUTO_SAVE_FILE)


# === Manual Save Slots ===

func save_to_slot(slot: int, character: Character) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	var path := SAVE_DIR + "slot_" + str(slot) + ".json"
	_save_to_file(path, character)
	return true


func load_from_slot(slot: int) -> Character:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return null
	var path := SAVE_DIR + "slot_" + str(slot) + ".json"
	return _load_from_file(path)


func has_save_in_slot(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	return FileAccess.file_exists(SAVE_DIR + "slot_" + str(slot) + ".json")


func get_slot_info(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_" + str(slot) + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var character := _load_from_file(path)
	if character == null:
		return {}
	return {
		"name": character.get_full_name(),
		"age": character.age,
		"phase": character.get_phase_name(),
		"country": character.country
	}


# === Completed Lives ===

func save_completed_life(character: Character) -> void:
	var lives := _load_completed_lives()
	var summary := {
		"name": character.get_full_name(),
		"country": character.country,
		"birth_year": character.birth_year,
		"death_age": character.age,
		"cause_of_death": character.cause_of_death,
		"career": character.current_career,
		"net_worth": character.get_net_worth(),
		"traits": character.traits,
		"education": character.education,
		"social_class": character.social_class,
		"key_events": _extract_key_events(character),
		"seed": character.world_seed
	}
	lives.append(summary)

	var file := FileAccess.open(COMPLETED_LIVES_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(lives, "\t"))
		file.close()


func get_completed_lives() -> Array:
	return _load_completed_lives()


# === Private Methods ===

func _save_to_file(path: String, character: Character) -> void:
	var data := character.to_save_dict()
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("SaveManager: Failed to write save file: " + path)


func _load_from_file(path: String) -> Character:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		return Character.from_save_dict(parsed)
	return null


func _load_completed_lives() -> Array:
	if not FileAccess.file_exists(COMPLETED_LIVES_FILE):
		return []
	var file := FileAccess.open(COMPLETED_LIVES_FILE, FileAccess.READ)
	if file == null:
		return []
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Array:
		return parsed
	return []


func _extract_key_events(character: Character) -> Array:
	var key_events: Array = []
	for entry in character.event_log:
		var cat: String = entry.get("category", "")
		if cat in ["career", "marriage", "crime", "death", "education", "health_major"]:
			key_events.append(entry)
	# Limit to last 10
	if key_events.size() > 10:
		key_events = key_events.slice(key_events.size() - 10)
	return key_events


func delete_auto_save() -> void:
	if FileAccess.file_exists(SAVE_DIR + AUTO_SAVE_FILE):
		DirAccess.remove_absolute(SAVE_DIR + AUTO_SAVE_FILE)


func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + "slot_" + str(slot) + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# === Settings ===

func save_setting(key: String, value: Variant) -> void:
	_settings_cache[key] = value
	_write_settings()


func load_setting(key: String, default_value: Variant = null) -> Variant:
	return _settings_cache.get(key, default_value)


func _load_settings_cache() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE):
		_settings_cache = {}
		return
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		_settings_cache = {}
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		_settings_cache = parsed
	else:
		_settings_cache = {}


func _write_settings() -> void:
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_settings_cache, "\t"))
		file.close()
