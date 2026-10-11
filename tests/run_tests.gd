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
	settings.candle_menu_on_rest = false   # menu has its own test; others must not pause on rest
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
		# --- economy & inventory ---
		test_items_valid, test_ember_reward_and_drop_roll, test_ember_drop_and_recover, test_level_up,
		test_inventory_rules, test_item_pickup_persists, test_economy_save_roundtrip, test_candle_and_inventory_menus,
		# --- boss ---
		test_boss_data_valid, test_boss_dormant_until_gate, test_boss_fight_seals_gate, test_boss_attacks_player,
		test_boss_parry_riposte, test_boss_phase_two_and_leap, test_boss_resets_on_player_death, test_boss_defeat_persists,
		# --- audio ---
		test_audio_files_and_music_flow,
		# --- village & transitions ---
		test_levels_wired_correctly, test_bell_door_and_travel, test_respawn_across_levels, test_continue_in_village,
		test_shortcut_gate, test_acolyte_projectile_parry_dodge, test_bell_bearer,
		# --- catacombs, second boss, map ---
		test_catacombs_travel_and_water, test_drown_shaft_kills, test_breakable_wall, test_canon_boss,
		test_map_exploration_and_screen, test_prologue_ending,
		# --- equipment screen ---
		test_equipment_screen,
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


## Sends a real input event (unlike press(), which only sets polled state), so
## _unhandled_input handlers see it.
func tap_action(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await frames(3)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await frames(2)


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
	panel._change_volume("master_volume", -0.1)
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
	await tap.call(JOY_BUTTON_DPAD_DOWN)
	await tap.call(JOY_BUTTON_DPAD_DOWN)   # Resume, Inventory, Map, Settings
	await tap.call(JOY_BUTTON_A)
	check(pm._settings.visible, "Cross on Settings opens it in the pause menu")
	await tap.call(JOY_BUTTON_B)
	check(not pm._settings.visible and pm._main_page.visible, "Circle closes settings")
	check(pm._resume_btn.has_focus(), "focus back on Resume (focus: %s)" % [pm.get_viewport().gui_get_focus_owner()])
	await tap.call(JOY_BUTTON_A)   # focus returns to Resume
	check(not get_tree().paused, "Cross on Resume closes the pause menu")
	wipe_saves()


# ------------------------------------------------------------------ economy & inventory tests

func test_items_valid() -> void:
	for id in Items.IDS:
		var it := Items.get_item(id)
		check(it != null and it.id == id, "%s loads with matching id" % id)
		if it:
			check(it.validate().is_empty(), "%s validates (%s)" % [id, it.validate()])
	check(Items.get_item(&"nope") == null, "unknown item id gives null")
	var pen: EnemyData = load("res://data/enemies/hollow_penitent.tres")
	check(pen.ember_reward > 0, "penitent awards embers")


func test_ember_reward_and_drop_roll() -> void:
	await fresh_game()
	var e: EnemyBase = level.get_node("Penitent1").enemy
	var reward: int = e.data.ember_reward
	e.receive_hit(damage(1000))
	await frames(3)
	check(game_state.embers == reward, "kill awards %d embers (got %d)" % [reward, game_state.embers])
	# Guaranteed drop path.
	var d: EnemyData = e.data.duplicate()
	d.drop_chance = 1.0
	d.drop_item = Items.get_item(&"ash_bandage")
	d.drop_count = 2
	var e2: EnemyBase = level.get_node("Penitent2").enemy
	e2.data = d
	e2.receive_hit(damage(1000))
	await frames(3)
	check(game_state.item_count(&"ash_bandage") == 2, "guaranteed drop lands in the pack")
	check(game_state.embers == reward * 2, "second kill adds embers")


func test_ember_drop_and_recover() -> void:
	await fresh_game()
	await place_player(170.0)
	await press(&"interact")
	await frames(60)
	await place_player(700.0)
	game_state.embers = 0
	game_state.add_embers(250)
	player.receive_hit(damage(500))
	await frames(3)
	check(game_state.embers == 0, "carried embers are lost on death")
	check(int(game_state.ember_drop.get("amount", 0)) == 250, "drop remembers the amount")
	check(absf(float(game_state.ember_drop.x) - 700.0) < 30.0, "drop is where the player fell (%s)" % game_state.ember_drop)
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 10)
	var rems := get_tree().get_nodes_in_group(&"ember_remnant").filter(func(r): return not r.is_queued_for_deletion())
	check(rems.size() == 1, "one remnant after respawn")
	# Dying again before recovering destroys the older stain.
	game_state.add_embers(30)
	await place_player(900.0)
	await frames(70)   # respawn invulnerability must run out
	player.receive_hit(damage(500))
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 12)
	check(int(game_state.ember_drop.get("amount", 0)) == 30, "second death replaces the stain (%s)" % game_state.ember_drop)
	rems = get_tree().get_nodes_in_group(&"ember_remnant").filter(func(r): return not r.is_queued_for_deletion())
	check(rems.size() == 1, "still exactly one remnant")
	# Walk into it.
	var rx: float = rems[0].global_position.x
	await place_player(rx - 2.0)
	await frames(40)   # a fresh stain arms after ~30 frames
	check(game_state.embers == 30 and game_state.ember_drop.is_empty(), "touching the remnant restores embers (%d)" % game_state.embers)
	rems = get_tree().get_nodes_in_group(&"ember_remnant").filter(func(r): return not r.is_queued_for_deletion())
	check(rems.is_empty(), "remnant is consumed")


