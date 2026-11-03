class_name FireSlash
extends Area2D
## The Long Katana's flame: each swing throws a crescent of fire a short way ahead that burns whatever it
## crosses (once each). Hits carry the player as source and count as jutsu hits. TEMPORARY ART (code).

var hit_template: HitData
var shooter: Node
var dir := 1
var speed := 230.0
var life := 0.42
var scale_up := 1.0
var _t := 0.0
var _hit := {}


static func spawn(parent: Node, pos: Vector2, facing: int, hit: HitData, who: Node, big := 1.0) -> FireSlash:
	var f := FireSlash.new()
	f.position = pos
	f.dir = facing
	f.hit_template = hit
	f.shooter = who
	f.scale_up = big
	parent.add_child(f)
	return f


func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26.0, 46.0) * scale_up
	cs.shape = r
	cs.position = Vector2(0, -22.0 * scale_up)
	add_child(cs)
	z_index = 5


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	position.x += float(dir) * speed * delta * (1.0 - 0.5 * _t / life)
	queue_redraw()
	for a in get_overlapping_areas():
		if a is Hurtbox and a.receiver != shooter and not _hit.has(a):
			_hit[a] = true
			var hit := HitData.new()
			hit.damage = hit_template.damage
			hit.poise_damage = hit_template.poise_damage
			hit.knockback = Vector2(30.0 * dir, -10.0)
			hit.parryable = false
			hit.environmental = false
			hit.jutsu = true
			hit.source = shooter as Node2D
			hit.attack_id = hit_template.attack_id
			hit.hit_stop = 0.03
			hit.shake = 1.0
			hit.status = &"burn"
			hit.status_amount = hit_template.status_amount
			(a as Hurtbox).receive_hit(hit)
			GameFeel.spark(global_position + Vector2(8.0 * dir, -20.0 * scale_up), Color(1.0, 0.55, 0.15), 6)


func _draw() -> void:
	var fade := 1.0 - _t / life
	var s := scale_up
	# a crescent of flame, bulging forward
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 9:
		var f := float(i) / 8.0
		var a := lerpf(-1.25, 1.25, f)
		var wob := 1.0 + 0.12 * sin(_t * 40.0 + f * 9.0)
		outer.append(Vector2(cos(a) * 20.0 * dir * wob + 0.0, -22.0 * s + sin(a) * 24.0 * s))
		inner.append(Vector2(cos(a) * 9.0 * dir, -22.0 * s + sin(a) * 20.0 * s))
	var pts := PackedVector2Array()
	pts.append_array(outer)
	var rev := inner.duplicate()
	rev.reverse()
	pts.append_array(rev)
	if Geometry2D.triangulate_polygon(pts).size() > 0:
		draw_colored_polygon(pts, Color(1.0, 0.45, 0.1, 0.85 * fade))
	draw_polyline(outer, Color(1.0, 0.85, 0.4, 0.95 * fade), 2.0)
	draw_circle(Vector2(float(dir) * 6.0, -22.0 * s), 18.0 * s, Color(1.0, 0.5, 0.1, 0.10 * fade))
