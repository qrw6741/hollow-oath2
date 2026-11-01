class_name DuoArena
extends BossArena
## A boss room for TWO bosses at once (the Twin Lords). Walking past the gate seals the fog and plays
## a scripted intro: the floor shakes, a colossal hand rises out of the ground, the palm opens (an eye
## in it opens too) and the two lords step out of black flame and speak. Then both fights begin.
## Three cutscenes (letterbox, camera pans, name plates, title card; press X to skip any of them (controller: hold Interact)):
## the intro, a short scene when the first lord falls, and a death scene with the reward.
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
var cine: CineLayer
var _skip := false
var _scene_busy := false
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
	_cine_cleanup()
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
	b.corpse_frames = 1500   # the death scene needs the bodies to stay
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
	_intro(_intro_id)


# ------------------------------------------------------------------ cutscene helpers

func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _cine_begin() -> void:
	_skip = false
	var p := _player()
	if p:
		p.cutscene_lock = true
		p.velocity.x = 0.0
	if cine == null or not is_instance_valid(cine):
		cine = CineLayer.new()
		add_child(cine)
		cine.skip_requested.connect(func(): _skip = true)
	cine.bars(true, 0.9)
	get_tree().call_group(&"hud", "set_cinematic", true)


func _cine_end() -> void:
	get_tree().call_group(&"hud", "set_cinematic", false)
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_end(0.9)
	var p := _player()
	if p:
		p.cutscene_lock = false
	if cine and is_instance_valid(cine):
		cine.bars(false, 0.8)
		var c := cine
		get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(c): c.queue_free())
	cine = null


## Immediate cleanup (arena reset, player died): no animation.
func _cine_cleanup() -> void:
	_scene_busy = false
	if not is_inside_tree():
		return
	get_tree().call_group(&"hud", "set_cinematic", false)
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_end(0.2)
	var p := _player()
	if p:
		p.cutscene_lock = false
	if cine and is_instance_valid(cine):
		cine.queue_free()
	cine = null


func _cam(pos: Vector2, z: float, dur: float) -> void:
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_to(pos, z, 0.05 if _skip else dur)


## Waits `secs` of game time; returns at once when the player skips.
func _wait(secs: float) -> void:
	var t := 0.0
	while not _skip and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()   # game time, like the tweens and subtitles, so a slow PC never desyncs them


func _say(who: String, text: String, voice: StringName) -> void:
	if _skip:
		return
	Events.boss_say.emit(who, text, voice)
	await _wait(maxf(clampf(1.6 + text.length() * 0.045, 2.0, 4.5), Audio.voice_length(voice) + 0.3))


func _speaker(who: String) -> BossBase:
	return boss2 if who.begins_with("Veshti") else boss


func _hand_at(dy := -70.0) -> Vector2:
	return global_position + hand_offset + Vector2(0, dy)


# ------------------------------------------------------------------ 1. intro

