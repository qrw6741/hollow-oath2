class_name ItemPickup
extends Area2D
## An item lying in the world. Press interact to take it. Taken pickups stay gone for
## the life of the save (stored as a world flag), even after resting.
## TEMPORARY ART (procedural).

@export var item: ItemData
@export var count := 1
## Unique per pickup across the whole game; used for the saved "already taken" flag.
@export var pickup_id: StringName = &""

var _player_inside: Player
var _t := 0.0


func _ready() -> void:
	if item == null or pickup_id == &"" or GameState.get_flag(_flag(), false):
		queue_free()
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _flag() -> StringName:
	return StringName("pickup_" + String(pickup_id))


func _on_enter(b: Node) -> void:
	if b is Player:
		_player_inside = b
		Events.interact_prompt_shown.emit("Take %s" % item.display_name)


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		take()


func take() -> bool:
	if GameState.add_item(item.id, count) <= 0:
		Events.banner_requested.emit("Cannot carry any more %s" % item.display_name)
		return false
	GameState.set_flag(_flag(), true)
	Events.interact_prompt_hidden.emit()
	Events.banner_requested.emit("%s  x%d" % [item.display_name, count])
	GameFeel.spark(global_position + Vector2(0, -10), item.icon_color, 12)
	queue_free()
	return true


func _draw() -> void:
	var glow := 0.5 + 0.5 * sin(_t * 2.5)
	draw_circle(Vector2(0, -8), 9.0 + glow, Color(item.icon_color, 0.10))
	# A small satchel / bundle.
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-7, -6), Vector2(-3, -11), Vector2(3, -11), Vector2(7, -6), Vector2(6, 0)]), Palette.WOOD)
	draw_line(Vector2(-6, -6), Vector2(6, -6), Palette.WOOD_LIGHT, 1.0)
	draw_circle(Vector2(0, -6), 1.4, item.icon_color)
	draw_rect(Rect2(-1, -12.5, 2, 2), item.icon_color)
