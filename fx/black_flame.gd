class_name BlackFlame
extends Area2D
## One tongue of black fire on the ground (the scythe's jutsu, Amaterasu). It ignites, burns for
## [member life] seconds, and every [member tick] hurts and burns each enemy standing in it.
## Hits carry the player as source (kills credit the player). TEMPORARY ART: drawn in code.

var hit_template: HitData
var shooter: Node
var life := 7.0
var tick := 0.35
var delay := 0.0
var width := 26.0
var height := 46.0
var _t := 0.0
var _next := 0.0
var _seed := randf() * 10.0


static func spawn(parent: Node, pos: Vector2, hit: HitData, who: Node, wait := 0.0, w := 26.0, h := 46.0) -> BlackFlame:
	var f := BlackFlame.new()
	f.position = pos
	f.hit_template = hit
	f.shooter = who
	f.delay = wait
	f.width = w
	f.height = h
	parent.add_child(f)
	return f


func _ready() -> void:
	add_to_group(&"black_flames")
	collision_layer = 0
	collision_mask = 16
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, height)
	cs.shape = r
	cs.position = Vector2(0, -height / 2.0)
	add_child(cs)
	z_index = 5
	visible = false


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < delay:
		return
	if not visible:
		visible = true
		GameFeel.rise(global_position + Vector2(0, -6), Color(0.35, 0.2, 0.6), 6, 12.0)
	var age := _t - delay
	if age >= life:
		queue_free()
		return
	queue_redraw()
	if age >= _next:
		_next = age + tick
		for a in get_overlapping_areas():
			if a is Hurtbox and a.receiver != shooter:
				var hit := HitData.new()
				hit.damage = hit_template.damage
				hit.poise_damage = hit_template.poise_damage
				hit.knockback = Vector2.ZERO
				hit.parryable = false
				hit.environmental = false
				hit.source = shooter as Node2D
				hit.attack_id = hit_template.attack_id
				hit.hit_stop = 0.0
				hit.shake = 0.0
				hit.status = hit_template.status
				hit.status_amount = hit_template.status_amount
				(a as Hurtbox).receive_hit(hit)


func _draw() -> void:
	var age := _t - delay
	var grow := clampf(age / 0.35, 0.0, 1.0)
	var fade := clampf((life - age) / 1.0, 0.0, 1.0)
	var h := height * grow
	for i in 5:
		var k := float(i) / 4.0
		var x := (k - 0.5) * width * 0.8
		var sway := sin(_t * 7.0 + _seed + i * 1.7) * 3.0
		var tip := Vector2(x + sway, -h * (0.55 + 0.45 * sin(_t * 5.0 + _seed * 2.0 + i * 2.3) * 0.5 + 0.2) * (1.0 - absf(k - 0.5) * 0.7))
		var w := width * 0.3
		draw_colored_polygon(PackedVector2Array([Vector2(x - w, 0), tip, Vector2(x + w, 0)]), Color(0.02, 0.0, 0.04, 0.97 * fade))
		draw_line(Vector2(x - w, 0), tip, Color(0.4, 0.15, 0.7, 0.45 * fade), 1.0)
		draw_line(Vector2(x + w, 0), tip, Color(0.4, 0.15, 0.7, 0.45 * fade), 1.0)
	draw_circle(Vector2(0, -2), width * 0.45, Color(0.2, 0.05, 0.35, 0.18 * fade * grow))
