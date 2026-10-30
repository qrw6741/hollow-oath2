class_name StatCard
extends Button
## One attribute on the level-up screen: a drawn emblem, the stat's name and value, a row of
## pips, "now -> next" for what it changes, and the price. Focus lifts and glows the card; if
## you cannot afford it the card dims and the price turns red. Still a Button: Confirm buys.

var stat := "vigor"
var title := "Vigor"
var value := 0
var cost := 0
var affordable := true
var line_now := ""
var line_next := ""
var blurb := ""
var _t := 0.0
var _pop := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(104, 112)
	focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(st, empty)


func _ready() -> void:
	focus_entered.connect(func(): queue_redraw(); if is_visible_in_tree(): Audio.sfx(&"ui_move", -6.0))
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	pressed.connect(func(): _pop = 1.0)


func _process(delta: float) -> void:
	if has_focus() or _pop > 0.0:
		_t += delta
		_pop = maxf(0.0, _pop - delta * 3.0)
		queue_redraw()


func _col() -> Color:
	return {"vigor": Palette.CRIMSON_BRIGHT, "endurance": Color("8fb35a"), "strength": Palette.GOLD_BRIGHT}.get(stat, Palette.BONE)


func _draw() -> void:
	var hot := has_focus() or is_hovered()
	var c := _col()
	var dim := 1.0 if affordable else 0.55
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.06, 0.055, 0.075, 0.96))
	draw_rect(r.grow(-1.5), Color(0.1, 0.09, 0.12))
	# A soft pool of the stat's colour behind the emblem.
	for i in 6:
		draw_circle(Vector2(size.x / 2.0, 21), 22.0 - i * 3.0, Color(c, (0.035 + 0.01 * i) * dim * (1.6 if hot else 1.0)))
	if hot:
		draw_rect(r, Color(Palette.GOLD, 0.07 + 0.05 * sin(_t * 5.0)))
	draw_rect(r, Palette.GOLD if hot else Color(Palette.STONE, 0.9), false, 1.5 if hot else 1.0)
	if _pop > 0.0:
		draw_rect(r.grow(_pop * 3.0), Color(c, _pop * 0.6), false, 1.5)
	_emblem(Vector2(size.x / 2.0, 20), c, dim)
	var tf := UITheme.body_font()   # lining digits for the numbers
	var bf := UITheme.body_font()
	_centered(tf, title.to_upper(), 43.0, 9, Color(Palette.BONE, dim))
	_centered(tf, str(value), 59.0, 17, Color(c, dim))
	# Pips: one per point up to 20, the next one pulsing when you could buy it.
	var n := 20
	var shown := mini(value, n)
	var px := (size.x - n * 3.8) / 2.0
	for i in n:
		var pr := Rect2(px + i * 3.8, 66.0, 2.8, 3.0)
		if i < shown:
			draw_rect(pr, Color(c, dim))
		elif i == shown and affordable:
			draw_rect(pr, Color(c, 0.35 + 0.35 * sin(_t * 6.0)))
		else:
			draw_rect(pr, Color(Palette.STONE, 0.5))
	_centered(bf, line_now + "  ->  " + line_next if line_next != "" else line_now, 91.0, 8, Color(Palette.BONE_DIM if not affordable else Color("b9d99a"), 1.0))
	_centered(bf, blurb, 102.0, 7, Color(Palette.STONE_LIGHT, 0.9))
	# Price tag
	var ptxt := str(cost)
	var pw := tf.get_string_size(ptxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	var pcol := Palette.GOLD_BRIGHT if affordable else Palette.CRIMSON_BRIGHT
	var gx := size.x / 2.0 - pw / 2.0 - 7.0
	draw_colored_polygon(PackedVector2Array([Vector2(gx - 2.5, 80.5), Vector2(gx, 75.0), Vector2(gx + 2.5, 80.5)]), Color(Palette.EMBER, 0.95))
	draw_string(tf, Vector2(size.x / 2.0 - pw / 2.0 + 1.0, 82.0), ptxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, pcol)


func _centered(f: Font, s: String, y: float, fs: int, col: Color) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2((size.x - w) / 2.0, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _emblem(p: Vector2, c: Color, dim: float) -> void:
	var col := Color(c, dim)
	var out := Color(Palette.INK, 0.9)
	match stat:
		"vigor":
			# A heart-shaped flame.
			var pts := PackedVector2Array([p + Vector2(0, 11), p + Vector2(-10, 1), p + Vector2(-10, -5), p + Vector2(-5, -9), p + Vector2(0, -4), p + Vector2(5, -9), p + Vector2(10, -5), p + Vector2(10, 1)])
			draw_colored_polygon(pts, out)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 9), p + Vector2(-8, 1), p + Vector2(-8, -4), p + Vector2(-5, -7), p + Vector2(0, -3), p + Vector2(5, -7), p + Vector2(8, -4), p + Vector2(8, 1)]), col)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 6), p + Vector2(-3, 0), p + Vector2(0, -3), p + Vector2(3, 0)]), Color(Palette.GOLD_BRIGHT, 0.7 * dim))
		"endurance":
			# Three rising chevrons: breath and stride.
			for i in 3:
				var y := 6.0 - i * 6.0
				draw_polyline(PackedVector2Array([p + Vector2(-9, y + 3), p + Vector2(0, y - 3), p + Vector2(9, y + 3)]), out, 4.0)
				draw_polyline(PackedVector2Array([p + Vector2(-9, y + 3), p + Vector2(0, y - 3), p + Vector2(9, y + 3)]), Color(col, dim * (0.45 + 0.28 * (2 - i) * 0.0 + 0.2 * i)), 2.2)
		_:
			# A sword over a fist: blade up, crossguard, grip.
			draw_line(p + Vector2(0, 12), p + Vector2(0, -11), out, 5.0)
			draw_line(p + Vector2(0, 8), p + Vector2(0, -10), col, 2.6)
			draw_line(p + Vector2(-7, 4), p + Vector2(7, 4), out, 4.0)
			draw_line(p + Vector2(-6, 4), p + Vector2(6, 4), Color(Palette.GOLD, dim), 2.0)
			draw_circle(p + Vector2(0, 12), 2.2, Color(Palette.GOLD, dim))
