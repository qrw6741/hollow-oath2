class_name DrownedCanon
extends BossBase
## Second boss. Keeps its distance more than the Bell-Warden and fights with water:
##   Rosary Lash  — long-reach whip, parryable (glint). Phase 2 chains a returning lash.
##   Bile Hymn    — three spat projectiles in a fan, parryable or dodged through.
##   Undertow     — sinks (invulnerable), surfaces under the player as a geyser after a
##                  bubbling telegraph. Unparryable: move away from the bubbles.
##   Flood Psalm  — phase 2: a wave rolls along the floor toward the player. Jump it.

## How far from its start position it may surface (keeps it inside the arena).
@export var arena_half_width := 320.0
## Frames into Undertow: when it sinks, and when it moves under the target.
@export var sink_frame := 18
@export var move_frame := 26

var submerged := false


func _state_attack(delta: float) -> void:
	var a := attack_runner.attack
	if a and a.animation == &"submerge":
		velocity.x = 0.0
		var f := state_frame
		if f == sink_frame:
			submerged = true
			hurtbox.enabled = false
			Audio.sfx_at(&"splash", global_position, 2.0)
		if f == move_frame:
			var tx := global_position.x
			if target:
				tx = target.global_position.x
			global_position.x = clampf(tx, home.x - arena_half_width, home.x + arena_half_width)
		if f == a.startup_frames - 1:
			submerged = false
			hurtbox.enabled = true
			Audio.sfx_at(&"geyser", global_position)
			GameFeel.shake(5.0, 0.3)
	super(delta)


func _set_state(s: State) -> void:
	if s != State.ATTACK and submerged:
		submerged = false
		if s != State.DEAD:
			hurtbox.enabled = true
	super(s)


func _fire_projectile(a: AttackData) -> void:
	var hit := HitData.new()
	hit.damage = a.damage
	hit.knockback = Vector2(a.knockback.x * facing, a.knockback.y)
	hit.parryable = a.parryable
	hit.attack_id = a.id
	hit.hit_stop = a.hit_stop
	hit.shake = a.shake
	var from := global_position + Vector2(a.projectile_offset.x * facing, a.projectile_offset.y)
	match a.animation:
		&"spit":
			for deg in [-14.0, 0.0, 14.0]:
				var dir := Vector2(facing, 0).rotated(deg_to_rad(deg) * facing)
				Projectile.spawn(get_parent(), from, dir * a.projectile_speed, hit, self,
					{"color": Color(0.45, 0.7, 0.4), "drop": 30.0, "radius": 4.0})
			Audio.sfx_at(&"spit", from)
		&"wave":
			Projectile.spawn(get_parent(), global_position + Vector2(facing * 24.0, -9.0), Vector2(facing * a.projectile_speed, 0.0), hit, self,
				{"kind": &"wave", "size": Vector2(22, 18), "drop": 0.0, "hit_world": false, "lifetime": 3.6})
			Audio.sfx_at(&"wave", global_position)
		_:
			super(a)


func play_attack_sound(a: AttackData) -> void:
	match a.animation:
		&"lash", &"lash_back":
			Audio.sfx_at(&"swing_heavy", global_position, -2.0, 1.25)
		&"submerge":
			Audio.sfx_at(&"boss_roar", global_position, -10.0, 1.4)
		&"wave":
			Audio.sfx_at(&"boss_bell", global_position, -6.0, 0.7)
		_:
			pass


func play_death_sound() -> void:
	Audio.sfx_at(&"boss_death", global_position, 0.0, 0.8)
	Audio.sfx_at(&"splash", global_position, 4.0, 0.6)
