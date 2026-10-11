class_name IconArt
extends RefCounted
## Every inventory icon, drawn with vector primitives (no image files: crisp at any
## resolution and costs nothing in download size). Icons are designed on a 16 x 16 grid
## and scaled to whatever rect they are drawn in. TEMPORARY ART until painted icons exist.
##
##   IconArt.draw(canvas_item, &"ash_bandage", Rect2(...))
## Ids: item ids, weapon ids (oathblade, twin_blades, sword_and_shield, fists),
## armour ids ("armor_" + preset id), and &"status".

const OUTLINE := Color(0.05, 0.04, 0.06, 0.9)


static func has_icon(id: StringName) -> bool:
	return id in [&"ash_bandage", &"ember_shard", &"stamina_tonic", &"rusted_key", &"warden_bell_shard",
		&"penitents_tear", &"candlewright_note", &"canon_seal", &"pilgrims_draught", &"marshals_crest", &"oathblade", &"twin_blades",
		&"sword_and_shield", &"fists", &"armor_sworn_knight", &"armor_duelist", &"armor_bulwark",
		&"armor_unsworn", &"status", &"forge_scrap", &"hollow_resin", &"vial"] \
		or Weapons.IDS.has(id) or (String(id).begins_with("armor_") and Armors.is_valid_id(String(id).substr(6)))


static func draw(ci: CanvasItem, id: StringName, r: Rect2, t := 0.0) -> void:
	var s := minf(r.size.x, r.size.y) / 16.0
	ci.draw_set_transform(r.position + (r.size - Vector2(16, 16) * s) / 2.0, 0.0, Vector2(s, s))
	match id:
		&"ash_bandage": _bandage(ci)
		&"ember_shard": _shard(ci, t)
		&"stamina_tonic": _tonic(ci)
		&"rusted_key": _key(ci)
		&"warden_bell_shard": _bell_shard(ci)
		&"penitents_tear": _tear(ci, t)
		&"candlewright_note": _note(ci)
		&"canon_seal": _seal(ci)
		&"pilgrims_draught": _draught(ci)
		&"marshals_crest": _crest(ci)
		&"oathblade": _sword(ci, Vector2(3, 13), Vector2(13, 3), true)
		&"twin_blades": _twin(ci)
		&"sword_and_shield": _sword_shield(ci)
		&"fists": _fist(ci)
		&"armor_sworn_knight": _mail(ci)
		&"armor_duelist": _leathers(ci)
		&"armor_bulwark": _plate(ci)
		&"armor_unsworn": _wraps(ci)
		&"status": _sigil(ci, t)
		&"forge_scrap": _scrap(ci)
		&"hollow_resin": _resin(ci)
		&"vial": _vial(ci)
		&"wayfarers_rapier": _rapier(ci)
		&"kingsfall_greatsword": _greatsword(ci)
		&"toll_hammer": _hammer(ci)
		&"marshals_lance": _lance(ci)
		&"tide_sabre": _sabre(ci)
		&"armor_pilgrim_coat", &"armor_penitent_shroud", &"armor_canons_mail", &"armor_marshal_plate": _armor_generic(ci, id)
		_: _unknown(ci)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _poly(ci: CanvasItem, pts: Array, col: Color, outline := true) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, col)
	if outline:
		var o := p.duplicate()
		o.append(p[0])
		ci.draw_polyline(o, OUTLINE, 0.6)


# ------------------------------------------------------------------ items

static func _bandage(ci: CanvasItem) -> void:
	# A roll of linen with a grey ash band and a loose tail.
	_poly(ci, [Vector2(3, 6), Vector2(11, 6), Vector2(11, 12), Vector2(3, 12)], Color("d9cfb6"))
	ci.draw_circle(Vector2(11, 9), 3.0, Color("e9e1cc"))
	ci.draw_arc(Vector2(11, 9), 3.0, 0, TAU, 12, OUTLINE, 0.6)
	ci.draw_arc(Vector2(11, 9), 1.6, 0, TAU, 10, Color("b9ae95"), 0.6)
	ci.draw_rect(Rect2(5.5, 6, 2, 6), Color("8a8580"))
	_poly(ci, [Vector2(3, 10), Vector2(1, 14), Vector2(3.5, 14.5), Vector2(4.5, 12)], Color("d9cfb6"))


