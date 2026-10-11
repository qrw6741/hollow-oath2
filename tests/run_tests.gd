extends Node
## Automated gameplay test suite. Runs the real game scenes headlessly with
## simulated input at a fixed 60 fps.
##
##   godot --headless --path . --fixed-fps 60 res://tests/run_tests.tscn
##
## Exit code 0 = all passed, 1 = failures.

var _passed := 0
var _failed: Array[String] = []
var _current := ""
var main: Node
var level: Level
var player: Player
var events: Node
var game_state: Node
var settings: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await get_tree().physics_frame
	events = get_tree().root.get_node("Events")
	game_state = get_tree().root.get_node("GameState")
	settings = get_tree().root.get_node("Settings")
	settings.hit_stop = false
	settings.screen_shake = 0.0

	var tests := [
		test_health_component, test_stamina_component, test_attack_data,
		test_player_lands_and_runs, test_jump, test_light_combo_chain, test_heavy_and_stamina,
		test_dodge_iframes, test_enemy_hits_player, test_parry_and_riposte,
		test_heal, test_heal_without_vials, test_checkpoint_rest, test_death_and_respawn,
		test_enemy_ai_engages, test_enemy_dies_and_resets, test_spike_pit, test_hit_stop_and_fx_cleanup,
	]
	for t: Callable in tests:
		_current = t.get_method()
		var before := _failed.size()
		await t.call()
		if _failed.size() == before:
			_passed += 1
			print("  PASS  ", _current)
		else:
			print("  FAIL  ", _current)
	await _teardown()
	print("\n%d passed, %d failed" % [_passed, _failed.size()])
	for f in _failed:
		print("   - ", f)
	get_tree().quit(0 if _failed.is_empty() else 1)


# ------------------------------------------------------------------ helpers

func check(cond: bool, msg: String) -> void:
	if not cond:
		_failed.append("%s: %s" % [_current, msg])
		push_error("%s: %s" % [_current, msg])


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func press(action: StringName, hold := 2) -> void:
	await get_tree().physics_frame
	Input.action_press(action)
	await frames(hold)
	Input.action_release(action)


func _teardown() -> void:
	for a in InputMap.get_actions():
		Input.action_release(a)
	if main:
		main.queue_free()
		main = null
		await frames(2)


func fresh_game() -> void:
	await _teardown()
	game_state.reset()
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(6)
	level = main.current_level()
	player = level.player


## Moves the player to x on the arena floor and waits for it to settle.
func place_player(x: float, y := 480.0, facing := 1) -> void:
	player.global_position = Vector2(x, y)
	player.velocity = Vector2.ZERO
	player.facing = facing
	await frames(4)


func enemies() -> Array:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(e): return not e.is_queued_for_deletion())


func spawn_enemy(x: float, facing := -1) -> EnemyBase:
	var e: EnemyBase = load("res://actors/enemies/hollow_penitent.tscn").instantiate()
	e.position = Vector2(x, 480)
	e.start_facing = facing
	e.patrol_distance = 0.0
	level.add_child(e)
	await frames(3)
	return e


func damage(amount: float) -> HitData:
	var h := HitData.make(amount, null, Vector2.ZERO)
	h.parryable = false
	return h


# ------------------------------------------------------------------ unit tests

func test_health_component() -> void:
	var h := HealthComponent.new()
	h.max_health = 100.0
	get_tree().root.add_child(h)
	var died_count := [0]
	h.died.connect(func(): died_count[0] += 1)
	check(h.take_damage(30) == 30.0 and h.current == 70.0, "damage applied")
	check(h.heal(50) == 30.0 and h.current == 100.0, "heal capped at max")
	h.take_damage(500)
	h.take_damage(10)
	check(h.is_dead and h.current == 0.0, "dies at zero")
	check(died_count[0] == 1, "died emitted exactly once")
	check(h.heal(10) == 0.0, "cannot heal while dead")
	h.restore_full()
	check(not h.is_dead and h.current == 100.0, "restore_full revives")
	h.queue_free()


