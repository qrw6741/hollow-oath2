extends CanvasLayer
## In-game HUD: health/stamina bars, healing vials, interaction prompt,
## area/checkpoint banners, death screen and a debug overlay (F3).
## Listens only to the Events bus and to the player's components.


var _player: Player
var _health_bar: StatBar
var _stamina_bar: StatBar
var _vials: Control
var _prompt: Label
var _prompt_glyph: Glyph
var _banner: Label
var _death: ColorRect
var _death_label: Label
var _fade: ColorRect
var _debug: Label
var _flasks := 0
var _flasks_max := 0
var _banner_tween: Tween
var _death_tween: Tween
var _saved_label: Label
var _ember_label: Label
var _ember_gain: Label
var _ember_shown := 0.0
var _ember_tween: Tween
var _quick_box: PanelContainer
var _boss_box: Control
var _msg_panel: PanelContainer
var _tip: Label
var _tip_tween: Tween
var _msg_title: Label
var _msg_text: Label
var _boss_name: Label
var _boss_bar: StatBar
var _boss: BossBase
var _quick_label: Label
var _quick_icon: Control
var _saved_tween: Tween
var _focus_bar: StatBar
var _status_row: Control


func _ready() -> void:
	layer = 10
	_build()
	Events.session_started.connect(_on_session_started)
	Events.game_saved.connect(_on_game_saved)
	Events.player_spawned.connect(_bind_player)
	Events.flasks_changed.connect(_on_flasks)
	Events.interact_prompt_shown.connect(_on_prompt)
	Events.interact_prompt_hidden.connect(func(): _prompt.visible = false)
	Events.banner_requested.connect(show_banner)
	Events.player_died.connect(_on_player_died)
	Events.player_respawned.connect(_on_player_respawned)
	Events.embers_changed.connect(_on_embers_changed)
	Events.embers_gained.connect(_on_embers_gained)
	Events.inventory_changed.connect(_refresh_quick)
	Events.item_picked.connect(func(id, n): _toast("%s  x%d" % [Items.get_item(id).display_name, n]))
	Events.stats_changed.connect(_sync_economy)
	Events.quest_changed.connect(_on_quest)
	Events.boss_fight_started.connect(_on_boss_fight_started)
	Events.message_requested.connect(_on_message)
	Events.tip_requested.connect(show_tip)
	Events.deed_unlocked.connect(func(id): _toast("Deed: %s" % Deeds.DEFS[id].title); Audio.sfx(&"coin", -6.0))
	Events.daynight_changed.connect(func(n): if n: show_tip(&"night"))
	Events.level_entered.connect(func(path): if "manor" in String(path): show_tip(&"travel"))
	Events.message_closed.connect(func(): _msg_panel.visible = false)
	Events.boss_fight_ended.connect(_on_boss_fight_ended)
	Events.session_started.connect(_sync_economy)
	Events.player_spawned.connect(func(_p): _sync_economy())


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	_health_bar = StatBar.new()
	_health_bar.position = Vector2(12, 10)
	_health_bar.size = Vector2(104, 7)
	_health_bar.fill_color = Palette.CRIMSON
	root.add_child(_health_bar)

	_stamina_bar = StatBar.new()
	_stamina_bar.position = Vector2(12, 20)
	_stamina_bar.size = Vector2(104, 4)
	_stamina_bar.fill_color = Color("7f8a5a")
	_stamina_bar.trail_color = Color("c8bd8a")
	root.add_child(_stamina_bar)

	_vials = Control.new()
	_vials.position = Vector2(12, 29)
	_vials.size = Vector2(80, 12)
	_vials.draw.connect(_draw_vials)
	root.add_child(_vials)

	# Focus (weapon skills) and status effects, under the vials.
	_focus_bar = StatBar.new()
	_focus_bar.position = Vector2(12, 43)
	_focus_bar.size = Vector2(60, 3)
	_focus_bar.fill_color = Color("6f7fd0")
	_focus_bar.trail_color = Color("b9c3ff")
	root.add_child(_focus_bar)
	_status_row = Control.new()
	_status_row.position = Vector2(12, 50)
	_status_row.size = Vector2(80, 10)
	_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_row.draw.connect(_draw_status)
	root.add_child(_status_row)

	# Embers (currency), top right.
	var ember_icon := Control.new()
	ember_icon.position = Vector2(480 - 26, 10)
	ember_icon.size = Vector2(12, 12)
	ember_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ember_icon.draw.connect(func():
		ember_icon.draw_circle(Vector2(6, 7), 5.5, Color(Palette.EMBER, 0.18))
		ember_icon.draw_colored_polygon(PackedVector2Array([Vector2(2, 11), Vector2(6, 0), Vector2(10, 11)]), Color(Palette.EMBER, 0.95))
		ember_icon.draw_colored_polygon(PackedVector2Array([Vector2(4, 11), Vector2(6, 4), Vector2(8, 11)]), Palette.GOLD_BRIGHT))
	root.add_child(ember_icon)
	_ember_label = _label(root, "0", 10, HORIZONTAL_ALIGNMENT_RIGHT)
	_ember_label.position = Vector2(480 - 140, 9)
	_ember_label.size = Vector2(108, 14)
	_ember_label.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	_tip = _label(root, "", 8, HORIZONTAL_ALIGNMENT_CENTER)
	_tip.position = Vector2(60, 226)
	_tip.size = Vector2(360, 30)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.add_theme_color_override(&"font_color", Palette.GOLD_BRIGHT)
	_tip.modulate.a = 0.0
	_ember_gain = _label(root, "", 8, HORIZONTAL_ALIGNMENT_RIGHT)
	_ember_gain.position = Vector2(480 - 168, 24)
	_ember_gain.size = Vector2(136, 12)
	_ember_gain.add_theme_color_override(&"font_color", Palette.EMBER)
	_ember_gain.modulate.a = 0.0

	# Quick-use item, bottom left.
	_quick_box = PanelContainer.new()
	_quick_box.position = Vector2(10, 246)
	_quick_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quick_box.add_theme_stylebox_override(&"panel", UITheme.box(Color(0.05, 0.045, 0.065, 0.78), Color(Palette.STONE, 0.8), 1, Vector2(4, 2)))
	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override(&"separation", 4)
	qrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quick_box.add_child(qrow)
	var qg := Glyph.new()
	qg.action = &"use_item"
	qrow.add_child(qg)
	_quick_icon = Control.new()
	_quick_icon.custom_minimum_size = Vector2(14, 14)
	_quick_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quick_icon.draw.connect(func(): IconArt.draw(_quick_icon, GameState.quick_item, Rect2(Vector2.ZERO, _quick_icon.size)))
	qrow.add_child(_quick_icon)
	_quick_label = _label(qrow, "", 8, HORIZONTAL_ALIGNMENT_LEFT)
	root.add_child(_quick_box)

	# Readable text (tablets, signs), lower middle.
	_msg_panel = PanelContainer.new()
	_msg_panel.position = Vector2(90, 150)
	_msg_panel.custom_minimum_size = Vector2(300, 0)
	_msg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_panel.visible = false
	root.add_child(_msg_panel)
	UITheme.frame(_msg_panel)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override(&"separation", 4)
	_msg_panel.add_child(mv)
	_msg_title = Label.new()
	UITheme.title(_msg_title, 11, Palette.GOLD_BRIGHT)
	mv.add_child(_msg_title)
	_msg_text = Label.new()
	_msg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_text.custom_minimum_size = Vector2(284, 0)
	_msg_text.add_theme_constant_override(&"line_spacing", -1)
	mv.add_child(_msg_text)

	# Boss bar, bottom centre.
	_boss_box = Control.new()
	_boss_box.position = Vector2(124, 232)
	_boss_box.size = Vector2(240, 28)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_name = _label(_boss_box, "", 10, HORIZONTAL_ALIGNMENT_LEFT)
	UITheme.title(_boss_name, 10, Palette.BONE)
	_boss_name.position = Vector2(0, 0)
	_boss_name.size = Vector2(240, 13)
	_boss_bar = StatBar.new()
	_boss_bar.position = Vector2(0, 15)
	_boss_bar.size = Vector2(240, 6)
	_boss_bar.fill_color = Palette.CRIMSON
	_boss_box.add_child(_boss_bar)

	_prompt = _label(root, "", 8, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(140, 236)
	_prompt.size = Vector2(200, 12)
	_prompt.visible = false
	# Button glyph (keyboard key or controller icon) sits to the left of the prompt text.
	var pg := Glyph.new()
	pg.action = &"interact"
	_prompt.add_child(pg)
	_prompt_glyph = pg
	_prompt.visibility_changed.connect(func(): pg.visible = _prompt.visible)

	_banner = _label(root, "", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.position = Vector2(0, 70)
	_banner.size = Vector2(480, 24)
	UITheme.title(_banner, 20, Palette.BONE)
	_banner.modulate.a = 0.0
	for ry in [-8.0, 32.0]:
		var rl := UITheme.rule(150)
		rl.position = Vector2(165, ry)
		_banner.add_child(rl)

	_death = ColorRect.new()
	_death.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death.color = Color(Palette.INK, 0.0)
	_death.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_death)
	_death_label = _label(root, "THE OATH BREAKS", 24, HORIZONTAL_ALIGNMENT_CENTER)
	_death_label.position = Vector2(0, 118)
	_death_label.size = Vector2(480, 30)
	UITheme.title(_death_label, 30, Palette.CRIMSON_BRIGHT)
	_death_label.modulate.a = 0.0

	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)

	_saved_label = _label(root, "Progress saved", 8, HORIZONTAL_ALIGNMENT_RIGHT)
	_saved_label.position = Vector2(332, 252)
	_saved_label.size = Vector2(140, 12)
	_saved_label.add_theme_color_override(&"font_color", Palette.GOLD)
	_saved_label.modulate.a = 0.0

	_debug = _label(root, "", 8, HORIZONTAL_ALIGNMENT_RIGHT)
	_debug.position = Vector2(280, 6)
	_debug.size = Vector2(192, 60)
	_debug.visible = Settings.show_debug


