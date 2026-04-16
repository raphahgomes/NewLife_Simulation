extends Node

## ThemeSetup — Creates and applies a polished dark theme globally

# ── Color Palette ──
const BG_DARK       := Color("#1A1D2E")
const BG_CARD       := Color("#252A3A")
const BG_CARD_LIGHT := Color("#2F3549")
const BG_INPUT      := Color("#1E2235")

const PRIMARY       := Color("#00BFA5")   # teal
const PRIMARY_DARK  := Color("#00897B")
const ACCENT        := Color("#FF9800")   # orange
const ACCENT_DARK   := Color("#E68900")

const TEXT_PRIMARY   := Color("#ECEFF1")
const TEXT_SECONDARY := Color("#90A4AE")
const TEXT_HINT      := Color("#607D8B")

# Stat bar colors
const COLOR_HEALTH    := Color("#E53935")
const COLOR_HAPPINESS := Color("#FFB300")
const COLOR_MONEY     := Color("#43A047")
const COLOR_SOCIAL    := Color("#1E88E5")
const COLOR_MORALITY  := Color("#AB47BC")


func _ready() -> void:
	var theme := _build_theme()
	get_tree().root.theme = theme


func _build_theme() -> Theme:
	var t := Theme.new()
	t.set_default_font_size(17)

	_setup_button(t)
	_setup_label(t)
	_setup_panel_container(t)
	_setup_progress_bar(t)
	_setup_rich_text_label(t)
	_setup_option_button(t)
	_setup_line_edit(t)
	_setup_hslider(t)
	_setup_popup_panel(t)
	return t


# ── Helpers ──

func make_flat_box(
	color: Color,
	corner: int = 12,
	margin_h: float = 12.0,
	margin_v: float = 12.0,
	border_w: int = 0,
	border_color: Color = Color.TRANSPARENT
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(corner)
	box.content_margin_left = margin_h
	box.content_margin_right = margin_h
	box.content_margin_top = margin_v
	box.content_margin_bottom = margin_v
	if border_w > 0:
		box.border_width_left = border_w
		box.border_width_right = border_w
		box.border_width_top = border_w
		box.border_width_bottom = border_w
		box.border_color = border_color
	return box


func make_bar_fill(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	box.content_margin_left = 0
	box.content_margin_right = 0
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box


func make_bar_bg() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BG_CARD_LIGHT
	box.set_corner_radius_all(8)
	box.content_margin_left = 0
	box.content_margin_right = 0
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box


# ── Control Styles ──

func _setup_button(t: Theme) -> void:
	var normal  := ThemeSetup.make_flat_box(PRIMARY_DARK, 14, 24, 14)
	var hover   := ThemeSetup.make_flat_box(PRIMARY, 14, 24, 14)
	var pressed := ThemeSetup.make_flat_box(PRIMARY.darkened(0.15), 14, 24, 14)
	var focus   := ThemeSetup.make_flat_box(PRIMARY_DARK, 14, 24, 14, 2, PRIMARY)
	var disabled := ThemeSetup.make_flat_box(BG_CARD_LIGHT, 14, 24, 14)

	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", disabled)

	t.set_color("font_color", "Button", TEXT_PRIMARY)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT_PRIMARY.darkened(0.1))
	t.set_color("font_disabled_color", "Button", TEXT_HINT)
	t.set_font_size("font_size", "Button", 17)


func _setup_label(t: Theme) -> void:
	t.set_color("font_color", "Label", TEXT_PRIMARY)
	t.set_font_size("font_size", "Label", 16)


func _setup_panel_container(t: Theme) -> void:
	t.set_stylebox("panel", "PanelContainer", ThemeSetup.make_flat_box(BG_CARD, 16, 20, 16))


func _setup_progress_bar(t: Theme) -> void:
	t.set_stylebox("background", "ProgressBar", ThemeSetup.make_bar_bg())
	t.set_stylebox("fill", "ProgressBar", ThemeSetup.make_bar_fill(PRIMARY))
	t.set_color("font_color", "ProgressBar", TEXT_PRIMARY)
	t.set_font_size("font_size", "ProgressBar", 13)


func _setup_rich_text_label(t: Theme) -> void:
	t.set_color("default_color", "RichTextLabel", TEXT_PRIMARY)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)


func _setup_option_button(t: Theme) -> void:
	t.set_stylebox("normal", "OptionButton", ThemeSetup.make_flat_box(BG_INPUT, 12, 16, 10, 1, TEXT_HINT))
	t.set_stylebox("hover", "OptionButton", ThemeSetup.make_flat_box(BG_INPUT, 12, 16, 10, 1, PRIMARY))
	t.set_stylebox("pressed", "OptionButton", ThemeSetup.make_flat_box(BG_INPUT, 12, 16, 10, 1, PRIMARY))
	t.set_stylebox("focus", "OptionButton", ThemeSetup.make_flat_box(BG_INPUT, 12, 16, 10, 2, PRIMARY))
	t.set_color("font_color", "OptionButton", TEXT_PRIMARY)


func _setup_line_edit(t: Theme) -> void:
	t.set_stylebox("normal", "LineEdit", ThemeSetup.make_flat_box(BG_INPUT, 10, 14, 10, 1, TEXT_HINT))
	t.set_stylebox("focus", "LineEdit", ThemeSetup.make_flat_box(BG_INPUT, 10, 14, 10, 2, PRIMARY))
	t.set_color("font_color", "LineEdit", TEXT_PRIMARY)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_HINT)


func _setup_hslider(t: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = BG_CARD_LIGHT
	track.set_corner_radius_all(4)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)

	var grabber_area := StyleBoxFlat.new()
	grabber_area.bg_color = PRIMARY_DARK
	grabber_area.set_corner_radius_all(4)
	grabber_area.content_margin_top = 6
	grabber_area.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", grabber_area)

	t.set_icon("grabber", "HSlider", _make_circle_texture(PRIMARY, 20))
	t.set_icon("grabber_highlight", "HSlider", _make_circle_texture(PRIMARY.lightened(0.2), 22))


func _setup_popup_panel(t: Theme) -> void:
	t.set_stylebox("panel", "PopupPanel", ThemeSetup.make_flat_box(BG_CARD, 16, 16, 16))


func _make_circle_texture(color: Color, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)
