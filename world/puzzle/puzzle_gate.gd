class_name PuzzleGate
extends StaticBody2D
## A castle portcullis that bars the way until every switch in [member requires] is on (levers, rune
## sequences). One ward-gem on the lintel per switch shows which are lit. Once opened it stays open
## (flag gate_open_<id>). Origin = bottom centre; the doorway fills the hall from floor to ceiling.
## TEMPORARY ART: drawn in code.

@export var gate_id: StringName = &"gate"
## Comma-separated switch ids (a plain String on purpose: a PackedStringArray export came through EMPTY in the
## exported Windows build, so no gate could ever open).
@export var requires_list := ""
var requires: PackedStringArray = []
@export var size := Vector2(44, 384)
@export var hint := "The gate will not move."

const OPENING := 150.0   ## height of the doorway under the arch (the camera only shows ~270 px above the floor)

var _open := 0.0          ## 0 closed .. 1 open
var _shape: CollisionShape2D
var _t := 0.0
var _check := 0
var _light: PointLight2D
var _rumble := 0.0


func _ready() -> void:
	requires = PackedStringArray()
	for r in requires_list.split(",", false):
		requires.append(r.strip_edges())
	add_to_group(&"puzzle_gates")
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	_shape.shape = r
	_shape.position = Vector2(0, -size.y / 2.0)
	add_child(_shape)
	z_index = 3
	_light = PointLight2D.new()
	_light.texture = LightTex.radial()
	_light.texture_scale = 1.6
	_light.color = Color(0.6, 0.35, 1.0)
	_light.energy = 0.0
	_light.position = Vector2(0, -OPENING - 30.0)
	add_child(_light)
	if is_open():
		_open = 1.0
		_shape.disabled = true


func flag() -> StringName:
	return StringName("gate_open_" + String(gate_id))


func is_open() -> bool:
	return bool(GameState.get_flag(flag(), false))


func lit_count() -> int:
	var n := 0
	for r in requires:
		if Puzzle.is_on(StringName(r)):
			n += 1
	return n


func solved() -> bool:
	return not requires.is_empty() and lit_count() == requires.size()


func open_now() -> void:
	if is_open():
		return
	GameState.set_flag(flag(), true)
	Audio.sfx_at(&"door_open", global_position, -2.0, 0.7)
	GameFeel.shake(3.0, 0.9)
	GameFeel.dust(global_position + Vector2(0, -OPENING), 14)
	Events.banner_requested.emit("THE GATE GRINDS OPEN")


func _physics_process(delta: float) -> void:
	_t += delta
	_check -= 1
	if not is_open() and _check <= 0:
		_check = 3
		if solved():
			open_now()
	var target := 1.0 if is_open() else 0.0
	if not is_equal_approx(_open, target):
		_open = move_toward(_open, target, delta * 0.4)   # a slow, heavy rise (2.5 s)
		if target > _open and _open > 0.0:
			_rumble -= delta
			if _rumble <= 0.0:
				_rumble = 0.3
				GameFeel.shake(2.2, 0.3)
				GameFeel.dust(global_position + Vector2(randf_range(-18.0, 18.0), -6.0), 5)
				GameFeel.spark(global_position + Vector2(randf_range(-14.0, 14.0), -OPENING * _open - 10.0), Color(0.7, 0.5, 1.0), 4)
		if _open > 0.7:
			_shape.set_deferred(&"disabled", true)
	_light.energy = 0.55 * (0.5 + 0.5 * sin(_t * 5.0)) * (1.0 - _open) if solved() and not is_open() else 0.0
	if Near.player(self): queue_redraw()


