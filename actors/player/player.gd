class_name Player
extends CharacterBody2D
## The Oathbound — player controller.
## Owns the movement/action state machine. Damage, stamina, attack timelines and
## drawing are delegated to child components (Health, Stamina, AttackRunner, Visual).

enum State { FREE, ATTACK, DODGE, PARRY, HEAL, HURT, REST, DEAD }

@export var weapon: WeaponData
## Starting preset (weapon, vitals, armour, handling). Assigned by Level before the
## player enters the tree; when null the scene defaults (the Sworn Knight) apply.
@export var preset: PresetData

@export_group("Movement")
@export var run_speed := 112.0
@export var ground_accel := 1200.0
@export var ground_decel := 1600.0
@export var air_accel := 800.0
@export var jump_velocity := -300.0
@export var gravity := 900.0
@export var fall_gravity_mult := 1.45
@export var max_fall_speed := 420.0
@export var jump_cut_mult := 0.45
@export var coyote_frames := 6
@export var buffer_frames := 8

@export_group("Dodge")
@export var dodge_frames := 22
@export var dodge_speed := 235.0
@export var dodge_iframe_start := 2
@export var dodge_iframe_end := 14
@export var dodge_stamina := 22.0
## Frame of the dodge after which attacks / jumps may cancel the tail.
@export var dodge_act_frame := 16

@export_group("Parry")
@export var parry_window_frames := 8
@export var parry_total_frames := 26
@export var parry_success_recovery := 8
@export var parry_stamina := 12.0
@export var riposte_reach := 46.0

@export_group("Healing")
@export var max_flasks := 3
@export var flask_heal := 45.0
@export var heal_frames := 42
@export var heal_apply_frame := 26
@export var heal_move_mult := 0.3

@export_group("Damage")
@export var hurt_frames := 18
@export var post_hit_iframes := 40
@export var rest_frames := 50

@onready var health: HealthComponent = $Health
@onready var stamina: StaminaComponent = $Stamina
@onready var attack_runner: AttackRunner = $AttackRunner
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node2D = $Visual

var state := State.FREE
var state_frame := 0
var facing := 1
var flasks := 3
var parry_flash := 0          ## Frames of "successful parry" feedback left (visual).
var heal_flash := 0
var _coyote := 0
var _buffer := {}
var _iframes := 0
var _jumping := false
var _queued_attack: StringName = &""
var _heal_applied := false
var _parried := false
var _last_hit_id := 0
## Multiplies all damage taken (armour). Set from the preset.
var damage_taken_mult := 1.0
## What is drawn: the preset composed with the equipped weapon and armour (see Loadout).
var look: PresetData
var _base_run_speed := 112.0
## Number of water zones the player stands in (WaterZone). Water slows movement.
var in_water := 0
const WATER_MOVE := 0.6
const WATER_JUMP := 0.88
## Last standing spot that was not a hazard; lost embers fall here.
var last_safe_position := Vector2.ZERO

const BUFFERED: Array[StringName] = [&"jump", &"attack_light", &"attack_heavy", &"dodge", &"parry", &"heal", &"skill"]


func _ready() -> void:
	add_to_group(&"player")
	status = StatusComponent.new()
	status.name = &"Status"
	status.health = health
	status.position = Vector2(0, -46)
	add_child(status)
	_base_run_speed = run_speed
	if preset:
		_apply_preset()
		Events.loadout_changed.connect(apply_loadout)
	flasks = max_flasks
	last_safe_position = global_position
	health.died.connect(_on_died)
	attack_runner.hit_confirmed.connect(_on_attack_hit)
	_add_lantern()
	var snd := Node.new()
	snd.name = &"Sounds"
	snd.set_script(load("res://actors/player/player_sounds.gd"))
	add_child(snd)
	_emit_spawned.call_deferred()