func test_stamina_component() -> void:
	var s := StaminaComponent.new()
	get_tree().root.add_child(s)
	await get_tree().physics_frame
	check(s.spend(30) and is_equal_approx(s.current, 70.0), "spend")
	s.spend(500)
	check(s.current == 0.0 and not s.can_spend(), "overdraw clamps to zero and blocks")
	await frames(30)
	check(s.current == 0.0, "exhausted delay holds regen")
	await frames(90)
	check(s.current > 0.0, "regen resumes after delay")
	s.queue_free()


func test_attack_data() -> void:
	var dir := DirAccess.open("res://data/attacks")
	check(dir != null, "attack dir exists")
	var count := 0
	for f in dir.get_files():
		if not f.ends_with(".tres"):
			continue
		var a := load("res://data/attacks/" + f) as AttackData
		check(a != null, "%s loads as AttackData" % f)
		if a:
			count += 1
			var problems := a.validate()
			check(problems.is_empty(), "%s valid: %s" % [f, ", ".join(problems)])
	check(count >= 8, "found attack definitions")
	var w := load("res://data/weapons/oathblade.tres") as WeaponData
	check(w and w.light_combo_start and w.heavy and w.aerial and w.riposte, "oathblade complete")
	var e := load("res://data/enemies/hollow_penitent.tres") as EnemyData
	check(e and e.attacks.size() == 2 and e.attacks.all(func(x): return x is AttackData), "penitent attacks load")


# ------------------------------------------------------------------ movement

func test_player_lands_and_runs() -> void:
	await fresh_game()
	await frames(30)
	check(player.is_on_floor(), "player lands on floor")
	var x0 := player.global_position.x
	Input.action_press(&"move_right")
	await frames(30)
	Input.action_release(&"move_right")
	check(player.global_position.x - x0 > 40.0, "runs right (moved %.1f)" % (player.global_position.x - x0))
	check(player.facing == 1, "faces right")
	Input.action_press(&"move_left")
	await frames(12)
	Input.action_release(&"move_left")
	check(player.facing == -1, "turns left")


func test_jump() -> void:
	await fresh_game()
	await place_player(250.0)
	var y0 := player.global_position.y
	await press(&"jump", 20)
	var peak := player.global_position.y
	check(y0 - peak > 30.0, "full jump rises (%.1f px)" % (y0 - peak))
	await frames(60)
	check(player.is_on_floor(), "lands after jump")
	# Short hop: tap the button.
	y0 = player.global_position.y
	var min_y := y0
	await press(&"jump", 2)
	for i in 30:
		await get_tree().physics_frame
		min_y = minf(min_y, player.global_position.y)
	check(y0 - min_y < 30.0 and y0 - min_y > 5.0, "tap gives a short hop (%.1f px)" % (y0 - min_y))


# ------------------------------------------------------------------ combat

func test_light_combo_chain() -> void:
	await fresh_game()
	await place_player(300.0, 480.0, 1)  # dummy at x=330
	var dummy := level.get_node("TrainingDummy")
	var ids: Array[StringName] = []
	player.attack_runner.started.connect(func(a): ids.append(a.id))
	for i in 3:
		await press(&"attack_light")
		await frames(9)
	await frames(50)
	check(ids.size() >= 3, "three attacks started (%s)" % [ids])
	if ids.size() >= 3:
		check(ids[0] == &"oathblade_light_1" and ids[1] == &"oathblade_light_2" and ids[2] == &"oathblade_light_3", "combo order 1-2-3 (%s)" % [ids])
	check(dummy._combo_total >= 12.0 + 13.0 + 20.0 - 0.1, "all combo hits landed on dummy (%.0f)" % dummy._combo_total)
	check(player.state == Player.State.FREE, "returns to FREE after combo")


