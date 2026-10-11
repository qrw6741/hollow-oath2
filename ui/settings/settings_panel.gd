class_name SettingsPanel
extends VBoxContainer
## Accessibility and audio options. Shared by the main menu and the pause menu.
## These change presentation only — they never alter combat timing or difficulty.
## Values apply immediately and are written to disk when the panel is left.

signal back_requested

var _shake: Button
var _flashes: Button
var _hitstop: Button
var _volume_label: Label
var _back: Button


func _ready() -> void:
	add_theme_constant_override(&"separation", 4)
	alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 12)
	add_child(title)

	_shake = _button(_toggle_shake)
	_flashes = _button(_toggle_flashes)
	_hitstop = _button(_toggle_hitstop)

	var vol := HBoxContainer.new()
	vol.alignment = BoxContainer.ALIGNMENT_CENTER
	vol.add_theme_constant_override(&"separation", 6)
	add_child(vol)
	var lab := Label.new()
	lab.text = "Volume"
	lab.custom_minimum_size.x = 60
	vol.add_child(lab)
	var minus := Button.new()
	minus.name = &"VolumeDown"
	minus.text = "-"
	minus.custom_minimum_size.x = 22
	minus.pressed.connect(_change_volume.bind(-0.1))
	vol.add_child(minus)
	_volume_label = Label.new()
	_volume_label.custom_minimum_size.x = 34
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vol.add_child(_volume_label)
	var plus := Button.new()
	plus.name = &"VolumeUp"
	plus.text = "+"
	plus.custom_minimum_size.x = 22
	plus.pressed.connect(_change_volume.bind(0.1))
	vol.add_child(plus)

	_back = _button(_on_back)
	_back.text = "Back"
	_refresh()


func _button(cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 16)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	add_child(b)
	return b


func focus_first() -> void:
	_shake.grab_focus()


func _refresh() -> void:
	_shake.text = "Screen shake: %s" % ("On" if Settings.screen_shake > 0.0 else "Off")
	_flashes.text = "Hit flashes: %s" % ("On" if Settings.flashes else "Off")
	_hitstop.text = "Hit-stop: %s" % ("On" if Settings.hit_stop else "Off")
	_volume_label.text = "%d%%" % roundi(Settings.master_volume * 100.0)


func _toggle_shake() -> void:
	Settings.screen_shake = 0.0 if Settings.screen_shake > 0.0 else 1.0
	_refresh()


func _toggle_flashes() -> void:
	Settings.flashes = not Settings.flashes
	_refresh()


func _toggle_hitstop() -> void:
	Settings.hit_stop = not Settings.hit_stop
	_refresh()


func _change_volume(step: float) -> void:
	Settings.master_volume = clampf(snappedf(Settings.master_volume + step, 0.1), 0.0, 1.0)
	Settings.apply_audio()
	_refresh()


func _on_back() -> void:
	Settings.save_settings()
	back_requested.emit()
