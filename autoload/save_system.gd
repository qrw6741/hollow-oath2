extends Node
## Versioned, crash-safe save slots.
##
## File format (slot_N.json):  { "checksum": <sha256 of data>, "data": { "version": 1, ... } }
##
## Write procedure (never leaves a half-written save as the only copy):
##   1. write slot_N.json.tmp and read it back to verify it decodes;
##   2. copy the current good slot_N.json to slot_N.json.bak;
##   3. swap the tmp file into place.
##
## Read procedure: main file -> if damaged or missing, the .bak -> otherwise the
## slot reports CORRUPT. Saves from a *newer* game version are reported TOO_NEW and
## never touched. Older versions are upgraded through _migrate() one step at a time.
## Missing or wrongly-typed fields are replaced by defaults, never crash the game.

const CURRENT_VERSION := 1
const SLOT_COUNT := 3

enum Status { OK, EMPTY, CORRUPT, TOO_NEW }

## Overridable so tests never touch real player saves.
var save_dir := "user://saves"


func _ready() -> void:
	Events.checkpoint_rested.connect(_on_progress_event)
	Events.player_respawned.connect(_on_progress_event)


func _on_progress_event(_a = null, _b = null) -> void:
	autosave()


## Saves the active session to its slot (no-op for slot-less sessions).
func autosave() -> bool:
	if GameState.in_game and GameState.current_slot > 0:
		return save_slot(GameState.current_slot)
	return false


# ------------------------------------------------------------------ paths

func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d.json" % slot)


func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


# ------------------------------------------------------------------ writing

func save_slot(slot: int) -> bool:
	if not _valid_slot(slot):
		return _fail(slot, "invalid slot")
	if DirAccess.make_dir_recursive_absolute(save_dir) != OK:
		return _fail(slot, "cannot create save folder")
	var data := GameState.to_dict()
	data["version"] = CURRENT_VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var text := _encode(data)

	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return _fail(slot, "cannot write file (%s)" % error_string(FileAccess.get_open_error()))
	f.store_string(text)
	f.close()

	# Verify what actually reached the disk before it replaces anything.
	if _decode(FileAccess.get_file_as_string(tmp)).status != Status.OK:
		DirAccess.remove_absolute(tmp)
		return _fail(slot, "verification failed")

	if FileAccess.file_exists(path):
		if _decode(FileAccess.get_file_as_string(path)).status == Status.OK:
			DirAccess.copy_absolute(path, path + ".bak")
		else:
			DirAccess.rename_absolute(path, path + ".corrupt")
	if DirAccess.rename_absolute(tmp, path) != OK:
		# Some platforms refuse to rename over an existing file; the .bak covers this window.
		DirAccess.remove_absolute(path)
		if DirAccess.rename_absolute(tmp, path) != OK:
			return _fail(slot, "cannot replace save file")
	Events.game_saved.emit(slot)
	return true


func _fail(slot: int, reason: String) -> bool:
	push_warning("Save slot %d failed: %s" % [slot, reason])
	Events.save_failed.emit(slot, reason)
	return false


func delete_slot(slot: int) -> void:
	if not _valid_slot(slot):
		return
	var path := slot_path(slot)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


# ------------------------------------------------------------------ reading

