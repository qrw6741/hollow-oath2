@tool
class_name ManorHall
extends Node2D
## TEMPORARY ART (procedural): the great hall of Hollowmere Manor as a backdrop - panelled
## walls, tall moonlit windows, portraits whose painted eyes catch the light, chandeliers,
## a grandfather clock, suits of armour with faint eyes, bookshelves, cobwebs - and a few
## gentle ghosts drifting through. Everything is drawn from [member seed_value], so the hall is
## the same every time.

@export var width := 2500.0:
	set(v): width = v; queue_redraw()
@export var floor_y := 480.0:
	set(v): floor_y = v; queue_redraw()
@export var ceiling_y := 96.0:
	set(v): ceiling_y = v; queue_redraw()
@export var seed_value := 9:
	set(v): seed_value = v; queue_redraw()
@export var ghosts := 6
## HALL: the great hall. CELLAR: brick vaults, casks and racks, hanging lanterns.
## GALLERY: portraits and glass cases, no windows.
enum Style { HALL, CELLAR, GALLERY }
@export var style := Style.HALL:
	set(v): style = v; queue_redraw()

var _t := 0.0
var _rng_ghost: Array = []


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 7 + 1
	for i in ghosts:
		_rng_ghost.append({
			"x": r.randf_range(160.0, width - 160.0), "y": r.randf_range(floor_y - 150.0, floor_y - 60.0),
			"speed": r.randf_range(0.12, 0.3), "phase": r.randf() * TAU, "scale": r.randf_range(0.8, 1.25),
			"range": r.randf_range(60.0, 160.0)})
	if not Engine.is_editor_hint():
		_add_lights()


## Real light from the chandeliers and the windows' moon-glow.
func _add_lights() -> void:
	var x := 300.0
	while x < width - 200.0:
		var l := PointLight2D.new()
		l.texture = LightTex.radial()
		l.texture_scale = 2.6
		l.color = Color(1.0, 0.82, 0.55)
		l.energy = 0.55
		l.position = Vector2(x, ceiling_y + 70.0)
		add_child(l)
		x += 520.0
	x = 160.0
	while x < width - 100.0:
		var m := PointLight2D.new()
		m.texture = LightTex.radial()
		m.texture_scale = 2.2
		m.color = Color(0.6, 0.72, 1.0)
		m.energy = 0.28
		m.position = Vector2(x, floor_y - 150.0)
		add_child(m)
		x += 520.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## First and last map x that are on screen (plus a margin). Everything below only draws this range:
## the old version drew the whole 5,000+ px hall every frame (about 9,000 draw calls).
var _vx0 := 0.0
var _vx1 := 960.0


func _update_view() -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		_vx0 = 0.0
		_vx1 = width
		return
	var vr := get_viewport_rect()
	var inv := get_canvas_transform().affine_inverse()
	_vx0 = maxf(0.0, (inv * vr.position).x - 60.0)
	_vx1 = minf(width, (inv * vr.end).x + 60.0)


## A random generator that depends only on a position, so culled drawing looks the same everywhere.
func _rng_at(x: float, salt := 0) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = (int(x) * 7919 + salt * 104729 + seed_value * 31) & 0x7fffffff
	return r


func _draw() -> void:
	_update_view()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if style == Style.CELLAR:
		_draw_cellar(rng)
		_draw_ghosts()
		return
	_draw_walls()
	# Windows every 260 px, portraits between them.
	var i := maxi(0, int((_vx0 - 130.0) / 130.0) - 1)
	var x := 130.0 + 130.0 * i
	while x < _vx1 + 130.0 and x < width:
		var r := _rng_at(x)
		if i % 2 == 0 and style == Style.HALL:
			_draw_window(x, r)
		elif i % 2 == 0:
			_draw_case(x)
		else:
			_draw_portrait(x, r)
		x += 130.0
		i += 1
	_draw_furniture()
	for k in range(maxi(0, int((_vx0 - 330.0) / 520.0)), mini(int(width / 520.0), int((_vx1 + 330.0) / 520.0)) + 1):
		if style == Style.GALLERY and k % 2 == 1:
			continue
		_draw_chandelier(300.0 + k * 520.0 + 30.0 * sin(float(k)))
	_draw_ghosts()
	_draw_cobwebs()


