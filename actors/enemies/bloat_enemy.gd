class_name BloatEnemy
extends EnemyBase
## Swollen Pilgrim: a bloated Penitent that bursts when it dies (or when it reaches you).
## The burst is a short telegraphed blast around it: kill it from range, or step away when it swells.

const BLAST_SIZE := Vector2(84, 46)
var _burst_done := false


func on_died() -> void:
	_burst()


func _burst() -> void:
	if _burst_done:
		return
	_burst_done = true
	var z := BossZone.new().setup(BossZone.Kind.BOX, BLAST_SIZE, 0.6, 28.0, Color(0.75, 0.85, 0.3))
	z.status = &"poison"
	z.status_amount = 30.0
	get_parent().add_child(z)
	z.global_position = global_position
	GameFeel.rise(global_position + Vector2(0, -12), Color(0.75, 0.85, 0.3), 10, 14.0)
