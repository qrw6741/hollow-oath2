class_name Lurker
extends EnemyBase
## An ambusher: lies hidden in the shallows (only a ripple and a pair of dim eyes give it away)
## until a living thing walks within reach, then bursts out with a lunge. Cannot be hit while
## hidden. Wakes the neighbours when it springs. TEMPORARY ART in lurker_visual.gd.

var dormant := true
var surface_t := 0.0
@export var trigger_x := 54.0
@export var trigger_y := 70.0


func _ready() -> void:
	super()
	hurtbox.collision_layer = 0
	surface_t = randf() * 6.0


func _physics_process(delta: float) -> void:
	surface_t += delta
	if dormant:
		velocity = Vector2.ZERO
		state_frame += 1
		var p := get_tree().get_first_node_in_group(&"player") as Node2D
		if p and not (p.has_method(&"is_dead") and p.is_dead()):
			var d := p.global_position - global_position
			if absf(d.x) <= trigger_x and absf(d.y) <= trigger_y:
				spring(p)
		return
	super(delta)


func spring(p: Node2D) -> void:
	if not dormant:
		return
	dormant = false
	hurtbox.collision_layer = 16
	target = p
	facing = 1 if p.global_position.x > global_position.x else -1
	Audio.sfx_at(&"boss_roar", global_position, -8.0, 1.5)
	GameFeel.spark(global_position + Vector2(0, -8), Color(0.7, 0.85, 0.9), 14)
	on_target_acquired()
	_start_attack(data.attacks[1] if data.attacks.size() > 1 else data.attacks[0])
	alert_allies()


func _sense() -> void:
	if not dormant:
		super()


func receive_hit(hit: HitData) -> int:
	if dormant:
		return HitData.Result.IGNORED
	return super(hit)


func play_attack_sound(a: AttackData) -> void:
	Audio.sfx_at(&"enemy_windup", global_position, 0.0, 0.8 if a.animation == &"lunge" else 1.2)