func _intro(id: int) -> void:
	var tree := get_tree()
	_cine_begin()
	# the camera leaves the player and drifts to where the hand will rise
	_cam(_hand_at(-70.0), 1.0, 1.8)
	await _wait(1.7)
	if not _alive(id):
		return
	GameFeel.shake(5.0, 2.4)
	Audio.sfx_at(&"boss_stomp", global_position + hand_offset, 0.0, 0.5)
	_cam(_hand_at(-95.0), 1.25, 2.6)
	var tw := create_tween()
	tw.tween_property(hand, "rise", 1.0, 0.05 if _skip else 2.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await _wait(2.5)
	if not _alive(id):
		return
	hand.rise = 1.0
	GameFeel.dust(global_position + hand_offset, 14)
	await _wait(0.5)
	# the palm opens, the eye with it: the camera pushes in on it
	Audio.sfx_at(&"boss_roar", global_position + hand_offset, -4.0, 0.55)
	_cam(_hand_at(-110.0), 1.65, 1.8)
	var tw2 := create_tween()
	tw2.tween_property(hand, "open", 1.0, 0.05 if _skip else 1.6).set_trans(Tween.TRANS_SINE)
	await _wait(1.8)
	if not _alive(id):
		return
	hand.open = 1.0
	GameFeel.ring(_hand_at(-100.0), Color(0.55, 0.3, 0.9), 60.0)
	GameFeel.rise(_hand_at(-110.0), Color(0.35, 0.2, 0.6), 30, 22.0)
	# the lords step out of black flame at either side of the hand
	for b in [boss, boss2]:
		_hide(b, false)
		_set_hurtable(b, false)
		b.global_position.x = global_position.x + hand_offset.x + (-70.0 if b == boss else 70.0)
		b.facing = 1 if b == boss else -1
		GameFeel.rise(b.global_position + Vector2(0, -10), Color(0.35, 0.2, 0.6), 18, 14.0)
	await _wait(0.9)
	if not _alive(id):
		return
	# close-up on each, with a name plate
	_cam(boss.global_position + Vector2(0, -45), 1.9, 1.2)
	cine.plate("ASHKAR", "THE BLACK REAPER", 2.4)
	await _wait(2.4)
	if not _alive(id):
		return
	_cam(boss2.global_position + Vector2(0, -45), 1.9, 1.2)
	cine.plate("VESHTI", "THE FAR HAND", 2.4)
	await _wait(2.4)
	if not _alive(id):
		return
	_cam(_hand_at(-60.0), 1.15, 1.2)
	await _wait(1.2)
	# the spoken intro: the camera cuts to whoever is speaking
	for i in BossLines.TWINS_INTRO.size():
		if not _alive(id):
			return
		var ln: Array = BossLines.TWINS_INTRO[i]
		_cam(_speaker(ln[0]).global_position + Vector2(0, -42), 1.55, 0.7)
		await _say(ln[0], ln[1], StringName("twins_intro_%d" % i))
	if not _alive(id):
		return
	# the hand sinks away, the camera pulls wide, the title falls
	_cam(_hand_at(-60.0), 1.0, 1.4)
	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(hand, "fade", 0.0, 1.0)
	tw3.tween_property(hand, "open", 0.0, 1.0)
	if not _skip:
		cine.title("THE TWIN LORDS", "two hands, one oath", 2.8)
		await _wait(2.8)
	if not _alive(id):
		return
	hand.fade = 0.0
	_cine_end()
	intro_done = true
	intro_running = false
	_begin_fight()


func _alive(id: int) -> bool:
	if id != _intro_id:
		return false
	if not is_inside_tree() or not is_instance_valid(boss) or not is_instance_valid(boss2):
		intro_running = false
		_cine_cleanup()
		return false
	var p := _player()
	if p == null or p.is_dead():
		intro_running = false
		_cine_cleanup()
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
		_cine_cleanup()
		_end_fight(false)


# ------------------------------------------------------------------ 2. first lord falls, 3. both fall

func _on_twin_died(b: EnemyBase) -> void:
	_dead_count += 1
	var other: BossBase = boss2 if b == boss else boss
	if is_instance_valid(other) and not other.is_dead():
		_mid_scene(b as BossBase, other)
		return
	if _dead_count >= 2:
		_defeated = true
		_death_scene()


func _mid_scene(fallen: BossBase, other: BossBase) -> void:
	_scene_busy = true
	var reaper_fell := fallen == boss
	await get_tree().create_timer(0.7, false).timeout   # let the killing blow land
	if not is_inside_tree() or not is_instance_valid(other) or other.is_dead():
		_scene_busy = false
		if is_instance_valid(other) and other.is_dead() and _dead_count >= 2:
			_death_scene()
		return
	other.set_physics_process(false)
	other.velocity = Vector2.ZERO
	_cine_begin()
	cine.bars(true, 0.5)
	_cam(fallen.global_position + Vector2(0, -30), 1.7, 0.9)
	await _wait(1.3)
	await _wait(0.9)   # the fallen lord's own last words play first
	_cam(other.global_position + Vector2(0, -42), 1.9, 0.9)
	await _wait(1.6)
	var ln: Array = BossLines.TWINS_MID[0 if reaper_fell else 1]
	await _say(ln[0], ln[1], StringName("twins_mid_%d" % (0 if reaper_fell else 1)))
	var line := "Brother! ...Then you answer for him." if reaper_fell else "Veshti! ...Then I finish this alone."
	await _say(String(other.data.display_name), line, StringName("twins_enrage_%d" % (0 if reaper_fell else 1)))
	if is_instance_valid(other):
		other.set_physics_process(true)
		if not other.is_dead():
			other.enrage()
			GameFeel.ring(other.global_position + Vector2(0, -30), Color(0.55, 0.3, 0.9), 50.0)
			GameFeel.shake(4.0, 0.4)
	_cine_end()
	_scene_busy = false
	if _dead_count >= 2 and not _defeated:
		_defeated = true
		_death_scene()


func _death_scene() -> void:
	while _scene_busy:
		await get_tree().process_frame
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree():
		return
	_end_fight(true)
	SaveSystem.autosave()
	_cine_begin()
	var mid := global_position + hand_offset
	_cam(mid + Vector2(0, -50), 1.2, 1.5)
	await _wait(1.8)
	# black flame lifts off the fallen
	for b in [boss, boss2]:
		if is_instance_valid(b):
			GameFeel.rise(b.global_position + Vector2(0, -16), Color(0.35, 0.2, 0.6), 24, 16.0)
	# the hand comes back for them
	hand.fade = 1.0
	hand.open = 0.0
	hand.rise = 0.0
	GameFeel.shake(4.0, 1.8)
	Audio.sfx_at(&"boss_stomp", mid, 0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(hand, "rise", 1.0, 0.05 if _skip else 2.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_cam(_hand_at(-90.0), 1.3, 2.0)
	await _wait(2.1)
	hand.rise = 1.0
	var tw2 := create_tween()
	tw2.tween_property(hand, "open", 1.0, 0.05 if _skip else 1.3)
	await _wait(1.4)
	hand.open = 1.0
	# their last words, camera on each
	for i in BossLines.TWINS_END.size():
		var ln: Array = BossLines.TWINS_END[i]
		var who: BossBase = _speaker(ln[0])
		if is_instance_valid(who):
			_cam(who.global_position + Vector2(0, -22), 1.6, 0.8)
		await _say(ln[0], ln[1], StringName("twins_end_%d" % i))
	# the bodies dissolve into the palm; the weapon is left in it
	for b in [boss, boss2]:
		if is_instance_valid(b):
			GameFeel.ring(b.global_position + Vector2(0, -20), Color(0.55, 0.3, 0.9), 44.0)
			GameFeel.rise(b.global_position + Vector2(0, -16), Color(0.55, 0.3, 0.9), 26, 18.0)
			b.queue_free()
	_cam(_hand_at(-100.0), 1.5, 1.2)
	GameFeel.shake(2.5, 0.8)
	await _wait(1.4)
	_spawn_reward()
	await _wait(1.2)
	var tw3 := create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(hand, "fade", 0.0, 1.2)
	tw3.tween_property(hand, "open", 0.0, 1.2)
	_cam(mid + Vector2(0, -60), 1.0, 1.4)
	if not _skip:
		cine.title(victory_text, "the Nightreaper is yours", 3.0)
		await _wait(3.0)
	hand.fade = 0.0
	_cine_end()
	SaveSystem.autosave()


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
