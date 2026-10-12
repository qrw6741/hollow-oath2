extends Node
## Registers the default input map at startup and provides runtime remapping.
## Defaults live here (not in project.godot) so remapping, resetting and saving
## all work from a single source of truth. Custom bindings persist to user://input.cfg.

const PATH := "user://input.cfg"

## action -> list of default events descriptors.
## "k:<keycode>"  keyboard (physical), "m:<button>" mouse, "j:<button>" joypad button,
## "a:<axis>:<sign>" joypad axis.
const DEFAULTS := {
	&"move_left": ["k:%d" % KEY_A, "k:%d" % KEY_LEFT, "a:%d:-1" % JOY_AXIS_LEFT_X, "j:%d" % JOY_BUTTON_DPAD_LEFT],
	&"move_right": ["k:%d" % KEY_D, "k:%d" % KEY_RIGHT, "a:%d:1" % JOY_AXIS_LEFT_X, "j:%d" % JOY_BUTTON_DPAD_RIGHT],
	&"move_up": ["k:%d" % KEY_W, "k:%d" % KEY_UP, "a:%d:-1" % JOY_AXIS_LEFT_Y, "j:%d" % JOY_BUTTON_DPAD_UP],
	&"move_down": ["k:%d" % KEY_S, "k:%d" % KEY_DOWN, "a:%d:1" % JOY_AXIS_LEFT_Y, "j:%d" % JOY_BUTTON_DPAD_DOWN],
	&"jump": ["k:%d" % KEY_SPACE, "j:%d" % JOY_BUTTON_A],
	&"attack_light": ["k:%d" % KEY_J, "m:%d" % MOUSE_BUTTON_LEFT, "j:%d" % JOY_BUTTON_X],
	&"attack_heavy": ["k:%d" % KEY_K, "m:%d" % MOUSE_BUTTON_RIGHT, "j:%d" % JOY_BUTTON_Y],
	&"dodge": ["k:%d" % KEY_L, "k:%d" % KEY_SHIFT, "j:%d" % JOY_BUTTON_B],
	&"parry": ["k:%d" % KEY_I, "k:%d" % KEY_Q, "j:%d" % JOY_BUTTON_LEFT_SHOULDER],
	&"heal": ["k:%d" % KEY_R, "j:%d" % JOY_BUTTON_RIGHT_SHOULDER],
	&"interact": ["k:%d" % KEY_E, "j:%d" % JOY_BUTTON_DPAD_UP],
	&"use_item": ["k:%d" % KEY_F, "j:%d" % JOY_BUTTON_RIGHT_STICK],
	&"inventory": ["k:%d" % KEY_TAB, "j:%d" % JOY_BUTTON_BACK],
	&"map": ["k:%d" % KEY_M, "j:%d" % JOY_BUTTON_TOUCHPAD, "j:%d" % JOY_BUTTON_LEFT_STICK],
	&"travel_manor": ["k:%d" % KEY_T, "j:%d" % JOY_BUTTON_MISC1],
	&"skill": ["k:%d" % KEY_O, "a:%d:1" % JOY_AXIS_TRIGGER_RIGHT],
	&"pause": ["k:%d" % KEY_ESCAPE, "j:%d" % JOY_BUTTON_START],
	&"debug_toggle": ["k:%d" % KEY_F3],
}


func _ready() -> void:
	_ensure_ui_pad_buttons()
	reset_to_defaults()
	_load_custom()


## Godot's built-in ui_accept / ui_cancel do not always carry controller buttons
## (observed: none at all), which made menus unusable on a pad. Add them explicitly:
## Cross / A confirms, Circle / B cancels.
func _ensure_ui_pad_buttons() -> void:
	for pair in [[&"ui_accept", JOY_BUTTON_A], [&"ui_cancel", JOY_BUTTON_B]]:
		var has := false
		for ev in InputMap.action_get_events(pair[0]):
			if ev is InputEventJoypadButton and ev.button_index == pair[1]:
				has = true
		if not has:
			var e := InputEventJoypadButton.new()
			e.button_index = pair[1]
			InputMap.action_add_event(pair[0], e)


func reset_to_defaults() -> void:
	for action: StringName in DEFAULTS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.4)
		for desc: String in DEFAULTS[action]:
			var ev := _event_from(desc)
			if ev:
				InputMap.action_add_event(action, ev)


## Replace all keyboard/mouse bindings (or all joypad bindings) of an action with [param event].
func rebind(action: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	var is_pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	for existing in InputMap.action_get_events(action):
		var existing_pad := existing is InputEventJoypadButton or existing is InputEventJoypadMotion
		if existing_pad == is_pad:
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event)
	_save_custom()


