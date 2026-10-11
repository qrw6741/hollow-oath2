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
var saves: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await get_tree().physics_frame
	events = get_tree().root.get_node("Events")
	game_state = get_tree().root.get_node("GameState")
	settings = get_tree().root.get_node("Settings")
	settings.hit_stop = false
	settings.screen_shake = 0.0
	# Tests must never touch the player's real saves.
	saves = get_tree().root.get_node("SaveSystem")
	saves.save_dir = "user://test_saves"
	wipe_saves()

	var tests := [
		test_health_component, test_stamina_component, test_attack_data,
		test_player_lands_and_runs, test_jump, test_light_combo_chain, test_heavy_and_stamina,
		test_dodge_iframes, test_enemy_hits_player, test_parry_and_riposte,
		test_heal, test_heal_without_vials, test_checkpoint_rest, test_death_and_respawn,
		test_enemy_ai_engages, test_enemy_dies_and_resets, test_spike_pit, test_hit_stop_and_fx_cleanup,
		# --- saving & menus ---
		test_save_roundtrip, test_save_corruption_cases, test_save_backup_recovery,
		test_save_future_and_malformed, test_save_write_failure,
		test_autosave_on_rest, test_no_autosave_without_slot,
		test_menu_flow_end_to_end, test_death_then_quit_is_clean,
		test_menu_overwrite_confirmation, test_menu_delete, test_menu_corrupt_slot,
		test_pause_menu,
		# --- presets ---
		test_presets_valid, test_preset_stats_applied, test_unsworn_is_bare_fists,
		test_each_preset_combo_lands, test_preset_save_and_fallback, test_preset_screen_menu,
		# --- controller prompts ---
		test_input_prompts, test_menu_works_with_controller,
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
	wipe_saves()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_saves"))
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


func fresh_game(preset: StringName = &"sworn_knight") -> void:
	await _teardown()
	game_state.reset()
	game_state.preset_id = preset
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
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


# ------------------------------------------------------------------ save / menu helpers

func wipe_saves() -> void:
	for slot in range(1, 4):
		saves.delete_slot(slot)


func write_raw(slot: int, text: String, suffix := "") -> void:
	DirAccess.make_dir_recursive_absolute(saves.save_dir)
	var f := FileAccess.open(saves.slot_path(slot) + suffix, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func read_raw(slot: int, suffix := "") -> String:
	return FileAccess.get_file_as_string(saves.slot_path(slot) + suffix)


## Writes a valid save for [param slot] using the real GameState -> SaveSystem path.
func make_save(slot: int, deaths := 0, place := "Test Place") -> void:
	game_state.reset()
	game_state.deaths = deaths
	game_state.level_name = place
	game_state.play_time = 75.0
	saves.save_slot(slot)
	game_state.reset()


## Starts the real game *with* the main menu showing.
func menu_game() -> void:
	await _teardown()
	game_state.reset()
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(6)


func menu_button(path_name: String) -> Button:
	return main.menu.find_child(path_name, true, false) as Button


# ------------------------------------------------------------------ save tests

func test_save_roundtrip() -> void:
	wipe_saves()
	game_state.reset()
	game_state.deaths = 4
	game_state.play_time = 123.5
	game_state.level_name = "The Penitent's Yard"
	game_state.has_checkpoint = true
	game_state.checkpoint_id = &"yard_candle"
	game_state.respawn_position = Vector2(182.25, 480.0)
	game_state.set_flag(&"boss_1_defeated", true)
	check(saves.save_slot(2), "save succeeds")
	check(not FileAccess.file_exists(saves.slot_path(2) + ".tmp"), "no temp file left behind")
	game_state.reset()
	var r: Dictionary = saves.load_slot(2)
	check(r.status == saves.Status.OK, "loads OK")
	check(not r.recovered, "not flagged as recovered")
	check(int(r.data.saved_at) > 0, "timestamp recorded")
	game_state.apply_dict(r.data, 2)
	check(game_state.deaths == 4 and is_equal_approx(game_state.play_time, 123.5), "numbers restored")
	check(game_state.level_name == "The Penitent's Yard", "level name restored")
	check(game_state.has_checkpoint and game_state.checkpoint_id == &"yard_candle", "checkpoint restored")
	check(game_state.respawn_position == Vector2(182.25, 480.0), "respawn position restored exactly")
	check(game_state.get_flag(&"boss_1_defeated") == true and game_state.get_flag(&"nope") == false, "flags restored")
	check(game_state.current_slot == 2, "slot remembered")
	check(saves.load_slot(1).status == saves.Status.EMPTY, "other slots untouched")
	check(saves.most_recent_slot() == 2, "most recent slot found")
	wipe_saves()
	game_state.reset()


func test_save_corruption_cases() -> void:
	wipe_saves()
	make_save(1, 4)
	var good := read_raw(1)
	check(good.contains('"deaths": 4'), "test assumption: deaths line present")
	var cases := {
		"garbage text": "this is not json at all {{{",
		"empty file": "",
		"truncated": good.substr(0, good.length() / 2),
		"valid JSON, wrong shape": "[1, 2, 3]",
		"tampered value": good.replace('"deaths": 4', '"deaths": 5'),
		"missing checksum": '{"data": {"version": 1}}',
	}
	for label in cases:
		wipe_saves()
		write_raw(1, cases[label])
		var r: Dictionary = saves.load_slot(1)
		check(r.status == saves.Status.CORRUPT, "%s is reported CORRUPT (got %d)" % [label, r.status])
		check(FileAccess.file_exists(saves.slot_path(1)), "%s: damaged file is kept, not deleted" % label)
	wipe_saves()


func test_save_backup_recovery() -> void:
	wipe_saves()
	make_save(1, 1)
	make_save(1, 2)
	check(FileAccess.file_exists(saves.slot_path(1) + ".bak"), "second save keeps a backup of the first")
	var bak: Dictionary = saves._decode(read_raw(1, ".bak"))
	check(bak.status == saves.Status.OK and bak.data.deaths == 1, "backup holds the previous save")
	check(saves.load_slot(1).data.deaths == 2, "main file holds the newest save")
	# Damage the main file: the game must fall back to the backup.
	write_raw(1, "broken!!")
	var r: Dictionary = saves.load_slot(1)
	check(r.status == saves.Status.OK and r.recovered, "recovered from backup")
	check(r.data.deaths == 1, "recovered data is the backup's")
	check(FileAccess.file_exists(saves.slot_path(1) + ".corrupt"), "damaged file set aside for inspection")
	var again: Dictionary = saves.load_slot(1)
	check(again.status == saves.Status.OK and not again.recovered, "slot is healthy again afterwards")
	# Main file missing entirely (crash mid-swap): also recovered.
	DirAccess.remove_absolute(saves.slot_path(1))
	check(saves.load_slot(1).status == saves.Status.OK, "recovers when only the backup exists")
	# A damaged main file must not overwrite a good backup on the next save.
	write_raw(1, "broken again")
	game_state.reset()
	game_state.deaths = 9
	saves.save_slot(1)
	check(saves.load_slot(1).data.deaths == 9, "saving over a damaged file works")
	wipe_saves()
	game_state.reset()


func test_save_future_and_malformed() -> void:
	wipe_saves()
	# A save from a newer game build must be refused but never modified.
	var future_text: String = saves._encode({"version": 99, "deaths": 3})
	write_raw(2, future_text)
	var r: Dictionary = saves.load_slot(2)
	check(r.status == saves.Status.TOO_NEW, "newer version reported TOO_NEW")
	check(read_raw(2) == future_text, "newer save file left untouched")
	# Missing and wrongly-typed fields fall back to defaults instead of crashing.
	write_raw(3, saves._encode({
		"version": 1, "deaths": "lots", "play_time": -5, "respawn_position": [1],
		"has_checkpoint": true, "checkpoint_id": "x", "flags": 3, "level_path": 7, "level_name": null}))
	var m: Dictionary = saves.load_slot(3)
	check(m.status == saves.Status.OK, "malformed fields still load")
	check(m.data.deaths == 0 and m.data.play_time == 0.0, "bad numbers become defaults")
	check(m.data.has_checkpoint == false, "checkpoint without a valid position is dropped")
	check(m.data.flags is Dictionary and m.data.flags.is_empty(), "bad flags become empty")
	check(m.data.level_path == game_state.DEFAULT_LEVEL_PATH, "bad level path becomes default")
	# No version at all is corruption, not 'version 0'.
	write_raw(1, saves._encode({"deaths": 1}))
	check(saves.load_slot(1).status == saves.Status.CORRUPT, "missing version is CORRUPT")
	wipe_saves()


func test_save_write_failure() -> void:
	# Make the save "folder" impossible to create: its parent is a regular file.
	var blocker := "user://test_saves_blocker"
	var f := FileAccess.open(blocker, FileAccess.WRITE)
	f.store_string("x")
	f.close()
	var real_dir: String = saves.save_dir
	saves.save_dir = blocker + "/sub"
	var failed := [""]
	events.save_failed.connect(func(_s, reason): failed[0] = reason, CONNECT_ONE_SHOT)
	game_state.reset()
	game_state.deaths = 3
	check(not saves.save_slot(1), "save reports failure")
	check(failed[0] != "", "save_failed signal emitted (%s)" % failed[0])
	check(game_state.deaths == 3, "game state unaffected by a failed save")
	saves.save_dir = real_dir
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker))
	game_state.reset()


