class_name IconSlot
extends Button
## A square inventory slot showing an icon (IconArt) instead of text, with an optional
## stack count and a small gold mark for the quick item. Focus / hover: gold frame and glow.
## Works with keyboard, gamepad (grid focus by position) and mouse like any Button.

var icon_id: StringName = &"":
	set(v): icon_id = v; queue_redraw()
var count := 0:
	set(v): count = v; queue_redraw()
var marked := false:
	set(v): marked = v; queue_redraw()
## An undiscovered thing: drawn as a grey "?" instead of its icon.
var locked := false:
	set(v): locked = v; queue_redraw()
var caption := "":
	set(v): caption = v; queue_redraw()

var _t := 0.0


func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(st, empty)


func _ready() -> void:
	focus_entered.connect(func(): queue_redraw(); if is_visible_in_tree(): Audio.sfx(&"ui_move", -8.0))
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _process(delta: float) -> void:
	if has_focus() or icon_id in [&"ember_shard", &"penitents_tear", &"status"]:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var cap_h := 9.0 if caption != "" else 0.0
	var box := Rect2(Vector2.ZERO, Vector2(size.x, size.y - cap_h))
	var hot := has_focus() or is_hovered()
	draw_rect(box, Color(0.07, 0.065, 0.085, 0.95))
	draw_rect(box.grow(-1.5), Color(0.11, 0.10, 0.13))
	if hot:
		draw_rect(box, Color(Palette.GOLD, 0.10 + 0.05 * sin(_t * 5.0)))
	draw_rect(box, Palette.GOLD if hot else Color(Palette.STONE, 0.9), false, 1.5 if hot else 1.0)
	if locked:
		var qf := UITheme.title_font()
		var qs := int(box.size.y * 0.6)
		var qw := qf.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs).x
		draw_string(qf, Vector2((box.size.x - qw) / 2.0, box.size.y * 0.72), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs, Color(0.35, 0.34, 0.38))
	elif icon_id != &"":
		IconArt.draw(self, icon_id, box.grow(-box.size.x * 0.14), _t)
	if count > 1:
		var s := str(count)
		var f := UITheme.body_font()
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_string_outline(f, Vector2(box.end.x - w - 2, box.end.y - 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Palette.INK)
		draw_string(f, Vector2(box.end.x - w - 2, box.end.y - 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Palette.BONE)
	if marked:
		draw_colored_polygon(PackedVector2Array([Vector2(3, 6), Vector2(5.5, 3), Vector2(8, 6), Vector2(5.5, 9)]), Palette.GOLD_BRIGHT)
	if caption != "":
		var f2 := UITheme.title_font()
		var cw := f2.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_string(f2, Vector2((size.x - cw) / 2.0, size.y - 1), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Palette.GOLD if hot else Palette.STONE_LIGHT)