func _apply_preset() -> void:
	Loadout.ensure(preset)
	health.set_max(preset.max_health)
	stamina.max_stamina = preset.max_stamina
	stamina.regen_per_second = preset.stamina_regen
	stamina.restore_full()
	parry_window_frames = preset.parry_window_frames
	parry_stamina = preset.parry_stamina
	apply_loadout()
	flasks = max_flasks
	apply_stats(false)


## Recomputes everything the equipped weapon, armour and vial level decide: weapon,
## damage multiplier, damage taken, run speed, dodge cost, vials and what is drawn.
## Called at spawn and whenever Events.loadout_changed fires.
func apply_loadout() -> void:
	if preset == null:
		return
	var w := Loadout.weapon()
	weapon = w if w else preset.weapon
	damage_taken_mult = Loadout.damage_taken_mult()
	if status:
		status.resist = Armors.resist_of(GameState.armor_id, GameState.armor_level(GameState.armor_id))
	attack_runner.weapon_status = weapon.status if weapon else &""
	attack_runner.weapon_status_amount = weapon.status_amount if weapon else 0.0
	run_speed = _base_run_speed * Armors.speed_mult(GameState.armor_id)
	dodge_stamina = preset.dodge_stamina + Armors.dodge_add(GameState.armor_id)
	var old_max := max_flasks
	max_flasks = preset.flasks + Forge.vial_extra(GameState.flask_level)
	flask_heal = preset.flask_heal + Forge.vial_heal_bonus(GameState.flask_level)
	if max_flasks > old_max:
		flasks += max_flasks - old_max
	flasks = mini(flasks, max_flasks)
	_refresh_damage_bonus()
	look = Loadout.compose_look(preset)
	Events.flasks_changed.emit(flasks, max_flasks)


func _refresh_damage_bonus() -> void:
	var stre := int(GameState.stats.get("strength", 0))
	attack_runner.damage_bonus = (1.0 + stre * GameState.STRENGTH_DAMAGE) * Loadout.weapon_mult()


## Applies Vigor / Endurance / Strength on top of the preset. With [param heal_gain],
## newly gained maximum health is also granted as current health (after a level-up).
func apply_stats(heal_gain := true) -> void:
	if preset == null:
		return
	var old_max := health.max_health
	var vig := int(GameState.stats.get("vigor", 0))
	var end := int(GameState.stats.get("endurance", 0))
	var stre := int(GameState.stats.get("strength", 0))
	health.set_max(preset.max_health + vig * GameState.VIGOR_HEALTH, false)
	if heal_gain and health.max_health > old_max:
		health.heal(health.max_health - old_max)
	stamina.max_stamina = preset.max_stamina + end * GameState.ENDURANCE_STAMINA
	_refresh_damage_bonus()
	if not heal_gain:
		health.current = health.max_health
		stamina.restore_full()


## Faint personal light so the player reads clearly in dark rooms.
func _add_lantern() -> void:
	var l := PointLight2D.new()
	l.name = &"Lantern"
	l.texture = LightTex.radial()
	l.texture_scale = 1.6
	l.color = Color("d9c7a0")
	l.energy = 0.35
	l.position = Vector2(0, -14)
	add_child(l)


func _emit_spawned() -> void:
	focus = GameState.focus
	focus_changed.emit(focus, MAX_FOCUS)
	Events.player_spawned.emit(self)
	Events.flasks_changed.emit(flasks, max_flasks)


# ------------------------------------------------------------------ main loop

func _physics_process(delta: float) -> void:
	_read_input()
	if is_on_floor() and state != State.DEAD and not _on_hazard():
		last_safe_position = global_position
	if Input.is_action_just_pressed(&"use_item") and state == State.FREE and not GameState.ui_modal:
		Items.use(GameState.quick_item, self)
	if combat_frames > 0:
		combat_frames -= 1
	if state != State.PARRY:
		blocking = false
	if Input.is_action_just_pressed(&"travel_manor") and state == State.FREE and not GameState.ui_modal:
		_try_manor_travel()
	state_frame += 1
	if _iframes > 0:
		_iframes -= 1
	if parry_flash > 0:
		parry_flash -= 1
	if heal_flash > 0:
		heal_flash -= 1
	stamina.regen_multiplier = 0.25 if state in [State.HEAL, State.PARRY] else 1.0

	match state:
		State.FREE: _state_free(delta)
		State.ATTACK: _state_attack(delta)
		State.DODGE: _state_dodge(delta)
		State.PARRY: _state_parry(delta)
		State.HEAL: _state_heal(delta)
		State.HURT: _state_hurt(delta)
		State.REST: _state_rest(delta)
		State.DEAD: _state_dead(delta)

	move_and_slide()


