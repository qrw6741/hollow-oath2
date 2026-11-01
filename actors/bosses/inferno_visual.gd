extends Node2D
## TEMPORARY ART: the fire monster the old man becomes. A towering humanoid of living flame: glowing eyes,
## mouth and spine, burning fists, a crown of fire. Reads the parent boss's state; origin = feet.

const CORE := Color("ffd878")
const MID := Color("ff7a28")
const EDGE := Color("b8260c")
const SMOKE := Color("2a0c08")

var enemy: EnemyBase
var _t := 0.0
var _ink := false


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if enemy:
		scale = Vector2(enemy.facing * 1.8, 1.8)
	queue_redraw()


func _c(col: Color, flash: float, alpha: float) -> Color:
	if _ink:
		return Color(Palette.INK, alpha * 0.8)
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


func _draw() -> void:
	if enemy == null:
		return
	_ink = true
	for o in Settings.outline_offsets():
		_pose(o)
	_ink = false
	_pose(Vector2.ZERO)


func _flame(base: Vector2, h: float, w: float, seed_: float, col: Color) -> void:
	var sway := sin(_t * 9.0 + seed_) * w * 0.4
	var top := base + Vector2(sway, -h * (0.8 + 0.2 * sin(_t * 7.0 + seed_ * 1.3)))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), top, base + Vector2(w, 0)]), col)


