extends Node2D
## TEMPORARY ART — procedural placeholder for the Bell-Warden (intro boss).
## A hulking penitent wearing the yard's cracked bronze bell as a helm and swinging
## the bell's iron clapper as a maul.
## Telegraphs (gameplay-critical, see docs/ART_BIBLE.md):
##   - parryable swings: crimson-white glint on the clapper in the last 12 frames of wind-up
##     (same cue as the Hollow Penitent);
##   - unparryable charge / leap: red aura and burning eye during wind-up; a red ring marks
##     where a leap will land. Dodge or jump these — they cannot be parried.

## [rest, windup, strike_end] clapper angles (0 = forward, -90 = up, 90 = down).
const POSES := {
	&"smash": [75.0, -140.0, 85.0],
	&"sweep": [75.0, 165.0, 5.0],
	&"backhand": [5.0, -20.0, 160.0],
	&"charge": [75.0, 150.0, 150.0],
	&"leap": [75.0, -110.0, 88.0],
}
const ROBE := Color("332c28")
const ROBE_DARK := Color("241f1c")
const BRONZE := Color("7a5a33")
const BRONZE_LIGHT := Color("a07a45")
const BRONZE_DARK := Color("4a3520")
const IRON := Color("4b4a52")

var boss: BossBase
var _t := 0.0


func _ready() -> void:
	boss = get_parent() as BossBase
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if boss:
		scale.x = boss.facing
	queue_redraw()


func _c(col: Color, flash: float, alpha: float) -> Color:
	var out := col.lerp(Color.WHITE, flash)
	out.a = alpha
	return out


