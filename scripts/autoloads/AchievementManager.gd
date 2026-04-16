extends Node

## AchievementManager — Tracks and awards achievements

signal achievement_unlocked(achievement_id: String, text_key: String, icon: String)

var _achievements: Array = []
var _unlocked: Dictionary = {}  # id -> true


func _ready() -> void:
	_load_achievements()
	_load_unlocked()
	_connect_signals()


func _load_achievements() -> void:
	var file := FileAccess.open("res://data/achievements/achievements.json", FileAccess.READ)
	if file == null:
		push_error("AchievementManager: Could not load achievements.json")
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary and parsed.has("achievements"):
		_achievements = parsed["achievements"]


func _load_unlocked() -> void:
	var saved: Variant = SaveManager.load_setting("unlocked_achievements", {})
	if saved is Dictionary:
		_unlocked = saved


func _save_unlocked() -> void:
	SaveManager.save_setting("unlocked_achievements", _unlocked)


func _connect_signals() -> void:
	if GameManager:
		GameManager.year_advanced.connect(_on_year_advanced)
		GameManager.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	_check_all()


func _on_year_advanced(_age: int) -> void:
	_check_all()


func _check_all() -> void:
	var character: Character = GameManager.character
	if character == null:
		return

	for ach in _achievements:
		var id: String = ach.get("id", "")
		if id == "" or _unlocked.has(id):
			continue
		if _check_condition(ach.get("condition", {}), character):
			_unlock(ach)


func _check_condition(condition: Dictionary, character: Character) -> bool:
	var type: String = condition.get("type", "")
	var value: Variant = condition.get("value", 0)

	match type:
		"age_reached":
			return character.age >= int(value)
		"has_career":
			return character.current_career != ""
		"is_married":
			return character.is_married
		"has_children":
			return character.children.size() > 0
		"min_money":
			return character.get_net_worth() >= int(value)
		"max_money":
			return character.get_net_worth() <= int(value)
		"min_stat":
			var stat_name: String = condition.get("stat", "")
			var stat_val: int = character.get(stat_name) if stat_name in character else 0
			return stat_val >= int(value)
		"max_stat":
			var stat_name: String = condition.get("stat", "")
			var stat_val: int = character.get(stat_name) if stat_name in character else 100
			return stat_val <= int(value)
		"min_education":
			return character.education >= int(value)
		"events_survived":
			return character.seen_events.size() >= int(value)
		"min_traits":
			return character.traits.size() >= int(value)
		"completed_lives":
			return SaveManager.get_completed_lives().size() >= int(value)
		_:
			return false


func _unlock(ach: Dictionary) -> void:
	var id: String = ach.get("id", "")
	_unlocked[id] = true
	_save_unlocked()
	achievement_unlocked.emit(id, ach.get("text_key", ""), ach.get("icon", "🏆"))


func is_unlocked(achievement_id: String) -> bool:
	return _unlocked.has(achievement_id)


func get_all_achievements() -> Array:
	return _achievements


func get_unlocked_count() -> int:
	return _unlocked.size()


func get_total_count() -> int:
	return _achievements.size()


func get_progress_percent() -> float:
	if _achievements.size() == 0:
		return 0.0
	return float(_unlocked.size()) / float(_achievements.size()) * 100.0
