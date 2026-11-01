class_name CandleMenu
extends CanvasLayer
## Opens after resting at an Oath Candle: spend embers to raise Vigor / Endurance /
## Strength (each point costs more), open the pack, or leave. Pauses the game while open.

var is_open := false
var _panel: ColorRect
var _goal: Label
var _info: Label
var _chip: EmberChip
var _msg: Label
var _rows := {}
var _inv_btn: Button
var _leave_btn: Button
var _travel_btn: Button
var _main_v: VBoxContainer
var _travel_v: VBoxContainer
var _travel_list: VBoxContainer
var travel_open := false
var _session := 0

const LABELS := {
	"vigor": ["Vigor", "+8 max health"],
	"endurance": ["Endurance", "+6 max stamina"],
	"strength": ["Strength", "+4% damage"],
}


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_build_travel()
	_panel.visible = false
	Events.checkpoint_rested.connect(_on_rested)
	Events.inventory_menu_closed.connect(func(): if is_open: _leave_btn_focus())


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(Palette.INK, 0.9)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	add_child(_panel)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 3)
	c.add_child(v)
	_main_v = v
	v.draw.connect(func(): UITheme.draw_panel(v, Rect2(Vector2(-22, -14), v.size + Vector2(44, 28))))
	v.resized.connect(v.queue_redraw)
	var title := Label.new()
	title.text = "THE OATH BURNS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(title, 16)
	v.add_child(title)
	v.add_child(UITheme.rule(220))
	_goal = Label.new()
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal.add_theme_color_override(&"font_color", Palette.GOLD)
	v.add_child(_goal)
	var head := HBoxContainer.new()
	head.custom_minimum_size.x = 330
	v.add_child(head)
	_info = Label.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_color_override(&"font_color", Palette.BONE)
	head.add_child(_info)
	_chip = EmberChip.new()
	head.add_child(_chip)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 9)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(cards)
	for stat in GameState.STAT_NAMES:
		var b := StatCard.new()
		b.stat = stat
		b.title = LABELS[stat][0]
		b.blurb = LABELS[stat][1]
		b.pressed.connect(_on_buy.bind(stat))
		cards.add_child(b)
		_rows[stat] = b
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_msg.custom_minimum_size.y = 10
	v.add_child(_msg)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override(&"separation", 6)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(foot)
	_inv_btn = FancyButton.new()
	_inv_btn.text = "Pack"
	_inv_btn.custom_minimum_size = Vector2(104, 17)
	_inv_btn.pressed.connect(func(): Events.inventory_menu_requested.emit())
	UITheme.compact(_inv_btn)
	foot.add_child(_inv_btn)
	_travel_btn = FancyButton.new()
	_travel_btn.text = "Travel"
	_travel_btn.custom_minimum_size = Vector2(104, 17)
	_travel_btn.pressed.connect(_show_travel)
	UITheme.compact(_travel_btn)
	foot.add_child(_travel_btn)
	_leave_btn = FancyButton.new()
	_leave_btn.text = "Leave"
	_leave_btn.custom_minimum_size = Vector2(104, 17)
	_leave_btn.pressed.connect(close)
	UITheme.compact(_leave_btn)
	foot.add_child(_leave_btn)


func _build_travel() -> void:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	_travel_v = VBoxContainer.new()
	_travel_v.add_theme_constant_override(&"separation", 3)
	_travel_v.visible = false
	c.add_child(_travel_v)
	_travel_v.draw.connect(func(): UITheme.draw_panel(_travel_v, Rect2(Vector2(-22, -14), _travel_v.size + Vector2(44, 28))))
	_travel_v.resized.connect(_travel_v.queue_redraw)
	var title := Label.new()
	title.text = "TRAVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(title, 16)
	_travel_v.add_child(title)
	_travel_v.add_child(UITheme.rule(220))
	var hint := Label.new()
	hint.text = "Journey to any candle you have rested at."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_travel_v.add_child(hint)
	# The list can grow long (dozens of candles), so it lives in a scroll area: mouse wheel,
	# drag, or simply moving the focus with the keys / stick scrolls it.
	var sc := ScrollContainer.new()
	sc.name = &"TravelScroll"
	sc.custom_minimum_size = Vector2(250, 150)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	_travel_v.add_child(sc)
	_travel_list = VBoxContainer.new()
	_travel_list.add_theme_constant_override(&"separation", 1)
	_travel_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_travel_list)
	var back := FancyButton.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(230, 15)
	back.pressed.connect(_hide_travel)
	UITheme.compact(back)
	_travel_v.add_child(back)


## Every lit candle in the game, as {level_path, area, id, name, pos}.
## Lit candles, newest first: the map discovered most recently comes first, and inside each map its
## newest candle comes first. Candles lit before the order was recorded (older saves) count as older than
## every recorded one and are ordered by their place in the world (later maps = newer).
static func travel_destinations() -> Array:
	var maps := []
	var wi := 0
	for d in WorldMap.all():
		var cands := []
		for cd in d.candles:
			wi += 1
			if GameState.get_flag(StringName("candle_lit_" + String(cd.id)), false):
				var stamp := int(GameState.get_flag(StringName("candle_order_" + String(cd.id)), 0))
				var key := stamp if stamp > 0 else wi - 1000000   # unrecorded = older than any recorded
				cands.append({"level": d.path, "area": d.name, "id": cd.id, "name": cd.name, "pos": cd.pos, "key": key})
		if cands.is_empty():
			continue
		var first_lit: int = cands.map(func(c): return c.key).min()
		cands.sort_custom(func(x, y): return x.key > y.key)
		maps.append({"first": first_lit, "cands": cands})
	maps.sort_custom(func(x, y): return x.first > y.first)
	var out := []
	for m in maps:
		out.append_array(m.cands)
	return out


