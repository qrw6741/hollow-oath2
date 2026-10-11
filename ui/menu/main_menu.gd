extends CanvasLayer
## Title screen, save-slot picker and settings page.
##
## The menu never starts a game itself: it emits Events.new_game_requested /
## load_game_requested and Main (which owns scene changes and the fade) reacts.
## Destructive actions (overwrite, delete) need a second press within 3 seconds.
## Everything is operable with keyboard or gamepad (ui_* actions) and the mouse.

enum Screen { TITLE, SLOTS, PRESET, SETTINGS }
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
var _preset_btns: Array[Button] = []
var _preset_sel := 0
var _pending_slot := 0
var _pv_visual: Node2D
var _pv_name: Label
var _pv_tag: Label
var _pv_desc: Label
var _pv_stats: Label
var _pv_perks: Label
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
	_screens[Screen.PRESET] = _build_preset(root)
	_screens[Screen.SETTINGS] = _build_settings(root)

	_status = Label.new()
	_status.name = &"Status"
	_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -34
	_status.offset_bottom = -22
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override(&"font_color", Palette.CRIMSON_BRIGHT)
	root.add_child(_status)

	var hint := HintBar.new()
	hint.spec = "dpad|Arrows:move,ui_accept:select,ui_cancel:back"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -16
	hint.offset_bottom = -3
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
		if screen == Screen.PRESET:
			_open_slots(SlotMode.NEW)
		else:
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
	# Foreground: low mist, a stone ledge, and a distant candle glow.
	var fg := Control.new()
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fg.set_anchors_preset(Control.PRESET_FULL_RECT)
	fg.draw.connect(func():
		for i in 54:
			var t := float(i) / 53.0
			fg.draw_rect(Rect2(0, 196 + i, 480, 1), Color(0.42, 0.30, 0.38, 0.03 + 0.10 * t))
		fg.draw_rect(Rect2(0, 250, 480, 20), Palette.INK)
		fg.draw_rect(Rect2(0, 250, 480, 1), Color(Palette.STONE_LIGHT, 0.5))
		for k in 24:
			fg.draw_rect(Rect2(k * 21 + 4, 256 + (k % 3) * 4, 14, 1), Color(Palette.STONE, 0.45))
		for r in [34.0, 22.0, 12.0]:
			fg.draw_circle(Vector2(412, 247), r, Color(Palette.GOLD, 0.05))
		fg.draw_rect(Rect2(411, 240, 2, 8), Palette.BONE_DIM)
		fg.draw_rect(Rect2(411, 237, 2, 3), Palette.GOLD_BRIGHT))
	add_child(fg)
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
	title.add_theme_color_override(&"font_shadow_color", Color(Palette.CRIMSON, 0.55))
	title.add_theme_constant_override(&"shadow_offset_y", 2)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "a kingdom that swore, and was emptied"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	v.add_child(sub)

	var orn := Control.new()
	orn.custom_minimum_size = Vector2(200, 8)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	orn.draw.connect(func():
		var m := 100.0
		orn.draw_line(Vector2(m - 90, 4), Vector2(m - 8, 4), Color(Palette.GOLD, 0.7), 1.0)
		orn.draw_line(Vector2(m + 8, 4), Vector2(m + 90, 4), Color(Palette.GOLD, 0.7), 1.0)
		orn.draw_colored_polygon(PackedVector2Array([Vector2(m - 5, 4), Vector2(m, 0), Vector2(m + 5, 4), Vector2(m, 8)]), Palette.GOLD_BRIGHT))
	v.add_child(orn)

	var gap := Control.new()
	gap.custom_minimum_size.y = 6
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


func _build_preset(root: Control) -> Control:
	var c := CenterContainer.new()
	c.name = &"PresetScreen"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_bottom = -24
	root.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 4)
	c.add_child(v)
	var title := Label.new()
	title.text = "CHOOSE YOUR OATH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 12)
	v.add_child(title)
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	v.add_child(h)

	var left := VBoxContainer.new()
	left.add_theme_constant_override(&"separation", 3)
	h.add_child(left)
	for i in Presets.IDS.size():
		var pr := Presets.get_preset(Presets.IDS[i])
		var b := Button.new()
		b.name = "Preset_%s" % pr.id
		b.text = pr.display_name
		b.custom_minimum_size = Vector2(112, 22)
		b.focus_entered.connect(_select_preset.bind(i))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_on_preset_pressed.bind(i))
		left.add_child(b)
		_preset_btns.append(b)
	var back := _menu_button(left, "Back", func(): _open_slots(SlotMode.NEW), 112.0)
	back.name = &"PresetBack"

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(332, 198)
	h.add_child(panel)
	var pv := HBoxContainer.new()
	pv.add_theme_constant_override(&"separation", 6)
	panel.add_child(pv)
	var prev := Control.new()
	prev.custom_minimum_size = Vector2(76, 120)
	prev.clip_contents = true
	pv.add_child(prev)
	_pv_visual = Node2D.new()
	_pv_visual.set_script(load("res://actors/player/player_visual.gd"))
	_pv_visual.set("preview", true)
	_pv_visual.position = Vector2(38, 104)
	_pv_visual.scale = Vector2(3, 3)
	prev.add_child(_pv_visual)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 3)
	pv.add_child(info)
	_pv_name = Label.new()
	_pv_name.add_theme_font_size_override(&"font_size", 12)
	_pv_name.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	info.add_child(_pv_name)
	_pv_tag = Label.new()
	_pv_tag.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_pv_tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_pv_tag)
	_pv_desc = Label.new()
	_pv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pv_desc.add_theme_constant_override(&"line_spacing", -3)
	_pv_desc.custom_minimum_size.x = 226
	info.add_child(_pv_desc)
	_pv_stats = Label.new()
	_pv_stats.add_theme_color_override(&"font_color", Palette.BONE)
	info.add_child(_pv_stats)
	_pv_perks = Label.new()
	_pv_perks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pv_perks.add_theme_constant_override(&"line_spacing", -3)
	_pv_perks.custom_minimum_size.x = 226
	info.add_child(_pv_perks)
	return c


func _select_preset(i: int) -> void:
	_preset_sel = i
	var pr := Presets.get_preset(Presets.IDS[i])
	_pv_visual.set("preset", pr)
	_pv_name.text = pr.display_name
	_pv_tag.text = pr.tagline
	_pv_desc.text = pr.description
	_pv_stats.text = "HP %d   Stamina %d   Flasks %d" % [int(pr.max_health), int(pr.max_stamina), pr.flasks]
	var perks := ""
	for t in pr.perks:
		perks += "+ %s\n" % t
	for t in pr.drawbacks:
		perks += "- %s\n" % t
	_pv_perks.text = perks.strip_edges()


func _on_preset_pressed(i: int) -> void:
	_select_preset(i)
	if _pending_slot > 0:
		Events.new_game_requested.emit(_pending_slot, Presets.IDS[i])


func _open_presets(slot: int) -> void:
	_pending_slot = slot
	_show_screen(Screen.PRESET)


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
		Screen.PRESET:
			_preset_btns[0].grab_focus()
			_select_preset(0)
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
		_open_presets(slot)
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
