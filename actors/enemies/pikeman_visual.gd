extends Node2D
## TEMPORARY ART — Roadside Pikeman: a conscript in a kettle helm and a faded road-watch
## tabard, gripping a long pike. The thrust glints (parryable); the low sweep glows red
## (unparryable: jump it).

const MAIL := Color("5d6166")
const TABARD := Color("6b5a3a")

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
	var ext := 0.0
	var ang := -0.12
	var glint := false
	var danger := 0.0
	var eye := 0.5
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			legs = sin(_t * 6.0) * 2.5
			eye = 0.8 if s == EnemyBase.State.CHASE else 0.5
		EnemyBase.State.IDLE:
			crouch = (sin(_t * 1.5) + 1.0) * 0.4
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			eye = 1.0
			if r.attack:
				var p := r.phase_progress()
				var low: bool = r.attack.animation == &"sweep"
				match r.phase:
					AttackRunner.Phase.STARTUP:
						crouch = 2.0 * p
						ext = -10.0 * p
						ang = 0.55 * p if low else -0.12 * (1.0 - p)
						if low:
							danger = 0.4 + 0.6 * p
						else:
							glint = r.attack.startup_frames - r.frame <= 10
					AttackRunner.Phase.ACTIVE:
						ext = 24.0
						ang = 0.55 if low else 0.0
						crouch = 2.0
					_:
						ext = 24.0 * (1.0 - p)
						ang = 0.4 * (1.0 - p) if low else 0.0
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			crouch = 4.0
			ang = -0.9
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			crouch = minf(f * 0.8, 20.0)
			ang = -1.0
			eye = 0.0
	var hip := Vector2(0, -15.0 + crouch * 0.6)
	var shoulder := Vector2(0, -28.0 + crouch)
	var head := shoulder + Vector2(1, -5)
	if danger > 0.0:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(20, -6), 14.0, Color(Palette.CRIMSON_BRIGHT, 0.14 * k * alpha))
	draw_line(hip + Vector2(-2.5, 0), Vector2(-3.5 - legs, 0), _c(Palette.STONE, flash, alpha), 3.0)
	draw_line(hip + Vector2(2.5, 0), Vector2(3.5 + legs, 0), _c(Palette.STONE_LIGHT, flash, alpha), 3.0)
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-5, 0), shoulder + Vector2(5, 0), hip + Vector2(5, 4), hip + Vector2(-5, 4)]), _c(MAIL, flash, alpha))
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4, 3), shoulder + Vector2(4, 3), hip + Vector2(4, 6), hip + Vector2(-4, 6)]), _c(TABARD, flash, alpha))
	# Kettle helm
	draw_circle(head, 3.4, _c(Color("c9a98a"), flash, alpha))
	draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -0.5), head + Vector2(-3.5, -5.5), head + Vector2(3.5, -5.5), head + Vector2(6, -0.5)]), _c(MAIL.darkened(0.1), flash, alpha))
	if eye > 0.0:
		draw_circle(head + Vector2(1.8, 0.4), 0.6 + eye * 0.3, Color(Palette.EMBER, alpha))
	# Pike
	var hand := shoulder + Vector2(4 + ext * 0.5, 7)
	var dir := Vector2.from_angle(ang)
	var butt := hand - dir * 14.0
	var tip := hand + dir * (30.0 + ext * 0.4)
	draw_line(butt, tip, _c(Palette.WOOD_LIGHT, flash, alpha), 1.6)
	draw_colored_polygon(PackedVector2Array([tip + dir * 7.0, tip + dir.orthogonal() * 2.2, tip - dir.orthogonal() * 2.2]), _c(Palette.STEEL, flash, alpha))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		var g := tip + dir * 4.0
		draw_line(g + Vector2(-5, 0), g + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(g + Vector2(0, -5), g + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(g, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -48.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)


## 1 px ink outline: the body drawn four times in ink, shifted, then once in colour on top.
var _ink := false


func _draw() -> void:
	_ink = true
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_set_transform(o, 0.0, Vector2.ONE)
		_draw_body()
	_ink = false
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body()