## Returns { status: Status, data: Dictionary, error: String, recovered: bool }.
func load_slot(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return _result(Status.EMPTY)
	var path := slot_path(slot)
	var main_exists := FileAccess.file_exists(path)
	var main := _result(Status.EMPTY)
	if main_exists:
		main = _decode(FileAccess.get_file_as_string(path))
		if main.status == Status.OK or main.status == Status.TOO_NEW:
			return main

	var bak_path := path + ".bak"
	if FileAccess.file_exists(bak_path):
		var bak := _decode(FileAccess.get_file_as_string(bak_path))
		if bak.status == Status.OK:
			if main_exists:
				DirAccess.rename_absolute(path, path + ".corrupt")
			DirAccess.copy_absolute(bak_path, path)
			bak["recovered"] = true
			return bak
	return main if main_exists else _result(Status.EMPTY)


## Slot with the newest save, or 0 when there is none.
func most_recent_slot() -> int:
	var best := 0
	var best_time := -1
	for s in range(1, SLOT_COUNT + 1):
		var r := load_slot(s)
		if r.status == Status.OK and int(r.data.saved_at) > best_time:
			best = s
			best_time = int(r.data.saved_at)
	return best


# ------------------------------------------------------------------ encoding

func _result(status: Status, data := {}, error := "") -> Dictionary:
	return {"status": status, "data": data, "error": error, "recovered": false}


func _encode(data: Dictionary) -> String:
	return JSON.stringify({"checksum": _checksum(data), "data": data}, "\t")


## Checksum of the data *as it will look after a JSON round trip*, so int/float
## differences introduced by parsing never cause false corruption reports.
func _checksum(data: Dictionary) -> String:
	var normalized: Variant = JSON.parse_string(JSON.stringify(data, "", true))
	return JSON.stringify(normalized, "", true).sha256_text()


func _decode(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return _result(Status.CORRUPT, {}, "empty file")
	var json := JSON.new()
	if json.parse(text) != OK:
		return _result(Status.CORRUPT, {}, "unreadable: " + json.get_error_message())
	var root: Variant = json.data
	if typeof(root) != TYPE_DICTIONARY or typeof(root.get("data")) != TYPE_DICTIONARY or typeof(root.get("checksum")) != TYPE_STRING:
		return _result(Status.CORRUPT, {}, "unexpected structure")
	var data: Dictionary = root["data"]
	if _checksum(data) != root["checksum"]:
		return _result(Status.CORRUPT, {}, "checksum mismatch")

	var version := int(data.get("version", 0)) if typeof(data.get("version")) in [TYPE_INT, TYPE_FLOAT] else 0
	if version > CURRENT_VERSION:
		return _result(Status.TOO_NEW, {}, "save version %d is newer than this game (%d)" % [version, CURRENT_VERSION])
	if version < 1:
		return _result(Status.CORRUPT, {}, "missing version")
	while version < CURRENT_VERSION:
		data = _migrate(data, version)
		version += 1
		data["version"] = version
	return _result(Status.OK, _normalize(data))


## Upgrade hook: transforms save data from [param from_version] to from_version + 1.
## Add a `match` arm here whenever CURRENT_VERSION is raised.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		_:
			return data


## Guarantees every field exists with the right type and sane range.
func _normalize(d: Dictionary) -> Dictionary:
	var out := {}
	out["version"] = CURRENT_VERSION
	out["saved_at"] = int(_num(d.get("saved_at"), 0.0))
	out["play_time"] = maxf(0.0, _num(d.get("play_time"), 0.0))
	out["deaths"] = maxi(0, int(_num(d.get("deaths"), 0.0)))
	var pid := _str(d.get("preset_id"), "sworn_knight")
	out["preset_id"] = pid if Presets.is_valid_id(pid) else "sworn_knight"
	out["embers"] = maxi(0, int(_num(d.get("embers"), 0.0)))
	var drop := {}
	var rd: Variant = d.get("ember_drop")
	if typeof(rd) == TYPE_DICTIONARY and rd.has("amount") and rd.has("x") and rd.has("y") \
		and typeof(rd["amount"]) in [TYPE_INT, TYPE_FLOAT] and int(rd["amount"]) > 0 \
		and typeof(rd["x"]) in [TYPE_INT, TYPE_FLOAT] and typeof(rd["y"]) in [TYPE_INT, TYPE_FLOAT]:
		drop = {"level_id": _str(rd.get("level_id"), ""), "x": float(rd["x"]), "y": float(rd["y"]), "amount": int(rd["amount"])}
	out["ember_drop"] = drop
	var st := {"vigor": 0, "endurance": 0, "strength": 0}
	if typeof(d.get("stats")) == TYPE_DICTIONARY:
		for k in st:
			st[k] = clampi(int(_num(d["stats"].get(k), 0.0)), 0, 99)
	out["stats"] = st
	var inv := {}
	if typeof(d.get("inventory")) == TYPE_DICTIONARY:
		for k in d["inventory"]:
			var item := Items.get_item(StringName(str(k)))
			if item != null and typeof(d["inventory"][k]) in [TYPE_INT, TYPE_FLOAT]:
				var n := clampi(int(d["inventory"][k]), 0, item.max_stack)
				if n > 0:
					inv[String(k)] = n
	out["inventory"] = inv
	var q := _str(d.get("quick_item"), "")
	out["quick_item"] = q if inv.has(q) else ""
	out["level_path"] = _str(d.get("level_path"), GameState.DEFAULT_LEVEL_PATH)
	out["level_name"] = _str(d.get("level_name"), "")
	out["checkpoint_id"] = _str(d.get("checkpoint_id"), "")
	var pos: Variant = d.get("respawn_position")
	var pos_ok: bool = typeof(pos) == TYPE_ARRAY and (pos as Array).size() == 2 \
		and typeof(pos[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(pos[1]) in [TYPE_INT, TYPE_FLOAT]
	out["respawn_position"] = [float(pos[0]), float(pos[1])] if pos_ok else [0.0, 0.0]
	# A checkpoint without a valid position or id is no checkpoint.
	out["has_checkpoint"] = bool(d.get("has_checkpoint", false)) and pos_ok and out["checkpoint_id"] != ""
	out["flags"] = (d.get("flags") as Dictionary).duplicate(true) if typeof(d.get("flags")) == TYPE_DICTIONARY else {}
	return out


func _num(v: Variant, default: float) -> float:
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


func _str(v: Variant, default: String) -> String:
	return String(v) if typeof(v) == TYPE_STRING else default