# ------------------------------------------------------------------ input

func _read_input() -> void:
	if state == State.DEAD:
		_buffer.clear()
		return
	for a in BUFFERED:
		if Input.is_action_just_pressed(a):
			_buffer[a] = buffer_frames
		elif _buffer.get(a, 0) > 0:
			_buffer[a] -= 1


func _buffered(a: StringName) -> bool:
	return _buffer.get(a, 0) > 0


func _consume(a: StringName) -> bool:
	if _buffered(a):
		_buffer[a] = 0
		return true
	return false


func _axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


# ------------------------------------------------------------------ states

func _state_free(delta: float) -> void:
	var dir := _axis()
	var accel := (ground_accel if dir != 0.0 else ground_decel) if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, dir * run_speed * move_mult(), accel * delta)
	if dir != 0.0:
		facing = signi(int(signf(dir)))
	_apply_gravity(delta)

	if is_on_floor():
		_coyote = coyote_frames
		_jumping = false
	elif _coyote > 0:
		_coyote -= 1

	# Variable jump height.
	if _jumping and velocity.y < 0.0 and not Input.is_action_pressed(&"jump"):
		velocity.y *= jump_cut_mult
		_jumping = false

	_try_actions()


## Shared action entry points (from FREE and from cancellable tails).
func _try_actions() -> bool:
	var grounded := is_on_floor()
	if _buffered(&"dodge") and grounded and stamina.can_spend():
		_consume(&"dodge")
		_start_dodge()
		return true
	if _buffered(&"parry") and stamina.can_spend():
		_consume(&"parry")
		_start_parry()
		return true
	if _buffered(&"heal") and grounded:
		_consume(&"heal")
		if flasks > 0:
			_start_heal()
			return true
	if _buffered(&"jump") and (grounded or _coyote > 0):
		_consume(&"jump")
		_jump()
		return true
	if _buffered(&"skill"):
		_consume(&"skill")
		if can_use_skill():
			set_focus(focus - weapon.skill_cost)
			_start_attack(weapon.skill)
			Audio.sfx_at(&"parry", global_position, -8.0, 0.7)
			return true
	if _buffered(&"attack_light") and stamina.can_spend() and weapon:
		_consume(&"attack_light")
		var target := find_riposte_target()
		if target and grounded and weapon.riposte:
			_start_attack(weapon.riposte, weapon.riposte_multiplier)
			_iframes = weapon.riposte.total_frames()  # Ripostes are protected.
		elif not grounded and weapon.aerial:
			_start_attack(weapon.aerial)
		elif weapon.light_combo_start:
			_start_attack(weapon.light_combo_start)
		return true
	if _buffered(&"attack_heavy") and stamina.can_spend() and weapon and weapon.heavy:
		_consume(&"attack_heavy")
		if grounded:
			_start_attack(weapon.heavy)
		elif weapon.aerial:
			_start_attack(weapon.aerial)
		return true
	return false


func _jump() -> void:
	velocity.y = jump_velocity * (WATER_JUMP if in_water > 0 else 1.0)
	_coyote = 0
	_jumping = true


func _start_attack(a: AttackData, multiplier := 1.0) -> void:
	var dir := _axis()
	if dir != 0.0:
		facing = signi(int(signf(dir)))
	stamina.spend(a.stamina_cost)
	if a.invulnerable_frames > 0:
		_iframes = maxi(_iframes, a.invulnerable_frames)
	_queued_attack = &""
	_set_state(State.ATTACK)
	attack_runner.start(a, facing, multiplier)


