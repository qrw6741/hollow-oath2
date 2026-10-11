class_name Hitbox
extends Area2D
## Attack volume. Always monitoring so overlap data is current; it only deals
## damage while an AttackRunner is in its active phase.

var shape: RectangleShape2D
var _collision: CollisionShape2D


func _ready() -> void:
	monitorable = false
	monitoring = true
	_collision = get_node_or_null(^"Shape") as CollisionShape2D
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = &"Shape"
		add_child(_collision)
	if not (_collision.shape is RectangleShape2D):
		_collision.shape = RectangleShape2D.new()
	shape = _collision.shape as RectangleShape2D


func configure(size: Vector2, offset: Vector2) -> void:
	shape.size = size
	_collision.position = offset


func hurtboxes() -> Array[Hurtbox]:
	var out: Array[Hurtbox] = []
	for a in get_overlapping_areas():
		if a is Hurtbox and (a as Hurtbox).enabled:
			out.append(a)
	return out