static func _shard(ci: CanvasItem, t: float) -> void:
	ci.draw_circle(Vector2(8, 8.5), 6.5, Color(1.0, 0.55, 0.2, 0.18 + 0.06 * sin(t * 3.0)))
	_poly(ci, [Vector2(8, 1.5), Vector2(11.5, 7), Vector2(9.5, 14.5), Vector2(5.5, 13), Vector2(4.5, 6.5)], Color("e07a2a"))
	_poly(ci, [Vector2(8, 1.5), Vector2(9.5, 7), Vector2(8, 13), Vector2(6.5, 6.5)], Color("ffc46b"), false)
	ci.draw_line(Vector2(8, 3), Vector2(8, 11), Color(1, 0.95, 0.8, 0.8), 0.6)


static func _tonic(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(6.5, 2), Vector2(9.5, 2), Vector2(9.5, 5), Vector2(12.5, 9), Vector2(12, 14), Vector2(4, 14), Vector2(3.5, 9), Vector2(6.5, 5)], Color(0.75, 0.85, 0.85, 0.55))
	_poly(ci, [Vector2(4.2, 9.5), Vector2(11.8, 9.5), Vector2(11.6, 13.5), Vector2(4.4, 13.5)], Color("8fd07a"), false)
	ci.draw_rect(Rect2(6.2, 1, 3.6, 1.6), Color("6d523b"))
	ci.draw_line(Vector2(5.5, 10.5), Vector2(6.5, 12.5), Color(1, 1, 1, 0.6), 0.6)


static func _draught(ci: CanvasItem) -> void:
	# A round-bellied flask of red wine with a corked neck and a herb sprig.
	_poly(ci, [Vector2(6.5, 2.5), Vector2(9.5, 2.5), Vector2(9.5, 6), Vector2(12.5, 9.5), Vector2(12, 13.5), Vector2(4, 13.5), Vector2(3.5, 9.5), Vector2(6.5, 6)], Color(0.85, 0.8, 0.8, 0.5))
	_poly(ci, [Vector2(4.1, 9.8), Vector2(11.9, 9.8), Vector2(11.6, 13.1), Vector2(4.4, 13.1)], Color("a8323e"), false)
	ci.draw_rect(Rect2(6.2, 1.2, 3.6, 1.8), Color("6d523b"))
	ci.draw_line(Vector2(5.2, 10.8), Vector2(6.2, 12.4), Color(1, 1, 1, 0.5), 0.6)
	ci.draw_line(Vector2(10.4, 3.2), Vector2(12.6, 1.6), Color("6fa05a"), 0.8)


static func _crest(ci: CanvasItem) -> void:
	# A brass plume-holder: a crowned shield with three candle flames.
	_poly(ci, [Vector2(3, 4), Vector2(13, 4), Vector2(13, 9), Vector2(8, 14), Vector2(3, 9)], Color("b9964a"))
	_poly(ci, [Vector2(4.5, 5.5), Vector2(11.5, 5.5), Vector2(11.5, 8.6), Vector2(8, 12), Vector2(4.5, 8.6)], Color("7a6130"), false)
	for x in [5.8, 8.0, 10.2]:
		ci.draw_rect(Rect2(x - 0.4, 7.0, 0.8, 2.2), Color("efe6cf"))
		ci.draw_circle(Vector2(x, 6.4), 0.7, Color("ffcc66"))
	ci.draw_line(Vector2(5, 2.4), Vector2(11, 2.4), Color("e0702a"), 0.9)
	ci.draw_line(Vector2(6, 1.4), Vector2(10, 1.4), Color("e0702a"), 0.9)


static func _key(ci: CanvasItem) -> void:
	var rust := Color("9a5b32")
	ci.draw_arc(Vector2(5, 5), 3.0, 0, TAU, 14, OUTLINE, 2.6)
	ci.draw_arc(Vector2(5, 5), 3.0, 0, TAU, 14, rust, 1.8)
	ci.draw_line(Vector2(7, 7), Vector2(13.5, 13.5), OUTLINE, 2.6)
	ci.draw_line(Vector2(7, 7), Vector2(13.5, 13.5), rust, 1.6)
	ci.draw_line(Vector2(11, 11), Vector2(9.5, 12.5), rust, 1.6)
	ci.draw_line(Vector2(13, 13), Vector2(11.5, 14.5), rust, 1.6)
	ci.draw_circle(Vector2(9, 9), 0.6, Color("c47a45"))


