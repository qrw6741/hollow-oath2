extends Node2D
## TEMPORARY ART — procedural placeholder for the player, driven by the chosen preset.
## Draws a readable, animated silhouette from the player's state so combat timing
## is legible before the final Aseprite sprite sheets land (Milestone 4).
## Four looks (armour) x four weapon styles: sword, twin blades, sword & shield, fists.
## The final sprites will replace this node; nothing in gameplay code depends on it.
##
## With [member preview] = true (main-menu preset cards) it draws an idle pose from
## [member preset] without needing a Player.

## Sword angle keys per attack animation: [windup, strike_end] in degrees
## (0 = forward, -90 = up, +90 = down).
const SWINGS := {
	&"slash": [-125.0, 55.0],
	&"slash_rev": [70.0, -95.0],
	&"heavy": [-170.0, 70.0],
	&"air": [-110.0, 120.0],
	&"riposte": [-20.0, -5.0],
	&"smash": [-150.0, 70.0],
	&"sweep": [-125.0, 55.0],
	&"thrust": [62.0, 0.0],
}
## Weapon looks that use the one-weapon swing poses (sword, shield, and the later additions).
const SINGLE_LOOKS := [0, 2, 4, 5, 6, 7, 8, 9, 10]
## Looks whose thrust / riposte pushes the weapon forward instead of swinging it.
const THRUSTERS := [5, 7, 10]
## Twin blades: [windup, strike_end] for blade A (front) and B (rear).
const TWIN := {
	&"twin_a": {"a": [-100.0, 45.0]},
	&"twin_b": {"b": [50.0, -80.0]},
	&"twin_x": {"a": [-120.0, 40.0], "b": [110.0, -30.0]},
	&"air": {"a": [-60.0, 110.0], "b": [-40.0, 120.0]},
	&"riposte": {"a": [-12.0, -3.0], "b": [12.0, 4.0]},
}
## Fists: which hand throws it, and hand position (relative to the shoulder) at wind-up and strike.
const FISTS := {
	&"jab": {"hand": "f", "wind": Vector2(3, 0), "strike": Vector2(17, -1)},
	&"cross": {"hand": "r", "wind": Vector2(-1, 3), "strike": Vector2(18, 0)},
	&"hook": {"hand": "f", "wind": Vector2(-6, -5), "strike": Vector2(13, 3), "bulge": -3.0},
	&"uppercut": {"hand": "r", "wind": Vector2(4, 10), "strike": Vector2(9, -16)},
	&"haymaker": {"hand": "r", "wind": Vector2(-10, -9), "strike": Vector2(15, 6), "bulge": -4.0},
	&"air_fist": {"hand": "both", "wind": Vector2(4, -8), "strike": Vector2(7, 12)},
	&"palm": {"hand": "f", "wind": Vector2(0, 1), "strike": Vector2(19, -1)},
}
const FIST_GUARD_F := Vector2(8, -2)
const FIST_GUARD_R := Vector2(4, 0)

var player: Player
var preset: PresetData
var preview := false
var _t := 0.0
var _ink := false   ## outline pass: every colour comes out as ink


func _ready() -> void:
	player = get_parent() as Player
	_t = randf() * 10.0


func _physics_process(delta: float) -> void:
	_t += delta
	if player:
		scale.x = player.facing
	queue_redraw()


func _look() -> PresetData:
	if player and player.look:
		return player.look
	if player and player.preset:
		return player.preset
	if preset:
		return preset
	return Presets.get_preset(Presets.DEFAULT_ID)


# ------------------------------------------------------------------ pose

## Builds the pose for the current state: body lean/crouch/legs plus weapon parameters.
func _new_pose(wl: int) -> Dictionary:
	var p := {
		"mode": "body", "lean": 0.0, "crouch": 0.0, "legs": 0.0, "arm_up": false,
		"flash": 0.0, "alpha": 1.0,
		"sa": 62.0, "sb": 100.0, "trail": Vector2.ZERO, "trail_b": Vector2.ZERO,
		"sh_off": 0.0, "sh_up": 0.0, "ext": 0.0,
		"fa": FIST_GUARD_F, "fb": FIST_GUARD_R, "ftrail": [],
	}
	if wl == PresetData.WeaponLook.TWIN:
		p["sa"] = 55.0
	return p