func test_heavy_and_stamina() -> void:
	await fresh_game()
	await place_player(300.0, 480.0, 1)
	var dummy := level.get_node("TrainingDummy")
	var st0 := player.stamina.current
	await press(&"attack_heavy")
	await frames(12)
	check(player.stamina.current < st0 - 20.0, "heavy costs stamina")
	await frames(40)
	check(dummy._combo_total >= 32.0, "heavy hits dummy (%.0f)" % dummy._combo_total)
	# Drain stamina: attacks are refused at zero.
	await frames(20)
	check(player.state == Player.State.FREE, "heavy finished")
	player.stamina.spend(1000.0)
	await press(&"attack_light")
	await frames(2)
	check(player.state != Player.State.ATTACK, "no attack with empty stamina")


func test_dodge_iframes() -> void:
	await fresh_game()
	await place_player(250.0)
	var hp := player.health.current
	await press(&"dodge")
	await frames(4)
	check(player.state == Player.State.DODGE, "dodge started")
	check(player.receive_hit(damage(30)) == HitData.Result.IGNORED, "hit during i-frames ignored")
	check(player.health.current == hp, "no damage during i-frames")
	check(player.global_position.x > 255.0, "dodge moves the player")
	await frames(30)
	check(player.state == Player.State.FREE, "dodge ends")
	check(player.receive_hit(damage(30)) == HitData.Result.HIT and player.health.current == hp - 30.0, "hit after dodge lands")


func test_enemy_hits_player() -> void:
	await fresh_game()
	await place_player(400.0, 480.0, 1)
	var e := await spawn_enemy(428.0, -1)
	e._start_attack(load("res://data/attacks/penitent_overhead.tres"))
	await frames(40)
	check(player.health.current < 100.0, "enemy overhead damaged the player (hp %.0f)" % player.health.current)
	e.queue_free()


func test_parry_and_riposte() -> void:
	await fresh_game()
	await place_player(400.0, 480.0, 1)
	var e := await spawn_enemy(426.0, -1)
	var atk: AttackData = load("res://data/attacks/penitent_overhead.tres")
	e._start_attack(atk)
	# Active frames start at startup+1 (frame 29). Press parry so the window covers it.
	while e.attack_runner.frame < atk.startup_frames - 4:
		await get_tree().physics_frame
	await press(&"parry")
	await frames(10)
	check(e.state == EnemyBase.State.PARRIED, "enemy is parried (state %s)" % e.state_name())
	check(player.health.current == 100.0, "parry negates damage")
	check(e.is_riposte_ready(), "riposte window open")
	var hp := e.health.current
	await press(&"attack_light")
	await frames(20)
	check(hp - e.health.current >= 60.0, "riposte deals critical damage (%.0f)" % (hp - e.health.current))
	check(e.state != EnemyBase.State.PARRIED, "riposte ends the parried state")
	e.queue_free()


func test_heal() -> void:
	await fresh_game()
	await place_player(250.0)
	player.receive_hit(damage(60))
	await frames(60)
	check(player.health.current == 40.0, "took damage")
	await press(&"heal")
	await frames(10)
	check(player.state == Player.State.HEAL, "healing animation playing")
	check(player.health.current == 40.0, "heal not applied before its frame")
	await frames(40)
	check(is_equal_approx(player.health.current, 85.0), "vial restored health (%.0f)" % player.health.current)
	check(player.flasks == player.max_flasks - 1, "one vial consumed")


func test_heal_without_vials() -> void:
	await fresh_game()
	await place_player(250.0)
	player.flasks = 0
	player.receive_hit(damage(20))
	await frames(60)
	await press(&"heal")
	await frames(5)
	check(player.state != Player.State.HEAL, "cannot heal with zero vials")


