class_name ShieldEnemy
extends EnemyBase
## Shield-bearer (Oathguard). Hits from the front are blocked by its tower shield while
## it is not mid-swing: no damage, your blade bounces back, and its GUARD drops
## (heavy attacks drain far more guard than light ones). Guard at zero = GUARD BREAK:
## it reels, open to a riposte, exactly like a parry. Guard refills if you stop hitting.
## It turns slowly, so rolling behind it works; hits from behind or during its own
## attacks land normally.

@export var max_guard := 70.0
@export var guard_regen_per_second := 16.0
@export var guard_regen_delay_frames := 75
## Frames before it turns to face a target that got behind it.
@export var turn_delay := 22

var guard := 0.0
## Frames of "shield struck" flash for the visual.
var shield_flash := 0
var guard_breaks := 0
var _guard_wait := 0
var _turn_wait := 0


func _ready() -> void:
	super()
	guard = max_guard


func _physics_process(delta: float) -> void:
	if shield_flash > 0:
		shield_flash -= 1
	if _guard_wait > 0:
		_guard_wait -= 1
	elif guard < max_guard:
		guard = minf(max_guard, guard + guard_regen_per_second * delta)
	super(delta)


func is_guarding() -> bool:
	match state:
		State.IDLE, State.PATROL, State.CHASE, State.RETURN, State.RECOVER:
			return true
		State.ATTACK:
			return attack_runner.phase == AttackRunner.Phase.STARTUP
	return false


func guard_ratio() -> float:
	return clampf(guard / max_guard, 0.0, 1.0)


func receive_hit(hit: HitData) -> int:
	if state == State.DEAD:
		return HitData.Result.IGNORED
	if hit.source and not hit.environmental and not hit.critical and is_guarding():
		var dx := hit.source.global_position.x - global_position.x
		if signf(dx) == float(facing) or absf(dx) < 3.0:
			return _block(hit)
	return super(hit)


func _block(hit: HitData) -> int:
	guard -= hit.poise_damage * 0.8 + hit.damage * 0.6
	_guard_wait = guard_regen_delay_frames
	shield_flash = 6
	var at := global_position + Vector2(facing * 10.0, -20.0)
	GameFeel.spark(at, Palette.STEEL, 8, facing)
	Audio.sfx_at(&"hit_armor", at, -1.0, 1.15)
	if target == null:
		target = hit.source
		on_target_acquired()
		if state in [State.IDLE, State.PATROL, State.RETURN]:
			_set_state(State.CHASE)
	if guard <= 0.0:
		guard_break()
		return HitData.Result.HIT
	return HitData.Result.BLOCKED


func guard_break() -> void:
	guard = max_guard
	guard_breaks += 1
	_set_state(State.PARRIED)
	velocity = Vector2(-facing * 50.0, 0.0)
	GameFeel.spark(global_position + Vector2(facing * 10.0, -24.0), Palette.GOLD_BRIGHT, 18, facing)
	GameFeel.shake(3.0, 0.15)
	Audio.sfx_at(&"parry", global_position, 0.0, 0.8)


func _state_chase(delta: float) -> void:
	if target:
		var dx := target.global_position.x - global_position.x
		if absf(dx) > 4.0 and signf(dx) != float(facing):
			_turn_wait += 1
			if _turn_wait < turn_delay:
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
				return
	_turn_wait = 0
	super(delta)


func play_attack_sound(_a: AttackData) -> void:
	Audio.sfx_at(&"enemy_windup", global_position, 0.0, 0.85)


func play_death_sound() -> void:
	Audio.sfx_at(&"enemy_death", global_position, 0.0, 0.8)
	Audio.sfx_at(&"hit_armor", global_position, -4.0, 0.7)
