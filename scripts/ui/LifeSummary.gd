extends Control

## LifeSummary — Shows summary after character dies

@onready var name_label: Label = %NameLabel
@onready var life_span: Label = %LifeSpan
@onready var career_label: Label = %CareerLabel
@onready var wealth_label: Label = %WealthLabel
@onready var education_label: Label = %EducationLabel
@onready var cause_label: Label = %CauseLabel
@onready var traits_label: Label = %TraitsLabel
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var btn_new_life: Button = %BtnNewLife


func _ready() -> void:
	var c := GameManager.character
	if c == null:
		return

	_populate(c)

	btn_new_life.text = tr("NEW_LIFE")
	btn_new_life.pressed.connect(_on_new_life)


func _populate(c: Character) -> void:
	name_label.text = c.get_full_name()
	life_span.text = str(c.birth_year) + " – " + str(c.birth_year + c.age) + " (" + str(c.age) + " " + tr("YEARS") + ")"

	career_label.text = tr("CAREER") + ": " + (tr("CAREER_" + c.current_career.to_upper()) if c.current_career != "" else tr("NONE"))
	wealth_label.text = tr("NET_WORTH") + ": $" + str(int(c.get_net_worth()))

	var edu_names := {
		Character.Education.NONE: "NONE",
		Character.Education.PRIMARY: "PRIMARY",
		Character.Education.SECONDARY: "SECONDARY",
		Character.Education.TECHNICAL: "TECHNICAL",
		Character.Education.COLLEGE: "COLLEGE",
		Character.Education.POSTGRAD: "POSTGRAD"
	}
	education_label.text = tr("EDUCATION") + ": " + tr(edu_names.get(c.education, "NONE"))
	cause_label.text = tr("CAUSE_OF_DEATH") + ": " + tr(c.cause_of_death)

	if c.traits.is_empty():
		traits_label.text = tr("TRAITS") + ": —"
	else:
		var trait_names: Array[String] = []
		for t in c.traits:
			trait_names.append(tr("TRAIT_" + t.to_upper()))
		traits_label.text = tr("TRAITS") + ": " + ", ".join(trait_names)

	# Timeline
	for child in timeline_container.get_children():
		child.queue_free()

	for entry in c.event_log:
		var label := Label.new()
		label.text = "🔹 " + tr("AGE") + " " + str(entry.get("age", 0)) + " — " + tr(entry.get("text_key", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		timeline_container.add_child(label)


func _on_new_life() -> void:
	SaveManager.delete_auto_save()
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
