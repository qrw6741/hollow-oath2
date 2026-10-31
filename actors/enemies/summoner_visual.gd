extends Node2D
## TEMPORARY ART — Candle Cantor: a tall, thin choir-master in wax-grey robes holding a staff
## topped with a guttering lantern. To summon it lifts the staff and the lantern flares white;
## its bolt is a cold blue flame (parryable).

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
	var lean := 0.0
	var crouch := 0.0
	var raise := 0.0           # staff lift 0..1
	var glow := 0.4
	var cold := false
	var glint := false
	var hover := sin(_t * 2.2) * 1.2
	match s:
		EnemyBase.State.PATROL, EnemyBase.State.RETURN, EnemyBase.State.CHASE:
			glow = 0.5
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				glow = 1.0
				cold = r.attack.animation == &"bolt"
				match r.phase:
					AttackRunner.Phase.STARTUP:
						raise = ease(p, 0.6)
						glint = r.attack.startup_frames - r.frame <= 10 and cold
					AttackRunner.Phase.ACTIVE:
						raise = 1.0
						lean = 3.0
					_:
						raise = 1.0 - p
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			lean = -4.0
			crouch = 3.0 if s == EnemyBase.State.PARRIED else 1.0
			glow = 0.15
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 20) / 60.0, 0.0, 1.0)
			crouch = minf(f * 1.0, 22.0)
			lean = -minf(f * 0.3, 6.0)
			glow = 0.0
	var robe := Color("9a9484")
	var hip := Vector2(lean * 0.3, -11.0 + crouch * 0.5 + hover * 0.4)
	var shoulder := Vector2(1.0 + lean, -28.0 + crouch + hover * 0.4)
	var head := shoulder + Vector2(2.0, -4.5)
	draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4, 1), shoulder + Vector2(4, 0), hip + Vector2(8, 11), hip + Vector2(-8, 11)]), _c(robe, flash, alpha))
	draw_line(shoulder + Vector2(0, 1), hip + Vector2(0, 11), _c(Palette.CRIMSON, flash, alpha), 1.0)
	for i in 4:
		draw_line(hip + Vector2(-6 + i * 4, 9), hip + Vector2(-6 + i * 4, 13 + (i % 2) * 2), _c(Color("d8cfb8"), flash, alpha), 1.0)
	draw_circle(head, 3.0, _c(Color("7c7666"), flash, alpha))
	draw_rect(Rect2(head + Vector2(0.4, -0.6), Vector2(2.4, 1.0)), _c(Palette.INK, flash, alpha))
	# Staff and lantern
	var hand := shoulder + Vector2(6.0, 4.0 - raise * 8.0)
	draw_line(shoulder, hand, _c(robe, flash, alpha), 1.8)
	var base := hand + Vector2(0, 14)
	var tip := hand + Vector2(0, -12)
	draw_line(base, tip, _c(Palette.WOOD_LIGHT, flash, alpha), 1.4)
	var lc := Color("9fd0ff") if cold else Palette.EMBER
	draw_circle(tip + Vector2(0, -2), 3.0, _c(Palette.STEEL_OXIDE, flash, alpha))
	draw_circle(tip + Vector2(0, -2), 1.5 + glow, Color(lc, alpha * (0.5 + glow * 0.5)))
	if glow > 0.6:
		draw_circle(tip + Vector2(0, -2), 6.0 + glow * 4.0, Color(lc, 0.16 * alpha))
	if glint:
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		var c := tip + Vector2(0, -2)
		draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
		draw_line(c + Vector2(0, -5), c + Vector2(0, 5), Color(Palette.GOLD_BRIGHT, alpha), 1.0)
		draw_circle(c, 1.8 + k, Color(1, 0.95, 0.85, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -46.0 + sin(_t * 6.0) * 1.5
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
