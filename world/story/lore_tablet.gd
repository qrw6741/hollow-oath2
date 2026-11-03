@tool
class_name LoreTablet
extends Area2D
## A standing stone with an inscription. Interact to read it (a panel on the HUD); walking
## away or interacting again closes it. TEMPORARY ART.

@export var title := "An inscription"
@export_multiline var text := ""

var _player_inside: Player
var _reading := false
var _t := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 30)
	cs.shape = r
	cs.position = Vector2(0, -15)
	add_child(cs)
	body_entered.connect(func(b): if b is Player: _player_inside = b; Events.interact_prompt_shown.emit("Read"))
	body_exited.connect(func(b): if b == _player_inside: _player_inside = null; Events.interact_prompt_hidden.emit(); _close())


func _physics_process(delta: float) -> void:
	_t += delta
	if Near.player(self): queue_redraw()
	if Engine.is_editor_hint() or _player_inside == null:
		return
	if Input.is_action_just_pressed(&"interact") and (_reading or _player_inside.can_interact()):
		if _reading:
			_close()
		else:
			_reading = true
			Events.interact_prompt_hidden.emit()
			Events.message_requested.emit(title, text)
			Audio.sfx(&"pickup", -6.0)


func _close() -> void:
	if _reading:
		_reading = false
		Events.message_closed.emit()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(-7, -22), Vector2(-3, -27), Vector2(3, -27), Vector2(7, -22), Vector2(8, 0)]), Color("8a857a"))
	draw_line(Vector2(-7, -22), Vector2(7, -22), Color("6d695f"), 1.0)
	for i in 4:
		draw_line(Vector2(-4, -18 + i * 4), Vector2(4 - (i % 2) * 2, -18 + i * 4), Color(0.95, 0.85, 0.5, 0.5 + 0.3 * sin(_t * 2.0 + i)), 1.0)
