extends Control

## NewLifeSetup — Full character creation screen

@onready var btn_back: Button = %BtnBack
@onready var header_title: Label = %HeaderTitle
@onready var avatar_preview: Label = %AvatarPreview

# Identity
@onready var input_first_name: LineEdit = %InputFirstName
@onready var input_last_name: LineEdit = %InputLastName
@onready var btn_random_first: Button = %BtnRandomFirst
@onready var btn_random_last: Button = %BtnRandomLast
@onready var btn_male: Button = %BtnMale
@onready var btn_female: Button = %BtnFemale
@onready var btn_brazil: Button = %BtnBrazil
@onready var btn_usa: Button = %BtnUSA

# Family
@onready var btn_class_low: Button = %BtnClassLow
@onready var btn_class_mid: Button = %BtnClassMid
@onready var btn_class_high: Button = %BtnClassHigh
@onready var btn_both_parents: Button = %BtnBothParents
@onready var btn_single_father: Button = %BtnSingleFather
@onready var btn_single_mother: Button = %BtnSingleMother
@onready var btn_orphan: Button = %BtnOrphan
@onready var btn_sib_minus: Button = %BtnSibMinus
@onready var btn_sib_plus: Button = %BtnSibPlus
@onready var lbl_sib_count: Label = %LblSibCount

# Attributes
@onready var slider_health: HSlider = %SliderHealth
@onready var slider_intel: HSlider = %SliderIntel
@onready var slider_charisma: HSlider = %SliderCharisma
@onready var slider_appearance: HSlider = %SliderAppearance
@onready var slider_luck: HSlider = %SliderLuck
@onready var slider_temper: HSlider = %SliderTemper
@onready var val_health: Label = %ValHealth
@onready var val_intel: Label = %ValIntel
@onready var val_charisma: Label = %ValCharisma
@onready var val_appearance: Label = %ValAppearance
@onready var val_luck: Label = %ValLuck
@onready var val_temper: Label = %ValTemper
@onready var attr_info: Label = %AttrInfo

@onready var btn_random_all: Button = %BtnRandomAll
@onready var summary_label: RichTextLabel = %SummaryLabel
@onready var btn_start: Button = %BtnStart

# Section labels
@onready var section_identity: Label = %SectionIdentity
@onready var section_family: Label = %SectionFamily
@onready var section_attributes: Label = %SectionAttributes
@onready var section_summary: Label = %SectionSummary

const MAX_ATTR_POINTS := 330
const MIN_ATTR := 10
const MAX_ATTR := 100

var _selected_gender: String = "male"
var _selected_country: String = "BR"
var _selected_class: int = 1  # 0=low, 1=mid, 2=high
var _selected_parents: int = 0  # 0=both, 1=father_only, 2=mother_only, 3=orphan
var _sibling_count: int = 0
var _names_data: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _updating_slider := false


func _ready() -> void:
	_rng.randomize()
	_load_names()
	_style_ui()
	_localize_ui()
	_connect_signals()
	_randomize_name()
	_update_summary()


# ── DATA ──

func _load_names() -> void:
	for lang_key in ["pt_BR", "en"]:
		var filename := "names_ptbr.json" if lang_key == "pt_BR" else "names_en.json"
		var path := "res://data/names/" + filename
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			var json_text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				_names_data[lang_key] = parsed


# ── STYLING ──