func _label(parent: Node, text: String, font_size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_outline_color", Palette.INK)
	l.add_theme_constant_override(&"outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _bind_player(p: Node2D) -> void:
	if not (p is Player):
		return
	if _player and is_instance_valid(_player):
		_player.health.changed.disconnect(_health_bar.set_values)
		_player.stamina.changed.disconnect(_stamina_bar.set_values)
		_player.focus_changed.disconnect(_focus_bar.set_values)
		_player.status.changed.disconnect(_status_row.queue_redraw)
	_player = p
	_player.health.changed.connect(_health_bar.set_values)
	_player.stamina.changed.connect(_stamina_bar.set_values)
	_health_bar.set_values(_player.health.current, _player.health.max_health)
	_stamina_bar.set_values(_player.stamina.current, _player.stamina.max_stamina)
	_on_flasks(_player.flasks, _player.max_flasks)
	_player.focus_changed.connect(_focus_bar.set_values)
	_player.focus_changed.connect(func(cur, _m): if cur >= 20.0: show_tip(&"focus"))
	_focus_bar.set_values(_player.focus, Player.MAX_FOCUS)
	_player.status.changed.connect(_status_row.queue_redraw)


func _on_flasks(current: int, maximum: int) -> void:
	_flasks = current
	_flasks_max = maximum
	_vials.queue_redraw()


func _draw_status() -> void:
	if _player == null or not is_instance_valid(_player) or _player.status == null:
		return
	var x := 0.0
	for k in StatusFx.KINDS:
		var on := _player.status.is_active(k)
		var b := float(_player.status.buildup.get(k, 0.0))
		if not on and b < 1.0:
			continue
		var c: Color = StatusFx.color_of(k)
		if on:
			_status_row.draw_circle(Vector2(x + 4, 4), 3.6, c)
		else:
			_status_row.draw_arc(Vector2(x + 4, 4), 3.2, -PI / 2.0, -PI / 2.0 + TAU * b / StatusFx.THRESHOLD, 14, c, 1.6)
		x += 10.0


func _draw_vials() -> void:
	for i in _flasks_max:
		var x := i * 9.0
		var full := i < _flasks
		var body := Palette.GOLD if full else Palette.STONE_DARK
		_vials.draw_rect(Rect2(x + 2, 0, 2, 2), Palette.BONE_DIM)
		_vials.draw_circle(Vector2(x + 3, 6), 3.2, Palette.INK)
		_vials.draw_circle(Vector2(x + 3, 6), 2.5, body)
		if full:
			_vials.draw_circle(Vector2(x + 2.3, 5.2), 0.8, Palette.GOLD_BRIGHT)


func _on_message(title: String, text: String) -> void:
	_msg_title.text = title
	_msg_text.text = text
	_msg_panel.reset_size()
	_msg_panel.position = Vector2(240 - _msg_panel.size.x / 2.0, 200 - _msg_panel.size.y)
	_msg_panel.visible = true


func _on_boss_fight_started(b: Node) -> void:
	var boss := b as BossBase
	if boss == null:
		return
	if is_instance_valid(_boss) and _boss.health.changed.is_connected(_boss_bar.set_values):
		_boss.health.changed.disconnect(_boss_bar.set_values)
	_boss = boss
	_boss_name.text = boss.data.display_name
	_boss_bar.px_per_point = 236.0 / maxf(1.0, boss.health.max_health)
	_boss_bar.value = boss.health.current
	_boss_bar.set_values(boss.health.current, boss.health.max_health)
	boss.health.changed.connect(_boss_bar.set_values)
	_boss_box.modulate.a = 0.0
	_boss_box.visible = true
	create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.6)
	_prompt.visible = false


func _on_boss_fight_ended(victory: bool) -> void:
	if not _boss_box.visible:
		return
	var t := create_tween()
	t.tween_interval(1.6 if victory else 0.8)
	t.tween_property(_boss_box, "modulate:a", 0.0, 0.8)
	t.tween_callback(func(): _boss_box.visible = false)


func _sync_economy() -> void:
	_ember_shown = float(GameState.embers)
	_ember_label.text = str(GameState.embers)
	_refresh_quick()


func _on_embers_changed(total: int) -> void:
	if _ember_tween:
		_ember_tween.kill()
	_ember_tween = create_tween()
	_ember_tween.tween_method(func(v: float): _ember_shown = v; _ember_label.text = str(roundi(v)), _ember_shown, float(total), 0.5)


func _on_embers_gained(amount: int) -> void:
	_ember_gain.text = "+%d" % amount
	_ember_gain.modulate.a = 1.0
	create_tween().tween_property(_ember_gain, "modulate:a", 0.0, 1.6).set_delay(0.6)


func _refresh_quick() -> void:
	var item := Items.get_item(GameState.quick_item)
	_quick_box.visible = item != null and GameState.item_count(GameState.quick_item) > 0
	if _quick_box.visible:
		_quick_label.text = "x%d" % GameState.item_count(GameState.quick_item)
		_quick_icon.queue_redraw()


func _on_quest(id: StringName, st: String) -> void:
	var d := Quests.def(id)
	match st:
		"active":
			_toast("Errand: %s" % d.title)
			show_tip(&"quest")
		"done":
			_toast("Errand done: %s" % d.title)
		_:
			var p := Quests.progress(id)
			if p.have <= p.need:
				_toast("%s  %d/%d" % [d.title, p.have, p.need])


## Shows a one-time tutorial tip near the bottom of the screen for a few seconds.
func show_tip(id: StringName) -> void:
	if not Tutorial.take(id):
		return
	var t: Dictionary = Tutorial.TIPS[id]
	var txt: String = t.text
	txt = txt.replace("{skill}", _key_name(&"skill")).replace("{travel}", _key_name(&"travel_manor")).replace("{parry}", _key_name(&"parry"))
	_tip.text = "%s: %s" % [t.title, txt]
	_tip.modulate.a = 1.0
	if _tip_tween:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip, "modulate:a", 0.0, 1.2).set_delay(7.0)
	Events.tip_shown.emit(id)