func test_level_up() -> void:
	await fresh_game()
	check(game_state.level() == 1 and game_state.level_cost() == 60, "level 1 costs 60")
	check(not game_state.buy_stat("vigor"), "cannot buy without embers")
	game_state.add_embers(500)
	var hp0 := player.health.max_health
	check(game_state.buy_stat("vigor"), "buy vigor")
	player.apply_stats(true)
	check(game_state.level() == 2 and game_state.embers == 440, "level 2, 60 spent")
	check(player.health.max_health == hp0 + 8.0 and player.health.current == player.health.max_health, "vigor +8 health, gained health granted")
	check(game_state.level_cost() > 60, "next level costs more (%d)" % game_state.level_cost())
	var sta0 := player.stamina.max_stamina
	game_state.buy_stat("endurance")
	game_state.buy_stat("strength")
	player.apply_stats(true)
	check(player.stamina.max_stamina == sta0 + 6.0, "endurance +6 stamina")
	check(is_equal_approx(player.attack_runner.damage_bonus, 1.04), "strength +4% damage")
	check(not game_state.buy_stat("bogus"), "unknown stat rejected")
	# Strength really changes damage on the dummy.
	await place_player(300.0, 480.0, 1)
	var dummy := level.get_node("TrainingDummy")
	await press(&"attack_light")
	await frames(40)
	check(dummy._combo_total > 0.0 and absf(dummy._combo_total - 12.0 * 1.04) < 0.2, "light hit deals boosted damage (%.2f)" % dummy._combo_total)


func test_inventory_rules() -> void:
	await fresh_game()
	check(game_state.add_item(&"ash_bandage", 3) == 3 and game_state.item_count(&"ash_bandage") == 3, "add items")
	check(game_state.quick_item == &"ash_bandage", "first usable item becomes the quick item")
	check(game_state.add_item(&"ash_bandage", 20) == 6, "stack capped at max (9)")
	check(game_state.add_item(&"nope", 1) == 0, "unknown item rejected")
	check(not game_state.remove_item(&"ash_bandage", 99), "cannot remove more than carried")
	# Using at full health does nothing and keeps the item.
	check(not Items.use(&"ash_bandage", player) and game_state.item_count(&"ash_bandage") == 9, "no use at full health")
	player.health.take_damage(50.0)
	var before := player.health.current
	check(Items.use(&"ash_bandage", player), "bandage used when hurt")
	check(player.health.current == before + 30.0 and game_state.item_count(&"ash_bandage") == 8, "heals 30 and consumes one")
	game_state.add_item(&"ember_shard", 1)
	var e0: int = game_state.embers
	check(Items.use(&"ember_shard", player) and game_state.embers == e0 + 120, "ember shard grants embers")
	game_state.add_item(&"rusted_key", 1)
	check(not Items.use(&"rusted_key", player), "key items are not usable")
	# Quick-use key.
	player.health.take_damage(40.0)
	var cnt: int = game_state.item_count(&"ash_bandage")
	await press(&"use_item")
	await frames(3)
	check(game_state.item_count(&"ash_bandage") == cnt - 1, "quick-use input consumes the quick item")
	# Dead players cannot use items.
	player.health.take_damage(1000.0)
	await frames(2)
	check(not Items.use(&"ash_bandage", player), "no item use while dead")


func test_item_pickup_persists() -> void:
	await fresh_game()
	var pk: ItemPickup = level.get_node("PickupBandages")
	check(pk.take(), "take pickup")
	check(game_state.item_count(&"ash_bandage") == 2, "pack has the bandages")
	check(game_state.get_flag(&"pickup_yard_bandages", false), "taken flag set")
	# Reload the level with the same game state: the pickup must stay gone.
	var data: Dictionary = game_state.to_dict()
	await _teardown()
	game_state.apply_dict(saves._normalize(data), 0)
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(6)
	level = main.current_level()
	check(not level.has_node("PickupBandages") or level.get_node("PickupBandages").is_queued_for_deletion(), "taken pickup does not return")
	check(game_state.item_count(&"ash_bandage") == 2, "items survived the reload")
	check(level.has_node("PickupShard") and not level.get_node("PickupShard").is_queued_for_deletion(), "untaken pickup is still there")


func test_economy_save_roundtrip() -> void:
	wipe_saves()
	game_state.reset()
	game_state.preset_id = &"duelist"
	game_state.embers = 321
	game_state.ember_drop = {"level_id": "test_arena", "x": 412.5, "y": 480.0, "amount": 99}
	game_state.stats = {"vigor": 2, "endurance": 1, "strength": 3}
	game_state.add_item(&"ash_bandage", 4)
	game_state.add_item(&"rusted_key", 1)
	game_state.quick_item = &"ash_bandage"
	game_state.in_game = true
	game_state.current_slot = 2
	check(saves.save_slot(2), "saved")
	game_state.reset()
	var r: Dictionary = saves.load_slot(2)
	check(r.status == saves.Status.OK, "loads")
	game_state.apply_dict(r.data, 2)
	check(game_state.embers == 321 and game_state.ember_drop.amount == 99 and is_equal_approx(float(game_state.ember_drop.x), 412.5), "embers and stain restored")
	check(game_state.stats.vigor == 2 and game_state.stats.endurance == 1 and game_state.stats.strength == 3 and game_state.level() == 7, "stats restored")
	check(game_state.item_count(&"ash_bandage") == 4 and game_state.item_count(&"rusted_key") == 1 and game_state.quick_item == &"ash_bandage", "pack restored")
	# Hostile / damaged values are cleaned, never crash.
	var bad := {"version": 1, "saved_at": 1, "embers": -50, "ember_drop": {"amount": "lots"},
		"stats": {"vigor": 9999, "endurance": "x"}, "inventory": {"ash_bandage": 500, "ghost_item": 3, "ember_shard": -2}, "quick_item": "ghost_item"}
	var n: Dictionary = saves._normalize(bad)
	check(n.embers == 0 and n.ember_drop.is_empty(), "negative embers / bad drop cleaned")
	check(n.stats.vigor == 99 and n.stats.endurance == 0, "stats clamped")
	check(n.inventory.size() == 1 and n.inventory.ash_bandage == 9, "inventory: unknown dropped, stack capped (%s)" % n.inventory)
	check(n.quick_item == "", "quick item must be carried")
	# A save from before this feature still loads with defaults.
	var old := {"version": 1, "saved_at": 1, "deaths": 2}
	var o: Dictionary = saves._normalize(old)
	check(o.embers == 0 and o.inventory.is_empty() and o.stats.vigor == 0, "legacy save gets economy defaults")
	game_state.reset()
	wipe_saves()


