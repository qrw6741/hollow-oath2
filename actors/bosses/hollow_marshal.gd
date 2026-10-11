class_name HollowMarshal
extends BossBase
## Third boss: Sir Orren, the Hollow Marshal, an armoured lancer holding the crossroads.
##   Lance Thrust — long reach lunge, parryable (glint on the tip).
##   Lance Sweep  — wide arc, parryable.
##   Couched Charge — unparryable rush across the arena. Dodge through or jump it.
## Phase 2 adds:
##   Pole Vault   — leaps over and lands with the lance, unparryable.
##   Raise the Banner — the tattered banner lifts and two Carrion Crows are called
##                      (never more than two at once; they give no embers). A free opening
##                      for the player while the banner is raised.

@export var crow_scene: PackedScene
const MAX_CROWS := 2

var _crows: Array = []


func alive_crows() -> int:
	_crows = _crows.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion() and not c.is_dead())
	return _crows.size()


func choose_attack(distance: float) -> AttackData:
	var a := super(distance)
	if a and a.animation == &"banner" and alive_crows() >= MAX_CROWS:
		return null
	return a


func _fire_projectile(a: AttackData) -> void:
	if a.animation == &"banner":
		call_crows()
	else:
		super(a)


func call_crows() -> void:
	if crow_scene == null:
		return
	Audio.sfx_at(&"caw", global_position, 0.0, 0.8)
	Audio.sfx_at(&"boss_roar", global_position, -8.0, 1.5)
	GameFeel.shake(3.0, 0.25)
	var need := MAX_CROWS - alive_crows()
	for i in need:
		var c := crow_scene.instantiate() as EnemyBase
		c.data = c.data.duplicate()
		c.data.ember_reward = 0
		c.data.drop_chance = 0.0
		c.patrol_distance = 0.0
		c.position = position + Vector2((-1 if i == 0 else 1) * 60.0, -110.0)
		c.start_facing = facing
		get_parent().add_child.call_deferred(c)
		_crows.append(c)
		_wake_crow.call_deferred(c)


func _wake_crow(c: EnemyBase) -> void:
	if is_instance_valid(c) and target:
		c.target = target
		c._set_state(EnemyBase.State.CHASE)


func _on_died() -> void:
	super()
	for c in _crows:
		if is_instance_valid(c) and not c.is_dead():
			c.health.take_damage(99999.0)
	_crows.clear()


func on_phase_changed(_p: int) -> void:
	Audio.sfx_at(&"caw", global_position, 0.0, 0.7)


func play_attack_sound(a: AttackData) -> void:
	match a.animation:
		&"thrust", &"sweep":
			Audio.sfx_at(&"swing_heavy", global_position, -2.0, 0.9 if a.animation == &"thrust" else 0.7)
		&"banner":
			Audio.sfx_at(&"caw", global_position, -2.0, 0.9)
		_:
			super(a)