func _draw_walls() -> void:
	var x0 := _vx0 - 40.0
	var w := _vx1 - _vx0 + 80.0
	draw_rect(Rect2(x0, ceiling_y - 70, w, floor_y - ceiling_y + 70), Color("2b2535"))
	# Faint vertical wallpaper stripes
	var x := floorf(_vx0 / 44.0) * 44.0
	while x < _vx1:
		draw_rect(Rect2(x, ceiling_y, 22, floor_y - ceiling_y), Color(0.17, 0.14, 0.22, 0.45))
		x += 44.0
	# Wainscot (lower panelled wall)
	var top := floor_y - 96.0
	draw_rect(Rect2(x0, top, w, 96), Color("33271f"))
	draw_rect(Rect2(x0, top, w, 4), Color("4a382b"))
	x = 20.0 + floorf(maxf(0.0, _vx0 - 20.0) / 96.0) * 96.0
	while x < _vx1:
		draw_rect(Rect2(x, top + 12, 70, 72), Color("2b2019"))
		draw_rect(Rect2(x + 3, top + 15, 64, 66), Color("372a21"), false, 1.0)
		x += 96.0
	# Crown moulding and a dark ceiling
	draw_rect(Rect2(x0, ceiling_y - 70, w, 62), Color("15121b"))
	draw_rect(Rect2(x0, ceiling_y - 10, w, 10), Color("3b3046"))
	draw_rect(Rect2(x0, ceiling_y, w, 3), Color("55466a"))
	# Ceiling beams
	x = 60.0 + floorf(maxf(0.0, _vx0 - 60.0) / 260.0) * 260.0
	while x < _vx1:
		draw_rect(Rect2(x, ceiling_y - 62, 12, 54), Color("241d2d"))
		x += 260.0


func _draw_window(cx: float, rng: RandomNumberGenerator) -> void:
	var w := 46.0
	var top := ceiling_y + 28.0
	var bottom := floor_y - 108.0
	# Moon-beam on the floor side, fading
	var beam := PackedVector2Array([Vector2(cx - w / 2.0, top + 20), Vector2(cx + w / 2.0, top + 20), Vector2(cx + w + 40, floor_y), Vector2(cx - w - 10, floor_y)])
	draw_colored_polygon(beam, Color(0.65, 0.75, 1.0, 0.045 + 0.015 * sin(_t * 0.7 + cx)))
	var pts := PackedVector2Array()
	pts.append(Vector2(cx - w / 2.0, bottom))
	pts.append(Vector2(cx - w / 2.0, top + w / 2.0))
	for a in range(0, 9):
		var an := PI + PI * a / 8.0
		pts.append(Vector2(cx, top + w / 2.0) + Vector2(cos(an), sin(an)) * (w / 2.0))
	pts.append(Vector2(cx + w / 2.0, bottom))
	draw_colored_polygon(pts, Color(0.32, 0.4, 0.62, 0.95))
	draw_colored_polygon(pts, Color(0.7, 0.8, 1.0, 0.12))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color("120f18"), 2.5)
	draw_line(Vector2(cx, top), Vector2(cx, bottom), Color("120f18"), 1.8)
	for y in [top + 34.0, top + 70.0]:
		draw_line(Vector2(cx - w / 2.0, y), Vector2(cx + w / 2.0, y), Color("120f18"), 1.5)
	# A cold star or two
	draw_circle(Vector2(cx - 8, top + 24), 0.8, Color(1, 1, 1, 0.7))
	draw_circle(Vector2(cx + 9, top + 52 + rng.randf() * 6.0), 0.7, Color(1, 1, 1, 0.5))


func _draw_portrait(cx: float, rng: RandomNumberGenerator) -> void:
	var w := 40.0
	var h := 56.0
	var y := floor_y - 230.0
	draw_rect(Rect2(cx - w / 2.0 - 4, y - 4, w + 8, h + 8), Color("5c4630"))
	draw_rect(Rect2(cx - w / 2.0 - 2, y - 2, w + 4, h + 4), Color("2a1f15"))
	draw_rect(Rect2(cx - w / 2.0, y, w, h), Color(0.12 + rng.randf() * 0.05, 0.1, 0.14))
	var kind := rng.randi_range(0, 3)
	if kind == 3:
		# An empty frame: someone has stepped out of it
		draw_line(Vector2(cx - w / 2.0, y + h), Vector2(cx + w / 2.0, y), Color(1, 1, 1, 0.03), 1.0)
		return
	# A sitter: dark robe, pale face, two points of light that follow the weather
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 15, y + h), Vector2(cx - 9, y + 30), Vector2(cx + 9, y + 30), Vector2(cx + 15, y + h)]), Color(0.2, 0.17, 0.24))
	draw_circle(Vector2(cx, y + 22), 8.0, Color(0.55, 0.52, 0.5))
	var glint := 0.45 + 0.4 * (0.5 + 0.5 * sin(_t * 0.9 + cx * 0.1))
	draw_circle(Vector2(cx - 3, y + 21), 0.9, Color(1.0, 0.95, 0.7, glint))
	draw_circle(Vector2(cx + 3, y + 21), 0.9, Color(1.0, 0.95, 0.7, glint))