## Generic (non-attack) weapon poses so every weapon style reads in every state.
func _generic(p: Dictionary, wl: int, kind: String) -> void:
	var sw := 62.0
	var tw := Vector2(55.0, 100.0)
	var fists := [FIST_GUARD_F, FIST_GUARD_R]
	match kind:
		"air":
			sw = 35.0
			tw = Vector2(30.0, 45.0)
			fists = [Vector2(7, 3), Vector2(3, 4)]
		"parry":
			sw = -80.0
			tw = Vector2(-70.0, -95.0)
			fists = [Vector2(10, -6), Vector2(6, -5)]
			if wl == PresetData.WeaponLook.SWORD_SHIELD:
				sw = 62.0
				p["sh_off"] = 5.0
		"heal":
			sw = 80.0
			tw = Vector2(80.0, 95.0)
			fists = [Vector2(2, 6), Vector2(1, 7)]
		"hurt":
			sw = 100.0
			tw = Vector2(100.0, 120.0)
			fists = [Vector2(2, 5), Vector2(0, 6)]
		"rest":
			sw = 95.0
			tw = Vector2(95.0, 110.0)
			fists = [Vector2(3, 7), Vector2(1, 8)]
	p["sa"] = tw.x if wl == PresetData.WeaponLook.TWIN else sw
	p["sb"] = tw.y
	p["fa"] = fists[0]
	p["fb"] = fists[1]


func _attack_pose(p: Dictionary, wl: int, r: AttackRunner) -> void:
	var key: StringName = r.attack.animation
	var prog := r.phase_progress()
	var phase := r.phase
	match wl:
		PresetData.WeaponLook.SWORD, PresetData.WeaponLook.SWORD_SHIELD, PresetData.WeaponLook.GREATSWORD, \
		PresetData.WeaponLook.RAPIER, PresetData.WeaponLook.HAMMER, PresetData.WeaponLook.SPEAR, PresetData.WeaponLook.SABRE, \
		PresetData.WeaponLook.AXE, PresetData.WeaponLook.STAFF:
			var sw: Array = SWINGS.get(key, SWINGS[&"slash"])
			if key == &"bash":
				sw = [62.0, 62.0]
				var off := 0.0
				match phase:
					AttackRunner.Phase.STARTUP: off = lerpf(0.0, -4.0, ease(prog, 0.4))
					AttackRunner.Phase.ACTIVE: off = lerpf(-4.0, 13.0, ease(prog, 0.3))
					_: off = lerpf(13.0, 0.0, prog * prog)
				p["sh_off"] = off
			if wl == PresetData.WeaponLook.SWORD_SHIELD and key == &"heavy":
				p["sh_off"] = 4.0
			match phase:
				AttackRunner.Phase.STARTUP:
					p["sa"] = lerpf(62.0, sw[0], ease(prog, 0.4)); p["lean"] = -1.5; p["crouch"] = 1.0
				AttackRunner.Phase.ACTIVE:
					p["sa"] = lerpf(sw[0], sw[1], ease(prog, 0.35)); p["trail"] = Vector2(sw[0], p["sa"]); p["lean"] = 3.0; p["crouch"] = 1.5
				_:
					p["sa"] = lerpf(sw[1], 62.0, prog * prog); p["lean"] = 2.0 * (1.0 - prog); p["crouch"] = 1.5 * (1.0 - prog)
			if key == &"thrust" or (key == &"riposte" and wl in THRUSTERS):
				match phase:
					AttackRunner.Phase.STARTUP:
						p["sa"] = lerpf(62.0, 14.0, ease(prog, 0.4)); p["ext"] = lerpf(0.0, -4.0, ease(prog, 0.4))
					AttackRunner.Phase.ACTIVE:
						p["sa"] = 2.0; p["ext"] = lerpf(-4.0, 11.0, ease(prog, 0.3))
						p["trail"] = Vector2.ZERO
					_:
						p["sa"] = lerpf(2.0, 62.0, prog * prog); p["ext"] = lerpf(11.0, 0.0, prog)
			if key == &"riposte":
				p["lean"] = 4.0
		PresetData.WeaponLook.TWIN:
			var sets: Dictionary = TWIN.get(key, TWIN[&"twin_x"])
			var ra := Vector2(55.0, 55.0)
			var rb := Vector2(100.0, 100.0)
			var a: Array = sets.get("a", [55.0, 55.0])
			var b: Array = sets.get("b", [100.0, 100.0])
			match phase:
				AttackRunner.Phase.STARTUP:
					p["sa"] = lerpf(ra.x, a[0], ease(prog, 0.4)); p["sb"] = lerpf(rb.x, b[0], ease(prog, 0.4))
					p["lean"] = -1.5; p["crouch"] = 1.0
				AttackRunner.Phase.ACTIVE:
					p["sa"] = lerpf(a[0], a[1], ease(prog, 0.35)); p["sb"] = lerpf(b[0], b[1], ease(prog, 0.35))
					if sets.has("a"): p["trail"] = Vector2(a[0], p["sa"])
					if sets.has("b"): p["trail_b"] = Vector2(b[0], p["sb"])
					p["lean"] = 3.0; p["crouch"] = 1.5
				_:
					p["sa"] = lerpf(a[1], ra.y, prog * prog); p["sb"] = lerpf(b[1], rb.y, prog * prog)
					p["lean"] = 2.0 * (1.0 - prog); p["crouch"] = 1.5 * (1.0 - prog)
			if key == &"riposte":
				p["lean"] = 4.0
		PresetData.WeaponLook.FISTS:
			var spec: Dictionary = FISTS.get(key, FISTS[&"jab"])
			var wind: Vector2 = spec.wind
			var strike: Vector2 = spec.strike
			var bulge: float = spec.get("bulge", 0.0)
			var rest_f := FIST_GUARD_F
			var rest_r := FIST_GUARD_R
			var cur := Vector2.ZERO
			var from := Vector2.ZERO
			var hand: String = spec.hand
			var start := rest_f if hand == "f" else rest_r
			if hand == "both":
				start = rest_f
			match phase:
				AttackRunner.Phase.STARTUP:
					cur = start.lerp(wind, ease(prog, 0.4)); p["lean"] = -1.5; p["crouch"] = 1.0
				AttackRunner.Phase.ACTIVE:
					cur = wind.lerp(strike, ease(prog, 0.3)) + Vector2(0, bulge * sin(prog * PI))
					from = wind
					p["lean"] = 3.0; p["crouch"] = 1.5
				_:
					cur = strike.lerp(start, prog * prog); p["lean"] = 2.0 * (1.0 - prog); p["crouch"] = 1.5 * (1.0 - prog)
			if hand == "f":
				p["fa"] = cur
			elif hand == "r":
				p["fb"] = cur
			else:
				p["fa"] = cur
				p["fb"] = cur + Vector2(-4, 0)
			if phase == AttackRunner.Phase.ACTIVE:
				p["ftrail"] = [from, cur]
			if key == &"palm":
				p["lean"] = 4.0


