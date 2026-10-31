extends Node2D
## Short-lived impact burst drawn procedurally (no texture needed).
## direction: -1 / 1 biases sparks horizontally, 0 = radial.

const LIFETIME := 0.28

## One shared additive material for every spark (a new material per effect is needless churn on the GPU).
static var _add_mat: CanvasItemMaterial

var _color := Color.WHITE
var _parts: Array[Dictionary] = []
var _t := 0.0


func setup(color: Color, amount: int, direction: int) -> void:
	if Settings.classic_gfx:
		amount = maxi(3, amount / 2)
	_color = color
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in amount:
		var ang := rng.randf_range(0.0, TAU)
		if direction != 0:
			ang = rng.randf_range(-0.9, 0.9) + (0.0 if direction > 0 else PI)
		var spd := rng.randf_range(60.0, 170.0)
		_parts.append({"p": Vector2.ZERO, "v": Vector2.from_angle(ang) * spd, "len": rng.randf_range(2.0, 5.0)})
	z_index = 20
	if not Settings.classic_gfx:   # Classic: plain alpha blending, no additive pass
		if _add_mat == null:
			_add_mat = CanvasItemMaterial.new()
			_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = _add_mat


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	for p in _parts:
		p.v *= 0.86
		p.v.y += 260.0 * delta
		p.p += p.v * delta
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFETIME
	# Core flash on the first frames.
	if _t < 0.08:
		draw_circle(Vector2.ZERO, 5.0 * k + 1.0, Color(1, 0.97, 0.9, 0.9))
		draw_circle(Vector2.ZERO, 11.0 * k + 2.0, Color(_color, 0.22))
	draw_arc(Vector2.ZERO, 4.0 + (1.0 - k) * 12.0, 0.0, TAU, 16, Color(_color, 0.35 * k), 1.0)
	for p in _parts:
		var dir: Vector2 = (p.v as Vector2).normalized()
		var c := _color
		c.a = k
		draw_line(p.p, p.p - dir * float(p.len) * 1.8, c, 1.0)
		draw_circle(p.p, 1.6, Color(c, 0.35 * k))
