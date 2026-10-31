extends Node2D
## TEMPORARY ART: a tall, skinny, mummy-wrapped lord with black flames (Enderman-thin limbs, pale
## bandages over a dark body, a masked head with two cold eye-slits). Used for the Twin Lords:
##   weapon 0 = the Reaper (a long scythe), weapon 1 = the Gunner (a bandaged hand-cannon).
## Telegraphs (gameplay-critical): the weapon edge/muzzle glows white-violet in the last 12 frames of a
## parryable wind-up; unparryable moves (leaps, sweeps) wrap the body in a red-black aura.
## Original design: no Marvel imagery is used; the 'wrapped moon' idea is only bandages and a pale mask.

const WRAP := Color("d2cab4")
const WRAP_D := Color("8f8770")
const CLOTH := Color("1d1a22")
const CLOTH_L := Color("2d2a36")
const FLAME := Color("120a1c")
const FLAME_EDGE := Color("8a55e8")
const EYE := Color("e8f0ff")

@export_range(0, 1) var weapon := 0
@export var tall := 1.0

var boss: BossBase
var _t := 0.0
var _ink := false
## While the arena's intro plays the lord is raised from the palm: 0 = hidden below, 1 = standing.
var rise := 1.0


func _ready() -> void:
	boss = get_parent() as BossBase
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if boss:
		scale.x = boss.facing
	queue_redraw()


func _c(col: Color, flash: float, alpha: float) -> Color:
	if _ink:
		return Color(Palette.INK, alpha * 0.9)
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


func _flame(at: Vector2, h: float, w: float, alpha: float, seed_: float) -> void:
	# one black flame tongue: dark body, a thin violet rim on the leading edge
	if _ink or alpha <= 0.01:
		return
	var sway := sin(_t * 7.0 + seed_) * w * 0.7
	var tip := at + Vector2(sway, -h)
	var pts := PackedVector2Array([at + Vector2(-w, 0), at + Vector2(-w * 0.5 + sway * 0.3, -h * 0.55), tip, at + Vector2(w * 0.5 + sway * 0.3, -h * 0.55), at + Vector2(w, 0)])
	draw_colored_polygon(pts, Color(FLAME, 0.92 * alpha))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4]]), Color(FLAME_EDGE, 0.55 * alpha), 1.0)