func _state_attack(delta: float) -> void:
	var a := attack_runner.attack
	if a == null:
		_set_state(State.FREE)
		return
	if attack_runner.is_lunging():
		velocity.x = facing * a.lunge_speed
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	else:
		velocity.x = move_toward(velocity.x, _axis() * run_speed * 0.6 * move_mult(), air_accel * 0.5 * delta)
	_apply_gravity(delta, a.gravity_scale)

	# Queue the next input any time after the startup has begun (Souls-style).
	if _consume(&"attack_light"):
		_queued_attack = &"light"
	elif _consume(&"attack_heavy"):
		_queued_attack = &"heavy"

	attack_runner.tick()
	if state != State.ATTACK:
		return  # A hit callback may have changed state.

	# Aerial attacks end on landing once their active frames are over.
	if a.is_aerial and is_on_floor() and attack_runner.phase == AttackRunner.Phase.RECOVERY:
		attack_runner.cancel()
		_set_state(State.FREE)
		return

	if attack_runner.can_chain() and _queued_attack != &"" and stamina.can_spend() and is_on_floor():
		var next: AttackData = null
		if _queued_attack == &"light":
			next = a.next_in_combo if a.next_in_combo else weapon.light_combo_start
		else:
			next = weapon.heavy
		if next:
			_start_attack(next)
			return
	if attack_runner.can_dodge_cancel() and _buffered(&"dodge") and is_on_floor() and stamina.can_spend():
		_consume(&"dodge")
		attack_runner.cancel()
		_start_dodge()
		return
	if not attack_runner.is_running():
		_set_state(State.FREE)


func _start_dodge() -> void:
	var dir := _axis()
	if dir != 0.0:
		facing = signi(int(signf(dir)))
	stamina.spend(dodge_stamina)
	_set_state(State.DODGE)


func _state_dodge(delta: float) -> void:
	var t := float(state_frame) / dodge_frames
	velocity.x = facing * dodge_speed * (0.75 if in_water > 0 else 1.0) * pow(1.0 - clampf(t, 0.0, 1.0), 1.4)
	_apply_gravity(delta)
	if state_frame >= dodge_act_frame and is_on_floor():
		# Tail of the roll may be cancelled by attacks or jumps — but not by another dodge.
		if not _buffered(&"dodge") and _try_actions():
			return
	if state_frame >= dodge_frames:
		_set_state(State.FREE)


func _start_parry() -> void:
	stamina.spend(parry_stamina)
	_parried = false
	_set_state(State.PARRY)


func _state_parry(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_apply_gravity(delta)
	var total := parry_success_recovery if _parried else _parry_total()
	blocking = false
	if not _parried and weapon and weapon.block_reduction > 0.0 and state_frame > _window_frames() \
			and Input.is_action_pressed(&"parry") and stamina.current > 0.0:
		blocking = true
		state_frame = mini(state_frame, total - 1)  # hold the guard while the button is down
		return
	if state_frame >= total:
		_set_state(State.FREE)


func is_parry_active() -> bool:
	return state == State.PARRY and not _parried and state_frame <= _window_frames() + (Settings.PARRY_ASSIST_FRAMES if Settings.parry_assist else 0)


func _start_heal() -> void:
	_heal_applied = false
	_set_state(State.HEAL)


func _state_heal(delta: float) -> void:
	var dir := _axis()
	velocity.x = move_toward(velocity.x, dir * run_speed * heal_move_mult * move_mult(), ground_accel * delta)
	_apply_gravity(delta)
	if not _heal_applied and state_frame >= heal_apply_frame:
		_heal_applied = true
		flasks -= 1
		health.heal(flask_heal)
		heal_flash = 20
		Events.flasks_changed.emit(flasks, max_flasks)
	if state_frame >= heal_frames:
		_set_state(State.FREE)


func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * 0.5 * delta)
	_apply_gravity(delta)
	if state_frame >= hurt_frames:
		_set_state(State.FREE)