func _pose() -> Dictionary:
	var look := _look()
	var wl: int = look.weapon_look
	var p := _new_pose(wl)
	if player == null:
		_generic(p, wl, "idle")
		p["crouch"] = (sin(_t * 2.6) + 1.0) * 0.35
		return p
	var s := player.state
	var f := player.state_frame
	if s == Player.State.HURT and f < 6 and Settings.flashes:
		p["flash"] = 1.0
	if player.is_dodge_invulnerable():
		p["alpha"] = 0.55
	elif player._iframes > 0 and s != Player.State.DEAD and s != Player.State.ATTACK and (f / 3) % 2 == 0:
		p["alpha"] = 0.7
	_generic(p, wl, "idle")
	match s:
		Player.State.FREE:
			if not player.is_on_floor():
				_generic(p, wl, "air")
				p["crouch"] = -1.0
				p["legs"] = 2.5
			elif absf(player.velocity.x) > 10.0:
				p["lean"] = 2.0
				p["legs"] = sin(_t * 14.0) * 3.5
				p["crouch"] = absf(sin(_t * 14.0)) * 0.8
			else:
				p["crouch"] = (sin(_t * 2.6) + 1.0) * 0.35
		Player.State.ATTACK:
			if player.attack_runner.attack:
				_attack_pose(p, wl, player.attack_runner)
		Player.State.DODGE:
			p["mode"] = "roll"
		Player.State.PARRY:
			_generic(p, wl, "parry")
			p["lean"] = -1.0
			p["crouch"] = 1.0
		Player.State.HEAL:
			_generic(p, wl, "heal")
			p["arm_up"] = f < player.heal_apply_frame + 6
			p["crouch"] = 0.5
		Player.State.HURT:
			_generic(p, wl, "hurt")
			p["lean"] = -3.0
		Player.State.REST:
			_generic(p, wl, "rest")
			p["crouch"] = 7.0
		Player.State.DEAD:
			p["mode"] = "dead"
	return p


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	if player == null and not preview:
		return
	var look := _look()
	var p := _pose()
	match p.mode:
		"roll":
			_draw_roll(look, player.state_frame, p.alpha)
			return
		"dead":
			_draw_dead(look, player.state_frame)
			return
	# 1 px ink outline: the figure drawn four times in ink, shifted, then once in colour on top.
	_ink = true
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_set_transform(o, 0.0, Vector2.ONE)
		_draw_figure(look, p)
	_ink = false
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_figure(look, p)
	if player == null:
		return
	if player.parry_flash > 0:
		var k := player.parry_flash / 18.0
		draw_arc(Vector2(10, -16), 10.0 + (1.0 - k) * 10.0, 0, TAU, 20, Color(Palette.GOLD_BRIGHT, k), 1.5)
	elif player.is_parry_active():
		draw_arc(Vector2(9, -16), 9.0, -1.4, 1.4, 10, Color(Palette.GOLD, 0.8), 1.0)
	if player.heal_flash > 0:
		var hk := player.heal_flash / 20.0
		draw_circle(Vector2(0, -14), 10.0 + (1.0 - hk) * 8.0, Color(Palette.GOLD_BRIGHT, hk * 0.35))


