extends Node
## Sound effects and music. TEMPORARY AUDIO: every sound is synthesised by
## tools/audio/gen_audio.py (see docs/AUDIO.md); swap the .ogg files to replace them.
##
##   Audio.sfx(&"parry")                    — non-positional (UI, the player's own body)
##   Audio.sfx_at(&"enemy_death", position) — positional, panned/attenuated from the camera
##   Audio.music(&"boss")                   — crossfades to a looping track; &"" = silence
##
## Buses: Master > Music, SFX (created at startup if the project has no bus layout).
## Volumes come from Settings (master / music / sfx).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL := 14
const POOL_2D := 10
## Sounds that get a small random pitch change so repeats do not sound mechanical.
const VARY := [&"swing_light", &"swing_heavy", &"swing_fist", &"hit_flesh", &"hit_armor", &"step_1", &"step_2",
	&"jump", &"land", &"dodge", &"enemy_windup", &"hurt", &"boss_stomp"]

var current_music: StringName = &""
var current_pitch := 1.0
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _players_2d: Array[AudioStreamPlayer2D] = []
var _next := 0
var _next_2d := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_tween: Tween
var _last_played := {}   # name -> msec, to stop the same sound stacking in one frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	for i in POOL_2D:
		var p := AudioStreamPlayer2D.new()
		p.bus = &"SFX"
		p.max_distance = 720.0
		p.attenuation = 1.2
		add_child(p)
		_players_2d.append(p)
	_music_a = _music_player()
	_music_b = _music_player()
	apply_volumes()
	_connect_events()


## World / UI events that have a sound. Combat sounds are played by the actors.
func _connect_events() -> void:
	Events.embers_gained.connect(func(_n): sfx(&"ember", -4.0))
	Events.item_picked.connect(func(_id, _n): sfx(&"pickup", -2.0))
	Events.stats_changed.connect(func(): sfx(&"levelup"))
	Events.game_saved.connect(func(_s): sfx(&"save", -10.0))
	Events.checkpoint_rested.connect(func(_id, _p): sfx(&"rest"))
	Events.boss_fight_started.connect(_on_boss_fight_started)
	Events.boss_fight_ended.connect(_on_boss_fight_ended)
	Events.player_died.connect(func(): music(&"", 1.5))
	Events.player_respawned.connect(func(_p): music(level_music(), 2.0, level_music_pitch()))


func _on_boss_fight_started(b: Node) -> void:
	sfx(&"gate_seal")
	var track: StringName = b.get("music_track") if b.get("music_track") != null else &"boss"
	var pitch: float = b.get("music_pitch") if b.get("music_pitch") != null else 1.0
	music(track, 0.8, pitch)


func level_music_pitch() -> float:
	var lv := get_tree().get_first_node_in_group(&"level")
	return lv.get("music_pitch") if lv and lv.get("music_pitch") != null else 1.0


func level_music() -> StringName:
	var lv := get_tree().get_first_node_in_group(&"level")
	return lv.get("music") if lv and lv.get("music") != null else &""


func _on_boss_fight_ended(victory: bool) -> void:
	if victory:
		music(&"", 0.6)
		sting(&"victory")
		await get_tree().create_timer(6.0).timeout
		if current_music == &"" and GameState.in_game:
			music(level_music(), 3.0, level_music_pitch())


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, &"Master")


func _music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func apply_volumes() -> void:
	_set_bus(&"Master", Settings.master_volume)
	_set_bus(&"Music", Settings.music_volume)
	_set_bus(&"SFX", Settings.sfx_volume)


func _set_bus(bus_name: StringName, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(idx, v <= 0.001)


func _stream(dir: String, sname: StringName, loop := false) -> AudioStream:
	var key := dir + String(sname)
	if _streams.has(key):
		return _streams[key]
	var path := dir + String(sname) + ".ogg"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	else:
		push_warning("Audio: missing sound %s" % path)
	if s is AudioStreamOggVorbis and loop:
		(s as AudioStreamOggVorbis).loop = true
	if s is AudioStreamWAV and loop:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	_streams[key] = s
	return s


func _recent(sname: StringName) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sname, -1000)) < 35:
		return true
	_last_played[sname] = now
	return false


## Plays a sound effect without position. volume_db is relative.
func sfx(sname: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	if sname == &"" or _recent(sname):
		return
	var s := _stream(SFX_DIR, sname)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * (randf_range(0.93, 1.07) if VARY.has(sname) else 1.0)
	p.play()


## Plays a sound effect in the world; it pans and fades with distance from the camera.
func sfx_at(sname: StringName, where: Vector2, volume_db := 0.0, pitch := 1.0) -> void:
	if sname == &"" or _recent(sname):
		return
	var s := _stream(SFX_DIR, sname)
	if s == null:
		return
	var p := _players_2d[_next_2d]
	_next_2d = (_next_2d + 1) % _players_2d.size()
	p.stream = s
	p.global_position = where
	p.volume_db = volume_db
	p.pitch_scale = pitch * (randf_range(0.93, 1.07) if VARY.has(sname) else 1.0)
	p.play()


## Crossfades to a looping music track. &"" fades to silence.
## pitch < 1 slows and darkens a track (one boss theme can serve two fights).
func music(track: StringName, fade_time := 1.2, pitch := 1.0) -> void:
	if track == current_music and is_equal_approx(pitch, current_pitch):
		return
	current_music = track
	current_pitch = pitch
	if _music_tween:
		_music_tween.kill()
	var old := _music_a
	var new := _music_b
	_music_a = new
	_music_b = old
	_music_tween = create_tween().set_parallel(true)
	if old.playing:
		_music_tween.tween_property(old, "volume_db", -80.0, fade_time)
	if track != &"":
		var s := _stream(MUSIC_DIR, track, true)
		if s:
			new.stream = s
			new.pitch_scale = pitch
			new.volume_db = -40.0
			new.play()
			_music_tween.tween_property(new, "volume_db", 0.0, fade_time)
	_music_tween.chain().tween_callback(func(): if not (old == _music_a): old.stop())


## A one-shot musical sting (victory, death) on the music bus.
func sting(sname: StringName) -> void:
	var s := _stream(SFX_DIR, sname)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = &"Music"
	p.stream = s
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
