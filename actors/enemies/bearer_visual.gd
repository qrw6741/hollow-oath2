extends Node2D
## TEMPORARY ART — Bell-Bearer: a broad penitent hunched under a yoke, dragging a village
## bell on a chain and swinging it like a flail.
## Telegraphs: the slam glints (parryable); the chain swing glows red (cannot be parried).

const POSES := {
	&"slam": [60.0, -150.0, 80.0],
	&"swing": [60.0, 170.0, -10.0],
}
const BRONZE := Color("6e5230")
const ROBE := Color("3a332d")

var enemy: EnemyBase
var _t := 0.0


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if enemy:
		scale.x = enemy.facing
	queue_redraw()


func _c(col: Color, flash: float, alpha: float) -> Color:
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


func _draw() -> void:
	if enemy == null:
		return
	var s := enemy.state
	var f := enemy.state_frame
	var flash := 1.0 if enemy.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var lean := 0.0
	var crouch := 0.0
	var legs := 0.0
	var chain := 60.0
	var trail := Vector2.ZERO
	var glint := false
	var danger := 0.0
	var eye := 0.4
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 6.0) * 3.0
			lean = 2.0
			chain = 70.0 + sin(_t * 6.0) * 8.0
			eye = 0.7 if s == EnemyBase.State.CHASE else 0.4
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.5) + 1.0) * 0.6
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var pose: Array = POSES.get(r.attack.animation, POSES[&"slam"])
				var p := r.phase_progress()
				eye = 1.0
				match r.phase:
					AttackRunner.Phase.STARTUP:
						chain = lerpf(pose[0], pose[1], ease(minf(p * 1.3, 1.0), 0.5))
						lean = -2.0 * p
						crouch = 2.0 * p
						if r.attack.parryable:
							glint = r.attack.startup_frames - r.frame <= 12
						else:
							danger = 0.4 + 0.6 * p
					AttackRunner.Phase.ACTIVE:
						chain = lerpf(pose[1], pose[2], ease(p, 0.3))
						trail = Vector2(pose[1], chain)
						lean = 4.0
						crouch = 2.0
					_:
						chain = pose[2]
						lean = 3.0 * (1.0 - p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -4.0
			crouch = 7.0 if s == EnemyBase.State.PARRIED else 2.0
			chain = 120.0
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			crouch = minf(f * 0.8, 20.0)
			lean = -minf(f * 0.3, 6.0)
			chain = 150.0
			eye = 0.0
	var hip := Vector2(lean * 0.3, -18.0 + crouch * 0.6)
	var shoulder := Vector2(3.0 + lean, -34.0 + crouch)
	var head := shoulder + Vector2(7.0 + lean * 0.3, 2.0)
	if danger > 0.0:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(0, -20), 22.0, Color(Palette.CRIMSON_BRIGHT, 0.12 * k * alpha))
	draw_line(hip + Vector2(-3, 0), Vector2(-5 - legs, 0), _c(Palette.DUST, flash, alpha), 3.5)
	draw_line(hip + Vector2(3, 0), Vector2(5 + legs, 0), _c(Palette.BONE_DIM, flash, alpha), 3.5)
	# Broad robe and wooden yoke
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-10, 1), shoulder + Vector2(8, -1), hip + Vector2(9, 6), hip + Vector2(-10, 7)]), _c(ROBE, flash, alpha))
	draw_line(shoulder + Vector2(-13, -2), shoulder + Vector2(10, -4), _c(Palette.WOOD_LIGHT, flash, alpha), 3.0)
	draw_line(hip + Vector2(-8, -2), hip + Vector2(8, -3), _c(Palette.WOOD, flash, alpha), 1.5)
	# Low hooded head with ember eye
	draw_circle(head, 4.2, _c(Color("2b2622"), flash, alpha))
	if eye > 0.0:
		draw_circle(head + Vector2(2.2, 0), 0.8 + eye * 0.6, Color(Palette.EMBER, alpha))
	# Chain and bell
	var hand := shoulder + Vector2(6, 6)
	var dir := Vector2.from_angle(deg_to_rad(chain))
	if trail != Vector2.ZERO:
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 30.0)
		for i in range(8, -1, -1):
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 14.0)
		draw_colored_polygon(pts, Color(Palette.CRIMSON_BRIGHT, 0.3 * alpha))
	draw_line(shoulder, hand, _c(ROBE, flash, alpha), 3.0)
	var bell_at := hand + dir * 24.0
	for i in 6:
		draw_circle(hand + dir * (i * 4.0), 0.9, _c(Palette.STEEL_OXIDE, flash, alpha))
	draw_set_transform(bell_at, dir.angle() - PI / 2.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(7, 5), Vector2(-7, 5)]), _c(BRONZE, flash, alpha))
	draw_line(Vector2(-7, 5), Vector2(7, 5), _c(Color("4a3520"), flash, alpha), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(bell_at + Vector2(-5, 0), bell_at + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(bell_at + Vector2(0, -5), bell_at + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(bell_at, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -54.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