func _draw() -> void:
	if boss == null:
		return
	var s := boss.state
	var f := boss.state_frame
	var flash := 1.0 if boss.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var lean := 0.0
	var crouch := 0.0
	var legs := 0.0
	var club := 75.0
	var trail := Vector2.ZERO
	var eye := 0.4
	var glint := false
	var danger := 0.0          # red aura strength (unparryable wind-up)
	var head_up := 0.0
	var helm_off := false
	var roar_ring := -1.0

	match s:
		EnemyBase.State.IDLE, EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			crouch = (sin(_t * 1.6) + 1.0) * 0.8
			eye = 0.5 if boss.active else 0.25
			head_up = -2.0 if not boss.active else 0.0
		EnemyBase.State.CHASE:
			legs = sin(_t * 7.0) * 4.0
			lean = 3.0
			eye = 0.8
			crouch = absf(sin(_t * 7.0)) * 1.5
		EnemyBase.State.RECOVER:
			lean = -1.5
			eye = 0.6
		EnemyBase.State.ATTACK:
			var r := boss.attack_runner
			if r.attack:
				var anim: StringName = r.attack.animation
				var pose: Array = POSES.get(anim, POSES[&"smash"])
				var p := r.phase_progress()
				eye = 1.0
				var unparryable := not r.attack.parryable
				match r.phase:
					AttackRunner.Phase.STARTUP:
						club = lerpf(pose[0], pose[1], ease(minf(p * 1.4, 1.0), 0.5))
						lean = -3.0 * p
						crouch = 3.0 * p
						if unparryable:
							danger = 0.4 + 0.6 * p
						else:
							glint = r.attack.startup_frames - r.frame <= 12
						if anim == &"charge":
							lean = 6.0 * p
							crouch = 4.0 * p
						if anim == &"leap":
							if boss.leaping:
								club = pose[1]
								crouch = -2.0
								legs = 3.0
							else:
								crouch = 8.0 * minf(1.0, float(f) / boss.leap_jump_frame)
					AttackRunner.Phase.ACTIVE:
						club = lerpf(pose[1], pose[2], ease(p, 0.3))
						if anim != &"charge":
							trail = Vector2(pose[1], club)
						lean = 6.0 if anim == &"charge" else 4.0
						crouch = 3.0
						if anim == &"charge":
							legs = sin(_t * 20.0) * 5.0
							danger = 0.6
					_:
						club = pose[2]
						lean = 3.0 * (1.0 - p)
						crouch = 3.0 * (1.0 - p)
		EnemyBase.State.STAGGER:
			if boss.roaring:
				head_up = -6.0
				lean = -4.0
				club = 100.0
				eye = 1.0
				roar_ring = clampf((f - 20) / 30.0, 0.0, 1.0) if f >= 20 else -1.0
				danger = 0.5
			else:
				lean = -5.0
				club = 115.0
				eye = 0.2
		EnemyBase.State.PARRIED:
			crouch = 10.0
			lean = -3.0
			club = 135.0
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 120) / 90.0, 0.0, 1.0)
			crouch = minf(f * 0.6, 22.0)
			lean = -minf(f * 0.2, 6.0)
			club = 140.0
			eye = maxf(0.0, 1.0 - f / 40.0)
			helm_off = f > 50

	var hip := Vector2(lean * 0.3, -24.0 + crouch * 0.6)
	var shoulder := Vector2(5.0 + lean, -46.0 + crouch)
	var head := shoulder + Vector2(7.0 + lean * 0.3, -4.0 + head_up)

	# Danger aura (unparryable wind-ups).
	if danger > 0.0:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(0, -28), 30.0, Color(Palette.CRIMSON_BRIGHT, 0.10 * k * alpha))
		draw_circle(Vector2(0, -28), 22.0, Color(Palette.CRIMSON_BRIGHT, 0.10 * k * alpha))

	# Predicted landing spot of a leap.
	if boss.leaping:
		var vy := boss.velocity.y
		var dy := maxf(0.0, boss.home.y - boss.global_position.y)
		var tl := (vy + sqrt(maxf(0.0, vy * vy + 2.0 * boss.gravity * dy))) / boss.gravity
		var lx := boss.velocity.x * tl * boss.facing
		var at := Vector2(lx, dy)
		draw_arc(at, 22.0, 0, TAU, 24, Color(Palette.CRIMSON_BRIGHT, 0.75), 1.5)
		draw_line(at + Vector2(-62, 0), at + Vector2(62, 0), Color(Palette.CRIMSON_BRIGHT, 0.45), 2.0)

	# Legs: heavy, wrapped.
	draw_line(hip + Vector2(-4, 0), Vector2(-6 - legs, 0), _c(Palette.DUST, flash, alpha), 5.0)
	draw_line(hip + Vector2(4, 0), Vector2(6 + legs, 0), _c(Palette.BONE_DIM, flash, alpha), 5.0)
	draw_line(Vector2(-9 - legs, 0), Vector2(-3 - legs, 0), _c(ROBE_DARK, flash, alpha), 3.0)
	draw_line(Vector2(3 + legs, 0), Vector2(9 + legs, 0), _c(ROBE_DARK, flash, alpha), 3.0)

	# Robe: huge hunched mass with a ragged hem and hanging chains.
	var hem := hip.y + 10.0
	var sway := sin(_t * 2.0) * 1.0
	var robe := PackedVector2Array([
		shoulder + Vector2(-14, 2), shoulder + Vector2(8, -1), shoulder + Vector2(12, 8),
		Vector2(hip.x + 13, hem - 2), Vector2(hip.x + 8, hem + 2), Vector2(hip.x + 3, hem - 1),
		Vector2(hip.x - 2, hem + 3), Vector2(hip.x - 8, hem), Vector2(hip.x - 14 + sway, hem + 2),
		Vector2(hip.x - 15, hip.y - 6),
	])
	draw_colored_polygon(robe, _c(ROBE, flash, alpha))
	draw_line(shoulder + Vector2(-14, 2), Vector2(hip.x - 14 + sway, hem + 2), _c(ROBE_DARK, flash, alpha), 2.0)
	# Rope belt with three small hanging bells.
	draw_line(Vector2(hip.x - 12, hip.y - 4), Vector2(hip.x + 12, hip.y - 6), _c(Palette.WOOD_LIGHT, flash, alpha), 1.5)
	for i in 3:
		var bx := hip.x - 7 + i * 7
		var by := hip.y - 2 + sin(_t * 4.0 + i) * 0.8
		draw_line(Vector2(bx, hip.y - 5), Vector2(bx, by), _c(IRON, flash, alpha), 1.0)
		draw_circle(Vector2(bx, by + 1.5), 1.6, _c(BRONZE, flash, alpha))
	# Hunched back cloth.
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-14, 2), shoulder + Vector2(-8, -6), shoulder + Vector2(2, -4)]), _c(ROBE_DARK, flash, alpha))

	# Bell helm.
	if not helm_off:
		_draw_bell(head, eye, flash, alpha)
	else:
		# The bell has fallen off and rolled away; the face beneath is just dark cloth.
		draw_circle(head, 5.0, _c(ROBE_DARK, flash, alpha))
		var roll := minf((f - 50) * 0.5, 26.0)
		_draw_bell(Vector2(-12 - roll, -6), 0.0, 0.0, alpha, deg_to_rad(-80.0 - roll * 6.0))

	# Arms and the clapper maul (two-handed).
	var hand := shoulder + Vector2(6.0, 8.0)
	var dir := Vector2.from_angle(deg_to_rad(club))
	if trail != Vector2.ZERO:
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 40.0)
		for i in range(8, -1, -1):
			pts.append(hand + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * 18.0)
		draw_colored_polygon(pts, Color(Palette.CRIMSON_BRIGHT, 0.30 * alpha))
	draw_line(shoulder + Vector2(-6, 2), hand + dir * 4.0, _c(ROBE_DARK, flash, alpha), 4.0)
	draw_line(shoulder + Vector2(4, 1), hand, _c(ROBE, flash, alpha), 4.0)
	var tip := hand + dir * 34.0
	draw_line(hand - dir * 6.0, tip, _c(IRON, flash, alpha), 3.0)
	draw_line(hand - dir * 4.0, tip - dir * 2.0, _c(Palette.STEEL_OXIDE, flash, alpha), 1.0)
	# Clapper head: a heavy iron teardrop.
	draw_circle(tip, 6.5, _c(IRON, flash, alpha))
	draw_circle(tip + dir * 3.0, 4.5, _c(IRON, flash, alpha))
	draw_circle(tip - dir.orthogonal() * 2.0, 2.0, _c(Palette.STEEL_OXIDE, flash, alpha))
	draw_circle(hand, 3.0, _c(Palette.BONE_DIM, flash, alpha))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(tip + Vector2(-6, 0), tip + Vector2(6, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.2)
		draw_line(tip + Vector2(0, -6), tip + Vector2(0, 6), Color(Palette.CRIMSON_BRIGHT, alpha), 1.2)
		draw_circle(tip, 2.5 + k * 1.5, Color(1, 0.85, 0.8, 0.75 * alpha))

	# Phase-change roar ring.
	if roar_ring >= 0.0:
		draw_arc(Vector2(0, -28), 20.0 + roar_ring * 70.0, 0, TAU, 36, Color(Palette.BONE, 0.6 * (1.0 - roar_ring)), 2.0)
		draw_arc(Vector2(0, -28), 12.0 + roar_ring * 50.0, 0, TAU, 36, Color(Palette.EMBER, 0.5 * (1.0 - roar_ring)), 1.5)

	# Riposte cue.
	if boss.is_riposte_ready():
		var y := -74.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 5), Vector2(4, y), Vector2(0, y + 5), Vector2(-4, y)]), Palette.GOLD_BRIGHT)