func _toast(text: String) -> void:
	_ember_gain.text = text
	_ember_gain.modulate.a = 1.0
	create_tween().tween_property(_ember_gain, "modulate:a", 0.0, 1.6).set_delay(1.2)


func _on_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = true
	_prompt_glyph.position = Vector2(_prompt.size.x / 2.0 - _prompt_half() - 16.0, 0.0)


func _prompt_half() -> float:
	return _prompt.get_theme_font(&"font").get_string_size(_prompt.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0


func _key_name(action: StringName) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var code: Key = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			return OS.get_keycode_string(code)
	return String(action)


func show_banner(text: String) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, ^"modulate:a", 1.0, 0.5)
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(_banner, ^"modulate:a", 0.0, 0.9)


func _on_player_died() -> void:
	_prompt.visible = false
	if _death_tween:
		_death_tween.kill()
	var t := create_tween()
	_death_tween = t
	t.tween_interval(0.5)
	t.tween_property(_death, ^"color:a", 0.55, 0.8)
	t.parallel().tween_property(_death_label, ^"modulate:a", 1.0, 0.8)
	t.tween_interval(0.6)
	t.tween_property(_fade, ^"color:a", 1.0, 0.6)


func _on_player_respawned(_p: Node2D) -> void:
	_death.color.a = 0.0
	_death_label.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_fade, ^"color:a", 0.0, 0.7)


