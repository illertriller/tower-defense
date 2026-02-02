extends Node

## AudioManager — Autoload singleton for all game audio
## Features:
## - SFX playback pool with overlapping sounds
## - Music crossfading between two players
## - Per-sound cooldowns to prevent spam
## - Variant randomization (e.g. button_click, button_click_2, button_click_3)
## - Volume controls (master, sfx, music) with persistence
## - Audio bus routing (Master → SFX / Music)

# ── Constants ──
const SFX_POOL_SIZE: int = 16
const SFX_COOLDOWN_MS: int = 80
const AUDIO_SETTINGS_PATH: String = "user://audio_settings.json"

# ── Volume Settings (linear 0.0–1.0) ──
var master_volume: float = 1.0
var sfx_volume: float = 0.7
var music_volume: float = 0.5

# ── Internal State ──
var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _sfx_pool: Array = []
var _sfx_index: int = 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music: String = ""
var _sfx_cooldowns: Dictionary = {}

# ── SFX File Paths ──
var _sfx_paths: Dictionary = {
	"arrow_fire": [
		"res://assets/audio/combat/arrow_fire.wav",
		"res://assets/audio/combat/arrow_fire_2.wav",
	],
	"fire_attack": ["res://assets/audio/combat/fire_attack.wav"],
	"frost_attack": ["res://assets/audio/combat/frost_attack.wav"],
	"holy_attack": ["res://assets/audio/combat/holy_attack.wav"],
	"poison_attack": ["res://assets/audio/combat/poison_attack.wav"],
	"wind_attack": ["res://assets/audio/combat/wind_attack.wav"],
	"spell": [
		"res://assets/audio/combat/spell_00.wav",
		"res://assets/audio/combat/spell_01.wav",
		"res://assets/audio/combat/spell_02.wav",
		"res://assets/audio/combat/spell_03.wav",
	],
	"explosion_impact": ["res://assets/audio/combat/explosion_impact.wav"],
	"hit_metal": ["res://assets/audio/combat/hit_metal.wav"],
	"enemy_death": [
		"res://assets/audio/combat/enemy_death.wav",
		"res://assets/audio/combat/enemy_death_2.wav",
	],
	"enemy_death_ogre": ["res://assets/audio/combat/enemy_death_ogre.wav"],
	"enemy_death_shade": ["res://assets/audio/combat/enemy_death_shade.wav"],
	"enemy_hit": [
		"res://assets/audio/combat/enemy_hit.wav",
		"res://assets/audio/combat/enemy_hit_2.wav",
		"res://assets/audio/combat/enemy_hit_3.wav",
	],
	"enemy_hit_soft": ["res://assets/audio/combat/enemy_hit_soft.wav"],
	"gold_pickup": [
		"res://assets/audio/combat/gold_pickup.wav",
		"res://assets/audio/combat/gold_pickup_2.wav",
		"res://assets/audio/combat/gold_pickup_3.wav",
	],
	"button_click": [
		"res://assets/audio/ui/button_click.wav",
		"res://assets/audio/ui/button_click_2.wav",
		"res://assets/audio/ui/button_click_3.wav",
	],
	"button_hover": [
		"res://assets/audio/ui/button_hover.wav",
		"res://assets/audio/ui/button_hover_2.wav",
	],
	"defeat": ["res://assets/audio/ui/defeat.wav"],
	"error": ["res://assets/audio/ui/error.wav"],
	"menu_close": ["res://assets/audio/ui/menu_close.wav"],
	"menu_open": ["res://assets/audio/ui/menu_open.wav"],
	"select": ["res://assets/audio/ui/select.wav"],
	"tower_place": ["res://assets/audio/ui/tower_place.wav"],
	"tower_sell": ["res://assets/audio/ui/tower_sell.wav"],
	"tower_upgrade": [
		"res://assets/audio/ui/tower_upgrade.wav",
		"res://assets/audio/ui/tower_upgrade_alt.wav",
	],
	"victory_fanfare": ["res://assets/audio/ui/victory_fanfare.wav"],
	"wave_start": ["res://assets/audio/ui/wave_start.wav"],
}

# ── Music File Paths ──
var _music_paths: Dictionary = {
	"battle_loop": "res://assets/audio/music/battle_loop.ogg",
	"battle_loop_alt": "res://assets/audio/music/battle_loop_alt.ogg",
	"menu_theme": "res://assets/audio/music/menu_theme.ogg",
	"victory_theme": "res://assets/audio/music/victory_theme.ogg",
}

# ── Tower Type → Attack Sound ──
var _tower_attack_sounds: Dictionary = {
	"arrow_tower": "arrow_fire",
	"cannon_tower": "spell",
	"magic_tower": "spell",
	"tesla_tower": "spell",
	"frost_tower": "frost_attack",
	"flame_tower": "fire_attack",
	"antiair_tower": "wind_attack",
	"sniper_tower": "arrow_fire",
	"poison_tower": "poison_attack",
	"bomb_tower": "spell",
	"holy_tower": "holy_attack",
	"storm_tower": "spell",
}

