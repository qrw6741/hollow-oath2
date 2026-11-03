class_name FireMeteor
extends Area2D
## The Fire Meteor jutsu: a big fireball that arcs forward, then bursts (wide, burning) on the first enemy or
## floor it meets. Hits carry the player as source. TEMPORARY ART: drawn in code.

var velocity := Vector2.ZERO
var hit_template: HitData
var shooter: Node
var radius := 56.0
var _t := 0.0
var _done := false


static func spawn(parent: Node, from: Vector2, vel: Vector2, hit: HitData, who: Node) -> FireMeteor:
	var m := FireMeteor.new()
	m.position = from
	m.velocity = vel
	m.hit_template = hit
	m.shooter = who
	parent.add_child(m)
	return m


func _ready() -> void:
	add_to_group(&"fire_meteors")
	collision_layer = 0
	collision_mask = 16 | 1
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	cs.shape = c
	add_child(cs)
	area_entered.connect(func(a): if a is Hurtbox and a.receiver != shooter: _burst.call_deferred())
	body_entered.connect(func(_b): _burst.call_deferred())
	z_index = 7


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	position += velocity * delta
	velocity.y += 320.0 * delta
	if _t > 3.0:
		_burst()
	if Engine.get_physics_frames() % 2 == 0:
		GameFeel.rise(global_position, Color(1.0, 0.5, 0.15), 2, 6.0)
	queue_redraw()


func _burst() -> void:
	if _done:
		return
	_done = true
	var pos := global_position
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	q.shape = shape
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = 16
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var seen := {}
	for r in space.intersect_shape(q, 16):
		var a = r.collider
		if a is Hurtbox and a.receiver != shooter and not seen.has(a.get_instance_id()):
			seen[a.get_instance_id()] = true
			var hit := HitData.new()
			hit.damage = hit_template.damage
			hit.poise_damage = hit_template.poise_damage
			hit.knockback = Vector2(signf(a.global_position.x - pos.x) * 160.0, -80.0)
			hit.parryable = false
			hit.source = shooter as Node2D
			hit.attack_id = hit_template.attack_id
			hit.status = hit_template.status
			hit.status_amount = hit_template.status_amount
			hit.jutsu = true
			hit.hit_stop = 0.08
			hit.shake = 6.0
			(a as Hurtbox).receive_hit(hit)
	GameFeel.ring(pos, Color(1.0, 0.55, 0.15), radius)
	GameFeel.rise(pos, Color(1.0, 0.5, 0.15), 24, 22.0)
	GameFeel.spark(pos, Color(1.0, 0.8, 0.3), 16)
	GameFeel.shake(6.0, 0.4)
	Audio.sfx_at(&"boss_land", pos, 0.0, 0.8)
	# a short-lived fire left where it burst
	for i in 3:
		var h := HitData.new()
		h.damage = hit_template.damage * 0.12
		h.status = &"burn"
		h.status_amount = 10.0
		h.jutsu = true
		h.attack_id = hit_template.attack_id
		var f := BlackFlame.spawn(get_parent(), pos + Vector2((i - 1) * 26.0, 0.0), h, shooter, 0.05 * i, 24.0, 34.0)
		f.life = 3.0
		f.tick = 0.5
		f.fire = true
	queue_free()


func _draw() -> void:
	if _done:
		return
	var p := 1.0 + 0.12 * sin(_t * 30.0)
	draw_circle(Vector2.ZERO, 14.0 * p, Color(0.9, 0.25, 0.05, 0.35))
	draw_circle(Vector2.ZERO, 9.0 * p, Color(1.0, 0.5, 0.12))
	draw_circle(Vector2.ZERO, 5.0 * p, Color(1.0, 0.9, 0.5))
	var back := -velocity.normalized()
	if velocity.length() > 1.0:
		draw_colored_polygon(PackedVector2Array([back * 10.0 + back.orthogonal() * 8.0, back * 34.0, back * 10.0 - back.orthogonal() * 8.0]), Color(1.0, 0.45, 0.1, 0.6))