func _pose(off: Vector2) -> void:
	var s := enemy.state
	var f := enemy.state_frame
	var flash := 1.0 if enemy.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var legs := 0.0
	var crouch := 0.0
	var lean := 0.0
	var arm := -20.0     # fist angle, degrees: 0 forward, -90 up, 90 down
	var glow := 0.6
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 5.0) * 4.0
			arm = -25.0 + sin(_t * 5.0) * 8.0
		EnemyBase.State.IDLE:
			crouch = sin(_t * 1.5) * 1.0
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				glow = 1.0
				match r.phase:
					AttackRunner.Phase.STARTUP:
						arm = lerpf(-20.0, -150.0, ease(p, 0.5))
						lean = -4.0 * p
						crouch = 3.0 * p
					AttackRunner.Phase.ACTIVE:
						arm = 80.0
						lean = 6.0
					_:
						arm = lerpf(80.0, -20.0, p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -6.0
			crouch = 4.0
			glow = 0.2
			arm = 50.0
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 90.0, 0.0, 1.0)
			crouch = minf(f * 0.6, 26.0)
			glow = maxf(0.0, 1.0 - f / 40.0)
			arm = 90.0
	draw_set_transform(off, 0.0, Vector2.ONE)
	var core := _c(CORE, flash, alpha)
	var mid := _c(MID, flash, alpha)
	var edge := _c(EDGE, flash, alpha)
	var rock := _c(Color("2b1612"), flash, alpha)
	var rock_l := _c(Color("4a2418"), flash, alpha)
	var tx := lean
	var pulse := 0.75 + 0.25 * sin(_t * 5.0)
	# heat aura behind the whole body
	if not _ink:
		draw_circle(Vector2(tx, -42 + crouch), 46.0 + 3.0 * pulse, Color(1.0, 0.4, 0.1, 0.07 * alpha * glow))
		draw_circle(Vector2(tx, -42 + crouch), 32.0, Color(1.0, 0.5, 0.1, 0.08 * alpha * glow))
	# legs: thick basalt columns with glowing knees and cracked shins
	for side in [-1, 1]:
		var ls: float = legs * side * -1.0
		var hip := Vector2(side * 7.0, -24 + crouch)
		var foot := Vector2(side * 8.0 + ls, 0)
		draw_colored_polygon(PackedVector2Array([hip + Vector2(-6, 0), hip + Vector2(6, 0), foot + Vector2(5, -4), foot + Vector2(7, 0), foot + Vector2(-7, 0), foot + Vector2(-5, -4)]), rock)
		draw_line(hip + Vector2(0, 4), foot + Vector2(0, -6), mid if not _ink else rock, 1.2)
		draw_circle(hip + Vector2(0, 8), 2.6, core if not _ink else rock)
	# pelvis and a broad torso that narrows to the waist, ribs glowing through cracks
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -24 + crouch), Vector2(11, -24 + crouch), Vector2(9, -30 + crouch), Vector2(-9, -30 + crouch)]), rock_l)
	draw_colored_polygon(PackedVector2Array([Vector2(-17 + tx, -54 + crouch), Vector2(-4 + tx, -58 + crouch), Vector2(8 + tx, -58 + crouch), Vector2(19 + tx, -54 + crouch), Vector2(11 + tx * 0.6, -30 + crouch), Vector2(-11 + tx * 0.6, -30 + crouch)]), rock)
	draw_colored_polygon(PackedVector2Array([Vector2(-17 + tx, -54 + crouch), Vector2(-4 + tx, -58 + crouch), Vector2(-6 + tx, -46 + crouch), Vector2(-13 + tx * 0.8, -40 + crouch)]), rock_l)
	if not _ink:
		for i in 4:
			var yy := -50.0 + crouch + i * 5.5
			var w := 10.0 - i * 1.2
			draw_line(Vector2(-w + tx * 0.8, yy), Vector2(w + tx * 0.8, yy + 1.5), Color(MID, alpha * (0.5 + 0.5 * glow)), 1.6)
		draw_line(Vector2(tx + 1, -56 + crouch), Vector2(tx * 0.5, -31 + crouch), Color(CORE, alpha * (0.5 + 0.5 * glow)), 1.8)   # spine seam
		draw_circle(Vector2(tx + 2, -42 + crouch), 5.0 * glow + 2.0, Color(CORE, alpha * 0.5))                               # heart
	# head: a heavy skull-like head with a burning jaw
	var hp := Vector2(2 + tx, -64 + crouch)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, -6), hp + Vector2(0, -10), hp + Vector2(8, -6), hp + Vector2(8, 3), hp + Vector2(4, 9), hp + Vector2(-4, 9), hp + Vector2(-8, 3)]), rock)
	if not _ink:
		draw_colored_polygon(PackedVector2Array([hp + Vector2(0, -3), hp + Vector2(7, -3), hp + Vector2(6, 0), hp + Vector2(0, 0)]), Color(CORE, alpha))      # eye
		draw_circle(hp + Vector2(4, -1.5), 1.2 + glow * 1.4, Color(1.0, 1.0, 0.9, alpha))
		draw_line(hp + Vector2(-3, 6), hp + Vector2(6, 6), Color(CORE, alpha), 1.8)                                                                           # the mouth
		for t in 4:
			draw_line(hp + Vector2(-2 + t * 2.6, 5), hp + Vector2(-2 + t * 2.6, 8), Color(MID, alpha), 1.0)
	# horns and a crown of living flame
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, -5), hp + Vector2(-16, -16), hp + Vector2(-6, -9)]), rock_l)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(8, -5), hp + Vector2(16, -16), hp + Vector2(6, -9)]), rock_l)
	for i in 9:
		_flame(hp + Vector2(-9 + i * 2.3, -8), 13.0 + (i % 4) * 5.0, 2.6, i * 1.9, mid if i % 2 == 0 else edge)
	_flame(hp + Vector2(0, -8), 22.0, 3.6, 0.5, core if not _ink else rock)
	# shoulders: spiked pauldrons; the front arm swings the burning fist, the back arm hangs
	var sh := Vector2(14 + tx, -52 + crouch)
	draw_colored_polygon(PackedVector2Array([sh + Vector2(-6, 2), sh + Vector2(-2, -8), sh + Vector2(5, -4), sh + Vector2(8, 4)]), rock_l)
	draw_colored_polygon(PackedVector2Array([sh + Vector2(-4, -6), sh + Vector2(0, -14), sh + Vector2(3, -6)]), edge)
	var elbow := sh + Vector2.from_angle(deg_to_rad(arm - 20.0)) * 14.0
	var fist := elbow + Vector2.from_angle(deg_to_rad(arm + 15.0)) * 14.0
	draw_line(sh, elbow, rock, 8.0)
	draw_line(elbow, fist, rock_l, 7.0)
	draw_circle(fist, 8.0, rock_l)
	if not _ink:
		draw_circle(fist, 6.0, Color(MID, alpha * 0.9))
		draw_circle(fist, 3.0, Color(CORE, alpha))
	for i in 4:
		_flame(fist + Vector2(-5 + i * 3.4, -4), 14.0, 2.6, i * 2.2, core if i == 1 and not _ink else edge)
	var bsh := Vector2(-15 + tx, -52 + crouch)
	var bel := bsh + Vector2(-4, 14)
	var bf := bel + Vector2.from_angle(deg_to_rad(95.0 - arm * 0.2)) * 14.0
	draw_colored_polygon(PackedVector2Array([bsh + Vector2(-8, 3), bsh + Vector2(-3, -8), bsh + Vector2(5, -3), bsh + Vector2(3, 4)]), rock_l)
	draw_line(bsh, bel, rock, 7.0)
	draw_line(bel, bf, rock_l, 6.0)
	draw_circle(bf, 6.5, rock_l)
	if not _ink:
		draw_circle(bf, 4.0, Color(EDGE, alpha))
	# embers and flame licks all over the body
	for i in 7:
		_flame(Vector2(-12 + i * 4.0 + tx * 0.5, -46 + crouch + (i % 3) * 7.0), 8.0, 2.2, i * 1.1, edge)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
