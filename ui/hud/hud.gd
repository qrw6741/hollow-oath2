extends CanvasLayer
## In-game HUD: health/stamina bars, healing vials, interaction prompt,
## area/checkpoint banners, death screen and a debug overlay (F3).
## Listens only to the Events bus and to the player's components.


var _player: Player
var _health_bar: StatBar
var _stamina_bar: StatBar
var _vials: Control
var _prompt: Label
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
var _saved_tween: Tween


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


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	_prompt = _label(root, "", 8, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(140, 236)
	_prompt.size = Vector2(200, 12)
	_prompt.visible = false

	_banner = _label(root, "", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.position = Vector2(0, 70)
	_banner.size = Vector2(480, 24)
	_banner.add_theme_color_override(&"font_color", Palette.BONE)
	_banner.modulate.a = 0.0

	_death = ColorRect.new()
	_death.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death.color = Color(Palette.INK, 0.0)
	_death.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_death)
	_death_label = _label(root, "THE OATH BREAKS", 24, HORIZONTAL_ALIGNMENT_CENTER)
	_death_label.position = Vector2(0, 118)
	_death_label.size = Vector2(480, 30)
	_death_label.add_theme_color_override(&"font_color", Palette.CRIMSON_BRIGHT)
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
	_player = p
	_player.health.changed.connect(_health_bar.set_values)
	_player.stamina.changed.connect(_stamina_bar.set_values)
	_health_bar.set_values(_player.health.current, _player.health.max_health)
	_stamina_bar.set_values(_player.stamina.current, _player.stamina.max_stamina)
	_on_flasks(_player.flasks, _player.max_flasks)


func _on_flasks(current: int, maximum: int) -> void:
	_flasks = current
	_flasks_max = maximum
	_vials.queue_redraw()


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


func _on_prompt(text: String) -> void:
	_prompt.text = "[%s]  %s" % [_key_name(&"interact"), text]
	_prompt.visible = true


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