func _state_rest(delta: float) -> void:
	velocity.x = 0.0
	_apply_gravity(delta)
	if state_frame >= rest_frames:
		_set_state(State.FREE)


func _state_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_apply_gravity(delta)


func _apply_gravity(delta: float, scale := 1.0) -> void:
	var g := gravity * (fall_gravity_mult if velocity.y > 0.0 else 1.0) * scale
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func _set_state(s: State) -> void:
	if state == State.ATTACK and s != State.ATTACK:
		attack_runner.cancel()
	state = s
	state_frame = 0


# ------------------------------------------------------------------ combat

func is_invulnerable(environmental := false) -> bool:
	if state == State.DEAD or _iframes > 0:
		return true
	if not environmental and state == State.DODGE:
		return state_frame >= dodge_iframe_start and state_frame <= dodge_iframe_end
	return false


func is_dodge_invulnerable() -> bool:
	return state == State.DODGE and is_invulnerable()


func receive_hit(hit: HitData) -> int:
	if state == State.DEAD:
		return HitData.Result.IGNORED
	if not hit.environmental and hit.parryable and is_parry_active() and _faces(hit.source):
		_on_parry_success(hit)
		return HitData.Result.PARRIED
	if is_invulnerable(hit.environmental):
		return HitData.Result.IGNORED
	if blocking and not hit.environmental and _faces(hit.source) and weapon and weapon.block_reduction > 0.0:
		var cost := hit.damage * 0.45 + hit.poise_damage * 0.1
		if stamina.current >= cost:
			stamina.spend(cost)
			combat_frames = COMBAT_LOCK_FRAMES
			health.take_damage(hit.damage * (1.0 - weapon.block_reduction) * damage_taken_mult * Settings.damage_taken_pct / 100.0)
			GameFeel.spark(global_position + Vector2(facing * 12, -16), Palette.BONE, 10, facing)
			GameFeel.shake(2.0, 0.12)
			velocity.x = -facing * 70.0
			if health.is_dead:
				return HitData.Result.HIT
			return HitData.Result.BLOCKED
		stamina.spend(stamina.current)  # guard broken: this one lands in full
		blocking = false
	combat_frames = COMBAT_LOCK_FRAMES
	if hit.status != &"" and status:
		status.apply(hit.status, hit.status_amount)
	health.take_damage(hit.damage * damage_taken_mult * Settings.damage_taken_pct / 100.0)
	GameFeel.spark(global_position + Vector2(0, -14), Palette.CRIMSON_BRIGHT, 12)
	GameFeel.shake(4.0, 0.22)
	GameFeel.hit_stop(0.08)
	if health.is_dead:
		return HitData.Result.HIT
	_set_state(State.HURT)
	velocity = hit.knockback
	if hit.source:
		facing = 1 if hit.source.global_position.x >= global_position.x else -1
	_iframes = post_hit_iframes
	return HitData.Result.HIT


## Frames since the last blow dealt or taken; Manor.can_travel refuses while this runs.
const COMBAT_LOCK_FRAMES := 300
var combat_frames := 0

signal focus_changed(value: float, maximum: float)
const MAX_FOCUS := 60.0
const FOCUS_PER_HIT := 6.0
const FOCUS_PER_CRIT := 10.0
const FOCUS_PER_PARRY := 16.0
var focus := 30.0
## Frames the current guard has been held past the parry window (shield weapons).
var blocking := false


func add_focus(amount: float) -> void:
	set_focus(focus + amount)


func set_focus(v: float) -> void:
	focus = clampf(v, 0.0, MAX_FOCUS)
	GameState.focus = focus
	focus_changed.emit(focus, MAX_FOCUS)


func can_use_skill() -> bool:
	return weapon != null and weapon.skill != null and focus >= weapon.skill_cost \
		and stamina.can_spend() and is_on_floor()


