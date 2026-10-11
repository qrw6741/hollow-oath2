class_name AttackRunner
extends Node
## Plays an AttackData timeline (startup -> active -> recovery) frame by frame.
## The owner calls [method tick] once per physics frame while attacking, so the
## owner keeps full control over update order. Used by player and enemies alike.

signal started(attack: AttackData)
signal phase_changed(phase: Phase)
signal hit_confirmed(target: Hurtbox, result: int, hit: HitData)
signal finished(attack: AttackData)

enum Phase { NONE, STARTUP, ACTIVE, RECOVERY }

@export var hitbox: Hitbox

var attack: AttackData
var phase := Phase.NONE
var frame := 0
var facing := 1
var damage_multiplier := 1.0
var _hit_ids := {}


func start(a: AttackData, dir: int, multiplier := 1.0) -> void:
	attack = a
	facing = dir
	frame = 0
	damage_multiplier = multiplier
	_hit_ids.clear()
	_set_phase(Phase.STARTUP)
	_place_hitbox()
	started.emit(a)


func set_facing(dir: int) -> void:
	facing = dir
	if attack:
		_place_hitbox()


func cancel() -> void:
	attack = null
	frame = 0
	_set_phase(Phase.NONE)


func is_running() -> bool:
	return phase != Phase.NONE


func tick() -> void:
	if attack == null:
		return
	frame += 1
	var a := attack
	var next := Phase.RECOVERY
	if frame <= a.startup_frames:
		next = Phase.STARTUP
	elif frame <= a.startup_frames + a.active_frames:
		next = Phase.ACTIVE
	if next != phase:
		_set_phase(next)
	if phase == Phase.ACTIVE:
		_check_hits()
	if attack == a and frame >= a.total_frames():
		attack = null
		_set_phase(Phase.NONE)
		finished.emit(a)


func recovery_frame() -> int:
	if attack == null or phase != Phase.RECOVERY:
		return -1
	return frame - attack.startup_frames - attack.active_frames


func can_chain() -> bool:
	return attack != null and attack.chain_open_frame >= 0 and recovery_frame() >= attack.chain_open_frame


func can_dodge_cancel() -> bool:
	return attack != null and attack.dodge_cancel_frame >= 0 and recovery_frame() >= attack.dodge_cancel_frame


func is_lunging() -> bool:
	if attack == null or attack.lunge_frames <= 0:
		return false
	return frame > attack.lunge_start_frame and frame <= attack.lunge_start_frame + attack.lunge_frames


## 0..1 progress through the current phase (for visuals).
func phase_progress() -> float:
	if attack == null:
		return 0.0
	match phase:
		Phase.STARTUP:
			return float(frame) / attack.startup_frames
		Phase.ACTIVE:
			return float(frame - attack.startup_frames) / attack.active_frames
		Phase.RECOVERY:
			return float(recovery_frame()) / maxf(1.0, attack.recovery_frames)
	return 0.0


func _place_hitbox() -> void:
	if hitbox and attack:
		hitbox.configure(attack.hitbox_size, Vector2(attack.hitbox_offset.x * facing, attack.hitbox_offset.y))


func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


func _check_hits() -> void:
	if hitbox == null:
		return
	var me := get_parent()
	for hb in hitbox.hurtboxes():
		if hb.receiver == me:
			continue
		var id := hb.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var hit := HitData.new()
		hit.damage = attack.damage * damage_multiplier
		hit.poise_damage = attack.poise_damage
		hit.knockback = Vector2(attack.knockback.x * facing, attack.knockback.y)
		hit.source = me as Node2D
		hit.attack_id = attack.id
		hit.parryable = attack.parryable
		hit.critical = attack.critical
		hit.hit_stop = attack.hit_stop
		hit.shake = attack.shake
		var result: int = hb.receive_hit(hit)
		hit_confirmed.emit(hb, result, hit)
		if attack == null:
			return  # Owner cancelled us (e.g. we were parried).
