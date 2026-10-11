@tool
class_name WaterZone
extends Area2D
## Shallow water: the player wades (slower run, lower jump, shorter roll). Origin = top-left
## of the water surface; [member size] extends right and down. Drawn as a translucent
## surface with a moving shimmer. TEMPORARY ART.

@export var size := Vector2(200, 40):
	set(v): size = v; queue_redraw()
@export var color := Color(0.16, 0.30, 0.32, 0.55)

var _t := 0.0


func _ready() -> void:
	z_index = 3
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
	body_exited.connect(_on_exit)


func _on_enter(b: Node) -> void:
	if b is Player:
		b.in_water += 1
		if b.velocity.y > 120.0:
			Audio.sfx_at(&"splash", b.global_position)


func _on_exit(b: Node) -> void:
	if b is Player:
		b.in_water = maxi(0, b.in_water - 1)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(0, 0, size.x, 1.5), Color(0.55, 0.75, 0.75, 0.55))
	var n := int(size.x / 24.0)
	for i in n:
		var x := i * 24.0 + fmod(_t * 9.0 + i * 7.0, 24.0)
		if x < size.x - 6:
			draw_line(Vector2(x, 3 + sin(_t * 2.0 + i) * 1.0), Vector2(x + 6, 3 + sin(_t * 2.0 + i) * 1.0), Color(0.7, 0.85, 0.85, 0.35), 1.0)
