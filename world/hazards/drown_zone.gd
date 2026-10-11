@tool
class_name DrownZone
extends Area2D
## Deep water / a bottomless flooded shaft: falling in is death (it ignores i-frames).
## Origin = top-left; [member size] extends right and down. TEMPORARY ART.

@export var size := Vector2(64, 200):
	set(v): size = v; queue_redraw()


func _ready() -> void:
	add_to_group(&"hazards")
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = size / 2.0
	add_child(cs)
	body_entered.connect(_on_enter)


func _on_enter(b: Node) -> void:
	if b is Player and not b.is_dead():
		Audio.sfx_at(&"splash", b.global_position, 2.0)
		b.health.take_damage(b.health.current + 1.0)


func _draw() -> void:
	for i in 12:
		var y := size.y * i / 12.0
		draw_rect(Rect2(0, y, size.x, size.y / 12.0 + 1), Color(0.05, 0.10, 0.12, 0.55 + 0.4 * i / 12.0))
