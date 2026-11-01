extends Node2D
## TEMPORARY ART: the Lower Hell's fox mini-boss. A big russet fox with a white-tipped tail that crouches,
## leaps (body stretches, tail streams) and slams the ground. Reads the parent boss's state like the other
## boss visuals; origin = feet, faces right (flipped by facing).

const FUR := Color("d9702e")
const FUR_L := Color("f0a050")
const FUR_D := Color("9a4120")
const WHITE := Color("f3ead6")
const SOCK := Color("2a1a1a")
const DARK := Color("160c10")
const EYE := Color("ffd84a")
const EMBER := Color("ff8a2a")

var enemy: EnemyBase
var _t := 0.0
var _ink := false


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if enemy:
		scale = Vector2(enemy.facing * 1.55, 1.55)
	queue_redraw()


func _c(col: Color, flash: float, alpha: float) -> Color:
	if _ink:
		return Color(Palette.INK, alpha * 0.9)
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


func _pose(off: Vector2) -> void:
	var s := enemy.state
	var f := enemy.state_frame
	var flash := 1.0 if enemy.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var crouch := 0.0     # px the body sinks
	var rot := 0.0
	var legs := 0.0
	var tail := sin(_t * 3.0) * 0.12
	var jaws := 0.0
	var eye := 0.8
	var danger := false
	var airborne: bool = enemy.get(&"leaping") == true or not enemy.is_on_floor()
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 12.0) * 5.0
			crouch = 1.0 + absf(sin(_t * 12.0)) * 1.0
			tail = sin(_t * 6.0) * 0.25
		EnemyBase.State.IDLE:
			crouch = 1.0 + sin(_t * 2.0) * 0.6
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				var an := r.attack.animation
				eye = 1.0
				danger = not r.attack.parryable
				if an == &"leap":
					match r.phase:
						AttackRunner.Phase.STARTUP:
							crouch = lerpf(1.0, 9.0, ease(minf(p * 1.3, 1.0), 0.5))
							rot = lerpf(0.0, 0.25, p)
							tail = lerpf(0.0, -0.6, p)
						AttackRunner.Phase.ACTIVE:
							crouch = 12.0       # the landing: slammed flat into the floor
							rot = -0.15
							tail = 0.5
						_:
							crouch = lerpf(12.0, 1.0, p)
					if airborne and r.phase == AttackRunner.Phase.STARTUP and f > 14:
						crouch = -10.0
						rot = -0.5
						legs = -8.0
						tail = 0.8
				else:
					match r.phase:
						AttackRunner.Phase.STARTUP:
							crouch = lerpf(1.0, 5.0, p)
							rot = lerpf(0.0, 0.2, p)
							jaws = lerpf(0.0, 4.0, p)
						AttackRunner.Phase.ACTIVE:
							rot = -0.2
							jaws = 0.0
							legs = 5.0
						_:
							jaws = lerpf(0.0, 2.0, p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			crouch = 7.0
			rot = 0.3
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 40) / 80.0, 0.0, 1.0)
			crouch = 14.0
			rot = 0.9
			eye = 0.0
	if airborne and s != EnemyBase.State.DEAD and s != EnemyBase.State.ATTACK:
		rot = -0.3
		crouch = -6.0
		legs = -8.0
	draw_set_transform(off + Vector2(0, -12 + crouch * 0.6), rot, Vector2.ONE)
	var fur := _c(FUR, flash, alpha)
	var fur_l := _c(FUR_L, flash, alpha)
	var fur_d := _c(FUR_D, flash, alpha)
	var white := _c(WHITE, flash, alpha)
	var sock := _c(SOCK, flash, alpha)
	var dark := _c(DARK, flash, alpha)
	var ember := _c(EMBER, flash, alpha)
	# tail: a big plume, banded dark at the root, white at the tip, streaming with the motion
	var tpts := PackedVector2Array()
	for i in 10:
		var k := float(i) / 9.0
		tpts.append(Vector2(-14.0 - k * 26.0, -6.0 - sin(k * 2.2 + tail * 3.0) * 11.0 - tail * 22.0 * k))
	for i in 9:
		var k2 := float(i) / 8.0
		var col := fur_d if i < 2 else (fur if i < 6 else (fur_l if i < 7 else white))
		draw_line(tpts[i], tpts[i + 1], col, lerpf(6.0, 11.0, sin(k2 * PI * 0.9)) + (3.0 if i >= 7 else 0.0))
	# far-side legs first (darker), then near-side, black "socks" at the paws
	var lpos := [[-13.0, 0.55], [-7.0, 0.35], [10.0, 0.4], [15.0, 0.6]]
	for i in 4:
		var lx: float = lpos[i][0]
		var sw: float = legs * (1.0 if i % 2 == 0 else -1.0)
		var top := Vector2(lx, -4.0)
		var knee := Vector2(lx + sw * 0.25 + (2.0 if i >= 2 else -2.0), 4.0 - crouch * 0.1)
		var paw := Vector2(lx + sw * 0.5, 12.0 - crouch * 0.4)
		var lc := fur_d if i % 2 == 1 else fur
		draw_line(top, knee, lc, 4.6)
		draw_line(knee, paw, sock, 3.6)
		draw_circle(paw, 2.2, sock)
	# body: arched back, deep chest, light belly
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -2), Vector2(-17, -13), Vector2(-6, -19), Vector2(8, -19), Vector2(17, -14), Vector2(21, -6), Vector2(14, 1), Vector2(-2, 3), Vector2(-14, 2)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -13), Vector2(-6, -19), Vector2(8, -19), Vector2(17, -14), Vector2(10, -13), Vector2(-4, -15), Vector2(-14, -10)]), fur_d)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 1), Vector2(-2, 3), Vector2(14, 1), Vector2(19, -5), Vector2(10, -4), Vector2(-4, -3)]), white)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -12), Vector2(4, -15), Vector2(12, -11), Vector2(4, -9), Vector2(-4, -8)]), fur_l)
	# ember markings along the spine: a hell fox
	if not _ink:
		for i in 5:
			var ex := -12.0 + i * 6.5
			draw_line(Vector2(ex, -17.5 + absf(i - 2) * 1.0), Vector2(ex + 3.0, -14.5 + absf(i - 2) * 1.0), Color(ember, alpha * (0.6 + 0.4 * sin(_t * 4.0 + i))), 1.6)
	# neck and head: long snout, white muzzle and cheek ruff, tall ears with dark insides
	var hp := Vector2(20, -17)
	draw_colored_polygon(PackedVector2Array([Vector2(12, -18), hp + Vector2(-2, -8), hp + Vector2(6, 3), Vector2(14, -2)]), fur)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-6, -7), hp + Vector2(5, -10), hp + Vector2(20, -1), hp + Vector2(21, 1), hp + Vector2(7, 5), hp + Vector2(-5, 5)]), fur)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(5, -2), hp + Vector2(20, 0), hp + Vector2(21, 1.5), hp + Vector2(7, 6 + jaws), hp + Vector2(-3, 6)]), white)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-6, 2), hp + Vector2(-9, 7), hp + Vector2(-2, 6), hp + Vector2(2, 9), hp + Vector2(3, 3)]), white)   # cheek ruff
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-5, -8), hp + Vector2(-3, -24), hp + Vector2(4, -9)]), fur)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-4, -9), hp + Vector2(-3, -20), hp + Vector2(1, -10)]), dark)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(3, -9), hp + Vector2(9, -23), hp + Vector2(11, -7)]), fur_d)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(5, -9), hp + Vector2(9, -19), hp + Vector2(9, -8)]), dark)
	draw_circle(hp + Vector2(21, 0.5), 1.8, dark)   # nose
	draw_line(hp + Vector2(2, -4), hp + Vector2(0, -6), dark, 1.2)
	if not _ink:
		var ec := EYE if not danger else Color("ff4a2a")
		draw_line(hp + Vector2(6, -3), hp + Vector2(11, -1.5), Color(dark, alpha), 2.2)
		draw_circle(hp + Vector2(8, -2.2), 1.5 + eye * 0.5, Color(ec, alpha * clampf(eye + 0.2, 0.0, 1.0)))
		for w in 2:
			draw_line(hp + Vector2(13, 1), hp + Vector2(21, 3 + w * 2), Color(white, alpha * 0.7), 0.7)
	if jaws > 1.0 and not _ink:
		draw_line(hp + Vector2(12, 4), hp + Vector2(12, 6 + jaws), white, 1.6)
		draw_line(hp + Vector2(16, 3), hp + Vector2(16, 5 + jaws), white, 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