static func _bell_shard(ci: CanvasItem) -> void:
	# The left half of a bronze bell, broken off along a jagged line.
	_poly(ci, [Vector2(8.5, 2.5), Vector2(6, 3), Vector2(4.5, 6), Vector2(4, 10), Vector2(2, 13), Vector2(9, 13),
		Vector2(8, 11.5), Vector2(9.5, 9.5), Vector2(8, 7.5), Vector2(9.5, 5.5), Vector2(8, 4)], Color("8a6638"))
	ci.draw_line(Vector2(2.3, 12.8), Vector2(8.8, 12.8), Color("4a3520"), 1.0)
	ci.draw_line(Vector2(5.5, 5), Vector2(5, 9), Color("c49a5c"), 0.8)
	ci.draw_rect(Rect2(6.5, 1, 2, 1.8), Color("4a3520"))
	# Small fragment beside it.
	_poly(ci, [Vector2(11, 9), Vector2(13.5, 10), Vector2(12.5, 13), Vector2(10.5, 12)], Color("7a5a33"))


static func _tear(ci: CanvasItem, t: float) -> void:
	ci.draw_circle(Vector2(8, 10), 5.5, Color(0.6, 0.75, 0.95, 0.15 + 0.05 * sin(t * 2.0)))
	_poly(ci, [Vector2(8, 2), Vector2(11.5, 8.5), Vector2(11.5, 11), Vector2(8, 14), Vector2(4.5, 11), Vector2(4.5, 8.5)], Color("8fb3e6"))
	ci.draw_circle(Vector2(6.5, 9.5), 1.0, Color(1, 1, 1, 0.75))


static func _note(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(3, 2), Vector2(12, 2), Vector2(13, 14), Vector2(4, 14)], Color("e3d6b2"))
	for i in 4:
		ci.draw_line(Vector2(5, 4.5 + i * 2.2), Vector2(11, 4.5 + i * 2.2), Color("7a6e58"), 0.6)
	ci.draw_circle(Vector2(10.5, 12), 2.0, Color("8e1b22"))
	ci.draw_circle(Vector2(10.5, 12), 0.8, Color("c0484e"))


static func _seal(ci: CanvasItem) -> void:
	ci.draw_circle(Vector2(8, 8), 6.0, Color("1d2122"))
	ci.draw_arc(Vector2(8, 8), 6.0, 0, TAU, 18, OUTLINE, 0.8)
	ci.draw_arc(Vector2(8, 8), 4.5, 0, TAU, 16, Color("4a5557"), 0.7)
	# The Candlewright flame, upside down.
	_poly(ci, [Vector2(6.5, 6), Vector2(9.5, 6), Vector2(8, 11)], Color("6f8a87"), false)
	ci.draw_line(Vector2(6, 5), Vector2(10, 5), Color("6f8a87"), 0.8)


# ------------------------------------------------------------------ weapons

static func _sword(ci: CanvasItem, hilt: Vector2, tip: Vector2, guard := true) -> void:
	var d := (tip - hilt).normalized()
	var n := d.orthogonal()
	var base := hilt + d * 3.0
	_poly(ci, [base + n * 1.0, tip - d * 1.2 + n * 0.7, tip, tip - d * 1.2 - n * 0.7, base - n * 1.0], Color("b8bcc4"))
	ci.draw_line(base, tip - d * 1.5, Color(1, 1, 1, 0.5), 0.5)
	if guard:
		ci.draw_line(base + n * 2.6, base - n * 2.6, OUTLINE, 1.8)
		ci.draw_line(base + n * 2.4, base - n * 2.4, Color("c9a24e"), 1.1)
	ci.draw_line(hilt, base, Color("4b3627"), 1.6)
	ci.draw_circle(hilt, 1.0, Color("c9a24e"))


static func _twin(ci: CanvasItem) -> void:
	_sword(ci, Vector2(3, 13), Vector2(12, 4), true)
	_sword(ci, Vector2(13, 13), Vector2(4, 4), true)


static func _sword_shield(ci: CanvasItem) -> void:
	_sword(ci, Vector2(2.5, 14), Vector2(10, 2), true)
	_poly(ci, [Vector2(7, 5), Vector2(14, 5), Vector2(14, 10), Vector2(10.5, 14.5), Vector2(7, 10)], Color("4a5160"))
	ci.draw_line(Vector2(10.5, 5.5), Vector2(10.5, 13.5), Color("8e1b22"), 1.2)
	ci.draw_circle(Vector2(10.5, 8.5), 1.0, Color("c9a24e"))


static func _fist(ci: CanvasItem) -> void:
	var skin := Color("8a6a52")
	var wrap := Color("d9d0bc")
	_poly(ci, [Vector2(4, 4), Vector2(12, 4), Vector2(13, 9), Vector2(11, 14), Vector2(5, 14), Vector2(3, 9)], skin)
	for i in 4:
		ci.draw_line(Vector2(5 + i * 2, 4.5), Vector2(5 + i * 2, 7.5), OUTLINE, 0.5)
	ci.draw_rect(Rect2(3.5, 8, 9, 2), wrap)
	ci.draw_rect(Rect2(4.5, 11, 7, 1.6), wrap)
	_poly(ci, [Vector2(3, 8), Vector2(6, 9), Vector2(5, 11.5), Vector2(2.5, 10.5)], skin)


