extends Node2D
## TEMPORARY ART — Sir Orren, the Hollow Marshal: a tall knight in dull plate with a
## guttering crimson plume, a lance, and a tattered banner on his back.
## Telegraphs (gameplay-critical, see docs/ART_BIBLE.md):
##   - parryable thrust / sweep: crimson-white glint on the lance tip in the last 12 frames;
##   - unparryable charge / vault: red aura and burning visor during the wind-up;
##   - banner: the pole lifts and the cloth blazes gold while he calls the crows.

const PLATE := Color("565a60")
const PLATE_D := Color("3a3d42")
const PLATE_L := Color("7c8086")
const TABARD := Color("7a2630")
const GOLD := Color("c9a24a")

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
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


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
	var ang := -0.2          # lance angle (radians, 0 = forward, negative = up)
	var ext := 0.0           # lance pushed forward (px)
	var glint := false
	var danger := 0.0
	var banner_up := 0.0
	var eye := 0.5
	match s:
		EnemyBase.State.CHASE, EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			legs = sin(_t * 6.0) * 3.0
			lean = 1.5
			eye = 0.7
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.5) + 1.0) * 0.5
		EnemyBase.State.ATTACK:
			var r := boss.attack_runner
			eye = 1.0
			if r.attack:
				var p := r.phase_progress()
				var kind := r.attack.animation
				match r.phase:
					AttackRunner.Phase.STARTUP:
						match kind:
							&"thrust":
								ext = -12.0 * p
								ang = -0.05
								crouch = 2.0 * p
								glint = r.attack.startup_frames - r.frame <= 12
							&"sweep":
								ang = lerpf(-0.2, -1.9, ease(p, 0.6))
								lean = -3.0 * p
								glint = r.attack.startup_frames - r.frame <= 12
							&"charge":
								ang = 0.0
								lean = 4.0 * p
								crouch = 4.0 * p
								danger = 0.4 + 0.6 * p
							&"leap":
								ang = -1.2
								crouch = 6.0 * p
								danger = 0.4 + 0.6 * p
							&"banner":
								banner_up = ease(p, 0.5)
								ang = -1.0
					AttackRunner.Phase.ACTIVE:
						match kind:
							&"thrust":
								ext = 26.0
								ang = 0.0
								lean = 3.0
							&"sweep":
								ang = lerpf(-1.9, 0.9, ease(p, 0.3))
								lean = 4.0
							&"charge":
								ang = 0.0
								lean = 6.0
								crouch = 4.0
								danger = 0.8
							&"leap":
								ang = 1.1
								crouch = 3.0
							&"banner":
								banner_up = 1.0
								ang = -1.0
					_:
						match kind:
							&"thrust":
								ext = 26.0 * (1.0 - p)
								ang = 0.0
							&"sweep":
								ang = lerpf(0.9, -0.2, p)
							&"banner":
								banner_up = 1.0 - p
								ang = -1.0
							_:
								ang = -0.2
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			if boss.roaring:
				banner_up = 1.0
				ang = -1.0
				eye = 1.0
			else:
				crouch = 8.0 if s == EnemyBase.State.PARRIED else 3.0
				lean = -4.0
				ang = 0.8
				eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 120) / 90.0, 0.0, 1.0)
			crouch = minf(f * 0.5, 16.0)
			lean = -minf(f * 0.2, 6.0)
			ang = 1.3
			eye = 0.0
	var hip := Vector2(lean * 0.3, -22.0 + crouch * 0.6)
	var shoulder := Vector2(lean, -44.0 + crouch)
	var head := shoulder + Vector2(1 + lean * 0.2, -6)
	if danger > 0.0:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(0, -26), 30.0, Color(Palette.CRIMSON_BRIGHT, 0.12 * k * alpha))
	# Banner pole on the back
	var pole_base := shoulder + Vector2(-5, 2)
	var pole_ang := lerpf(-1.9, -1.35, banner_up)
	var pole_dir := Vector2.from_angle(pole_ang)
	var pole_tip := pole_base + pole_dir * 34.0
	draw_line(pole_base, pole_tip, _c(Palette.WOOD, flash, alpha), 1.5)
	var wave := sin(_t * 5.0) * 2.0
	var cloth := PackedVector2Array([pole_tip, pole_tip + Vector2(-13, 3 + wave), pole_tip + Vector2(-11, 9), pole_tip + Vector2(-14, 14 + wave), pole_tip + Vector2(-3, 14)])
	draw_colored_polygon(cloth, _c(TABARD.darkened(0.25).lerp(GOLD, banner_up * 0.7), flash, alpha * 0.9))
	if banner_up > 0.1:
		draw_circle(pole_tip + Vector2(-7, 7), 12.0, Color(GOLD, 0.12 * banner_up * alpha))
	# Legs
	draw_line(hip + Vector2(-4, 0), Vector2(-5 - legs, 0), _c(PLATE_D, flash, alpha), 4.0)
	draw_line(hip + Vector2(4, 0), Vector2(5 + legs, 0), _c(PLATE, flash, alpha), 4.0)
	# Torso: breastplate over crimson tabard
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-8, 0), shoulder + Vector2(8, -1), hip + Vector2(7, 5), hip + Vector2(-7, 6)]), _c(PLATE, flash, alpha))
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4, 3), shoulder + Vector2(4, 3), hip + Vector2(5, 12), hip + Vector2(-5, 12)]), _c(TABARD, flash, alpha))
	draw_line(hip + Vector2(0, 2), hip + Vector2(0, 11), _c(GOLD, flash, alpha), 1.0)
	draw_line(shoulder + Vector2(-9, 0), shoulder + Vector2(9, -1), _c(PLATE_L, flash, alpha), 3.0)
	# Great helm with a burning visor slit and a guttering plume
	draw_rect(Rect2(head + Vector2(-5, -6), Vector2(10, 12)), _c(PLATE, flash, alpha))
	draw_rect(Rect2(head + Vector2(-5, -7), Vector2(10, 3)), _c(PLATE_D, flash, alpha))
	draw_line(head + Vector2(-1, -1), head + Vector2(5, -1), Color(Palette.EMBER, alpha * eye), 1.5)
	var pl := sin(_t * 6.0) * 2.0
	draw_colored_polygon(PackedVector2Array([head + Vector2(-2, -7), head + Vector2(-12 + pl, -12), head + Vector2(-14 + pl, -6), head + Vector2(-5, -5)]), _c(Palette.CRIMSON, flash, alpha))
	# Lance
	var hand := shoulder + Vector2(6 + ext * 0.4, 12)
	var d := Vector2.from_angle(ang)
	var butt := hand - d * 20.0
	var tip := hand + d * (36.0 + ext * 0.6)
	draw_line(butt, tip, _c(Palette.WOOD_LIGHT, flash, alpha), 2.4)
	draw_colored_polygon(PackedVector2Array([tip + d * 9.0, tip + d.orthogonal() * 2.8, tip - d.orthogonal() * 2.8]), _c(Palette.STEEL, flash, alpha))
	draw_line(hand - d * 4.0, hand + d * 4.0, _c(PLATE_D, flash, alpha), 4.0)
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		var g := tip + d * 5.0
		draw_line(g + Vector2(-6, 0), g + Vector2(6, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(g + Vector2(0, -6), g + Vector2(0, 6), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(g, 2.5 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if boss.is_riposte_ready():
		var y := -70.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
