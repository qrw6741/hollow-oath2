extends Node2D
## TEMPORARY ART — the Drowned Canon: a tall, bloated Candlewright priest in sodden grey
## vestments and a crooked mitre, face hidden behind a dripping wax mask, swinging a long
## rosary chain weighted with a bronze censer.
## Telegraphs: lash = crimson glint on the censer (parryable); spit = green glow in the mask
## (parryable shots); Undertow = sinks, then a ring of bubbles marks where it will burst up
## (unparryable, move away); Flood Psalm = arms raised and a red aura (unparryable, jump the wave).

const ROBE := Color("55595c")
const ROBE_DARK := Color("3a3e41")
const WAX := Color("d8cfb4")
const KELP := Color("2f4a3a")
const BRONZE := Color("7a5a33")

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
	if _ink:
		return Color(Palette.INK, alpha * 0.9)
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


func _draw_body() -> void:
	if boss == null:
		return
	var s := boss.state
	var f := boss.state_frame
	var flash := 1.0 if boss.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var lean := 0.0
	var sink := 0.0            # 0 standing .. 1 fully under water
	var arm := 70.0            # rosary angle (0 forward, -90 up)
	var reach := 26.0
	var trail := Vector2.ZERO
	var glint := false
	var mouth := 0.0
	var danger := 0.0
	var arms_up := 0.0
	var bubbles := false
	var geyser := 0.0
	var roar_ring := -1.0
	var bob := sin(_t * 1.5) * 1.2

	match s:
		EnemyBase.State.CHASE:
			lean = 2.0
			arm = 70.0 + sin(_t * 3.0) * 10.0
		EnemyBase.State.RECOVER:
			lean = -1.0
		EnemyBase.State.ATTACK:
			var r := boss.attack_runner
			if r.attack:
				var anim: StringName = r.attack.animation
				var p := r.phase_progress()
				match anim:
					&"lash", &"lash_back":
						var a0 := 160.0 if anim == &"lash" else -10.0
						var a1 := -5.0 if anim == &"lash" else 150.0
						match r.phase:
							AttackRunner.Phase.STARTUP:
								arm = lerpf(70.0, a0, ease(p, 0.5))
								reach = 26.0
								lean = -2.0 * p
								glint = r.attack.startup_frames - r.frame <= 12
							AttackRunner.Phase.ACTIVE:
								arm = lerpf(a0, a1, ease(p, 0.3))
								reach = 58.0
								trail = Vector2(a0, arm)
								lean = 3.0
							_:
								arm = lerpf(a1, 70.0, p)
								reach = lerpf(58.0, 26.0, p)
					&"spit":
						match r.phase:
							AttackRunner.Phase.STARTUP:
								lean = -3.0 * p
								mouth = p
							AttackRunner.Phase.ACTIVE:
								lean = 3.0
								mouth = 1.0
							_:
								mouth = 1.0 - p
					&"submerge":
						danger = 0.5
						var cb := boss as DrownedCanon
						if f < cb.sink_frame:
							sink = float(f) / cb.sink_frame
						elif cb.submerged:
							sink = 1.0
							bubbles = true
						else:
							geyser = 1.0 - p if r.phase != AttackRunner.Phase.STARTUP else 1.0
					&"wave":
						match r.phase:
							AttackRunner.Phase.STARTUP:
								arms_up = ease(p, 0.5)
								danger = 0.4 + 0.6 * p
							AttackRunner.Phase.ACTIVE:
								arms_up = 0.0
								lean = 4.0
							_:
								arms_up = 0.0
		EnemyBase.State.STAGGER:
			if boss.roaring:
				arms_up = 1.0
				danger = 0.5
				roar_ring = clampf((f - 20) / 30.0, 0.0, 1.0) if f >= 20 else -1.0
			else:
				lean = -4.0
				arm = 110.0
		EnemyBase.State.PARRIED:
			lean = -4.0
			sink = 0.12
			arm = 130.0
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 100) / 90.0, 0.0, 1.0)
			sink = minf(f / 120.0, 0.85)
			lean = -minf(f * 0.2, 6.0)

	var drop := sink * 64.0
	var a := alpha * (1.0 - sink * 0.85)
	if danger > 0.0 and sink < 0.9:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(0, -32 + drop), 30.0, Color(Palette.CRIMSON_BRIGHT, 0.1 * k * alpha))

	if bubbles:
		# The tell: a widening ring of bubbles where it will surface.
		var cb := boss as DrownedCanon
		var tleft := float(boss.attack_runner.attack.startup_frames - f) / maxf(1.0, boss.attack_runner.attack.startup_frames - cb.move_frame)
		draw_arc(Vector2(0, -2), 26.0 * (1.0 - tleft * 0.5), 0, TAU, 24, Color(Palette.CRIMSON_BRIGHT, 0.6), 1.5)
		for i in 9:
			var bx := sin(_t * 3.0 + i * 1.7) * 18.0
			var by := -fmod(_t * 40.0 + i * 13.0, 26.0)
			draw_circle(Vector2(bx, by), 1.6, Color(0.75, 0.9, 0.9, 0.8))
	if geyser > 0.0:
		draw_rect(Rect2(-20, -84 * geyser, 40, 84 * geyser), Color(0.55, 0.75, 0.78, 0.55 * geyser))
		for i in 7:
			draw_circle(Vector2(sin(i * 2.1) * 16.0, -84 * geyser + i * 6.0), 3.0, Color(0.85, 0.95, 0.95, 0.6 * geyser))

	if a <= 0.02:
		return
	var hip := Vector2(lean * 0.3, -26.0 + drop + bob * 0.3)
	var shoulder := Vector2(3.0 + lean, -52.0 + drop + bob)
	var head := shoulder + Vector2(5.0 + lean * 0.3, -7.0)

	# Vestments: long, bell-shaped, dripping, hung with kelp.
	var hem := hip.y + 26.0
	draw_colored_polygon(PackedVector2Array([
		shoulder + Vector2(-11, 2), shoulder + Vector2(9, 0), Vector2(hip.x + 15, hem - 2), Vector2(hip.x + 9, hem + 2),
		Vector2(hip.x + 2, hem - 1), Vector2(hip.x - 5, hem + 2), Vector2(hip.x - 12, hem), Vector2(hip.x - 16, hem - 3)]), _c(ROBE, flash, a))
	draw_line(shoulder + Vector2(-11, 2), Vector2(hip.x - 16, hem - 3), _c(ROBE_DARK, flash, a), 2.0)
	draw_line(shoulder + Vector2(-1, 2), Vector2(hip.x + 1, hem - 2), _c(Palette.CRIMSON, flash, a), 1.5)   # stole
	for i in 4:
		var kx := hip.x - 10 + i * 6
		draw_line(Vector2(kx, hip.y - 6 + i % 2 * 4), Vector2(kx + sin(_t * 2.0 + i) * 2.0, hem + 3), _c(KELP, flash, a), 1.5)
	# Drips
	for i in 3:
		var dy := fmod(_t * 30.0 + i * 11.0, 22.0)
		draw_circle(Vector2(hip.x - 8 + i * 8, hem - 6 + dy), 0.9, Color(0.7, 0.85, 0.9, 0.6 * a))

	# Mitre (crooked) and wax mask
	draw_colored_polygon(PackedVector2Array([head + Vector2(-5, -4), head + Vector2(-2, -18), head + Vector2(4, -15), head + Vector2(5, -4)]), _c(Color("b9b29c"), flash, a))
	draw_line(head + Vector2(-1, -16), head + Vector2(1, -5), _c(Palette.CRIMSON, flash, a), 1.0)
	draw_circle(head, 5.0, _c(WAX, flash, a))
	for i in 3:
		draw_line(head + Vector2(-3 + i * 3, 3), head + Vector2(-3 + i * 3, 6 + i % 2 * 3 + sin(_t + i)), _c(WAX, flash, a), 1.2)
	draw_rect(Rect2(head + Vector2(1, -1.5), Vector2(3.5, 1.2)), _c(Palette.INK, flash, a))
	if mouth > 0.0:
		draw_circle(head + Vector2(3, 2.5), 1.0 + mouth * 1.5, Color(0.5, 0.85, 0.4, a))
		draw_circle(head + Vector2(3, 2.5), 4.0 + mouth * 4.0, Color(0.5, 0.85, 0.4, 0.2 * a))

	# Arms
	if arms_up > 0.0:
		for side in [-1.0, 1.0]:
			var hand := shoulder + Vector2(side * 8.0, 4.0).lerp(Vector2(side * 10.0, -22.0), arms_up)
			draw_line(shoulder + Vector2(side * 4.0, 2.0), hand, _c(ROBE, flash, a), 3.0)
			draw_circle(hand, 2.2, _c(WAX, flash, a))
	# Rosary lash
	var hand2 := shoulder + Vector2(6, 6)
	draw_line(shoulder + Vector2(3, 2), hand2, _c(ROBE, flash, a), 3.0)
	if trail != Vector2.ZERO:
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(hand2 + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * reach)
		for i in range(8, -1, -1):
			pts.append(hand2 + Vector2.from_angle(deg_to_rad(lerpf(trail.x, trail.y, i / 8.0))) * reach * 0.4)
		draw_colored_polygon(pts, Color(Palette.CRIMSON_BRIGHT, 0.28 * a))
	var dir := Vector2.from_angle(deg_to_rad(arm))
	var sag := Vector2(0, 6.0 if reach < 40.0 else 2.0)
	var beads := 10
	var tip := hand2 + dir * reach
	for i in beads + 1:
		var t := float(i) / beads
		var pnt := hand2.lerp(tip, t) + sag * sin(t * PI)
		draw_circle(pnt, 1.1, _c(Color("8d8673"), flash, a))
	draw_circle(tip, 3.2, _c(BRONZE, flash, a))
	draw_circle(tip, 1.4, Color(0.5, 0.85, 0.4, 0.8 * a))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(tip + Vector2(-5, 0), tip + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, a), 1.0)
		draw_line(tip + Vector2(0, -5), tip + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, a), 1.0)
		draw_circle(tip, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * a))

	if roar_ring >= 0.0:
		draw_arc(Vector2(0, -30), 20.0 + roar_ring * 70.0, 0, TAU, 36, Color(0.7, 0.9, 0.9, 0.6 * (1.0 - roar_ring)), 2.0)
	if boss.is_riposte_ready():
		var y := -80.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 5), Vector2(4, y), Vector2(0, y + 5), Vector2(-4, y)]), Palette.GOLD_BRIGHT)


## 1 px ink outline: the body drawn four times in ink, shifted, then once in colour on top.
var _ink := false


func _draw() -> void:
	_ink = true
	for o in Settings.outline_offsets():
		draw_set_transform(o, 0.0, Vector2.ONE)
		_draw_body()
	_ink = false
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body()
