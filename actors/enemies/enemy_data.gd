class_name EnemyData
extends Resource
## Tunable definition of an enemy type. New enemy variants (e.g. a faster
## Penitent, an armoured one) are new .tres files reusing the same scene/script.

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var lore := ""

@export_group("Vitals")
@export var max_health := 60.0
## Poise: accumulated poise damage above this staggers the enemy.
@export var max_poise := 30.0
@export var poise_regen_delay_frames := 90
@export var poise_regen_per_second := 30.0

@export_group("Movement & senses")
@export var patrol_speed := 30.0
@export var chase_speed := 70.0
@export var detection_range := 160.0
@export var vertical_detection := 60.0
## Distance from home beyond which the enemy gives up and returns.
@export var leash_range := 320.0

@export_group("Combat")
## Array of AttackData. Selection uses each attack's ai_min/max_range and ai_weight.
@export var attacks: Array = []
@export var attack_cooldown_min := 30
@export var attack_cooldown_max := 70
@export var recover_frames := 24
@export var backstep_speed := 70.0
@export var stagger_frames := 40
## Frames the enemy stays open to a riposte after being parried.
@export var parry_stagger_frames := 100