func test_autosave_on_rest() -> void:
	await fresh_game()
	wipe_saves()
	game_state.current_slot = 1
	var saved := [0]
	events.game_saved.connect(func(s): saved[0] = s, CONNECT_ONE_SHOT)
	await place_player(170.0)
	await press(&"interact")
	await frames(4)
	check(saved[0] == 1, "game_saved emitted for slot 1")
	var r: Dictionary = saves.load_slot(1)
	check(r.status == saves.Status.OK, "slot written")
	check(r.data.has_checkpoint and r.data.checkpoint_id == "yard_candle", "checkpoint is in the save")
	check(r.data.level_path == game_state.DEFAULT_LEVEL_PATH, "level path saved (%s)" % r.data.level_path)
	wipe_saves()


func test_no_autosave_without_slot() -> void:
	await fresh_game()
	wipe_saves()
	check(game_state.current_slot == 0, "dev session has no slot")
	await place_player(170.0)
	await press(&"interact")
	await frames(4)
	for slot in range(1, 4):
		check(saves.load_slot(slot).status == saves.Status.EMPTY, "slot %d still empty" % slot)


# ------------------------------------------------------------------ menu tests

func test_menu_flow_end_to_end() -> void:
	wipe_saves()
	await menu_game()
	check(main.current_level() == null, "no level while the menu is showing")
	check(main.menu.visible and not main.hud.visible, "menu visible, HUD hidden")
	check(not game_state.in_game, "not in game")
	check(menu_button("Continue").disabled, "Continue disabled with no saves")
	check(menu_button("LoadGame").disabled, "Load Game disabled with no saves")
	check(not menu_button("NewGame").disabled, "New Game available")

	# New game in slot 2.
	events.new_game_requested.emit(2, &"sworn_knight")
	await frames(100)
	level = main.current_level()
	check(level != null, "level loaded")
	if level == null:
		return
	player = level.player
	check(game_state.in_game and game_state.current_slot == 2, "session active on slot 2")
	check(saves.load_slot(2).status == saves.Status.OK, "new game wrote its slot immediately")
	check(not main.menu.visible and main.hud.visible, "menu closed, HUD shown")
	check(game_state.level_name == "The Penitent's Yard", "level name recorded")

	# Rest at the candle, die, respawn: deaths are persisted.
	await place_player(170.0)
	await press(&"interact")
	await frames(4)
	player.receive_hit(damage(500))
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 14)
	check(game_state.deaths == 1, "death counted")
	var r: Dictionary = saves.load_slot(2)
	check(r.data.deaths == 1 and r.data.checkpoint_id == "yard_candle", "death count and checkpoint saved")

	# Quit to menu: world gone, state closed.
	events.quit_to_menu_requested.emit()
	await frames(100)
	check(main.current_level() == null and not game_state.in_game, "back at the menu")
	check(main.menu.visible and not main.hud.visible, "menu visible again")
	check(not menu_button("Continue").disabled, "Continue now enabled")
	check(menu_button("Continue").has_focus(), "Continue is focused so Enter/A resumes immediately")

	# Continue: everything is restored.
	game_state.reset()   # prove the data comes from the file, not memory
	menu_button("Continue").pressed.emit()
	await frames(100)
	level = main.current_level()
	check(level != null, "continue loads the level")
	if level == null:
		return
	player = level.player
	check(player.global_position.distance_to(Vector2(182.0, 480.0)) < 12.0, "player respawns beside the candle (%s)" % player.global_position)
	check(game_state.deaths == 1 and game_state.checkpoint_id == &"yard_candle" and game_state.current_slot == 2, "state restored from file")
	check(player.health.current == 100.0 and player.flasks == player.max_flasks, "full vitals")
	check(game_state.play_time > 0.0, "play time tracked")
	wipe_saves()


