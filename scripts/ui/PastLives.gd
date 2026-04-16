extends Control

## PastLives — Shows completed lives history

@onready var lives_list: VBoxContainer = %LivesList
@onready var btn_back: Button = %BtnBack


func _ready() -> void:
	btn_back.text = tr("BACK")
	btn_back.pressed.connect(_on_back)
	_populate_lives()


func _populate_lives() -> void:
	for child in lives_list.get_children():
		child.queue_free()

	var lives := SaveManager.get_completed_lives()
	if lives.is_empty():
		var label := Label.new()
		label.text = tr("NO_PAST_LIVES")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lives_list.add_child(label)
		return

	for life_data in lives:
		var card := PanelContainer.new()
		var vbox := VBoxContainer.new()
		card.add_child(vbox)

		var name_label := Label.new()
		name_label.text = life_data.get("name", "Unknown")
		vbox.add_child(name_label)

		var info_label := Label.new()
		var years_lived: int = life_data.get("age", 0)
		var career_text: String = life_data.get("career", tr("NONE"))
		info_label.text = str(years_lived) + " " + tr("YEARS") + " · " + tr(career_text)
		vbox.add_child(info_label)

		var wealth_label := Label.new()
		wealth_label.text = tr("NET_WORTH") + ": $" + str(life_data.get("net_worth", 0))
		vbox.add_child(wealth_label)

		lives_list.add_child(card)


func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/screens/MainMenu.tscn")
