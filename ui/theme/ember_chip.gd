class_name EmberChip
extends Control
## A little ember glyph and a number, right-aligned in gold: the currency readout used by the
## shop and level-up screens. [member shown] eases toward [member value] so gains and spending
## visibly tick. [member flash] briefly tints it (red on a refused purchase, green on a gain).

var value := 0:
	set(v):
		value = v
		queue_redraw()
var shown := 0.0
var flash := 0.0
var flash_color := Palette.CRIMSON_BRIGHT
var label := ""


func _init() -> void:
	custom_minimum_size = Vector2(96, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(v: int, instant := false) -> void:
	value = v
	if instant:
		shown = float(v)


func pulse(c: Color) -> void:
	flash = 1.0
	flash_color = c


func _process(delta: float) -> void:
	var changed := false
	if not is_equal_approx(shown, float(value)):
		shown = move_toward(shown, float(value), maxf(1.0, absf(float(value) - shown) * 8.0 * delta))
		changed = true
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.5)
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var f := UITheme.title_font()
	var s := str(roundi(shown))
	var col := Palette.GOLD_BRIGHT.lerp(flash_color, flash)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var x := size.x - w - 2.0
	draw_string_outline(f, Vector2(x, size.y - 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 2, Palette.INK)
	draw_string(f, Vector2(x, size.y - 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	var gx := x - 9.0
	draw_circle(Vector2(gx, size.y / 2.0 + 1.0), 6.0, Color(Palette.EMBER, 0.16))
	draw_colored_polygon(PackedVector2Array([Vector2(gx - 3.5, size.y - 2.5), Vector2(gx, 1.5), Vector2(gx + 3.5, size.y - 2.5)]), Color(Palette.EMBER, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(gx - 1.6, size.y - 2.5), Vector2(gx, 5.5), Vector2(gx + 1.6, size.y - 2.5)]), Palette.GOLD_BRIGHT)
	if label != "":
		draw_string(UITheme.body_font(), Vector2(0, size.y - 3.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.BONE_DIM)