func test_death_then_quit_is_clean() -> void:
	wipe_saves()
	await fresh_game()
	player.receive_hit(damage(500))
	await frames(10)
	var respawned := [false]
	events.player_respawned.connect(func(_p): respawned[0] = true)
	main.return_to_menu()
	await frames(60)
	check(not game_state.in_game and main.menu.visible, "in menu during pending respawn")
	events.new_game_requested.emit(1, &"sworn_knight")
	await frames(130)   # well past the old session's respawn timer
	check(not respawned[0], "stale respawn from the old session never fires")
	level = main.current_level()
	check(level != null and level.player.health.current == 100.0 and not level.player.is_dead(), "new session player is alive")
	check(main.hud._fade.color.a < 0.01 and main.hud._death.color.a < 0.01, "death screen did not leak into the new session")
	check(game_state.deaths == 0, "deaths reset for the new game")
	wipe_saves()


func test_menu_overwrite_confirmation() -> void:
	wipe_saves()
	make_save(1, 7, "Old Place")
	await menu_game()
	check(not menu_button("Continue").disabled, "Continue enabled")
	check(main.menu._continue_info.text.contains("Slot 1") and main.menu._continue_info.text.contains("Old Place"), "continue info (%s)" % main.menu._continue_info.text)
	main.menu._open_slots(0)   # NEW
	await frames(2)
	var rows: Array = main.menu._rows
	check(rows[0].act.text == "Overwrite" and rows[1].act.text == "Begin", "occupied slot says Overwrite, empty says Begin")
	check(rows[0].del.visible and not rows[1].del.visible, "delete only offered on occupied slots")
	var before := read_raw(1)
	rows[0].act.pressed.emit()
	await frames(30)
	check(rows[0].act.text == "Sure?", "first press asks for confirmation")
	check(main.current_level() == null and read_raw(1) == before, "nothing happened yet")
	rows[0].act.pressed.emit()
	await frames(10)
	check(main.menu.screen == main.menu.Screen.PRESET and main.current_level() == null, "slot choice opens the preset screen")
	main.menu._preset_btns[1].pressed.emit()
	await frames(100)
	check(main.current_level() != null, "choosing a preset starts the new game")
	check(game_state.preset_id == &"duelist" and saves.load_slot(1).data.preset_id == "duelist", "chosen preset stored and saved")
	check(saves.load_slot(1).data.deaths == 0, "slot was overwritten")
	wipe_saves()