func test_candle_and_inventory_menus() -> void:
	await fresh_game()
	settings.candle_menu_on_rest = true
	game_state.add_embers(400)
	game_state.add_item(&"ash_bandage", 2)
	await place_player(170.0)
	await press(&"interact")
	await frames(70)
	var cm: CandleMenu = main.get_node("CandleMenu")
	var im: InventoryMenu = main.get_node("InventoryMenu")
	check(cm.is_open and get_tree().paused and game_state.ui_modal, "candle menu opens after resting and pauses")
	var hp0 := player.health.max_health
	cm._rows["vigor"].pressed.emit()
	await frames(2)
	check(game_state.level() == 2 and player.health.max_health == hp0 + 8.0, "buying vigor in the menu applies it")
	check(game_state.embers == 340, "cost deducted (%d)" % game_state.embers)
	# Open the pack from the candle menu, close it, and we are back in the candle menu still paused.
	cm._inv_btn.pressed.emit()
	await frames(3)
	check(im.is_open and get_tree().paused, "pack opens over the candle menu")
	check(im._list.get_child_count() >= 1, "pack lists the bandages")
	im.close()
	await frames(2)
	check(not im.is_open and cm.is_open and get_tree().paused and game_state.ui_modal, "closing the pack returns to the candle menu")
	cm.close()
	await frames(2)
	check(not get_tree().paused and not game_state.ui_modal, "leaving unpauses")
	# Pack from gameplay with the Inventory action.
	await tap_action(&"inventory")
	check(im.is_open and get_tree().paused, "inventory action opens the pack")
	await tap_action(&"inventory")
	check(not im.is_open and not get_tree().paused, "inventory action closes it and unpauses")
	settings.candle_menu_on_rest = false


# ------------------------------------------------------------------ boss tests

func arena() -> BossArena:
	return level.get_node("BellWardenArena") as BossArena


## Puts the player inside the arena (past the trigger) and waits for the fight to start.
func enter_boss_arena(x := 1990.0) -> BossBase:
	await place_player(x, 448.0, 1)
	await frames(36)   # the trigger arms 30 frames after the boss spawns
	return arena().boss


func test_boss_data_valid() -> void:
	for id in ["warden_smash", "warden_sweep", "warden_backhand", "warden_charge", "warden_leap", "warden_toll", "warden_toll_2", "warden_toll_3"]:
		var a: AttackData = load("res://data/attacks/%s.tres" % id)
		check(a != null and a.validate().is_empty(), "%s valid (%s)" % [id, a.validate() if a else "missing"])
	check(not load("res://data/attacks/warden_charge.tres").parryable and not load("res://data/attacks/warden_leap.tres").parryable, "charge and leap are unparryable")
	check(load("res://data/attacks/warden_smash.tres").parryable, "smash is parryable")
	var b: BossBase = load("res://actors/bosses/bell_warden.tscn").instantiate()
	check(b.boss_id == &"bell_warden" and b.phase2_attacks.size() >= 3, "boss scene configured")
	check(b.data.ember_reward >= 1000 and b.data.drop_item != null and b.data.drop_chance == 1.0, "boss reward configured")
	b.free()


func test_boss_dormant_until_gate() -> void:
	await fresh_game()
	await frames(4)
	var boss := arena().boss
	check(is_instance_valid(boss) and not boss.active, "boss spawned dormant")
	var x0 := boss.global_position.x
	await place_player(1700.0, 448.0, 1)
	await frames(90)
	check(not boss.active and not arena().fight_active, "boss ignores a player outside the gate")
	check(absf(boss.global_position.x - x0) < 2.0, "dormant boss stays put")
	check(not main.hud._boss_box.visible, "no boss bar outside the fight")


func test_boss_fight_seals_gate() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena()
	check(arena().fight_active and boss.active, "walking in starts the fight")
	check(not arena()._barrier_shape.disabled, "fog gate seals")
	check(main.hud._boss_box.visible and main.hud._boss_name.text == "The Bell-Warden", "boss bar shown with name")
	# Try to run back out through the gate.
	Input.action_press(&"move_left")
	await frames(90)
	Input.action_release(&"move_left")
	check(player.global_position.x > 1900.0, "cannot leave through the sealed gate (x %.0f)" % player.global_position.x)


func test_boss_attacks_player() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena(2260.0)
	var hit := [false]
	player.health.damaged.connect(func(_a): hit[0] = true)
	for i in 400:
		if hit[0]:
			break
		await get_tree().physics_frame
	check(hit[0], "the boss lands an attack on an idle player")
	check(boss.state != EnemyBase.State.IDLE or hit[0], "boss engaged")


func test_boss_parry_riposte() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena(2290.0)
	boss._cooldown = 9999
	await frames(2)
	player.facing = 1
	boss.facing = -1
	var atk: AttackData = load("res://data/attacks/warden_smash.tres")
	boss._start_attack(atk)
	while boss.attack_runner.frame < atk.startup_frames - 4:
		await get_tree().physics_frame
	await press(&"parry")
	await frames(10)
	check(boss.state == EnemyBase.State.PARRIED, "smash can be parried (state %s)" % boss.state_name())
	check(player.health.current == player.health.max_health, "parry negates the smash")
	check(boss.is_riposte_ready(), "riposte window open on the boss")
	var hp := boss.health.current
	await press(&"attack_light")
	await frames(24)
	check(hp - boss.health.current >= 60.0, "riposte hits the boss hard (%.0f)" % (hp - boss.health.current))


