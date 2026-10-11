extends CanvasLayer
## Title screen, save-slot picker and settings page.
##
## The menu never starts a game itself: it emits Events.new_game_requested /
## load_game_requested and Main (which owns scene changes and the fade) reacts.
## Destructive actions (overwrite, delete) need a second press within 3 seconds.
## Everything is operable with keyboard or gamepad (ui_* actions) and the mouse.

enum Screen { TITLE, SLOTS, SETTINGS }
enum SlotMode { NEW, LOAD }

const CONFIRM_MS := 3000

var screen := Screen.TITLE
var slot_mode := SlotMode.NEW

var _screens := {}
var _summaries := {}            ## slot -> SaveSystem.load_slot() result
var _btn_continue: Button
var _btn_new: Button
var _btn_load: Button
var _btn_settings: Button
var _btn_quit: Button
var _continue_info: Label
var _slots_title: Label
var _rows: Array[Dictionary] = []
var _slots_back: Button
var _settings: SettingsPanel
var _status: Label
var _armed := ""
var _armed_btn: Button
var _armed_text := ""
var _armed_until := 0


func _ready() -> void:
	layer = 5
	_build_backdrop()

	var root := Control.new()
	root.name = &"Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	add_child(root)

	_screens[Screen.TITLE] = _build_title(root)
	_screens[Screen.SLOTS] = _build_slots(root)
	_screens[Screen.SETTINGS] = _build_settings(root)

	_status = Label.new()
	_status.name = &"Status"
	_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -34
	_status.offset_bottom = -22
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override(&"font_color", Palette.CRIMSON_BRIGHT)
	root.add_child(_status)

	var hint := Label.new()
	hint.text = "Arrows / D-pad: move     Enter / A: select     Esc / B: back"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -16
	hint.offset_bottom = -4
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	root.add_child(hint)

	var ver := Label.new()
	ver.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0"))
	ver.position = Vector2(6, 4)
	ver.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	root.add_child(ver)

	Events.save_failed.connect(_on_save_failed)
	open()


func _process(_delta: float) -> void:
	if _armed != "" and Time.get_ticks_msec() > _armed_until:
		_disarm()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") and screen != Screen.TITLE:
		_show_screen(Screen.TITLE)
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ public API

func open() -> void:
	visible = true
	_status.text = ""
	_disarm()
	_show_screen(Screen.TITLE)


func close() -> void:
	visible = false
	_disarm()


func show_message(text: String) -> void:
	_status.text = text


# ------------------------------------------------------------------ building

func _build_backdrop() -> void:
	var sky := Node2D.new()
	sky.set_script(load("res://world/background/sky.gd"))
	add_child(sky)
	_ruins(196.0, 120.0, Color("17141c"), Color(0.549, 0.239, 0.133, 0.55), 7, 60.0)
	_ruins(232.0, 90.0, Color("1d1922"), Color(0, 0, 0, 0), 11, 90.0)
	_ruins(262.0, 60.0, Color("241f29"), Color(0, 0, 0, 0), 5, 130.0)
	var ash := CPUParticles2D.new()
	ash.position = Vector2(240, -6)
	ash.amount = 60
	ash.lifetime = 14.0
	ash.preprocess = 14.0
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(260, 4)
	ash.direction = Vector2(0.3, 1)
	ash.spread = 25.0
	ash.gravity = Vector2(6, 10)
	ash.initial_velocity_min = 4.0
	ash.initial_velocity_max = 12.0
	ash.color = Color(Palette.DUST, 0.55)
	add_child(ash)


func _ruins(base_y: float, height: float, color: Color, window: Color, seed_value: int, spacing: float) -> void:
	var r := RuinsSilhouette.new()
	r.width = 700.0
	r.base_y = base_y
	r.max_height = height
	r.color = color
	r.window_color = window
	r.seed_value = seed_value
	r.spacing = spacing
	r.position.x = -110.0
	add_child(r)


func _centered(parent: Control, separation := 4) -> VBoxContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", separation)
	c.add_child(v)
	return v


