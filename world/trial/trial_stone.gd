@tool
class_name TrialStone
extends Area2D
## A carved stone in the Trial Ring: walk up, press Interact to begin that challenge.
## Shows your record beneath its name. Origin = feet. TEMPORARY ART.

@export_enum("rush", "gauntlet") var trial := "rush"
@export var runner_path := NodePath("../TrialRunner")

var _player_inside: Player
var _t := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 40)
	cs.shape = r
	cs.position = Vector2(0, -20)
	add_child(cs)
	body_entered.connect(func(b): if b is Player: _player_inside = b; Events.interact_prompt_shown.emit(_prompt()))
	body_exited.connect(func(b): if b == _player_inside: _player_inside = null; Events.interact_prompt_hidden.emit())


func _prompt() -> String:
	if trial == "rush":
		var b := Trials.best_rush()
		return "Begin the Boss Rush" + ("  (best %s)" % Trials.fmt_time(b) if b > 0.0 else "")
	var g := Trials.best_gauntlet()
	return "Begin the Gauntlet" + ("  (best wave %d)" % g if g > 0 else "")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if Engine.is_editor_hint() or _player_inside == null:
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		var rn := get_node_or_null(runner_path) as TrialRunner
		if rn and not rn.running:
			Events.interact_prompt_hidden.emit()
			rn.start(&"rush" if trial == "rush" else &"gauntlet")


func _draw() -> void:
	var col := Palette.CRIMSON_BRIGHT if trial == "rush" else Palette.GOLD
	draw_rect(Rect2(-9, -30, 18, 30), Palette.STONE_DARK)
	draw_rect(Rect2(-9, -30, 18, 3), Palette.STONE_LIGHT)
	var k := 0.6 + 0.4 * sin(_t * 3.0)
	if trial == "rush":
		draw_line(Vector2(-4, -20), Vector2(4, -10), Color(col, k), 1.4)
		draw_line(Vector2(4, -20), Vector2(-4, -10), Color(col, k), 1.4)
	else:
		for i in 3:
			draw_line(Vector2(-5 + i * 5, -10), Vector2(-5 + i * 5, -22 + i * 2), Color(col, k), 1.4)
