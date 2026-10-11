class_name FlyingEnemy
extends EnemyBase
## Airborne enemy (Gloam Moth). Drifts around its home in the air; once it spots you it
## hovers above and to one side of you, then dives along a straight line (aimed during
## the wind-up, locked for the last part of it). After a dive it hangs dazed near the
## ground for a moment — that is the window to hit it. Parried or staggered, it drops
## to the ground (gravity switches on) and can be riposted; then it rises again.

@export var hover_height := 44.0
@export var hover_side := 36.0
@export var fly_speed := 85.0
## Typical dive speed; the actual speed adapts to the distance (up to 1.5x).
@export var dive_speed := 280.0
@export var fall_gravity := 700.0

var _dive_dir := Vector2.DOWN
var _dive_speed := 240.0
var _bob := 0.0
var _side := 1


func _ready() -> void:
	super()
	gravity = 0.0
	_bob = randf() * 10.0


func _physics_process(delta: float) -> void:
	_bob += delta
	gravity = fall_gravity if state in [State.STAGGER, State.PARRIED, State.DEAD] else 0.0
	super(delta)


func _ledge_ahead() -> bool:
	return false


func _state_patrol(delta: float) -> void:
	if state == State.IDLE:
		_set_state(State.PATROL)
	var off := global_position.x - home.x
	if patrol_distance <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if state_frame % 150 == 149:
			facing = -facing
	else:
		if (facing > 0 and off >= patrol_distance) or (facing < 0 and off <= -patrol_distance) or (is_on_wall() and state_frame > 10):
			facing = -facing
			state_frame = 0
		velocity.x = move_toward(velocity.x, facing * data.patrol_speed, 300.0 * delta)
	var want_y := home.y + sin(_bob * 2.0) * 6.0
	velocity.y = move_toward(velocity.y, clampf((want_y - global_position.y) * 3.0, -60.0, 60.0), 300.0 * delta)


func _state_chase(delta: float) -> void:
	if target == null:
		_set_state(State.RETURN)
		return
	var tp := target.global_position
	var dx := tp.x - global_position.x
	if absf(dx) > 4.0:
		facing = 1 if dx > 0.0 else -1
		_side = -facing
	var want := tp + Vector2(_side * hover_side, -hover_height + sin(_bob * 3.0) * 5.0)
	var to := want - global_position
	var desired := to.normalized() * minf(fly_speed, to.length() * 3.0)
	velocity = velocity.move_toward(desired, 420.0 * delta)
	if _cooldown <= 0 and to.length() < 36.0:
		var a := choose_attack((tp - global_position).length())
		if a:
			_start_attack(a)


func _start_attack(a: AttackData) -> void:
	super(a)
	velocity = Vector2.ZERO
	_aim()


func _aim() -> void:
	if target:
		var to := target.global_position + Vector2(0, -6) - global_position
		_dive_dir = to.normalized()
		# Fast enough to pass a little beyond the aim point within the active frames.
		var a := attack_runner.attack
		var secs := (a.active_frames if a else 18) / 60.0
		_dive_speed = clampf(to.length() * 1.2 / secs, 160.0, dive_speed * 1.5)
		if absf(_dive_dir.x) > 0.05:
			var nf := 1 if _dive_dir.x > 0.0 else -1
			if nf != facing:
				facing = nf
				attack_runner.set_facing(facing)


func _state_attack(delta: float) -> void:
	var a := attack_runner.attack
	if a == null:
		_set_state(State.RECOVER)
		return
	match attack_runner.phase:
		AttackRunner.Phase.STARTUP:
			# Rear back while aiming; the aim locks for the final 30% of the wind-up.
			if attack_runner.frame < a.startup_frames * 0.7:
				_aim()
			velocity = velocity.move_toward(-_dive_dir * 22.0, 300.0 * delta)
		AttackRunner.Phase.ACTIVE:
			velocity = _dive_dir * _dive_speed
			if is_on_floor() or is_on_wall():
				velocity = Vector2.ZERO
		_:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	attack_runner.tick()
	if state != State.ATTACK:
		return
	if not attack_runner.is_running():
		_cooldown = _rng.randi_range(data.attack_cooldown_min, data.attack_cooldown_max)
		_set_state(State.RECOVER)


## Dazed after a dive: hangs where it ended up (low, within reach), then climbs back.
func _state_recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2(0, sin(_bob * 4.0) * 4.0), 500.0 * delta)
	if state_frame >= data.recover_frames:
		_set_state(State.CHASE if target else State.RETURN)


func _state_return(delta: float) -> void:
	var to := home - global_position
	if to.length() < 6.0:
		_set_state(State.PATROL)
		return
	if absf(to.x) > 2.0:
		facing = 1 if to.x > 0.0 else -1
	velocity = velocity.move_toward(to.normalized() * data.patrol_speed * 1.6, 300.0 * delta)
	if state_frame > 600:   # stuck: make here home
		home = global_position
		_set_state(State.PATROL)


func play_attack_sound(_a: AttackData) -> void:
	Audio.sfx_at(&"enemy_windup", global_position, -3.0, 1.5)


func play_death_sound() -> void:
	Audio.sfx_at(&"fizzle", global_position, -2.0, 0.8)
	Audio.sfx_at(&"enemy_death", global_position, -6.0, 1.6)
