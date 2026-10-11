extends Node2D
## TEMPORARY ART — Oathguard: a tall armoured sentinel behind a tower shield, spear in
## the other hand. The shield cracks as its guard drains and flashes when struck.
## Guard break: shield flung up and aside, arms wide (riposte diamond above).
## Telegraphs glint (both attacks are parryable).

const PLATE := Color("5e6266")
const PLATE_D := Color("3e4145")
const SHIELD := Color("4b3a2c")
const SHIELD_RIM := Color("8b9290")

var enemy: ShieldEnemy
var _t := 0.0


func _ready() -> void:
	enemy = get_parent() as ShieldEnemy
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
	var sflash := 0.6 if enemy.shield_flash > 2 and Settings.flashes else 0.0
	var alpha := 1.0
	var legs := 0.0
	var crouch := 0.0
	var shield_off := Vector2(9, 0)
	var shield_rot := 0.0
	var spear_ext := 0.0
	var spear_ang := -0.15
	var glint_at := Vector2.ZERO
	var eye := 0.5
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 5.0) * 2.5
			eye = 0.8 if s == EnemyBase.State.CHASE else 0.5
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.5) + 1.0) * 0.4
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			eye = 1.0
			if r.attack:
				var p := r.phase_progress()
				var bash := r.attack.animation == &"bash"
				match r.phase:
					AttackRunner.Phase.STARTUP:
						crouch = 2.0 * p
						if bash:
							shield_off = Vector2(9 - 5 * p, 0)
						else:
							spear_ext = -8.0 * p
							spear_ang = 0.0
						if r.attack.startup_frames - r.frame <= 12:
							glint_at = Vector2(30 + spear_ext, -22) if not bash else Vector2(10, -34)
					AttackRunner.Phase.ACTIVE:
						if bash:
							shield_off = Vector2(18, -1)
						else:
							spear_ext = 22.0
							spear_ang = 0.0
					_:
						if bash:
							shield_off = Vector2(18 - 9 * p, 0)
						else:
							spear_ext = 22.0 * (1.0 - p)
							spear_ang = 0.0
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			crouch = 4.0
			shield_off = Vector2(-2, -14)
			shield_rot = -0.9
			spear_ang = -0.9
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			crouch = minf(f * 0.8, 22.0)
			shield_off = Vector2(10, 0)
			shield_rot = minf(f * 0.03, 1.4)
			eye = 0.0
	var hip := Vector2(0, -16.0 + crouch * 0.6)
	var shoulder := Vector2(1, -31.0 + crouch)
	var head := shoulder + Vector2(1, -6)
	draw_line(hip + Vector2(-3, 0), Vector2(-4 - legs, 0), _c(PLATE_D, flash, alpha), 3.5)
	draw_line(hip + Vector2(3, 0), Vector2(4 + legs, 0), _c(PLATE, flash, alpha), 3.5)
	# Spear (behind the body, held back hand)
	var hand := shoulder + Vector2(-2 + spear_ext * 0.5, 9)
	var sdir := Vector2.from_angle(spear_ang)
	var butt := hand - sdir * 16.0
	var tip := hand + sdir * (26.0 + spear_ext * 0.5)
	draw_line(butt, tip, _c(Palette.WOOD_LIGHT, flash, alpha), 1.5)
	draw_colored_polygon(PackedVector2Array([tip + sdir * 6.0, tip + sdir.orthogonal() * 2.0, tip - sdir.orthogonal() * 2.0]), _c(Palette.STEEL, flash, alpha))
	# Body: tabard over plate
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-7, 0), shoulder + Vector2(7, 0), hip + Vector2(6, 4), hip + Vector2(-6, 4)]), _c(PLATE, flash, alpha))
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-3, 3), shoulder + Vector2(3, 3), hip + Vector2(3, 6), hip + Vector2(-3, 6)]), _c(Palette.CRIMSON.darkened(0.3), flash, alpha))
	draw_line(shoulder + Vector2(-8, 0), shoulder + Vector2(8, 0), _c(PLATE_D, flash, alpha), 3.0)
	# Great helm with eye slit
	draw_rect(Rect2(head + Vector2(-4, -5), Vector2(8, 9)), _c(PLATE, flash, alpha))
	draw_rect(Rect2(head + Vector2(-4, -6), Vector2(8, 2)), _c(PLATE_D, flash, alpha))
	draw_line(head + Vector2(0, -1), head + Vector2(4, -1), Color(Palette.EMBER, alpha * eye), 1.0)
	# Tower shield in front
	var sc := shoulder + Vector2(0, 14) + shield_off
	draw_set_transform(sc, shield_rot, Vector2.ONE)
	var shc := SHIELD.lerp(Color.WHITE, maxf(flash, sflash))
	shc.a = alpha
	draw_rect(Rect2(-3, -17, 7, 32), shc)
	draw_rect(Rect2(-3, -17, 7, 32), _c(SHIELD_RIM, flash, alpha), false, 1.0)
	draw_line(Vector2(0.5, -15), Vector2(0.5, 13), _c(Palette.GOLD.darkened(0.3), flash, alpha * 0.8), 1.0)
	draw_line(Vector2(-2, -4), Vector2(3, -4), _c(Palette.GOLD.darkened(0.3), flash, alpha * 0.8), 1.0)
	var g := enemy.guard_ratio()
	var crack := Color(0.08, 0.06, 0.06, alpha)
	if g < 0.67:
		draw_polyline(PackedVector2Array([Vector2(-2, -12), Vector2(1, -7), Vector2(-1, -2), Vector2(2, 3)]), crack, 1.0)
	if g < 0.34:
		draw_polyline(PackedVector2Array([Vector2(3, -10), Vector2(0, -5), Vector2(3, 2), Vector2(-1, 9), Vector2(1, 14)]), crack, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glint_at != Vector2.ZERO:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(glint_at + Vector2(-5, 0), glint_at + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(glint_at + Vector2(0, -5), glint_at + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(glint_at, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -52.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
