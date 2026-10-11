class_name EnemyBase
extends CharacterBody2D
## Reusable melee enemy brain: patrol -> chase -> attack -> recover, plus stagger,
## parried (riposte window) and death. Subclasses override the virtual hooks
## (choose_attack, on_* callbacks) to build new enemy types on the same behaviours.
## Bosses (Milestone 6) will use a dedicated phase state machine on top of this.

signal died(enemy: EnemyBase)

enum State { IDLE, PATROL, CHASE, ATTACK, RECOVER, STAGGER, PARRIED, RETURN, DEAD }

@export var data: EnemyData
@export var patrol_distance := 56.0
@export_enum("Left:-1", "Right:1") var start_facing := -1
@export var gravity := 900.0

@onready var health: HealthComponent = $Health
@onready var attack_runner: AttackRunner = $AttackRunner
@onready var hurtbox: Hurtbox = $Hurtbox

var state := State.PATROL
var state_frame := 0
var facing := -1
var home := Vector2.ZERO
var poise := 0.0
var target: Node2D
var hit_flash := 0
var _poise_regen_wait := 0
var _cooldown := 0
var _ledge_ray: RayCast2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"enemies")
	_rng.randomize()
	facing = start_facing
	home = global_position
	if data:
		health.set_max(data.max_health)
		poise = data.max_poise
	health.died.connect(_on_died)
	attack_runner.hit_confirmed.connect(_on_attack_hit)
	_ledge_ray = RayCast2D.new()
	_ledge_ray.collision_mask = 1
	_ledge_ray.target_position = Vector2(0, 20)
	add_child(_ledge_ray)


func _physics_process(delta: float) -> void:
	state_frame += 1
	if hit_flash > 0:
		hit_flash -= 1
	if _cooldown > 0:
		_cooldown -= 1
	_update_poise(delta)
	_ledge_ray.position = Vector2(facing * 10.0, -4.0)
	if state != State.DEAD:
		_sense()

	match state:
		State.IDLE, State.PATROL: _state_patrol(delta)
		State.CHASE: _state_chase(delta)
		State.ATTACK: _state_attack(delta)
		State.RECOVER: _state_recover(delta)
		State.STAGGER, State.PARRIED: _state_stagger(delta)
		State.RETURN: _state_return(delta)
		State.DEAD: _state_dead(delta)

	velocity.y = minf(velocity.y + gravity * delta, 420.0)
	move_and_slide()


# ------------------------------------------------------------------ senses

func _sense() -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Node2D
	if p == null or (p.has_method(&"is_dead") and p.is_dead()):
		if target and state in [State.CHASE, State.RECOVER]:
			_set_state(State.RETURN)
		target = null
		return
	var d := p.global_position - global_position
	if target == null:
		if absf(d.x) <= data.detection_range and absf(d.y) <= data.vertical_detection and _can_see_side(d.x):
			target = p
			on_target_acquired()
			if state in [State.IDLE, State.PATROL, State.RETURN]:
				_set_state(State.CHASE)
	else:
		var from_home := absf(global_position.x - home.x)
		if from_home > data.leash_range or d.length() > data.detection_range * 1.8:
			target = null
			if state in [State.CHASE, State.RECOVER]:
				_set_state(State.RETURN)


## Enemies notice players in front of them at full range, behind them at half.
func _can_see_side(dx: float) -> bool:
	return signf(dx) == float(facing) or absf(dx) < data.detection_range * 0.5


func _ledge_ahead() -> bool:
	return is_on_floor() and not _ledge_ray.is_colliding()


# ------------------------------------------------------------------ states

## Walk back and forth around [member home]; pause and look around at each end.
## With patrol_distance 0 the enemy is a sentry that turns around periodically.
func _state_patrol(delta: float) -> void:
	if state == State.IDLE:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if state_frame > 60:
			facing = -facing
			_set_state(State.PATROL)
		return
	var offset := global_position.x - home.x
	var blocked := (facing > 0 and offset >= patrol_distance) or (facing < 0 and offset <= -patrol_distance)
	if state_frame > 6 and (is_on_wall() or _ledge_ahead()):
		blocked = true
	if blocked:
		_set_state(State.IDLE)
		return
	velocity.x = facing * data.patrol_speed


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
	var desired := facing * data.chase_speed
	if dist < 22.0:
		desired = -facing * data.chase_speed * 0.4   # Give a little space.
	elif _cooldown > 0 and dist < 60.0:
		desired = 0.0                                # Hold spacing while waiting.
	if _ledge_ahead() and signf(desired) == float(facing):
		desired = 0.0
	velocity.x = move_toward(velocity.x, desired, 700.0 * delta)


func _start_attack(a: AttackData) -> void:
	_set_state(State.ATTACK)
	velocity.x = 0.0
	attack_runner.start(a, facing)
	play_attack_sound(a)
	on_attack_started(a)


func _state_attack(delta: float) -> void:
	var a := attack_runner.attack
	if a == null:
		_set_state(State.RECOVER)
		return
	# Track the target during the first 60% of the wind-up only — committing after that.
	if a.track_during_startup and target and attack_runner.phase == AttackRunner.Phase.STARTUP and attack_runner.frame < a.startup_frames * 0.6:
		var dx := target.global_position.x - global_position.x
		if absf(dx) > 4.0:
			var nf := 1 if dx > 0.0 else -1
			if nf != facing:
				facing = nf
				attack_runner.set_facing(facing)
	if attack_runner.is_lunging() and not _ledge_ahead():
		velocity.x = facing * a.lunge_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	attack_runner.tick()
	if state != State.ATTACK:
		return
	if not attack_runner.is_running():
		if a.next_in_combo and _rng.randf() < a.ai_chain_chance:
			_start_attack(a.next_in_combo)
		else:
			_cooldown = _rng.randi_range(data.attack_cooldown_min, data.attack_cooldown_max)
			_set_state(State.RECOVER)