func _draw() -> void:
	var w := size.x
	var top := -size.y
	var op := -OPENING
	var stone := Color("4a3c44")
	var dark := Color("241a28")
	var lite := Color("6a5a66")
	# --- the stone frame: buttresses, a pointed arch, a keystone
	for sx in [-1.0, 1.0]:
		var x0: float = (-w / 2.0 - 18.0) if sx < 0.0 else (w / 2.0)
		draw_rect(Rect2(x0, top, 18.0, size.y), stone)
		draw_rect(Rect2(x0, top, 4.0, size.y), lite)
		draw_rect(Rect2(x0 - 5.0 if sx < 0.0 else x0 - 1.0, op - 6.0, 24.0, 8.0), lite)
		draw_rect(Rect2(x0 - 5.0 if sx < 0.0 else x0 - 1.0, -14.0, 24.0, 14.0), lite)
		for k in 11:
			draw_line(Vector2(x0, -24.0 - k * 36.0), Vector2(x0 + 18.0, -24.0 - k * 36.0), dark, 1.0)
	# pointed arch infill above the doorway
	draw_rect(Rect2(-w / 2.0 - 18.0, top, w + 36.0, size.y - OPENING), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, op), Vector2(-w / 2.0, op - 20.0), Vector2(0, op - 52.0), Vector2(w / 2.0, op - 20.0), Vector2(w / 2.0, op)]), dark)
	draw_line(Vector2(-w / 2.0, op - 20.0), Vector2(0, op - 52.0), lite, 2.0)
	draw_line(Vector2(w / 2.0, op - 20.0), Vector2(0, op - 52.0), lite, 2.0)
	for k in 8:
		draw_line(Vector2(-w / 2.0 - 18.0, op - 64.0 - k * 22.0), Vector2(w / 2.0 + 18.0, op - 64.0 - k * 22.0), dark, 1.0)
	var gem_on := solved()
	# ward gems: one per switch, set in the stone above the arch
	var n := requires.size()
	for i in n:
		var gx := (float(i) - (n - 1) / 2.0) * 18.0
		var gp := Vector2(gx, op - 80.0)
		var on := Puzzle.is_on(StringName(requires[i]))
		var pts := PackedVector2Array([gp + Vector2(0, -8), gp + Vector2(6, 0), gp + Vector2(0, 8), gp + Vector2(-6, 0), gp + Vector2(0, -8)])
		draw_colored_polygon(pts, Color(0.65, 0.4, 1.0) if on else Color(0.34, 0.08, 0.1))
		draw_polyline(pts, lite, 1.2)
		if on:
			draw_circle(gp, 13.0 + 2.0 * sin(_t * 4.0 + i), Color(0.6, 0.35, 1.0, 0.18))
	if not is_open() and n > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-16, op + 16.0), "%d / %d" % [lit_count(), n], HORIZONTAL_ALIGNMENT_CENTER, 32.0, 11, Color(0.85, 0.75, 0.95, 0.85))
	# wall sconces on the buttresses
	for sx in [-1.0, 1.0]:
		var tx: float = sx * (w / 2.0 + 9.0)
		var ty := -96.0
		draw_rect(Rect2(tx - 5.0, ty, 10.0, 5.0), Color("56463a"))
		var fl := 0.7 + 0.3 * sin(_t * 9.0 + sx)
		draw_colored_polygon(PackedVector2Array([Vector2(tx - 4.0, ty), Vector2(tx, ty - 17.0 * fl), Vector2(tx + 4.0, ty)]), Color(1.0, 0.55, 0.15, 0.92))
		draw_circle(Vector2(tx, ty - 8.0), 26.0, Color(1.0, 0.55, 0.2, 0.06 * fl))
	# --- the portcullis: iron bars that rise into the arch
	var lift := OPENING * _open
	var ptop := op - lift
	var pbot := ptop + OPENING
	var vis_top := maxf(ptop, op)
	if pbot - vis_top > 1.0:
		var bars := 7
		for i in bars:
			var x := -w / 2.0 + (i + 0.5) * w / bars
			draw_line(Vector2(x, vis_top), Vector2(x, pbot), Palette.STEEL_OXIDE, 2.6)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 2.4, pbot), Vector2(x + 2.4, pbot), Vector2(x, pbot + 7.0)]), Palette.STEEL_OXIDE)
		for fr in [0.12, 0.34, 0.56, 0.78]:
			var yy: float = ptop + OPENING * fr
			if yy >= op:
				draw_line(Vector2(-w / 2.0, yy), Vector2(w / 2.0, yy), Palette.STEEL, 2.0)
				for i in bars:
					draw_circle(Vector2(-w / 2.0 + (i + 0.5) * w / bars, yy), 1.6, Palette.STEEL.lightened(0.2))
		if gem_on:
			draw_rect(Rect2(-w / 2.0, vis_top, w, pbot - vis_top), Color(0.55, 0.3, 0.9, 0.16 + 0.08 * sin(_t * 6.0)))
		# chains to the winch
		draw_line(Vector2(-w / 2.0 + 4.0, vis_top), Vector2(-w / 2.0 + 4.0, op - 30.0), Color("5a5660"), 1.5)
		draw_line(Vector2(w / 2.0 - 4.0, vis_top), Vector2(w / 2.0 - 4.0, op - 30.0), Color("5a5660"), 1.5)
