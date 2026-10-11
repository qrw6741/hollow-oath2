extends Node2D
## TEMPORARY ART — Ember Acolyte: a thin Candlewright novice in pale, wax-stained robes
## with a tall candle-crown and a burning censer on a chain.
## Telegraph: the censer flares and swings back for the whole wind-up of a throw; a
## gold glint marks the moment it is released (the projectile can be parried).

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
	var legs := 0.0
	var crouch := 0.0
	var swing := 40.0          # censer chain angle (0 forward, 90 down)
	var glow := 0.4
	var glint := false
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			legs = sin(_t * 8.0) * 2.0
			swing = 80.0 + sin(_t * 4.0) * 10.0
		EnemyBase.State.CHASE:
			legs = sin(_t * 11.0) * 3.0
			lean = 1.5
			swing = 70.0 + sin(_t * 6.0) * 15.0
			glow = 0.6
		EnemyBase.State.IDLE:
			swing = 85.0 + sin(_t * 2.0) * 6.0
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				glow = 1.0
				match r.phase:
					AttackRunner.Phase.STARTUP:
						swing = lerpf(80.0, 220.0, ease(p, 0.6)) if r.attack.animation == &"throw" else lerpf(80.0, 160.0, p)
						lean = -2.0 * p
						glint = r.attack.startup_frames - r.frame <= 10
					AttackRunner.Phase.ACTIVE:
						swing = -30.0 if r.attack.animation == &"throw" else 10.0
						lean = 3.0
					_:
						swing = lerpf(-30.0, 80.0, p)
						lean = 2.0 * (1.0 - p)
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -4.0
			crouch = 4.0 if s == EnemyBase.State.PARRIED else 1.0
			swing = 120.0
			glow = 0.2
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 20) / 60.0, 0.0, 1.0)
			crouch = minf(f * 1.0, 18.0)
			lean = -minf(f * 0.3, 6.0)
			glow = 0.0
	var hip := Vector2(lean * 0.3, -12.0 + crouch * 0.6)
	var shoulder := Vector2(2.0 + lean, -25.0 + crouch)
	var head := shoulder + Vector2(2.0, -4.0)
	# Legs
	draw_line(hip + Vector2(-1.5, 0), Vector2(-2 - legs, 0), _c(Palette.DUST, flash, alpha), 1.6)
	draw_line(hip + Vector2(1.5, 0), Vector2(2 + legs, 0), _c(Palette.BONE_DIM, flash, alpha), 1.6)
	# Pale robe with wax drips
	var robe := Color("b8ae98")
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4, 1), shoulder + Vector2(4, 0), hip + Vector2(5, 5), hip + Vector2(-6, 6)]), _c(robe, flash, alpha))
	for i in 3:
		draw_line(hip + Vector2(-4 + i * 3, 1), hip + Vector2(-4 + i * 3, 4 + i % 2 * 2), _c(Color("d8cfb8"), flash, alpha), 1.0)
	draw_line(shoulder + Vector2(-3, 4), hip + Vector2(3, -1), _c(Palette.CRIMSON, flash, alpha), 1.0)
	# Hooded head with a tall candle-crown
	draw_circle(head, 3.2, _c(Color("8c8370"), flash, alpha))
	draw_rect(Rect2(head + Vector2(0.5, -0.6), Vector2(2.5, 1.0)), _c(Palette.INK, flash, alpha))
	draw_rect(Rect2(head + Vector2(-1.5, -9), Vector2(3, 6)), _c(Palette.BONE, flash, alpha))
	if alpha > 0.5:
		var fl := sin(_t * 12.0) * 0.6
		draw_colored_polygon(PackedVector2Array([head + Vector2(-1, -9), head + Vector2(0 + fl, -13.5), head + Vector2(1.5, -9)]), Color(Palette.EMBER, alpha))
	# Arm + chain + censer
	var hand := shoulder + Vector2(3, 4)
	draw_line(shoulder, hand, _c(robe, flash, alpha), 1.8)
	var cen := hand + Vector2.from_angle(deg_to_rad(swing)) * 9.0
	draw_line(hand, cen, _c(Palette.STEEL_OXIDE, flash, alpha), 0.8)
	draw_circle(cen, 2.6, _c(Palette.WOOD, flash, alpha))
	draw_circle(cen, 1.4 + glow, Color(Palette.EMBER, alpha * (0.5 + glow * 0.5)))
	if glow > 0.6:
		draw_circle(cen, 5.0 + glow * 3.0, Color(Palette.EMBER, 0.15 * alpha))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(cen + Vector2(-4, 0), cen + Vector2(4, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(cen + Vector2(0, -4), cen + Vector2(0, 4), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(cen, 1.8 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -42.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
