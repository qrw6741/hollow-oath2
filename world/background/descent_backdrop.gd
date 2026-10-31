@tool
class_name DescentBackdrop
extends Node2D
## TEMPORARY ART (procedural): a distinct, layered, parallax backdrop for each map of the Descent.
## Two silhouette layers + floor haze + ambient particles + soft flickering lights, all drawn only
## for the part of the map on screen, from a per-slot seed so it is identical every time.
## Replaces the manor hall in the eleven Descent maps.

enum Look { OSSUARY, TALLOW, ARCHIVE, ORCHARD, MARKET, VAULTS, GALLERY, FORGE, CLOISTER, BARROW, HEART }

@export var theme: Look = Look.OSSUARY:
	set(v): theme = v; queue_redraw()
@export var width := 7400.0
@export var floor_y := 480.0
@export var ceiling_y := 96.0
@export var seed_value := 1

## top, bottom (wall gradient), far silhouette, near silhouette, glow / accent, particle colour
const PAL := [
	[Color("1c1a18"), Color("342e26"), Color("2a2620"), Color("3c352b"), Color("e8dcc0"), Color("d8d0b8")],  # ossuary
	[Color("1e1408"), Color("46280e"), Color("33200e"), Color("523212"), Color("ffb050"), Color("ffcc70")],  # tallow
	[Color("181410"), Color("3a2e18"), Color("2c2212"), Color("46361a"), Color("f0d888"), Color("f4e8b8")],  # archive
	[Color("0c1410"), Color("1c3020"), Color("14241a"), Color("1e3626"), Color("a8d890"), Color("d8f0a0")],  # orchard
	[Color("1c1210"), Color("3c2418"), Color("2c1c14"), Color("48301e"), Color("ffc070"), Color("f0d0a0")],  # market
	[Color("0a1420"), Color("14304a"), Color("0e2236"), Color("183a58"), Color("80d0f0"), Color("a8e4ff")],  # vaults
	[Color("14101c"), Color("2a2440"), Color("201a30"), Color("302848"), Color("d8d0ff"), Color("f0eaff")],  # gallery
	[Color("1c0c08"), Color("4a1c0c"), Color("361408"), Color("56220e"), Color("ff7030"), Color("ffa850")],  # forge
	[Color("10161c"), Color("243440"), Color("1a2630"), Color("2c4050"), Color("e8f4ff"), Color("ffffff")],  # cloister
	[Color("12101a"), Color("26223a"), Color("1c182c"), Color("2e2842"), Color("e0c860"), Color("c8c0e8")],  # barrow
	[Color("1c0810"), Color("4a1424"), Color("340c18"), Color("5a1a2c"), Color("ff5070"), Color("ff8090")],  # heart
]

var _t := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		_add_lights()


func _add_lights() -> void:
	var pal: Array = PAL[theme]
	var x := 260.0
	var i := 0
	while x < width - 200.0:
		var l := PointLight2D.new()
		l.texture = LightTex.radial()
		l.texture_scale = 2.4
		l.color = pal[4]
		l.energy = 0.42
		l.position = Vector2(x, floor_y - 120.0 - 40.0 * float(i % 3))
		l.set_meta("phase", float(i) * 1.7)
		add_child(l)
		x += 560.0
		i += 1


func _process(delta: float) -> void:
	_t += delta
	if not Engine.is_editor_hint():
		for c in get_children():
			if c is PointLight2D:
				var ph: float = float(c.get_meta("phase", 0.0))
				var pulse := 0.5 + 0.5 * sin(_t * 1.6 + ph)
				if theme == Look.HEART:
					pulse = pow(maxf(0.0, sin(_t * 2.2 + ph * 0.1)), 6.0)
				c.energy = 0.3 + 0.28 * pulse
	queue_redraw()


func _view() -> Rect2:
	if Engine.is_editor_hint() or not is_inside_tree():
		return Rect2(0, 0, 960, 540)
	var vr := get_viewport_rect()
	var inv := get_canvas_transform().affine_inverse()
	var tl: Vector2 = inv * vr.position
	var br: Vector2 = inv * vr.end
	return Rect2(tl, br - tl)


func _draw() -> void:
	var pal: Array = PAL[theme]
	var v := _view()
	var x0 := maxf(0.0, v.position.x - 40.0)
	var x1 := minf(width, v.end.x + 40.0)
	# wall gradient, in bands
	var bands := 14
	for b in bands:
		var y := ceiling_y + (floor_y - ceiling_y) * float(b) / float(bands)
		var h := (floor_y - ceiling_y) / float(bands) + 1.0
		draw_rect(Rect2(x0, y, x1 - x0, h), (pal[0] as Color).lerp(pal[1], float(b) / float(bands - 1)))
	_shafts(v, pal)
	_layer(v, pal, 0.45, 0.8, pal[2], 1)
	_layer(v, pal, 0.75, 1.0, pal[3], 2)
	_haze(v, pal)
	_particles(v, pal)


