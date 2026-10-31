class_name BossSpeech
extends Control
## Boss voice lines as speech subtitles: speaker name in gold, the line below, fading in and out.
## Plays on fight start (two lines), at the boss's phase change, on its death and when you fall.
## Non-blocking: combat carries on. Text only; the 'talk' blip stands in for a voice.

var _name: Label
var _line: Label
var _queue: Array[Dictionary] = []
var _busy := false
var _speaker := ""
## boss id -> speaker name, filled as fights start (so two bosses can both speak).
var _names := {}
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
	Events.boss_say.connect(_on_scripted)


func _on_started(b: Node) -> void:
	var boss := b as BossBase
	if boss == null:
		return
	_boss = boss
	_over = false
	_id = boss.boss_id
	_speaker = String(boss.data.display_name)
	_names[_id] = _speaker
	if boss.scripted_intro:
		return   # the arena plays its own spoken intro
	_queue.clear()
	var intro := BossLines.intro(_id)
	for i in intro.size():
		_queue.append({"t": intro[i], "who": _speaker, "voice": "%s_%d" % [_id, i]})
	_run()


func _on_phase(b: Node, _phase: int) -> void:
	var boss := b as BossBase
	if boss and _names.has(boss.boss_id):
		_say(BossLines.half(boss.boss_id), _names[boss.boss_id], "%s_2" % boss.boss_id, true)


func _on_defeated(id: StringName) -> void:
	if _names.has(id):
		if id == _id:
			_over = true
		_say(BossLines.defeated(id), _names[id], "%s_3" % id, true)


func _on_player_died() -> void:
	if not _over and _boss and is_instance_valid(_boss) and _id != &"" and _boss.health.current > 0.0:
		_say(BossLines.fallen(_id), _speaker, "%s_4" % _id, true)


## A line the arena scripts itself (the Twin Lords' hand-arena dialogue).
func _on_scripted(speaker: String, text: String, voice: StringName) -> void:
	_say(text, speaker, String(voice), false)


## Queues one line; urgent lines jump the queue.
func _say(text: String, who: String, voice: String, urgent := false) -> void:
	var item := {"t": text, "who": who, "voice": voice}
	if urgent:
		_queue.push_front(item)
	else:
		_queue.append(item)
	_run()


func _run() -> void:
	if _busy:
		return
	_busy = true
	var box := get_node("Box") as Control
	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		var t: String = item["t"]
		_name.text = item["who"]
		_fit(t)
		box.reset_size()
		box.position = Vector2(240.0 - box.size.x / 2.0, 150.0)
		var vlen := Audio.voice_line(StringName(item["voice"]))
		if vlen <= 0.0:
			Audio.sfx(&"talk", -10.0, randf_range(0.55, 0.7))
		var tw := create_tween()
		tw.tween_property(box, "modulate:a", 1.0, 0.25)
		await tw.finished
		await get_tree().create_timer(maxf(clampf(1.6 + t.length() * 0.045, 2.0, 4.5), vlen + 0.3)).timeout
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
