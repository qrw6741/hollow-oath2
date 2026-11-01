class_name CineLayer
extends CanvasLayer
## Cutscene dressing: letterbox bars, a name plate for a character, a title card and a "hold to skip" hint.
## Pressing X on the keyboard skips at once; on a controller, holding Interact (D-pad up) for one second does.
## Either emits [signal skip_requested].
## TEMPORARY ART: plain bars and text.

signal skip_requested

const BAR_H := 30.0
const HOLD_TO_SKIP := 1.0

var _top: ColorRect
var _bot: ColorRect
var _plate: Label
var _plate_sub: Label
var _title: Label
var _title_sub: Label
var _hint: Label
var _hold := 0.0
var _skipped := false


func _ready() -> void:
	layer = 30
	_top = _bar(true)
	_bot = _bar(false)
	_plate = _label(11, Palette.GOLD_BRIGHT)
	_plate.position = Vector2(26, 196)
	_plate_sub = _label(7, Color(0.85, 0.82, 0.75))
	_plate_sub.position = Vector2(27, 211)
	_title = _label(24, Palette.GOLD_BRIGHT)
	_title_sub = _label(8, Color(0.85, 0.82, 0.75))
	for l in [_title, _title_sub]:
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.offset_bottom = -14.0   # a little above the middle
	_title_sub.offset_top = 22.0
	_hint = _label(6, Color(0.7, 0.68, 0.64))
	_hint.text = "Press X to skip"
	_hint.position = Vector2(380, 246)
	_hint.modulate.a = 0.0


func _bar(top: bool) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_right = 1.0
	if top:
		r.offset_bottom = 0.0
	else:
		r.anchor_top = 1.0
		r.anchor_bottom = 1.0
		r.offset_top = 0.0
	add_child(r)
	return r


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override(&"font", UITheme.title_font())
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", col)
	l.add_theme_color_override(&"font_outline_color", Color.BLACK)
	l.add_theme_constant_override(&"outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = 0.0
	add_child(l)
	return l


## Closes the letterbox bars in (on) or opens them (off).
func bars(on: bool, dur := 0.8) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_top, "offset_bottom", BAR_H if on else 0.0, dur)
	tw.tween_property(_bot, "offset_top", -BAR_H if on else 0.0, dur)
	tw.tween_property(_hint, "modulate:a", 0.8 if on else 0.0, dur)


## A character name plate at the lower left; fades in, holds, fades out (does not block).
func plate(who: String, sub: String, secs := 2.2) -> void:
	_plate.text = who
	_plate_sub.text = sub
	var tw := create_tween()
	tw.tween_property(_plate, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(_plate_sub, "modulate:a", 1.0, 0.3)
	tw.tween_interval(maxf(secs - 0.6, 0.1))
	tw.tween_property(_plate, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(_plate_sub, "modulate:a", 0.0, 0.3)


## Big centred title card; returns after it has faded out.
func title(text: String, sub := "", secs := 2.6) -> void:
	_title.text = text
	_title_sub.text = sub
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.6)
	tw.parallel().tween_property(_title_sub, "modulate:a", 1.0, 0.9)
	tw.tween_interval(maxf(secs - 1.5, 0.1))
	tw.tween_property(_title, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(_title_sub, "modulate:a", 0.0, 0.7)
	await tw.finished


func _input(event: InputEvent) -> void:
	if _skipped:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X:
		_skipped = true
		skip_requested.emit()
		get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	if _skipped:
		return
	if Input.is_action_pressed(&"interact"):
		_hold += dt
		_hint.modulate.a = 1.0
		if _hold >= HOLD_TO_SKIP:
			_skipped = true
			skip_requested.emit()
	else:
		_hold = maxf(0.0, _hold - dt * 2.0)
