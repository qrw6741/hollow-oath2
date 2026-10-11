class_name Mimic
extends EnemyBase
## A chest that is not a chest. Dormant it looks exactly like a TreasureChest and offers
## "Open chest"; opening it springs an unparryable ambush bite (dodge it!). Striking it
## first instead wakes it with a critical stagger — the reward for suspicion.
## The tell: every few seconds its lid lifts and it lets out a breath of ash. Real
## chests never do that. A slain mimic stays dead (world flag) and drops treasure.

## Unique id (set by the EnemySpawner) for the saved "slain" flag.
var spawn_id: StringName = &""
var dormant := true
## Seconds since the last breath (drives the tell in the visual).
var breath_t := 0.0
var _player_inside: Player
var _area: Area2D


func _ready() -> void:
	super()
	if spawn_id != &"" and GameState.get_flag(_flag(), false):
		queue_free()
		return
	breath_t = randf() * 3.0
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(_on_enter)
	_area.body_exited.connect(_on_exit)


func _on_enter(b: Node) -> void:
	if b is Player and dormant:
		_player_inside = b
		Events.interact_prompt_shown.emit("Open chest")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		if dormant:
			Events.interact_prompt_hidden.emit()


func _flag() -> StringName:
	return StringName("mimic_slain_" + String(spawn_id))


func _physics_process(delta: float) -> void:
	breath_t += delta
	super(delta)
	if dormant and _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		wake(_player_inside, true)


func _sense() -> void:
	if not dormant:
		super()


func _state_patrol(delta: float) -> void:
	if dormant:
		velocity.x = 0.0
		return
	super(delta)


## Springs to life. [param ambush] = the player tried to open it: instant bite.
func wake(p: Node2D, ambush: bool) -> void:
	if not dormant:
		return
	dormant = false
	_player_inside = null
	Events.interact_prompt_hidden.emit()
	target = p
	if p:
		facing = 1 if p.global_position.x > global_position.x else -1
	Audio.sfx_at(&"boss_roar", global_position, -6.0, 1.7)
	on_target_acquired()
	if ambush:
		_start_attack(load("res://data/attacks/mimic_ambush.tres"))
	else:
		_set_state(State.CHASE)


func receive_hit(hit: HitData) -> int:
	if dormant and state != State.DEAD:
		wake(hit.source, false)
		hit.critical = true   # caught it napping
	return super(hit)


func on_died() -> void:
	if spawn_id != &"":
		GameState.set_flag(_flag(), true)


func play_attack_sound(a: AttackData) -> void:
	Audio.sfx_at(&"enemy_windup", global_position, 0.0, 0.7 if a.animation == &"pounce" else 1.1)


func play_death_sound() -> void:
	Audio.sfx_at(&"door_open", global_position, 0.0, 0.6)
	Audio.sfx_at(&"enemy_death", global_position, -2.0, 0.6)
