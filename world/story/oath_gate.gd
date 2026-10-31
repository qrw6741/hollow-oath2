@tool
class_name OathGate
extends Area2D
## The gate at the end of the Vaelmoor Road. Sealed until the Marshal falls, then it asks the
## Oathbound to choose an ending (see Endings / EndingMenu). TEMPORARY ART (procedural).

var _player_inside: Player
var _t := 0.0
var _confirm := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(60, 70)
	cs.shape = r
	cs.position = Vector2(0, -35)
	add_child(cs)
	body_entered.connect(func(b): if b is Player: _player_inside = b; Events.interact_prompt_shown.emit(_prompt()))
	body_exited.connect(func(b): if b == _player_inside: _player_inside = null; Events.interact_prompt_hidden.emit())


func _prompt() -> String:
	if not Endings.enabled:
		return "The gate (the road goes on)" if bool(GameState.get_flag(Endings.MARSHAL_FLAG, false)) else "The gate is sealed"
	if Endings.gate_open():
		return "Face the gate"
	if Endings.chosen() != &"":
		return "Begin anew (New Game+)" if Progress.next_goal().is_empty() else "The gate (your road is not finished)"
	return "Face the gate" if Endings.gate_open() else "The gate is sealed"


func _physics_process(delta: float) -> void:
	_t += delta
	_confirm = maxf(0.0, _confirm - delta)
	queue_redraw()
	if Engine.is_editor_hint() or _player_inside == null:
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact() and not Endings.enabled:
		if bool(GameState.get_flag(Endings.MARSHAL_FLAG, false)):
			Events.banner_requested.emit("THE ROAD GOES ON.  " + Progress.text())
		else:
			Audio.sfx(&"door_locked")
			Events.banner_requested.emit("THE GATE IS SEALED  -  ORREN STILL HOLDS THE ROAD")
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		if Endings.chosen() != &"" and not Endings.gate_open():
			if _confirm > 0.0:
				_confirm = 0.0
				Events.new_cycle_requested.emit()
			else:
				_confirm = 5.0
				if Progress.next_goal().is_empty():
					Events.banner_requested.emit("INTERACT AGAIN TO BEGIN ANEW  -  NEW GAME+ (CYCLE %d)" % (GameState.ng_cycle() + 1))
				else:
					Events.banner_requested.emit("THE ROAD GOES ON.  " + Progress.text() + "  (Interact again to start New Game+ instead.)")
		elif Endings.gate_open():
			Events.ending_requested.emit()
		else:
			Audio.sfx(&"door_locked")
			Events.banner_requested.emit("THE GATE IS SEALED  -  ORREN STILL HOLDS THE ROAD")


func open_state() -> bool:
	return (Endings.gate_open() or (not Endings.enabled and bool(GameState.get_flag(Endings.MARSHAL_FLAG, false)))) if not Engine.is_editor_hint() else false


func _draw() -> void:
	var lit := open_state()
	var stone := Color("5d5a62")
	draw_rect(Rect2(-30, -64, 10, 64), stone)
	draw_rect(Rect2(20, -64, 10, 64), stone)
	draw_rect(Rect2(-32, -72, 64, 10), stone.darkened(0.15))
	for i in 5:
		var a := 0.15 + (0.12 + 0.08 * sin(_t * 2.0 + i)) * (1.0 if lit else 0.3)
		draw_rect(Rect2(-20 + i * 8, -62, 6, 62), Color(0.95, 0.85, 0.5, a) if lit else Color(0.4, 0.4, 0.5, a))