func _style_ui() -> void:
	# Background
	$Background.color = ThemeSetup.BG_DARK

	# Header
	var header := $ScrollContainer/MainMargin/MainVBox/HeaderPanel
	header.add_theme_stylebox_override("panel", ThemeSetup.make_flat_box(ThemeSetup.PRIMARY, 0, 16, 12))
	header_title.add_theme_font_size_override("font_size", 22)
	header_title.add_theme_color_override("font_color", Color.WHITE)
	btn_back.add_theme_font_size_override("font_size", 22)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	var back_style := ThemeSetup.make_flat_box(Color.TRANSPARENT, 8, 8, 8)
	btn_back.add_theme_stylebox_override("normal", back_style)
	btn_back.add_theme_stylebox_override("hover", ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 8, 8, 8))

	# Avatar
	avatar_preview.add_theme_font_size_override("font_size", 64)

	# Section headers
	for section in [section_identity, section_family, section_attributes, section_summary]:
		section.add_theme_font_size_override("font_size", 18)
		section.add_theme_color_override("font_color", ThemeSetup.PRIMARY)

	# Attribute info
	attr_info.add_theme_font_size_override("font_size", 14)
	attr_info.add_theme_color_override("font_color", ThemeSetup.ACCENT)

	# Toggle button groups styling
	_style_toggle_group([btn_male, btn_female])
	_style_toggle_group([btn_brazil, btn_usa])
	_style_toggle_group([btn_class_low, btn_class_mid, btn_class_high])
	_style_toggle_group([btn_both_parents, btn_single_father, btn_single_mother, btn_orphan])

	# Random buttons
	for btn in [btn_random_first, btn_random_last]:
		btn.add_theme_stylebox_override("normal", ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 8, 4, 4))
		btn.add_theme_stylebox_override("hover", ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 8, 4, 4))

	# Sibling buttons
	for btn in [btn_sib_minus, btn_sib_plus]:
		btn.add_theme_stylebox_override("normal", ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 8, 8, 4))
		btn.add_theme_stylebox_override("hover", ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 8, 8, 4))
		btn.add_theme_font_size_override("font_size", 20)

	lbl_sib_count.add_theme_font_size_override("font_size", 20)
	lbl_sib_count.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)

	# Randomize all button
	btn_random_all.add_theme_stylebox_override("normal", ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 12, 16, 12))
	btn_random_all.add_theme_stylebox_override("hover", ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 12, 16, 12))
	btn_random_all.add_theme_font_size_override("font_size", 18)

	# Start button
	var start_normal := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY, 16, 24, 16)
	var start_hover := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.lightened(0.15), 16, 24, 16)
	btn_start.add_theme_stylebox_override("normal", start_normal)
	btn_start.add_theme_stylebox_override("hover", start_hover)
	btn_start.add_theme_font_size_override("font_size", 22)
	btn_start.add_theme_color_override("font_color", Color.WHITE)

	# Summary
	summary_label.add_theme_color_override("default_color", ThemeSetup.TEXT_PRIMARY)
	summary_label.add_theme_font_size_override("normal_font_size", 14)


func _style_toggle_group(buttons: Array) -> void:
	for btn in buttons:
		var off := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 10, 10, 8)
		var on := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY_DARK, 10, 10, 8, 2, ThemeSetup.PRIMARY)
		var hover := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT.lightened(0.1), 10, 10, 8)
		btn.add_theme_stylebox_override("normal", off)
		btn.add_theme_stylebox_override("pressed", on)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)


# ── LOCALIZATION ──