func _menu_button(parent: Control, text: String, cb: Callable, width := 130.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 16)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_title(root: Control) -> Control:
	var v := _centered(root, 3)
	v.get_parent().name = &"TitleScreen"
	v.get_parent().offset_top = -6

	var emblem := Control.new()
	emblem.custom_minimum_size = Vector2(40, 30)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	emblem.draw.connect(func():
		var c := Vector2(20, 16)
		emblem.draw_arc(c, 11.0, 0.6, TAU - 0.9, 24, Palette.GOLD, 2.0)
		emblem.draw_line(c + Vector2(0, -12), c + Vector2(0, 11), Palette.BONE, 2.0)
		emblem.draw_line(c + Vector2(-5, 4), c + Vector2(5, 4), Palette.GOLD_BRIGHT, 1.5)
		emblem.draw_line(c + Vector2(-9, -3), c + Vector2(9, -3), Palette.CRIMSON, 1.5))
	v.add_child(emblem)

	var title := Label.new()
	title.text = "THE HOLLOW OATH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 24)
	title.add_theme_color_override(&"font_color", Palette.BONE)
	title.add_theme_constant_override(&"outline_size", 4)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "a kingdom that swore, and was emptied"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	v.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	v.add_child(gap)

	_btn_continue = _menu_button(v, "Continue", _on_continue)
	_btn_continue.name = &"Continue"
	_btn_new = _menu_button(v, "New Game", func(): _open_slots(SlotMode.NEW))
	_btn_new.name = &"NewGame"
	_btn_load = _menu_button(v, "Load Game", func(): _open_slots(SlotMode.LOAD))
	_btn_load.name = &"LoadGame"
	_btn_settings = _menu_button(v, "Settings", func(): _show_screen(Screen.SETTINGS))
	_btn_settings.name = &"Settings"
	_btn_quit = _menu_button(v, "Quit", func(): get_tree().quit())
	_btn_quit.name = &"Quit"

	_continue_info = Label.new()
	_continue_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_info.add_theme_color_override(&"font_color", Palette.STONE_LIGHT)
	_continue_info.custom_minimum_size.y = 10
	v.add_child(_continue_info)
	return v.get_parent()


func _build_slots(root: Control) -> Control:
	var v := _centered(root, 4)
	v.get_parent().name = &"SlotsScreen"
	_slots_title = Label.new()
	_slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_title.add_theme_font_size_override(&"font_size", 12)
	v.add_child(_slots_title)

	for i in SaveSystem.SLOT_COUNT:
		var slot := i + 1
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(380, 34)
		v.add_child(panel)
		var h := HBoxContainer.new()
		h.add_theme_constant_override(&"separation", 6)
		panel.add_child(h)
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(info)
		var act := Button.new()
		act.name = &"Action"
		act.custom_minimum_size = Vector2(66, 20)
		act.pressed.connect(_on_slot_action.bind(slot))
		h.add_child(act)
		var del := Button.new()
		del.name = &"Delete"
		del.text = "Delete"
		del.custom_minimum_size = Vector2(46, 20)
		del.pressed.connect(_on_slot_delete.bind(slot))
		h.add_child(del)
		panel.name = "Slot%d" % slot
		_rows.append({"panel": panel, "info": info, "act": act, "del": del})

	_slots_back = _menu_button(v, "Back", func(): _show_screen(Screen.TITLE), 80.0)
	_slots_back.name = &"Back"
	_slots_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return v.get_parent()


func _build_settings(root: Control) -> Control:
	var c := CenterContainer.new()
	c.name = &"SettingsScreen"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	_settings = SettingsPanel.new()
	_settings.back_requested.connect(func(): _show_screen(Screen.TITLE))
	c.add_child(_settings)
	return c


# ------------------------------------------------------------------ screens

func _show_screen(s: Screen) -> void:
	screen = s
	_disarm()
	for key in _screens:
		(_screens[key] as Control).visible = (key == s)
	match s:
		Screen.TITLE:
			_refresh_title()
		Screen.SLOTS:
			_refresh_slots()
		Screen.SETTINGS:
			_settings.focus_first()


func _refresh_summaries() -> void:
	for s in range(1, SaveSystem.SLOT_COUNT + 1):
		_summaries[s] = SaveSystem.load_slot(s)


func _recent_slot() -> int:
	var best := 0
	var best_time := -1
	for s in _summaries:
		var r: Dictionary = _summaries[s]
		if r.status == SaveSystem.Status.OK and int(r.data.saved_at) > best_time:
			best = s
			best_time = int(r.data.saved_at)
	return best


