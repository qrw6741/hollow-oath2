class_name Hurtbox
extends Area2D
## Receives hits and forwards them to [member receiver], which must implement
## `receive_hit(hit: HitData) -> int` (returning a HitData.Result).

## Defaults to the parent node.
@export var receiver: Node
var enabled := true:
	set(value):
		enabled = value
		set_deferred(&"monitorable", value)


func _ready() -> void:
	monitoring = false
	monitorable = true
	if receiver == null:
		receiver = get_parent()


func receive_hit(hit: HitData) -> int:
	if not enabled or receiver == null or not receiver.has_method(&"receive_hit"):
		return HitData.Result.IGNORED
	return receiver.receive_hit(hit)
