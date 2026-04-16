extends CanvasLayer

## SceneTransition — Fade-based scene transitions

var _overlay: ColorRect = null
const FADE_DURATION: float = 0.3


func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func change_scene(path: String) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	await tween.finished
	get_tree().change_scene_to_file(path)
	var tween2 := create_tween()
	tween2.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	await tween2.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
