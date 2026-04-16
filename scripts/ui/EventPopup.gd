extends Control

## EventPopup — Shows an event with choice buttons

signal choice_made(choice_index: int)

@onready var event_title: Label = %EventTitle
@onready var event_description: RichTextLabel = %EventDescription
@onready var choices_container: VBoxContainer = %ChoicesContainer

var _event: EventData


func setup(event: EventData) -> void:
	_event = event


func _ready() -> void:
	if _event:
		_populate()


func _populate() -> void:
	# Style the popup card with a teal border
	var card := $CenterCard
	if card:
		var card_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 20, 24, 20, 2, ThemeSetup.PRIMARY)
		card.add_theme_stylebox_override("panel", card_style)

	# Title
	event_title.text = tr(_event.text_key)
	event_title.add_theme_font_size_override("font_size", 22)
	event_title.add_theme_color_override("font_color", ThemeSetup.PRIMARY)

	# Description — fall back to title if _DESC key is missing
	var desc_key := _event.text_key + "_DESC"
	var desc_text := tr(desc_key)
	if desc_text == desc_key:
		event_description.visible = false
	else:
		event_description.text = desc_text

	# Clear existing choice buttons
	for child in choices_container.get_children():
		child.queue_free()

	# Create choice buttons
	for i in _event.choices.size():
		var choice: Dictionary = _event.choices[i]
		var btn := Button.new()
		btn.text = tr(choice.get("text_key", "CHOICE_" + str(i)))
		btn.custom_minimum_size = Vector2(0, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_normal := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 12, 16, 12, 1, ThemeSetup.PRIMARY.darkened(0.3))
		var btn_hover := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 12, 16, 12)
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)


func _on_choice_pressed(index: int) -> void:
	choice_made.emit(index)
	queue_free()