func _draw_body() -> void:
	if boss == null:
		return
	var s := boss.state
	var f := boss.state_frame
	var flash := 1.0 if boss.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := clampf(rise, 0.0, 1.0)
	var lean := 0.0
	var crouch := 0.0
	var legs := 0.0
	var ang := -0.5          # weapon angle (0 = forward, negative = up)
	var ext := 0.0
	var glint := false
	var danger := 0.0
	var eye := 0.7
	var flames := 1.0 + (0.7 if boss.phase >= 2 else 0.0)
	var recoil := 0.0
	var muzzle := 0.0
	match s:
		EnemyBase.State.CHASE, EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			legs = sin(_t * 5.0) * 4.0
			lean = 2.0
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.3) + 1.0) * 0.6
		EnemyBase.State.ATTACK:
			var r := boss.attack_runner
			eye = 1.0
			if r.attack:
				var p := r.phase_progress()
				var kind := r.attack.animation
				var late: bool = r.attack.startup_frames - r.frame <= 12
				match r.phase:
					AttackRunner.Phase.STARTUP:
						match kind:
							&"sweep":
								ang = lerpf(0.3, -2.4, ease(p, 0.6))
								lean = -4.0 * p
								danger = 0.3 + 0.5 * p
							&"smash":
								ang = lerpf(-0.5, -2.7, ease(p, 0.5))
								lean = -5.0 * p
								crouch = 3.0 * p
								glint = late and r.attack.parryable
							&"leap":
								ang = -2.2
								crouch = 9.0 * p
								danger = 0.4 + 0.6 * p
							&"shoot":
								ang = lerpf(-0.8, 0.0, p)
								lean = 1.0 + 3.0 * p
								glint = late
							&"butt":
								ang = lerpf(-0.2, -1.4, p)
								lean = -3.0 * p
					AttackRunner.Phase.ACTIVE:
						match kind:
							&"sweep":
								ang = lerpf(-2.4, 1.2, ease(p, 0.3))
								lean = 6.0
							&"smash":
								ang = lerpf(-2.7, 1.0, ease(p, 0.3))
								lean = 6.0
								crouch = 4.0
							&"leap":
								ang = 1.2
								crouch = 3.0
							&"shoot":
								ang = 0.0
								lean = 3.0
								recoil = 5.0 * (1.0 - p)
								muzzle = 1.0 - p
							&"butt":
								ang = lerpf(-1.4, 0.6, p)
								lean = 5.0
					_:
						match kind:
							&"sweep":
								ang = lerpf(1.2, -0.5, p)
							&"smash":
								ang = lerpf(1.0, -0.5, p)
							&"shoot":
								ang = lerpf(0.0, -0.8, p)
								recoil = 2.0 * (1.0 - p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			if boss.roaring:
				ang = -1.7
				eye = 1.0
				flames = 2.6
				lean = -2.0
			else:
				crouch = 10.0 if s == EnemyBase.State.PARRIED else 4.0
				lean = -5.0
				ang = 0.9
				eye = 0.1
		EnemyBase.State.DEAD:
			alpha *= clampf(1.0 - (f - 110) / 100.0, 0.0, 1.0)
			crouch = minf(f * 0.7, 26.0)
			lean = -minf(f * 0.25, 8.0)
			ang = 1.4
			eye = 0.0
			flames = 2.2
	var k := tall
	var hip := Vector2(lean * 0.3, -32.0 * k + crouch * 0.7)
	var shoulder := Vector2(lean, -58.0 * k + crouch)
	var head := shoulder + Vector2(1.0 + lean * 0.15, -9.0)
	var drop := (1.0 - clampf(rise, 0.0, 1.0)) * 70.0
	hip.y += drop
	shoulder.y += drop
	head.y += drop
	if danger > 0.0:
		var kk := danger * (0.7 + 0.3 * sin(_t * 28.0))
		draw_circle(Vector2(0, -36 + drop), 38.0, Color(Palette.CRIMSON_BRIGHT, 0.10 * kk * alpha))
	# long thin legs (stilted, bandaged)
	var foot_l := Vector2(-4 - legs, drop)
	var foot_r := Vector2(4 + legs, drop)
	for foot in [foot_l, foot_r]:
		var knee: Vector2 = (hip + foot) * 0.5 + Vector2(1.5, 0)
		draw_line(hip + Vector2(sign(foot.x) * 2.0, 0), knee, _c(CLOTH, flash, alpha), 3.0)
		draw_line(knee, foot, _c(CLOTH_L, flash, alpha), 2.6)
		for i in 5:
			var q: Vector2 = hip.lerp(foot, 0.15 + i * 0.17)
			draw_line(q + Vector2(-1.6, -0.6), q + Vector2(1.6, 0.8), _c(WRAP, flash, alpha), 0.9)
	# slim torso: dark cloth crossed with bandage straps
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4.5, 0), shoulder + Vector2(4.5, -0.5), hip + Vector2(3, 0), hip + Vector2(-3, 0)]), _c(CLOTH, flash, alpha))
	for i in 6:
		var y := float(i) / 5.0
		var a2 := shoulder.lerp(hip, y)
		draw_line(a2 + Vector2(-4.5 + y, 0), a2 + Vector2(4.5 - y, 3.0), _c(WRAP, flash, alpha), 1.1)
	draw_line(shoulder + Vector2(-5, 0), shoulder + Vector2(5, -0.5), _c(WRAP_D, flash, alpha), 2.0)
	# the off-hand arm: very long and thin, hanging or guarding
	var off_hand := shoulder + Vector2(-5.0 - recoil * 0.2, 14.0 + (6.0 if s == EnemyBase.State.CHASE else 0.0))
	draw_line(shoulder + Vector2(-3, 1), off_hand, _c(CLOTH_L, flash, alpha), 2.0)
	draw_line(off_hand, off_hand + Vector2(-1.5, 7.0), _c(WRAP, flash, alpha), 1.4)
	# head: pale bandaged mask, a hood of dark cloth, two cold eye slits
	draw_rect(Rect2(head + Vector2(-3.5, -7), Vector2(7, 13)), _c(WRAP, flash, alpha))
	draw_rect(Rect2(head + Vector2(-4.0, -8), Vector2(8, 3.5)), _c(CLOTH, flash, alpha))
	for i in 3:
		draw_line(head + Vector2(-3.5, -3 + i * 3), head + Vector2(3.5, -1.5 + i * 3), _c(WRAP_D, flash, alpha), 0.8)
	if not _ink:
		draw_line(head + Vector2(0.5, -2), head + Vector2(3.6, -2), Color(EYE, alpha * eye), 1.4)
		draw_circle(head + Vector2(2.5, -2), 3.5 + 1.5 * eye, Color(0.7, 0.8, 1.0, 0.10 * eye * alpha))
	# weapon in the main hand
	var hand := shoulder + Vector2(6.0 + ext * 0.3 - recoil, 12.0)
	draw_line(shoulder + Vector2(3, 1), hand, _c(CLOTH_L, flash, alpha), 2.0)
	var d := Vector2.from_angle(ang)
	if weapon == 0:
		# the scythe: a long pole, a curved blade, and black flame along the cutting edge
		var butt := hand - d * 22.0
		var top := hand + d * 34.0
		draw_line(butt, top, _c(WRAP_D, flash, alpha), 2.0)
		for i in 5:
			var q := butt.lerp(top, 0.1 + 0.2 * i)
			draw_line(q + d.orthogonal() * 1.5, q - d.orthogonal() * 1.5, _c(WRAP, flash, alpha), 0.9)
		var o := d.orthogonal()
		var blade := PackedVector2Array([top, top + d * 6.0 - o * 8.0, top + d * 20.0 - o * 11.0, top + d * 31.0 - o * 3.0, top + d * 22.0 - o * 6.0, top + d * 9.0 - o * 3.0])
		draw_colored_polygon(blade, _c(Palette.STEEL.darkened(0.2), flash, alpha))
		if not _ink:
			draw_polyline(PackedVector2Array([blade[1], blade[2], blade[3]]), Color(FLAME_EDGE, (0.9 if glint else 0.5) * alpha), 1.2)
			if glint:
				var g := top + d * 18.0 - o * 8.0
				draw_circle(g, 2.5 + 1.5 * sin(_t * 40.0), Color(0.9, 0.85, 1.0, 0.85 * alpha))
	else:
		# the hand-cannon: a bandaged barrel with a glowing bore; the muzzle flares when it fires
		var butt2 := hand - d * 8.0
		var muzz := hand + d * 28.0
		draw_line(butt2, muzz, _c(CLOTH_L, flash, alpha), 3.4)
		for i in 4:
			var q := butt2.lerp(muzz, 0.12 + 0.24 * i)
			draw_line(q + d.orthogonal() * 2.0, q - d.orthogonal() * 2.0, _c(WRAP, flash, alpha), 1.0)
		draw_line(hand - d * 6.0, hand - d * 6.0 + d.orthogonal() * 6.0, _c(CLOTH, flash, alpha), 2.0)
		if not _ink:
			if glint:
				draw_circle(muzz, 2.0 + 1.5 * sin(_t * 40.0), Color(0.9, 0.85, 1.0, 0.85 * alpha))
			if muzzle > 0.0:
				draw_circle(muzz + d * 4.0, 7.0 * muzzle + 2.0, Color(FLAME_EDGE, 0.6 * muzzle * alpha))
				draw_circle(muzz + d * 3.0, 3.5 * muzzle + 1.0, Color(1, 1, 1, 0.9 * muzzle * alpha))
	# black flames: crown, shoulders, hands, ankles (heavier in phase 2 / while enraged)
	if not _ink and alpha > 0.0:
		var fa := alpha * clampf(flames, 0.4, 1.6)
		_flame(head + Vector2(-2, -8), 11.0 * flames, 2.6, fa, 0.0)
		_flame(head + Vector2(2, -8), 14.0 * flames, 2.8, fa, 1.7)
		_flame(head + Vector2(0, -8), 8.0 * flames, 2.0, fa, 3.1)
		_flame(shoulder + Vector2(-5, -1), 8.0 * flames, 2.4, fa, 0.9)
		_flame(shoulder + Vector2(5, -1), 8.0 * flames, 2.4, fa, 2.4)
		_flame(hand + Vector2(0, -2), 7.0 * flames, 2.0, fa, 4.0)
		_flame(foot_l + Vector2(0, -1), 5.0 * flames, 2.0, fa, 5.0)
		_flame(foot_r + Vector2(0, -1), 5.0 * flames, 2.0, fa, 6.0)
	if boss.is_riposte_ready():
		var y := -88.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)


func _draw() -> void:
	_ink = true
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_set_transform(o, 0.0, Vector2.ONE)
		_draw_body()
	_ink = false
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body()
