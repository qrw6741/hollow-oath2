class_name DialogueBox
extends CanvasLayer
## Speech box at the bottom of the screen. Lines type out; Interact / Confirm / Light attack
## finishes the line, then moves to the next; Cancel / Pause skips the rest. The game is
## paused while it is open. Opened with Events.dialogue_requested.

const CHARS_PER_SECOND := 70.0

var is_open := false
var speaker := ""
var lines: Array = []
var index := 0
var _shown := 0.0
var _arm := 0
var _panel: PanelContainer
var _name: Label
var _text: Label
var _hint: HBoxContainer
var _last_voice := 0


func _ready() -> void:
	layer = 23
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.theme = UITheme.get_theme()
	_panel.visible = false
	_panel.position = Vector2(70, 190)
	_panel.custom_minimum_size = Vector2(340, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	UITheme.frame(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	_panel.add_child(v)
	_name = Label.new()
	UITheme.title(_name, 10, Palette.GOLD_BRIGHT)
	v.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(324, 38)
	_text.add_theme_constant_override(&"line_spacing", -1)
	v.add_child(_text)
	_hint = HBoxContainer.new()
	_hint.alignment = BoxContainer.ALIGNMENT_END
	_hint.add_theme_constant_override(&"separation", 3)
	var g := Glyph.new()
	g.action = &"interact"
	_hint.add_child(g)
	var hl := Label.new()
	hl.text = "continue"
	hl.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_hint.add_child(hl)
	v.add_child(_hint)
	Events.dialogue_requested.connect(open)


func _line_parts(i: int) -> Dictionary:
	var l = lines[i]
	if typeof(l) == TYPE_DICTIONARY:
		return {"who": String(l.get("who", speaker)), "text": String(l.get("text", ""))}
	return {"who": speaker, "text": String(l)}


func open(who: String, the_lines: Array) -> void:
	if is_open or the_lines.is_empty() or GameState.ui_modal:
		return
	is_open = true
	speaker = who
	lines = the_lines
	index = 0
	_arm = 10   # the press that opened it must not also advance it
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	Events.interact_prompt_hidden.emit()
	_panel.visible = true
	_show_line()


func _show_line() -> void:
	var p := _line_parts(index)
	_name.text = p.who
	_text.text = p.text
	_text.visible_characters = 0
	_shown = 0.0
	_panel.reset_size()
	_panel.position = Vector2(240 - _panel.size.x / 2.0, 262 - _panel.size.y)


func line_done() -> bool:
	return _text.visible_characters == -1 or _text.visible_characters >= _text.get_total_character_count()


func advance() -> void:
	if not is_open:
		return
	if not line_done():
		_text.visible_characters = -1   # finish typing
		return
	index += 1
	if index >= lines.size():
		close()
	else:
		_show_line()
		Audio.sfx(&"ui_select", -14.0)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false
	Events.dialogue_closed.emit()


func _process(delta: float) -> void:
	if not is_open:
		return
	if _arm > 0:
		_arm -= 1
	if not line_done():
		_shown += CHARS_PER_SECOND * delta
		var n := int(_shown)
		if n != _text.visible_characters:
			_text.visible_characters = n
			if n - _last_voice >= 3:
				_last_voice = n
				Audio.sfx(&"talk", -12.0, randf_range(0.9, 1.15))
	_hint.modulate.a = 1.0 if line_done() else 0.35


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or _arm > 0:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"attack_light"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
