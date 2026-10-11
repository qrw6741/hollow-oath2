class_name Glyph
extends Control
## One button prompt, drawn with vector primitives (crisp at any resolution, no image
## files): PlayStation face buttons / L1 / R1 / Options / D-pad, Xbox-style letters,
## or a keycap for keyboard. Follows InputPrompts.device automatically.
##
## Set [member action] to show whatever that action is bound to, or [member pad_id] /
## [member key_text] for a fixed token (menu navigation hints).

@export var action: StringName = &""
@export var pad_id := ""
@export var key_text := ""

const SIZE := 12.0
const C_FACE := Color(0.10, 0.10, 0.14)
const C_RING := Color(0.62, 0.62, 0.68)
const C_CROSS := Color(0.45, 0.65, 0.98)
const C_CIRCLE := Color(0.96, 0.42, 0.46)
const C_SQUARE := Color(0.96, 0.58, 0.82)
const C_TRI := Color(0.36, 0.86, 0.62)

var _id := ""
var _pad := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	InputPrompts.device_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if action != &"":
		var t := InputPrompts.token_for(action)
		_pad = t.pad
		_id = t.id
	else:
		_pad = InputPrompts.is_pad()
		_id = pad_id if _pad else key_text
		if not _pad and _id == "":
			_id = "?"
	custom_minimum_size = _wanted_size()
	size = custom_minimum_size
	visible = _id != ""
	queue_redraw()


func _wide() -> bool:
	return not _pad or _id in ["l1", "r1", "options", "create"]


func _wanted_size() -> Vector2:
	if not _pad:
		var w := ThemeDB.fallback_font.get_string_size(_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		return Vector2(maxf(SIZE, w + 6.0), SIZE)
	if _id in ["l1", "r1"]:
		return Vector2(17, SIZE)
	if _id in ["options", "create"]:
		return Vector2(15, 9)
	return Vector2(SIZE, SIZE)


func _draw() -> void:
	var s := size
	var c := s / 2.0
	if not _pad:
		_keycap(s)
		return
	var ps := InputPrompts.device == InputPrompts.Device.PLAYSTATION
	match _id:
		"cross", "circle", "square", "triangle":
			draw_circle(c, 5.6, C_FACE)
			draw_arc(c, 5.6, 0, TAU, 20, C_RING, 0.8)
			if ps:
				_ps_symbol(_id, c)
			else:
				_xbox_letter(_id, c)
		"l1", "r1":
			_pill(s)
			_text(("L1" if _id == "l1" else "R1") if ps else ("LB" if _id == "l1" else "RB"), s)
		"options", "create":
			_pill(s)
			if _id == "options" and ps:
				for i in 3:
					draw_line(Vector2(5, 2.6 + i * 1.8), Vector2(10, 2.6 + i * 1.8), Color.WHITE, 0.8)
			else:
				_text("≡" if _id == "options" else "···", s)
		"dpad_up", "dpad_down", "dpad_left", "dpad_right", "dpad":
			_dpad(c, _id)
		"r3", "l3":
			draw_circle(c, 5.6, C_FACE)
			draw_arc(c, 5.6, 0, TAU, 20, C_RING, 0.8)
			_text(_id.to_upper(), s)
		"stick_l":
			draw_circle(c, 5.6, C_FACE)
			draw_arc(c, 5.6, 0, TAU, 20, C_RING, 0.8)
			draw_circle(c, 2.6, C_RING)
		_:
			_keycap(s)


func _ps_symbol(id: String, c: Vector2) -> void:
	match id:
		"cross":
			draw_line(c + Vector2(-2.4, -2.4), c + Vector2(2.4, 2.4), C_CROSS, 1.3)
			draw_line(c + Vector2(-2.4, 2.4), c + Vector2(2.4, -2.4), C_CROSS, 1.3)
		"circle":
			draw_arc(c, 2.6, 0, TAU, 16, C_CIRCLE, 1.2)
		"square":
			draw_rect(Rect2(c - Vector2(2.5, 2.5), Vector2(5, 5)), C_SQUARE, false, 1.2)
		"triangle":
			var p := PackedVector2Array([c + Vector2(0, -3), c + Vector2(2.9, 2.2), c + Vector2(-2.9, 2.2), c + Vector2(0, -3)])
			draw_polyline(p, C_TRI, 1.2)


func _xbox_letter(id: String, c: Vector2) -> void:
	var letter: String = {"cross": "A", "circle": "B", "square": "X", "triangle": "Y"}[id]
	var col: Color = {"cross": Color(0.5, 0.85, 0.4), "circle": C_CIRCLE, "square": C_CROSS, "triangle": Color(0.98, 0.84, 0.35)}[id]
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(f, Vector2(c.x - w / 2.0, c.y + 3.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


func _pill(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, s), C_FACE)
	draw_rect(Rect2(Vector2.ZERO, s), C_RING, false, 0.8)


func _text(t: String, s: Vector2) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(f, Vector2((s.x - w) / 2.0, s.y / 2.0 + 2.6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)


func _keycap(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.16, 0.15, 0.19))
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.55, 0.52, 0.58), false, 0.8)
	_text(_id, s)


func _dpad(c: Vector2, id: String) -> void:
	var arm := Color(0.85, 0.85, 0.9)
	var dim := C_RING
	var arms := {"up": Vector2(0, -3.4), "down": Vector2(0, 3.4), "left": Vector2(-3.4, 0), "right": Vector2(3.4, 0)}
	for k in arms:
		var hot: bool = id == "dpad" or id == "dpad_" + k
		var r := Rect2(c + arms[k] - Vector2(1.5, 1.5), Vector2(3, 3))
		draw_rect(r, arm if hot else dim)
	draw_rect(Rect2(c - Vector2(1.5, 1.5), Vector2(3, 3)), dim)
