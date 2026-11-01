class_name Puzzle
extends RefCounted
## Shared state of the Lower Hell's puzzles. A puzzle switch is "on" when its flag is set (permanent: a solved
## puzzle stays solved across saves) or, for timed levers, until its timer runs out. Gates open when every
## switch they need is on; an opened gate is remembered as a flag (gate_open_<id>).

static var _timed := {}      ## switch id -> time (msec) until which it stays on
static var _progress := {}   ## rune sequence id -> how many stones are lit


static func flag(id: StringName) -> StringName:
	return StringName("puzzle_" + String(id))


static func is_on(id: StringName) -> bool:
	if bool(GameState.get_flag(flag(id), false)):
		return true
	return int(_timed.get(id, 0)) > Time.get_ticks_msec()


static func set_on(id: StringName, seconds := 0.0) -> void:
	if seconds > 0.0:
		_timed[id] = Time.get_ticks_msec() + int(seconds * 1000.0)
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
