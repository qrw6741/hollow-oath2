extends Node2D
## TEMPORARY ART — Reliquary Lurker. Hidden: a slow ripple on the water line and two dim, wet
## eyes. Awake: a pale, long-armed drowned thing hunched forward; the snap glints (parryable),
## the lunge glows red (dodge it).

var enemy: Lurker
var _t := 0.0


func _ready() -> void:
	enemy = get_parent() as Lurker
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if enemy:
		scale.x = enemy.facing
	queue_redraw()


func _draw() -> void:
	if enemy == null:
		return
	var flash := 1.0 if enemy.hit_flash > 3 and Settings.flashes else 0.0
	if enemy.dormant:
		var k := 0.5 + 0.5 * sin(enemy.surface_t * 1.6)
		for i in 3:
			var w := 6.0 + i * 4.0 + k * 3.0
			draw_arc(Vector2(0, -1), w, PI + 0.4, TAU - 0.4, 10, Color(0.7, 0.85, 0.9, 0.18 - i * 0.04), 0.8)
		var blink := 1.0 if fmod(enemy.surface_t, 4.2) > 0.25 else 0.0
		draw_circle(Vector2(-2.5, -2.5), 0.9, Color(0.85, 0.95, 1.0, 0.4 * k * blink))
		draw_circle(Vector2(2.5, -2.5), 0.9, Color(0.85, 0.95, 1.0, 0.4 * k * blink))
		return
	var skin := Color("a9b8bd").lerp(Color.WHITE, flash)
	var dark := Color("5c6a70").lerp(Color.WHITE, flash)
	var glint := false
	var danger := 0.0
	var reach := 0.0
	var hunch := 0.0
	var bob := absf(sin(_t * 8.0)) * 1.5 if enemy.state == EnemyBase.State.CHASE else 0.0
	if enemy.state == EnemyBase.State.ATTACK and enemy.attack_runner.attack:
		var r := enemy.attack_runner
		var p := r.phase_progress()
		match r.phase:
			AttackRunner.Phase.STARTUP:
				hunch = 4.0 * p
				if r.attack.parryable:
					glint = r.attack.startup_frames - r.frame <= 8
				else:
					danger = 0.3 + 0.7 * p
			AttackRunner.Phase.ACTIVE:
				reach = 14.0
				hunch = -2.0
			_:
				reach = 14.0 * (1.0 - p)
	var y := -bob
	draw_line(Vector2(-3, y - 10), Vector2(-4, y), dark, 2.4)
	draw_line(Vector2(3, y - 10), Vector2(4, y), dark, 2.4)
	var sh := Vector2(1 + hunch, y - 22)
	draw_line(Vector2(0, y - 10), sh, skin, 5.0)
	draw_circle(sh + Vector2(3, -3), 4.0, skin)
	draw_circle(sh + Vector2(4.5, -3.5), 1.0, Color(0.1, 0.12, 0.14))
	draw_line(sh, sh + Vector2(9 + reach, 9 - reach * 0.4), dark, 2.0)
	draw_line(sh + Vector2(9 + reach, 9 - reach * 0.4), sh + Vector2(12 + reach, 10 - reach * 0.4), skin, 1.2)
	if glint:
		draw_circle(sh + Vector2(4.5, -3.5), 3.0, Color(Palette.GOLD_BRIGHT, 0.8))
	if danger > 0.0:
		draw_circle(sh + Vector2(4.5, -3.5), 3.0, Color(1.0, 0.15, 0.1, 0.6 * danger))