func _draw_furniture() -> void:
	# Suits of armour on plinths every 620 px
	var x := 60.0 + floorf(maxf(0.0, _vx0 - 80.0) / 620.0) * 620.0
	while x < _vx1:
		_draw_armour(x + 20.0)
		x += 620.0
	# Bookshelves
	var bx := 760.0 + floorf(maxf(0.0, _vx0 - 880.0) / 940.0) * 940.0
	while bx < width - 200.0 and bx < _vx1:
		_draw_bookshelf(bx, _rng_at(bx, 3))
		bx += 940.0
	# Grandfather clock
	if 1180.0 > _vx0 - 40.0 and 1180.0 < _vx1 + 40.0:
		_draw_clock(1180.0)


func _draw_armour(x: float) -> void:
	draw_rect(Rect2(x - 9, floor_y - 18, 18, 18), Color("221b26"))
	var steel := Color("5a5f6e")
	draw_rect(Rect2(x - 6, floor_y - 52, 12, 34), steel)
	draw_circle(Vector2(x, floor_y - 58), 6.0, Color("6a7080"))
	draw_rect(Rect2(x - 9, floor_y - 48, 18, 8), Color("4a4f5c"))
	draw_line(Vector2(x - 10, floor_y - 46), Vector2(x - 12, floor_y - 18), Color("4a4f5c"), 3.0)
	draw_line(Vector2(x + 10, floor_y - 46), Vector2(x + 14, floor_y - 62), Color("8a8f9a"), 1.2)
	var glow := 0.5 + 0.5 * sin(_t * 1.4 + x)
	draw_rect(Rect2(x - 3.5, floor_y - 59, 2, 1.4), Color(0.6, 0.85, 1.0, 0.3 + 0.5 * glow))
	draw_rect(Rect2(x + 1.5, floor_y - 59, 2, 1.4), Color(0.6, 0.85, 1.0, 0.3 + 0.5 * glow))


func _draw_bookshelf(x: float, rng: RandomNumberGenerator) -> void:
	var w := 120.0
	var top := floor_y - 130.0
	draw_rect(Rect2(x, top, w, 130), Color("231a14"))
	draw_rect(Rect2(x, top, w, 130), Color("4a382b"), false, 2.0)
	for row in 4:
		var y := top + 6.0 + row * 31.0
		draw_rect(Rect2(x + 2, y + 25, w - 4, 3), Color("3a2c20"))
		var bxp := x + 5.0
		while bxp < x + w - 8.0:
			var bw := rng.randf_range(4.0, 9.0)
			var bh := rng.randf_range(15.0, 24.0)
			var hue := rng.randf()
			draw_rect(Rect2(bxp, y + 25.0 - bh, bw, bh), Color.from_hsv(hue * 0.15 + 0.02, 0.45, 0.28 + rng.randf() * 0.12))
			bxp += bw + 0.6


func _draw_clock(x: float) -> void:
	draw_rect(Rect2(x - 16, floor_y - 120, 32, 120), Color("2f2118"))
	draw_rect(Rect2(x - 16, floor_y - 120, 32, 120), Color("5c4630"), false, 2.0)
	draw_circle(Vector2(x, floor_y - 98), 11.0, Color("c9c2a8"))
	draw_circle(Vector2(x, floor_y - 98), 11.0, Color("1a1410"), false, 1.5)
	draw_line(Vector2(x, floor_y - 98), Vector2(x, floor_y - 106), Color("1a1410"), 1.2)
	draw_line(Vector2(x, floor_y - 98), Vector2(x + 6, floor_y - 95), Color("1a1410"), 1.0)
	draw_rect(Rect2(x - 9, floor_y - 74, 18, 52), Color("120d09"))
	var sw := sin(_t * 2.6) * 5.0
	draw_line(Vector2(x, floor_y - 74), Vector2(x + sw, floor_y - 34), Color("a08a52"), 1.2)
	draw_circle(Vector2(x + sw, floor_y - 33), 4.0, Color("c0a35a"))


