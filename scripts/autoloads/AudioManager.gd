extends Node

## AudioManager — Handles background music, SFX, and volume control

signal music_changed(phase_name: String)

# Audio players
var _music_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null
var _ui_sfx_player: AudioStreamPlayer = null

# Volume settings (linear 0.0–1.0)
var music_volume: float = 0.7:
	set(val):
		music_volume = clampf(val, 0.0, 1.0)
		if _music_player:
			_music_player.volume_db = linear_to_db(music_volume)
		SaveManager.save_setting("music_volume", music_volume)

var sfx_volume: float = 0.8:
	set(val):
		sfx_volume = clampf(val, 0.0, 1.0)
		if _sfx_player:
			_sfx_player.volume_db = linear_to_db(sfx_volume)
		if _ui_sfx_player:
			_ui_sfx_player.volume_db = linear_to_db(sfx_volume)
		SaveManager.save_setting("sfx_volume", sfx_volume)

var music_enabled: bool = true:
	set(val):
		music_enabled = val
		if _music_player:
			if not val:
				_music_player.stop()
			elif _current_music_path != "":
				_play_music(_current_music_path)
		SaveManager.save_setting("music_enabled", music_enabled)

var sfx_enabled: bool = true:
	set(val):
		sfx_enabled = val
		SaveManager.save_setting("sfx_enabled", sfx_enabled)

# Music per life phase
var _phase_music: Dictionary = {
	"baby": "res://assets/sounds/music_baby.ogg",
	"child": "res://assets/sounds/music_child.ogg",
	"teen": "res://assets/sounds/music_teen.ogg",
	"adult": "res://assets/sounds/music_adult.ogg",
	"elder": "res://assets/sounds/music_elder.ogg",
	"menu": "res://assets/sounds/music_menu.ogg",
}

# SFX paths
var _sfx_cache: Dictionary = {}
var _current_music_path: String = ""
var _current_phase: String = ""

# Fade settings
var _fade_tween: Tween = null
const FADE_DURATION: float = 1.0


func _ready() -> void:
	_setup_audio_players()
	_load_volume_settings()
	_connect_signals()


func _setup_audio_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = linear_to_db(music_volume)
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	_sfx_player.volume_db = linear_to_db(sfx_volume)
	add_child(_sfx_player)

	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.bus = "Master"
	_ui_sfx_player.volume_db = linear_to_db(sfx_volume)
	add_child(_ui_sfx_player)


func _load_volume_settings() -> void:
	var saved_music_vol = SaveManager.load_setting("music_volume", 0.7)
	var saved_sfx_vol = SaveManager.load_setting("sfx_volume", 0.8)
	var saved_music_on = SaveManager.load_setting("music_enabled", true)
	var saved_sfx_on = SaveManager.load_setting("sfx_enabled", true)
	music_volume = saved_music_vol
	sfx_volume = saved_sfx_vol
	music_enabled = saved_music_on
	sfx_enabled = saved_sfx_on


func _connect_signals() -> void:
	if GameManager:
		GameManager.phase_changed.connect(_on_phase_changed)
		GameManager.game_started.connect(_on_game_started)
		GameManager.character_died.connect(_on_character_died)


# === Music Control ===

func play_phase_music(phase: Character.LifePhase) -> void:
	var phase_name := _phase_to_string(phase)
	if phase_name == _current_phase:
		return
	_current_phase = phase_name
	var path: String = _phase_music.get(phase_name, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	_crossfade_to(path)


func play_menu_music() -> void:
	if _current_phase == "menu":
		return
	_current_phase = "menu"
	var path: String = _phase_music.get("menu", "")
	if path == "" or not ResourceLoader.exists(path):
		return
	_crossfade_to(path)


func stop_music() -> void:
	if _music_player and _music_player.playing:
		_fade_out()
	_current_phase = ""
	_current_music_path = ""


func _crossfade_to(path: String) -> void:
	if not music_enabled:
		_current_music_path = path
		return

	if _music_player.playing:
		# Fade out, then play new
		_fade_out()
		await get_tree().create_timer(FADE_DURATION).timeout
	_play_music(path)


func _play_music(path: String) -> void:
	if not music_enabled or not ResourceLoader.exists(path):
		return
	_current_music_path = path
	var stream = load(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()
	music_changed.emit(_current_phase)


func _fade_out() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music_player, "volume_db", -40.0, FADE_DURATION)
	_fade_tween.tween_callback(_music_player.stop)


func _on_music_finished() -> void:
	# Loop the music
	if music_enabled and _current_music_path != "":
		_music_player.play()


# === SFX Control ===

func play_sfx(sfx_name: String) -> void:
	if not sfx_enabled:
		return
	var path := "res://assets/sounds/sfx_%s.ogg" % sfx_name
	if not ResourceLoader.exists(path):
		return
	var stream = _get_cached_sfx(path)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


func play_ui_sfx(sfx_name: String) -> void:
	if not sfx_enabled:
		return
	var path := "res://assets/sounds/sfx_%s.ogg" % sfx_name
	if not ResourceLoader.exists(path):
		return
	var stream = _get_cached_sfx(path)
	if stream == null:
		return
	_ui_sfx_player.stream = stream
	_ui_sfx_player.play()


func _get_cached_sfx(path: String) -> AudioStream:
	if _sfx_cache.has(path):
		return _sfx_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream:
		_sfx_cache[path] = stream
	return stream


# === Signal Handlers ===

func _on_phase_changed(new_phase: Character.LifePhase) -> void:
	play_phase_music(new_phase)


func _on_game_started() -> void:
	play_phase_music(Character.LifePhase.BABY)


func _on_character_died(_char: Character) -> void:
	stop_music()


# === Helpers ===

func _phase_to_string(phase: Character.LifePhase) -> String:
	match phase:
		Character.LifePhase.BABY: return "baby"
		Character.LifePhase.CHILD: return "child"
		Character.LifePhase.TEEN: return "teen"
		Character.LifePhase.ADULT: return "adult"
		Character.LifePhase.ELDER: return "elder"
		_: return "adult"
