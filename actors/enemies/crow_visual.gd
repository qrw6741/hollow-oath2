extends Node2D
## TEMPORARY ART — Carrion Crow: a black road-crow with ragged wings and a red eye.
## Dive wind-up: wings flared, eye glints (parryable). Dazed after a dive: slow, drooping wings.

const FEATHER := Color("1c191d")
const FEATHER_L := Color("3a343c")

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
	var speed := 16.0
	var spread := 1.0
	var tilt := 0.0
	var glint := false
	var eye := 0.7
	match s:
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			match r.phase:
				AttackRunner.Phase.STARTUP:
					speed = 9.0
					spread = 1.3
					tilt = -0.35
					eye = 1.0
					glint = r.attack and r.attack.startup_frames - r.frame <= 10
				AttackRunner.Phase.ACTIVE:
					speed = 0.0
					spread = 0.3
					tilt = 0.7
					eye = 1.0
				_:
					speed = 8.0
					spread = 0.8
		EnemyBase.State.RECOVER:
			speed = 6.0
			spread = 0.7
			eye = 0.3
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			speed = 3.0
			spread = 0.5
			tilt = 1.0
			eye = 0.1
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			speed = 0.0
			spread = 0.25
			tilt = 1.5
			eye = 0.0
	var c := Vector2(0, -6)
	var beat := sin(_t * speed) if speed > 0.0 else 0.0
	draw_set_transform(c, tilt, Vector2.ONE)
	for side in [-1.0, 1.0]:
		var lift: float = beat * 0.9 * side
		var span: float = 11.0 * spread
		var tip := Vector2(-1.0, -span * (0.6 + 0.4 * lift * side)).rotated(side * 0.3)
		var col: Color = FEATHER if side > 0 else FEATHER.lightened(0.05)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -1), tip, tip + Vector2(-5, 2.0), Vector2(-4, 1.5)]), _c(col, flash, alpha))
		for k in 3:
			var q := tip.lerp(Vector2(-4, 1.5), 0.25 + k * 0.25)
			draw_line(q, q + Vector2(-2.2, 1.6), _c(FEATHER_L, flash, alpha), 0.7)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 1), Vector2(-3, -2.5), Vector2(3, -2), Vector2(3, 2.5), Vector2(-3, 3)]), _c(FEATHER, flash, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 1), Vector2(-11, -1), Vector2(-10, 3.5)]), _c(FEATHER, flash, alpha))   # tail
	draw_circle(Vector2(4, -1.5), 2.4, _c(FEATHER, flash, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -2.4), Vector2(10, -1.2), Vector2(6, -0.2)]), _c(Color("6b5a3a"), flash, alpha))
	if eye > 0.0:
		draw_circle(Vector2(4.8, -2.2), 0.6 + eye * 0.5, Color(Palette.CRIMSON_BRIGHT, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		var g := c + Vector2(4.8, -2.2)
		draw_line(g + Vector2(-5, 0), g + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(g + Vector2(0, -5), g + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(g, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -26.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)
