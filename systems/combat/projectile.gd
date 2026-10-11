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


static func spawn(parent: Node, from: Vector2, vel: Vector2, hit: HitData, who: Node) -> Projectile:
	var p := Projectile.new()
	p.global_position = from
	p.velocity = vel
	p.hit_template = hit
	p.shooter = who
	parent.add_child(p)
	return p


func _ready() -> void:
	add_to_group(&"projectiles")
	collision_layer = 0
	collision_mask = 8 | 1      # player hurtbox + world geometry
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.5
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
	velocity.y += 20.0 * delta   # a slight drop
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
	var dir := velocity.normalized()
	for i in 4:
		draw_circle(-dir * (i * 3.0), 3.0 - i * 0.6, Color(color, 0.5 - i * 0.1))
	draw_circle(Vector2.ZERO, 3.0, color)
	draw_circle(Vector2.ZERO, 1.6, Palette.GOLD_BRIGHT)
