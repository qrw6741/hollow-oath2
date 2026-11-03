class_name Puzzle
extends RefCounted
## Shared state of the Lower Hell's puzzles. A puzzle switch is "on" when its flag is set (permanent: a solved
## puzzle stays solved across saves) or, for timed levers, until its timer runs out. Gates open when every
## switch they need is on; an opened gate is remembered as a flag (gate_open_<id>).

static var _timed := {}      ## switch id -> time (msec) until which it stays on
static var _progress := {}   ## rune sequence id -> how many stones are lit


## Game time in msec: counted in physics ticks, NOT wall-clock, so a slow frame rate slows the timers exactly as
## much as it slows the player (a timed lever must never run out while the game crawls).
static func now_ms() -> int:
	return int(Engine.get_physics_frames() * 1000.0 / float(Engine.physics_ticks_per_second))


static func flag(id: StringName) -> StringName:
	return StringName("puzzle_" + String(id))


static func is_on(id: StringName) -> bool:
	if bool(GameState.get_flag(flag(id), false)):
		return true
	return int(_timed.get(id, 0)) > now_ms()


static func set_on(id: StringName, seconds := 0.0) -> void:
	if seconds > 0.0:
		_timed[id] = now_ms() + int(seconds * 1000.0)
	else:
		GameState.set_flag(flag(id), true)


static func set_off(id: StringName) -> void:
	_timed.erase(id)
	if bool(GameState.get_flag(flag(id), false)):
		GameState.set_flag(flag(id), false)


static func progress(seq: StringName) -> int:
	return int(_progress.get(seq, 0))


static func set_progress(seq: StringName, n: int) -> void:
	_progress[seq] = n


static func reset_session() -> void:
	_timed.clear()
	_progress.clear()