func _draw_chandelier(x: float) -> void:
	var y := ceiling_y + 62.0
	draw_line(Vector2(x, ceiling_y - 8), Vector2(x, y - 6), Color("2a2430"), 1.5)
	draw_arc(Vector2(x, y), 22.0, 0.2, PI - 0.2, 12, Color("6a5a3a"), 2.0)
	draw_line(Vector2(x - 22, y), Vector2(x + 22, y), Color("6a5a3a"), 2.0)
	for k in 5:
		var cx := x - 20.0 + k * 10.0
		draw_rect(Rect2(cx - 1.5, y - 7, 3, 7), Color("d9d0b8"))
		var fl := 0.75 + 0.25 * sin(_t * 8.0 + k * 1.7 + x)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 1.4, y - 7), Vector2(cx, y - 12 - fl * 2.0), Vector2(cx + 1.4, y - 7)]), Color(1.0, 0.82, 0.45, 0.95))
		draw_circle(Vector2(cx, y - 9), 6.0, Color(1.0, 0.8, 0.4, 0.05 * fl))


func _draw_ghosts() -> void:
	for g in _rng_ghost:
		var gx: float = g.x + sin(_t * g.speed + g.phase) * g.range
		var gy: float = g.y + sin(_t * g.speed * 1.7 + g.phase) * 14.0
		var s: float = g.scale
		var face := 1.0 if cos(_t * g.speed + g.phase) > 0.0 else -1.0
		var a := 0.16 + 0.07 * sin(_t * 1.3 + g.phase)
		var col := Color(0.75, 0.85, 1.0, a)
		# Gown: a rounded head and a tail that trails off in waves
		draw_circle(Vector2(gx, gy - 18 * s), 6.0 * s, col)
		var pts := PackedVector2Array([Vector2(gx - 8 * s, gy - 16 * s), Vector2(gx + 8 * s, gy - 16 * s)])
		for k in 5:
			var f := float(k) / 4.0
			pts.append(Vector2(gx + 8 * s - f * 16 * s + sin(_t * 3.0 + f * 5.0 + g.phase) * 2.5 * s, gy + 6 * s * (1.0 + (k % 2) * 0.4)))
		draw_colored_polygon(pts, col)
		draw_circle(Vector2(gx + 2.0 * s * face, gy - 18 * s), 0.9 * s, Color(0.1, 0.12, 0.25, a * 4.0))
		draw_circle(Vector2(gx - 2.5 * s * face, gy - 18 * s), 0.9 * s, Color(0.1, 0.12, 0.25, a * 4.0))


func _draw_cobwebs() -> void:
	for cx in [0.0, width]:
		if cx < _vx0 - 100.0 or cx > _vx1 + 100.0:
			continue
		var dir := 1.0 if cx == 0.0 else -1.0
		for k in 4:
			var r := 30.0 + k * 14.0
			draw_arc(Vector2(cx, ceiling_y), r, 0.0 if dir > 0.0 else PI / 2.0, PI / 2.0 if dir > 0.0 else PI, 6, Color(0.8, 0.82, 0.9, 0.12), 0.8)
		for a in [0.2, 0.7, 1.2]:
			var ang: float = a if dir > 0.0 else PI - a
			draw_line(Vector2(cx, ceiling_y), Vector2(cx, ceiling_y) + Vector2.from_angle(ang) * 74.0, Color(0.8, 0.82, 0.9, 0.12), 0.8)


func _draw_case(cx: float) -> void:
	# A glass display case on a plinth holding a small, pale object.
	var w := 44.0
	var top := floor_y - 190.0
	draw_rect(Rect2(cx - w / 2.0, top + 70, w, 120), Color("2a2030"))
	draw_rect(Rect2(cx - w / 2.0 + 3, top + 6, w - 6, 70), Color(0.55, 0.65, 0.85, 0.12))
	draw_rect(Rect2(cx - w / 2.0 + 3, top + 6, w - 6, 70), Color("55466a"), false, 1.5)
	draw_rect(Rect2(cx - 7, top + 46, 14, 4), Color("7a6a4a"))
	draw_circle(Vector2(cx, top + 40), 5.0, Color(0.85, 0.82, 0.7, 0.8))
	draw_circle(Vector2(cx, top + 40), 14.0, Color(0.9, 0.9, 1.0, 0.05 + 0.02 * sin(_t * 1.2 + cx)))


