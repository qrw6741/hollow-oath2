class_name SettingsPanel
extends VBoxContainer
## Settings, shared by the main menu and the pause menu, in three tabs:
##   Display  — window, resolution, graphics, frame rate, vsync
##   Game     — difficulty and accessibility, feedback effects, controller, volumes
##   Controls — rebind every action on keyboard and controller (ControlsPanel)
## Switch tabs with the tab buttons or Parry / Heal (L1 / R1). Values apply immediately and
## are written to disk when the panel is left.

signal back_requested

var _shake: Button
var _flashes: Button
var _hitstop: Button
var _display: Button
var _res: Button
var _render: Button
var _onehit: Button
var _glow: Button
var _classic: Button
var _dmgnum: Button
var _fps: Button
var _vsync: Button
var _icons: Button
var _vibe: Button
var _volume_label: Label
var _music_label: Label
var _sfx_label: Label
var _back: Button
var _dmg: Button
var _ehp: Button
var _assist: Button
var _cb: Button
var _tips: Button
var _tab_btns: Array[Button] = []
var _pages: Array[VBoxContainer] = []
var _controls: ControlsPanel
var page := 0


func _ready() -> void:
	add_theme_constant_override(&"separation", 2)
	alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.title(title, 13)
	add_child(title)
	add_child(UITheme.rule(180))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override(&"separation", 10)
	add_child(tabs)
	for i in 4:
		var t := FancyButton.new()
		t.text = ["Display", "Game", "Controls", "Dev"][i]
		t.custom_minimum_size = Vector2(64, 14)
		t.focus_mode = Control.FOCUS_NONE
		t.add_theme_font_override(&"font", UITheme.title_font())
		UITheme.compact(t)
		t.pressed.connect(show_page.bind(i))
		tabs.add_child(t)
		_tab_btns.append(t)
	for i in 4:
		var pg := VBoxContainer.new()
		pg.add_theme_constant_override(&"separation", 2)
		add_child(pg)
		_pages.append(pg)
	var p0 := _pages[0]
	_display = _button(func(): Settings.fullscreen = not Settings.fullscreen; _video_changed(), p0)
	_res = _button(func(): Settings.resolution_index = (Settings.resolution_index + 1) % Settings.RESOLUTIONS.size(); _video_changed(), p0)
	_render = _button(func(): Settings.hires = not Settings.hires; _video_changed(), p0)
	_classic = _button(func(): Settings.classic_gfx = not Settings.classic_gfx; _video_changed(), p0)
	_glow = _button(func(): Settings.glow = not Settings.glow; _video_changed(), p0)
	_fps = _button(func(): Settings.fps_cap = Settings.FPS_CAPS[(Settings.FPS_CAPS.find(Settings.fps_cap) + 1) % Settings.FPS_CAPS.size()]; _video_changed(), p0)
	_vsync = _button(func(): Settings.vsync = not Settings.vsync; _video_changed(), p0)
	var p1 := _pages[1]
	_dmgnum = _button(func(): Settings.damage_numbers = not Settings.damage_numbers; _refresh(), p1)
	_dmg = _button(func(): Settings.damage_taken_pct = _cycle(Settings.DAMAGE_STEPS, Settings.damage_taken_pct); _refresh(), p1)
	_ehp = _button(func(): Settings.enemy_health_pct = _cycle(Settings.ENEMY_HP_STEPS, Settings.enemy_health_pct); _refresh(), p1)
	_assist = _button(func(): Settings.parry_assist = not Settings.parry_assist; _refresh(), p1)
	_cb = _button(func(): Settings.colorblind = not Settings.colorblind; _refresh(), p1)
	_tips = _button(func(): Settings.tutorial_hints = not Settings.tutorial_hints; _refresh(), p1)
	_shake = _button(_toggle_shake, p1)
	_flashes = _button(_toggle_flashes, p1)
	_hitstop = _button(_toggle_hitstop, p1)
	_icons = _button(func(): Settings.pad_style = (Settings.pad_style + 1) % 3; InputPrompts.refresh(); _refresh(), p1)
	_vibe = _button(func(): Settings.vibration = not Settings.vibration; _refresh(), p1)
	# Volumes: master / music / effects on one row.
	var vol := HBoxContainer.new()
	vol.alignment = BoxContainer.ALIGNMENT_CENTER
	vol.add_theme_constant_override(&"separation", 3)
	p1.add_child(vol)
	_volume_label = _volume_group(vol, "Volume", "master_volume", &"VolumeDown", &"VolumeUp")
	_music_label = _volume_group(vol, "Music", "music_volume", &"MusicDown", &"MusicUp")
	_sfx_label = _volume_group(vol, "Effects", "sfx_volume", &"SfxDown", &"SfxUp")
	_controls = ControlsPanel.new()
	_pages[2].add_child(_controls)

	# Dev hub: testing tools. Off by default, saved with the other settings.
	var note := Label.new()
	note.text = "DEV HUB  -  testing tools, not part of the normal game"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override(&"font_size", 7)
	note.add_theme_color_override(&"font_color", Palette.DUST)
	_pages[3].add_child(note)
	_onehit = _button(func(): Settings.dev_one_hit = not Settings.dev_one_hit; _refresh(), _pages[3])

	_back = _button(_on_back)
	_back.text = "Back"
	_refresh()
	show_page(0, false)


