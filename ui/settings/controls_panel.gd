class_name ControlsPanel
extends VBoxContainer
## The Controls tab of the settings: one row per action with its keyboard binding and its
## controller binding. Select a cell, then press the new key / button.
##   - Keyboard column accepts a key or a mouse button. Esc cancels.
##   - Controller column accepts a controller button. Esc (keyboard) cancels; it also
##     cancels by itself after a few seconds.
##   - Movement on a controller is always the left stick + D-pad (not remappable).
##   - Using a binding that another action already had swaps the two.
## Changes apply and save immediately (user://input.cfg). "Reset to defaults" restores all.

const LISTEN_TIMEOUT := 5.0
const PS_NAMES := {"cross": "Cross", "circle": "Circle", "square": "Square", "triangle": "Triangle",
	"l1": "L1", "r1": "R1", "options": "Options", "create": "Create", "r3": "R3", "l3": "L3",
	"touchpad": "Touchpad", "dpad_up": "D-pad up", "dpad_down": "D-pad down",
	"dpad_left": "D-pad left", "dpad_right": "D-pad right", "stick": "Left stick"}
const XBOX_NAMES := {"cross": "A", "circle": "B", "square": "X", "triangle": "Y",
	"l1": "LB", "r1": "RB", "options": "Menu", "create": "View", "r3": "RS", "l3": "LS",
	"touchpad": "Touchpad", "dpad_up": "D-pad up", "dpad_down": "D-pad down",
	"dpad_left": "D-pad left", "dpad_right": "D-pad right", "stick": "Left stick"}

## True while waiting for the new key / button.
var listening := false
var listen_action: StringName = &""
var listen_pad := false
var _listen_btn: Button
var _listen_t := 0.0
var _ignore_frames := 0
var _kb: Dictionary = {}   # action -> Button
var _pad: Dictionary = {}  # action -> Button
var _note: Label
var _reset: Button
var _scroll: ScrollContainer


func _ready() -> void:
	add_theme_constant_override(&"separation", 2)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 4)
	head.add_child(_cell_label("Action", 96, Palette.DUST))
	head.add_child(_cell_label("Keyboard", 84, Palette.DUST))
	head.add_child(_cell_label("Controller", 84, Palette.DUST))
	add_child(head)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(272, 128)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	var vs := _scroll.get_v_scroll_bar()
	vs.custom_minimum_size.x = 3
	vs.add_theme_stylebox_override(&"scroll", UITheme.box(Color(Palette.STONE_DARK, 0.6), Color(0, 0, 0, 0), 0, Vector2.ZERO))
	for st in [&"grabber", &"grabber_highlight", &"grabber_pressed"]:
		vs.add_theme_stylebox_override(st, UITheme.box(Palette.GOLD if st != &"grabber" else Palette.BONE_DIM, Color(0, 0, 0, 0), 0, Vector2.ZERO))
	add_child(_scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 1)
	_scroll.add_child(rows)
	for action in InputConfig.REMAPPABLE:
		var r := HBoxContainer.new()
		r.add_theme_constant_override(&"separation", 4)
		r.add_child(_cell_label(InputConfig.ACTION_NAMES.get(action, String(action)), 96, Palette.BONE_DIM))
		var kb := _cell_button(84)
		kb.name = StringName("Key_" + String(action))
		kb.pressed.connect(start_listening.bind(action, false))
		r.add_child(kb)
		_kb[action] = kb
		var pb := _cell_button(84)
		pb.name = StringName("Pad_" + String(action))
		if InputConfig.MOVE_ACTIONS.has(action):
			pb.disabled = true
			pb.focus_mode = Control.FOCUS_NONE
		else:
			pb.pressed.connect(start_listening.bind(action, true))
		r.add_child(pb)
		_pad[action] = pb
		rows.add_child(r)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override(&"font_color", Palette.GOLD)
	_note.custom_minimum_size = Vector2(272, 10)
	add_child(_note)
	_reset = FancyButton.new()
	_reset.text = "Reset controls to defaults"
	_reset.name = &"ResetControls"
	_reset.custom_minimum_size = Vector2(170, 13)
	_reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.compact(_reset)
	_reset.pressed.connect(reset_defaults)
	add_child(_reset)
	InputPrompts.device_changed.connect(refresh)
	refresh()


