class_name BellBearer
extends EnemyBase
## Heavy village enemy: slow, high poise (hard to stagger), rings its bell before every
## attack. The slam can be parried; the chain swing cannot (red telegraph) — dodge it.


func play_attack_sound(a: AttackData) -> void:
	Audio.sfx_at(&"bell_small", global_position, -2.0 if a.parryable else 0.0, 1.0 if a.parryable else 0.8)


func play_death_sound() -> void:
	Audio.sfx_at(&"enemy_death", global_position, 0.0, 0.7)
	Audio.sfx_at(&"bell_small", global_position, -4.0, 0.6)
