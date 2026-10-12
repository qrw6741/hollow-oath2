class_name ShopMenu
extends CanvasLayer
## A merchant's counter. Two tabs, BUY and SELL (switch with Parry / Heal or by clicking).
## Left: one row per ware (icon, name, price in ember-gold, red when you cannot afford it).
## Right: the highlighted item drawn large with its description, what it does, how many you
## carry and what your embers will be afterwards. Confirm trades one; Cancel leaves.
## Opened with Events.shop_requested(shop_id); pauses the game while open.

var is_open := false
var shop_id: StringName = &""
var selling := false
var _panel: ColorRect
var _title: Label
var _chip: EmberChip
var _list: VBoxContainer
var _empty: Label
var _msg: Label
var _leave: Button
var _tab_btns: Array[Button] = []
var _big: IconSlot
var _d_name: Label
var _d_kind: Label
var _d_desc: Label
var _d_effect: Label
var _d_have: Label
var _d_after: Label
var _focus_item: StringName = &""
var rows: Array = []   # [{"item": StringName, "button": Button, "slot": IconSlot, "row": Node, "price": Label}]


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
	v.draw.connect(func(): UITheme.draw_panel(v, Rect2(Vector2(-18, -12), v.size + Vector2(36, 24))))
	v.resized.connect(v.queue_redraw)
	# Header: name of the stall on the left, your embers on the right.
	var head := HBoxContainer.new()
	head.custom_minimum_size.x = 370
	v.add_child(head)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.title(_title, 14)
	head.add_child(_title)
	_chip = EmberChip.new()
	head.add_child(_chip)
	v.add_child(UITheme.rule(370))
	# Tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 6)
	v.add_child(tabs)
	for i in 2:
		var b := FancyButton.new()
		b.text = ["BUY", "SELL"][i]
		b.custom_minimum_size = Vector2(70, 15)
		b.add_theme_font_override(&"font", UITheme.title_font())
		b.add_theme_font_size_override(&"font_size", 10)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(i == 1))
		UITheme.compact(b)
		tabs.add_child(b)
		_tab_btns.append(b)
	var hint := HintBar.new()
	hint.spec = "parry:prev tab,heal:next tab"
	tabs.add_child(hint)
	# Body: wares on the left, the item drawn large on the right.
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 8)
	v.add_child(body)
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(176, 112)
	body.add_child(left)
	UITheme.frame(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 2)
	lv.add_child(_list)
	_empty = Label.new()
	_empty.text = "Nothing she would take."
	_empty.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_empty.visible = false
	lv.add_child(_empty)
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(186, 112)
	body.add_child(right)
	UITheme.frame(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override(&"separation", 2)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 7)
	rv.add_child(top)
	_big = IconSlot.new()
	_big.custom_minimum_size = Vector2(38, 38)
	_big.focus_mode = Control.FOCUS_NONE
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_big)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override(&"separation", 0)
	top.add_child(tv)
	_d_name = Label.new()
	UITheme.title(_d_name, 11, Palette.GOLD_BRIGHT)
	tv.add_child(_d_name)
	_d_kind = Label.new()
	_d_kind.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	tv.add_child(_d_kind)
	_d_have = Label.new()
	_d_have.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	tv.add_child(_d_have)
	_d_desc = Label.new()
	_d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_desc.custom_minimum_size = Vector2(170, 34)
	_d_desc.add_theme_color_override(&"font_color", Palette.BONE)
	_d_desc.add_theme_constant_override(&"line_spacing", -2)
	rv.add_child(_d_desc)
	_d_effect = Label.new()
	_d_effect.add_theme_color_override(&"font_color", Color("b9d99a"))
	rv.add_child(_d_effect)
	_d_after = Label.new()
	_d_after.add_theme_color_override(&"font_color", Palette.GOLD)
	rv.add_child(_d_after)
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.custom_minimum_size.y = 10
	_msg.add_theme_color_override(&"font_color", Palette.GOLD)
	v.add_child(_msg)
	_leave = FancyButton.new()
	_leave.text = "Leave"
	_leave.custom_minimum_size = Vector2(370, 15)
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
	_panel.visible = true
	_chip.set_value(GameState.embers, true)
	show_tab(false)


## Switches between BUY (false) and SELL (true) and rebuilds the list.
func show_tab(sell: bool) -> void:
	selling = sell
	for i in _tab_btns.size():
		_tab_btns[i].add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if (i == 1) == sell else Palette.STONE_LIGHT)
	_rebuild()
	Audio.sfx(&"ui_move", -4.0)