## One silhouette layer. p = parallax factor (1 = moves with the world).
func _layer(v: Rect2, pal: Array, p: float, sc: float, col: Color, salt: int) -> void:
	var slot := 150.0 * sc
	var cam := v.position.x + v.size.x * 0.5
	var ux0 := (v.position.x - cam * (1.0 - p)) / p - slot
	var ux1 := (v.end.x - cam * (1.0 - p)) / p + slot
	var s := int(floorf(maxf(ux0, -slot) / slot))
	var e := int(ceilf(minf(ux1, width / p) / slot))
	for k in range(s, e + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = (k * 7919 + salt * 104729 + seed_value * 31) & 0x7fffffff
		var ux := float(k) * slot + rng.randf_range(0.0, slot * 0.4)
		var wx := ux * p + cam * (1.0 - p)
		_shape(Vector2(wx, floor_y), rng, sc, col, pal, salt)


func _poly(pts: Array, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), col)


func _shape(o: Vector2, rng: RandomNumberGenerator, sc: float, col: Color, pal: Array, salt: int) -> void:
	var glow: Color = pal[4]
	var h := rng.randf_range(0.6, 1.0)
	var flick := 0.6 + 0.4 * sin(_t * 3.0 + o.x * 0.01)
	match theme:
		Look.OSSUARY:  # arches of stacked skull niches and rib-columns
			var w := 70.0 * sc
			var top := o.y - (170.0 + 70.0 * h) * sc
			draw_rect(Rect2(o.x, top + 30.0, 12.0 * sc, o.y - top - 30.0), col)
			draw_rect(Rect2(o.x + w, top + 30.0, 12.0 * sc, o.y - top - 30.0), col)
			draw_arc(Vector2(o.x + w * 0.5 + 6.0, top + 36.0), w * 0.5 + 6.0, PI, TAU, 14, col, 10.0 * sc)
			for r in 4:
				for c in 2:
					draw_circle(Vector2(o.x + 24.0 * sc + c * 22.0 * sc, o.y - (30.0 + r * 26.0) * sc), 7.0 * sc, col.lightened(0.12))
		Look.TALLOW:  # wax stalagmites with candle flames
			var hh := (60.0 + 100.0 * h) * sc
			_poly([Vector2(o.x, o.y), Vector2(o.x + 16.0 * sc, o.y - hh), Vector2(o.x + 34.0 * sc, o.y)], col)
			if rng.randf() < 0.5:
				draw_circle(Vector2(o.x + 16.0 * sc, o.y - hh - 4.0), 3.0 * sc * flick, Color(glow, 0.8))
				draw_circle(Vector2(o.x + 16.0 * sc, o.y - hh - 4.0), 9.0 * sc, Color(glow, 0.12 * flick))
			var dh := (40.0 + 80.0 * rng.randf()) * sc
			_poly([Vector2(o.x + 20.0, ceiling_y), Vector2(o.x + 30.0, ceiling_y + dh), Vector2(o.x + 40.0, ceiling_y)], col)
		Look.ARCHIVE:  # bookcases
			var bw := 56.0 * sc
			var bh := (200.0 + 90.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - bh, bw, bh), col)
			for r in int(bh / (22.0 * sc)):
				var by := o.y - bh + r * 22.0 * sc + 4.0
				draw_line(Vector2(o.x + 3.0, by), Vector2(o.x + bw - 3.0, by), col.lightened(0.14), 2.0)
				for b in 5:
					if rng.randf() < 0.7:
						draw_rect(Rect2(o.x + 5.0 + b * 10.0 * sc, by - 12.0 * sc, 6.0 * sc, 12.0 * sc), col.lightened(0.06 + 0.1 * rng.randf()))
		Look.ORCHARD:  # twisted trees with pale fruit
			var th := (150.0 + 100.0 * h) * sc
			draw_line(o, o + Vector2(rng.randf_range(-10.0, 10.0), -th), col, 9.0 * sc)
			for b in 4:
				var a := -PI / 2.0 + rng.randf_range(-1.1, 1.1)
				var base := o + Vector2(0, -th * (0.4 + 0.15 * b))
				var tip := base + Vector2.from_angle(a) * (50.0 + 40.0 * rng.randf()) * sc
				draw_line(base, tip, col, 5.0 * sc)
				if rng.randf() < 0.6:
					draw_circle(tip + Vector2(0, 6.0), 4.0 * sc, Color(glow, 0.55))
		Look.MARKET:  # stalls with awnings and hanging lanterns
			var sw := 90.0 * sc
			var sh := (90.0 + 40.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - sh, 4.0, sh), col)
			draw_rect(Rect2(o.x + sw, o.y - sh, 4.0, sh), col)
			_poly([Vector2(o.x - 8.0, o.y - sh), Vector2(o.x + sw + 12.0, o.y - sh), Vector2(o.x + sw, o.y - sh + 22.0 * sc), Vector2(o.x, o.y - sh + 22.0 * sc)], col.lightened(0.1))
			draw_rect(Rect2(o.x, o.y - 34.0 * sc, sw, 6.0), col)
			draw_circle(Vector2(o.x + sw * 0.5, o.y - sh + 34.0 * sc), 3.0 * sc, Color(glow, 0.7 * flick))
			draw_circle(Vector2(o.x + sw * 0.5, o.y - sh + 34.0 * sc), 10.0 * sc, Color(glow, 0.1 * flick))
		Look.VAULTS:  # drowned pillars and arches
			var pw := 22.0 * sc
			var ph := (230.0 + 80.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - ph, pw, ph), col)
			draw_arc(Vector2(o.x + 60.0 * sc, o.y - ph + 4.0), 60.0 * sc, PI, TAU, 14, col, 9.0 * sc)
			draw_rect(Rect2(o.x - 4.0, o.y - 14.0, pw + 8.0, 14.0), col.lightened(0.08))
		Look.GALLERY:  # tall framed mirrors, some shattered
			var mw := 44.0 * sc
			var mh := (150.0 + 60.0 * h) * sc
			draw_rect(Rect2(o.x - 4.0, o.y - mh - 30.0 * sc - 4.0, mw + 8.0, mh + 8.0), col)
			var mc := Color(glow, 0.1 + 0.08 * flick)
			draw_rect(Rect2(o.x, o.y - mh - 30.0 * sc, mw, mh), mc)
			draw_line(Vector2(o.x, o.y - mh - 30.0 * sc), Vector2(o.x + mw * 0.7, o.y - 30.0 * sc), Color(glow, 0.35), 1.0)
			draw_line(Vector2(o.x + mw, o.y - mh * 0.7 - 30.0 * sc), Vector2(o.x + mw * 0.2, o.y - 30.0 * sc), Color(glow, 0.25), 1.0)
		Look.FORGE:  # chimneys, anvils and slag glow
			var cw := 34.0 * sc
			var chh := (180.0 + 100.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - chh, cw, chh), col)
			draw_rect(Rect2(o.x - 4.0, o.y - chh - 8.0, cw + 8.0, 10.0), col.lightened(0.08))
			draw_rect(Rect2(o.x + 4.0, o.y - 40.0 * sc, cw - 8.0, 40.0 * sc), Color(glow, 0.16 + 0.1 * flick))
			if rng.randf() < 0.4:
				_poly([Vector2(o.x + 50.0, o.y), Vector2(o.x + 50.0, o.y - 26.0 * sc), Vector2(o.x + 90.0, o.y - 26.0 * sc), Vector2(o.x + 84.0, o.y - 14.0 * sc), Vector2(o.x + 80.0, o.y)], col.lightened(0.1))
		Look.CLOISTER:  # a colonnade of pointed arches
			var aw := 80.0 * sc
			var ah := (190.0 + 40.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - ah, 10.0 * sc, ah), col)
			draw_rect(Rect2(o.x + aw, o.y - ah, 10.0 * sc, ah), col)
			_poly([Vector2(o.x, o.y - ah), Vector2(o.x + aw * 0.5 + 5.0, o.y - ah - 46.0 * sc), Vector2(o.x + aw + 10.0 * sc, o.y - ah), Vector2(o.x + aw + 10.0 * sc, o.y - ah + 12.0), Vector2(o.x + aw * 0.5 + 5.0, o.y - ah - 30.0 * sc), Vector2(o.x, o.y - ah + 12.0)], col)
		Look.BARROW:  # standing kings in niches
			var kw := 54.0 * sc
			var kh := (210.0 + 40.0 * h) * sc
			draw_rect(Rect2(o.x, o.y - kh, kw, kh), col)
			draw_arc(Vector2(o.x + kw * 0.5, o.y - kh), kw * 0.5, PI, TAU, 10, col, 4.0)
			var f := Color(col.lightened(0.18))
			draw_circle(Vector2(o.x + kw * 0.5, o.y - kh + 40.0 * sc), 9.0 * sc, f)
			_poly([Vector2(o.x + kw * 0.5 - 14.0 * sc, o.y - kh + 52.0 * sc), Vector2(o.x + kw * 0.5 + 14.0 * sc, o.y - kh + 52.0 * sc), Vector2(o.x + kw * 0.5 + 18.0 * sc, o.y - 24.0), Vector2(o.x + kw * 0.5 - 18.0 * sc, o.y - 24.0)], f)
			draw_rect(Rect2(o.x + kw * 0.5 - 12.0 * sc, o.y - kh + 28.0 * sc, 24.0 * sc, 5.0 * sc), Color(glow, 0.55))
		Look.HEART:  # great ribs and pulsing veins
			var beat := pow(maxf(0.0, sin(_t * 2.2)), 6.0)
			var rh := (220.0 + 80.0 * h) * sc
			draw_arc(Vector2(o.x, o.y), rh * 0.55, -PI * 0.1, -PI * 0.9, 16, col, 12.0 * sc)
			var vein := Color(glow, 0.12 + 0.28 * beat)
			draw_arc(Vector2(o.x + 40.0, o.y - 30.0), rh * 0.4, -PI * 0.2, -PI * 0.8, 12, vein, 2.5 * sc)
			if rng.randf() < 0.3:
				draw_circle(Vector2(o.x, o.y - rh * 0.5), 10.0 * sc * (1.0 + 0.3 * beat), Color(glow, 0.18 + 0.2 * beat))


