class_name TalismanArt
extends RefCounted
## Hand-drawn (procedural) icons for every talisman, on the same 16x16 grid as IconArt.
## Boss talismans: gilded rim, four studs, a glowing gem and a pulsing aura. Elite talismans:
## a plain silver rim. Each has its own emblem. TEMPORARY ART until hand-painted icons.

const OUT := Color(0.05, 0.04, 0.06, 0.95)
const M := Vector2(8, 9.5)


static func draw(ci: CanvasItem, id: StringName, t: float) -> void:
	var item := Items.get_item(id)
	var c: Color = item.icon_color if item else Palette.GOLD
	var boss: bool = TalismanData.DEFS.get(id, {}).get("source", &"elite") != &"elite"
	var pulse := 0.5 + 0.5 * sin(t * 2.2 + float(String(id).hash() % 7))
	if boss:
		for k in 3:
			ci.draw_circle(M, 8.2 - k * 1.5, Color(c.r, c.g, c.b, (0.05 + 0.05 * pulse) * (k + 1) * 0.6))
	# Cord
	ci.draw_line(Vector2(8, 0.2), Vector2(8, 4.2), OUT, 2.4)
	ci.draw_line(Vector2(8, 0.2), Vector2(8, 4.2), Color(0.62, 0.5, 0.36), 1.0)
	ci.draw_circle(Vector2(8, 3.6), 1.1, OUT)
	ci.draw_circle(Vector2(8, 3.6), 0.6, Color(0.85, 0.75, 0.5))
	# Medallion
	var rim := Color(0.88, 0.7, 0.3) if boss else Color(0.72, 0.74, 0.8)
	ci.draw_circle(M, 6.5, OUT)
	ci.draw_circle(M, 5.9, rim.darkened(0.35))
	ci.draw_circle(M, 5.3, rim)
	ci.draw_circle(M, 4.5, c.darkened(0.7))
	ci.draw_circle(M, 3.9, c.darkened(0.45))
	ci.draw_arc(M, 5.5, PI * 1.1, PI * 1.75, 8, rim.lightened(0.5), 0.8)
	if boss:
		for a in 4:
			var p := M + Vector2.from_angle(a * PI * 0.5 - PI * 0.5) * 6.0
			ci.draw_circle(p, 1.0, OUT)
			ci.draw_circle(p, 0.6, Color(1.0, 0.9, 0.55))
	var e := c.lightened(0.62)
	_emblem(ci, id, e, c, t)
	# Glint
	ci.draw_circle(M + Vector2(-2.2, -2.4), 0.9, Color(1, 1, 1, 0.35 + 0.35 * pulse))


static func _poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(0.45, 0.45))
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.55))
	ci.draw_colored_polygon(PackedVector2Array(pts), col)


