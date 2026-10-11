class_name InventoryMenu
extends CanvasLayer
## Pack screen: list of carried items, a description, Use and "Set quick slot".
## Opens with the Inventory button (Tab / Select-Create) or from the pause / candle menus,
## and pauses the game while open. Navigable with keyboard, mouse and gamepad.

var is_open := false
var _was_paused := false
var _prev_modal := false
var _panel: ColorRect
var _list: VBoxContainer
var _name: Label
var _kind: Label
var _desc: Label
var _msg: Label
var _use_btn: Button
var _quick_btn: Button
var _close_btn: Button
var _title: Label
var _selected: StringName = &""


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false
	Events.inventory_menu_requested.connect(open)
	Events.inventory_changed.connect(func(): if is_open: _rebuild())


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.95)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	add_child(_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -14
	_panel.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 4)
	center.add_child(v)
	_title = Label.new()
	_title.text = "PACK"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(_title, 14)
	v.add_child(_title)
	v.add_child(UITheme.rule(220))
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	v.add_child(h)
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(150, 160)
	h.add_child(left)
	UITheme.frame(left)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 1)
	left.add_child(_list)
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(230, 160)
	h.add_child(right)
	UITheme.frame(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 4)
	right.add_child(rv)
	_name = Label.new()
	UITheme.title(_name, 13, Palette.GOLD_BRIGHT)
	rv.add_child(_name)
	_kind = Label.new()
	_kind.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	rv.add_child(_kind)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(214, 60)
	_desc.add_theme_constant_override(&"line_spacing", -2)
	rv.add_child(_desc)
	_msg = Label.new()
	_msg.add_theme_color_override(&"font_color", Palette.CRIMSON_BRIGHT)
	_msg.custom_minimum_size.y = 10
	rv.add_child(_msg)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(spacer)
	_use_btn = _btn(rv, "Use", _on_use)
	_quick_btn = _btn(rv, "Set as quick item", _on_quick)
	_close_btn = _btn(v, "Close", close)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hint := HintBar.new()
	hint.spec = "inventory:close,use_item:use quick item"
	v.add_child(hint)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := FancyButton.new()
	b.text = text
	b.custom_minimum_size = Vector2(130, 15)
	b.pressed.connect(cb)
	UITheme.compact(b)
	parent.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"inventory") and GameState.in_game and not GameState.ui_modal and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	_was_paused = get_tree().paused
	_prev_modal = GameState.ui_modal
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	_msg.text = ""
	_panel.visible = true
	_rebuild()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = _was_paused
	GameState.ui_modal = _prev_modal
	Events.inventory_menu_closed.emit()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var first: Button
	var found := false
	for id in Items.IDS:
		var n := GameState.item_count(id)
		if n <= 0:
			continue
		var item := Items.get_item(id)
		var b := FancyButton.new()
		b.text = "%s%s%s" % [item.display_name, "  x%d" % n if n > 1 else "", "   [quick]" if id == GameState.quick_item else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(140, 14)
		UITheme.compact(b)
		b.focus_entered.connect(_select.bind(id))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_select.bind(id))
		_list.add_child(b)
		if first == null:
			first = b
		if id == _selected:
			first = b
			found = true
	if _list.get_child_count() == 0:
		var l := Label.new()
		l.text = "Your pack is empty."
		l.add_theme_color_override(&"font_color", Palette.BONE_DIM)
		_list.add_child(l)
		_selected = &""
		_show_detail()
		_close_btn.grab_focus()
		return
	if not found:
		_selected = &""
	first.grab_focus()
	_show_detail()


func _select(id: StringName) -> void:
	_selected = id
	_msg.text = ""
	_show_detail()


func _show_detail() -> void:
	var item := Items.get_item(_selected)
	_use_btn.visible = item != null and item.is_usable()
	_quick_btn.visible = _use_btn.visible
	if item == null:
		_name.text = ""
		_kind.text = ""
		_desc.text = ""
		return
	_name.text = item.display_name
	_kind.text = ["Consumable", "Key item", "Lore"][item.kind]
	_desc.text = item.description
	_quick_btn.disabled = _selected == GameState.quick_item
	_quick_btn.text = "Quick item (set)" if _quick_btn.disabled else "Set as quick item"


func _on_use() -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if Items.use(_selected, p):
		_msg.text = ""
	else:
		_msg.text = "That would have no effect right now."


func _on_quick() -> void:
	GameState.quick_item = _selected
	Events.inventory_changed.emit()
