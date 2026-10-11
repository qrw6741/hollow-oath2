@tool
class_name ShortcutGate
extends StaticBody2D
## Iron portcullis that blocks a passage until it is raised from its open side
## (a lever beside it). Once opened it stays open for the life of the save.
## Origin = bottom centre of the gate.

@export var gate_id: StringName = &"gate"
@export var height := 80.0:
	set(v): height = v; queue_redraw()
## Which side the lever is on: 1 = right, -1 = left. Interacting from the other side
## only gives the "opened from the other side" message.
@export_enum("Left:-1", "Right:1") var lever_side := 1

var is_open := false
var _shape: CollisionShape2D
var _area: Area2D
var _player_inside: Player
var _lift := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, height)
	_shape.shape = r
	_shape.position = Vector2(0, -height / 2.0)
	add_child(_shape)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(70, height)
	cs.shape = ar
	cs.position = Vector2(0, -height / 2.0)
	_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(func(b): if b is Player: _player_inside = b; _prompt())
	_area.body_exited.connect(func(b): if b == _player_inside: _player_inside = null; Events.interact_prompt_hidden.emit())
	is_open = GameState.get_flag(_flag(), false)
	_lift = 1.0 if is_open else 0.0
	_shape.disabled = is_open


func _flag() -> StringName:
	return StringName("gate_open_" + String(gate_id))


func _prompt() -> void:
	if is_open or _player_inside == null:
		return
	var on_lever_side := signf(_player_inside.global_position.x - global_position.x) == float(lever_side)
	Events.interact_prompt_shown.emit("Raise the gate" if on_lever_side else "Examine the gate")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_open and _lift < 1.0:
		_lift = minf(1.0, _lift + delta * 0.8)
		queue_redraw()
	if is_open or _player_inside == null:
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		interact(_player_inside)


## Returns true if the gate opened.
func interact(p: Player) -> bool:
	if is_open:
		return false
	if signf(p.global_position.x - global_position.x) != float(lever_side):
		Audio.sfx(&"door_locked")
		Events.banner_requested.emit("It opens from the other side")
		return false
	is_open = true
	GameState.set_flag(_flag(), true)
	_shape.set_deferred(&"disabled", true)
	Events.interact_prompt_hidden.emit()
	Events.banner_requested.emit("A SHORTCUT OPENS")
	Audio.sfx_at(&"gate_open", global_position)
	GameFeel.shake(3.0, 0.4)
	SaveSystem.autosave()
	return true


func _draw() -> void:
	var y0 := -height * (1.0 - _lift * 0.92)
	# Bars: they rise into the ceiling as the gate opens.
	var bottom := -height * _lift * 0.92
	for i in 4:
		var x := -4.5 + i * 3.0
		draw_line(Vector2(x, -height), Vector2(x, bottom), Palette.STEEL_OXIDE, 1.5)
	for k in 3:
		var y := -height + (k + 1) * height / 4.0
		if y <= bottom:
			draw_line(Vector2(-6, y), Vector2(6, y), Palette.STEEL, 1.5)
	# Lever on its side
	var lx := lever_side * 16.0
	draw_rect(Rect2(lx - 2, -14, 4, 14), Palette.STONE)
	var ang := deg_to_rad(-60.0 if is_open else 60.0) * lever_side
	draw_line(Vector2(lx, -12), Vector2(lx, -12) + Vector2.from_angle(-PI / 2.0 + ang) * 10.0, Palette.WOOD_LIGHT, 2.0)