func test_menu_delete() -> void:
	wipe_saves()
	make_save(3, 2)
	await menu_game()
	main.menu._open_slots(1)   # LOAD
	await frames(2)
	var rows: Array = main.menu._rows
	check(rows[0].act.disabled and not rows[2].act.disabled, "only occupied slot is loadable")
	rows[2].del.pressed.emit()
	await frames(2)
	check(rows[2].del.text == "Sure?" and FileAccess.file_exists(saves.slot_path(3)), "delete needs confirmation")
	rows[2].del.pressed.emit()
	await frames(2)
	check(not FileAccess.file_exists(saves.slot_path(3)), "second press deletes")
	check(main.menu.screen == 0, "returns to title when no saves remain")
	check(menu_button("Continue").disabled and menu_button("LoadGame").disabled, "Continue and Load disabled again")
	wipe_saves()


func test_menu_corrupt_slot() -> void:
	wipe_saves()
	write_raw(1, "garbage")
	await menu_game()
	check(menu_button("Continue").disabled, "a damaged save never offers Continue")
	check(not menu_button("LoadGame").disabled, "damaged slot still reachable to delete it")
	main.menu._open_slots(1)
	await frames(2)
	var row: Dictionary = main.menu._rows[0]
	check(row.info.text.contains("damaged"), "row explains the problem (%s)" % row.info.text)
	check(row.act.disabled and row.del.visible, "cannot load, can delete")
	# Forcing a load must fail gracefully and stay in the menu.
	events.load_game_requested.emit(1)
	await frames(60)
	check(main.current_level() == null and main.menu.visible, "stays in menu")
	check(main.menu._status.text != "", "tells the player (%s)" % main.menu._status.text)
	wipe_saves()


