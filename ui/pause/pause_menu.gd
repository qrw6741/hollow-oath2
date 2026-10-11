extends CanvasLayer
## Pause menu. Runs while the tree is paused; only available during a game session.
## Esc / Start toggles it; inside Settings, Esc goes back one level first.

const CONFIRM_MS := 3000

var _panel: ColorRect
var _main_page: VBoxContainer
var _settings: SettingsPanel
var _resume_btn: Button
var _menu_btn: Button
var _hint: Label
var _armed_until := 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.93)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	add_child(_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)

	_main_page = VBoxContainer.new()
	_main_page.add_theme_constant_override(&"separation", 4)
	center.add_child(_main_page)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 16)
	_main_page.add_child(title)

	_resume_btn = _button("Resume", _resume)
	_button("Settings", _open_settings)
	_menu_btn = _button("Quit to Main Menu", _on_quit_to_menu)
	_button("Quit to Desktop", func(): get_tree().quit())

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_hint.custom_minimum_size.y = 10
	_main_page.add_child(_hint)

	_settings = SettingsPanel.new()
	_settings.back_requested.connect(_close_settings)
	_settings.visible = false
	center.add_child(_settings)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(130, 16)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	_main_page.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.in_game:
		return
	if event.is_action_pressed(&"pause") or (get_tree().paused and event.is_action_pressed(&"ui_cancel")):
		if not get_tree().paused:
			_pause()
		elif _settings.visible:
			_settings._on_back()
		else:
			_resume()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _armed_until > 0 and Time.get_ticks_msec() > _armed_until:
		_disarm()


func _pause() -> void:
	get_tree().paused = true
	GameFeel.reset()
	_panel.visible = true
	_main_page.visible = true
	_settings.visible = false
	_disarm()
	_resume_btn.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	_panel.visible = false
	_disarm()


func _open_settings() -> void:
	_main_page.visible = false
	_settings.visible = true
	_settings.focus_first()


func _close_settings() -> void:
	_settings.visible = false
	_main_page.visible = true
	_resume_btn.grab_focus()


func _on_quit_to_menu() -> void:
	if _armed_until == 0:
		_armed_until = Time.get_ticks_msec() + CONFIRM_MS
		_menu_btn.text = "Sure?"
		_hint.text = "Progress since your last rest is lost"
		return
	_disarm()
	_resume()
	Events.quit_to_menu_requested.emit()


func _disarm() -> void:
	_armed_until = 0
	_menu_btn.text = "Quit to Main Menu"
	_hint.text = ""