func test_boss_phase_two_and_leap() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena(2150.0)
	boss._cooldown = 9999
	var speed1: float = boss.data.chase_speed
	var h := damage(boss.health.max_health * 0.52)
	h.poise_damage = 0.0
	boss.receive_hit(h)
	await frames(2)
	check(boss.phase == 2 and boss.roaring, "below half health the boss roars into phase 2")
	check(boss.data.attacks.any(func(a): return a.id == &"warden_leap"), "phase 2 adds the leap")
	check(boss.data.chase_speed > speed1, "phase 2 is faster")
	await frames(boss.roar_frames + 4)
	check(not boss.roaring, "roar ends")
	# Leap at a player 140px away: it must leave the ground and land near the player.
	boss._cooldown = 9999
	await place_player(boss.global_position.x - 140.0, 448.0, 1)
	boss.facing = -1
	var hp := player.health.current
	var left_ground := [false]
	boss._start_attack(load("res://data/attacks/warden_leap.tres"))
	for i in 90:
		if boss.leaping and boss.global_position.y < 440.0:
			left_ground[0] = true
		await get_tree().physics_frame
	check(left_ground[0], "leap leaves the ground")
	check(absf(boss.global_position.x - player.global_position.x) < 48.0, "leap lands on the player (dx %.0f)" % (boss.global_position.x - player.global_position.x))
	check(player.health.current < hp, "landing shockwave hurts")


func test_boss_resets_on_player_death() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena()
	boss.receive_hit(damage(200.0))
	player.receive_hit(damage(9999.0))
	await frames(4)
	check(not arena().fight_active, "fight ends when the player dies")
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 20)
	var fresh := arena().boss
	check(is_instance_valid(fresh) and fresh != boss, "boss recreated on respawn")
	check(fresh.health.current == fresh.health.max_health and not fresh.active and fresh.phase == 1, "boss back to full, dormant, phase 1")
	check(arena()._barrier_shape.disabled, "gate open again")
	await frames(60)
	check(not main.hud._boss_box.visible, "boss bar hidden after the reset")


func test_boss_defeat_persists() -> void:
	await fresh_game()
	await frames(4)
	var boss := await enter_boss_arena()
	var e0: int = game_state.embers
	boss.receive_hit(damage(99999.0))
	await frames(4)
	check(boss.is_dead(), "boss dies")
	check(game_state.get_flag(&"boss_defeated_bell_warden", false), "defeat flag saved")
	check(game_state.embers == e0 + 1500, "boss embers awarded (%d)" % (game_state.embers - e0))
	check(game_state.item_count(&"warden_bell_shard") == 1, "boss drops its bell shard")
	check(not arena().fight_active and arena()._barrier_shape.disabled, "gate opens on victory")
	await frames(30)
	level.reset_enemies()   # what resting does
	await frames(4)
	check(not is_instance_valid(arena().boss), "a beaten boss never respawns")
	# Through a save round trip too.
	var data: Dictionary = game_state.to_dict()
	await _teardown()
	game_state.apply_dict(saves._normalize(data), 0)
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(8)
	level = main.current_level()
	check(not is_instance_valid(arena().boss), "beaten boss absent after reload")


# ------------------------------------------------------------------ audio

## Every sound name used in code must exist as a file; music loops; tracks follow the game.
func test_audio_files_and_music_flow() -> void:
	var audio: Node = get_tree().root.get_node("Audio")
	var re := RegEx.new()
	re.compile("(sfx|sfx_at|sting|music)\\(&\"([a-z0-9_]+)\"")
	var used := {}
	for dir in ["res://actors", "res://autoload", "res://ui", "res://world", "res://main"]:
		for f in _gd_files(dir):
			for m in re.search_all(FileAccess.get_file_as_string(f)):
				used[m.get_string(2)] = m.get_string(1)
	check(used.size() >= 25, "found the sound calls in code (%d)" % used.size())
	for sname in used:
		var folder := "music" if used[sname] == "music" else "sfx"
		check(ResourceLoader.exists("res://assets/audio/%s/%s.ogg" % [folder, sname]), "sound file exists: %s/%s" % [folder, sname])
	for track in [&"menu", &"yard", &"boss"]:
		var st: AudioStreamOggVorbis = audio._stream(audio.MUSIC_DIR, track, true)
		check(st != null and st.loop and st.get_length() > 20.0, "%s loops" % track)
	# Music follows the game.
	await fresh_game()
	await frames(4)
	check(audio.current_music == &"yard", "level plays its music (%s)" % audio.current_music)
	await enter_boss_arena()
	check(audio.current_music == &"boss", "boss fight switches to boss music")
	arena().boss.receive_hit(damage(99999.0))
	await frames(4)
	check(audio.current_music == &"", "victory silences the music for the sting")
	await menu_game()
	check(audio.current_music == &"menu", "menu music in the main menu")
	# Volume settings reach the buses.
	var mv: float = settings.music_volume
	settings.music_volume = 0.5
	settings.apply_audio()
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.5)), "music volume applied to the Music bus")
	settings.music_volume = mv
	settings.apply_audio()


func _gd_files(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_gd_files(dir.path_join(sub)))
	return out


# ------------------------------------------------------------------ village & transitions

const YARD := "res://world/levels/test_arena.tscn"
const VILLAGE := "res://world/levels/forsaken_village.tscn"


func go_to_level(path: String, entry: StringName) -> void:
	events.level_change_requested.emit(path, entry, false)
	await frames(75)
	level = main.current_level()
	player = level.player