# ══════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════

func _ready():
	# Keep audio playing even when the tree is paused (ESC menu, etc.)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_players()
	_preload_sfx()
	_preload_music()
	_load_settings()
	_apply_volumes()

func _setup_audio_buses():
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Music"), "Master")

func _create_players():
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	add_child(_music_a)
	
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Music"
	add_child(_music_b)
	
	_active_music = _music_a
	
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

func _preload_sfx():
	for sound_name in _sfx_paths:
		var streams: Array = []
		for path in _sfx_paths[sound_name]:
			if ResourceLoader.exists(path):
				streams.append(load(path))
			else:
				push_warning("AudioManager: SFX not found — " + path)
		if not streams.is_empty():
			_sfx[sound_name] = streams

func _preload_music():
	for track_name in _music_paths:
		var path = _music_paths[track_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStreamOGGVorbis:
				stream.loop = true
			_music[track_name] = stream
		else:
			push_warning("AudioManager: Music not found — " + path)

# ══════════════════════════════════════════════════════════
# SFX PLAYBACK
# ══════════════════════════════════════════════════════════

func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	if not _sfx.has(sound_name):
		return
	
	# Per-sound cooldown to prevent deafening overlap
	var now: int = Time.get_ticks_msec()
	if _sfx_cooldowns.has(sound_name):
		if now - _sfx_cooldowns[sound_name] < SFX_COOLDOWN_MS:
			return
	_sfx_cooldowns[sound_name] = now
	
	# Pick a random variant
	var variants: Array = _sfx[sound_name]
	var stream: AudioStream = variants[randi() % variants.size()]
	
	# Round-robin through the pool
	var player: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	player.volume_db = volume_db
	player.play()

# ══════════════════════════════════════════════════════════
# MUSIC PLAYBACK
# ══════════════════════════════════════════════════════════

func play_music(track_name: String, fade_duration: float = 1.0) -> void:
	if track_name == _current_music:
		return
	
	if not _music.has(track_name):
		push_warning("AudioManager: Unknown music — " + track_name)
		return
	
	_current_music = track_name
	
	# Swap players for crossfade
	var new_player: AudioStreamPlayer
	var old_player: AudioStreamPlayer
	if _active_music == _music_a:
		new_player = _music_b
		old_player = _music_a
	else:
		new_player = _music_a
		old_player = _music_b
	
	# Start new track silently
	new_player.stream = _music[track_name]
	new_player.volume_db = -80.0
	new_player.play()
	
	# Crossfade
	var tween = create_tween()
	if old_player.playing:
		tween.set_parallel(true)
		tween.tween_property(new_player, "volume_db", 0.0, fade_duration)
		tween.tween_property(old_player, "volume_db", -80.0, fade_duration)
		tween.set_parallel(false)
		tween.tween_callback(old_player.stop)
	else:
		tween.tween_property(new_player, "volume_db", 0.0, fade_duration)
	
	_active_music = new_player

func stop_music(fade_duration: float = 0.5) -> void:
	_current_music = ""
	for player in [_music_a, _music_b]:
		if player.playing:
			var tween = create_tween()
			tween.tween_property(player, "volume_db", -80.0, fade_duration)
			tween.tween_callback(player.stop)

# ══════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════

func get_tower_attack_sound(tower_type: String) -> String:
	return _tower_attack_sounds.get(tower_type, "")

func get_enemy_death_sound(enemy_type: String) -> String:
	match enemy_type:
		"brute_demon", "bone_golem", "tank":
			return "enemy_death_ogre"
		"wraith", "shadow_stalker":
			return "enemy_death_shade"
		_:
			return "enemy_death"

# ══════════════════════════════════════════════════════════
# VOLUME CONTROLS
# ══════════════════════════════════════════════════════════

func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()
	save_settings()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()
	save_settings()

func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()
	save_settings()

func _apply_volumes():
	AudioServer.set_bus_volume_db(0, _vol_to_db(master_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, _vol_to_db(sfx_volume))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, _vol_to_db(music_volume))

func _vol_to_db(vol: float) -> float:
	if vol <= 0.001:
		return -80.0
	return linear_to_db(vol)

# ══════════════════════════════════════════════════════════
# SETTINGS PERSISTENCE
# ══════════════════════════════════════════════════════════

func save_settings():
	var data = {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
	}
	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func _load_settings():
	if not FileAccess.file_exists(AUDIO_SETTINGS_PATH):
		return
	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	master_volume = clampf(data.get("master_volume", 1.0), 0.0, 1.0)
	sfx_volume = clampf(data.get("sfx_volume", 0.7), 0.0, 1.0)
	music_volume = clampf(data.get("music_volume", 0.5), 0.0, 1.0)
