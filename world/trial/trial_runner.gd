class_name TrialRunner
extends Node2D
## Runs a Trial Ring challenge inside the arena level. Started by a TrialStone.
## Boss Rush spawns each boss in turn (restoring the player between); the Gauntlet spawns ten
## waves of ordinary enemies. Dying (or leaving) ends the run. Bosses and enemies are spawned
## straight into the ring; no arena gate, the ring walls are the arena.

signal run_started(mode: StringName)
signal run_finished(mode: StringName, success: bool)

@export var spawn_x := 760.0
@export var floor_y := 480.0

var mode: StringName = &""
var running := false
var step := 0
var elapsed := 0.0
var _alive := 0
var _gate_shape: CollisionShape2D
var _barrier: StaticBody2D


func _ready() -> void:
	_barrier = StaticBody2D.new()
	_barrier.collision_layer = 1
	_barrier.collision_mask = 0
	_gate_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 120)
	_gate_shape.shape = r
	_gate_shape.position = Vector2(0, -60)
	_gate_shape.disabled = true
	_barrier.add_child(_gate_shape)
	_barrier.position = Vector2(60, floor_y)
	add_child(_barrier)
	Events.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if running:
		elapsed += delta


func start(m: StringName) -> bool:
	if running or not Trials.unlocked():
		return false
	mode = m
	running = true
	step = 0
	elapsed = 0.0
	_gate_shape.set_deferred(&"disabled", false)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.rest()
		p._set_state(Player.State.FREE)
	Events.banner_requested.emit("BOSS RUSH" if m == &"rush" else "THE GAUNTLET")
	run_started.emit(m)
	_next.call_deferred()
	return true


func _next() -> void:
	if not running:
		return
	if mode == &"rush":
		if step >= Trials.RUSH_BOSSES.size():
			_finish(true)
			return
		var boss := (load(Trials.RUSH_BOSSES[step]) as PackedScene).instantiate() as BossBase
		boss.position = Vector2(spawn_x, floor_y)
		boss.start_facing = -1
		boss.died.connect(_on_foe_died)
		_alive = 1
		get_parent().add_child(boss)
		boss.start_fight.call_deferred()
	else:
		if step >= Trials.WAVES.size():
			_finish(true)
			return
		Events.banner_requested.emit("WAVE %d / %d" % [step + 1, Trials.WAVES.size()])
		_alive = 0
		var i := 0
		for n in Trials.WAVES[step]:
			var e := (load(Trials.E + n + ".tscn") as PackedScene).instantiate() as EnemyBase
			e.position = Vector2(spawn_x - i * 70.0, floor_y if n != "gloam_moth" else floor_y - 70.0)
			e.start_facing = -1
			e.died.connect(_on_foe_died)
			_alive += 1
			get_parent().add_child(e)
			i += 1


func _on_foe_died(_e: EnemyBase) -> void:
	if not running:
		return
	_alive -= 1
	if _alive > 0:
		return
	step += 1
	if mode == &"rush":
		Events.boss_fight_ended.emit(true)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p and not p.is_dead():
		p.health.heal(p.health.max_health * 0.4)
		p.flasks = p.max_flasks
		Events.flasks_changed.emit(p.flasks, p.max_flasks)
	await get_tree().create_timer(2.5, false).timeout
	_next()


func _finish(success: bool) -> void:
	if not running:
		return
	running = false
	_gate_shape.set_deferred(&"disabled", true)
	var res := {}
	if success:
		res = Trials.record_rush(elapsed) if mode == &"rush" else Trials.record_gauntlet(Trials.WAVES.size(), true)
		var txt := "TRIAL COMPLETE"
		if mode == &"rush":
			txt += "   %s" % Trials.fmt_time(elapsed)
		if int(res.get("reward", 0)) > 0:
			txt += "   +%d embers" % int(res.reward)
		Events.banner_requested.emit(txt)
		Audio.sting(&"victory")
	run_finished.emit(mode, success)


func _on_player_died() -> void:
	if not running:
		return
	if mode == &"gauntlet":
		Trials.record_gauntlet(step, false)
	if mode == &"rush":
		Events.boss_fight_ended.emit(false)
	running = false
	_gate_shape.set_deferred(&"disabled", true)
	for n in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"bosses"):
		if is_instance_valid(n) and n != self:
			n.queue_free()
	run_finished.emit(mode, false)