func test_checkpoint_rest() -> void:
	await fresh_game()
	await place_player(170.0)
	player.flasks = 0
	player.receive_hit(damage(50))
	await frames(60)
	await press(&"interact")
	await frames(3)
	check(game_state.has_checkpoint and game_state.checkpoint_id == &"yard_candle", "checkpoint registered")
	check(player.health.current == 100.0 and player.flasks == player.max_flasks, "rest restores health and vials")
	check(player.state == Player.State.REST, "player kneels")


func test_death_and_respawn() -> void:
	await fresh_game()
	await place_player(170.0)
	await press(&"interact")   # rest -> respawn point next to the candle
	await frames(60)
	await place_player(700.0)
	var first_enemy: EnemyBase = level.get_node("Penitent1").enemy
	var died := [false]
	events.player_died.connect(func(): died[0] = true, CONNECT_ONE_SHOT)
	player.receive_hit(damage(500))
	await frames(2)
	check(died[0] and player.state == Player.State.DEAD, "player dies")
	check(player.receive_hit(damage(10)) == HitData.Result.IGNORED, "dead player ignores hits")
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 10)
	check(player.state != Player.State.DEAD, "player respawned")
	check(player.health.current == 100.0 and player.flasks == player.max_flasks, "respawn restores vitals")
	check(player.global_position.distance_to(game_state.respawn_position) < 8.0, "respawned at checkpoint")
	check(not is_instance_valid(first_enemy) or first_enemy.is_queued_for_deletion(), "old enemy instance removed")
	var new_enemy = level.get_node("Penitent1").enemy
	check(is_instance_valid(new_enemy) and new_enemy != first_enemy, "enemy re-spawned")
	check(game_state.deaths == 1, "death counted")


func test_enemy_ai_engages() -> void:
	await fresh_game()
	var e: EnemyBase = level.get_node("Penitent1").enemy
	await place_player(e.global_position.x - 90.0, 480.0, 1)
	var attacked := [false]
	e.attack_runner.started.connect(func(_a): attacked[0] = true)
	var chased := false
	for i in 300:
		await get_tree().physics_frame
		if e.state == EnemyBase.State.CHASE:
			chased = true
		if attacked[0]:
			break
	check(chased, "enemy detects and chases")
	check(attacked[0], "enemy attacks when in range")


func test_enemy_dies_and_resets() -> void:
	await fresh_game()
	var spawner: EnemySpawner = level.get_node("Penitent1")
	var e: EnemyBase = spawner.enemy
	var killed := [false]
	events.enemy_killed.connect(func(_x): killed[0] = true, CONNECT_ONE_SHOT)
	var h := damage(1000)
	e.receive_hit(h)
	await frames(2)
	check(killed[0] and e.is_dead(), "enemy dies")
	check(not e.hurtbox.enabled, "dead enemy hurtbox disabled")
	await frames(100)
	check(not is_instance_valid(e), "corpse removed after fade")
	level.reset_enemies()
	await frames(2)
	check(is_instance_valid(spawner.enemy) and not spawner.enemy.is_dead(), "reset revives enemy")


func test_spike_pit() -> void:
	await fresh_game()
	var hits := [0]
	player.health.damaged.connect(func(_a): hits[0] += 1)
	await place_player(588.0, 500.0)
	await frames(20)
	check(hits[0] == 1, "spikes hit exactly once (%d)" % hits[0])
	check(player.health.current == 80.0, "spike damage applied")


func test_hit_stop_and_fx_cleanup() -> void:
	await fresh_game()
	settings.hit_stop = true
	await place_player(300.0, 480.0, 1)
	var slowed := false
	await press(&"attack_light")
	for i in 20:
		await get_tree().physics_frame
		if Engine.time_scale < 1.0:
			slowed = true
	settings.hit_stop = false
	check(slowed, "hit-stop slowed time on impact")
	await frames(60)
	check(Engine.time_scale == 1.0, "time scale restored")
	var fx := main.get_node("World/FX")
	check(fx.get_child_count() == 0, "hit FX freed (%d left)" % fx.get_child_count())
