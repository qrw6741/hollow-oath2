extends Node2D
## TEMPORARY ART — Hollow Archer: a gaunt road-watch bowman in a rotted green hood. The bow
## draws back and the arrow tip glints for the whole wind-up of a shot (parryable).

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
	if _ink:
		return Color(Palette.INK, alpha * 0.9)
	var o := col.lerp(Color.WHITE, flash)
	o.a = alpha
	return o


func _draw_body() -> void:
	if enemy == null:
		return
	var s := enemy.state
	var f := enemy.state_frame
	var flash := 1.0 if enemy.hit_flash > 3 and Settings.flashes else 0.0
	var alpha := 1.0
	var legs := 0.0
	var crouch := 0.0
	var lean := 0.0
	var draw_back := 0.0       # 0 relaxed .. 1 fully drawn
	var glint := false
	var stab := 0.0
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN:
			legs = sin(_t * 7.0) * 2.0
		EnemyBase.State.CHASE:
			legs = sin(_t * 10.0) * 3.0
			lean = 1.0
			draw_back = 0.15
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.6) + 1.0) * 0.4
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				if r.attack.animation == &"stab":
					stab = p if r.phase != AttackRunner.Phase.RECOVERY else 1.0 - p
					lean = 3.0 * stab
				else:
					match r.phase:
						AttackRunner.Phase.STARTUP:
							draw_back = ease(p, 0.5)
							glint = r.attack.startup_frames - r.frame <= 10
						AttackRunner.Phase.ACTIVE:
							draw_back = 0.0
						_:
							draw_back = 0.0
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -4.0
			crouch = 4.0 if s == EnemyBase.State.PARRIED else 1.0
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 20) / 60.0, 0.0, 1.0)
			crouch = minf(f * 1.0, 18.0)
			lean = -minf(f * 0.3, 6.0)
	var cloth := Color("46513a")
	var hip := Vector2(lean * 0.3, -12.0 + crouch * 0.6)
	var shoulder := Vector2(1.0 + lean, -25.0 + crouch)
	var head := shoulder + Vector2(2.0, -4.0)
	draw_line(hip + Vector2(-1.5, 0), Vector2(-2 - legs, 0), _c(Palette.WOOD, flash, alpha), 1.6)
	draw_line(hip + Vector2(1.5, 0), Vector2(2 + legs, 0), _c(Palette.WOOD_LIGHT, flash, alpha), 1.6)
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-3, 1), shoulder + Vector2(3, 0), hip + Vector2(4, 4), hip + Vector2(-4, 5)]), _c(cloth, flash, alpha))
	# Quiver
	draw_line(shoulder + Vector2(-3, 0), hip + Vector2(-5, 2), _c(Palette.WOOD, flash, alpha), 2.0)
	for i in 3:
		draw_line(shoulder + Vector2(-3 + i, 0), shoulder + Vector2(-4 + i * 1.2, -4), _c(Palette.BONE_DIM, flash, alpha), 0.7)
	# Hood
	draw_circle(head, 3.4, _c(Color("34402c"), flash, alpha))
	draw_rect(Rect2(head + Vector2(0.4, -0.6), Vector2(2.6, 1.0)), _c(Palette.INK, flash, alpha))
	draw_colored_polygon(PackedVector2Array([head + Vector2(-3.4, -1), head + Vector2(-0.5, -5.6), head + Vector2(2.4, -2.0)]), _c(Color("34402c"), flash, alpha))
	# Bow arm and bow
	var grip := shoulder + Vector2(9.0 - stab * 3.0, 3.0)
	draw_line(shoulder, grip, _c(cloth, flash, alpha), 1.8)
	if stab > 0.0:
		var k := grip + Vector2(8.0 * stab, -2.0 * stab)
		draw_line(grip, k, _c(Palette.STEEL, flash, alpha), 1.4)
	else:
		var top := grip + Vector2(-1, -11)
		var bot := grip + Vector2(-1, 11)
		var pull := grip + Vector2(-2.0 - draw_back * 9.0, 0)
		draw_line(top, grip + Vector2(3.0, 0), _c(Palette.WOOD_LIGHT, flash, alpha), 1.4)
		draw_line(bot, grip + Vector2(3.0, 0), _c(Palette.WOOD_LIGHT, flash, alpha), 1.4)
		draw_line(top, pull, _c(Palette.BONE_DIM, flash, alpha), 0.6)
		draw_line(bot, pull, _c(Palette.BONE_DIM, flash, alpha), 0.6)
		if draw_back > 0.1 or glint:
			draw_line(pull, grip + Vector2(8, 0), _c(Palette.BONE, flash, alpha), 0.9)
			draw_colored_polygon(PackedVector2Array([grip + Vector2(8, -1.4), grip + Vector2(11, 0), grip + Vector2(8, 1.4)]), _c(Palette.STEEL, flash, alpha))
		if glint:
			var k2 := 0.5 + 0.5 * sin(_t * 40.0)
			var tip := grip + Vector2(11, 0)
			draw_line(tip + Vector2(-4, 0), tip + Vector2(4, 0), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
			draw_line(tip + Vector2(0, -4), tip + Vector2(0, 4), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
			draw_circle(tip, 1.6 + k2, Color(1, 0.95, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -42.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)


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
