class_name Presets
extends RefCounted
## Registry of starting presets. Order here is the order on the selection screen.

const IDS: Array[StringName] = [&"sworn_knight", &"duelist", &"bulwark", &"unsworn"]
const DEFAULT_ID: StringName = &"sworn_knight"
const DIR := "res://data/presets/"

static var _cache := {}


## Unknown ids (an edited or future save) fall back to the default preset.
static func get_preset(id: StringName) -> PresetData:
	if not IDS.has(id):
		id = DEFAULT_ID
	if not _cache.has(id):
		_cache[id] = load(DIR + String(id) + ".tres") as PresetData
	return _cache[id]


static func all() -> Array[PresetData]:
	var out: Array[PresetData] = []
	for id in IDS:
		out.append(get_preset(id))
	return out


static func is_valid_id(id: String) -> bool:
	return IDS.has(StringName(id))