static func _rapier(ci: CanvasItem) -> void:
	var d := Vector2(1, -1).normalized()
	ci.draw_line(Vector2(5, 11), Vector2(14, 2), Color("d8dce4"), 1.0)
	ci.draw_arc(Vector2(4.6, 11.4), 3.2, deg_to_rad(-135), deg_to_rad(45), 8, Color("c9a24e"), 1.2)
	ci.draw_line(Vector2(4, 12), Vector2(2, 14), Color("4b3627"), 1.8)
	ci.draw_circle(Vector2(1.8, 14.2), 1.0, Color("c9a24e"))


static func _greatsword(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(4, 11), Vector2(12.8, 2), Vector2(14, 2), Vector2(14, 3.2), Vector2(5, 12)], Color("c3c7d0"))
	ci.draw_line(Vector2(5.5, 10.5), Vector2(13, 3), Color(1, 1, 1, 0.5), 0.5)
	ci.draw_line(Vector2(2.6, 9.4), Vector2(7.2, 13.8), OUTLINE, 2.2)
	ci.draw_line(Vector2(2.8, 9.6), Vector2(7.0, 13.6), Color("c9a24e"), 1.4)
	ci.draw_line(Vector2(4.5, 11.5), Vector2(2, 14), Color("4b3627"), 2.0)
	ci.draw_circle(Vector2(1.8, 14.2), 1.1, Color("c9a24e"))


static func _hammer(ci: CanvasItem) -> void:
	ci.draw_line(Vector2(3, 14), Vector2(11, 6), Color("6a4a30"), 1.8)
	_poly(ci, [Vector2(8, 3.5), Vector2(14, 3.5 + 3), Vector2(11.5, 9), Vector2(5.5, 6)], Color("8a8f98"))
	ci.draw_line(Vector2(8.5, 4), Vector2(13.5, 7), Color("c9a24e"), 0.8)


static func _lance(ci: CanvasItem) -> void:
	ci.draw_line(Vector2(2, 14), Vector2(11, 5), Color("6a4a30"), 1.6)
	_poly(ci, [Vector2(10, 3.5), Vector2(14.5, 1.5), Vector2(12.5, 6), Vector2(9.5, 6.5)], Color("c3c7d0"))
	ci.draw_line(Vector2(9.2, 5.0), Vector2(11.8, 7.6), Color("8e1b22"), 1.4)


static func _sabre(ci: CanvasItem) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var f := float(i) / 7.0
		pts.append(Vector2(4.5, 11.5).lerp(Vector2(13.5, 2.5), f) + Vector2(1, 1) * sin(f * PI) * 1.6)
	ci.draw_polyline(pts, Color("9fb7bf"), 1.8)
	ci.draw_line(Vector2(3, 9.5), Vector2(6.5, 13), OUTLINE, 2.0)
	ci.draw_line(Vector2(3.2, 9.7), Vector2(6.3, 12.8), Color("c9a24e"), 1.2)
	ci.draw_line(Vector2(4.8, 11.2), Vector2(2.5, 13.8), Color("4b3627"), 1.8)


static func _scrap(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(2, 10), Vector2(6, 7), Vector2(9, 10), Vector2(8, 14), Vector2(3, 14)], Color("6f7480"))
	_poly(ci, [Vector2(7, 5), Vector2(12, 3), Vector2(14, 7), Vector2(11, 10), Vector2(8, 8)], Color("8a8f98"))
	ci.draw_line(Vector2(3, 12), Vector2(7, 9), Color("b0b4bc"), 0.6)
	ci.draw_line(Vector2(9, 5.5), Vector2(12, 8.5), Color("5a5f68"), 0.6)


static func _resin(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(8, 2), Vector2(12, 8), Vector2(12, 11.5), Vector2(8, 14.5), Vector2(4, 11.5), Vector2(4, 8)], Color("d89a2c"))
	ci.draw_line(Vector2(6, 8), Vector2(7, 12), Color(1, 0.95, 0.7, 0.7), 1.0)
	ci.draw_circle(Vector2(10, 10.5), 0.9, Color(1, 0.85, 0.4))