func _scene_nodes(path: String) -> Array:
	var inst: Node = load(path).instantiate()
	var out := [inst]
	var stack := [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			out.append(c)
			stack.append(c)
	return out


## Every exit leads to an existing level and an entry marker that exists there; pickup,
## door, gate and candle ids are unique across the game.
func test_levels_wired_correctly() -> void:
	var ids := {}
	for path in WorldMap.LEVELS:
		var nodes := _scene_nodes(path)
		var root: Node = nodes[0]
		check(root is Level, "%s is a Level" % path)
		for n in nodes:
			if n is LevelExit and n.target_level != "":
				check(ResourceLoader.exists(n.target_level), "%s: exit %s target exists" % [path, n.name])
				var found := false
				var tn := _scene_nodes(n.target_level)
				for m in tn:
					if m is LevelEntry and m.entry_id == n.target_entry:
						found = true
				tn[0].free()
				check(found, "%s: exit %s lands on entry '%s'" % [path, n.name, n.target_entry])
			var key := ""
			if n is ItemPickup:
				key = "pickup:" + String(n.pickup_id)
			elif n is OathCandle:
				key = "candle:" + String(n.checkpoint_id)
			elif n is ShortcutGate:
				key = "gate:" + String(n.gate_id)
			elif n is LevelExit and n.door_id != &"":
				key = "door:" + String(n.door_id)
			if key != "":
				check(not ids.has(key), "unique id %s" % key)
				ids[key] = true
			if n is EnemySpawner:
				check(n.enemy_scene != null, "%s: spawner %s has a scene" % [path, n.name])
		root.free()
	var v := _scene_nodes(VILLAGE)
	var kinds := {}
	for n in v:
		if n is EnemySpawner:
			kinds[n.enemy_scene.resource_path.get_file()] = true
	check(kinds.has("ember_acolyte.tscn") and kinds.has("bell_bearer.tscn"), "village has both new enemy types")
	v[0].free()


func test_bell_door_and_travel() -> void:
	await fresh_game()
	game_state.set_flag(&"boss_defeated_bell_warden", true)
	level.reset_enemies()
	await place_player(2510.0, 448.0, 1)
	var door: LevelExit = level.get_node("BellDoor")
	check(not door.try_open(), "Bell Door is locked without the shard")
	check(main.current_level().level_id == &"test_arena", "still in the yard")
	game_state.add_item(&"warden_bell_shard", 1)
	check(door.try_open(), "the shard opens the Bell Door")
	await frames(75)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"forsaken_village", "arrived in the Forsaken Village")
	check(absf(player.global_position.x - 92.0) < 6.0, "at the entry marker (%.0f)" % player.global_position.x)
	check(game_state.level_path == VILLAGE, "level path recorded")
	check(game_state.get_flag(&"door_open_bell_door", false), "door remembered as unlocked")
	# Walk back out to the left: the Yard, at the Bell Door.
	Input.action_press(&"move_left")
	await frames(40)
	Input.action_release(&"move_left")
	await frames(75)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"test_arena", "walked back to the Yard")
	check(absf(player.global_position.x - 2490.0) < 8.0, "arrived at the Bell Door (%.0f)" % player.global_position.x)
	check(level.get_node("BellDoor").is_unlocked(), "door stays unlocked")


func test_respawn_across_levels() -> void:
	await fresh_game()
	await place_player(170.0)
	await press(&"interact")   # rest at the Yard Candle
	await frames(60)
	await go_to_level(VILLAGE, &"from_yard")
	check(level.level_id == &"forsaken_village", "in the village")
	await place_player(400.0)
	player.receive_hit(damage(9999.0))
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 90)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"test_arena", "death returns you to the level of your last candle")
	check(player.global_position.distance_to(game_state.respawn_position) < 8.0 and not player.is_dead(), "respawned at the Yard Candle")
	await frames(60)
	check(main.hud._death.color.a < 0.05 and main.hud._fade.color.a < 0.05, "death screen cleared after a cross-level respawn")
	# Rest in the village, die there: respawn in the village.
	await go_to_level(VILLAGE, &"from_yard")
	await place_player(2510.0)
	await press(&"interact")   # Chapel Steps Candle
	await frames(60)
	check(game_state.checkpoint_level == VILLAGE, "village candle recorded")
	await frames(70)
	player.receive_hit(damage(9999.0))
	await frames(int(game_state.RESPAWN_DELAY * 60.0) + 30)
	level = main.current_level()
	check(level.level_id == &"forsaken_village" and level.player.global_position.distance_to(game_state.respawn_position) < 8.0, "respawned at the village candle")


func test_continue_in_village() -> void:
	wipe_saves()
	game_state.reset()
	game_state.level_path = VILLAGE
	game_state.level_entry = &"from_yard"
	game_state.in_game = true
	game_state.current_slot = 1
	check(saves.save_slot(1), "saved in the village")
	await menu_game()
	events.load_game_requested.emit(1)
	await frames(80)
	level = main.current_level()
	check(level != null and level.level_id == &"forsaken_village", "Continue loads the village")
	check(absf(level.player.global_position.x - 92.0) < 6.0, "at the village entry")
	# A legacy save (no checkpoint_level) keeps working.
	var n: Dictionary = saves._normalize({"version": 1, "saved_at": 1, "has_checkpoint": true, "checkpoint_id": "yard_candle", "respawn_position": [182, 480]})
	check(n.checkpoint_level == "" and n.level_entry == "", "legacy save gets empty travel fields")
	wipe_saves()


