extends Node2D
## TEMPORARY ART — procedural placeholder for the Hollow Penitent.
## Hunched hooded silhouette, rusted greatblade, ember eye. The eye flares and a
## crimson glint appears on the blade during wind-up: the attack telegraph.
## Final sprites (Milestone 4/5) replace this node; gameplay never reads it.


## [rest, windup, strike_end] blade angles per animation (0 forward, -90 up).
const POSES := {
	&"overhead": [70.0, -150.0, 75.0],
	&"sweep": [70.0, 150.0, 20.0],
	&"thrust": [70.0, 180.0, 0.0],
}

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
	var blade := 70.0
	var blade_reach := 0.0
	var trail := Vector2.ZERO
	var eye := 0.45
	var glint := false

	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			legs = sin(_t * 8.0) * 2.5
			lean = 1.0
		EnemyBase.State.CHASE:
			legs = sin(_t * 13.0) * 3.5
			lean = 3.0
			eye = 0.8
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.8) + 1.0) * 0.5
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var pose: Array = POSES.get(r.attack.animation, POSES[&"overhead"])
				var p := r.phase_progress()
				eye = 1.0
				match r.phase:
					AttackRunner.Phase.STARTUP:
						blade = lerpf(pose[0], pose[1], ease(minf(p * 1.6, 1.0), 0.5))
						lean = -2.5 * p
						crouch = 2.0 * p
						# Glint in the last ~12 frames before the hit: the "now" cue.
						glint = r.attack.startup_frames - r.frame <= 12
						if r.attack.animation == &"thrust":
							blade_reach = -6.0 * p
					AttackRunner.Phase.ACTIVE:
						blade = lerpf(pose[1], pose[2], ease(p, 0.3))
						if r.attack.animation != &"thrust":
							trail = Vector2(pose[1], blade)
						else:
							blade_reach = 10.0
						lean = 4.0
						crouch = 2.0
					_:
						blade = pose[2]
						lean = 3.0 * (1.0 - p)
						crouch = 2.0 * (1.0 - p)
						blade_reach = 10.0 * (1.0 - p) if r.attack.animation == &"thrust" else 0.0
		EnemyBase.State.RECOVER:
			lean = -1.0
		EnemyBase.State.STAGGER:
			lean = -4.0
			blade = 110.0
			eye = 0.2
		EnemyBase.State.PARRIED:
			crouch = 7.0
			lean = -2.0
			blade = 140.0
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 20) / 70.0, 0.0, 1.0)
			crouch = minf(f * 1.2, 22.0)
			lean = -minf(f * 0.4, 8.0)
			blade = 150.0
			eye = 0.0

	var hip := Vector2(lean * 0.3, -14.0 + crouch * 0.6)
	var shoulder := Vector2(4.0 + lean, -28.0 + crouch)
	var head := shoulder + Vector2(5.0 + lean * 0.3, -1.0)

	# Legs: wrapped, bony.
	draw_line(hip + Vector2(-2, 0), Vector2(-3 - legs, 0), _c(Palette.BONE_DIM, flash, alpha), 2.0)
	draw_line(hip + Vector2(2, 0), Vector2(3 + legs, 0), _c(Palette.DUST, flash, alpha), 2.0)

	# Robe: tattered, with ragged hem.
	var hem := hip.y + 6.0
	var robe := PackedVector2Array([
		shoulder + Vector2(-7, 2), shoulder + Vector2(4, 0),
		Vector2(hip.x + 7, hem - 2), Vector2(hip.x + 4, hem + 1), Vector2(hip.x + 1, hem - 1),
		Vector2(hip.x - 2, hem + 2), Vector2(hip.x - 5, hem - 1), Vector2(hip.x - 9, hem + 1),
	])
	draw_colored_polygon(robe, _c(Color("3b3530"), flash, alpha))
	draw_line(shoulder + Vector2(-7, 2), Vector2(hip.x - 9, hem + 1), _c(Color("29241f"), flash, alpha), 1.5)
	# Rope belt.
	draw_line(Vector2(hip.x - 6, hip.y - 3), Vector2(hip.x + 6, hip.y - 4), _c(Palette.WOOD_LIGHT, flash, alpha), 1.0)

	# Hood (hunched forward) + ember eye.
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-7, 3), head + Vector2(-4, -6), head + Vector2(3, -5), head + Vector2(6, 2), head + Vector2(1, 5),
	]), _c(Color("2e2925"), flash, alpha))
	draw_circle(head + Vector2(2, 0), 2.6, _c(Palette.INK, flash, alpha))
	if eye > 0.0:
		var ec := Palette.EMBER.lerp(Palette.GOLD_BRIGHT, maxf(0.0, eye - 0.6) * 2.0)
		draw_circle(head + Vector2(3, -0.5), 0.9 + eye * 0.6, Color(ec, alpha))
		if eye >= 0.8:
			draw_circle(head + Vector2(3, -0.5), 3.0 + eye * 2.0, Color(Palette.EMBER, 0.18 * alpha))

	# Arms + rusted greatblade.
	var hand := shoulder + Vector2(3.0 + blade_reach, 5.0)
	if trail != Vector2.ZERO:
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 26.0)
		for i in range(8, -1, -1):
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 10.0)
		draw_colored_polygon(pts, Color(Palette.CRIMSON_BRIGHT, 0.35 * alpha))
	var dir := Vector2.from_angle(deg_to_rad(blade))
	draw_line(shoulder, hand, _c(Palette.BONE_DIM, flash, alpha), 2.0)
	draw_line(hand - dir * 3.0, hand + dir * 25.0, _c(Palette.RUST, flash, alpha), 3.0)
	draw_line(hand + dir * 4.0, hand + dir * 24.0, _c(Palette.STEEL_OXIDE, flash, alpha), 1.0)
	if glint:
		var tip := hand + dir * 24.0
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(tip + Vector2(-4, 0), tip + Vector2(4, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(tip + Vector2(0, -4), tip + Vector2(0, 4), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(tip, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))

	# Riposte cue above a parried enemy.
	if enemy.is_riposte_ready():
		var y := -48.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)


func _c(col: Color, flash: float, alpha: float) -> Color:
	var out := col.lerp(Color.WHITE, flash)
	out.a = alpha
	return out
