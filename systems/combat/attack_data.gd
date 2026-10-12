class_name AttackData
extends Resource
## Data definition of a single attack. Shared by the player and enemies.
## All timings are in physics frames at 60 Hz.
##
## Timeline:  [ startup (anticipation) ][ active (hitbox live) ][ recovery ]
## Chains and dodge-cancels are only possible inside recovery, from the frame
## indicated below. -1 disables the option, so cancels are always deliberate.

@export var id: StringName = &""
@export var display_name := ""
## Pose key used by the visual layer (slash, heavy, air, riposte, thrust, overhead...).
@export var animation: StringName = &"slash"

@export_group("Timing (frames @ 60 fps)")
@export_range(1, 120) var startup_frames := 8
@export_range(1, 60) var active_frames := 4
@export_range(0, 120) var recovery_frames := 14
## Recovery frame from which the next attack in the combo may start (-1 = never).
@export var chain_open_frame := 4
## Recovery frame from which a dodge may cancel the attack (-1 = never).
@export var dodge_cancel_frame := 6
## Attack that follows when chaining a light input.
@export var next_in_combo: AttackData

@export_group("Damage")
@export var damage := 10.0
@export var poise_damage := 10.0
@export var stamina_cost := 12.0
## Player attacks: frames of invulnerability from the start (lunging weapon skills).
@export var invulnerable_frames := 0
## Push applied to the target; x is multiplied by the attacker's facing.
@export var knockback := Vector2(60, -20)
@export var parryable := true
## Optional status buildup this attack inflicts (StatusFx.KINDS) and how much per hit.
@export var status: StringName = &""
@export var status_amount := 0.0
@export var critical := false

@export_group("Hitbox")
@export var hitbox_size := Vector2(32, 20)
## Offset from the attacker's origin (feet) when facing right.
@export var hitbox_offset := Vector2(20, -14)

@export_group("Movement")
@export var lunge_speed := 0.0
@export var lunge_start_frame := 0
@export var lunge_frames := 0
## Gravity multiplier while the attack runs (aerial attacks hang briefly).
@export var gravity_scale := 1.0
@export var is_aerial := false
## Enemies: may turn toward the target during the first part of startup.
@export var track_during_startup := true

@export_group("Projectile")
## When set, this attack fires a projectile on its first active frame instead of using
## the melee hitbox (damage / knockback / parryable below are given to the projectile).
@export var projectile_speed := 0.0
## Spawn point relative to the attacker's feet (x flipped by facing).
@export var projectile_offset := Vector2(14, -22)

@export_group("Feel")
@export var hit_stop := 0.06
@export var shake := 2.0

@export_group("AI (enemies only)")
@export var ai_min_range := 0.0
@export var ai_max_range := 40.0
@export var ai_weight := 1.0
## Chance (0-1) that an enemy continues into next_in_combo.
@export var ai_chain_chance := 1.0


func is_ranged() -> bool:
	return projectile_speed > 0.0


func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("missing id")
	if active_frames < 2:
		problems.append("%s: active_frames < 2 can miss hits" % id)
	if chain_open_frame > recovery_frames:
		problems.append("%s: chain_open_frame beyond recovery" % id)
	if dodge_cancel_frame > recovery_frames:
		problems.append("%s: dodge_cancel_frame beyond recovery" % id)
	if hitbox_size.x <= 0 or hitbox_size.y <= 0:
		problems.append("%s: empty hitbox" % id)
	return problems