func _localize_ui() -> void:
	header_title.text = tr("NEW_LIFE_SETUP")
	section_identity.text = tr("SECTION_IDENTITY")
	section_family.text = tr("SECTION_FAMILY")
	section_attributes.text = tr("SECTION_ATTRIBUTES")
	section_summary.text = tr("SECTION_SUMMARY")

	%LblFirstName.text = tr("FIRST_NAME") + ":"
	%LblLastName.text = tr("LAST_NAME") + ":"
	%LblGender.text = tr("GENDER") + ":"
	%LblCountry.text = tr("COUNTRY") + ":"
	%LblClass.text = tr("SOCIAL_CLASS") + ":"
	%LblParents.text = tr("PARENTS") + ":"
	%LblSiblings.text = tr("SIBLINGS") + ":"

	input_first_name.placeholder_text = tr("TYPE_OR_RANDOM")
	input_last_name.placeholder_text = tr("TYPE_OR_RANDOM")

	btn_male.text = "♂ " + tr("MALE")
	btn_female.text = "♀ " + tr("FEMALE")
	btn_brazil.text = "🇧🇷 " + tr("BRAZIL")
	btn_usa.text = "🇺🇸 " + tr("USA")

	btn_class_low.text = tr("CLASS_LOW")
	btn_class_mid.text = tr("CLASS_MIDDLE")
	btn_class_high.text = tr("CLASS_HIGH")

	btn_both_parents.text = tr("PARENTS_BOTH")
	btn_single_father.text = tr("PARENTS_FATHER")
	btn_single_mother.text = tr("PARENTS_MOTHER")
	btn_orphan.text = tr("PARENTS_ORPHAN")

	$ScrollContainer/MainMargin/MainVBox/HealthRow/LblHealth.text = "❤️ " + tr("HEALTH") + ":"
	$ScrollContainer/MainMargin/MainVBox/IntelRow/LblIntel.text = "🧠 " + tr("INTELLIGENCE") + ":"
	$ScrollContainer/MainMargin/MainVBox/CharismaRow/LblCharisma.text = "😎 " + tr("CHARISMA") + ":"
	$ScrollContainer/MainMargin/MainVBox/AppearanceRow/LblAppearance.text = "✨ " + tr("APPEARANCE") + ":"
	$ScrollContainer/MainMargin/MainVBox/LuckRow/LblLuck.text = "🍀 " + tr("LUCK") + ":"
	$ScrollContainer/MainMargin/MainVBox/TemperRow/LblTemper.text = "😌 " + tr("TEMPERAMENT") + ":"

	btn_random_all.text = "🎲 " + tr("RANDOMIZE_ALL")
	btn_start.text = "🌱 " + tr("START_LIFE")


# ── SIGNALS ──

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back)

	# Name
	btn_random_first.pressed.connect(func(): _randomize_first_name())
	btn_random_last.pressed.connect(func(): _randomize_last_name())
	input_first_name.text_changed.connect(func(_t): _update_summary())
	input_last_name.text_changed.connect(func(_t): _update_summary())

	# Gender toggle
	btn_male.pressed.connect(func():
		_selected_gender = "male"
		btn_female.button_pressed = false
		btn_male.button_pressed = true
		_update_avatar()
		_randomize_first_name()
		_update_summary()
	)
	btn_female.pressed.connect(func():
		_selected_gender = "female"
		btn_male.button_pressed = false
		btn_female.button_pressed = true
		_update_avatar()
		_randomize_first_name()
		_update_summary()
	)

	# Country toggle
	btn_brazil.pressed.connect(func():
		_selected_country = "BR"
		btn_usa.button_pressed = false
		btn_brazil.button_pressed = true
		_randomize_name()
		_update_summary()
	)
	btn_usa.pressed.connect(func():
		_selected_country = "US"
		btn_brazil.button_pressed = false
		btn_usa.button_pressed = true
		_randomize_name()
		_update_summary()
	)

	# Social class toggle
	var class_btns := [btn_class_low, btn_class_mid, btn_class_high]
	for i in class_btns.size():
		var idx := i
		class_btns[i].pressed.connect(func():
			_selected_class = idx
			for j in class_btns.size():
				class_btns[j].button_pressed = (j == idx)
			_update_summary()
		)

	# Parents toggle
	var parent_btns := [btn_both_parents, btn_single_father, btn_single_mother, btn_orphan]
	for i in parent_btns.size():
		var idx := i
		parent_btns[i].pressed.connect(func():
			_selected_parents = idx
			for j in parent_btns.size():
				parent_btns[j].button_pressed = (j == idx)
			_update_summary()
		)

	# Siblings
	btn_sib_minus.pressed.connect(func():
		_sibling_count = maxi(_sibling_count - 1, 0)
		lbl_sib_count.text = str(_sibling_count)
		_update_summary()
	)
	btn_sib_plus.pressed.connect(func():
		_sibling_count = mini(_sibling_count + 1, 8)
		lbl_sib_count.text = str(_sibling_count)
		_update_summary()
	)

	# Attribute sliders
	var sliders := [slider_health, slider_intel, slider_charisma, slider_appearance, slider_luck, slider_temper]
	var labels := [val_health, val_intel, val_charisma, val_appearance, val_luck, val_temper]
	for i in sliders.size():
		var s: HSlider = sliders[i]
		var lbl: Label = labels[i]
		s.value_changed.connect(func(val: float):
			lbl.text = str(int(val))
			if not _updating_slider:
				_clamp_attributes(s)
			_update_attr_info()
			_update_summary()
		)

	btn_random_all.pressed.connect(_randomize_all)
	btn_start.pressed.connect(_on_start)