func _cycle(steps: Array, cur: int) -> int:
	var i := steps.find(cur)
	return steps[(i + 1) % steps.size()]


func show_page(i: int, focus := true) -> void:
	page = i
	for k in _pages.size():
		_pages[k].visible = k == i
		_tab_btns[k].add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT if k == i else Palette.DUST)
	if focus:
		focus_first()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or (_controls and _controls.listening):
		return
	if event.is_action_pressed(&"parry") or event.is_action_pressed(&"heal"):
		var step := -1 if event.is_action_pressed(&"parry") else 1
		show_page(wrapi(page + step, 0, _pages.size()))
		get_viewport().set_input_as_handled()


func _button(cb: Callable, parent: Control = null) -> Button:
	var b := FancyButton.new()
	b.custom_minimum_size = Vector2(190, 13)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	UITheme.compact(b)
	(parent if parent else self).add_child(b)
	return b


func focus_first() -> void:
	match page:
		0: _display.grab_focus()
		1: _dmg.grab_focus()
		2: _controls.focus_first()
		3: _onehit.grab_focus()


func _video_changed() -> void:
	Settings.apply_video()
	_refresh()


func _refresh() -> void:
	_onehit.text = "One-hit kills (every hit kills): %s" % ("On" if Settings.dev_one_hit else "Off")
	_dmg.text = "Damage you take: %d%%" % Settings.damage_taken_pct
	_ehp.text = "Enemy health: %d%%" % Settings.enemy_health_pct
	_assist.text = "Parry assist (wider window): %s" % ("On" if Settings.parry_assist else "Off")
	_cb.text = "Colourblind status colours: %s" % ("On" if Settings.colorblind else "Off")
	_tips.text = "Tutorial tips: %s" % ("On" if Settings.tutorial_hints else "Off")
	_icons.text = "Controller icons: %s" % ["Auto", "PlayStation", "Xbox"][Settings.pad_style]
	_vibe.text = "Controller vibration: %s" % ("On" if Settings.vibration else "Off")
	_display.text = "Display: %s" % ("Fullscreen" if Settings.fullscreen else "Windowed")
	var r := Settings.RESOLUTIONS[Settings.resolution_index]
	_res.text = "Window size: %dx%d" % [r.x, r.y]
	_res.disabled = Settings.fullscreen
	_render.text = "Graphics: %s" % ("High-res (smooth)" if Settings.hires else "Pixel (480x270)")
	_classic.text = "Visuals: %s" % ("Classic (light)" if Settings.classic_gfx else "Enhanced")
	_glow.text = "Glow & colour grading: %s" % ("On" if Settings.glow else "Off")
	_fps.text = "Frame rate limit: %s" % ("Unlimited" if Settings.fps_cap == 0 else str(Settings.fps_cap))
	_vsync.text = "VSync: %s" % ("On" if Settings.vsync else "Off")
	_shake.text = "Screen shake: %s" % ("On" if Settings.screen_shake > 0.0 else "Off")
	_flashes.text = "Hit flashes: %s" % ("On" if Settings.flashes else "Off")
	_dmgnum.text = "Damage numbers: %s" % ("On" if Settings.damage_numbers else "Off")
	_hitstop.text = "Hit-stop: %s" % ("On" if Settings.hit_stop else "Off")
	_volume_label.text = "%d%%" % roundi(Settings.master_volume * 100.0)
	_music_label.text = "%d%%" % roundi(Settings.music_volume * 100.0)
	_sfx_label.text = "%d%%" % roundi(Settings.sfx_volume * 100.0)


func _toggle_shake() -> void:
	Settings.screen_shake = 0.0 if Settings.screen_shake > 0.0 else 1.0
	_refresh()


func _toggle_flashes() -> void:
	Settings.flashes = not Settings.flashes
	_refresh()


func _toggle_hitstop() -> void:
	Settings.hit_stop = not Settings.hit_stop
	_refresh()


func _volume_group(row: HBoxContainer, text: String, prop: String, down_name: StringName, up_name: StringName) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	row.add_child(lab)
	var minus := Button.new()
	minus.name = down_name
	minus.text = "-"
	minus.custom_minimum_size.x = 16
	UITheme.compact(minus)
	minus.pressed.connect(_change_volume.bind(prop, -0.1))
	row.add_child(minus)
	var val := Label.new()
	val.custom_minimum_size.x = 28
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(val)
	var plus := Button.new()
	plus.name = up_name
	plus.text = "+"
	plus.custom_minimum_size.x = 16
	UITheme.compact(plus)
	plus.pressed.connect(_change_volume.bind(prop, 0.1))
	row.add_child(plus)
	var gap := Control.new()
	gap.custom_minimum_size.x = 6
	row.add_child(gap)
	return val


func _change_volume(prop: String, step: float) -> void:
	Settings.set(prop, clampf(snappedf(float(Settings.get(prop)) + step, 0.1), 0.0, 1.0))
	Settings.apply_audio()
	Audio.sfx(&"ui_move")
	_refresh()


func _on_back() -> void:
	Settings.save_settings()
	back_requested.emit()
