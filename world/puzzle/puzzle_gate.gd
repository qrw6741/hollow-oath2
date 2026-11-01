class_name PuzzleGate
extends StaticBody2D
## An iron portcullis that blocks the way until every switch in [member requires] is on (levers, rune
## sequences). Once opened it stays open (flag gate_open_<id>). Origin = bottom centre.
## TEMPORARY ART: drawn in code.

@export var gate_id: StringName = &"gate"
@export var requires: PackedStringArray = []
@export var size := Vector2(20, 120)
@export var hint := "The gate will not move."

var _open := 0.0          ## 0 closed .. 1 open
var _shape: CollisionShape2D
var _t := 0.0
var _check := 0


func _ready() -> void:
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
	if is_open():
		_open = 1.0
		_shape.disabled = true


func flag() -> StringName:
	return StringName("gate_open_" + String(gate_id))


func is_open() -> bool:
	return bool(GameState.get_flag(flag(), false))


func solved() -> bool:
	for r in requires:
		if not Puzzle.is_on(StringName(r)):
			return false
	return not requires.is_empty()


func _physics_process(delta: float) -> void:
	_t += delta
	_check -= 1
	if not is_open() and _check <= 0:
		_check = 10
		if solved():
			GameState.set_flag(flag(), true)
			Audio.sfx_at(&"door_open", global_position, -2.0, 0.7)
			GameFeel.shake(2.5, 0.8)
			GameFeel.dust(global_position + Vector2(0, -4), 10)
			Events.banner_requested.emit("A gate grinds open")
	var target := 1.0 if is_open() else 0.0
	if not is_equal_approx(_open, target):
		_open = move_toward(_open, target, delta * 0.7)
		queue_redraw()
		if _open > 0.7:
			_shape.set_deferred(&"disabled", true)
	elif target == 0.0:
		queue_redraw()


func _draw() -> void:
	var h := size.y * (1.0 - _open * 0.92)
	var w := size.x
	draw_rect(Rect2(-w / 2.0 - 4, -size.y - 6, 4, size.y + 6), Palette.STONE_DARK)
	draw_rect(Rect2(w / 2.0, -size.y - 6, 4, size.y + 6), Palette.STONE_DARK)
	draw_rect(Rect2(-w / 2.0 - 4, -size.y - 8, w + 8, 4), Palette.STONE_DARK)
	if h < 2.0:
		return
	var y0 := -size.y
	var bars := 4
	for i in bars:
		var x := -w / 2.0 + (i + 0.5) * w / bars
		draw_line(Vector2(x, y0), Vector2(x, y0 + h), Palette.STEEL_OXIDE, 2.4)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, y0 + h), Vector2(x + 2, y0 + h), Vector2(x, y0 + h + 5)]), Palette.STEEL_OXIDE)
	for yy in [0.25, 0.6]:
		draw_line(Vector2(-w / 2.0, y0 + h * yy), Vector2(w / 2.0, y0 + h * yy), Palette.STEEL, 1.6)
	# a faint violet seam when the way is about to open
	if solved():
		draw_rect(Rect2(-w / 2.0, y0, w, h), Color(0.55, 0.3, 0.9, 0.2 + 0.1 * sin(_t * 6.0)))