func test_pause_menu() -> void:
	await fresh_game()
	var pm := main.get_node("PauseMenu")
	var press_pause := func(down: bool):
		var ev := InputEventAction.new()
		ev.action = &"pause"
		ev.pressed = down
		Input.parse_input_event(ev)
	press_pause.call(true)
	press_pause.call(false)
	await frames(3)
	check(get_tree().paused, "Esc pauses during a session")
	press_pause.call(true)
	press_pause.call(false)
	await frames(3)
	check(not get_tree().paused, "Esc resumes")
	# Quit to menu needs a second press.
	pm._pause()
	pm._on_quit_to_menu()
	check(pm._menu_btn.text == "Sure?" and get_tree().paused, "quit to menu asks first")
	pm._on_quit_to_menu()
	await frames(100)
	check(not get_tree().paused, "game unpaused after quitting to menu")
	check(main.current_level() == null and main.menu.visible, "arrived at main menu")
	# Pause must be unavailable in the menu.
	press_pause.call(true)
	press_pause.call(false)
	await frames(3)
	check(not get_tree().paused, "Esc does not pause inside the main menu")
	# Volume buttons change the setting (no disk write; restored afterwards).
	var panel := SettingsPanel.new()
	get_tree().root.add_child(panel)
	var v: float = settings.master_volume
	panel._change_volume(-0.1)
	check(is_equal_approx(settings.master_volume, clampf(snappedf(v - 0.1, 0.1), 0.0, 1.0)), "volume steps down")
	settings.master_volume = v
	settings.apply_audio()
	panel.queue_free()


# ------------------------------------------------------------------ preset tests

func test_presets_valid() -> void:
	check(Presets.IDS.size() == 4, "four presets registered")
	var seen := {}
	for id in Presets.IDS:
		var pr := Presets.get_preset(id)
		check(pr != null and pr.id == id, "%s loads with matching id" % id)
		if pr == null:
			continue
		check(pr.validate().is_empty(), "%s validates (%s)" % [id, pr.validate()])
		check(pr.weapon != null and pr.weapon.light_combo_start != null, "%s has a weapon with a light combo" % id)
		check(pr.perks.size() > 0 and pr.drawbacks.size() > 0, "%s lists perks and drawbacks" % id)
		seen[pr.display_name] = true
	check(seen.size() == 4, "display names are unique")
	check(Presets.get_preset(&"nope").id == Presets.DEFAULT_ID, "unknown id falls back to default")


