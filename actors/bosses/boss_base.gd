class_name BossBase
extends EnemyBase
## Boss brain built on EnemyBase (same attacks, parry/riposte, poise and stagger rules)
## plus what bosses need:
##   - stays dormant until its arena calls start_fight(); never leashes or wanders home;
##   - two phases: below [member phase2_threshold] health it roars (a short pause that
##     shoves the player back) and switches to [member phase2_attacks], moving faster and
##     attacking more often;
##   - "leap" attacks (animation &"leap"): jumps at the target and lands on the hit frame;
##   - a defeat flag in GameState so it never returns once beaten.

signal phase_changed(phase: int)

@export var boss_id: StringName = &"boss"
## Attack pool after the phase change (AttackData). Empty = keep the phase-1 pool.
@export var phase2_attacks: Array = []
@export_range(0.0, 1.0) var phase2_threshold := 0.5
@export var phase2_speed_mult := 1.3
@export var phase2_cooldown_mult := 0.6
## Frames of the phase-change roar (boss does not attack during it).
@export var roar_frames := 80
## Frame of a leap attack on which the boss leaves the ground.
@export var leap_jump_frame := 12
@export var leap_jump_speed := 330.0
@export var leap_max_speed := 280.0
## Music for this fight (assets/audio/music) and its playback pitch.
@export var music_track: StringName = &"boss"
@export var music_pitch := 1.0
## Frames the corpse lingers before fading out.
@export var corpse_frames := 220

var active := false
var gimmicks: BossGimmicks
var phase := 1
var roaring := false
var leaping := false
var _leap_vx := 0.0


func _ready() -> void:
	super()
	add_to_group(&"bosses")
	# Bosses own their data at runtime (phase 2 modifies it).
	if data:
		data = data.duplicate()
	state = State.IDLE


func defeat_flag() -> StringName:
	return StringName("boss_defeated_" + String(boss_id))


## Called by the arena when the player walks in.
func start_fight() -> void:
	if active or is_dead():
		return
	active = true
	target = get_tree().get_first_node_in_group(&"player") as Node2D
	_cooldown = 50   # a beat to read the boss before the first swing
	_set_state(State.CHASE)
	if gimmicks == null and BossGimmicks.has_for(boss_id):
		gimmicks = BossGimmicks.new().setup(self)
		add_child(gimmicks)
	Events.boss_fight_started.emit(self)


# ------------------------------------------------------------------ overrides

func _sense() -> void:
	if not active:
		target = null
		return
	var p := get_tree().get_first_node_in_group(&"player") as Node2D
	if p == null or (p.has_method(&"is_dead") and p.is_dead()):
		target = null
		if state in [State.CHASE, State.RECOVER]:
			_set_state(State.IDLE)
		return
	target = p


## Dormant (or waiting for a target): stand still and face the arena entrance / the player.
func _physics_process(delta: float) -> void:
	super(delta)
	if state == State.CHASE and is_on_floor() and absf(velocity.x) > 20.0 and state_frame % 26 == 0:
		Audio.sfx_at(&"boss_stomp", global_position, -10.0)


func _state_patrol(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if active and target:
		_set_state(State.CHASE)


func _state_return(delta: float) -> void:
	_state_patrol(delta)
	if state == State.RETURN:
		_set_state(State.IDLE)


func _start_attack(a: AttackData) -> void:
	leaping = false
	super(a)


func _state_attack(delta: float) -> void:
	var a := attack_runner.attack
	var is_leap := a != null and a.animation == &"leap"
	if is_leap and state_frame == leap_jump_frame and is_on_floor():
		var dx := 0.0
		if target:
			dx = target.global_position.x - global_position.x
		var air := 2.0 * leap_jump_speed / gravity
		_leap_vx = clampf(dx / air, -leap_max_speed, leap_max_speed)
		velocity.y = -leap_jump_speed
		leaping = true
	super(delta)
	if leaping:
		if state_frame > leap_jump_frame + 3 and is_on_floor():
			leaping = false
			velocity.x = 0.0
			GameFeel.shake(6.0, 0.3)
			Audio.sfx_at(&"boss_land", global_position)
			GameFeel.spark(global_position, Palette.DUST, 20)
		else:
			velocity.x = _leap_vx


func _state_stagger(delta: float) -> void:
	if not roaring:
		super(delta)
		return
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	if state_frame == 24:
		_roar_shove()
	if state_frame >= roar_frames:
		roaring = false
		_cooldown = 20
		_set_state(State.CHASE if target else State.IDLE)


func _state_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if state_frame >= corpse_frames:
		queue_free()


func receive_hit(hit: HitData) -> int:
	if not active and not hit.environmental and not is_dead():
		start_fight()   # struck from outside the arena trigger (e.g. a long lunge)
	var r := super(hit)
	if phase == 1 and not health.is_dead and health.current <= health.max_health * phase2_threshold:
		_enter_phase2()
	return r


func _enter_phase2() -> void:
	phase = 2
	if not phase2_attacks.is_empty():
		data.attacks = phase2_attacks.duplicate()
	data.chase_speed *= phase2_speed_mult
	data.attack_cooldown_min = int(data.attack_cooldown_min * phase2_cooldown_mult)
	data.attack_cooldown_max = int(data.attack_cooldown_max * phase2_cooldown_mult)
	poise = data.max_poise
	roaring = true
	_set_state(State.STAGGER)
	velocity = Vector2.ZERO
	phase_changed.emit(phase)
	Events.boss_phase_changed.emit(self, phase)
	on_phase_changed(phase)


## The roar pushes a nearby player away (no damage) so phase 2 starts with space.
func _roar_shove() -> void:
	Audio.sfx_at(&"boss_roar", global_position)
	GameFeel.shake(5.0, 0.4)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p and not p.is_dead():
		var d := p.global_position.x - global_position.x
		if absf(d) < 90.0:
			p.velocity = Vector2(signf(d if d != 0.0 else 1.0) * 260.0, -140.0)


func _on_died() -> void:
	super()
	roaring = false
	leaping = false
	GameState.set_flag(defeat_flag(), true)
	# A boss dying is an event: a long freeze, a heavy shake and a burst of sparks.
	GameFeel.hit_stop(0.3)
	GameFeel.shake(12.0, 0.7)
	GameFeel.ring(global_position + Vector2(0, -26), Palette.GOLD_BRIGHT, 90.0)
	GameFeel.rise(global_position + Vector2(0, -10), Palette.EMBER, 40, 40.0)
	for i in 3:
		GameFeel.spark(global_position + Vector2(randf_range(-14, 14), -26 + randf_range(-14, 14)), Palette.EMBER, 14)
	Events.boss_defeated.emit(boss_id)


# ------------------------------------------------------------------ sounds

## The Bell-Warden tolls its bell during every overhead wind-up: an audio telegraph.
func play_attack_sound(a: AttackData) -> void:
	match a.animation:
		&"smash":
			Audio.sfx_at(&"boss_bell", global_position, -2.0)
		&"charge":
			Audio.sfx_at(&"boss_stomp", global_position)
		&"leap":
			Audio.sfx_at(&"swing_heavy", global_position, 0.0, 0.6)
		_:
			Audio.sfx_at(&"swing_heavy", global_position, -2.0, 0.7)


func play_death_sound() -> void:
	Audio.sfx_at(&"boss_death", global_position)


## Virtual hook for subclasses / visuals.
func on_phase_changed(_phase: int) -> void:
	pass