func _shafts(v: Rect2, pal: Array) -> void:
	if theme not in [Look.CLOISTER, Look.VAULTS, Look.ARCHIVE, Look.GALLERY, Look.ORCHARD]:
		return
	var col: Color = pal[4]
	var step := 260.0
	var k0 := int(floorf(v.position.x / step)) - 1
	var k1 := int(ceilf(v.end.x / step)) + 1
	for k in range(k0, k1 + 1):
		var x := float(k) * step + 40.0 * sin(float(k) * 2.3)
		var a := 0.05 + 0.025 * sin(_t * 0.7 + float(k))
		_poly([Vector2(x, ceiling_y), Vector2(x + 34.0, ceiling_y), Vector2(x + 120.0, floor_y), Vector2(x + 50.0, floor_y)], Color(col, a))


func _haze(v: Rect2, pal: Array) -> void:
	var col: Color = pal[1]
	var x0 := maxf(0.0, v.position.x - 20.0)
	var x1 := minf(width, v.end.x + 20.0)
	for i in 6:
		var a := 0.07 * float(6 - i)
		draw_rect(Rect2(x0, floor_y - 10.0 - i * 9.0, x1 - x0, 9.0), Color(col.lightened(0.15), a))
	if theme == Look.VAULTS:
		draw_rect(Rect2(x0, floor_y - 40.0, x1 - x0, 40.0), Color(0.3, 0.6, 0.85, 0.1))