func _c(col: Color, flash: float, alpha: float) -> Color:
	if _ink:
		return Color(Palette.INK, alpha * 0.9)
	var out := col.lerp(Color.WHITE, flash)
	out.a = alpha
	return out


func _draw_figure(look: PresetData, p: Dictionary) -> void:
	var lean: float = p.lean
	var crouch: float = p.crouch
	var flash: float = p.flash
	var alpha: float = p.alpha
	var hip := Vector2(lean * 0.4, -11.0 + crouch)
	var shoulder := Vector2(lean, -22.0 + crouch * 1.2)
	var head := shoulder + Vector2(1.0 + lean * 0.3, -4.5)
	var sway := sin(_t * 3.0) * 0.8 - lean * 0.6

	_draw_legs(look, hip, p.legs, flash, alpha)
	_draw_torso(look, shoulder, hip, lean, sway, flash, alpha)
	_draw_head(look, head, flash, alpha)
	if p.arm_up:
		var vial := shoulder + Vector2(4, -6)
		draw_line(shoulder + Vector2(2, 1), vial, _c(look.cloth_light_color, flash, alpha), 2.0)
		draw_circle(vial, 2.2, _c(Palette.GOLD_BRIGHT, flash, alpha))
		draw_circle(vial, 5.0, Color(Palette.GOLD, 0.25 * alpha))
	_draw_weapon(look, p, shoulder, flash, alpha)


func _draw_legs(look: PresetData, hip: Vector2, legs: float, flash: float, alpha: float) -> void:
	var back := look.cloth_color
	var front := look.cloth_light_color
	var width := 3.0
	match look.armor_look:
		PresetData.ArmorLook.BARE:
			back = look.cloth_color
			front = look.cloth_light_color
			width = 2.6
		PresetData.ArmorLook.LIGHT:
			back = Palette.STONE_DARK
			front = Palette.CLOAK_LIGHT
		PresetData.ArmorLook.KNIGHT:
			back = Palette.STONE_DARK
			front = Palette.CLOAK_LIGHT
		PresetData.ArmorLook.HEAVY:
			back = look.cloth_color
			front = look.cloth_light_color
			width = 3.6
	draw_line(hip + Vector2(-2, 0), Vector2(-2.5 - legs, 0), _c(back, flash, alpha), width)
	draw_line(hip + Vector2(2, 0), Vector2(2.5 + legs, 0), _c(front, flash, alpha), width)
	if look.armor_look == PresetData.ArmorLook.BARE:
		# Wrapped ankles (bone cloth) so the barefoot silhouette still reads.
		draw_line(Vector2(-2.5 - legs, -2.5), Vector2(-2.5 - legs, -1.0), _c(look.accent_color, flash, alpha), 3.0)
		draw_line(Vector2(2.5 + legs, -2.5), Vector2(2.5 + legs, -1.0), _c(look.accent_color, flash, alpha), 3.0)
	if look.armor_look == PresetData.ArmorLook.HEAVY:
		# Knee plates.
		draw_circle(Vector2(-2.3 - legs * 0.5, -5.0), 1.8, _c(Palette.STEEL, flash, alpha))
		draw_circle(Vector2(2.3 + legs * 0.5, -5.0), 1.8, _c(Palette.STEEL, flash, alpha))