func test_preset_stats_applied() -> void:
	for id in Presets.IDS:
		await fresh_game(id)
		var pr := Presets.get_preset(id)
		check(player.preset == pr, "%s: player holds its preset" % id)
		check(player.health.max_health == pr.max_health and player.health.current == pr.max_health, "%s: health %.0f" % [id, player.health.current])
		check(player.stamina.max_stamina == pr.max_stamina, "%s: stamina" % id)
		check(player.flasks == pr.flasks and player.max_flasks == pr.flasks, "%s: flasks" % id)
		check(player.weapon == pr.weapon, "%s: weapon" % id)
	# Damage multiplier really changes damage taken.
	await fresh_game(&"unsworn")
	var before := player.health.current
	player.receive_hit(damage(10.0))
	check(is_equal_approx(before - player.health.current, 10.0 * Presets.get_preset(&"unsworn").damage_taken_mult), "unsworn takes multiplied damage (%.1f)" % (before - player.health.current))


func test_unsworn_is_bare_fists() -> void:
	var pr := Presets.get_preset(&"unsworn")
	check(pr.armor_look == PresetData.ArmorLook.BARE, "unsworn wears no armour")
	check(pr.weapon_look == PresetData.WeaponLook.FISTS, "unsworn fights with fists")
	check(pr.weapon.id == &"fists", "unsworn weapon is fists")
	check(pr.damage_taken_mult > 1.0, "unsworn takes extra damage (trade-off)")
	for id in Presets.IDS:
		if id != &"unsworn":
			check(Presets.get_preset(id).armor_look != PresetData.ArmorLook.BARE, "%s is armoured" % id)


func test_each_preset_combo_lands() -> void:
	for id in Presets.IDS:
		await fresh_game(id)
		await place_player(300.0, 480.0, 1)
		var dummy := level.get_node("TrainingDummy")
		var started := [0]
		player.attack_runner.started.connect(func(_a): started[0] += 1)
		for i in 3:
			await press(&"attack_light")
			await frames(9)
		await frames(60)
		check(started[0] >= 2, "%s: light chain started (%d attacks)" % [id, started[0]])
		check(dummy._combo_total > 5.0, "%s: light combo damaged the dummy (%.0f)" % [id, dummy._combo_total])
		check(player.state == Player.State.FREE, "%s: returns to FREE" % id)


