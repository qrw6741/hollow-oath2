class_name RangedEnemy
extends EnemyBase
## Keeps its distance and attacks from range (attacks whose AttackData fires a
## projectile). Backs away when the player closes in, and falls back on its melee
## attacks (those without a projectile) when cornered.

## Preferred distance band to the target.
@export var keep_min := 80.0
@export var keep_max := 200.0
@export var retreat_speed_mult := 0.9


func _state_chase(delta: float) -> void:
	if target == null:
		_set_state(State.RETURN)
		return
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 4.0:
		facing = 1 if dx > 0.0 else -1
	var dist := absf(dx)
	if _cooldown <= 0:
		var a := choose_attack(dist)
		if a:
			_start_attack(a)
			return
	var desired := 0.0
	if dist < keep_min:
		desired = -facing * data.chase_speed * retreat_speed_mult
		if _ledge_behind() or _wall_behind():
			desired = 0.0
	elif dist > keep_max:
		desired = facing * data.chase_speed
		if _ledge_ahead():
			desired = 0.0
	velocity.x = move_toward(velocity.x, desired, 700.0 * delta)


func _wall_behind() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0, -10)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(-facing * 14.0, 0), 1)
	return not space.intersect_ray(q).is_empty()
