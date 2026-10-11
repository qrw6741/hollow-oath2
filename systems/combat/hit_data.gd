class_name HitData
extends RefCounted
## One instance of damage being delivered to a Hurtbox.

## BLOCKED: stopped by a shield (no damage; the attacker recoils).
enum Result { HIT, IGNORED, PARRIED, BLOCKED }

var damage := 0.0
var poise_damage := 0.0
var knockback := Vector2.ZERO        ## Already oriented (x sign = push direction).
var source: Node2D                   ## Attacker (or hazard) node.
var attack_id: StringName = &""
var parryable := true
var critical := false                ## Ripostes / executions.
var environmental := false           ## Hazards: not parryable, ignore dodge i-frames.
var hit_stop := 0.0
var shake := 0.0


static func make(amount: float, from: Node2D, push := Vector2.ZERO) -> HitData:
	var h := HitData.new()
	h.damage = amount
	h.source = from
	h.knockback = push
	return h