func _refresh_title() -> void:
	_refresh_summaries()
	var recent := _recent_slot()
	var any_file := false
	for s in _summaries:
		if _summaries[s].status != SaveSystem.Status.EMPTY:
			any_file = true
	_btn_continue.disabled = recent == 0
	_btn_load.disabled = not any_file
	if recent > 0:
		var d: Dictionary = _summaries[recent].data
		_continue_info.text = "Slot %d  -  %s  -  %s" % [recent, _place(d), _clock(d.play_time)]
	else:
		_continue_info.text = ""
	for b in [_btn_continue, _btn_new, _btn_load, _btn_settings, _btn_quit]:
		if not b.disabled:
			b.grab_focus()
			break


func _open_slots(mode: SlotMode) -> void:
	slot_mode = mode
	_slots_title.text = "NEW GAME  -  choose a slot" if mode == SlotMode.NEW else "LOAD GAME"
	_show_screen(Screen.SLOTS)


func _refresh_slots() -> void:
	_refresh_summaries()
	for i in _rows.size():
		var slot := i + 1
		var row := _rows[i]
		var r: Dictionary = _summaries[slot]
		var info: Label = row.info
		var act: Button = row.act
		var del: Button = row.del
		match r.status:
			SaveSystem.Status.EMPTY:
				info.text = "Slot %d\nEmpty" % slot
			SaveSystem.Status.OK:
				var d: Dictionary = r.data
				info.text = "Slot %d  -  %s\n%s played  -  %d death%s  -  %s%s" % [
					slot, _place(d), _clock(d.play_time), d.deaths, "" if d.deaths == 1 else "s",
					_date(d.saved_at), "  (restored from backup)" if r.recovered else ""]
			SaveSystem.Status.CORRUPT:
				info.text = "Slot %d\nThis save is damaged and cannot be read" % slot
			SaveSystem.Status.TOO_NEW:
				info.text = "Slot %d\nSaved by a newer version of the game" % slot
		if slot_mode == SlotMode.NEW:
			act.text = "Begin" if r.status == SaveSystem.Status.EMPTY else "Overwrite"
			act.disabled = false
		else:
			act.text = "Load"
			act.disabled = r.status != SaveSystem.Status.OK
		del.visible = r.status != SaveSystem.Status.EMPTY
		del.text = "Delete"
	for row in _rows:
		if not row.act.disabled:
			row.act.grab_focus()
			return
	_slots_back.grab_focus()


# ------------------------------------------------------------------ actions

func _on_continue() -> void:
	var slot := _recent_slot()
	if slot > 0:
		Events.load_game_requested.emit(slot)


func _on_slot_action(slot: int) -> void:
	var r: Dictionary = _summaries[slot]
	if slot_mode == SlotMode.NEW:
		if r.status != SaveSystem.Status.EMPTY and not _arm("act%d" % slot, _rows[slot - 1].act):
			return
		Events.new_game_requested.emit(slot)
	else:
		Events.load_game_requested.emit(slot)


func _on_slot_delete(slot: int) -> void:
	if not _arm("del%d" % slot, _rows[slot - 1].del):
		return
	SaveSystem.delete_slot(slot)
	_refresh_slots()
	_status.text = "Slot %d deleted." % slot
	var any_file := false
	for s in _summaries:
		if _summaries[s].status != SaveSystem.Status.EMPTY:
			any_file = true
	if slot_mode == SlotMode.LOAD and not any_file:
		_show_screen(Screen.TITLE)


## Two-step confirmation: returns true only on the second press within CONFIRM_MS.
func _arm(key: String, button: Button) -> bool:
	if _armed == key and Time.get_ticks_msec() <= _armed_until:
		_disarm()
		return true
	_disarm()
	_armed = key
	_armed_btn = button
	_armed_text = button.text
	button.text = "Sure?"
	_armed_until = Time.get_ticks_msec() + CONFIRM_MS
	return false


func _disarm() -> void:
	if _armed_btn and is_instance_valid(_armed_btn):
		_armed_btn.text = _armed_text
	_armed = ""
	_armed_btn = null
	_armed_text = ""


func _on_save_failed(_slot: int, _reason: String) -> void:
	_status.text = "Could not write the save file. Check free disk space and folder permissions."


# ------------------------------------------------------------------ formatting

func _place(d: Dictionary) -> String:
	return d.level_name if d.level_name != "" else "Unknown place"


func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func _date(unix: int) -> String:
	if unix <= 0:
		return "unknown date"
	var local := unix + int(Time.get_time_zone_from_system().bias) * 60
	var dt := Time.get_datetime_dict_from_unix_time(local)
	return "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