func _cell_label(t: String, w: float, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(w, 11)
	l.clip_text = true
	l.add_theme_color_override(&"font_color", c)
	return l


func _cell_button(w: float) -> Button:
	var b := FancyButton.new()
	b.custom_minimum_size = Vector2(w, 11)
	b.clip_text = true
	UITheme.compact(b)
	return b


func focus_first() -> void:
	(_kb[InputConfig.REMAPPABLE[0]] as Button).grab_focus()


func _pad_names() -> Dictionary:
	var xbox := InputPrompts.device == InputPrompts.Device.XBOX or Settings.pad_style == 2
	return XBOX_NAMES if xbox else PS_NAMES


func refresh() -> void:
	if not is_inside_tree():
		return
	var names := _pad_names()
	for action in InputConfig.REMAPPABLE:
		var kb: Button = _kb[action]
		var pb: Button = _pad[action]
		if not (listening and _listen_btn == kb):
			var k := InputConfig.binding_names(action, false)
			kb.text = " / ".join(k) if not k.is_empty() else "-"
		if not (listening and _listen_btn == pb):
			var parts: Array[String] = []
			for id in InputConfig.binding_names(action, true):
				parts.append(names.get(id, id))
			if InputConfig.MOVE_ACTIONS.has(action):
				parts = ["Stick / D-pad"]
			pb.text = " / ".join(parts) if not parts.is_empty() else "-"


func start_listening(action: StringName, pad: bool) -> void:
	listening = true
	listen_action = action
	listen_pad = pad
	_listen_btn = _pad[action] if pad else _kb[action]
	_listen_btn.text = "Press a button..." if pad else "Press a key..."
	_listen_btn.grab_focus()
	_listen_t = 0.0
	_ignore_frames = 6
	_note.text = "Esc to cancel"


func _process(delta: float) -> void:
	if _ignore_frames > 0:
		_ignore_frames -= 1
	if listening:
		_listen_t += delta
		if _listen_t > LISTEN_TIMEOUT:
			stop_listening("Cancelled")


func stop_listening(msg := "") -> void:
	var btn := _listen_btn
	listening = false
	_listen_btn = null
	_note.text = msg
	refresh()
	if is_instance_valid(btn):
		btn.grab_focus()


func _input(event: InputEvent) -> void:
	if not listening or not is_visible_in_tree():
		return
	# Swallow everything while listening so menus don't react to the key being bound.
	get_viewport().set_input_as_handled()
	if _ignore_frames > 0 or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE):
		stop_listening("Cancelled")
		return
	if listen_pad:
		if event is InputEventJoypadButton:
			apply_binding(listen_action, event)
	elif event is InputEventKey or event is InputEventMouseButton:
		apply_binding(listen_action, event)


## Binds [param event] (a copy is stored) and reports any swap. Used by the UI and tests.
func apply_binding(action: StringName, event: InputEvent) -> void:
	var ev: InputEvent
	if event is InputEventKey:
		var k := InputEventKey.new()
		k.physical_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		ev = k
	elif event is InputEventMouseButton:
		var m := InputEventMouseButton.new()
		m.button_index = event.button_index
		ev = m
	elif event is InputEventJoypadButton:
		var j := InputEventJoypadButton.new()
		j.button_index = event.button_index
		ev = j
	else:
		return
	var swapped := InputConfig.rebind_swap(action, ev)
	var msg := ""
	if swapped != &"":
		msg = "Swapped with %s" % InputConfig.ACTION_NAMES.get(swapped, String(swapped))
	if listening:
		stop_listening(msg)
	else:
		_note.text = msg
		refresh()
	InputPrompts.refresh()


func reset_defaults() -> void:
	InputConfig.reset_all()
	_note.text = "Controls reset"
	refresh()
	InputPrompts.refresh()
