extends Node

## EventManager — Loads, indexes, and serves events from JSON files

var _all_events: Array[EventData] = []
var _events_by_phase: Dictionary = {}  # phase_name -> Array[EventData]
var _events_by_id: Dictionary = {}  # id -> EventData
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_load_all_events()


func _load_all_events() -> void:
	_all_events.clear()
	_events_by_phase.clear()
	_events_by_id.clear()

	var event_files := [
		"res://data/events/baby_events.json",
		"res://data/events/child_events.json",
		"res://data/events/teen_events.json",
		"res://data/events/adult_events.json",
		"res://data/events/elder_events.json",
	]

	for file_path in event_files:
		if not FileAccess.file_exists(file_path):
			push_warning("EventManager: Event file not found: " + file_path)
			continue

		var file := FileAccess.open(file_path, FileAccess.READ)
		var json_text := file.get_as_text()
		file.close()

		var parsed = JSON.parse_string(json_text)
		if parsed == null:
			push_error("EventManager: Failed to parse JSON: " + file_path)
			continue

		var events_array: Array = parsed.get("events", [])
		for event_dict in events_array:
			var event := EventData.from_dict(event_dict)
			_all_events.append(event)
			_events_by_id[event.id] = event

			# Index by phase
			for phase in event.phases:
				if not _events_by_phase.has(phase):
					_events_by_phase[phase] = []
				_events_by_phase[phase].append(event)

	print("EventManager: Loaded ", _all_events.size(), " events")


func get_event_by_id(event_id: String) -> EventData:
	return _events_by_id.get(event_id, null)


func get_random_event(character: Character) -> EventData:
	var phase_name := character.get_phase_name()
	var candidates: Array = _events_by_phase.get(phase_name, [])

	if candidates.is_empty():
		return null

	# Filter by conditions and anti-repetition
	var valid: Array[EventData] = []
	var total_weight: int = 0
	for event in candidates:
		if event is EventData:
			if character.seen_events.has(event.id):
				continue
			if event.matches_character(character):
				valid.append(event)
				total_weight += event.weight

	if valid.is_empty():
		# If all events seen, allow repeats
		for event in candidates:
			if event is EventData and event.matches_character(character):
				valid.append(event)
				total_weight += event.weight

	if valid.is_empty():
		return null

	# Weighted random selection
	var roll := _rng.randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for event in valid:
		cumulative += event.weight
		if roll < cumulative:
			return event

	return valid[valid.size() - 1]


func get_random_event_by_category(character: Character, category: String) -> EventData:
	var phase_name := character.get_phase_name()
	var candidates: Array = _events_by_phase.get(phase_name, [])
	if candidates.is_empty():
		return null

	var valid: Array[EventData] = []
	var total_weight: int = 0
	for event in candidates:
		if event is EventData and event.category == category:
			if event.matches_character(character):
				valid.append(event)
				total_weight += event.weight

	if valid.is_empty():
		return null

	var roll := _rng.randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for event in valid:
		cumulative += event.weight
		if roll < cumulative:
			return event

	return valid[valid.size() - 1]


func get_events_for_phase(phase_name: String) -> Array:
	return _events_by_phase.get(phase_name, [])


func get_total_event_count() -> int:
	return _all_events.size()