func test_preset_save_and_fallback() -> void:
	wipe_saves()
	game_state.new_game(2, &"bulwark")
	game_state.in_game = true
	check(saves.save_slot(2), "save written")
	check(saves.load_slot(2).data.preset_id == "bulwark", "preset_id round-trips")
	game_state.reset()
	game_state.apply_dict(saves.load_slot(2).data, 2)
	check(game_state.preset_id == &"bulwark", "preset_id restored into GameState")
	# Hand-edited / unknown preset id and a legacy save without the field.
	var data: Dictionary = game_state.to_dict()
	data["preset_id"] = "ghost"
	data["version"] = 1
	var txt: String = saves._encode(data)
	var f := FileAccess.open(saves.slot_path(3), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	check(saves.load_slot(3).data.preset_id == "sworn_knight", "unknown preset id falls back")
	data.erase("preset_id")
	f = FileAccess.open(saves.slot_path(3), FileAccess.WRITE)
	f.store_string(saves._encode(data))
	f.close()
	check(saves.load_slot(3).data.preset_id == "sworn_knight", "legacy save without preset gets default")
	game_state.reset()
	wipe_saves()


func test_preset_screen_menu() -> void:
	wipe_saves()
	await menu_game()
	menu_button("NewGame").pressed.emit()
	await frames(2)
	main.menu._rows[0].act.pressed.emit()
	await frames(2)
	var m = main.menu
	check(m.screen == m.Screen.PRESET, "preset screen shown after slot")
	check(m._preset_btns.size() == 4, "four preset buttons")
	m._select_preset(3)
	check(m._pv_name.text == "The Unsworn" or m._pv_name.text == Presets.get_preset(&"unsworn").display_name, "detail panel shows selection")
	check(m._pv_visual.get("preset") == Presets.get_preset(&"unsworn"), "preview follows selection")
	# Esc goes back to the slot list, not the title.
	var ev := InputEventAction.new()
	ev.action = &"ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(3)
	check(m.screen == m.Screen.SLOTS, "cancel returns to slots")
	m._open_presets(1)
	m._preset_btns[3].pressed.emit()
	await frames(100)
	check(main.current_level() != null and main.current_level().player.preset.id == &"unsworn", "unsworn game starts")
	check(saves.load_slot(1).data.preset_id == "unsworn", "saved with preset")
	wipe_saves()


# ------------------------------------------------------------------ controller prompts

func test_input_prompts() -> void:
	var ip: Node = get_tree().root.get_node("InputPrompts")
	settings.pad_style = 1   # force PlayStation icons regardless of detected hardware
	ip.set_device(ip.Device.PLAYSTATION, true)
	var expect := {&"jump": "cross", &"attack_light": "square", &"attack_heavy": "triangle", &"dodge": "circle",
		&"parry": "l1", &"heal": "r1", &"interact": "dpad_up", &"pause": "options"}
	for a in expect:
		var t: Dictionary = ip.token_for(a)
		check(t.pad and t.id == expect[a], "%s -> %s on a PS pad (got %s)" % [a, expect[a], t])
	check(ip.token_for(&"move_left").pad, "movement resolves to a pad token")
	ip.set_device(ip.Device.KEYBOARD, true)
	check(not ip.token_for(&"attack_light").pad and ip.token_for(&"attack_light").id == "J", "keyboard shows J for light attack")
	# Real events switch the active device, both ways.
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_A
	jb.pressed = true
	ip._input(jb)
	check(ip.is_pad(), "pad button press switches prompts to the controller")
	var kk := InputEventKey.new()
	kk.keycode = KEY_J
	kk.pressed = true
	ip._input(kk)
	check(not ip.is_pad(), "key press switches prompts back to keyboard")
	# Every glyph kind and a hint bar build without errors in each style.
	for style in [1, 2]:
		settings.pad_style = style
		ip.set_device(ip.Device.PLAYSTATION if style == 1 else ip.Device.XBOX, true)
		var bar := HintBar.new()
		bar.spec = "attack_light:light,attack_heavy:heavy,dodge:dodge,parry:parry,heal:heal,pause:pause,dpad|Arrows:move"
		add_child(bar)
		await frames(2)
		var glyphs := bar.get_children().filter(func(n): return n is Glyph)
		check(glyphs.size() == 7 and glyphs.all(func(g): return g.visible and g.size.x > 4.0), "style %d: seven visible glyphs" % style)
		bar.queue_free()
	settings.pad_style = 0
	ip.set_device(ip.Device.KEYBOARD, true)


func test_menu_works_with_controller() -> void:
	wipe_saves()
	make_save(1, 0, "Pad Place")
	await menu_game()
	var cont := menu_button("Continue")
	check(cont.has_focus(), "Continue focused")
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await frames(100)
	check(main.current_level() != null, "Cross/A on Continue starts the game")
	# Pause with Options, move down with D-pad, confirm Settings with Cross, back with Circle.
	var pm := main.get_node("PauseMenu")
	var tap := func(btn: int):
		var e := InputEventJoypadButton.new()
		e.button_index = btn
		e.pressed = true
		Input.parse_input_event(e)
		await frames(3)
		var r := InputEventJoypadButton.new()
		r.button_index = btn
		r.pressed = false
		Input.parse_input_event(r)
		await frames(3)
	await tap.call(JOY_BUTTON_START)
	check(get_tree().paused, "Options opens the pause menu")
	await tap.call(JOY_BUTTON_DPAD_DOWN)
	await tap.call(JOY_BUTTON_A)
	check(pm._settings.visible, "Cross on Settings opens it in the pause menu")
	await tap.call(JOY_BUTTON_B)
	check(not pm._settings.visible and pm._main_page.visible, "Circle closes settings")
	check(pm._resume_btn.has_focus(), "focus back on Resume (focus: %s)" % [pm.get_viewport().gui_get_focus_owner()])
	await tap.call(JOY_BUTTON_A)   # focus returns to Resume
	check(not get_tree().paused, "Cross on Resume closes the pause menu")
	wipe_saves()