func _draw_torso(look: PresetData, shoulder: Vector2, hip: Vector2, lean: float, sway: float, flash: float, alpha: float) -> void:
	match look.armor_look:
		PresetData.ArmorLook.BARE:
			# Bare torso (skin) with ragged waist-cloth and bone-cloth wraps; no cloak, no armour.
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-3.4, 0), shoulder + Vector2(3.6, 0),
				hip + Vector2(2.8, 1), hip + Vector2(-2.8, 1)]), _c(look.cloth_color, flash, alpha))
			draw_line(shoulder + Vector2(1.5, 2), hip + Vector2(1.2, -2), _c(look.cloth_light_color, flash, alpha), 1.0)
			draw_line(shoulder + Vector2(-0.5, 5), shoulder + Vector2(3.0, 5), _c(look.cloth_light_color, flash, alpha), 1.0)
			draw_colored_polygon(PackedVector2Array([
				hip + Vector2(-4.2, -1.5), hip + Vector2(4.2, -1.5), hip + Vector2(4.6, 4.5 + sway * 0.3),
				hip + Vector2(1.5, 3.2), hip + Vector2(-0.8, 5.5), hip + Vector2(-4.6, 4.0)]), _c(Palette.STONE, flash, alpha))
			draw_line(hip + Vector2(-4.2, -1.5), hip + Vector2(4.2, -1.5), _c(look.accent_color, flash, alpha), 1.2)
		PresetData.ArmorLook.LIGHT:
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-4, 0), shoulder + Vector2(4, 0),
				hip + Vector2(4, 1), hip + Vector2(-3.6, 1)]), _c(look.cloth_color, flash, alpha))
			draw_line(shoulder + Vector2(-3, 2), hip + Vector2(3, -1), _c(look.accent_color, flash, alpha), 1.0)
			draw_line(shoulder + Vector2(3, 2), hip + Vector2(-3, -1), _c(look.accent_color, flash, alpha), 1.0)
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-4, 0), shoulder + Vector2(-8 + sway, 8), shoulder + Vector2(-3, 7)]), _c(look.cloth_light_color, flash, alpha))
			draw_line(hip + Vector2(-4, 0), hip + Vector2(4, 0), _c(Palette.WOOD_LIGHT, flash, alpha), 1.4)
		PresetData.ArmorLook.KNIGHT:
			var cloak := PackedVector2Array([
				shoulder + Vector2(-4, 0), shoulder + Vector2(4, 0),
				hip + Vector2(5, 2), hip + Vector2(1, 5), hip + Vector2(-3, 4 + sway), hip + Vector2(-8 + sway, 3)])
			draw_colored_polygon(cloak, _c(look.cloth_color, flash, alpha))
			draw_line(shoulder + Vector2(-4, 0), hip + Vector2(-8 + sway, 3), _c(look.cloth_light_color, flash, alpha), 1.0)
			draw_line(shoulder + Vector2(-3, 3), hip + Vector2(4, -1), _c(look.accent_color, flash, alpha), 1.5)
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-2, -1), shoulder + Vector2(-9 - lean, 1 + sway), shoulder + Vector2(-2, 2)]), _c(look.accent_color, flash, alpha))
		PresetData.ArmorLook.HEAVY:
			# Plate cuirass, tabard strip, skirt plates, and pauldrons.
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-4.6, 0), shoulder + Vector2(4.6, 0),
				hip + Vector2(4.2, 1), hip + Vector2(-4.2, 1)]), _c(look.cloth_color, flash, alpha))
			draw_line(shoulder + Vector2(-4.6, 0.5), shoulder + Vector2(4.6, 0.5), _c(look.cloth_light_color, flash, alpha), 1.0)
			draw_colored_polygon(PackedVector2Array([
				shoulder + Vector2(-1.2, 1), shoulder + Vector2(1.6, 1), hip + Vector2(1.6, 6), hip + Vector2(-1.2, 6)]), _c(look.accent_color, flash, alpha))
			draw_colored_polygon(PackedVector2Array([
				hip + Vector2(-5, 0), hip + Vector2(5, 0), hip + Vector2(5.4, 4), hip + Vector2(-5.4, 4)]), _c(look.cloth_light_color, flash, alpha))
			draw_circle(shoulder + Vector2(-3.8, 0.5), 3.0, _c(look.cloth_light_color, flash, alpha))
			draw_circle(shoulder + Vector2(3.8, 0.5), 3.0, _c(look.cloth_light_color, flash, alpha))


func _draw_head(look: PresetData, head: Vector2, flash: float, alpha: float) -> void:
	match look.armor_look:
		PresetData.ArmorLook.BARE:
			# Bare head: skin, dark cropped hair, a bone headband (the Unsworn's only adornment).
			draw_circle(head, 3.9, _c(look.cloth_light_color, flash, alpha))
			draw_arc(head, 4.2, PI * 0.55, PI * 1.75, 8, _c(Palette.NIGHT, flash, alpha), 2.4)
			draw_line(head + Vector2(-3.9, -1.3), head + Vector2(3.9, -1.9), _c(look.accent_color, flash, alpha), 1.3)
			draw_line(head + Vector2(-3.9, -1.3), head + Vector2(-7.0, 0.5 + sin(_t * 5.0)), _c(look.accent_color, flash, alpha), 1.0)
			draw_rect(Rect2(head + Vector2(1.6, -0.2), Vector2(1.3, 1.0)), _c(Palette.INK, flash, alpha))
		PresetData.ArmorLook.LIGHT:
			draw_circle(head, 4.0, _c(Palette.BONE_DIM, flash, alpha))
			draw_arc(head, 4.8, PI * 0.5, PI * 1.7, 8, _c(look.cloth_color, flash, alpha), 2.4)
			draw_rect(Rect2(head + Vector2(0.5, -1.0), Vector2(3.5, 1.2)), _c(Palette.INK, flash, alpha))
			draw_circle(head + Vector2(-1.5, -3.2), 0.9, _c(look.accent_color, flash, alpha))
		PresetData.ArmorLook.KNIGHT:
			draw_circle(head, 4.0, _c(Palette.BONE, flash, alpha))
			draw_rect(Rect2(head + Vector2(0.5, -1.0), Vector2(3.5, 1.2)), _c(Palette.INK, flash, alpha))
			draw_arc(head, 4.6, PI * 0.6, PI * 1.6, 8, _c(look.cloth_color, flash, alpha), 1.6)
		PresetData.ArmorLook.HEAVY:
			draw_circle(head, 4.6, _c(look.cloth_light_color, flash, alpha))
			draw_rect(Rect2(head + Vector2(-0.5, -1.4), Vector2(5.0, 1.3)), _c(Palette.INK, flash, alpha))
			draw_line(head + Vector2(-4.2, 1.6), head + Vector2(4.2, 1.6), _c(look.cloth_color, flash, alpha), 1.2)
			draw_colored_polygon(PackedVector2Array([
				head + Vector2(-1.5, -4.2), head + Vector2(0.5, -7.5), head + Vector2(2.5, -4.2)]), _c(look.accent_color, flash, alpha))


