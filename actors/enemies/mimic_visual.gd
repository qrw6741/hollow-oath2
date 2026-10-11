extends Node2D
## TEMPORARY ART — Mimic. Dormant: drawn exactly like a TreasureChest, except that every
## few seconds the lid lifts a hair and a puff of ash escapes (the tell). Awake: the lid
## gapes into a fanged maw with a tongue, and spindly legs carry it in hops.
## Bite telegraph glints (parryable); the pounce and the ambush glow red (dodge them).

const BREATH_EVERY := 4.5

var enemy: Mimic
var _t := 0.0


func _ready() -> void:
	enemy = get_parent() as Mimic
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
		var b := fmod(enemy.breath_t, BREATH_EVERY)
		var lift := 0.0
		if b < 0.7:
			lift = sin(b / 0.7 * PI) * 1.5
			for i in 3:
				var k := b / 0.7
				draw_circle(Vector2(8 + i * 2 + k * 6, -19 - k * 6 - i), 1.0 + k, Color(Palette.DUST, 0.45 * (1.0 - k)))
		TreasureChest.draw_chest(self, 0.0, flash, 1.0, lift)
		return
	var s := enemy.state
	var f := enemy.state_frame
	var alpha := 1.0
	var gape := 0.25 + 0.1 * sin(_t * 6.0)
	var hop := absf(sin(_t * 9.0)) * 4.0 if s in [EnemyBase.State.CHASE, EnemyBase.State.RETURN] else 0.0
	var glint := false
	var danger := 0.0
	match s:
		EnemyBase.State.ATTACK:
			var r := enemy.attack_runner
			if r.attack:
				var p := r.phase_progress()
				match r.phase:
					AttackRunner.Phase.STARTUP:
						gape = 0.3 + 0.7 * p
						if r.attack.parryable:
							glint = r.attack.startup_frames - r.frame <= 10
						else:
							danger = 0.4 + 0.6 * p
						if r.attack.animation == &"pounce":
							hop = -2.0 * p
					AttackRunner.Phase.ACTIVE:
						gape = 0.05
						hop = 8.0 if r.attack.animation == &"pounce" else 0.0
					_:
						gape = 0.15
		EnemyBase.State.STAGGER, EnemyBase.State.PARRIED:
			gape = 0.9
		EnemyBase.State.DEAD:
			alpha = clampf(1.0 - (f - 30) / 60.0, 0.0, 1.0)
			gape = 1.0
	if danger > 0.0:
		var k := danger * (0.7 + 0.3 * sin(_t * 30.0))
		draw_circle(Vector2(0, -14), 20.0, Color(Palette.CRIMSON_BRIGHT, 0.14 * k * alpha))
	# Spindly legs
	var leg := Color(Color("2b2622"), alpha)
	for i in 4:
		var x := -8.0 + i * 5.3
		var kx := x + sin(_t * 9.0 + i) * 2.0
		draw_polyline(PackedVector2Array([Vector2(x, -hop - 2), Vector2(kx + 2, -hop + 2), Vector2(x + 1, 0)]), leg, 1.2)
	draw_set_transform(Vector2(0, -hop - 2), 0.0, Vector2.ONE)
	_maw(gape, flash, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glint:
		var g := Vector2(11, -18 - hop)
		var k := 0.5 + 0.5 * sin(_t * 40.0)
		draw_line(g + Vector2(-5, 0), g + Vector2(5, 0), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_line(g + Vector2(0, -5), g + Vector2(0, 5), Color(Palette.CRIMSON_BRIGHT, alpha), 1.0)
		draw_circle(g, 2.0 + k, Color(1, 0.85, 0.8, 0.7 * alpha))
	if enemy.is_riposte_ready():
		var y := -40.0 + sin(_t * 6.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 4), Vector2(3, y), Vector2(0, y + 4), Vector2(-3, y)]), Palette.GOLD_BRIGHT)


## Chest body with the lid hinged at the back, opened [param g] (0..1) into a maw.
func _maw(g: float, flash: float, alpha: float) -> void:
	TreasureChest.draw_chest(self, 1.0, flash, alpha)   # body (and an open-lid backdrop)
	# Cover the plain open lid with a fanged one rotated around the back hinge.
	var hinge := Vector2(-11, -12)
	var ang := -g * 1.1
	var lid := PackedVector2Array()
	for p in [Vector2(0, 0), Vector2(1, -5), Vector2(5, -7), Vector2(17, -7), Vector2(21, -5), Vector2(22, 0)]:
		lid.append(hinge + p.rotated(ang))
	var inner := Color(0.25, 0.04, 0.06, alpha)
	draw_colored_polygon(PackedVector2Array([hinge, hinge + Vector2(22, 0).rotated(ang), Vector2(11, -12), Vector2(-9, -12)]), inner)
	draw_colored_polygon(lid, Color(Palette.WOOD_LIGHT.lerp(Color.WHITE, flash), alpha))
	# Teeth on the lid edge and the chest rim
	for i in 5:
		var a := hinge + Vector2(3 + i * 4, 0).rotated(ang)
		draw_colored_polygon(PackedVector2Array([a, a + Vector2(2, 0).rotated(ang), a + Vector2(1, 3).rotated(ang)]), Color(Palette.BONE, alpha))
		var b := Vector2(-8 + i * 4, -12)
		draw_colored_polygon(PackedVector2Array([b, b + Vector2(2, 0), b + Vector2(1, -3)]), Color(Palette.BONE, alpha))
	# Tongue + eye
	draw_line(Vector2(-4, -13), Vector2(8 + g * 6, -15 - g * 3), Color(Palette.CRIMSON_BRIGHT, alpha), 2.0)
	draw_circle(hinge + Vector2(16, -3).rotated(ang), 1.3, Color(Palette.EMBER, alpha))