## Ambient motes: dust, embers, pages, spores, bubbles, glass, snow... by theme.
func _particles(v: Rect2, pal: Array) -> void:
	var col: Color = pal[5]
	var n := 46
	var vw := v.size.x + 80.0
	var vh := floor_y - ceiling_y
	for i in n:
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 977 + seed_value * 13
		var sp := rng.randf_range(6.0, 22.0)
		var bx := rng.randf() * vw
		var by := rng.randf() * vh
		var x := v.position.x - 40.0 + fposmod(bx + sin(_t * 0.4 + float(i)) * 14.0 - v.position.x * 0.2, vw)
		var y: float
		var r := rng.randf_range(0.8, 1.8)
		var a := rng.randf_range(0.25, 0.7)
		match theme:
			Look.TALLOW, Look.FORGE, Look.HEART:  # rise like embers
				y = floor_y - fposmod(by + _t * sp * 1.6, vh)
				a *= 1.0 - (floor_y - y) / vh
			Look.VAULTS:  # bubbles
				y = floor_y - fposmod(by + _t * sp, vh)
				r += 0.6
				draw_arc(Vector2(x, y), r, 0.0, TAU, 8, Color(col, a), 0.8)
				continue
			Look.CLOISTER, Look.OSSUARY, Look.BARROW:  # slow fall
				y = ceiling_y + fposmod(by + _t * sp * 0.7, vh)
			Look.ORCHARD:  # spores wander
				y = ceiling_y + vh * 0.35 + vh * 0.6 * (0.5 + 0.5 * sin(_t * 0.5 + float(i)))
				a *= 0.6 + 0.4 * sin(_t * 2.0 + float(i))
			Look.ARCHIVE:  # pages tumble
				y = ceiling_y + fposmod(by + _t * sp * 0.9, vh)
				draw_rect(Rect2(x, y, 4.0 + r, 3.0), Color(col, a * 0.8))
				continue
			Look.GALLERY:  # glints
				y = ceiling_y + vh * 0.2 + vh * 0.7 * rng.randf()
				a *= 0.5 + 0.5 * sin(_t * 3.0 + float(i) * 1.3)
				draw_line(Vector2(x - 3.0, y), Vector2(x + 3.0, y), Color(col, a), 1.0)
				draw_line(Vector2(x, y - 3.0), Vector2(x, y + 3.0), Color(col, a), 1.0)
				continue
			_:
				y = ceiling_y + fposmod(by + _t * sp * 0.5, vh)
		draw_circle(Vector2(x, y), r, Color(col, a))