# ── NAME GENERATION ──

func _get_names_for_current() -> Dictionary:
	var lang := "pt_BR" if _selected_country == "BR" else "en"
	var country_key := _selected_country
	if _names_data.has(lang):
		var data: Dictionary = _names_data[lang]
		if data.has(country_key):
			return data[country_key]
		# Fallback: check root-level keys
		return data
	return {}


func _randomize_name() -> void:
	_randomize_first_name()
	_randomize_last_name()


func _randomize_first_name() -> void:
	var names := _get_names_for_current()
	var key := "male_first" if _selected_gender == "male" else "female_first"
	var name_list: Array = names.get(key, ["Alex"])
	input_first_name.text = name_list[_rng.randi_range(0, name_list.size() - 1)]
	_update_summary()


func _randomize_last_name() -> void:
	var names := _get_names_for_current()
	var last_list: Array = names.get("last", ["Silva"])
	input_last_name.text = last_list[_rng.randi_range(0, last_list.size() - 1)]
	_update_summary()


# ── ATTRIBUTES ──

func _get_total_attrs() -> int:
	return int(slider_health.value) + int(slider_intel.value) + int(slider_charisma.value) + \
		int(slider_appearance.value) + int(slider_luck.value) + int(slider_temper.value)


func _clamp_attributes(changed_slider: HSlider) -> void:
	var total := _get_total_attrs()
	if total <= MAX_ATTR_POINTS:
		return
	# Reduce the changed slider to fit within budget
	var over := total - MAX_ATTR_POINTS
	_updating_slider = true
	changed_slider.value = maxf(changed_slider.value - over, MIN_ATTR)
	_updating_slider = false


func _update_attr_info() -> void:
	var remaining := MAX_ATTR_POINTS - _get_total_attrs()
	attr_info.text = tr("POINTS_REMAINING") + ": " + str(remaining)
	if remaining < 0:
		attr_info.add_theme_color_override("font_color", ThemeSetup.COLOR_HEALTH)
	elif remaining < 50:
		attr_info.add_theme_color_override("font_color", ThemeSetup.ACCENT)
	else:
		attr_info.add_theme_color_override("font_color", ThemeSetup.COLOR_MONEY)


# ── AVATAR ──

func _update_avatar() -> void:
	if _selected_gender == "male":
		avatar_preview.text = "👶"
	else:
		avatar_preview.text = "👶"  # babies look the same


# ── RANDOMIZE ALL ──

