extends Control

## Statistics — Displays lifetime statistics for the current character

@onready var title_label: Label = %Title
@onready var stats_list: VBoxContainer = %StatsList
@onready var btn_back: Button = %BtnBack


func _ready() -> void:
	title_label.text = tr("STATS_TITLE")
	btn_back.text = tr("BACK")
	btn_back.pressed.connect(_on_back)
	_populate_stats()


func _populate_stats() -> void:
	for child in stats_list.get_children():
		child.queue_free()

	var ch := GameManager.character
	if ch == null:
		var label := Label.new()
		label.text = tr("NO_STATISTICS")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_list.add_child(label)
		return

	var stats := ch.statistics
	var entries: Array[Array] = [
		[tr("STAT_TOTAL_EVENTS"), str(stats.get("total_events", 0))],
		[tr("STAT_TOTAL_CHOICES"), str(stats.get("total_choices", 0))],
		[tr("STAT_MAX_MONEY"), "$" + _format_money(stats.get("max_money", 0.0))],
		[tr("STAT_MIN_MONEY"), "$" + _format_money(stats.get("min_money", 0.0))],
		[tr("STAT_CAREERS_HELD"), str(stats.get("careers_held", 0))],
		[tr("STAT_PROMOTIONS"), str(stats.get("promotions", 0))],
		[tr("STAT_RELATIONSHIPS"), str(stats.get("relationships_started", 0))],
		[tr("STAT_TRAITS_GAINED"), str(stats.get("traits_gained", 0))],
	]

	for entry in entries:
		var card := PanelContainer.new()
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(hbox)

		var key_label := Label.new()
		key_label.text = entry[0]
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(key_label)

		var val_label := Label.new()
		val_label.text = entry[1]
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(val_label)

		stats_list.add_child(card)


func _format_money(value: float) -> String:
	if absf(value) >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	elif absf(value) >= 1_000:
		return "%.1fK" % (value / 1_000.0)
	else:
		return "%.0f" % value


func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/screens/GameHUD.tscn")