func test_shortcut_gate() -> void:
	await fresh_game()
	await go_to_level(VILLAGE, &"from_yard")
	var gate: ShortcutGate = level.get_node("ShortcutGate")
	check(not gate.is_open, "gate starts shut")
	await place_player(600.0)
	check(not gate.interact(player), "cannot raise it from the outskirts side")
	# Try to walk through it.
	Input.action_press(&"move_right")
	await frames(40)
	Input.action_release(&"move_right")
	check(player.global_position.x < 660.0, "the shut gate blocks the passage (x %.0f)" % player.global_position.x)
	await place_player(700.0)
	check(gate.interact(player), "raised from the corridor side")
	check(game_state.get_flag(&"gate_open_village_corridor", false), "shortcut remembered")
	await frames(4)
	await place_player(620.0, 480.0, 1)
	Input.action_press(&"move_right")
	await frames(40)
	Input.action_release(&"move_right")
	check(player.global_position.x > 680.0, "open gate lets you through (x %.0f)" % player.global_position.x)
	# Reload: stays open.
	await go_to_level(VILLAGE, &"from_yard")
	check(level.get_node("ShortcutGate").is_open, "gate still open after reloading the level")


func test_acolyte_projectile_parry_dodge() -> void:
	await fresh_game()
	await place_player(300.0, 480.0, 1)
	var a: EnemyBase = load("res://actors/enemies/ember_acolyte.tscn").instantiate()
	a.position = Vector2(450, 480)
	a.start_facing = -1
	a.patrol_distance = 0.0
	level.add_child(a)
	await frames(3)
	check(a is RangedEnemy, "acolyte uses the ranged brain")
	a.target = player
	a._cooldown = 9999
	a.facing = -1
	var hp := player.health.current
	a._start_attack(load("res://data/attacks/acolyte_throw.tres"))
	await frames(40)
	check(get_tree().get_nodes_in_group(&"projectiles").size() >= 1, "the throw launches a projectile")
	await frames(60)
	check(player.health.current < hp, "burning wax hurts (%.0f)" % (hp - player.health.current))
	# Parry: a projectile arriving during the parry window is deflected.
	# (Remove the acolyte first so its next throw cannot interfere with the timing.)
	a.queue_free()
	for q in get_tree().get_nodes_in_group(&"projectiles"):
		q.queue_free()
	await frames(90)
	player.health.restore_full()
	var h := HitData.make(18.0, null, Vector2(-80, -40))
	var p := Projectile.spawn(level, player.global_position + Vector2(22, -16), Vector2(-170, 0), h, null)
	player.facing = 1
	await press(&"parry")
	await frames(20)
	check(player.health.current == player.health.max_health, "parried projectile does no damage")
	check(not is_instance_valid(p), "parried projectile is destroyed")
	# Dodge: i-frames let it pass through.
	await frames(40)
	await press(&"dodge")
	while not player.is_dodge_invulnerable():
		await get_tree().physics_frame
	var p2 := Projectile.spawn(level, player.global_position + Vector2(6, -16), Vector2(-170, 0), h, null)
	await frames(8)
	check(player.health.current == player.health.max_health, "dodging through takes no damage")
	check(is_instance_valid(p2) and p2.global_position.x < player.global_position.x + 10.0, "projectile flies on past a dodging player")


func test_bell_bearer() -> void:
	await fresh_game()
	await place_player(400.0, 480.0, 1)
	var b: EnemyBase = load("res://actors/enemies/bell_bearer.tscn").instantiate()
	b.position = Vector2(440, 480)
	b.start_facing = -1
	b.patrol_distance = 0.0
	level.add_child(b)
	await frames(3)
	b.target = player
	b._cooldown = 9999
	# A light hit does not stagger it (high poise).
	var h := damage(12.0)
	h.poise_damage = 12.0
	b.receive_hit(h)
	check(b.state != EnemyBase.State.STAGGER, "one light hit does not stagger a Bell-Bearer")
	# The chain swing cannot be parried.
	await frames(10)
	b.facing = -1
	var atk: AttackData = load("res://data/attacks/bearer_swing.tres")
	check(not atk.parryable, "chain swing is unparryable")
	var hp := player.health.current
	b._start_attack(atk)
	while b.attack_runner.frame < atk.startup_frames - 4:
		await get_tree().physics_frame
	await press(&"parry")
	await frames(14)
	check(player.health.current < hp, "parrying the chain swing does not help (hp %.0f)" % player.health.current)
	b.queue_free()


# ------------------------------------------------------------------ catacombs, Drowned Canon, map

const CATACOMBS := "res://world/levels/drowned_catacombs.tscn"


func test_catacombs_travel_and_water() -> void:
	await fresh_game()
	await go_to_level(VILLAGE, &"from_yard")
	await place_player(3300.0, 400.0, 1)
	var door: LevelExit = level.get_node("ChapelDoor")
	check(door.try_open(), "the chapel door opens")
	await frames(75)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"drowned_catacombs", "arrived in the Drowned Catacombs")
	check(player.global_position.distance_to(Vector2(90, 240)) < 8.0, "at the chapel entry (%s)" % player.global_position)
	# Water slows running (enemies removed so nothing interrupts the run).
	for e in enemies():
		e.queue_free()
	await place_player(1300.0, 660.0, 1)
	await frames(10)
	check(player.in_water > 0, "standing in the flooded nave counts as water")
	Input.action_press(&"move_right")
	await frames(40)
	var wet_speed := absf(player.velocity.x)
	Input.action_release(&"move_right")
	check(wet_speed < player.run_speed * 0.7 and wet_speed > 10.0, "wading is slower (%.0f vs %.0f)" % [wet_speed, player.run_speed])
	await place_player(400.0, 240.0, 1)
	await frames(6)
	check(player.in_water == 0, "dry on the ossuary stair")
	# Walking out the left edge returns to the village chapel.
	await place_player(70.0, 240.0, -1)
	Input.action_press(&"move_left")
	await frames(30)
	Input.action_release(&"move_left")
	await frames(75)
	level = main.current_level()
	check(level.level_id == &"forsaken_village" and absf(level.player.global_position.x - 3372.0) < 8.0, "back at the chapel door")