func _entries() -> Array:
	return Shops.sellable() if selling else Shops.stock(shop_id)


func _rebuild() -> void:
	for r in rows:
		(r.row as Node).queue_free()
	rows.clear()
	for e in _entries():
		var item := Items.get_item(e.item)
		if item == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 3)
		var slot := IconSlot.new()
		slot.custom_minimum_size = Vector2(17, 17)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.icon_id = e.item
		row.add_child(slot)
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(112, 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UITheme.compact(b)
		b.pressed.connect(_on_trade.bind(e.item))
		b.focus_entered.connect(_describe.bind(e.item))
		b.mouse_entered.connect(_describe.bind(e.item))
		row.add_child(b)
		var price := Label.new()
		price.custom_minimum_size = Vector2(36, 17)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(price)
		_list.add_child(row)
		rows.append({"item": e.item, "button": b, "slot": slot, "row": row, "price": price})
	_empty.visible = rows.is_empty()
	_refresh()
	if not rows.is_empty():
		(rows[0].button as Button).grab_focus()
		_describe(rows[0].item)
	else:
		_describe(&"")
		_leave.grab_focus()


func _price(item_id: StringName) -> int:
	return Shops.sell_price(item_id) if selling else Shops.buy_price_in(shop_id, item_id)


func _describe(item_id: StringName) -> void:
	_focus_item = item_id
	var item := Items.get_item(item_id)
	_big.icon_id = item_id
	if item == null:
		_d_name.text = ""
		_d_kind.text = ""
		_d_have.text = ""
		_d_desc.text = "Nothing in your pack that she would buy." if selling else ""
		_d_effect.text = ""
		_d_after.text = ""
		return
	_d_name.text = item.display_name
	_d_kind.text = ["Consumable", "Key item", "Lore"][item.kind]
	_d_desc.text = item.description
	_d_effect.text = _effect_text(item)
	_update_after()


func _effect_text(item: ItemData) -> String:
	match item.effect:
		ItemData.Effect.HEAL: return "Restores %d health" % roundi(item.effect_amount)
		ItemData.Effect.STAMINA: return "Restores %d stamina" % roundi(item.effect_amount)
		ItemData.Effect.EMBERS: return "Releases %d embers" % roundi(item.effect_amount)
		_:
			if item.id == &"forge_scrap" or item.id == &"hollow_resin":
				return "Smithing material (Hobb, Ilse)"
	return ""


func _update_after() -> void:
	var item := Items.get_item(_focus_item)
	if item == null:
		return
	var price := _price(_focus_item)
	_d_have.text = "You carry %d" % GameState.item_count(_focus_item)
	if selling:
		_d_after.text = "Sell for %d      embers %d -> %d" % [price, GameState.embers, GameState.embers + price]
	else:
		var left := GameState.embers - price
		_d_after.text = "Cost %d      embers %d -> %d" % [price, GameState.embers, left] if left >= 0 else "Cost %d      you are %d short" % [price, -left]


func _refresh() -> void:
	if not is_open:
		return
	_chip.set_value(GameState.embers)
	for r in rows:
		var item := Items.get_item(r.item)
		var owned := GameState.item_count(r.item)
		var price := _price(r.item)
		(r.button as Button).text = "%s%s" % [item.display_name, "  x%d" % owned if owned > 0 else ""]
		var ok := selling or GameState.embers >= price
		var pl := r.price as Label
		pl.text = str(price)
		pl.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if ok else Palette.CRIMSON_BRIGHT)
		(r.button as Button).modulate = Color.WHITE if ok else Color(1, 1, 1, 0.6)
	_update_after()


func _on_trade(item_id: StringName) -> void:
	var res: Dictionary = Shops.sell(item_id) if selling else Shops.buy(shop_id, item_id)
	_msg.text = res.msg
	Audio.sfx(&"coin" if res.ok else &"fizzle", -4.0)
	_chip.pulse(Palette.EMBER if res.ok and selling else (Palette.CRIMSON_BRIGHT))
	if selling and res.ok and GameState.item_count(item_id) <= 0:
		_rebuild()   # that stack is gone from the list
	else:
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
	if not is_open:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"parry") or event.is_action_pressed(&"heal"):
		show_tab(not selling)
		get_viewport().set_input_as_handled()
