extends Node
## Tracks which device the player used last (keyboard / PlayStation pad / Xbox-style pad)
## and answers "what button do I show for this action?". UI glyphs (ui/glyph.gd) and hint
## bars (ui/hint_bar.gd) redraw when [signal device_changed] fires, so prompts always
## match the hardware in the player's hands.
##
## SDL maps the DualSense to Godot's Xbox-named buttons: A=Cross, B=Circle, X=Square,
## Y=Triangle, LB/RB=L1/R1, Start=Options. Rebinding therefore needs no PlayStation-specific code.

signal device_changed

enum Device { KEYBOARD, PLAYSTATION, XBOX }

const SONY_WORDS := ["ps5", "ps4", "ps3", "dualsense", "dualshock", "playstation", "sony"]

var device := Device.KEYBOARD
var _pad_is_sony := false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		set_device(Device.KEYBOARD)
	elif event is InputEventMouseButton and event.pressed:
		set_device(Device.KEYBOARD)
	elif event is InputEventJoypadButton and event.pressed:
		_pad_used(event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		_pad_used(event.device)


func _pad_used(dev_id: int) -> void:
	var name := Input.get_joy_name(dev_id).to_lower()
	_pad_is_sony = SONY_WORDS.any(func(w): return name.contains(w))
	set_device(_pad_device())


func _pad_device() -> Device:
	match Settings.pad_style:
		1: return Device.PLAYSTATION
		2: return Device.XBOX
	return Device.PLAYSTATION if _pad_is_sony else Device.XBOX


## Re-evaluates after the "Controller icons" setting changes.
func refresh() -> void:
	if device != Device.KEYBOARD:
		set_device(_pad_device(), true)
	else:
		device_changed.emit()


func set_device(d: Device, force := false) -> void:
	if d == device and not force:
		return
	device = d
	device_changed.emit()


func is_pad() -> bool:
	return device != Device.KEYBOARD


## Token for the current device: a pad token ("cross", "l1", "dpad_up"...) or a key name.
## Returns { "pad": bool, "id": String }.
func token_for(action: StringName) -> Dictionary:
	if is_pad():
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton:
				return {"pad": true, "id": _button_id(ev.button_index)}
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion:
				return {"pad": true, "id": "stick_l"}
		match action:
			&"ui_accept": return {"pad": true, "id": "cross"}
			&"ui_cancel": return {"pad": true, "id": "circle"}
		return {"pad": true, "id": "?"}
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var code: Key = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			return {"pad": false, "id": OS.get_keycode_string(code)}
		if ev is InputEventMouseButton:
			return {"pad": false, "id": "LMB" if ev.button_index == MOUSE_BUTTON_LEFT else "RMB"}
	return {"pad": false, "id": String(action)}


func _button_id(b: int) -> String:
	match b:
		JOY_BUTTON_A: return "cross"
		JOY_BUTTON_B: return "circle"
		JOY_BUTTON_X: return "square"
		JOY_BUTTON_Y: return "triangle"
		JOY_BUTTON_LEFT_SHOULDER: return "l1"
		JOY_BUTTON_RIGHT_SHOULDER: return "r1"
		JOY_BUTTON_START: return "options"
		JOY_BUTTON_BACK: return "create"
		JOY_BUTTON_DPAD_UP: return "dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "dpad_right"
	return "?"


## Short controller vibration, only while a pad is the active device.
func rumble(weak: float, strong: float, duration: float) -> void:
	if not Settings.vibration or not is_pad():
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), duration)
