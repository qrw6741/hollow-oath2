extends Node2D
## Floating damage number. Critical hits are larger and gold.

const LIFETIME := 0.8

var _text := ""
var _critical := false
var _t := 0.0
var _vx := 0.0


func setup(amount: float, critical: bool) -> void:
	_text = str(roundi(amount))
	_critical = critical
	_vx = randf_range(-14.0, 14.0)
	z_index = 30


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	position += Vector2(_vx, -32.0 * (1.0 - _t / LIFETIME)) * delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := 12 if _critical else 8
	var a := clampf((LIFETIME - _t) / 0.3, 0.0, 1.0)
	var col := Color("e7c25a") if _critical else Color("e8e0cc")
	col.a = a
	var w := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(-w * 0.5, 0)
	draw_string_outline(font, pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0.04, 0.03, 0.05, a))
	draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