func _draw_weapon(look: PresetData, p: Dictionary, shoulder: Vector2, flash: float, alpha: float) -> void:
	var arm_col := look.cloth_light_color if look.armor_look != PresetData.ArmorLook.KNIGHT else Palette.CLOAK_LIGHT
	match look.weapon_look:
		PresetData.WeaponLook.SWORD:
			_draw_blade(shoulder + Vector2(3, 3), p.sa, 17.0, p.trail, arm_col, shoulder, flash, alpha, true)
		PresetData.WeaponLook.TWIN:
			_draw_blade(shoulder + Vector2(2, 4), p.sb, 11.0, p.trail_b, arm_col, shoulder, flash, alpha, false)
			_draw_blade(shoulder + Vector2(3, 3), p.sa, 11.0, p.trail, arm_col, shoulder, flash, alpha, false)
		PresetData.WeaponLook.SWORD_SHIELD:
			_draw_blade(shoulder + Vector2(3, 3), p.sa, 16.0, p.trail, arm_col, shoulder, flash, alpha, true)
			_draw_shield(look, shoulder + Vector2(5.0 + p.sh_off, 5.0 - p.sh_up), p.sh_off > 2.0, flash, alpha)
		PresetData.WeaponLook.FISTS:
			_draw_fists(look, p, shoulder, flash, alpha)
		PresetData.WeaponLook.GREATSWORD, PresetData.WeaponLook.RAPIER, PresetData.WeaponLook.HAMMER, \
		PresetData.WeaponLook.SPEAR, PresetData.WeaponLook.SABRE, PresetData.WeaponLook.AXE, PresetData.WeaponLook.STAFF:
			_draw_long_weapon(look, p, shoulder, flash, alpha, arm_col)


## Greatsword, rapier, hammer, spear and sabre: one hand position, a different thing in it.
func _draw_long_weapon(look: PresetData, p: Dictionary, shoulder: Vector2, flash: float, alpha: float, arm_col: Color) -> void:
	var wl: int = look.weapon_look
	var hand := shoulder + Vector2(3.0 + float(p.get("ext", 0.0)), 3.0)
	var deg: float = p.sa
	var dir := Vector2.from_angle(deg_to_rad(deg))
	var ortho := dir.orthogonal()
	var length: float = {4: 26.0, 5: 22.0, 6: 15.0, 7: 30.0, 8: 18.0, 9: 24.0, 10: 28.0}[wl]
	if p.trail != Vector2.ZERO:
		_draw_trail(hand, p.trail.x, p.trail.y, alpha, length)
	draw_line(shoulder + Vector2(2, 1), hand, _c(arm_col, flash, alpha), 2.0)
	var steel := _c(Palette.STEEL, flash, alpha)
	var gold := _c(Palette.GOLD, flash, alpha)
	var wood := _c(Palette.WOOD_LIGHT, flash, alpha)
	match wl:
		PresetData.WeaponLook.GREATSWORD:
			draw_line(shoulder + Vector2(1, 3), hand + dir * 2.0, _c(arm_col, flash, alpha), 1.6)
			draw_line(hand - dir * 4.0, hand + dir * 3.0, wood, 2.0)
			draw_line(hand + dir * 3.0 - ortho * 3.5, hand + dir * 3.0 + ortho * 3.5, gold, 1.6)
			draw_line(hand + dir * 3.0, hand + dir * length, steel, 3.0)
			draw_line(hand + dir * 5.0, hand + dir * (length - 2.0), _c(Palette.BONE, flash, alpha * 0.7), 0.8)
		PresetData.WeaponLook.RAPIER:
			draw_line(hand - dir * 2.0, hand + dir * 1.0, wood, 1.6)
			draw_arc(hand + dir * 2.0, 3.0, deg_to_rad(deg) - 1.6, deg_to_rad(deg) + 1.6, 6, gold, 1.0)
			draw_line(hand + dir * 2.0, hand + dir * length, steel, 1.0)
		PresetData.WeaponLook.HAMMER:
			draw_line(hand - dir * 3.0, hand + dir * length, wood, 2.0)
			var head: Vector2 = hand + dir * length
			draw_colored_polygon(PackedVector2Array([head + ortho * 4.0 - dir * 3.0, head + ortho * 4.0 + dir * 3.0,
				head - ortho * 4.0 + dir * 3.0, head - ortho * 4.0 - dir * 3.0]), steel)
			draw_line(head + ortho * 4.0, head - ortho * 4.0, gold, 0.8)
		PresetData.WeaponLook.SPEAR:
			draw_line(hand - dir * 7.0, hand + dir * (length - 6.0), wood, 1.8)
			var tip: Vector2 = hand + dir * length
			var base: Vector2 = hand + dir * (length - 7.0)
			draw_colored_polygon(PackedVector2Array([base + ortho * 2.0, tip, base - ortho * 2.0]), steel)
			draw_line(base + ortho * 1.6, base - ortho * 1.6, _c(look.accent_color, flash, alpha), 1.2)
		PresetData.WeaponLook.AXE:
			draw_line(hand - dir * 4.0, hand + dir * length, wood, 2.2)
			var ah: Vector2 = hand + dir * (length - 3.0)
			draw_colored_polygon(PackedVector2Array([ah - dir * 3.0, ah + dir * 3.0, ah + ortho * 7.0 + dir * 5.0, ah + ortho * 7.0 - dir * 5.0]), steel)
			draw_line(ah + ortho * 7.0 + dir * 5.0, ah + ortho * 7.0 - dir * 5.0, _c(Palette.BONE, flash, alpha * 0.8), 0.8)
			draw_line(ah - dir * 4.0, ah + dir * 4.0, gold, 1.2)
		PresetData.WeaponLook.STAFF:
			draw_line(hand - dir * 6.0, hand + dir * (length - 4.0), wood, 1.8)
			var sh: Vector2 = hand + dir * length
			draw_arc(sh, 3.4, 0.0, TAU, 10, gold, 1.2)
			var lit := 0.6 + 0.4 * sin(_t * 9.0)
			draw_circle(sh, 1.6, Color(1.0, 0.7, 0.3, lit * alpha))
			draw_circle(sh, 5.0, Color(1.0, 0.6, 0.2, 0.15 * lit * alpha))
		PresetData.WeaponLook.SABRE:
			var pts := PackedVector2Array()
			for i in 7:
				var f := float(i) / 6.0
				pts.append(hand + dir * (f * length) + ortho * (sin(f * PI) * 2.2))
			draw_polyline(pts, _c(Color("9fb7bf"), flash, alpha), 1.6)
			draw_line(hand + dir * 1.5 - ortho * 2.0, hand + dir * 1.5 + ortho * 2.0, gold, 1.2)


