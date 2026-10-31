extends Node2D
## One-shot procedural effects drawn with additive blending: expanding ring, rising motes (embers / souls /
## heal), dust puffs. Self-freeing, no textures. Created through GameFeel.ring / rise / dust.

enum Kind { RING, RISE, DUST }

static var _add_mat: CanvasItemMaterial   ## shared by every burst

var kind := Kind.RING
var color := Color.WHITE
var radius := 20.0
var life := 0.35
var _t := 0.0
var _parts: Array[Dictionary] = []


func setup(k: Kind, c: Color, amount := 10, r := 20.0) -> void:
	kind = k
	color = c
	radius = r
	z_index = 19
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	match k:
		Kind.RING:
			life = 0.32
		Kind.RISE:
			life = 1.1
			for i in amount:
				_parts.append({"p": Vector2(rng.randf_range(-r, r), rng.randf_range(-6.0, 6.0)),
					"v": Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-46.0, -18.0)),
					"s": rng.randf_range(1.0, 2.2), "ph": rng.randf() * TAU, "d": rng.randf_range(0.6, 1.0)})
		Kind.DUST:
			life = 0.5
			for i in amount:
				var dir := -1.0 if i % 2 == 0 else 1.0
				_parts.append({"p": Vector2(rng.randf_range(-3.0, 3.0), 0.0),
					"v": Vector2(dir * rng.randf_range(14.0, 42.0), rng.randf_range(-18.0, -4.0)),
					"s": rng.randf_range(1.5, 3.2), "d": rng.randf_range(0.7, 1.0)})
	if k != Kind.DUST:
		if _add_mat == null:
			_add_mat = CanvasItemMaterial.new()
			_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = _add_mat


func _process(dt: float) -> void:
	_t += dt
	if _t >= life:
		queue_free()
		return
	for p in _parts:
		p.p += p.v * dt
		if kind == Kind.RISE:
			p.p.x += sin(_t * 5.0 + p.ph) * 14.0 * dt
		else:
			p.v *= 0.92
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / life
	match kind:
		Kind.RING:
			var rr := radius * (1.0 - k * k)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 28, Color(color, 0.85 * k), 1.5 + 2.0 * k)
			draw_circle(Vector2.ZERO, rr * 0.5, Color(color, 0.18 * k))
		Kind.RISE:
			for p in _parts:
				var a: float = k * float(p.d)
				draw_circle(p.p, p.s * 2.6, Color(color, 0.14 * a))
				draw_circle(p.p, p.s, Color(color.lightened(0.5), 0.9 * a))
		Kind.DUST:
			for p in _parts:
				var a: float = k * float(p.d) * 0.55
				draw_circle(p.p, p.s * (1.0 + (1.0 - k) * 1.2), Color(color, a))