func _draw_cellar(_rng: RandomNumberGenerator) -> void:
	var x0 := _vx0 - 40.0
	var w := _vx1 - _vx0 + 80.0
	draw_rect(Rect2(x0, ceiling_y - 70, w, floor_y - ceiling_y + 70), Color(0.04, 0.03, 0.04))   # the mortar
	# Brick courses (only the ones on screen; each brick's shade comes from its position)
	var y := ceiling_y - 60.0
	var row := 0
	while y < floor_y:
		var x := -40.0 + (row % 2) * 18.0
		x += floorf((x0 - x) / 36.0) * 36.0
		while x < _vx1 + 40.0:
			var shade := 0.10 + _hash01(x, y) * 0.05
			draw_rect(Rect2(x, y, 34, 14), Color(shade + 0.07, shade + 0.03, shade + 0.03))
			x += 36.0
		y += 16.0
		row += 1
	# Vault arches
	var ax := floorf(maxf(0.0, _vx0 - 300.0) / 300.0) * 300.0
	while ax < _vx1 and ax < width:
		draw_arc(Vector2(ax + 150, ceiling_y + 30), 140.0, PI, TAU, 18, Color("0d0b0e"), 6.0)
		draw_rect(Rect2(ax + 4, ceiling_y + 30, 10, floor_y - ceiling_y - 30), Color("0d0b0e"))
		ax += 300.0
	# Casks, racks and crates, one per 170 px slot (kind and offset from the slot's position)
	var k := maxi(0, int((_vx0 - 60.0) / 170.0) - 1)
	while 120.0 + k * 170.0 < _vx1 + 60.0 and 120.0 + k * 170.0 < width - 100.0:
		var cx := 120.0 + k * 170.0
		var r := _rng_at(cx, 5)
		cx += r.randf_range(-30.0, 30.0)
		var kind := r.randi_range(0, 3)
		if kind == 0:
			_draw_cask(cx, r)
		elif kind == 1:
			_draw_rack(cx)
		elif kind == 2:
			draw_rect(Rect2(cx - 14, floor_y - 28, 28, 28), Color("3b2d20"))
			draw_rect(Rect2(cx - 14, floor_y - 28, 28, 28), Color("1a120c"), false, 1.5)
			draw_line(Vector2(cx - 14, floor_y - 28), Vector2(cx + 14, floor_y), Color("1a120c"), 1.2)
		k += 1
	# Hanging lanterns
	var lx := 220.0 + floorf(maxf(0.0, _vx0 - 220.0) / 420.0) * 420.0
	while lx < _vx1 and lx < width:
		var sway := sin(_t * 1.1 + lx) * 1.5
		draw_line(Vector2(lx, ceiling_y - 8), Vector2(lx + sway, ceiling_y + 40), Color("2a2430"), 1.0)
		draw_rect(Rect2(lx + sway - 4, ceiling_y + 40, 8, 10), Color("6a5a3a"))
		draw_circle(Vector2(lx + sway, ceiling_y + 45), 3.0 + 0.6 * sin(_t * 9.0 + lx), Color(1.0, 0.75, 0.4, 0.95))
		draw_circle(Vector2(lx + sway, ceiling_y + 45), 18.0, Color(1.0, 0.7, 0.3, 0.05))
		lx += 420.0
	draw_rect(Rect2(x0, ceiling_y - 10, w, 12), Color("0d0b0e"))


func _hash01(x: float, y: float) -> float:
	var h := int(x * 73.0 + y * 151.0) * 2654435761 + seed_value * 40503
	return float((h >> 8) & 0xffff) / 65535.0


func _draw_cask(x: float, rng: RandomNumberGenerator) -> void:
	var h := rng.randf_range(34.0, 50.0)
	draw_rect(Rect2(x - 20, floor_y - h, 40, h), Color("4a3524"))
	draw_rect(Rect2(x - 20, floor_y - h, 40, h), Color("1a120c"), false, 1.5)
	for yy in [floor_y - h * 0.8, floor_y - h * 0.2]:
		draw_line(Vector2(x - 20, yy), Vector2(x + 20, yy), Color("6a6a70"), 2.0)
	draw_circle(Vector2(x, floor_y - h * 0.5), 3.0, Color("1a120c"))


func _draw_rack(x: float) -> void:
	draw_rect(Rect2(x - 30, floor_y - 90, 60, 90), Color("2a1f17"))
	draw_rect(Rect2(x - 30, floor_y - 90, 60, 90), Color("4a3524"), false, 2.0)
	for r in 4:
		for c in 4:
			var bx := x - 24 + c * 14
			var by := floor_y - 80 + r * 20
			draw_circle(Vector2(bx + 4, by + 6), 5.0, Color("14221a") if (r + c) % 3 else Color("2a1a2a"))