func _draw_blade(hand: Vector2, deg: float, length: float, trail: Vector2, arm_col: Color, shoulder: Vector2, flash: float, alpha: float, crossguard: bool) -> void:
	if trail != Vector2.ZERO:
		_draw_trail(hand, trail.x, trail.y, alpha, length)
	var dir := Vector2.from_angle(deg_to_rad(deg))
	draw_line(shoulder + Vector2(2, 1), hand, _c(arm_col, flash, alpha), 2.0)
	draw_line(hand - dir * 2.0, hand + dir * length, _c(Palette.STEEL, flash, alpha), 1.6)
	draw_line(hand + dir * 2.0, hand + dir * (length - 2.0), _c(Palette.BONE, flash, alpha * 0.6), 0.6)
	var ortho := dir.orthogonal()
	var gw := 2.5 if crossguard else 1.8
	draw_line(hand + dir * 1.5 - ortho * gw, hand + dir * 1.5 + ortho * gw, _c(Palette.GOLD, flash, alpha), 1.2)


func _draw_shield(look: PresetData, c: Vector2, bash: bool, flash: float, alpha: float) -> void:
	var pts := PackedVector2Array([
		c + Vector2(-2.5, -6), c + Vector2(2.5, -6), c + Vector2(4.2, -2), c + Vector2(3.4, 3.5),
		c + Vector2(0, 7), c + Vector2(-3.4, 3.5), c + Vector2(-4.2, -2)])
	draw_colored_polygon(pts, _c(look.cloth_light_color, flash, alpha))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, _c(Palette.STEEL, flash, alpha), 1.0)
	draw_line(c + Vector2(0, -5), c + Vector2(0, 6), _c(look.accent_color, flash, alpha), 1.0)
	draw_circle(c, 1.5, _c(Palette.GOLD, flash, alpha))
	if bash:
		draw_arc(c + Vector2(-3, 0), 9.0, -0.9, 0.9, 8, Color(Palette.BONE, 0.45 * alpha), 1.5)