static func _vial(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(6, 2), Vector2(10, 2), Vector2(10, 5), Vector2(12.5, 10), Vector2(11, 14), Vector2(5, 14), Vector2(3.5, 10), Vector2(6, 5)], Color("5b3b34"))
	_poly(ci, [Vector2(4.6, 9), Vector2(11.4, 9), Vector2(11, 13), Vector2(5, 13)], Color("e0702a"), false)
	ci.draw_rect(Rect2(6, 1, 4, 2), Color("b8a58a"))


# ------------------------------------------------------------------ armour

static func _armor_generic(ci: CanvasItem, id: StringName) -> void:
	var a := Armors.get_armor(StringName(String(id).substr(6)))
	if a == null:
		_unknown(ci)
		return
	match a.look:
		PresetData.ArmorLook.LIGHT: _leathers(ci)
		PresetData.ArmorLook.HEAVY: _plate(ci)
		PresetData.ArmorLook.BARE: _wraps(ci)
		_: _mail(ci)
	# Tint with the armour's own colours so each piece reads differently.
	ci.draw_rect(Rect2(4.5, 3.2, 7, 2.2), Color(a.cloth_light_color, 0.9))
	ci.draw_line(Vector2(5, 13), Vector2(11, 13), a.accent_color, 1.4)
	ci.draw_circle(Vector2(8, 8.5), 1.1, a.accent_color)

static func _torso(ci: CanvasItem, col: Color, shoulders := 0.0) -> void:
	_poly(ci, [Vector2(3 - shoulders, 3), Vector2(6, 2), Vector2(8, 4), Vector2(10, 2), Vector2(13 + shoulders, 3),
		Vector2(12.5, 8), Vector2(11.5, 14), Vector2(4.5, 14), Vector2(3.5, 8)], col)


static func _mail(ci: CanvasItem) -> void:
	_torso(ci, Color("2c2834"))
	for y in range(5, 14, 2):
		ci.draw_line(Vector2(5, y), Vector2(11, y), Color("4a4554"), 0.6)
	ci.draw_line(Vector2(4.5, 4), Vector2(11.5, 13), Color("8e1b22"), 1.6)


static func _leathers(ci: CanvasItem) -> void:
	_torso(ci, Color("5a3d2a"))
	ci.draw_line(Vector2(4.5, 4), Vector2(11.5, 13), Color("c9a24e"), 0.8)
	ci.draw_line(Vector2(11.5, 4), Vector2(4.5, 13), Color("c9a24e"), 0.8)
	ci.draw_rect(Rect2(4.5, 10, 7, 1.2), Color("3a281b"))


static func _plate(ci: CanvasItem) -> void:
	_torso(ci, Color("7d828c"), 1.0)
	ci.draw_circle(Vector2(3.5, 4), 2.2, Color("9aa0aa"))
	ci.draw_circle(Vector2(12.5, 4), 2.2, Color("9aa0aa"))
	ci.draw_line(Vector2(8, 4.5), Vector2(8, 13.5), Color("5a5f68"), 0.8)
	ci.draw_rect(Rect2(7, 5, 2, 7), Color("8e1b22"))
	ci.draw_line(Vector2(5, 7), Vector2(11, 7), Color(1, 1, 1, 0.35), 0.6)


static func _wraps(ci: CanvasItem) -> void:
	var c := Color("d9d0bc")
	for i in 4:
		var y := 3.0 + i * 3.2
		ci.draw_line(Vector2(3, y), Vector2(13, y + 1.2), OUTLINE, 2.0)
		ci.draw_line(Vector2(3, y), Vector2(13, y + 1.2), c, 1.3)
	ci.draw_line(Vector2(12, 4), Vector2(14.5, 1.5), c, 1.0)


# ------------------------------------------------------------------ misc

static func _sigil(ci: CanvasItem, t: float) -> void:
	# The oath sigil (as on the title screen): a ring, a vertical stroke, a crimson bar.
	ci.draw_circle(Vector2(8, 8), 6.8, Color(0.75, 0.6, 0.3, 0.12 + 0.05 * sin(t * 2.0)))
	ci.draw_arc(Vector2(8, 8), 5.5, PI * 0.35, PI * 1.65, 16, Color("c9a24e"), 1.3)
	ci.draw_line(Vector2(8, 2), Vector2(8, 14), Color("e9dfc8"), 1.2)
	ci.draw_line(Vector2(4.5, 6.5), Vector2(11.5, 6.5), Color("8e1b22"), 1.3)
	ci.draw_line(Vector2(5.5, 10), Vector2(10.5, 10), Color("e9dfc8"), 0.9)


static func _unknown(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(3, 3, 10, 10), Color(0.3, 0.3, 0.35))
	ci.draw_string(ThemeDB.fallback_font, Vector2(6, 12), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
