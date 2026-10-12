class_name Projectile
extends Area2D
## A thrown / shot hit carrier (e.g. the Ember Acolyte's burning wax).
## Hits the first Hurtbox it overlaps (other than its shooter's). If that hit is ignored
## (dodge i-frames) it flies on; parried or landed hits end it. Walls end it too.
## TEMPORARY ART: a burning blob drawn in code.

var velocity := Vector2.ZERO
var hit_template: HitData
var shooter: Node
var lifetime := 3.0
var color := Color("e0702a")
var _t := 0.0
var _done := false
var _ignored := {}
## Shape: radius for round shots; a non-zero [member size] makes a rectangle (waves).
var radius := 3.5
var size := Vector2.ZERO
## Downward acceleration (px/s^2). 0 = straight line.
var drop := 20.0
## When false the projectile passes through level geometry (ground waves).
var hit_world := true
var kind: StringName = &"ember"


## opts may set: radius, size, drop, hit_world, kind, lifetime, color.
static func spawn(parent: Node, from: Vector2, vel: Vector2, hit: HitData, who: Node, opts := {}) -> Projectile:
	var p := Projectile.new()
	p.position = from
	p.velocity = vel
	p.hit_template = hit
	p.shooter = who
	for k in opts:
		p.set(k, opts[k])
	parent.add_child(p)
	return p


func _ready() -> void:
	add_to_group(&"projectiles")
	collision_layer = 0
	collision_mask = 8 | (1 if hit_world else 0)   # player hurtbox (+ world geometry)
	monitoring = true
	var cs := CollisionShape2D.new()
	if size != Vector2.ZERO:
		var r := RectangleShape2D.new()
		r.size = size
		cs.shape = r
	else:
		var c := CircleShape2D.new()
		c.radius = radius
		cs.shape = c
	add_child(cs)
	area_entered.connect(_on_area)
	body_entered.connect(_on_body)
	var l := PointLight2D.new()
	l.texture = LightTex.radial()
	l.texture_scale = 0.4
	l.color = Palette.EMBER
	l.energy = 0.8
	add_child(l)
	z_index = 6


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	position += velocity * delta
	velocity.y += drop * delta
	if _t >= lifetime:
		queue_free()
	queue_redraw()


func _on_area(a: Area2D) -> void:
	if _done or not (a is Hurtbox) or a.receiver == shooter or _ignored.has(a.get_instance_id()):
		return
	var hit := HitData.new()
	hit.damage = hit_template.damage
	hit.poise_damage = hit_template.poise_damage
	hit.knockback = hit_template.knockback
	hit.parryable = hit_template.parryable
	hit.source = self
	hit.attack_id = hit_template.attack_id
	hit.hit_stop = hit_template.hit_stop
	hit.status = hit_template.status
	hit.status_amount = hit_template.status_amount
	hit.shake = hit_template.shake
	var result: int = (a as Hurtbox).receive_hit(hit)
	match result:
		HitData.Result.IGNORED:
			_ignored[a.get_instance_id()] = true
		HitData.Result.PARRIED:
			GameFeel.spark(global_position, Palette.GOLD_BRIGHT, 12)
			_finish()
		_:
			GameFeel.spark(global_position, color, 10)
			Audio.sfx_at(&"hit_flesh", global_position)
			_finish()


func _on_body(_b: Node) -> void:
	if _done:
		return
	GameFeel.spark(global_position, color, 8)
	Audio.sfx_at(&"fizzle", global_position, -4.0)
	_finish()


func _finish() -> void:
	_done = true
	set_deferred(&"monitoring", false)
	queue_free()


func _draw() -> void:
	if kind == &"wave":
		_draw_wave()
		return
	var dir := velocity.normalized()
	for i in 4:
		draw_circle(-dir * (i * 3.0), 3.0 - i * 0.6, Color(color, 0.5 - i * 0.1))
	draw_circle(Vector2.ZERO, 3.0, color)
	draw_circle(Vector2.ZERO, 1.6, Palette.GOLD_BRIGHT)


func _draw_wave() -> void:
	var h := size.y
	var w := size.x
	var s := signf(velocity.x) if velocity.x != 0.0 else 1.0
	var pts := PackedVector2Array()
	pts.append(Vector2(-w / 2.0 * s, h / 2.0))
	for i in 9:
		var t := i / 8.0
		var x := lerpf(-w / 2.0, w / 2.0, t) * s
		var y := h / 2.0 - h * sin(t * PI * 0.85) * (0.8 + 0.2 * sin(_t * 20.0 + i))
		pts.append(Vector2(x, y))
	pts.append(Vector2(w / 2.0 * s, h / 2.0))
	draw_colored_polygon(pts, Color(0.25, 0.45, 0.48, 0.75))
	draw_polyline(pts.slice(1, pts.size() - 1), Color(0.75, 0.9, 0.9, 0.8), 1.5)
	for i in 4:
		draw_circle(Vector2((w / 2.0 - 2) * s, -h / 2.0 + 4 + i * 3) + Vector2(sin(_t * 30.0 + i) * 2, 0), 1.2, Color(0.85, 0.95, 0.95, 0.7))
