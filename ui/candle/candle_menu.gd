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
	var title := Label.new()
	title.text = "THE OATH BURNS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 14)
	v.add_child(title)
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	v.add_child(_info)
	for stat in GameState.STAT_NAMES:
		var b := Button.new()
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
	_inv_btn = Button.new()
	_inv_btn.text = "Pack"
	_inv_btn.custom_minimum_size = Vector2(210, 17)
	_inv_btn.pressed.connect(func(): Events.inventory_menu_requested.emit())
	UITheme.compact(_inv_btn)
	v.add_child(_inv_btn)
	_leave_btn = Button.new()
	_leave_btn.text = "Leave"
	_leave_btn.custom_minimum_size = Vector2(210, 17)
	_leave_btn.pressed.connect(close)
	UITheme.compact(_leave_btn)
	v.add_child(_leave_btn)


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
