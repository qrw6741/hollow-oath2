extends Node
## Plays the player's sounds by watching its state and signals, so gameplay code stays
## free of audio calls. Added by Player at runtime. TEMPORARY AUDIO (see docs/AUDIO.md).

const FIST_ANIMS := [&"jab", &"cross", &"hook", &"uppercut", &"haymaker", &"air_fist", &"palm"]
const HEAVY_ANIMS := [&"heavy", &"haymaker", &"riposte", &"palm", &"twin_x"]
const STEP_INTERVAL := 0.27

var player: Player
var _prev_state := -1
var _was_floor := true
var _prev_parry := 0
var _prev_heal_flash := 0
var _step_t := 0.0
var _step_alt := false


func _ready() -> void:
	player = get_parent() as Player
	player.attack_runner.started.connect(_on_attack_started)
	player.attack_runner.hit_confirmed.connect(_on_hit_confirmed)
	player.health.damaged.connect(func(_a): Audio.sfx(&"hurt"); Audio.sfx(&"hit_flesh", -4.0))
	player.health.died.connect(func(): Audio.sfx(&"death"))


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var s := player.state
	if s != _prev_state:
		match s:
			Player.State.DODGE: Audio.sfx(&"dodge")
		_prev_state = s
	var floor_now := player.is_on_floor()
	if floor_now and not _was_floor and player.velocity.y >= 0.0 and s != Player.State.DEAD:
		Audio.sfx(&"land", -6.0)
	if not floor_now and _was_floor and player.velocity.y < -100.0:
		Audio.sfx(&"jump", -4.0)
	_was_floor = floor_now
	if player.parry_flash > _prev_parry:
		Audio.sfx(&"parry")
	_prev_parry = player.parry_flash
	if player.heal_flash > _prev_heal_flash and s == Player.State.HEAL:
		Audio.sfx(&"heal", -3.0)
	_prev_heal_flash = player.heal_flash
	# Footsteps while running on the ground.
	if floor_now and s == Player.State.FREE and absf(player.velocity.x) > 40.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = STEP_INTERVAL
			_step_alt = not _step_alt
			Audio.sfx(&"step_1" if _step_alt else &"step_2", -2.0)
	else:
		_step_t = 0.05


func _on_attack_started(a: AttackData) -> void:
	if FIST_ANIMS.has(a.animation):
		Audio.sfx(&"swing_fist", 0.0, 0.85 if HEAVY_ANIMS.has(a.animation) else 1.0)
	elif HEAVY_ANIMS.has(a.animation):
		Audio.sfx(&"swing_heavy")
	else:
		Audio.sfx(&"swing_light")


func _on_hit_confirmed(target: Hurtbox, result: int, hit: HitData) -> void:
	if result != HitData.Result.HIT:
		return
	var at := player.global_position
	if target:
		at = target.global_position
	if hit.critical:
		Audio.sfx_at(&"hit_crit", at)
	elif target and target.owner is BossBase:
		Audio.sfx_at(&"hit_armor", at)
	else:
		Audio.sfx_at(&"hit_flesh", at)
