extends Node2D
## TEMPORARY ART — procedural placeholder for the Oathbound (player).
## Draws a readable, animated silhouette from the player's state so combat timing
## is legible before the final Aseprite sprite sheet lands (Milestone 4).
## The final sprite will replace this node with an AnimatedSprite2D driven by the
## same state/phase data; nothing in gameplay code depends on this script.


## Weapon angle keys per attack animation: [windup, strike_end] in degrees
## (0 = forward, -90 = up, +90 = down).
const SWINGS := {
	&"slash": [-125.0, 55.0],
	&"slash_rev": [70.0, -95.0],
	&"heavy": [-170.0, 70.0],
	&"air": [-110.0, 120.0],
	&"riposte": [-20.0, -5.0],
}

var player: Player
var _t := 0.0


func _ready() -> void:
	player = get_parent() as Player


func _physics_process(delta: float) -> void:
	_t += delta
	if player:
		scale.x = player.facing
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var s := player.state
	var f := player.state_frame
	var flash := 0.0
	if s == Player.State.HURT and f < 6 and Settings.flashes:
		flash = 1.0
	var alpha := 1.0
	if player.is_dodge_invulnerable():
		alpha = 0.55
	elif player._iframes > 0 and s != Player.State.DEAD and s != Player.State.ATTACK and (f / 3) % 2 == 0:
		alpha = 0.7

	var lean := 0.0
	var crouch := 0.0
	var legs := 0.0
	var sword := 62.0
	var trail := Vector2.ZERO  # (from, to) angles of the swing trail, 0 = none
	var arm_up := false
	var on_floor := player.is_on_floor()

	match s:
		Player.State.FREE:
			if not on_floor:
				crouch = -1.0
				sword = 35.0
				legs = 2.5
			elif absf(player.velocity.x) > 10.0:
				lean = 2.0
				legs = sin(_t * 14.0) * 3.5
				crouch = absf(sin(_t * 14.0)) * 0.8
			else:
				crouch = (sin(_t * 2.6) + 1.0) * 0.35
		Player.State.ATTACK:
			var r := player.attack_runner
			if r.attack:
				var key: StringName = r.attack.animation
				var sw: Array = SWINGS.get(key, SWINGS[&"slash"])
				var p := r.phase_progress()
				match r.phase:
					AttackRunner.Phase.STARTUP:
						sword = lerpf(62.0, sw[0], ease(p, 0.4))
						lean = -1.5
						crouch = 1.0
					AttackRunner.Phase.ACTIVE:
						sword = lerpf(sw[0], sw[1], ease(p, 0.35))
						trail = Vector2(sw[0], sword)
						lean = 3.0
						crouch = 1.5
					_:
						sword = lerpf(sw[1], 62.0, p * p)
						lean = 2.0 * (1.0 - p)
						crouch = 1.5 * (1.0 - p)
				if key == &"riposte":
					lean = 4.0
		Player.State.DODGE:
			_draw_roll(f, alpha)
			return
		Player.State.PARRY:
			sword = -80.0
			lean = -1.0
			crouch = 1.0
		Player.State.HEAL:
			arm_up = f < player.heal_apply_frame + 6
			sword = 80.0
			crouch = 0.5
		Player.State.HURT:
			lean = -3.0
			sword = 100.0
		Player.State.REST:
			crouch = 7.0
			sword = 95.0
		Player.State.DEAD:
			_draw_dead(f)
			return

	_draw_body(lean, crouch, legs, sword, trail, arm_up, flash, alpha)

	if player.parry_flash > 0:
		var k := player.parry_flash / 18.0
		draw_arc(Vector2(10, -16), 10.0 + (1.0 - k) * 10.0, 0, TAU, 20, Color(Palette.GOLD_BRIGHT, k), 1.5)
	elif player.is_parry_active():
		draw_arc(Vector2(9, -16), 9.0, -1.4, 1.4, 10, Color(Palette.GOLD, 0.8), 1.0)
	if player.heal_flash > 0:
		var hk := player.heal_flash / 20.0
		draw_circle(Vector2(0, -14), 10.0 + (1.0 - hk) * 8.0, Color(Palette.GOLD_BRIGHT, hk * 0.35))


func _c(col: Color, flash: float, alpha: float) -> Color:
	var out := col.lerp(Color.WHITE, flash)
	out.a = alpha
	return out