func _window_frames() -> int:
	return maxi(2, parry_window_frames + (weapon.parry_window_bonus if weapon else 0))


func _parry_total() -> int:
	return maxi(10, parry_total_frames + (weapon.parry_recovery_bonus if weapon else 0))
## Bleed / poison / burning / frost on the player; resistances come from armour.
var status: StatusComponent


func _try_manor_travel() -> void:
	var r := Manor.travel(self)
	if not r.ok:
		Events.message_requested.emit("The oath holds", String(r.msg))


func _faces(source: Node2D) -> bool:
	if source == null:
		return false
	var dx := source.global_position.x - global_position.x
	return absf(dx) < 6.0 or signf(dx) == float(facing)


func _on_parry_success(hit: HitData) -> void:
	_parried = true
	add_focus(FOCUS_PER_PARRY)
	state_frame = 0
	parry_flash = 18
	_iframes = maxi(_iframes, 20)
	stamina.refund(parry_stamina)
	GameFeel.hit_stop(0.12)
	GameFeel.shake(3.0, 0.15)
	var src := hit.source
	var at := global_position + Vector2(facing * 12, -16)
	if src:
		at = (global_position + src.global_position) * 0.5 + Vector2(0, -16)
	GameFeel.spark(at, Palette.GOLD_BRIGHT, 18)


func _on_attack_hit(_target: Hurtbox, result: int, hit: HitData) -> void:
	combat_frames = COMBAT_LOCK_FRAMES
	if result == HitData.Result.HIT:
		add_focus(FOCUS_PER_CRIT if hit.critical else FOCUS_PER_HIT)
		GameFeel.hit_stop(hit.hit_stop)
		GameFeel.shake(hit.shake)
	elif result == HitData.Result.BLOCKED:
		# Bounced off a shield: small recoil, the swing loses its forward lunge.
		velocity.x = -facing * 110.0
		GameFeel.shake(1.5, 0.1)
		InputPrompts.rumble(0.3, 0.0, 0.08)


## Returns a parried enemy within riposte reach in front of the player, if any.
func find_riposte_target() -> Node2D:
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if not e.has_method(&"is_riposte_ready") or not e.is_riposte_ready():
			continue
		var d: Vector2 = e.global_position - global_position
		if absf(d.x) <= riposte_reach and absf(d.y) <= 24.0 and (absf(d.x) < 10.0 or signf(d.x) == float(facing)):
			return e
	return null


func move_mult() -> float:
	return (WATER_MOVE if in_water > 0 else 1.0) * (status.speed_mult() if status else 1.0)


func _on_hazard() -> bool:
	for h in get_tree().get_nodes_in_group(&"hazards"):
		for c in h.get_children():
			if c is CollisionShape2D and c.shape is RectangleShape2D:
				var size: Vector2 = c.shape.size
				if Rect2(c.global_position - size / 2.0, size).grow(10.0).has_point(global_position):
					return true
	return false


func _on_died() -> void:
	_set_state(State.DEAD)
	_iframes = 0
	_buffer.clear()
	Events.player_died.emit()


# ------------------------------------------------------------------ world API

func is_dead() -> bool:
	return state == State.DEAD


func can_interact() -> bool:
	return state == State.FREE and is_on_floor()


## Kneel at a checkpoint: full restore.
func rest() -> void:
	health.restore_full()
	stamina.restore_full()
	flasks = max_flasks
	set_focus(MAX_FOCUS)
	Events.flasks_changed.emit(flasks, max_flasks)
	velocity = Vector2.ZERO
	_set_state(State.REST)


func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	health.restore_full()
	stamina.restore_full()
	flasks = max_flasks
	_iframes = 60
	set_focus(0.0)
	_buffer.clear()
	_set_state(State.FREE)
	Events.flasks_changed.emit(flasks, max_flasks)
	Events.player_respawned.emit(self)


func state_name() -> String:
	return State.keys()[state]
