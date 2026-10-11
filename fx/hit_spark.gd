extends Node2D
## Short-lived impact burst drawn procedurally (no texture needed).
## direction: -1 / 1 biases sparks horizontally, 0 = radial.

const LIFETIME := 0.28

var _color := Color.WHITE
var _parts: Array[Dictionary] = []
var _t := 0.0


func setup(color: Color, amount: int, direction: int) -> void:
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
	if _t < 0.06:
		draw_circle(Vector2.ZERO, 5.0 * k + 1.0, Color(1, 0.97, 0.9, 0.9))
	for p in _parts:
		var dir: Vector2 = (p.v as Vector2).normalized()
		var c := _color
		c.a = k
		draw_line(p.p, p.p - dir * float(p.len), c, 1.0)