static func _ln(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	ci.draw_line(a + Vector2(0.4, 0.4), b + Vector2(0.4, 0.4), Color(0, 0, 0, 0.55), w)
	ci.draw_line(a, b, col, w)


static func _emblem(ci: CanvasItem, id: StringName, e: Color, c: Color, t: float) -> void:
	var m := M
	match id:
		&"tal_warden":  # a bell
			_poly(ci, [m + Vector2(-1.2, -3.2), m + Vector2(1.2, -3.2), m + Vector2(2.2, 1.4), m + Vector2(3.0, 2.6), m + Vector2(-3.0, 2.6), m + Vector2(-2.2, 1.4)], e)
			ci.draw_circle(m + Vector2(0, 3.3), 0.8, e)
		&"tal_marshal":  # a crest: shield with chevron
			_poly(ci, [m + Vector2(-3, -3), m + Vector2(3, -3), m + Vector2(3, 0.8), m + Vector2(0, 3.8), m + Vector2(-3, 0.8)], e)
			_ln(ci, m + Vector2(-2, -0.6), m + Vector2(0, 1.6), c.darkened(0.6), 1.0)
			_ln(ci, m + Vector2(0, 1.6), m + Vector2(2, -0.6), c.darkened(0.6), 1.0)
		&"tal_cellarer":  # a key
			ci.draw_arc(m + Vector2(-1.6, -1.2), 1.7, 0, TAU, 10, e, 1.2)
			_ln(ci, m + Vector2(-0.4, 0.0), m + Vector2(3.2, 3.2), e, 1.2)
			_ln(ci, m + Vector2(2.0, 2.0), m + Vector2(3.4, 0.8), e, 1.0)
		&"tal_sexton":  # a bent nail
			_ln(ci, m + Vector2(-1.6, -3.2), m + Vector2(1.6, -3.2), e, 1.4)
			_ln(ci, m + Vector2(0, -3.2), m + Vector2(0, 1.4), e, 1.2)
			_ln(ci, m + Vector2(0, 1.4), m + Vector2(2.4, 3.4), e, 1.0)
		&"tal_cinder":  # a flame
			var f := 0.5 * sin(t * 6.0)
			_poly(ci, [m + Vector2(0, -4), m + Vector2(2.6 + f * 0.3, 0.2), m + Vector2(1.6, 3.4), m + Vector2(-1.6, 3.4), m + Vector2(-2.6, 0.2), m + Vector2(-0.6, -1.0)], Color(1.0, 0.6, 0.22))
			_poly(ci, [m + Vector2(0, -0.8), m + Vector2(1.2, 1.6), m + Vector2(0.8, 3.2), m + Vector2(-0.8, 3.2), m + Vector2(-1.2, 1.6)], Color(1.0, 0.92, 0.5))
		&"tal_ashfall":  # a bar across a post
			_ln(ci, m + Vector2(-3.4, -0.4), m + Vector2(3.4, -0.4), e, 1.6)
			_ln(ci, m + Vector2(0, -3.4), m + Vector2(0, 3.6), e, 1.2)
			ci.draw_circle(m + Vector2(0, -0.4), 1.0, c.darkened(0.5))
		&"tal_canon":  # a tear
			_poly(ci, [m + Vector2(0, -3.8), m + Vector2(2.6, 0.6), m + Vector2(1.8, 3.0), m + Vector2(0, 3.8), m + Vector2(-1.8, 3.0), m + Vector2(-2.6, 0.6)], e)
			ci.draw_circle(m + Vector2(-0.8, 0.8), 0.7, Color(1, 1, 1, 0.7))
		&"tal_abbot":  # salt crystals
			for p in [Vector2(-1.8, 1.4), Vector2(1.9, 1.2), Vector2(0, -1.4)]:
				_poly(ci, [m + p + Vector2(0, -2), m + p + Vector2(1.5, 0), m + p + Vector2(0, 2), m + p + Vector2(-1.5, 0)], e)
		&"tal_vess":  # chain links
			ci.draw_arc(m + Vector2(-1.6, -1.0), 2.0, 0, TAU, 10, e, 1.1)
			ci.draw_arc(m + Vector2(1.6, 1.0), 2.0, 0, TAU, 10, e.darkened(0.15), 1.1)
		&"tal_brand":  # an anvil with a spark
			_poly(ci, [m + Vector2(-3.6, -1.6), m + Vector2(3.6, -1.6), m + Vector2(2.2, 0.4), m + Vector2(1.0, 0.4), m + Vector2(1.6, 3.2), m + Vector2(-1.6, 3.2), m + Vector2(-1.0, 0.4), m + Vector2(-2.2, 0.4)], e)
			ci.draw_circle(m + Vector2(2.4 + sin(t * 5.0) * 0.5, -3.0), 0.7, Color(1.0, 0.8, 0.3))
		&"tal_regent":  # a crown
			_poly(ci, [m + Vector2(-3.4, 2.6), m + Vector2(-3.4, -2.4), m + Vector2(-1.6, 0.0), m + Vector2(0, -3.2), m + Vector2(1.6, 0.0), m + Vector2(3.4, -2.4), m + Vector2(3.4, 2.6)], e)
			ci.draw_rect(Rect2(m + Vector2(-3.4, 1.6), Vector2(6.8, 1.0)), c.darkened(0.45))
		&"tal_ringer":  # a bellflower
			for a in 5:
				var d := Vector2.from_angle(a * TAU / 5.0 - PI / 2.0)
				ci.draw_circle(m + d * 2.2, 1.5, e)
			ci.draw_circle(m, 1.3, c.darkened(0.5))
		&"tal_thornmother":  # a seed with thorns
			ci.draw_circle(m, 2.2, e)
			for a in 6:
				var d := Vector2.from_angle(a * TAU / 6.0 + 0.3)
				_ln(ci, m + d * 2.0, m + d * 3.8, e, 0.9)
		&"tal_orrerist":  # a gear
			var rot := t * 0.6
			for a in 8:
				var d := Vector2.from_angle(a * TAU / 8.0 + rot)
				_ln(ci, m + d * 2.2, m + d * 3.6, e, 1.2)
			ci.draw_circle(m, 2.6, e)
			ci.draw_circle(m, 1.0, c.darkened(0.6))
		&"tal_bishop":  # a wafer with a cross
			ci.draw_circle(m, 3.4, e)
			_ln(ci, m + Vector2(0, -2.2), m + Vector2(0, 2.2), c.darkened(0.55), 1.0)
			_ln(ci, m + Vector2(-2.2, 0), m + Vector2(2.2, 0), c.darkened(0.55), 1.0)
		&"tal_king":  # a four-pointed star over a hollow ring
			ci.draw_arc(m, 3.6, 0, TAU, 14, e.darkened(0.2), 0.8)
			_poly(ci, [m + Vector2(0, -3.8), m + Vector2(0.9, -0.9), m + Vector2(3.8, 0), m + Vector2(0.9, 0.9), m + Vector2(0, 3.8), m + Vector2(-0.9, 0.9), m + Vector2(-3.8, 0), m + Vector2(-0.9, -0.9)], Color(1, 1, 1))
		&"tal_iron_bead":
			ci.draw_circle(m, 2.8, e.darkened(0.25))
			ci.draw_circle(m + Vector2(-0.8, -0.8), 1.0, e.lightened(0.4))
			ci.draw_circle(m, 0.7, c.darkened(0.7))
		&"tal_swift_feather":
			_poly(ci, [m + Vector2(-2.6, 3.2), m + Vector2(-1.6, -1.0), m + Vector2(1.4, -3.8), m + Vector2(3.0, -2.6), m + Vector2(1.6, 0.6), m + Vector2(-1.2, 2.6)], e)
			_ln(ci, m + Vector2(-2.8, 3.4), m + Vector2(1.8, -2.6), c.darkened(0.5), 0.8)
		&"tal_ember_bead":
			ci.draw_circle(m, 2.8, Color(1.0, 0.66, 0.2))
			ci.draw_circle(m + Vector2(0.4, 0.4), 1.4, Color(1.0, 0.9, 0.5, 0.6 + 0.4 * sin(t * 4.0)))
		&"tal_mender":  # needle and thread
			_ln(ci, m + Vector2(-3, 3), m + Vector2(3, -3), e, 0.9)
			ci.draw_arc(m + Vector2(0.6, 1.4), 2.4, PI * 0.9, PI * 2.1, 8, Color(1.0, 0.4, 0.4), 1.0)
		&"tal_keen_edge":  # whetstone
			_poly(ci, [m + Vector2(-3.6, 0.8), m + Vector2(-1.2, -2.4), m + Vector2(3.6, -0.6), m + Vector2(1.2, 2.6)], e.darkened(0.15))
			_ln(ci, m + Vector2(-2.2, -0.4), m + Vector2(2.0, 0.2), Color(1, 1, 1, 0.8), 0.7)
		&"tal_hardy":  # a knot
			ci.draw_arc(m + Vector2(-1.2, 0), 2.2, 0, TAU, 10, e, 1.3)
			ci.draw_arc(m + Vector2(1.2, 0), 2.2, 0, TAU, 10, e.darkened(0.15), 1.3)
		&"tal_steady":  # a pebble with ripples
			ci.draw_circle(m + Vector2(0, -0.6), 1.9, e)
			ci.draw_arc(m + Vector2(0, 1.0), 3.2, 0.3, PI - 0.3, 8, e.darkened(0.2), 0.8)
			ci.draw_arc(m + Vector2(0, 2.0), 3.8, 0.4, PI - 0.4, 8, e.darkened(0.35), 0.8)
		_:
			_generic(ci, id, e, c, t)


## Emblems for the generated (expansion) talismans: one of eight shapes picked from the id.
static func _generic(ci: CanvasItem, id: StringName, e: Color, c: Color, t: float) -> void:
	var m := M
	var k := absi(String(id).hash()) % 8
	match k:
		0:  # eight-point star
			var pts := []
			for i in 16:
				pts.append(m + Vector2.from_angle(i * TAU / 16.0 - PI / 2.0) * (3.8 if i % 2 == 0 else 1.6))
			_poly(ci, pts, e)
		1:  # diamond
			_poly(ci, [m + Vector2(0, -3.8), m + Vector2(3.0, 0), m + Vector2(0, 3.8), m + Vector2(-3.0, 0)], e)
			_poly(ci, [m + Vector2(0, -1.6), m + Vector2(1.2, 0), m + Vector2(0, 1.6), m + Vector2(-1.2, 0)], c.darkened(0.5))
		2:  # triangle with an eye
			_poly(ci, [m + Vector2(0, -3.8), m + Vector2(3.6, 2.8), m + Vector2(-3.6, 2.8)], e)
			ci.draw_circle(m + Vector2(0, 0.8), 0.9, c.darkened(0.6))
		3:  # crescent
			ci.draw_circle(m, 3.4, e)
			ci.draw_circle(m + Vector2(1.5, -0.6), 2.9, c.darkened(0.45))
		4:  # cross
			_ln(ci, m + Vector2(0, -3.6), m + Vector2(0, 3.6), e, 1.6)
			_ln(ci, m + Vector2(-3.0, -0.8), m + Vector2(3.0, -0.8), e, 1.6)
		5:  # spiral
			var prev := m
			for i in 20:
				var a := i * 0.55
				var p := m + Vector2.from_angle(a) * (0.4 + i * 0.17)
				ci.draw_line(prev, p, e, 1.1)
				prev = p
		6:  # hexagon with a dot
			var hp := []
			for i in 6:
				hp.append(m + Vector2.from_angle(i * TAU / 6.0) * 3.6)
			_poly(ci, hp, e)
			ci.draw_circle(m, 1.2, c.darkened(0.55))
		_:  # eye
			_poly(ci, [m + Vector2(-3.8, 0), m + Vector2(0, -2.6), m + Vector2(3.8, 0), m + Vector2(0, 2.6)], e)
			ci.draw_circle(m, 1.3 + 0.2 * sin(t * 3.0), c.darkened(0.6))
