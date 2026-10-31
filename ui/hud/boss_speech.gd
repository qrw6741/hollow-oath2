class_name BossSpeech
extends Control
## Boss voice lines as speech subtitles: speaker name in gold, the line below, fading in and out.
## Plays on fight start (two lines), at the boss's phase change, on its death and when you fall.
## Non-blocking: combat carries on. Text only; the 'talk' blip stands in for a voice.

var _name: Label
var _line: Label
var _queue: Array[String] = []
var _busy := false
var _speaker := ""
var _boss: Node
var _id: StringName = &""
var _over := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := PanelContainer.new()
	box.position = Vector2(60, 150)
	box.custom_minimum_size = Vector2(360, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(&"panel", UITheme.box(Color(0.04, 0.035, 0.05, 0.72), Color(Palette.CRIMSON, 0.7), 1, Vector2(8, 4)))
	add_child(box)
	box.name = &"Box"
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 1)
	box.add_child(v)
	_name = Label.new()
	UITheme.title(_name, 8, Palette.GOLD_BRIGHT)
	v.add_child(_name)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(344, 0)
	_line.add_theme_color_override(&"font_color", Palette.BONE)
	v.add_child(_line)
	box.modulate.a = 0.0
	Events.boss_fight_started.connect(_on_started)
	Events.boss_phase_changed.connect(_on_phase)
	Events.boss_defeated.connect(_on_defeated)
	Events.player_died.connect(_on_player_died)


func _on_started(b: Node) -> void:
	var boss := b as BossBase
	if boss == null:
		return
	_boss = boss
	_over = false
	_id = boss.boss_id
	_speaker = String(boss.data.display_name)
	_queue.clear()
	for t in BossLines.intro(_id):
		_queue.append(t)
	_run()


func _on_phase(b: Node, _phase: int) -> void:
	if b == _boss and _id != &"":
		_say(BossLines.half(_id), true)


func _on_defeated(id: StringName) -> void:
	if id == _id and _id != &"":
		_over = true
		_say(BossLines.defeated(id), true)


func _on_player_died() -> void:
	if not _over and _boss and is_instance_valid(_boss) and _id != &"" and _boss.health.current > 0.0:
		_say(BossLines.fallen(_id), true)


## Queues one line; urgent lines jump the queue.
func _say(text: String, urgent := false) -> void:
	if urgent:
		_queue.push_front(text)
	else:
		_queue.append(text)
	_run()


func _run() -> void:
	if _busy:
		return
	_busy = true
	var box := get_node("Box") as Control
	while not _queue.is_empty():
		var t: String = _queue.pop_front()
		_name.text = _speaker
		_fit(t)
		box.reset_size()
		box.position = Vector2(240.0 - box.size.x / 2.0, 150.0)
		Audio.sfx(&"talk", -10.0, randf_range(0.55, 0.7))
		var tw := create_tween()
		tw.tween_property(box, "modulate:a", 1.0, 0.25)
		await tw.finished
		await get_tree().create_timer(clampf(1.6 + t.length() * 0.045, 2.0, 4.5)).timeout
		var tw2 := create_tween()
		tw2.tween_property(box, "modulate:a", 0.0, 0.3)
		await tw2.finished
	_busy = false


func _fit(t: String) -> void:
	_line.text = t
	var f := _line.get_theme_font(&"font")
	var size := 9
	while size > 6 and f.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, 344.0, size).y > 28.0:
		size -= 1
	_line.add_theme_font_size_override(&"font_size", size)