func test_drown_shaft_kills() -> void:
	await fresh_game()
	await go_to_level(CATACOMBS, &"from_chapel")
	await place_player(1732.0, 600.0, 1)
	player.global_position = Vector2(1732, 760)   # inside the shaft
	await frames(6)
	check(player.is_dead(), "falling into the drowned shaft is death")


func test_breakable_wall() -> void:
	await fresh_game()
	await go_to_level(CATACOMBS, &"from_chapel")
	var wall: BreakableWall = level.get_node("CrackedWall")
	await place_player(2170.0, 660.0, 1)
	for i in 3:
		await press(&"attack_light")
		await frames(30)
	await frames(4)
	check(not is_instance_valid(wall), "three hits break the cracked wall")
	check(game_state.get_flag(&"wall_broken_canon_alcove", false), "broken wall remembered")
	await go_to_level(CATACOMBS, &"from_chapel")
	check(not level.has_node("CrackedWall") or level.get_node("CrackedWall").is_queued_for_deletion(), "stays broken after reloading")


func test_canon_boss() -> void:
	await fresh_game()
	await go_to_level(CATACOMBS, &"from_chapel")
	await place_player(2560.0, 720.0, 1)
	await frames(40)
	var ar: BossArena = level.get_node("CanonArena")
	var boss := ar.boss as DrownedCanon
	check(boss != null and ar.fight_active and boss.active, "dropping into the choir starts the Canon fight")
	check(get_tree().root.get_node("Audio").current_music == &"boss" and is_equal_approx(get_tree().root.get_node("Audio").current_pitch, 0.82), "boss theme, slowed")
	boss._cooldown = 99999
	await frames(2)
	# Undertow: invulnerable while under, surfaces under the player.
	player.global_position = Vector2(2700, 720)
	await frames(4)
	var hp := player.health.current
	boss._start_attack(load("res://data/attacks/canon_submerge.tres"))
	await frames(boss.sink_frame + 4)
	check(boss.submerged and not boss.hurtbox.enabled, "submerged boss cannot be hit")
	await frames(20)
	check(absf(boss.global_position.x - 2700.0) < 4.0, "it moves under the player (%.0f)" % boss.global_position.x)
	await frames(50)
	check(not boss.submerged and boss.hurtbox.enabled, "surfaces and can be hit again")
	check(player.health.current < hp, "the geyser hurts a player who stayed on the bubbles")
	# Spit fires a fan of three.
	await frames(60)
	for q in get_tree().get_nodes_in_group(&"projectiles"):
		q.queue_free()
	await frames(2)
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/canon_spit.tres"))
	await frames(34)
	check(get_tree().get_nodes_in_group(&"projectiles").size() == 3, "Bile Hymn spits three")
	# Phase 2 adds the floor wave; the wave is unparryable and rolls toward the player.
	await frames(60)
	var h := damage(boss.health.max_health * 0.55)
	h.poise_damage = 0.0
	boss.receive_hit(h)
	await frames(boss.roar_frames + 6)
	check(boss.phase == 2 and boss.data.attacks.any(func(a): return a.id == &"canon_wave"), "phase 2 adds Flood Psalm")
	boss._cooldown = 99999   # the roar resets it; keep the boss to the scripted attack
	for q in get_tree().get_nodes_in_group(&"projectiles"):
		q.queue_free()
	player.health.restore_full()
	await place_player(boss.global_position.x - 160.0, 720.0, 1)
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/canon_wave.tres"))
	await frames(45)
	var waves := get_tree().get_nodes_in_group(&"projectiles").filter(func(q): return q.kind == &"wave")
	check(waves.size() == 1 and waves[0].velocity.x < 0.0, "a wave rolls toward the player")
	if waves.size() == 1:
		var w: Projectile = waves[0]
		while is_instance_valid(w) and w.global_position.x - player.global_position.x > 56.0:
			await get_tree().physics_frame
		await press(&"jump", 24)   # hold for a full jump (a tap is a short hop)
	await frames(60)
	check(player.health.current == player.health.max_health, "jumping over the wave avoids it (hp %.0f)" % player.health.current)
	# Victory.
	var e0: int = game_state.embers
	boss.receive_hit(damage(99999.0))
	await frames(4)
	check(game_state.get_flag(&"boss_defeated_drowned_canon", false) and game_state.item_count(&"canon_seal") == 1, "Canon defeated: flag + seal")
	check(game_state.embers - e0 == 2600, "2600 embers")


func test_map_exploration_and_screen() -> void:
	await fresh_game()
	await place_player(300.0, 480.0, 1)
	await frames(20)
	var seen: Dictionary = game_state.explored.get("test_arena", {})
	check(seen.has(WorldMap.cell_key(4, 7)), "walking reveals map cells around the player")
	check(not seen.has(WorldMap.cell_key(30, 7)), "far parts stay unexplored")
	# Persistence.
	var n: Dictionary = saves._normalize(game_state.to_dict())
	check((n.explored.test_arena as Array).size() == seen.size(), "explored cells are saved")
	var bad: Dictionary = saves._normalize({"version": 1, "saved_at": 1, "explored": {"x": [1, "a", -5, 3.0], "y": "nope"}})
	check(bad.explored.x == [1, 3] and not bad.explored.has("y"), "bad exploration data is cleaned (%s)" % bad.explored)
	# Map data for every level.
	for d in WorldMap.all():
		check(d.blocks.size() > 5 and d.candles.size() >= 1 and d.name != "", "%s map data read" % d.path)
	# Doors line up across levels on the world map.
	var yard := WorldMap.info(YARD)
	var vil := WorldMap.info(VILLAGE)
	var door_g: Vector2 = yard.origin + Vector2(2530, 448)
	var entry_g: Vector2 = vil.origin + Vector2(92, 480)
	check(door_g.distance_to(entry_g) < 64.0, "Yard and Village meet on the map (%s vs %s)" % [door_g, entry_g])
	# The screen opens, pauses, closes.
	var m: MapMenu = main.get_node("MapMenu")
	await tap_action(&"map")
	check(m.is_open and get_tree().paused, "Map button opens the map and pauses")
	check(m.player_map_position().distance_to(Vector2(300, 480)) < 4.0, "player marker at the right place")
	check((m._rects[YARD].blocks as Array).size() > 0, "explored geometry is drawn")
	await tap_action(&"map")
	check(not m.is_open and not get_tree().paused, "Map button closes it again")
	# Candle rest lights its icon.
	await place_player(170.0)
	await press(&"interact")
	await frames(60)
	check(game_state.get_flag(&"candle_lit_yard_candle", false), "resting marks the candle on the map")


