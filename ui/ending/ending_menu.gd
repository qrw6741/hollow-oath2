class_name EndingMenu
extends CanvasLayer
## The Oath Gate's choice and the epilogue that follows. Opened with Events.ending_requested.
## CHOICE: one button per ending (locked ones show what they need). EPILOGUE: pages advance with
## Interact / Confirm / Light attack; the last page closes the menu and the world carries on.

enum Phase { CHOICE, EPILOGUE }

var is_open := false
var phase := Phase.CHOICE
var page := 0
var pages: Array = []
var _panel: ColorRect
var _title: Label
var _body: Label
var _hint: Label
var _buttons: Array[Button] = []
var _box: VBoxContainer
var _arm := 0


func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.02, 0.018, 0.03, 0.96)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	_panel.visible = false
	add_child(_panel)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override(&"separation", 5)
	c.add_child(_box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(_title, 16)
	_box.add_child(_title)
	_box.add_child(UITheme.rule(300))
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.custom_minimum_size = Vector2(320, 44)
	_body.add_theme_color_override(&"font_color", Palette.BONE)
	_box.add_child(_body)
	for i in Endings.ORDER.size():
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(320, 24)
		UITheme.compact(b)
		b.pressed.connect(_pick.bind(Endings.ORDER[i]))
		b.focus_entered.connect(_hover.bind(Endings.ORDER[i]))
		_box.add_child(b)
		_buttons.append(b)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(320, 20)
	_hint.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_box.add_child(_hint)
	Events.ending_requested.connect(open)


func open() -> void:
	if is_open or GameState.ui_modal or not Endings.gate_open():
		return
	is_open = true
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	Events.interact_prompt_hidden.emit()
	_panel.visible = true
	_show_choice()


func _show_choice() -> void:
	phase = Phase.CHOICE
	_title.text = "THE OATH GATE"
	_body.text = "The gate hears whatever you carry. Orren's lance lies where he fell. The oath is yours to hold, set down, or rewrite.\nThis choice cannot be taken back."
	for i in _buttons.size():
		var id: StringName = Endings.ORDER[i]
		var ok := Endings.available(id)
		_buttons[i].visible = true
		_buttons[i].text = "%s    %s" % [Endings.DEFS[id].title, Endings.DEFS[id].blurb] if ok else "%s    (locked)" % Endings.DEFS[id].title
		_buttons[i].modulate = Color.WHITE if ok else Color(1, 1, 1, 0.5)
	_hint.text = ""
	_buttons[0].grab_focus()


func _hover(id: StringName) -> void:
	if phase == Phase.CHOICE:
		_hint.text = Endings.reason(id)


func _pick(id: StringName) -> void:
	if phase != Phase.CHOICE:
		return
	if not Endings.available(id):
		_hint.text = Endings.reason(id)
		Audio.sfx(&"fizzle", -4.0)
		return
	if not Endings.choose(id):
		return
	phase = Phase.EPILOGUE
	pages = Endings.DEFS[id].pages
	page = 0
	_arm = 20
	for b in _buttons:
		b.visible = false
	_title.text = String(Endings.DEFS[id].title).to_upper()
	_body.text = pages[0]
	_hint.text = "Interact to continue"
	Audio.sting(&"victory")


func advance() -> void:
	if phase != Phase.EPILOGUE:
		return
	page += 1
	if page >= pages.size():
		close()
		return
	_body.text = pages[page]
	_hint.text = "Interact to continue" if page < pages.size() - 1 else "Interact to return to the road"


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false
	Events.banner_requested.emit("THE OATH IS %s" % ["KEPT", "BROKEN", "MENDED"][Endings.ORDER.find(Endings.chosen())])


func _process(_d: float) -> void:
	if _arm > 0:
		_arm -= 1


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if phase == Phase.CHOICE:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
			is_open = false
			_panel.visible = false
			get_tree().paused = false
			GameState.ui_modal = false
			get_viewport().set_input_as_handled()
	elif _arm <= 0 and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"attack_light")):
		advance()
		get_viewport().set_input_as_handled()