func _draw_fists(look: PresetData, p: Dictionary, shoulder: Vector2, flash: float, alpha: float) -> void:
	var trail: Array = p.ftrail
	if trail.size() == 2:
		var a: Vector2 = shoulder + trail[0]
		var b: Vector2 = shoulder + trail[1]
		draw_line(a, b, Color(Palette.BONE, 0.40 * alpha), 4.0)
		draw_line(a, b, Color(Palette.BONE, 0.7 * alpha), 1.5)
	# Rear arm behind, front arm in front.
	_draw_arm_fist(look, shoulder + Vector2(-1, 1), shoulder + p.fb, true, flash, alpha)
	_draw_arm_fist(look, shoulder + Vector2(2, 1), shoulder + p.fa, false, flash, alpha)
	if look.id == &"unsworn" and trail.size() == 2 and p.fa.x > 14.0:
		draw_circle(shoulder + p.fa, 5.0, Color(Palette.GOLD_BRIGHT, 0.18 * alpha))


func _draw_arm_fist(look: PresetData, from: Vector2, to: Vector2, rear: bool, flash: float, alpha: float) -> void:
	var skin := look.cloth_color if rear else look.cloth_light_color
	if look.armor_look != PresetData.ArmorLook.BARE:
		skin = look.cloth_light_color
	draw_line(from, to, _c(skin, flash, alpha), 2.2)
	# Bone-cloth wrapped forearm and knuckles.
	var dir := (to - from).normalized()
	draw_line(to - dir * 4.0, to - dir * 1.0, _c(look.accent_color, flash, alpha), 2.6)
	draw_circle(to, 2.4, _c(look.accent_color, flash, alpha))
	draw_circle(to + dir * 0.6, 1.0, _c(Palette.BONE_DIM, flash, alpha))


func _draw_trail(hand: Vector2, from_deg: float, to_deg: float, alpha: float, length: float = 17.0) -> void:
	var a0 := deg_to_rad(from_deg)
	var a1 := deg_to_rad(to_deg)
	var pts := PackedVector2Array()
	var steps := 8
	var outer := length + 2.0
	var inner := length * 0.45
	for i in steps + 1:
		pts.append(hand + Vector2.from_angle(lerpf(a0, a1, float(i) / steps)) * outer)
	for i in range(steps, -1, -1):
		pts.append(hand + Vector2.from_angle(lerpf(a0, a1, float(i) / steps)) * inner)
	draw_colored_polygon(pts, Color(Palette.BONE, 0.35 * alpha))


func _draw_roll(look: PresetData, f: int, alpha: float) -> void:
	var t := clampf(float(f) / player.dodge_frames, 0.0, 1.0)
	var ang := t * TAU * 1.0
	var c := Vector2(0, -8)
	var body := look.cloth_color
	var head := Palette.BONE
	var mark := look.accent_color
	match look.armor_look:
		PresetData.ArmorLook.BARE:
			head = look.cloth_light_color
		PresetData.ArmorLook.HEAVY:
			head = look.cloth_light_color
	draw_circle(c, 8.0 if look.armor_look != PresetData.ArmorLook.HEAVY else 8.6, Color(body, alpha))
	draw_arc(c, 8.0, ang, ang + PI, 10, Color(look.cloth_light_color, alpha), 1.5)
	draw_circle(c + Vector2.from_angle(ang) * 4.0, 2.5, Color(head, alpha))
	draw_line(c + Vector2.from_angle(ang + 2.0) * 5.0, c + Vector2.from_angle(ang + 2.6) * 11.0, Color(mark, alpha), 1.5)
	if player.is_on_floor():
		for i in 3:
			draw_circle(Vector2(-8 - i * 4, -1 - i), 1.5 - i * 0.4, Color(Palette.DUST, 0.5 * (1.0 - t)))


func _draw_dead(look: PresetData, f: int) -> void:
	var k := clampf(f / 20.0, 0.0, 1.0)
	var a := 1.0 - clampf((f - 60) / 60.0, 0.0, 0.7)
	var head := Palette.BONE
	if look.armor_look == PresetData.ArmorLook.BARE or look.armor_look == PresetData.ArmorLook.HEAVY:
		head = look.cloth_light_color
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(10, 0), Vector2(8, -5 * (1.0 - k) - 4), Vector2(-10, -4),
	]), Color(look.cloth_color, a))
	draw_circle(Vector2(12, -2 - 6 * (1.0 - k)), 3.5, Color(head, a))
	match look.weapon_look:
		PresetData.WeaponLook.FISTS:
			draw_circle(Vector2(-6, -2), 2.2, Color(look.accent_color, a))
			draw_circle(Vector2(-12, 0), 2.2, Color(look.accent_color, a))
		PresetData.WeaponLook.SWORD_SHIELD:
			draw_line(Vector2(-4, -1), Vector2(-20, 1), Color(Palette.STEEL, a), 1.5)
			draw_circle(Vector2(-1, -5), 4.0, Color(look.cloth_light_color, a))
		_:
			draw_line(Vector2(-4, -1), Vector2(-20, 1), Color(Palette.STEEL, a), 1.5)
	draw_line(Vector2(-6, -3), Vector2(6, -2), Color(look.accent_color, a), 1.5)
