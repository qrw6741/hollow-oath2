class_name ShopMenu
extends CanvasLayer
## A merchant's wares: one row per item (icon, name, owned, price). Confirm buys one.
## Opened with Events.shop_requested(shop_id); pauses the game while open.

var is_open := false
var shop_id: StringName = &""
var _panel: ColorRect
var _title: Label
var _embers: Label
var _list: VBoxContainer
var _desc: Label
var _msg: Label
var _leave: Button
var rows: Array = []   # [{"item": StringName, "button": Button, "slot": IconSlot}]


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.9)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	_panel.visible = false
	add_child(_panel)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	c.add_child(v)
	v.draw.connect(func(): UITheme.draw_panel(v, Rect2(Vector2(-22, -14), v.size + Vector2(44, 28))))
	v.resized.connect(v.queue_redraw)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(_title, 14)
	v.add_child(_title)
	v.add_child(UITheme.rule(240))
	_embers = Label.new()
	_embers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_embers.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	v.add_child(_embers)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 2)
	v.add_child(_list)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(240, 26)
	_desc.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	v.add_child(_desc)
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.custom_minimum_size.y = 10
	_msg.add_theme_color_override(&"font_color", Palette.GOLD)
	v.add_child(_msg)
	_leave = FancyButton.new()
	_leave.text = "Leave"
	_leave.custom_minimum_size = Vector2(240, 15)
	_leave.pressed.connect(close)
	UITheme.compact(_leave)
	v.add_child(_leave)
	Events.shop_requested.connect(open)
	Events.embers_changed.connect(func(_n): _refresh())
	Events.inventory_changed.connect(_refresh)


func open(id: StringName) -> void:
	if is_open or GameState.ui_modal:
		return
	shop_id = id
	is_open = true
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	_title.text = Shops.shop_name(id)
	_msg.text = ""
	for r in rows:
		(r.row as Node).queue_free()
	rows.clear()
	for e in Shops.stock(id):
		var item := Items.get_item(e.item)
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 3)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(16, 16)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = e.item
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(221, 16)
		UITheme.compact(b)
		b.pressed.connect(_on_buy.bind(e.item))
		b.focus_entered.connect(_describe.bind(e.item))
		row.add_child(b)
		_list.add_child(row)
		rows.append({"item": e.item, "button": b, "slot": slot, "row": row})
	_panel.visible = true
	_refresh()
	if not rows.is_empty():
		(rows[0].button as Button).grab_focus()
		_describe(rows[0].item)
	else:
		_leave.grab_focus()


func _describe(item_id: StringName) -> void:
	var item := Items.get_item(item_id)
	_desc.text = item.description if item else ""


func _price(item_id: StringName) -> int:
	for e in Shops.stock(shop_id):
		if e.item == item_id:
			return int(e.price)
	return 0


func _refresh() -> void:
	if not is_open:
		return
	_embers.text = "Embers: %d" % GameState.embers
	for r in rows:
		var item := Items.get_item(r.item)
		var owned := GameState.item_count(r.item)
		var price := _price(r.item)
		(r.button as Button).text = "%s     owned %d     %d" % [item.display_name, owned, price]
		(r.button as Button).modulate = Color.WHITE if GameState.embers >= price else Color(1, 1, 1, 0.55)


func _on_buy(item_id: StringName) -> void:
	var res := Shops.buy(shop_id, item_id)
	_msg.text = res.msg
	Audio.sfx(&"coin" if res.ok else &"fizzle", -4.0)
	_refresh()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false
	Events.shop_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		close()
		get_viewport().set_input_as_handled()
