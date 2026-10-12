class_name SummonerEnemy
extends RangedEnemy
## Keeps its distance, flings bolts, and calls up to [member max_minions] minions with an
## attack whose animation is &"summon" (it fires its "projectile" event once on the first
## active frame, which this class turns into the summons). When it dies its minions go cold.

@export var minion_scene: PackedScene
@export var max_minions := 2

var _minions: Array = []


func alive_minions() -> int:
	_minions = _minions.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion() and not m.is_dead())
	return _minions.size()


func choose_attack(distance: float) -> AttackData:
	var a := super(distance)
	if a and a.animation == &"summon" and alive_minions() >= max_minions:
		# Already has its fill: throw a bolt instead.
		for o in data.attacks:
			if o.animation != &"summon" and distance >= o.ai_min_range and distance <= o.ai_max_range:
				return o
		return null
	return a


func _fire_projectile(a: AttackData) -> void:
	if a.animation == &"summon":
		summon()
	else:
		super(a)


func summon() -> void:
	if minion_scene == null:
		return
	Audio.sfx_at(&"boss_roar", global_position, -10.0, 1.6)
	GameFeel.shake(1.5, 0.2)
	var need := max_minions - alive_minions()
	for i in need:
		var m := minion_scene.instantiate() as EnemyBase
		m.data = m.data.duplicate()
		m.data.ember_reward = 0
		m.data.drop_chance = 0.0
		m.data.bonus_drop_chance = 0.0
		m.patrol_distance = 0.0
		m.position = position + Vector2((-1 if i == 0 else 1) * 34.0, -52.0)
		m.start_facing = facing
		get_parent().add_child.call_deferred(m)
		_minions.append(m)
		_wake.call_deferred(m)
		GameFeel.spark.call_deferred(m.position, Palette.EMBER, 12)


func _wake(m: EnemyBase) -> void:
	if is_instance_valid(m) and target:
		m.target = target
		m.state = EnemyBase.State.CHASE


func on_died() -> void:
	for m in _minions:
		if is_instance_valid(m) and not m.is_dead():
			m.health.take_damage(99999.0)