func _randomize_all() -> void:
	# Gender
	_selected_gender = ["male", "female"][_rng.randi_range(0, 1)]
	btn_male.button_pressed = (_selected_gender == "male")
	btn_female.button_pressed = (_selected_gender == "female")

	# Country
	_selected_country = ["BR", "US"][_rng.randi_range(0, 1)]
	btn_brazil.button_pressed = (_selected_country == "BR")
	btn_usa.button_pressed = (_selected_country == "US")

	# Name
	_randomize_name()

	# Social class
	_selected_class = _rng.randi_range(0, 2)
	btn_class_low.button_pressed = (_selected_class == 0)
	btn_class_mid.button_pressed = (_selected_class == 1)
	btn_class_high.button_pressed = (_selected_class == 2)

	# Parents
	var parent_weights := [60, 15, 15, 10]  # both, father, mother, orphan
	var roll := _rng.randi_range(1, 100)
	if roll <= parent_weights[0]:
		_selected_parents = 0
	elif roll <= parent_weights[0] + parent_weights[1]:
		_selected_parents = 1
	elif roll <= parent_weights[0] + parent_weights[1] + parent_weights[2]:
		_selected_parents = 2
	else:
		_selected_parents = 3
	btn_both_parents.button_pressed = (_selected_parents == 0)
	btn_single_father.button_pressed = (_selected_parents == 1)
	btn_single_mother.button_pressed = (_selected_parents == 2)
	btn_orphan.button_pressed = (_selected_parents == 3)

	# Siblings
	_sibling_count = _rng.randi_range(0, 4)
	lbl_sib_count.text = str(_sibling_count)

	# Attributes — random distribution within budget
	_updating_slider = true
	var attrs := [slider_health, slider_intel, slider_charisma, slider_appearance, slider_luck, slider_temper]
	var values: Array[int] = []
	var budget := MAX_ATTR_POINTS
	for i in attrs.size():
		if i == attrs.size() - 1:
			values.append(clampi(budget, MIN_ATTR, MAX_ATTR))
		else:
			var max_for_this := mini(budget - (attrs.size() - 1 - i) * MIN_ATTR, MAX_ATTR)
			var v := _rng.randi_range(MIN_ATTR, max_for_this)
			values.append(v)
			budget -= v

	# Shuffle for variety
	for i in range(values.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp

	for i in attrs.size():
		attrs[i].value = values[i]

	_updating_slider = false
	_update_attr_info()
	_update_avatar()
	_update_summary()


# ── SUMMARY ──

func _update_summary() -> void:
	var first := input_first_name.text.strip_edges()
	var last := input_last_name.text.strip_edges()
	if first == "":
		first = "???"
	if last == "":
		last = "???"

	var gender_text := tr("MALE") if _selected_gender == "male" else tr("FEMALE")
	var country_text := tr("BRAZIL") if _selected_country == "BR" else tr("USA")
	var class_text: String
	match _selected_class:
		0: class_text = tr("CLASS_LOW")
		1: class_text = tr("CLASS_MIDDLE")
		_: class_text = tr("CLASS_HIGH")
	var parents_text: String
	match _selected_parents:
		0: parents_text = tr("PARENTS_BOTH")
		1: parents_text = tr("PARENTS_FATHER")
		2: parents_text = tr("PARENTS_MOTHER")
		_: parents_text = tr("PARENTS_ORPHAN")

	var text := "[b]" + first + " " + last + "[/b]\n"
	text += gender_text + " · " + country_text + "\n"
	text += tr("SOCIAL_CLASS") + ": " + class_text + "\n"
	text += tr("PARENTS") + ": " + parents_text + " · " + tr("SIBLINGS") + ": " + str(_sibling_count) + "\n"
	text += "❤️" + str(int(slider_health.value)) + " "
	text += "🧠" + str(int(slider_intel.value)) + " "
	text += "😎" + str(int(slider_charisma.value)) + " "
	text += "✨" + str(int(slider_appearance.value)) + " "
	text += "🍀" + str(int(slider_luck.value)) + " "
	text += "😌" + str(int(slider_temper.value))

	summary_label.text = text


# ── ACTIONS ──

func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/screens/MainMenu.tscn")


func _on_start() -> void:
	var first := input_first_name.text.strip_edges()
	var last := input_last_name.text.strip_edges()
	if first == "" or last == "":
		_randomize_name()
		first = input_first_name.text.strip_edges()
		last = input_last_name.text.strip_edges()

	var config := {
		"first_name": first,
		"last_name": last,
		"gender": _selected_gender,
		"country": _selected_country,
		"social_class": _selected_class,
		"parents": _selected_parents,
		"siblings": _sibling_count,
		"health": int(slider_health.value),
		"intelligence": int(slider_intel.value),
		"charisma": int(slider_charisma.value),
		"appearance": int(slider_appearance.value),
		"luck": int(slider_luck.value),
		"temperament": int(slider_temper.value),
	}

	GameManager.start_custom_life(config)
	SceneTransition.change_scene("res://scenes/screens/GameHUD.tscn")
