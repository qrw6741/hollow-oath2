extends CanvasLayer
## Pause menu with accessibility toggles. Runs while the tree is paused.


var _panel: Control
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false


func _build() -> void:
	_panel = ColorRect.new()
	(_panel as ColorRect).color = Color(Palette.INK, 0.82)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(170, 70)
	box.size = Vector2(140, 140)
	box.add_theme_constant_override(&"separation", 4)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 16)
	title.add_theme_color_override(&"font_color", Palette.BONE)
	box.add_child(title)

	_add_button(box, "Resume", _resume)
	_add_button(box, "", _toggle_shake, &"shake")
	_add_button(box, "", _toggle_flashes, &"flashes")
	_add_button(box, "", _toggle_hitstop, &"hitstop")
	_add_button(box, "Quit to Desktop", func(): get_tree().quit())
	_refresh()


func _add_button(parent: Node, text: String, cb: Callable, key: StringName = &"") -> void:
	var b := Button.new()
	b.text = text
	b.set_meta(&"key", key)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	_buttons.append(b)


func _refresh() -> void:
	for b in _buttons:
		match b.get_meta(&"key"):
			&"shake": b.text = "Screen shake: %s" % ("On" if Settings.screen_shake > 0.0 else "Off")
			&"flashes": b.text = "Hit flashes: %s" % ("On" if Settings.flashes else "Off")
			&"hitstop": b.text = "Hit-stop: %s" % ("On" if Settings.hit_stop else "Off")


func _toggle_shake() -> void:
	Settings.screen_shake = 0.0 if Settings.screen_shake > 0.0 else 1.0
	Settings.save_settings()
	_refresh()


func _toggle_flashes() -> void:
	Settings.flashes = not Settings.flashes
	Settings.save_settings()
	_refresh()


func _toggle_hitstop() -> void:
	Settings.hit_stop = not Settings.hit_stop
	Settings.save_settings()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	get_tree().paused = true
	GameFeel.reset()
	_panel.visible = true
	_buttons[0].grab_focus()


func _resume() -> void:
	get_tree().paused = false
	_panel.visible = false