func _draw_bell(c: Vector2, eye: float, flash: float, alpha: float, rot := 0.0) -> void:
	draw_set_transform(c, rot, Vector2.ONE)
	# Dome, flared rim, crack.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7, 5), Vector2(-6, -2), Vector2(-4, -7), Vector2(0, -9), Vector2(4, -7),
		Vector2(6, -2), Vector2(7, 5), Vector2(9, 7), Vector2(-9, 7)]), _c(BRONZE, flash, alpha))
	draw_line(Vector2(-9, 7), Vector2(9, 7), _c(BRONZE_DARK, flash, alpha), 1.5)
	draw_line(Vector2(-5, -6), Vector2(-3, 0), _c(BRONZE_LIGHT, flash, alpha), 1.0)
	draw_rect(Rect2(-1.5, -11, 3, 3), _c(BRONZE_DARK, flash, alpha))
	draw_polyline(PackedVector2Array([Vector2(2, -8), Vector2(1, -3), Vector2(3, 0), Vector2(1, 4)]), _c(Palette.INK, flash, alpha), 1.0)
	# Eye slit with a burning ember behind it.
	draw_rect(Rect2(1, 1, 6, 1.6), _c(Palette.INK, flash, alpha))
	if eye > 0.0:
		var ec := Palette.EMBER.lerp(Palette.CRIMSON_BRIGHT, maxf(0.0, eye - 0.7) * 3.0)
		draw_circle(Vector2(5, 1.8), 0.8 + eye * 0.8, Color(ec, alpha))
		if eye >= 0.8:
			draw_circle(Vector2(5, 1.8), 3.0 + eye * 2.5, Color(Palette.EMBER, 0.2 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
