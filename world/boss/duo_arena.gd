class_name DuoArena
extends BossArena
## A boss room for TWO bosses at once (the Twin Lords). Walking past the gate seals the fog and plays
## a scripted intro: the floor shakes, a colossal hand rises out of the ground, the palm opens (an eye
## in it opens too) and the two lords step out of black flame and speak. Then both fights begin.
## - The fight ends only when both are dead; when one falls the other is enraged.
## - Both defeats are saved flags (boss_defeated_<id>), so the pair never returns.
## - Victory spawns a chest holding [member reward_weapon].
## TEMPORARY ART: everything is procedural.

@export var second_scene: PackedScene
@export var second_offset := Vector2(520, 0)
@export var reward_weapon: StringName = &""
@export var reward_chest_id: StringName = &"twin_lords_reward"
@export var hand_offset := Vector2(470, 0)

var boss2: BossBase
var hand: RisingHand
var intro_running := false
var intro_done := false
var _dead_count := 0
## Bumped whenever the intro starts or the arena resets, so a stale intro coroutine stops itself.
var _intro_id := 0


func _boss_id() -> StringName:
	return _first_id(boss_scene)


func _first_id(scene: PackedScene) -> StringName:
	if scene:
		var st := scene.get_state()
		for i in st.get_node_property_count(0):
			if st.get_node_property_name(0, i) == &"boss_id":
				return st.get_node_property_value(0, i)
	return &"boss"


func is_defeated() -> bool:
	return GameState.get_flag(StringName("boss_defeated_" + String(_first_id(boss_scene))), false) \
		and GameState.get_flag(StringName("boss_defeated_" + String(_first_id(second_scene))), false)


func spawn() -> void:
	if fight_active:
		_end_fight(false)
	for b in [boss, boss2]:
		if is_instance_valid(b):
			b.queue_free()
	if is_instance_valid(hand):
		hand.queue_free()
	boss = null
	boss2 = null
	hand = null
	_intro_id += 1
	intro_running = false
	intro_done = false
	_dead_count = 0
	_set_sealed(false)
	_arm = 30
	_defeated = is_defeated()
	if _defeated:
		_spawn_reward()
		return
	boss = _make(boss_scene, boss_offset)
	boss2 = _make(second_scene, second_offset)
	hand = RisingHand.new()
	hand.position = position + hand_offset
	hand.z_index = -1
	get_parent().add_child.call_deferred(hand)
	for b in [boss, boss2]:
		if b:
			_hide(b, true)


func _make(scene: PackedScene, off: Vector2) -> BossBase:
	if scene == null:
		return null
	var b := scene.instantiate() as BossBase
	b.position = position + off
	b.start_facing = -1
	b.scripted_intro = true
	b.died.connect(_on_twin_died)
	get_parent().add_child.call_deferred(b)
	return b


## Hidden lords stay put on the floor but are invisible, cannot be hit and cannot be bumped (their
## collision layer is cleared) until the hand has opened. Physics stays ON so they do not fall.
func _hide(b: BossBase, hidden: bool) -> void:
	b.visible = not hidden
	b.collision_layer = 0 if hidden else 4
	var hb := b.get_node_or_null("Hurtbox") as Area2D
	if hb:
		hb.set_deferred(&"monitorable", not hidden)


func _set_hurtable(b: BossBase, on: bool) -> void:
	var hb := b.get_node_or_null("Hurtbox") as Area2D
	if hb:
		hb.set_deferred(&"monitorable", on)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or fight_active or intro_running or _defeated or _trigger == null:
		return
	if _arm > 0:
		_arm -= 1
		return
	if not is_instance_valid(boss) or not is_instance_valid(boss2) or not boss.is_inside_tree() or not boss2.is_inside_tree():
		return
	if boss.is_dead() and boss2.is_dead():
		return
	for b in _trigger.get_overlapping_bodies():
		if b is Player and not b.is_dead():
			_start_duo()
			return


## Either lord struck first (not through the trigger): skip straight to the fight.
func _on_boss_fight_started(b: Node) -> void:
	if (b != boss and b != boss2) or fight_active:
		return
	fight_active = true
	_set_sealed(true)


func _start_duo() -> void:
	if intro_running or fight_active:
		return
	if intro_done:
		_begin_fight()
		return
	intro_running = true
	_intro_id += 1
	_set_sealed(true)
	Events.banner_requested.emit("THE TWIN LORDS")
	_intro(_intro_id)