## A new session (new game / continue) must never inherit the old one's death
## screen, fade or banner — e.g. when quitting to the menu from the death screen.
func _on_session_started() -> void:
	for t in [_death_tween, _banner_tween, _saved_tween]:
		if t:
			t.kill()
	_death.color.a = 0.0
	_death_label.modulate.a = 0.0
	_fade.color.a = 0.0
	_banner.modulate.a = 0.0
	_saved_label.modulate.a = 0.0
	_prompt.visible = false
	_boss_box.visible = false
	_msg_panel.visible = false


func _on_game_saved(_slot: int) -> void:
	if _saved_tween:
		_saved_tween.kill()
	_saved_tween = create_tween()
	_saved_tween.tween_property(_saved_label, ^"modulate:a", 1.0, 0.2)
	_saved_tween.tween_interval(1.4)
	_saved_tween.tween_property(_saved_label, ^"modulate:a", 0.0, 0.6)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_toggle"):
		Settings.show_debug = not Settings.show_debug
		_debug.visible = Settings.show_debug
	if _debug.visible and is_instance_valid(_player):
		var r := _player.attack_runner
		var atk := "-"
		if r.attack:
			atk = "%s f%d %s" % [r.attack.id, r.frame, AttackRunner.Phase.keys()[r.phase]]
		_debug.text = "FPS %d\n%s f%d\nvel %.0f, %.0f\nHP %.0f  ST %.0f\natk %s\ni-frames %s" % [
			Engine.get_frames_per_second(), _player.state_name(), _player.state_frame,
			_player.velocity.x, _player.velocity.y, _player.health.current, _player.stamina.current,
			atk, str(_player.is_invulnerable())]
