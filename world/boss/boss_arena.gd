@tool
class_name BossArena
extends Node2D
## A boss room: a fog gate at the entrance, a trigger just inside it, and the boss.
## Origin = the bottom of the gate opening (floor level).
##
## - Walking past the gate starts the fight: the fog seals behind the player and the
##   HUD shows the boss bar.
## - If the player dies, the fight ends; on respawn (or rest) the boss is reset to full
##   health and the gate opens again (it is registered as an enemy spawner).
## - When the boss dies the gate opens for good. The defeat is a saved world flag, so a
##   beaten boss never returns. The game is autosaved immediately on victory.
## TEMPORARY ART: the fog is procedural.

@export var boss_scene: PackedScene
## Boss start position relative to this node.
@export var boss_offset := Vector2(420, 0)
## Height of the gate opening (floor up).
@export var gate_height := 96.0
## The trigger zone starts this far inside the gate and covers [member trigger_width].
@export var trigger_offset := 36.0
@export var trigger_width := 600.0
## Extra trigger height below the gate floor (arenas that drop down from their entrance).
@export var trigger_below := 0.0
@export var victory_text := "THE BELL FALLS SILENT"
## Optional: a ShiningLight appears here after victory (and stays on later visits).
@export_file("*.tscn") var light_target_level := ""
@export var light_target_entry: StringName = &"arrival"
@export var light_offset := Vector2(320, 0)
@export var light_delay := 3.0

var boss: BossBase
var fight_active := false
var _barrier: StaticBody2D
var _barrier_shape: CollisionShape2D
var _trigger: Area2D
var _t := 0.0
var _defeated := false
## Frames after a (re)spawn during which the trigger is ignored: on respawn the physics
## server can still report the player's body where it died, inside the arena.
var _arm := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"enemy_spawners")
	_barrier = StaticBody2D.new()
	_barrier.collision_layer = 1
	_barrier.collision_mask = 0
	_barrier_shape = CollisionShape2D.new()
	var bs := RectangleShape2D.new()
	bs.size = Vector2(12, gate_height)
	_barrier_shape.shape = bs
	_barrier_shape.position = Vector2(6, -gate_height / 2.0)
	_barrier.add_child(_barrier_shape)
	add_child(_barrier)
	_trigger = Area2D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = 2
	var ts := CollisionShape2D.new()
	var tr := RectangleShape2D.new()
	tr.size = Vector2(trigger_width, gate_height + trigger_below)
	ts.shape = tr
	ts.position = Vector2(trigger_offset + trigger_width / 2.0, (trigger_below - gate_height) / 2.0)
	_trigger.add_child(ts)
	add_child(_trigger)
	Events.player_died.connect(_on_player_died)
	Events.boss_fight_started.connect(_on_boss_fight_started)
	_set_sealed(false)
	spawn.call_deferred()


func _defeat_flag() -> StringName:
	return StringName("boss_defeated_" + String(_boss_id()))


func _boss_id() -> StringName:
	if boss:
		return boss.boss_id
	if boss_scene:
		var st := boss_scene.get_state()
		for i in st.get_node_property_count(0):
			if st.get_node_property_name(0, i) == &"boss_id":
				return st.get_node_property_value(0, i)
	return &"boss"


func is_defeated() -> bool:
	return GameState.get_flag(_defeat_flag(), false)


## (Re)creates the boss in its dormant state. Called on level start, rest and respawn.
func spawn() -> void:
	if fight_active:
		_end_fight(false)
	if is_instance_valid(boss):
		boss.queue_free()
	boss = null
	_set_sealed(false)
	_arm = 30
	_defeated = is_defeated()
	if _defeated:
		_spawn_light()
	if _defeated or boss_scene == null:
		return
	boss = boss_scene.instantiate() as BossBase
	boss.position = position + boss_offset
	boss.start_facing = -1
	boss.died.connect(_on_boss_died)
	get_parent().add_child.call_deferred(boss)


## Polled (not body_entered) so a player who appears inside the zone — teleport, respawn,
## a long dodge through it — still starts the fight.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or fight_active or _defeated or _trigger == null:
		return
	if _arm > 0:
		_arm -= 1
		return
	if not is_instance_valid(boss) or boss.is_dead() or not boss.is_inside_tree():
		return
	for b in _trigger.get_overlapping_bodies():
		if b is Player and not b.is_dead():
			boss.start_fight()
			return


## Single entry point for "the fight has begun" (also when the boss is struck first).
func _on_boss_fight_started(b: Node) -> void:
	if b != boss or fight_active:
		return
	fight_active = true
	_set_sealed(true)
	Events.banner_requested.emit(boss.data.display_name.to_upper())


func _on_player_died() -> void:
	if fight_active:
		_end_fight(false)


func _on_boss_died(_b: EnemyBase) -> void:
	_defeated = true
	_end_fight(true)
	Events.banner_requested.emit(victory_text)
	SaveSystem.autosave()
	if light_target_level != "":
		await get_tree().create_timer(light_delay, false).timeout
		if is_inside_tree():
			_spawn_light()


func _end_fight(victory: bool) -> void:
	fight_active = false
	_set_sealed(false)
	Events.boss_fight_ended.emit(victory)


func _set_sealed(on: bool) -> void:
	if _barrier_shape:
		_barrier_shape.set_deferred(&"disabled", not on)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() and _defeated:
		return
	# Fog wall: pale and drifting while open, deep crimson while sealed.
	var sealed := fight_active
	var base := Palette.CRIMSON_BRIGHT if sealed else Palette.BONE
	var a := 0.32 if sealed else 0.16
	for i in 14:
		var y := -gate_height + i * gate_height / 14.0
		var w := 6.0 + 4.0 * sin(_t * 2.0 + i * 0.9)
		draw_rect(Rect2(6.0 - w / 2.0, y, w, gate_height / 14.0 + 1.0), Color(base, a * (0.6 + 0.4 * sin(_t * 3.0 + i))))
	for i in 6:
		var py := -fmod(_t * 18.0 + i * 17.0, gate_height)
		draw_circle(Vector2(6.0 + sin(_t + i) * 4.0, py), 1.2, Color(base, a * 2.0))
	if Engine.is_editor_hint():
		draw_circle(boss_offset + Vector2(0, -24), 8.0, Color(0.8, 0.2, 0.2, 0.5))
		draw_rect(Rect2(trigger_offset, -gate_height, trigger_width, gate_height), Color(0.2, 0.8, 0.2, 0.3), false)


func _spawn_light() -> void:
	if light_target_level == "":
		return
	for l in get_tree().get_nodes_in_group(&"shining_light"):
		if is_instance_valid(l) and not l.is_queued_for_deletion() and get_parent().is_ancestor_of(l):
			return
	var l := ShiningLight.new()
	l.target_level = light_target_level
	l.target_entry = light_target_entry
	l.position = position + light_offset
	get_parent().add_child.call_deferred(l)
