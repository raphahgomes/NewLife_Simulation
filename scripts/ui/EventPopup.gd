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
	# Set event text
	event_title.text = tr(_event.text_key)
	event_description.text = tr(_event.text_key + "_DESC")

	# Clear existing choice buttons
	for child in choices_container.get_children():
		child.queue_free()

	# Create choice buttons
	for i in _event.choices.size():
		var choice: Dictionary = _event.choices[i]
		var btn := Button.new()
		btn.text = tr(choice.get("text_key", "CHOICE_" + str(i)))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)


func _on_choice_pressed(index: int) -> void:
	choice_made.emit(index)
	queue_free()
