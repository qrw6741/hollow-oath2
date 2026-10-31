class_name MenuAnim
extends Node2D
## Living backdrop for the title screen (screen space, 480x270): drifting mist, a flickering
## candle, a pulsing moon halo, twinkling stars, rising embers, a lone cloaked figure pacing the
## ledge, and a slow parallax sway of the ruins. Purely visual; no gameplay state. TEMPORARY ART.

var ruins: Array[Node2D] = []     ## parallax layers to sway (set by the menu)
var _t := 0.0
var _base_x: Array[float] = []
var _walker_x := 120.0
var _walker_dir := 1.0
var _stars: Array[Vector2] = []
var _embers: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 22:
		_stars.append(Vector2(rng.randf() * 480.0, rng.randf() * 130.0))
	for i in 26:
		_embers.append({"x": rng.randf() * 480.0, "y": rng.randf() * 270.0, "v": rng.randf_range(6.0, 18.0), "p": rng.randf() * TAU})
	for r in ruins:
		_base_x.append(r.position.x)


func _process(delta: float) -> void:
	_t += delta
	# Ruins sway: far layers drift less than near ones.
	for i in ruins.size():
		ruins[i].position.x = _base_x[i] + sin(_t * 0.12 + i) * (3.0 + i * 3.0)
	_walker_x += _walker_dir * 9.0 * delta
	if _walker_x > 330.0:
		_walker_dir = -1.0
	elif _walker_x < 90.0:
		_walker_dir = 1.0
	for e in _embers:
		e.y -= e.v * delta
		if e.y < -4.0:
			e.y = 272.0
			e.x = randf() * 480.0
	queue_redraw()


func _draw() -> void:
	# Twinkling stars
	for i in _stars.size():
		var a := 0.25 + 0.35 * (0.5 + 0.5 * sin(_t * 1.7 + i * 1.9))
		draw_rect(Rect2(_stars[i].floor(), Vector2.ONE), Color(Palette.BONE, a))
	# Moon halo breathing
	var m := Vector2(372, 58)
	draw_circle(m, 40.0 + sin(_t * 0.8) * 3.0, Color(Palette.MOON, 0.035))
	# Mist: two slow bands of soft ellipses sliding in opposite directions
	for band in 2:
		var dir := 1.0 if band == 0 else -1.0
		var y := 222.0 + band * 18.0
		for k in 9:
			var x := fposmod(k * 70.0 + _t * 6.0 * dir * (1.0 + band * 0.6), 560.0) - 40.0
			draw_circle(Vector2(x, y + sin(_t * 0.5 + k) * 2.0), 26.0, Color(0.55, 0.42, 0.5, 0.022))
			draw_circle(Vector2(x + 14, y + 3), 18.0, Color(0.55, 0.42, 0.5, 0.018))
	# Candle on the ledge: flame wobble and glow flicker
	var flick := 0.6 + 0.4 * sin(_t * 17.0) * sin(_t * 5.3 + 1.0)
	var c := Vector2(412, 238)
	draw_circle(c, 30.0 + flick * 8.0, Color(Palette.GOLD, 0.03 + 0.02 * flick))
	draw_circle(c, 12.0 + flick * 3.0, Color(Palette.GOLD_BRIGHT, 0.07 + 0.04 * flick))
	var sway := sin(_t * 9.0) * 0.8
	draw_colored_polygon(PackedVector2Array([c + Vector2(-1.5, 0), c + Vector2(1.5, 0), c + Vector2(sway, -4.5 - flick * 1.5)]), Palette.GOLD_BRIGHT)
	# The lone figure: cloaked, hooded, pacing, with a small lantern glow
	var p := Vector2(_walker_x, 250.0)
	var bob := absf(sin(_t * 5.0)) * 1.0
	var f := _walker_dir
	p.y -= bob
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(3, -12), p + Vector2(0, -15), p + Vector2(-3, -12)]), Color("0d0b10"))
	draw_circle(p + Vector2(0.5 * f, -15), 2.6, Color("0d0b10"))
	draw_line(p + Vector2(0, -2), p + Vector2(f * 3.0 + sin(_t * 5.0) * 1.5, 2.0 + bob), Color("0d0b10"), 1.5)
	var lp := p + Vector2(f * 6.0, -6.0 + sin(_t * 2.0))
	draw_circle(lp, 1.3, Palette.GOLD_BRIGHT)
	draw_circle(lp, 9.0 + flick * 2.0, Color(Palette.GOLD, 0.07))
	# Rising embers
	for e in _embers:
		var a := 0.15 + 0.5 * (0.5 + 0.5 * sin(_t * 3.0 + e.p))
		draw_rect(Rect2(Vector2(e.x + sin(_t * 0.9 + e.p) * 5.0, e.y).floor(), Vector2(1, 1)), Color(1.0, 0.55, 0.2, a))