func test_prologue_ending() -> void:
	await fresh_game()
	await go_to_level(CATACOMBS, &"from_chapel")
	var ar: BossArena = level.get_node("CanonArena")
	check(get_tree().get_nodes_in_group(&"shining_light").is_empty(), "no light before the Canon falls")
	await place_player(2600.0, 720.0, 1)
	await frames(40)
	ar.boss.receive_hit(damage(99999.0))
	await frames(int(ar.light_delay * 60.0) + 20)
	var lights := get_tree().get_nodes_in_group(&"shining_light")
	check(lights.size() == 1, "a shining light appears after the victory")
	if lights.is_empty():
		return
	# Walk into it.
	await place_player(lights[0].global_position.x - 40.0, 720.0, 1)
	Input.action_press(&"move_right")
	await frames(50)
	Input.action_release(&"move_right")
	await frames(60 * 5)
	level = main.current_level()
	check(level.level_id == &"vaelmoor_awake", "the light carries you to the true Vaelmoor")
	check(level.player.global_position.distance_to(Vector2(220, 480)) < 8.0, "arrive at the arrival point")
	await frames(60 * 5)
	check(game_state.get_flag(&"prologue_complete", false), "prologue marked complete")
	check(main._fade.color.a < 0.05, "white fade cleared")
	# The light stays for later visits.
	await go_to_level(CATACOMBS, &"from_chapel")
	await frames(4)
	check(get_tree().get_nodes_in_group(&"shining_light").size() == 1, "the light is still there when you return")
	# The stone can be read.
	await go_to_level("res://world/levels/vaelmoor_awake.tscn", &"arrival")
	await place_player(700.0, 460.0, 1)
	await frames(6)
	await press(&"interact")
	await frames(4)
	check(main.hud._msg_panel.visible and main.hud._msg_title.text == "The Waking Stone", "the Waking Stone can be read")
	await place_player(1200.0, 460.0, 1)
	await frames(6)
	check(not main.hud._msg_panel.visible, "walking away closes the text")


func test_equipment_screen() -> void:
	for id in Presets.IDS:
		var pr := Presets.get_preset(id)
		check(pr.armor_name != "" and pr.armor_description != "", "%s has an armour name and description" % id)
	var ob: WeaponData = load("res://data/weapons/oathblade.tres")
	var s := WeaponStats.summary(ob, 1.0)
	check(s.light == [12, 13, 20] and s.light_total == 45, "Oathblade light combo 12/13/20 (%s)" % [s.light])
	var s3 := WeaponStats.summary(ob, 1.12)
	check(s3.light == [13, 15, 22], "Strength scales the shown damage (%s)" % [s3.light])
	check(WeaponStats.summary(load("res://data/weapons/fists.tres"), 1.0).light.size() == 4, "fists show a four-hit combo")
	game_state.reset()
	game_state.preset_id = &"unsworn"
	await fresh_game(&"unsworn")
	game_state.stats = {"vigor": 1, "endurance": 0, "strength": 0}
	var im: InventoryMenu = main.get_node("InventoryMenu")
	await tap_action(&"inventory")
	check(im.is_open and im.tab == InventoryMenu.Tab.EQUIPMENT, "inventory opens on the equipment tab")
	check(im._slots.weapon.icon_id == &"fists" and im._slots.armour.icon_id == &"armor_unsworn", "slots show the equipped weapon and armour icons")
	im._slots.weapon.grab_focus()
	await frames(2)
	check(im._d_title.text == "Bare Hands", "selecting the weapon slot names it")
	im._slots.armour.grab_focus()
	await frames(2)
	check(im._d_title.text == "Bone-cloth Wraps", "selecting the armour slot names it")
	for id in Items.IDS + [&"oathblade", &"twin_blades", &"sword_and_shield", &"fists", &"armor_sworn_knight", &"armor_duelist", &"armor_bulwark", &"armor_unsworn", &"status"]:
		check(IconArt.has_icon(id), "icon exists for %s" % id)
	check(im._preview.get("preset") == Presets.get_preset(&"unsworn"), "character preview shows your preset")
	im._slots.armour.grab_focus()
	await frames(2)
	var texts := im._d_grid.get_children().map(func(n): return n.text)
	check(texts.has("Damage taken") and texts.any(func(t): return t.begins_with("130%")), "armour details show damage taken (%s)" % [texts])
	im._slots.status.grab_focus()
	await frames(2)
	texts = im._d_grid.get_children().map(func(n): return n.text)
	check(im._d_sub.text.contains("Level 2") and texts.has("Vigor"), "status shows level and attributes")
	await tap_action(&"heal")
	check(im.tab == InventoryMenu.Tab.ITEMS and im._pages[1].visible and not im._pages[0].visible, "R1 / heal switches to the items tab")
	await tap_action(&"parry")
	check(im.tab == InventoryMenu.Tab.EQUIPMENT, "L1 / parry switches back")
	await tap_action(&"inventory")
	check(not im.is_open and not get_tree().paused, "closes and resumes")
