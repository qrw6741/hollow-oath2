class_name BossZone
extends Area2D
## A hazard a boss throws into the arena. Kinds:
##   BOX  - telegraphed strike: a marked patch of ground that goes off after [member warn] seconds.
##   WAVE - a low ripple that races along the floor; jump it (dodge i-frames do not help).
##   RAIN - a falling column: warns from above, then crashes down.
## Environmental damage: cannot be parried and ignores dodge i-frames. Origin = bottom centre.
## TEMPORARY ART (procedural).

enum Kind { BOX, WAVE, RAIN }

var kind := Kind.BOX
var size := Vector2(44, 70)
var warn := 0.9
var damage := 24.0
var status: StringName = &""
var status_amount := 0.0
var speed := 150.0
var dir := 1.0
var travel := 420.0
var tint := Color(0.9, 0.3, 0.25)

var _t := 0.0
var _went := false
var _hit_ids := {}
var _dist := 0.0


func setup(k: Kind, sz: Vector2, w: float, dmg: float, c: Color) -> BossZone:
	kind = k
	size = sz
	warn = w
	damage = dmg
	tint = c
	return self


func _ready() -> void:
	add_to_group(&"hazards")
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	monitorable = false
	z_index = 5
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(0, -size.y / 2.0)
	add_child(cs)
	if kind == Kind.WAVE:
		Audio.sfx_at(&"boss_stomp", global_position, -6.0, 0.7)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	match kind:
		Kind.WAVE:
			var step := speed * delta
			global_position.x += dir * step
			_dist += step
			_strike(0.5)
			if _dist >= travel:
				queue_free()
		_:
			if not _went and _t >= warn:
				_went = true
				Audio.sfx_at(&"boss_land", global_position, -4.0, 1.1)
				GameFeel.shake(2.5, 0.15)
				GameFeel.spark(global_position + Vector2(0, -6), tint, 10)
			if _went:
				_strike(1.0)
				if _t >= warn + 0.28:
					queue_free()


func _strike(_rehit_after: float) -> void:
	for a in get_overlapping_areas():
		if a is Hurtbox and not _hit_ids.has(a.get_instance_id()):
			var hit := HitData.make(damage, self, Vector2(dir * 120.0, -150.0))
			hit.environmental = true
			hit.parryable = false
			if status != &"":
				hit.status = status
				hit.status_amount = status_amount
			if (a as Hurtbox).receive_hit(hit) == HitData.Result.HIT:
				_hit_ids[a.get_instance_id()] = true


func _draw() -> void:
	match kind:
		Kind.WAVE:
			var h := size.y
			var pts := PackedVector2Array([Vector2(-size.x / 2.0, 0), Vector2(0, -h), Vector2(size.x / 2.0, 0)])
			draw_colored_polygon(pts, Color(tint, 0.75))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2]]), Color(1, 1, 1, 0.6), 1.0)
		_:
			var k := clampf(_t / warn, 0.0, 1.0)
			var rect := Rect2(-size.x / 2.0, -size.y, size.x, size.y)
			if not _went:
				draw_rect(rect, Color(tint, 0.10 + 0.12 * k))
				draw_rect(Rect2(rect.position.x, -size.y * k, size.x, size.y * k), Color(tint, 0.28))
				draw_rect(rect, Color(tint, 0.6 + 0.4 * sin(_t * 18.0) * k), false, 1.0)
				draw_line(Vector2(-size.x / 2.0, 0), Vector2(size.x / 2.0, 0), Color(tint, 0.9), 2.0)
			else:
				var f := 1.0 - (_t - warn) / 0.28
				draw_rect(rect, Color(1, 0.95, 0.85, 0.85 * f))
				draw_rect(Rect2(rect.position.x + 4, rect.position.y, size.x - 8, size.y), Color(tint, 0.6 * f))
