extends Node2D
## TEMPORARY ART — Gloam Moth: a soot-grey moth the size of a dog, with ember eyes and
## ash-dusted wings. Wind-up: it rears back, wings spread wide, and the eyes glint
## (parryable dive). Dazed after a dive: slow, drooping wingbeats.

const WING := Color("4a4448")
const WING_EDGE := Color("8d867e")
const BODY := Color("2b2628")

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
	var beat_speed := 22.0
	var spread := 1.0
	var tilt := 0.0
	var glint := false
	var eye := 0.7
	match s:
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			match r.phase:
				AttackRunner.Phase.STARTUP:
					spread = 1.3
					beat_speed = 10.0
					tilt = -0.3
					eye = 1.0
					glint = r.attack and r.attack.startup_frames - r.frame <= 10
				AttackRunner.Phase.ACTIVE:
					spread = 0.35
					beat_speed = 0.0
					tilt = 0.5
					eye = 1.0
				_:
					beat_speed = 8.0
					spread = 0.8
		EnemyBase.State.RECOVER:
			beat_speed = 7.0
			spread = 0.7
			eye = 0.3
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			beat_speed = 3.0
			spread = 0.5
			tilt = 0.9
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			beat_speed = 0.0
			spread = 0.3
			tilt = 1.4
			eye = 0.0
	var c := Vector2(0, -8)
	var beat := sin(_t * beat_speed) if beat_speed > 0.0 else 0.0
	draw_set_transform(c, tilt, Vector2.ONE)
	# Far wing, then body, then near wing.
	for side in [-1.0, 1.0]:
		var lift: float = beat * 0.9 * side
		var span: float = 13.0 * spread
		var tip: Vector2 = Vector2(-2.0, -span * (0.6 + 0.4 * lift * side)).rotated(side * 0.35)
		var tip2: Vector2 = Vector2(-9.0 * spread, -span * 0.4 * (1.0 + lift * side))
		var col: Color = WING if side > 0 else WING.darkened(0.25)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -1), tip, tip2, Vector2(-4, 1)]), _c(col, flash, alpha))
		draw_line(Vector2(1, -1), tip, _c(WING_EDGE, flash, alpha * 0.8), 1.0)
		# Lower wing
		draw_colored_polygon(PackedVector2Array([Vector2(-1, 1), Vector2(-8, 5 + beat * 2.0), Vector2(-4, 7)]), _c(col.darkened(0.1), flash, alpha))
	# Body: fat abdomen + thorax + head
	draw_colored_polygon(PackedVector2Array([Vector2(-11, 1), Vector2(-4, -3), Vector2(3, -2), Vector2(3, 3), Vector2(-4, 4)]), _c(BODY, flash, alpha))
	for i in 3:
		draw_line(Vector2(-8 + i * 3, -2), Vector2(-8 + i * 3, 3), _c(WING_EDGE, flash, alpha * 0.4), 1.0)
	draw_circle(Vector2(5, 0), 3.2, _c(BODY.lightened(0.1), flash, alpha))
	# Feathered antennae
	draw_line(Vector2(6, -2), Vector2(10, -7), _c(WING_EDGE, flash, alpha), 1.0)
	draw_line(Vector2(5, -2), Vector2(7, -8), _c(WING_EDGE, flash, alpha), 1.0)
	if eye > 0.0:
		draw_circle(Vector2(6.5, -0.5), 0.8 + eye * 0.7, Color(Palette.EMBER, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Falling ash
	if alpha > 0.0 and s != EnemyBase.State.DEAD:
		for i in 3:
			var k := fmod(_t * 0.8 + i * 0.33, 1.0)
			draw_circle(c + Vector2(-3 + i * 3, 4 + k * 16), 0.6, Color(Palette.DUST, (1.0 - k) * 0.6 * alpha))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		var g := c + Vector2(6.5, -0.5)
		draw_line(g + Vector2(-5, 0), g + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(g + Vector2(0, -5), g + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(g, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -30.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