func _draw_body(lean: float, crouch: float, legs: float, sword_deg: float, trail: Vector2, arm_up: bool, flash: float, alpha: float) -> void:
	var hip := Vector2(lean * 0.4, -11.0 + crouch)
	var shoulder := Vector2(lean, -22.0 + crouch * 1.2)
	var head := shoulder + Vector2(1.0 + lean * 0.3, -4.5)

	# Legs (greaves).
	var lc := _c(Palette.STONE_DARK, flash, alpha)
	draw_line(hip + Vector2(-2, 0), Vector2(-2.5 - legs, 0), lc, 3.0)
	draw_line(hip + Vector2(2, 0), Vector2(2.5 + legs, 0), _c(Palette.CLOAK_LIGHT, flash, alpha), 3.0)

	# Cloak: tattered trapezoid trailing behind.
	var sway := sin(_t * 3.0) * 0.8 - lean * 0.6
	var cloak := PackedVector2Array([
		shoulder + Vector2(-4, 0), shoulder + Vector2(4, 0),
		hip + Vector2(5, 2), hip + Vector2(1, 5), hip + Vector2(-3, 4 + sway), hip + Vector2(-8 + sway, 3),
	])
	draw_colored_polygon(cloak, _c(Palette.CLOAK, flash, alpha))
	draw_line(shoulder + Vector2(-4, 0), hip + Vector2(-8 + sway, 3), _c(Palette.CLOAK_LIGHT, flash, alpha), 1.0)
	# Crimson oath-sash.
	draw_line(shoulder + Vector2(-3, 3), hip + Vector2(4, -1), _c(Palette.CRIMSON, flash, alpha), 1.5)
	# Scarf tail.
	draw_colored_polygon(PackedVector2Array([
		shoulder + Vector2(-2, -1), shoulder + Vector2(-9 - lean, 1 + sway), shoulder + Vector2(-2, 2),
	]), _c(Palette.CRIMSON, flash, alpha))

	# Bone mask head with dark visor slit.
	draw_circle(head, 4.0, _c(Palette.BONE, flash, alpha))
	draw_rect(Rect2(head + Vector2(0.5, -1.0), Vector2(3.5, 1.2)), _c(Palette.INK, flash, alpha))
	# Hood edge.
	draw_arc(head, 4.6, PI * 0.6, PI * 1.6, 8, _c(Palette.CLOAK, flash, alpha), 1.6)

	# Arm + sword.
	var hand := shoulder + Vector2(3, 3)
	if arm_up:
		var vial := shoulder + Vector2(4, -6)
		draw_line(shoulder + Vector2(2, 1), vial, _c(Palette.CLOAK_LIGHT, flash, alpha), 2.0)
		draw_circle(vial, 2.2, _c(Palette.GOLD_BRIGHT, flash, alpha))
		draw_circle(vial, 5.0, Color(Palette.GOLD, 0.25 * alpha))
	if trail != Vector2.ZERO:
		_draw_trail(hand, trail.x, trail.y, alpha)
	var dir := Vector2.from_angle(deg_to_rad(sword_deg))
	draw_line(shoulder + Vector2(2, 1), hand, _c(Palette.CLOAK_LIGHT, flash, alpha), 2.0)
	draw_line(hand - dir * 2.0, hand + dir * 17.0, _c(Palette.STEEL, flash, alpha), 1.6)
	draw_line(hand + dir * 2.0, hand + dir * 15.0, _c(Palette.BONE, flash, alpha * 0.6), 0.6)
	# Crossguard.
	var ortho := dir.orthogonal()
	draw_line(hand + dir * 1.5 - ortho * 2.5, hand + dir * 1.5 + ortho * 2.5, _c(Palette.GOLD, flash, alpha), 1.2)


func _draw_trail(hand: Vector2, from_deg: float, to_deg: float, alpha: float) -> void:
	var a0 := deg_to_rad(from_deg)
	var a1 := deg_to_rad(to_deg)
	var pts := PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		pts.append(hand + Vector2.from_angle(lerpf(a0, a1, float(i) / steps)) * 19.0)
	for i in range(steps, -1, -1):
		pts.append(hand + Vector2.from_angle(lerpf(a0, a1, float(i) / steps)) * 8.0)
	draw_colored_polygon(pts, Color(Palette.BONE, 0.35 * alpha))


func _draw_roll(f: int, alpha: float) -> void:
	var t := clampf(float(f) / player.dodge_frames, 0.0, 1.0)
	var ang := t * TAU * 1.0
	var c := Vector2(0, -8)
	draw_circle(c, 8.0, Color(Palette.CLOAK, alpha))
	draw_arc(c, 8.0, ang, ang + PI, 10, Color(Palette.CLOAK_LIGHT, alpha), 1.5)
	draw_circle(c + Vector2.from_angle(ang) * 4.0, 2.5, Color(Palette.BONE, alpha))
	draw_line(c + Vector2.from_angle(ang + 2.0) * 5.0, c + Vector2.from_angle(ang + 2.6) * 11.0, Color(Palette.CRIMSON, alpha), 1.5)
	# Dust.
	if player.is_on_floor():
		for i in 3:
			draw_circle(Vector2(-8 - i * 4, -1 - i), 1.5 - i * 0.4, Color(Palette.DUST, 0.5 * (1.0 - t)))


func _draw_dead(f: int) -> void:
	var k := clampf(f / 20.0, 0.0, 1.0)
	var a := 1.0 - clampf((f - 60) / 60.0, 0.0, 0.7)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(10, 0), Vector2(8, -5 * (1.0 - k) - 4), Vector2(-10, -4),
	]), Color(Palette.CLOAK, a))
	draw_circle(Vector2(12, -2 - 6 * (1.0 - k)), 3.5, Color(Palette.BONE, a))
	draw_line(Vector2(-4, -1), Vector2(-20, 1), Color(Palette.STEEL, a), 1.5)
	draw_line(Vector2(-6, -3), Vector2(6, -2), Color(Palette.CRIMSON, a), 1.5)