func _show_travel() -> void:
	travel_open = true
	for ch in _travel_list.get_children():
		_travel_list.remove_child(ch)
		ch.queue_free()
	var first: Button
	var last_area := ""
	for dest in travel_destinations():
		if dest.area != last_area:
			last_area = dest.area
			var al := Label.new()
			UITheme.title(al, 8, Palette.STONE_LIGHT)
			al.text = String(dest.area).to_upper()
			_travel_list.add_child(al)
		var b := FancyButton.new()
		var here: bool = String(dest.id) == String(GameState.checkpoint_id) and dest.level == GameState.checkpoint_level_path()
		b.text = dest.name + ("   (here)" if here else "")
		b.disabled = here
		b.custom_minimum_size = Vector2(230, 15)
		UITheme.compact(b)
		b.pressed.connect(travel_to.bind(dest))
		_travel_list.add_child(b)
		if first == null and not here:
			first = b
	_main_v.visible = false
	_travel_v.visible = true
	if first:
		first.grab_focus()
	else:
		(_travel_v.get_child(_travel_v.get_child_count() - 1) as Button).grab_focus()


func _hide_travel() -> void:
	travel_open = false
	_travel_v.visible = false
	_main_v.visible = true
	_focus_best()


## Moves the player to another lit candle (any level). That candle becomes the
## respawn point, as if rested at.
func travel_to(dest: Dictionary) -> void:
	_hide_travel()
	close()
	GameState.has_checkpoint = true
	GameState.checkpoint_id = StringName(dest.id)
	GameState.respawn_position = (dest.pos as Vector2) + Vector2(22, 0)
	GameState.checkpoint_level = dest.level
	GameState.level_entry = &""
	Audio.sfx(&"rest", -2.0)
	Events.level_change_requested.emit(dest.level, &"", false)


func _on_rested(_id: StringName, _pos: Vector2) -> void:
	if not Settings.candle_menu_on_rest:
		return
	var sid := GameState.session_id
	await get_tree().create_timer(0.9).timeout
	if sid != GameState.session_id or not GameState.in_game or GameState.ui_modal:
		return
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null or p.is_dead():
		return
	open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_session = GameState.session_id
	get_tree().paused = true
	GameFeel.reset()
	GameState.ui_modal = true
	_msg.text = ""
	_goal.text = Progress.text()
	_panel.visible = true
	_refresh()
	_chip.set_value(GameState.embers, true)
	_focus_best()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false


## The Travel list is long (one row per lit candle), so besides the ScrollContainer's own handling the
## wheel, PageUp/PageDown and the right stick scroll it from anywhere on the menu, whatever has focus.
func _input(event: InputEvent) -> void:
	if not (is_open and travel_open) or _travel_list == null:
		return
	var sc := _travel_list.get_parent() as ScrollContainer
	if sc == null:
		return
	var step := 0
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = -1
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_PAGEDOWN:
			step = 5
		elif event.keycode == KEY_PAGEUP:
			step = -5
		elif event.keycode == KEY_END:
			step = 1000
		elif event.keycode == KEY_HOME:
			step = -1000
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_RIGHT_Y and absf(event.axis_value) > 0.6:
		step = 1 if event.axis_value > 0.0 else -1
	if step == 0:
		return
	sc.scroll_vertical = clampi(sc.scroll_vertical + step * 32, 0, int(sc.get_v_scroll_bar().max_value))
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and not _inv_open() and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		if travel_open:
			_hide_travel()
		else:
			close()
		get_viewport().set_input_as_handled()


func _inv_open() -> bool:
	var inv := get_parent().get_node_or_null(^"InventoryMenu") as InventoryMenu
	return inv != null and inv.is_open


func _leave_btn_focus() -> void:
	_refresh()
	_focus_best()


func _focus_best() -> void:
	for stat in GameState.STAT_NAMES:
		if not _rows[stat].disabled:
			_rows[stat].grab_focus()
			return
	_inv_btn.grab_focus()


func _stat_numbers(stat: String) -> Array:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	match stat:
		"vigor":
			var now := roundi(p.health.max_health) if p else 100
			return ["Health %d" % now, "%d" % (now + 8)]
		"endurance":
			var now2 := roundi(p.stamina.max_stamina) if p else 100
			return ["Stamina %d" % now2, "%d" % (now2 + 6)]
		_:
			var pct := roundi(int(GameState.stats[stat]) * GameState.STRENGTH_DAMAGE * 100.0)
			return ["Damage +%d%%" % pct, "+%d%%" % (pct + 4)]


func _refresh() -> void:
	var cost := GameState.level_cost()
	_info.text = "LEVEL %d     next level costs %d" % [GameState.level(), cost]
	_chip.set_value(GameState.embers)
	for stat in GameState.STAT_NAMES:
		var b := _rows[stat] as StatCard
		var nums := _stat_numbers(stat)
		b.value = int(GameState.stats[stat])
		b.cost = cost
		b.affordable = GameState.embers >= cost
		b.line_now = nums[0]
		b.line_next = nums[1]
		b.disabled = not b.affordable
		b.queue_redraw()
	if GameState.embers < cost:
		_msg.text = "Not enough embers to grow stronger."
	else:
		_msg.text = ""


func _on_buy(stat: String) -> void:
	if GameState.buy_stat(stat):
		var p := get_tree().get_first_node_in_group(&"player") as Player
		if p:
			p.apply_stats(true)
		_msg.text = "%s raised." % LABELS[stat][0]
		_chip.pulse(Palette.EMBER)
		Audio.sfx(&"coin", -4.0)
		_refresh()
		_focus_best()
	else:
		_chip.pulse(Palette.CRIMSON_BRIGHT)
		_msg.text = "Not enough embers."
