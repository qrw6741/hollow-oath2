class_name CandleMenu
extends CanvasLayer
## Opens after resting at an Oath Candle: spend embers to raise Vigor / Endurance /
## Strength (each point costs more), open the pack, or leave. Pauses the game while open.

var is_open := false
var _panel: ColorRect
var _info: Label
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
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	v.add_child(_info)
	for stat in GameState.STAT_NAMES:
		var b := FancyButton.new()
		b.custom_minimum_size = Vector2(210, 17)
		b.pressed.connect(_on_buy.bind(stat))
		UITheme.compact(b)
		v.add_child(b)
		_rows[stat] = b
	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_msg.custom_minimum_size.y = 10
	v.add_child(_msg)
	_inv_btn = FancyButton.new()
	_inv_btn.text = "Pack"
	_inv_btn.custom_minimum_size = Vector2(210, 17)
	_inv_btn.pressed.connect(func(): Events.inventory_menu_requested.emit())
	UITheme.compact(_inv_btn)
	v.add_child(_inv_btn)
	_travel_btn = FancyButton.new()
	_travel_btn.text = "Travel"
	_travel_btn.custom_minimum_size = Vector2(210, 17)
	_travel_btn.pressed.connect(_show_travel)
	UITheme.compact(_travel_btn)
	v.add_child(_travel_btn)
	_leave_btn = FancyButton.new()
	_leave_btn.text = "Leave"
	_leave_btn.custom_minimum_size = Vector2(210, 17)
	_leave_btn.pressed.connect(close)
	UITheme.compact(_leave_btn)
	v.add_child(_leave_btn)


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
	_travel_list = VBoxContainer.new()
	_travel_list.add_theme_constant_override(&"separation", 1)
	_travel_v.add_child(_travel_list)
	var back := FancyButton.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(230, 15)
	back.pressed.connect(_hide_travel)
	UITheme.compact(back)
	_travel_v.add_child(back)


## Every lit candle in the game, as {level_path, area, id, name, pos}.
static func travel_destinations() -> Array:
	var out := []
	for d in WorldMap.all():
		for cd in d.candles:
			if GameState.get_flag(StringName("candle_lit_" + String(cd.id)), false):
				out.append({"level": d.path, "area": d.name, "id": cd.id, "name": cd.name, "pos": cd.pos})
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
	_panel.visible = true
	_refresh()
	_focus_best()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = false
	GameState.ui_modal = false


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


func _refresh() -> void:
	var cost := GameState.level_cost()
	_info.text = "Level %d      Embers %d      Next level: %d" % [GameState.level(), GameState.embers, cost]
	for stat in GameState.STAT_NAMES:
		var b: Button = _rows[stat]
		b.text = "%s  %d  ->  %d     %s" % [LABELS[stat][0], GameState.stats[stat], GameState.stats[stat] + 1, LABELS[stat][1]]
		b.disabled = GameState.embers < cost
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
		_refresh()
		_focus_best()
	else:
		_msg.text = "Not enough embers."
