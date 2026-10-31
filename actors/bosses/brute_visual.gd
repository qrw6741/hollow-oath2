extends Node2D
## TEMPORARY ART — shared look for the two mini-bosses: a big, slow-moving bruiser holding a
## two-handed tool. style CELLARER: bald, leather apron, studded cask-club, throws bottles.
## style SEXTON: wide hat, long black coat, a grave-spade, a cold blue lantern on the belt.
## Telegraphs: overhead (smash) glints = parryable; sweep glows red where it can't be parried.

enum Style { CELLARER, SEXTON, CINDER, ASHFALL, SALT, GAOLER, FOUNDRY, REGENT, RINGER, THORN, IRON, BASILICA, CROWNLESS }
@export var style := Style.CELLARER

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
	var legs := 0.0
	var crouch := 0.0
	var lean := 0.0
	var arm := -60.0           # weapon angle: 0 forward, -90 straight up, +90 down
	var glint := false
	var danger := 0.0
	var eye := 0.5
	var bottle := false
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 6.0) * 3.0
			arm = -50.0 + sin(_t * 6.0) * 6.0
			eye = 0.8 if s == EnemyBase.State.CHASE else 0.5
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.4) + 1.0) * 0.5
			arm = -40.0
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				var an := r.attack.animation
				eye = 1.0
				if an == &"throw":
					bottle = true
					match r.phase:
						AttackRunner.Phase.STARTUP:
							arm = lerpf(-30.0, -150.0, ease(p, 0.6))
							glint = r.attack.startup_frames - r.frame <= 10
						AttackRunner.Phase.ACTIVE:
							arm = -10.0
						_:
							arm = lerpf(-10.0, -40.0, p)
				elif an == &"sweep" or an == &"charge":
					danger = 1.0 if not r.attack.parryable else 0.0
					match r.phase:
						AttackRunner.Phase.STARTUP:
							arm = lerpf(-20.0, 160.0, ease(p, 0.5))
							lean = -3.0 * p
							glint = r.attack.parryable and r.attack.startup_frames - r.frame <= 10
						AttackRunner.Phase.ACTIVE:
							arm = -10.0
							lean = 4.0
						_:
							arm = lerpf(-10.0, -40.0, p)
				else:
					danger = 1.0 if not r.attack.parryable else 0.0
					match r.phase:
						AttackRunner.Phase.STARTUP:
							arm = lerpf(-50.0, -170.0, ease(p, 0.5))
							lean = -3.0 * p
							glint = r.attack.parryable and r.attack.startup_frames - r.frame <= 10
						AttackRunner.Phase.ACTIVE:
							arm = 80.0
							lean = 5.0
						_:
							arm = lerpf(80.0, -40.0, p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -5.0
			crouch = 5.0 if s == EnemyBase.State.PARRIED else 2.0
			arm = 60.0
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 40) / 80.0, 0.0, 1.0)
			crouch = minf(f * 0.8, 24.0)
			lean = -minf(f * 0.25, 8.0)
			arm = 90.0
			eye = 0.0
	var cinder := style == Style.CINDER
	var ashfall := style == Style.ASHFALL
	var salt := style == Style.SALT
	var gaoler := style == Style.GAOLER
	var foundry := style == Style.FOUNDRY
	var regent := style == Style.REGENT
	var ringer := style == Style.RINGER
	var thorn := style == Style.THORN
	var iron := style == Style.IRON
	var basilica := style == Style.BASILICA
	var crownless := style == Style.CROWNLESS
	var sexton := style == Style.SEXTON or ashfall or salt or regent or ringer or thorn or basilica or crownless   # long-coat silhouette with a blade
	var coat := Color("2a2530") if sexton else Color("5a4a3a")
	var trim := Color("4a4258") if sexton else Color("8a7a60")
	if cinder:
		coat = Color("5a2018")
		trim = Color("e07a2c")
	elif ashfall:
		coat = Color("3a3a46")
		trim = Color("b8b8c8")
	elif salt:
		coat = Color("34505a")
		trim = Color("b6dce6")
	elif gaoler:
		coat = Color("40362f")
		trim = Color("8a8f98")
	elif foundry:
		coat = Color("4a2a1e")
		trim = Color("ff9a3c")
	elif thorn:
		coat = Color("3a2a34")
		trim = Color("c04060")
	elif iron:
		coat = Color("3c3a40")
		trim = Color("d0a050")
	elif basilica:
		coat = Color("2a4048")
		trim = Color("9ad0d8")
	elif crownless:
		coat = Color("2a2430")
		trim = Color("f0f0f8")
	elif ringer:
		coat = Color("5a4630")
		trim = Color("e0b060")
	elif regent:
		coat = Color("24202e")
		trim = Color("d8b44c")
	var hip := Vector2(lean * 0.3, -18.0 + crouch * 0.6)
	var shoulder := Vector2(2.0 + lean, -40.0 + crouch)
	var head := shoulder + Vector2(2.0, -8.0)
	draw_line(hip + Vector2(-3, 0), Vector2(-4 - legs, 0), _c(Palette.INK, flash, alpha), 3.4)
	draw_line(hip + Vector2(3, 0), Vector2(4 + legs, 0), _c(Palette.STONE_DARK, flash, alpha), 3.4)
	var long_coat := PackedVector2Array([shoulder + Vector2(-9, 1), shoulder + Vector2(9, 0), hip + Vector2(11, 12), hip + Vector2(-11, 12)])
	draw_colored_polygon(long_coat, _c(coat, flash, alpha))
	if sexton:
		for i in 4:
			draw_line(shoulder + Vector2(-6 + i * 4, 6), hip + Vector2(-7 + i * 4, 12), _c(trim, flash, alpha), 1.0)
		# Lantern on the belt
		var lp := hip + Vector2(9, 2)
		draw_rect(Rect2(lp + Vector2(-2, -2), Vector2(4, 6)), _c(Palette.STEEL_OXIDE, flash, alpha))
		draw_circle(lp + Vector2(0, 1), 1.6, Color(0.6, 0.85, 1.0, alpha))
		draw_circle(lp + Vector2(0, 1), 7.0 + sin(_t * 4.0), Color(0.6, 0.85, 1.0, 0.1 * alpha))
	else:
		draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-6, 8), shoulder + Vector2(6, 8), hip + Vector2(8, 11), hip + Vector2(-8, 11)]), _c(Color("c8bda0"), flash, alpha))
		draw_line(shoulder + Vector2(-6, 4), shoulder + Vector2(-9, 0), _c(trim, flash, alpha), 1.4)
	if cinder:
		# A halo of embers around the head and a smouldering hem.
		draw_circle(head, 9.0 + sin(_t * 5.0), Color(1.0, 0.5, 0.15, 0.18 * alpha))
		for i in 3:
			draw_circle(hip + Vector2(-8 + i * 8, 12 - absf(sin(_t * 3.0 + i)) * 3.0), 1.3, Color(1.0, 0.6, 0.2, 0.8 * alpha))
	if foundry:
		for i in 4:
			draw_circle(hip + Vector2(-9 + i * 6, 6 - absf(sin(_t * 4.0 + i)) * 4.0), 1.2, Color(1.0, 0.6, 0.2, 0.8 * alpha))
	if thorn:
		for i in 6:
			var tx := -9.0 + i * 3.6
			draw_line(shoulder + Vector2(tx, 8), shoulder + Vector2(tx + (3 if i % 2 else -3), 3 - (i % 3)), _c(Color("c04060"), flash, alpha), 1.2)
	if iron:
		# A turning gear on the back.
		var gp := shoulder + Vector2(-8, 4)
		draw_arc(gp, 6.0, 0.0, TAU, 12, _c(Color("d0a050"), flash, alpha), 1.6)
		for i in 6:
			var ga := _t * 1.5 + i * TAU / 6.0
			draw_line(gp + Vector2(cos(ga), sin(ga)) * 5.0, gp + Vector2(cos(ga), sin(ga)) * 8.0, _c(Color("d0a050"), flash, alpha), 1.6)
	if basilica:
		for i in 4:
			draw_circle(hip + Vector2(-8 + i * 5, 10 + sin(_t * 2.0 + i) * 2.0), 1.3, Color(0.6, 0.85, 0.95, 0.7 * alpha))
	if crownless:
		draw_circle(head + Vector2(0, -2), 12.0 + sin(_t * 2.5) * 1.5, Color(0.9, 0.9, 1.0, 0.09 * alpha))
		draw_arc(head + Vector2(0, -7), 6.0, PI, TAU, 10, Color(0.95, 0.95, 1.0, 0.5 * alpha), 1.0)
	if ringer:
		# A bronze bell hung at the hip, swinging with the stride.
		var bp := hip + Vector2(-10, 4 + sin(_t * 2.5) * 1.5)
		draw_colored_polygon(PackedVector2Array([bp + Vector2(-3, -4), bp + Vector2(3, -4), bp + Vector2(5, 4), bp + Vector2(-5, 4)]), _c(Color("c89a48"), flash, alpha))
		draw_circle(bp + Vector2(0, 5), 1.2, _c(Palette.INK, flash, alpha))
	if gaoler:
		for i in 5:
			var cx := -10.0 + i * 5.0
			draw_circle(shoulder + Vector2(cx, 10 + sin(_t * 3.0 + i) * 1.5), 1.6, _c(Palette.STEEL, flash, alpha))
	# Head
	draw_circle(head, 5.0, _c(Color("9a8f7c") if not sexton else Color("7a7468"), flash, alpha))
	if sexton:
		draw_rect(Rect2(head + Vector2(-8, -3), Vector2(16, 2)), _c(Palette.INK, flash, alpha))
		draw_colored_polygon(PackedVector2Array([head + Vector2(-5, -2.5), head + Vector2(0, -10), head + Vector2(5, -2.5)]), _c(Palette.INK, flash, alpha))
	if regent:
		for k in 5:
			var tx := -5.0 + k * 2.5
			draw_colored_polygon(PackedVector2Array([head + Vector2(tx - 1.2, -4.5), head + Vector2(tx, -9.5 - (k % 2) * 3.0), head + Vector2(tx + 1.2, -4.5)]), _c(Color("d8b44c"), flash, alpha))
		draw_circle(head, 11.0 + sin(_t * 3.0), Color(0.8, 0.7, 0.3, 0.1 * alpha))
	draw_rect(Rect2(head + Vector2(1.0, -0.4), Vector2(3.4, 1.4)), Color(Palette.CRIMSON_BRIGHT, eye * alpha) if eye > 0.1 else _c(Palette.INK, flash, alpha))
	# Weapon arm (both hands on the haft)
	var hand := shoulder + Vector2(7, 8)
	var dir := Vector2.from_angle(deg_to_rad(arm))
	draw_line(shoulder, hand, _c(coat, flash, alpha), 4.0)
	var tip := hand + dir * 30.0
	var butt := hand - dir * 8.0
	draw_line(butt, tip, _c(Palette.WOOD_LIGHT if not sexton else Color("6a5a40"), flash, alpha), 2.4)
	if sexton:
		# Spade blade
		var side := dir.rotated(PI / 2.0)
		draw_colored_polygon(PackedVector2Array([tip + side * 5.0, tip + dir * 9.0 + side * 3.0, tip + dir * 12.0, tip + dir * 9.0 - side * 3.0, tip - side * 5.0]), _c(Palette.STEEL, flash, alpha))
	else:
		# Studded cask-club head
		var side2 := dir.rotated(PI / 2.0)
		draw_colored_polygon(PackedVector2Array([tip - dir * 12.0 + side2 * 4.0, tip + dir * 6.0 + side2 * 6.0, tip + dir * 6.0 - side2 * 6.0, tip - dir * 12.0 - side2 * 4.0]), _c(Color("5a4028"), flash, alpha))
		for k in 3:
			draw_circle(tip - dir * (8.0 - k * 5.0) + side2 * 3.0, 0.9, _c(Palette.STEEL, flash, alpha))
	if bottle:
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-1.5, -4), tip + Vector2(1.5, -4), tip + Vector2(2.5, 3), tip + Vector2(-2.5, 3)]), Color(0.4, 0.7, 0.35, 0.9 * alpha))
	if glint:
		var k2 := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(tip + Vector2(-6, 0), tip + Vector2(6, 0), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
		draw_line(tip + Vector2(0, -6), tip + Vector2(0, 6), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
		draw_circle(tip, 2.0 + k2, Color(1, 0.95, 0.8, 0.7 * alpha))
	if danger > 0.0:
		draw_circle(tip, 6.0 + sin(_t * 30.0), Color(Palette.CRIMSON_BRIGHT, 0.35 * alpha))
	if enemy.is_riposte_ready():
		var y := -62.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