## Movement keeps its stick + D-pad on a controller; only its keys can be remapped.
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
## Actions shown on the Controls page, in order (debug_toggle is not remappable).
const REMAPPABLE: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down",
	&"jump", &"attack_light", &"attack_heavy", &"dodge", &"parry", &"heal", &"interact",
	&"use_item", &"skill", &"travel_manor", &"inventory", &"map", &"pause"]
const ACTION_NAMES := {
	&"move_left": "Move left", &"move_right": "Move right", &"move_up": "Look up / climb",
	&"move_down": "Crouch / drop", &"jump": "Jump", &"attack_light": "Light attack",
	&"attack_heavy": "Heavy attack", &"dodge": "Dodge", &"parry": "Parry",
	&"heal": "Heal", &"interact": "Interact", &"use_item": "Use quick item",
	&"skill": "Weapon skill", &"travel_manor": "Hollowmere travel",
	&"inventory": "Inventory", &"map": "Map", &"pause": "Pause",
}


static func is_pad_event(ev: InputEvent) -> bool:
	return ev is InputEventJoypadButton or ev is InputEventJoypadMotion


## Binds [param event] to [param action] (replacing that action's bindings of the same kind).
## If another remappable action already used it, the two swap: that action takes this
## action's previous binding. Returns the swapped action's name ("" if none).
## On a controller, movement actions are ignored when checking (the D-pad doubles as menu
## navigation and Interact = D-pad up by default).
func rebind_swap(action: StringName, event: InputEvent) -> StringName:
	var pad := is_pad_event(event)
	var desc := _descriptor_of(event)
	var previous: Array[InputEvent] = []
	for ev in InputMap.action_get_events(action):
		if is_pad_event(ev) == pad:
			previous.append(ev)
	var swapped: StringName = &""
	for other in REMAPPABLE:
		if other == action or (pad and MOVE_ACTIONS.has(other)):
			continue
		for ev in InputMap.action_get_events(other):
			if is_pad_event(ev) == pad and _descriptor_of(ev) == desc:
				InputMap.action_erase_event(other, ev)
				if not previous.is_empty():
					InputMap.action_add_event(other, previous[0])
				swapped = other
	rebind(action, event)
	return swapped


## Restores every default binding and forgets the saved custom ones.
func reset_all() -> void:
	reset_to_defaults()
	_save_custom()


## The names of an action's bindings for one device kind, e.g. ["L", "Shift"] or ["l1"].
## Pad entries are InputPrompts button ids ("cross", "l1", "dpad_up") or "stick".
func binding_names(action: StringName, pad: bool) -> Array[String]:
	var out: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if is_pad_event(ev) != pad:
			continue
		if ev is InputEventKey:
			out.append(OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode))
		elif ev is InputEventMouseButton:
			out.append({MOUSE_BUTTON_LEFT: "Mouse L", MOUSE_BUTTON_RIGHT: "Mouse R", MOUSE_BUTTON_MIDDLE: "Mouse M"}.get(ev.button_index, "Mouse %d" % ev.button_index))
		elif ev is InputEventJoypadButton:
			out.append(InputPrompts._button_id(ev.button_index))
		elif ev is InputEventJoypadMotion:
			if not out.has("stick"):
				out.append("stick")
	return out


func _save_custom() -> void:
	var cfg := ConfigFile.new()
	for action: StringName in DEFAULTS:
		var list: Array[String] = []
		for ev in InputMap.action_get_events(action):
			var d := _descriptor_of(ev)
			if d != "":
				list.append(d)
		cfg.set_value("bindings", String(action), list)
	cfg.save(PATH)


func _load_custom() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for action: StringName in DEFAULTS:
		var list = cfg.get_value("bindings", String(action)) if cfg.has_section_key("bindings", String(action)) else null
		if typeof(list) != TYPE_ARRAY or (list as Array).is_empty():
			continue
		InputMap.action_erase_events(action)
		for desc in list:
			var ev := _event_from(str(desc))
			if ev:
				InputMap.action_add_event(action, ev)


func _event_from(desc: String) -> InputEvent:
	var parts := desc.split(":")
	match parts[0]:
		"k":
			var k := InputEventKey.new()
			k.physical_keycode = int(parts[1]) as Key
			return k
		"m":
			var m := InputEventMouseButton.new()
			m.button_index = int(parts[1]) as MouseButton
			return m
		"j":
			var j := InputEventJoypadButton.new()
			j.button_index = int(parts[1]) as JoyButton
			return j
		"a":
			var a := InputEventJoypadMotion.new()
			a.axis = int(parts[1]) as JoyAxis
			a.axis_value = float(parts[2])
			return a
	return null


func _descriptor_of(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return "k:%d" % (ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
	if ev is InputEventMouseButton:
		return "m:%d" % ev.button_index
	if ev is InputEventJoypadButton:
		return "j:%d" % ev.button_index
	if ev is InputEventJoypadMotion:
		return "a:%d:%d" % [ev.axis, signi(roundi(ev.axis_value))]
	return ""
