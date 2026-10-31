class_name MenderEnemy
extends RangedEnemy
## Wick-Mender: stays back and relights wounded allies (heals the weakest ally nearby every few
## seconds). Kill it first.

const HEAL_EVERY := 4.5
const HEAL_RANGE := 220.0
const HEAL_FRACTION := 0.3
var _heal_t := 2.0
var heals_done := 0


func _physics_process(delta: float) -> void:
	super(delta)
	if is_dead():
		return
	_heal_t -= delta
	if _heal_t > 0.0:
		return
	_heal_t = HEAL_EVERY
	var best: EnemyBase = null
	var worst := 0.9
	for e in get_tree().get_nodes_in_group(&"enemies"):
		var o := e as EnemyBase
		if o == null or o == self or o.is_dead() or o is BossBase:
			continue
		if o.global_position.distance_to(global_position) > HEAL_RANGE:
			continue
		var frac := o.health.current / o.health.max_health
		if frac < worst:
			worst = frac
			best = o
	if best:
		best.health.heal(best.health.max_health * HEAL_FRACTION)
		heals_done += 1
		GameFeel.rise(best.global_position + Vector2(0, -8), Color(0.55, 1.0, 0.65), 8, 8.0)
		GameFeel.ring(best.global_position + Vector2(0, -16), Color(0.55, 1.0, 0.65), 20.0)
		Audio.sfx_at(&"heal", best.global_position, -8.0, 1.3)