func _intro(id: int) -> void:
	var tree := get_tree()
	GameFeel.shake(5.0, 2.2)
	Audio.sfx_at(&"boss_stomp", global_position + hand_offset, 0.0, 0.5)
	# the hand claws up out of the floor
	var tw := create_tween()
	tw.tween_property(hand, "rise", 1.0, 2.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not _alive(id):
		return
	GameFeel.dust(global_position + hand_offset, 14)
	await tree.create_timer(0.5, false).timeout
	# the palm opens, the eye with it
	Audio.sfx_at(&"boss_roar", global_position + hand_offset, -4.0, 0.55)
	var tw2 := create_tween()
	tw2.tween_property(hand, "open", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	if not _alive(id):
		return
	GameFeel.ring(global_position + hand_offset + Vector2(0, -100), Color(0.55, 0.3, 0.9), 60.0)
	GameFeel.rise(global_position + hand_offset + Vector2(0, -110), Color(0.35, 0.2, 0.6), 30, 22.0)
	# the lords step out of black flame at either side of the hand
	for b in [boss, boss2]:
		_hide(b, false)
		_set_hurtable(b, false)
		b.global_position.x = global_position.x + hand_offset.x + (-70.0 if b == boss else 70.0)
		b.facing = 1 if b == boss else -1
		GameFeel.rise(b.global_position + Vector2(0, -10), Color(0.35, 0.2, 0.6), 18, 14.0)
	await tree.create_timer(0.8, false).timeout
	# the spoken intro (subtitles + synthesised voice)
	for i in BossLines.TWINS_INTRO.size():
		if not _alive(id):
			return
		var ln: Array = BossLines.TWINS_INTRO[i]
		Events.boss_say.emit(ln[0], ln[1], StringName("twins_intro_%d" % i))
		var secs := maxf(clampf(1.6 + String(ln[1]).length() * 0.045, 2.0, 4.5), Audio.voice_length(StringName("twins_intro_%d" % i)) + 0.3)
		await tree.create_timer(secs, false).timeout
	if not _alive(id):
		return
	# the hand sinks away and the fight begins
	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(hand, "fade", 0.0, 1.0)
	tw3.tween_property(hand, "open", 0.0, 1.0)
	intro_done = true
	intro_running = false
	_begin_fight()


func _alive(id: int) -> bool:
	if id != _intro_id:
		return false
	if not is_inside_tree() or not is_instance_valid(boss) or not is_instance_valid(boss2):
		intro_running = false
		return false
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null or p.is_dead():
		intro_running = false
		return false
	return true


func _begin_fight() -> void:
	intro_running = false
	_set_hurtable(boss, true)
	_set_hurtable(boss2, true)
	fight_active = true
	boss.start_fight()
	boss2.start_fight()
	fight_active = true
	_set_sealed(true)


func _on_player_died() -> void:
	if intro_running or fight_active:
		intro_running = false
		_end_fight(false)


func _on_twin_died(b: EnemyBase) -> void:
	_dead_count += 1
	var other: BossBase = boss2 if b == boss else boss
	if is_instance_valid(other) and not other.is_dead():
		other.enrage()
		var first_fell := b == boss   # the Reaper fell, the Gunner answers
		var line := "Brother! ...Then you answer for him." if first_fell else "Veshti! ...Then I finish this alone."
		Events.boss_say.emit(String(other.data.display_name), line, StringName("twins_enrage_%d" % (0 if first_fell else 1)))
		return
	if _dead_count >= 2:
		_defeated = true
		_end_fight(true)
		Events.banner_requested.emit(victory_text)
		SaveSystem.autosave()
		await get_tree().create_timer(2.5, false).timeout
		if is_inside_tree():
			_spawn_reward()


func _spawn_reward() -> void:
	if reward_weapon == &"" or get_parent() == null:
		return
	for c in get_parent().get_children():
		if c is TreasureChest and c.chest_id == reward_chest_id:
			return
	var c := TreasureChest.new()
	c.chest_id = reward_chest_id
	c.gear_kind = "weapon"
	c.gear_id = reward_weapon
	c.position = position + hand_offset
	get_parent().add_child.call_deferred(c)
	GameFeel.rise(c.position + Vector2(0, -10), Color(0.55, 0.3, 0.9), 30, 20.0)