func _state_recover(delta: float) -> void:
	# Short backstep, then re-engage.
	var spd := data.backstep_speed if state_frame < 10 and not _ledge_behind() else 0.0
	velocity.x = move_toward(velocity.x, -facing * spd, 900.0 * delta)
	if state_frame >= data.recover_frames:
		_set_state(State.CHASE if target else State.RETURN)


func _ledge_behind() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(-facing * 12.0, -4.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 22), 1)
	return is_on_floor() and space.intersect_ray(q).is_empty()


func _state_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	var length := data.parry_stagger_frames if state == State.PARRIED else data.stagger_frames
	if state_frame >= length:
		_cooldown = maxi(_cooldown, 20)
		_set_state(State.CHASE if target else State.RETURN)


func _state_return(delta: float) -> void:
	var dx := home.x - global_position.x
	if absf(dx) < 6.0 or is_on_wall() or (_ledge_ahead() and state_frame > 5):
		home.x = global_position.x if absf(dx) >= 6.0 else home.x
		_set_state(State.PATROL)
		return
	facing = 1 if dx > 0.0 else -1
	velocity.x = move_toward(velocity.x, facing * data.patrol_speed * 1.5, 600.0 * delta)


func _state_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if state_frame >= 90:
		queue_free()


func _set_state(s: State) -> void:
	if state == State.ATTACK and s != State.ATTACK:
		attack_runner.cancel()
	state = s
	state_frame = 0


# ------------------------------------------------------------------ combat

## Virtual: pick an attack for the current distance (null = keep approaching).
func choose_attack(distance: float) -> AttackData:
	var options: Array[AttackData] = []
	var total := 0.0
	for a in data.attacks:
		var atk := a as AttackData
		if atk and atk.ai_weight > 0.0 and distance >= atk.ai_min_range and distance <= atk.ai_max_range:
			options.append(atk)
			total += atk.ai_weight
	if options.is_empty():
		return null
	var roll := _rng.randf() * total
	for atk in options:
		roll -= atk.ai_weight
		if roll <= 0.0:
			return atk
	return options.back()


func receive_hit(hit: HitData) -> int:
	if state == State.DEAD:
		return HitData.Result.IGNORED
	var was_parried := state == State.PARRIED
	var applied := health.take_damage(hit.damage)
	hit_flash = 6
	GameFeel.damage_number(global_position + Vector2(0, -38), applied, hit.critical)
	var push_dir := 1 if hit.knockback.x >= 0.0 else -1
	GameFeel.spark(global_position + Vector2(-push_dir * 4, -16), Palette.BONE if not hit.critical else Palette.GOLD_BRIGHT, 14 if hit.critical else 9, push_dir)
	if hit.source and target == null and not hit.environmental:
		target = hit.source
		on_target_acquired()
	if health.is_dead:
		return HitData.Result.HIT
	poise -= hit.poise_damage
	_poise_regen_wait = data.poise_regen_delay_frames
	if hit.critical or poise <= 0.0 or was_parried:
		poise = data.max_poise
		_set_state(State.STAGGER)
		velocity = hit.knockback
		on_staggered()
	elif hit.environmental:
		velocity = hit.knockback
	else:
		velocity.x += hit.knockback.x * 0.2  # Hyper-armour: flinch only visually.
	return HitData.Result.HIT


func _on_attack_hit(_target: Hurtbox, result: int, hit: HitData) -> void:
	match result:
		HitData.Result.PARRIED:
			_set_state(State.PARRIED)
			velocity = Vector2(-facing * 60.0, 0.0)
			on_parried()
		HitData.Result.HIT:
			GameFeel.hit_stop(hit.hit_stop)


func _update_poise(delta: float) -> void:
	if _poise_regen_wait > 0:
		_poise_regen_wait -= 1
	elif data and poise < data.max_poise:
		poise = minf(data.max_poise, poise + data.poise_regen_per_second * delta)


func is_riposte_ready() -> bool:
	return state == State.PARRIED and state_frame >= 4


func is_dead() -> bool:
	return state == State.DEAD


func _on_died() -> void:
	_set_state(State.DEAD)
	hurtbox.enabled = false
	collision_layer = 0
	GameFeel.spark(global_position + Vector2(0, -16), Palette.EMBER, 22)
	died.emit(self)
	play_death_sound()
	Events.enemy_killed.emit(self)
	on_died()


# ------------------------------------------------------------------ sounds (virtual)

func play_attack_sound(_a: AttackData) -> void:
	Audio.sfx_at(&"enemy_windup", global_position)


func play_death_sound() -> void:
	Audio.sfx_at(&"enemy_death", global_position)


# ------------------------------------------------------------------ virtual hooks

func on_target_acquired() -> void:
	pass

func on_attack_started(_a: AttackData) -> void:
	pass

func on_staggered() -> void:
	pass

func on_parried() -> void:
	pass

func on_died() -> void:
	pass


func state_name() -> String:
	return State.keys()[state]
