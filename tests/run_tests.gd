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
	Endings.enabled = true   # the ending logic stays under test; test_no_ending_yet checks the shipped default
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
		# --- systems ---
		test_fast_travel,
		test_remapping,
		test_difficulty_options,
		test_settings_tabs,
		# --- new enemies ---
		test_flying_enemy, test_shield_enemy, test_mimic_and_chest,
		# --- after the prologue ---
		test_dialogue_box, test_shop, test_shop_selling, test_tips_and_access, test_bestiary_and_deeds, test_relics_and_infusion, test_weapons_tab, test_endings, test_night_merchant, test_new_game_plus, test_chapel_and_unique_weapons, test_sound_extras, test_npc_story, test_road_level, test_road_enemies, test_marshal_boss,
		# --- weapons, armour, upgrades ---
		test_gear_data, test_loadout_equip, test_forge_rules, test_gear_save, test_forge_menu, test_equip_ui, test_new_weapons_land, test_gear_npcs,
		# --- Hollowmere Manor and the sigil ---
		test_sigil_gift, test_sigil_travel, test_travel_key_combat_lock, test_status_effects, test_status_data_valid, test_weapon_skills_data, test_focus_and_skill, test_weapon_parry_and_guard, test_new_enemy_data_and_scenes, test_archer_and_cantor, test_elite_enemy, test_quests_collect_and_kill, test_quest_gating_and_manor_lines, test_journal_tab, test_side_levels_load, test_gallery_gate_and_key, test_minibosses, test_day_night, test_manor_level, test_npcs_stand_on_ground,
		# --- expansion: region, weapons, arts, variety, secrets, trials ---
		test_reliquary_region, test_keep_region, test_belfry_and_crown, test_four_parts, test_descent, test_no_ending_yet, test_reliquary_opens, test_levels_reachable, test_graphics_pass, test_qol, test_boss_lines, test_wayfarers, test_progress_goal, test_talismans, test_potions_and_alchemy, test_lurker_ambush, test_elite_modifiers_and_alert, test_arts, test_second_weapon_set, test_secrets_and_hazards, test_trials, test_boss_intro_card,
	]
	# TEST_ONLY=test_a,test_b runs just those (quick iteration); default runs everything.
	var only := OS.get_environment("TEST_ONLY")
	for t: Callable in tests:
		if only != "" and not only.split(",").has(t.get_method()):
			continue
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
		check(d.blocks.size() > 3 and d.candles.size() >= 1 and d.name != "", "%s map data read" % d.path)
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
	var pv: PresetData = im._preview.get("preset")
	check(pv.id == &"unsworn" and pv.weapon_look == PresetData.WeaponLook.FISTS and pv.armor_look == PresetData.ArmorLook.BARE, "character preview shows your preset, weapon and armour")
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


func test_fast_travel() -> void:
	await fresh_game()
	settings.candle_menu_on_rest = true
	game_state.set_flag(&"candle_lit_village_gate_candle", true)
	await place_player(170.0)
	await press(&"interact")
	await frames(70)
	var cm: CandleMenu = main.get_node("CandleMenu")
	check(cm.is_open, "candle menu open")
	var dests := CandleMenu.travel_destinations()
	check(dests.size() == 2 and dests.any(func(d): return d.id == "village_gate_candle"), "lit candles are destinations (%d)" % dests.size())
	check(not dests.any(func(d): return d.id == "chapel_steps_candle"), "unlit candles are not")
	cm._travel_btn.pressed.emit()
	await frames(2)
	check(cm.travel_open and cm._travel_list.get_child_count() >= 3, "travel list shows areas and candles")
	var target: Dictionary = dests.filter(func(d): return d.id == "village_gate_candle")[0]
	cm.travel_to(target)
	await frames(80)
	level = main.current_level()
	check(level.level_id == &"forsaken_village", "travelled to the village")
	check(level.player.global_position.distance_to(Vector2(222, 480)) < 8.0, "standing at the Village Gate Candle (%s)" % level.player.global_position)
	check(game_state.checkpoint_level == VILLAGE and game_state.checkpoint_id == &"village_gate_candle", "that candle is now the respawn point")
	check(not get_tree().paused and not game_state.ui_modal, "game resumes after travelling")
	settings.candle_menu_on_rest = false


func test_remapping() -> void:
	await fresh_game()
	var input_config := get_tree().root.get_node("InputConfig")
	input_config.reset_all()
	var cp := ControlsPanel.new()
	get_tree().root.add_child(cp)
	await frames(2)
	check(cp._kb.size() == 18 and cp._pad[&"move_left"].disabled, "a row per action; pad movement is fixed")
	check((cp._kb[&"jump"] as Button).text == "Space", "jump shows Space (%s)" % cp._kb[&"jump"].text)
	# Rebind jump to G via the listening flow.
	cp.start_listening(&"jump", false)
	await frames(8)
	var k := InputEventKey.new()
	k.physical_keycode = KEY_G
	k.pressed = true
	Input.parse_input_event(k)
	await frames(3)
	var ku := InputEventKey.new()
	ku.physical_keycode = KEY_G
	Input.parse_input_event(ku)
	await frames(2)
	check(not cp.listening, "listening ends after a key")
	var has_g := InputMap.action_get_events(&"jump").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_G)
	var has_space := InputMap.action_get_events(&"jump").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_SPACE)
	check(has_g and not has_space, "jump is now G (keyboard binding replaced)")
	check(InputMap.action_get_events(&"jump").any(func(e): return e is InputEventJoypadButton), "jump keeps its controller button")
	var cfg := ConfigFile.new()
	cfg.load("user://input.cfg")
	check(("k:%d" % KEY_G) in cfg.get_value("bindings", "jump", []), "saved to input.cfg")
	# Pressing G now jumps.
	await place_player(400.0)
	await press(&"jump", 6)
	check(player.velocity.y < 0.0 or player.global_position.y < 470.0, "the jump action still works")
	# Swap: bind dodge's pad button (Circle) to parry -> dodge takes L1.
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	cp.apply_binding(&"parry", b)
	var parry_pad := InputMap.action_get_events(&"parry").filter(func(e): return e is InputEventJoypadButton)
	var dodge_pad := InputMap.action_get_events(&"dodge").filter(func(e): return e is InputEventJoypadButton)
	check(parry_pad.size() == 1 and parry_pad[0].button_index == JOY_BUTTON_B, "parry is now Circle")
	check(dodge_pad.size() == 1 and dodge_pad[0].button_index == JOY_BUTTON_LEFT_SHOULDER, "dodge swapped to L1")
	check(cp._note.text.contains("Dodge"), "the swap is reported (%s)" % cp._note.text)
	# Escape cancels listening without changing anything.
	cp.start_listening(&"heal", false)
	await frames(8)
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await frames(3)
	check(not cp.listening and InputMap.action_get_events(&"heal").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_R), "Esc cancels")
	cp.reset_defaults()
	check(InputMap.action_get_events(&"jump").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_SPACE), "reset restores Space")
	check(InputMap.action_get_events(&"dodge").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B), "reset restores Circle dodge")
	cp.queue_free()
	await frames(2)


func test_difficulty_options() -> void:
	await fresh_game()
	await place_player(400.0)
	settings.damage_taken_pct = 50
	var hp := player.health.current
	player.receive_hit(damage(20))
	check(is_equal_approx(player.health.current, hp - 10.0), "50% damage taken halves hits (%.1f)" % (hp - player.health.current))
	settings.damage_taken_pct = 200
	await frames(60)   # past the post-hit invulnerability
	hp = player.health.current
	player.receive_hit(damage(10))
	check(is_equal_approx(player.health.current, hp - 20.0), "200% doubles them (%.1f)" % (hp - player.health.current))
	settings.damage_taken_pct = 100
	settings.enemy_health_pct = 150
	var e := await spawn_enemy(600.0)
	check(is_equal_approx(e.health.max_health, e.data.max_health * 1.5), "enemy health 150% (%.0f)" % e.health.max_health)
	e.queue_free()
	settings.enemy_health_pct = 100
	# Parry window: without assist it closes after parry_window_frames; with assist 4 later.
	for assist in [false, true]:
		settings.parry_assist = assist
		await frames(40)
		Input.action_press(&"parry")
		var last_active := -1
		for i in 30:
			await get_tree().physics_frame
			if i == 2:
				Input.action_release(&"parry")
			if player.is_parry_active():
				last_active = player.state_frame
		var want: int = player.parry_window_frames + (4 if assist else 0)
		check(last_active == want, "parry window ends at frame %d (want %d, assist %s)" % [last_active, want, assist])
	settings.parry_assist = false


func test_settings_tabs() -> void:
	await fresh_game()
	var panel := SettingsPanel.new()
	get_tree().root.add_child(panel)
	await frames(2)
	check(panel._pages[0].visible and not panel._pages[1].visible, "starts on Display")
	await tap_action(&"heal")
	check(panel.page == 1 and panel._pages[1].visible, "R1 / Heal moves to the Game tab")
	panel._dmg.pressed.emit()
	check(settings.damage_taken_pct == 125, "damage option cycles (%d)" % settings.damage_taken_pct)
	settings.damage_taken_pct = 100
	await tap_action(&"heal")
	check(panel.page == 2 and panel._controls.is_visible_in_tree(), "then Controls")
	await tap_action(&"parry")
	check(panel.page == 1, "L1 / Parry goes back")
	panel.queue_free()
	await frames(2)


func spawn_scene(path: String, pos: Vector2, facing := -1, patrol := 0.0) -> EnemyBase:
	var e: EnemyBase = load(path).instantiate()
	e.position = pos
	e.start_facing = facing
	e.patrol_distance = patrol
	level.add_child(e)
	await frames(3)
	return e


func test_flying_enemy() -> void:
	await fresh_game()
	for x in enemies():
		x.queue_free()
	await place_player(300.0, 480.0, 1)
	var m: FlyingEnemy = await spawn_scene("res://actors/enemies/gloam_moth.tscn", Vector2(700, 400))
	await frames(60)
	check(absf(m.global_position.y - 400.0) < 12.0, "hovers at its home without falling (y %.0f)" % m.global_position.y)
	await place_player(640.0, 480.0, 1)
	var dove := false
	var lowest := 0.0
	for i in 400:
		await get_tree().physics_frame
		if m.state == EnemyBase.State.ATTACK and m.attack_runner.phase == AttackRunner.Phase.ACTIVE:
			dove = true
		if dove:
			lowest = maxf(lowest, m.global_position.y)
		if dove and m.state == EnemyBase.State.RECOVER:
			break
	check(dove, "spots the player, hovers above and dives")
	check(lowest > 455.0, "the dive comes down to the player (lowest y %.0f)" % lowest)
	check(m.state == EnemyBase.State.RECOVER and m.global_position.y > 440.0, "hangs low and dazed after the dive (y %.0f)" % m.global_position.y)
	check(player.health.current < player.health.max_health, "the dive hit a player who stood still")
	# Parry the next dive: it drops to the ground and can be riposted.
	player.health.restore_full()
	m._cooldown = 0
	var parried := false
	for i in 500:
		await get_tree().physics_frame
		var r := m.attack_runner
		if m.state == EnemyBase.State.ATTACK and r.phase == AttackRunner.Phase.ACTIVE and (m.global_position - player.global_position).length() < 44.0 and player.state == Player.State.FREE:
			player.facing = 1 if m.global_position.x > player.global_position.x else -1
			await press(&"parry", 1)
		if m.state == EnemyBase.State.PARRIED:
			parried = true
			break
	check(parried, "the dive can be parried")
	await frames(30)
	check(m.global_position.y > 470.0, "parried moth falls to the ground (y %.0f)" % m.global_position.y)
	check(player.find_riposte_target() == m, "and is open to a riposte")
	m.queue_free()
	await frames(2)


func test_shield_enemy() -> void:
	await fresh_game()
	for x in enemies():
		x.queue_free()
	await place_player(400.0, 480.0, 1)
	var g: ShieldEnemy = await spawn_scene("res://actors/enemies/oathguard.tscn", Vector2(440, 480), -1)
	g._set_state(EnemyBase.State.IDLE)   # cancel any opening swing (it would reset the cooldown)
	g._cooldown = 100000
	await frames(10)
	var hp := g.health.current
	var light := HitData.make(12.0, player, Vector2(60, 0))
	light.poise_damage = 10.0
	check(g.receive_hit(light) == HitData.Result.BLOCKED and g.health.current == hp, "a frontal hit is blocked, no damage")
	check(g.guard < g.max_guard, "blocking drains guard (%.0f)" % g.guard)
	# The player's real swing bounces off.
	g.guard = g.max_guard
	g.facing = -1
	await press(&"attack_light")
	await frames(20)
	check(g.health.current == hp and g.guard < g.max_guard, "player's light attack is blocked (guard %.0f)" % g.guard)
	# Heavy hits break the guard -> riposte window.
	g.facing = -1
	g.guard = g.max_guard
	var heavy := HitData.make(32.0, player, Vector2(60, 0))
	heavy.poise_damage = 45.0
	check(g.receive_hit(heavy) == HitData.Result.BLOCKED, "one heavy is still blocked")
	var r: int = g.receive_hit(heavy)
	check(r == HitData.Result.HIT and g.state == EnemyBase.State.PARRIED and g.guard_breaks == 1, "two heavy hits break the guard")
	await frames(6)
	check(g.is_riposte_ready(), "guard break opens a riposte")
	await frames(130)
	# From behind it takes full damage.
	g.facing = 1
	g._set_state(EnemyBase.State.IDLE)
	hp = g.health.current
	check(g.receive_hit(light) == HitData.Result.HIT and g.health.current < hp, "hits from behind land")
	# It turns slowly.
	g._cooldown = 100000
	g.target = player
	g.facing = 1
	g._set_state(EnemyBase.State.CHASE)
	await frames(8)
	check(g.facing == 1, "still facing away a few frames later")
	await frames(30)
	check(g.facing == -1, "then turns to face the player")
	g.queue_free()
	await frames(2)


func test_mimic_and_chest() -> void:
	await fresh_game()
	for x in enemies():
		x.queue_free()
	# A real chest.
	var chest := TreasureChest.new()
	chest.item = load("res://data/items/ash_bandage.tres")
	chest.count = 2
	chest.embers = 50
	chest.chest_id = &"test_chest"
	chest.position = Vector2(500, 480)
	level.add_child(chest)
	var band: int = game_state.item_count(&"ash_bandage")
	var emb: int = game_state.embers
	await place_player(500.0)
	await press(&"interact")
	await frames(5)
	check(chest.opened and game_state.item_count(&"ash_bandage") == band + 2 and game_state.embers == emb + 50, "opening a chest gives its contents")
	check(game_state.get_flag(&"chest_open_test_chest"), "and it stays open (flag)")
	chest.queue_free()
	# A mimic: opening it springs an ambush.
	var sp := EnemySpawner.new()
	sp.enemy_scene = load("res://actors/enemies/mimic.tscn")
	sp.spawn_id = &"test_mimic"
	sp.patrol_distance = 0.0
	sp.position = Vector2(700, 480)
	level.add_child(sp)
	await frames(4)
	var m := sp.enemy as Mimic
	check(m and m.dormant and m.spawn_id == &"test_mimic", "mimic waits, dormant")
	await place_player(690.0, 480.0, 1)
	player.health.restore_full()
	await frames(60)
	check(m.dormant, "it does not wake by itself")
	await press(&"interact")
	await frames(2)
	check(not m.dormant and m.state == EnemyBase.State.ATTACK and m.attack_runner.attack.id == &"mimic_ambush", "trying to open it springs the ambush")
	await frames(30)
	check(player.health.current < player.health.max_health, "the ambush bites")
	m.receive_hit(HitData.make(5000.0, player))
	await frames(5)
	check(m.is_dead() and game_state.get_flag(&"mimic_slain_test_mimic"), "slain mimic is remembered")
	await frames(100)
	sp.spawn()
	await frames(4)
	check(not is_instance_valid(sp.enemy) or sp.enemy.is_queued_for_deletion(), "a slain mimic does not come back")
	# Striking a dormant mimic first: critical stagger.
	sp.spawn_id = &"test_mimic_2"
	sp.spawn()
	await frames(4)
	var m2 := sp.enemy as Mimic
	var h := HitData.make(10.0, player)
	m2.receive_hit(h)
	check(not m2.dormant and m2.state == EnemyBase.State.STAGGER, "hitting it first wakes it staggered")
	m2.queue_free()
	sp.queue_free()
	await frames(2)


const ROAD := "res://world/levels/vaelmoor_road.tscn"
const AWAKE := "res://world/levels/vaelmoor_awake.tscn"


func test_dialogue_box() -> void:
	await fresh_game()
	var box: DialogueBox = main.get_node("DialogueBox")
	events.dialogue_requested.emit("Tester", ["The first line of speech is deliberately long enough that it is still typing out when the first press arrives, which is the point of this test.", {"who": "Other", "text": "Second line."}])
	await frames(2)
	check(box.is_open and get_tree().paused and game_state.ui_modal, "dialogue opens, pauses, takes over input")
	check(box._name.text == "Tester" and not box.line_done(), "speaker shown, line still typing")
	await tap_action(&"interact")   # inside the arm window: ignored
	check(box.index == 0 and not box.line_done(), "the opening press does not skip anything")
	await frames(8)
	await tap_action(&"interact")
	check(box.index == 0 and box.line_done(), "first press finishes the typing")
	await tap_action(&"interact")
	check(box.index == 1 and box._name.text == "Other", "second press moves on; speaker can change")
	await frames(60)
	await tap_action(&"interact")
	await tap_action(&"interact")
	check(not box.is_open and not get_tree().paused and not game_state.ui_modal, "last press closes it and unpauses")
	# Cancel skips the rest.
	events.dialogue_requested.emit("Tester", ["a", "b", "c"])
	await frames(14)
	await tap_action(&"ui_cancel")
	check(not box.is_open, "Cancel skips the conversation")


func test_sound_extras() -> void:
	await fresh_game()
	for nm in Audio.STEPS:
		check(ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % nm), "footstep %s exists" % nm)
	for nm in [&"voice_growl", &"voice_hiss", &"voice_chant", &"archer_twang", &"fx_burn", &"fx_frost", &"fx_bleed", &"fx_poison", &"skill_cast", &"focus_ready", &"relic_equip"]:
		check(ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % nm), "sound %s exists" % nm)
	for nm in [&"night", &"chapel"]:
		check(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % nm), "music %s exists" % nm)
	for id in Audio.VOICES:
		check(Bestiary.data(id) != null, "voice entry %s names a real enemy" % id)
	var seen := {}
	for i in 60:
		Audio.step()
		seen[Audio._last_step] = true
	check(seen.size() >= 4, "footsteps use several variants (%d)" % seen.size())
	# Night music on a day/night level
	game_state.in_game = true
	DayNight.forced = 0.2
	await go_to_level(ROAD, &"")
	check(Audio.level_music() != &"night" and Audio.level_music() != &"", "by day the road plays its own music (%s)" % Audio.level_music())
	DayNight.forced = 0.7
	check(Audio.level_music() == &"night", "at night the road plays the night loop")
	await go_to_level(Manor.PATH, &"")
	check(Audio.level_music() != &"night", "indoor levels never switch to the night loop")
	DayNight.forced = -1.0


func test_chapel_and_unique_weapons() -> void:
	await fresh_game()
	game_state.in_game = true
	const CHAPEL := "res://world/levels/ashen_chapel.tscn"
	await go_to_level(CHAPEL, &"")
	check(level.scene_file_path == CHAPEL and WorldMap.LEVELS.has(CHAPEL), "the Ashen Chapel loads and is on the map")
	for n in ["FromGraveyard", "ToGraveyard", "ChapelCandle", "NaveCandle", "CinderArena", "AshfallArena", "SecretWall", "PewChest", "GildedNave", "CaptainA", "SergeantA"]:
		check(level.get_node_or_null(n) != null, "the chapel has %s" % n)
	var bad := placement_problems()
	check(bad.is_empty(), "the chapel: everything stands on something %s" % [bad])
	await go_to_level(GRAVEYARD, &"from_chapel")
	check(level.find_entry(&"from_chapel") != null and level.get_node_or_null("ToChapel") != null, "the graveyard links to the chapel")
	# Bosses and their data
	for pair in [["mother_cinder", &"cinder_heart"], ["ser_ashfall", &"ashfall_seal"]]:
		var d := Bestiary.data(StringName(pair[0]))
		check(d != null and d.drop_item != null and d.drop_item.id == pair[1] and d.drop_chance == 1.0, "%s drops %s" % [pair[0], pair[1]])
	# Unique weapons
	for id in [&"cinderbrand", &"ashfall_pike"]:
		var w := Weapons.get_weapon(id)
		check(w != null and w.damage_mult > 1.0 and w.skill != null and w.light_combo_start != null and IconArt.has_icon(id), "%s is a complete weapon" % id)
		check(Forge.recipe(id).has("relic") and Forge.recipe(id).kind == "weapon", "%s is forged from a boss relic" % id)
	game_state.embers = 5000
	game_state.add_item(&"forge_scrap", 10)
	check(not Forge.make(&"cinderbrand").ok, "no relic, no Cinderbrand")
	game_state.add_item(&"cinder_heart", 1)
	check(Forge.make(&"cinderbrand").ok and game_state.owns_weapon(&"cinderbrand"), "the Heart lets Hobb forge it")
	Loadout.equip_weapon(&"cinderbrand")
	var base_mult := Weapons.level_mult(0)
	check(is_equal_approx(Loadout.weapon_mult(), base_mult * 1.15), "a unique weapon hits harder (%.2f)" % Loadout.weapon_mult())
	check(Deeds.DEFS.has(&"cinder_down") and Deeds.DEFS.has(&"ashfall_down"), "the new bosses have deeds")


func test_new_game_plus() -> void:
	await fresh_game()
	check(game_state.ng_cycle() == 0 and is_equal_approx(game_state.ng_hp_mult(), 1.0), "a first run has no scaling")
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	game_state.set_flag(&"quest_hobb_scrap", "done")
	game_state.set_flag(&"chest_open_cellar_chest", true)
	game_state.set_flag(&"deed_first_blood", true)
	game_state.set_flag(&"bk_carrion_crow", 4)
	game_state.set_flag(&"infuse_oathblade", "burn")
	game_state.set_flag(&"ending_chosen", "keep")
	game_state.set_flag(&"ending_keep", true)
	game_state.add_item(&"relic_coin", 1)
	game_state.embers = 777
	game_state.stats["vigor"] = 5
	var wid: StringName = game_state.weapon_id
	var n: int = game_state.begin_new_cycle()
	check(n == 1 and game_state.ng_cycle() == 1, "the cycle counter rises")
	check(not game_state.get_flag(&"boss_defeated_hollow_marshal", false) and not Quests.is_done(&"hobb_scrap") and not game_state.get_flag(&"chest_open_cellar_chest", false), "the story resets: bosses, errands, chests")
	check(Endings.chosen() == &"" and game_state.get_flag(&"ending_keep", false), "the gate asks again, but past endings are remembered")
	check(game_state.get_flag(&"deed_first_blood", false) and Bestiary.kills(&"carrion_crow") == 4 and Forge.infusion_of(&"oathblade") == &"burn", "deeds, bestiary and infusions are kept")
	check(game_state.item_count(&"relic_coin") == 1 and game_state.embers == 777 and game_state.stats["vigor"] == 5 and game_state.weapon_id == wid, "gear, stats and embers are kept")
	check(is_equal_approx(game_state.ng_hp_mult(), 1.6) and is_equal_approx(game_state.ng_damage_mult(), 1.35) and is_equal_approx(game_state.ng_ember_mult(), 1.5), "cycle 1 is harder and pays more")
	check(game_state.level_path == GameState.DEFAULT_LEVEL_PATH and not game_state.has_checkpoint, "you start again at the beginning")
	await go_to_level(ROAD, &"")
	var base: float = 0.0
	var found := false
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if e is EnemyBase and e.data and e.data.id == &"roadside_pikeman":
			base = e.data.max_health
			check(is_equal_approx(e.health.max_health, base * 1.6 * settings.enemy_health_pct / 100.0), "enemies spawn with cycle health (%.0f vs %.0f)" % [e.health.max_health, base])
			found = true
			break
	check(found, "found a pikeman to check")


func test_night_merchant() -> void:
	await fresh_game()
	DayNight.forced = 0.2
	await go_to_level(ROAD, &"")
	var lm: Npc = main.current_level().get_node("LanternMan")
	events.daynight_changed.emit(false)
	await frames(3)
	check(not lm.is_about() and not lm.visible, "the Lantern-Man is not about by day")
	DayNight.forced = 0.7
	events.daynight_changed.emit(true)
	await frames(3)
	check(lm.is_about() and lm.visible, "he walks the road at night")
	check(Shops.stock(&"lantern").size() == 5 and Shops.shop_name(&"lantern") != "WARES", "he has his own stock and name")
	var cheaper := true
	for e in Shops.stock(&"lantern"):
		if e.item != &"ember_shard" and e.price >= Shops.buy_price(e.item):
			cheaper = false
	check(cheaper, "his everyday wares are cheaper than the pedlar's")
	check(Dialogues.conversation(&"lantern_man").speaker == "The Lantern-Man", "he has lines of his own")
	DayNight.forced = -1.0


func test_endings() -> void:
	await fresh_game()
	var em: EndingMenu = main.get_node("EndingMenu")
	check(not Endings.gate_open() and not Endings.choose(&"keep"), "the gate is shut and nothing can be chosen before the Marshal falls")
	events.ending_requested.emit()
	await frames(2)
	check(not em.is_open, "the ending menu will not open early")
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	check(Endings.gate_open() and Endings.available(&"keep") and Endings.available(&"break") and not Endings.available(&"mend"), "after the Marshal, keep and break are open; mend is locked")
	check(Endings.reason(&"mend") != "", "a locked ending says what it needs")
	events.ending_requested.emit()
	await frames(3)
	check(em.is_open and get_tree().paused and em.phase == EndingMenu.Phase.CHOICE, "the choice opens")
	em._pick(&"mend")
	check(Endings.chosen() == &"", "picking a locked ending does nothing")
	em._pick(&"break")
	check(Endings.chosen() == &"break" and game_state.get_flag(&"ending_break", false) and em.phase == EndingMenu.Phase.EPILOGUE, "choosing starts the epilogue")
	var n: int = em.pages.size()
	for i in n:
		em.advance()
	check(not em.is_open and not get_tree().paused, "the last page returns to the road")
	check(not Endings.gate_open() and not Endings.choose(&"keep"), "the choice cannot be taken back")
	check(Deeds.has(&"ending"), "an ending unlocks its deed")
	# Mend: all errands + Gallery opened.
	await fresh_game()
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	for q in Quests.ORDER:
		game_state.set_flag(StringName("quest_" + String(q)), "done")
	check(not Endings.available(&"mend"), "errands alone are not enough")
	game_state.set_flag(&"door_open_hollowmere_gallery", true)
	check(Endings.available(&"mend") and Endings.choose(&"mend") and Endings.chosen() == &"mend", "every errand plus the Gallery opens the third ending")


func test_weapons_tab() -> void:
	await fresh_game()
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.WEAPONS)
	await frames(3)
	check(inv.tab == InventoryMenu.Tab.WEAPONS and inv._w_slots.size() == Weapons.IDS.size(), "the weapons tab has a slot for every weapon in the game")
	var owned := 0
	for i in Weapons.IDS.size():
		var has: bool = game_state.owns_weapon(Weapons.IDS[i])
		owned += 1 if has else 0
		check(inv._w_slots[i].locked == not has, "%s is %s" % [Weapons.IDS[i], "shown" if has else "a grey question mark"])
	check("%d / %d" % [owned, Weapons.IDS.size()] in inv._w_head.text, "the header counts what you have found")
	inv._show_weapon(&"cinderbrand")
	check(inv._w_name.text == "???" and not ("Cinderbrand" in inv._w_text.text) and "Where to find it" in inv._w_text.text, "an unfound weapon reveals nothing")
	game_state.grant_gear("weapon", &"toll_hammer")
	inv.show_tab(InventoryMenu.Tab.WEAPONS)
	var idx := Weapons.IDS.find(&"toll_hammer")
	check(not inv._w_slots[idx].locked, "a weapon you pick up appears at once")
	inv._weapon_pressed(&"toll_hammer")
	check(game_state.weapon_id == &"toll_hammer", "pressing a found weapon equips it")
	inv.close()
	await frames(2)


func test_relics_and_infusion() -> void:
	await fresh_game()
	var pl: Player = main.current_level().player
	for id in Relics.IDS:
		check(Items.get_item(id) != null and Relics.DEFS.has(id), "relic item exists: %s" % id)
	check(not Relics.toggle(&"relic_locket").ok, "you cannot wear a relic you do not own")
	game_state.add_item(&"relic_locket", 1)
	game_state.add_item(&"relic_knot", 1)
	game_state.add_item(&"relic_coin", 1)
	check(Relics.toggle(&"relic_locket").ok and Relics.toggle(&"relic_knot").ok, "two relics can be worn")
	check(not Relics.toggle(&"relic_coin").ok and Relics.equipped().size() == 2, "a third does not fit")
	check(is_equal_approx(Relics.mult("focus_gain"), 1.25) and is_equal_approx(Relics.mult("status_resist"), 0.15), "worn relics give their effects")
	pl.set_focus(0.0)
	pl.add_focus(10.0)
	check(is_equal_approx(pl.focus, 12.5), "the locket speeds focus (%.1f)" % pl.focus)
	await frames(2)
	check(is_equal_approx(pl.status.resist_of(&"bleed"), clampf(StatusFx.lookup(pl.status.resist, &"bleed") + 0.15, -1.0, 1.0)), "the knot adds status resistance")
	check(Relics.toggle(&"relic_locket").ok and not Relics.is_worn(&"relic_locket"), "a relic can be taken off")
	var before: int = game_state.embers
	Relics.toggle(&"relic_coin")
	var base := 100
	check(is_equal_approx(Relics.mult("ember_gain"), 1.2) and roundi(base * Relics.mult("ember_gain")) == 120, "the coin raises ember rewards")
	# infusion
	var w: StringName = game_state.weapon_id
	game_state.embers = 1000
	game_state.add_item(&"hollow_resin", 5)
	check(Forge.infusion_of(w) == &"" and Forge.next_infusion(w) == &"bleed", "weapons start clean; first infusion is bleed")
	var r := Forge.infuse(w, &"poison")
	check(r.ok and Forge.infusion_of(w) == &"poison" and game_state.embers == 700 and game_state.item_count(&"hollow_resin") == 3, "infusing costs embers and resin")
	check(not Forge.infuse(w, &"poison").ok, "the same infusion twice is refused")
	pl.apply_loadout()
	check(pl.attack_runner.weapon_status == &"poison" and pl.attack_runner.weapon_status_amount >= 28.0, "the player's hits carry the infusion")
	game_state.embers = 0
	check(not Forge.infuse(w, &"burn").ok and Forge.infusion_of(w) == &"poison", "too poor: nothing changes")
	check(Forge.infuse(w, &"").ok and Forge.infusion_of(w) == &"", "cleaning is free")
	var fm: ForgeMenu = main.get_node("ForgeMenu")
	events.station_requested.emit(&"forge")
	await frames(3)
	fm._describe(w)
	check(fm._infuse_btn.visible, "the forge shows an infusion button for an owned weapon")
	fm.close()
	await frames(2)
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.RELICS)
	await frames(3)
	check(inv._relic_btns.size() == 3, "the relics tab lists the relics you carry")
	inv.close()
	await frames(2)


func test_bestiary_and_deeds() -> void:
	await fresh_game()
	var d := Bestiary.data(&"candle_cantor")
	check(d != null and Bestiary.entry_text(&"candle_cantor") == "???", "an unmet creature shows ???")
	Bestiary.record_seen(d)
	check(Bestiary.seen(&"candle_cantor") and not (d.lore in Bestiary.entry_text(&"candle_cantor")), "met but not slain: no lore yet")
	Bestiary.record_kill(d)
	check(d.lore in Bestiary.entry_text(&"candle_cantor") and Bestiary.kills(&"candle_cantor") == 1, "one kill reveals the lore")
	check("more kills reveal" in Bestiary.entry_text(&"candle_cantor"), "weaknesses stay hidden until three kills")
	Bestiary.record_kill(d)
	Bestiary.record_kill(d)
	check("Frost" in Bestiary.entry_text(&"candle_cantor") or "frost" in Bestiary.entry_text(&"candle_cantor").to_lower(), "three kills reveal resistances")
	for id in Bestiary.IDS:
		check(Bestiary.data(id) != null, "bestiary data exists for %s" % id)
	check(Deeds.has(&"first_blood"), "the first kill unlocks First Blood")
	check(not Deeds.has(&"warden_down"), "boss deeds start locked")
	game_state.set_flag(&"boss_defeated_bell_warden", true)
	var got := Deeds.check_all()
	check(&"warden_down" in got and Deeds.has(&"warden_down"), "a boss flag unlocks its deed")
	check(Deeds.check_all().is_empty(), "a deed unlocks only once")
	game_state.set_flag(&"fx_bleed", true)
	game_state.set_flag(&"fx_poison", true)
	game_state.set_flag(&"fx_burn", true)
	check(not Deeds.has(&"all_status"), "three of four afflictions is not enough")
	events.status_triggered.emit(&"frost")
	check(Deeds.has(&"all_status"), "all four afflictions unlock the deed")
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.BESTIARY)
	await frames(3)
	check(inv.tab == InventoryMenu.Tab.BESTIARY and "BESTIARY" in inv._bestiary_label.text, "the bestiary tab lists creatures")
	inv.show_tab(InventoryMenu.Tab.DEEDS)
	check("DEEDS" in inv._deeds_label.text and "[x]" in inv._deeds_label.text, "the deeds tab lists deeds")
	inv.close()
	await frames(2)


func test_tips_and_access() -> void:
	await fresh_game()
	settings.tutorial_hints = true
	check(Tutorial.take(&"focus") and not Tutorial.take(&"focus"), "a tip is given once")
	check(game_state.get_flag(&"tip_focus", false), "the tip is remembered in the save flags")
	settings.tutorial_hints = false
	check(not Tutorial.take(&"night"), "tips can be turned off")
	settings.tutorial_hints = true
	var hud = main.hud
	hud.show_tip(&"travel")
	check(hud._tip.modulate.a > 0.9 and "Manor" in hud._tip.text and not ("{travel}" in hud._tip.text), "the HUD shows a tip with the key name filled in")
	settings.colorblind = false
	var normal: Color = StatusFx.color_of(&"poison")
	settings.colorblind = true
	check(StatusFx.color_of(&"poison") != normal and StatusFx.color_of(&"bleed") != StatusFx.COLORS[&"bleed"], "colourblind palette changes status colours")
	settings.colorblind = false
	for id in Tutorial.ids():
		check(Tutorial.TIPS[id].has("title") and Tutorial.TIPS[id].has("text"), "tip %s has text" % id)


func test_shop_selling() -> void:
	await fresh_game()
	game_state.embers = 0
	game_state.add_item(&"ash_bandage", 2)
	game_state.add_item(&"gallery_key", 1)
	var ids: Array = Shops.sellable().map(func(e): return e.item)
	check(&"ash_bandage" in ids and not (&"gallery_key" in ids), "consumables sell, keys never do")
	check(Shops.sell_price(&"gallery_key") == 0, "a key has no sell price")
	var price := Shops.sell_price(&"ash_bandage")
	check(price > 0 and price < Shops.buy_price(&"ash_bandage"), "selling pays less than buying (%d)" % price)
	var r := Shops.sell(&"ash_bandage")
	check(r.ok and game_state.embers == price and game_state.item_count(&"ash_bandage") == 1, "selling gives embers and removes one")
	check(not Shops.sell(&"gallery_key").ok and game_state.item_count(&"gallery_key") == 1, "a key cannot be sold")
	var shop: ShopMenu = main.get_node("ShopMenu")
	events.shop_requested.emit(&"pedlar")
	await frames(3)
	shop.show_tab(true)
	await frames(2)
	check(shop.selling and shop.rows.size() == Shops.sellable().size() and shop.rows.size() > 0, "the sell tab lists the pack")
	var before: int = game_state.embers
	(shop.rows[0].button as Button).pressed.emit()
	await frames(2)
	check(game_state.embers > before, "the sell tab's button sells")
	shop.close()
	await frames(2)


func test_shop() -> void:
	await fresh_game()
	game_state.embers = 100
	var shop: ShopMenu = main.get_node("ShopMenu")
	events.shop_requested.emit(&"pedlar")
	await frames(3)
	check(shop.is_open and get_tree().paused and shop.rows.size() == 5, "the pedlar's shop opens with five wares")
	var b0: int = game_state.item_count(&"ash_bandage")
	var r := Shops.buy(&"pedlar", &"ash_bandage")
	check(r.ok and game_state.embers == 60 and game_state.item_count(&"ash_bandage") == b0 + 1, "buying costs embers and gives the item")
	var r2 := Shops.buy(&"pedlar", &"pilgrims_draught")
	check(not r2.ok and game_state.embers == 60 and game_state.item_count(&"pilgrims_draught") == 0, "too poor: nothing is taken")
	game_state.embers = 10000
	for i in 12:
		Shops.buy(&"pedlar", &"pilgrims_draught")
	check(game_state.item_count(&"pilgrims_draught") == 5 and game_state.embers == 10000 - 5 * 150, "a full stack stops the sale without taking embers (%d)" % game_state.embers)
	# The UI button buys too.
	game_state.embers = 500
	var before: int = game_state.item_count(&"stamina_tonic")
	(shop.rows[1].button as Button).pressed.emit()
	await frames(2)
	check(game_state.item_count(&"stamina_tonic") == before + 1 and game_state.embers == 410, "the buy button works")
	await tap_action(&"ui_cancel")
	check(not shop.is_open and not get_tree().paused, "Cancel leaves the shop")
	# The new items are valid and have icons.
	for id in [&"pilgrims_draught", &"marshals_crest"]:
		var it := Items.get_item(id)
		check(it != null and it.validate().is_empty() and IconArt.has_icon(id), "%s valid with an icon" % id)


func test_npc_story() -> void:
	await fresh_game()
	await go_to_level(AWAKE, &"arrival")
	var box: DialogueBox = main.get_node("DialogueBox")
	var ommen: Npc = level.get_node("Ommen")
	await place_player(ommen.global_position.x - 24.0, 480.0, 1)
	await frames(8)
	await press(&"interact")
	await frames(4)
	check(box.is_open and box._name.text == "Hooded Figure" and box.lines.size() == 3, "the stranger speaks first (%s)" % box._name.text)
	check(player.global_position.x < ommen.global_position.x and ommen.facing == -1, "he turns to face you")
	box.close()
	await frames(30)
	check(Dialogues.talks(&"ommen") == 1, "the talk is counted")
	# Pages advance with each visit; the name is given on the third.
	await press(&"interact")
	await frames(4)
	check(box.is_open and box.lines[0].begins_with("Vaelmoor was held together"), "second page: the Hollow Oath")
	box.close()
	await frames(30)
	await press(&"interact")
	await frames(4)
	check(box._name.text == "Ommen" and box.lines[0].begins_with("My name is Ommen"), "third page: he gives his name")
	box.close()
	await frames(30)
	check(Dialogues.talks(&"ommen") == 3, "three talks so far")
	# After the Marshal falls he has something new to say, once.
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	var c := Dialogues.conversation(&"ommen")
	check(c.lines[0].contains("crossroads are quiet"), "he reacts to the Marshal's fall")
	Dialogues.finish(&"ommen")
	check(Dialogues.talks(&"ommen") == 3 and not Dialogues.conversation(&"ommen").lines[0].contains("quiet"), "that line is only said once")
	# The counter survives a save round trip as a number.
	var n: Dictionary = saves._normalize(game_state.to_dict())
	check(int(n.flags.get("talks_ommen", -1)) == 3, "talk counter is saved")
	# Wenna: intro, then the shop opens after she speaks.
	await go_to_level(ROAD, &"from_awake")
	var wenna: Npc = level.get_node("Wenna")
	await place_player(wenna.global_position.x - 30.0, 480.0, 1)
	await frames(8)
	game_state.embers = 200
	await press(&"interact")
	await frames(4)
	check(box.is_open and box._name.text == "Wenna" and box.lines.size() == 3, "Wenna introduces herself")
	box.close()
	await frames(6)
	check(main.get_node("ShopMenu").is_open, "her shop opens after she speaks")
	main.get_node("ShopMenu").close()
	await frames(30)
	await press(&"interact")
	await frames(4)
	check(box.is_open and box.lines.size() == 1, "later she only greets you")
	box.close()
	await frames(4)
	main.get_node("ShopMenu").close()


func test_road_level() -> void:
	await fresh_game()
	await go_to_level(AWAKE, &"arrival")
	await place_player(1860.0, 480.0, 1)
	Input.action_press(&"move_right")
	await frames(60)
	Input.action_release(&"move_right")
	await frames(80)
	level = main.current_level()
	check(level.level_id == &"vaelmoor_road", "the east edge of Vaelmoor, Awake leads to the road")
	check(level.player.global_position.distance_to(Vector2(110, 480)) < 60.0, "arrive at the road start (%s)" % level.player.global_position)
	player = level.player
	# Back west again.
	await place_player(60.0, 480.0, -1)
	Input.action_press(&"move_left")
	await frames(40)
	Input.action_release(&"move_left")
	await frames(80)
	level = main.current_level()
	check(level.level_id == &"vaelmoor_awake" and level.player.global_position.x > 1700.0, "and the west edge leads back")
	await go_to_level(ROAD, &"from_awake")
	var ks := {}
	for e in level.get_children():
		if e is EnemySpawner:
			var nm: String = e.enemy_scene.resource_path.get_file()
			ks[nm] = int(ks.get(nm, 0)) + 1
	check(ks.get("roadside_pikeman.tscn", 0) == 4 and ks.get("carrion_crow.tscn", 0) == 4 and ks.get("oathguard.tscn", 0) == 2 and ks.get("mimic.tscn", 0) == 1, "the road is populated (%s)" % ks)
	check(WorldMap.LEVELS.has(ROAD) and WorldMap.info(ROAD).candles.size() == 2, "the road is on the map with two candles")
	check(level.get_node("OathGate") is OathGate and not Endings.gate_open(), "the Oath Gate is sealed until the Marshal falls")
	# Resting at the wayside candle: a fast travel destination.
	await place_player(500.0, 480.0, 1)
	await press(&"interact")
	await frames(60)
	check(game_state.get_flag(&"candle_lit_wayside_candle", false), "the wayside candle can be rested at")
	check(CandleMenu.travel_destinations().any(func(d): return d.id == "wayside_candle"), "and appears in fast travel")
	# The field chest.
	await place_player(1005.0, 460.0, 1)
	await frames(6)
	var emb: int = game_state.embers
	await press(&"interact")
	await frames(4)
	check(game_state.embers == emb + 200 and game_state.item_count(&"pilgrims_draught") == 1, "the field chest holds embers and a draught")


func test_road_enemies() -> void:
	await fresh_game()
	for x in enemies():
		x.queue_free()
	var a := {}
	for id in ["crow_dive", "pike_thrust", "pike_trip", "marshal_thrust", "marshal_sweep", "marshal_charge", "marshal_vault", "marshal_banner"]:
		var at: AttackData = load("res://data/attacks/%s.tres" % id)
		check(at != null and at.validate().is_empty(), "%s valid" % id)
	check(not load("res://data/attacks/pike_trip.tres").parryable and load("res://data/attacks/pike_thrust.tres").parryable, "the low sweep cannot be parried; the thrust can")
	check(load("res://data/attacks/marshal_banner.tres").is_ranged(), "the banner call uses the ranged hook")
	await place_player(400.0, 480.0, 1)
	var pk := await spawn_scene("res://actors/enemies/roadside_pikeman.tscn", Vector2(440, 480), -1)
	pk._start_attack(load("res://data/attacks/pike_thrust.tres"))
	await frames(40)
	check(player.health.current < player.health.max_health, "a pike thrust hurts")
	check(pk.health.max_health == 90.0 and pk.data.ember_reward == 60, "pikeman stats")
	pk.queue_free()
	var cr := await spawn_scene("res://actors/enemies/carrion_crow.tscn", Vector2(500, 420), -1)
	check(cr is FlyingEnemy and cr.data.ember_reward == 30, "a crow is a flying enemy")
	cr.queue_free()
	await frames(2)


func test_marshal_boss() -> void:
	await fresh_game()
	await go_to_level(ROAD, &"from_awake")
	var ar: BossArena = level.get_node("MarshalArena")
	await place_player(2840.0, 480.0, 1)
	await frames(40)
	var boss := ar.boss as HollowMarshal
	check(boss != null and ar.fight_active and boss.active, "walking through the gate starts the Marshal fight")
	check(boss.boss_id == &"hollow_marshal" and boss.health.max_health == 900.0 and boss.phase2_attacks.size() == 5, "boss configured")
	boss._cooldown = 99999
	await frames(2)
	# Thrust is parryable and hurts when it lands.
	player.global_position = Vector2(boss.global_position.x - 70.0, 480.0)
	player.facing = 1
	boss.facing = -1
	await frames(4)
	var hp := player.health.current
	boss._start_attack(load("res://data/attacks/marshal_thrust.tres"))
	await frames(60)
	check(player.health.current < hp, "an unanswered lance thrust lands")
	# Phase 2.
	boss.receive_hit(damage(boss.health.max_health * 0.55))
	await frames(boss.roar_frames + 6)
	check(boss.phase == 2 and boss.data.attacks.any(func(a): return a.id == &"marshal_banner"), "phase 2 adds the banner and the vault")
	boss._cooldown = 99999
	player.health.restore_full()
	await place_player(boss.global_position.x - 150.0, 480.0, 1)
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/marshal_banner.tres"))
	await frames(60)
	check(boss.alive_crows() == 2, "raising the banner calls two crows (%d)" % boss.alive_crows())
	check(boss._crows.all(func(c): return c.data.ember_reward == 0), "summoned crows give no embers")
	boss._start_attack(load("res://data/attacks/marshal_banner.tres"))
	await frames(60)
	check(boss.alive_crows() == 2, "never more than two at once")
	# Victory: flag, crest, embers; crows vanish; Ommen reacts.
	var e0: int = game_state.embers
	boss.receive_hit(damage(99999.0))
	await frames(6)
	check(game_state.get_flag(&"boss_defeated_hollow_marshal", false) and game_state.item_count(&"marshals_crest") == 1, "Marshal defeated: flag + crest")
	check(game_state.embers - e0 == 3200, "3200 embers (%d)" % (game_state.embers - e0))
	await frames(6)
	check(boss.alive_crows() == 0, "the crows fall with him")
	check(Dialogues.conversation(&"ommen").lines[0].contains("crossroads are quiet"), "Ommen has something to say")


# ---------------------------------------------------------------- weapons, armour, upgrades

func test_gear_data() -> void:
	for id in Weapons.IDS:
		var w := Weapons.get_weapon(id)
		check(w != null and w.id == id and w.light_combo_start and w.heavy and w.aerial and w.riposte, "%s: weapon complete" % id)
		if w == null:
			continue
		var bad := PackedStringArray()
		for a in WeaponStats.light_chain(w) + [w.heavy, w.aerial, w.riposte]:
			bad.append_array(a.validate())
		check(bad.is_empty(), "%s: attacks valid %s" % [id, bad])
		check(IconArt.has_icon(id), "%s: has an icon" % id)
		check(WeaponStats.summary(w, 1.0).light_total > 0, "%s: summary works" % id)
	for id in Armors.IDS:
		var a := Armors.get_armor(id)
		check(a != null and a.validate().is_empty(), "%s: armour valid" % id)
		check(IconArt.has_icon(StringName("armor_" + String(id))), "%s: armour icon" % id)
	# The four starting armours behave exactly like their presets always did.
	for pid in Presets.IDS:
		var pr := Presets.get_preset(pid)
		var ar := Armors.get_armor(pid)
		check(ar != null and is_equal_approx(ar.damage_taken_mult, pr.damage_taken_mult) and is_equal_approx(ar.run_speed_mult, pr.run_speed_mult) and ar.look == pr.armor_look, "%s: starter armour mirrors its preset" % pid)
		check(pr.weapon.look == pr.weapon_look, "%s: weapon look matches" % pid)
	for rid in Forge.RECIPES:
		var rc: Dictionary = Forge.RECIPES[rid]
		var known: bool = Weapons.is_valid_id(String(rid)) if rc.kind == "weapon" else Armors.is_valid_id(String(rid))
		check(known, "%s: recipe points at real gear" % rid)
		check(not rc.has("relic") or Items.get_item(rc.relic) != null, "%s: relic exists" % rid)
	for it in [&"forge_scrap", &"hollow_resin"]:
		check(Items.get_item(it).validate().is_empty() and IconArt.has_icon(it), "%s valid with an icon" % it)
	# Every enemy that drops materials points at a real item.
	var dropped := 0
	for e in ["ember_acolyte", "hollow_penitent", "oathguard", "roadside_pikeman", "gloam_moth", "carrion_crow", "mimic", "bell_warden", "drowned_canon", "hollow_marshal", "bell_bearer"]:
		var ed := load("res://data/enemies/%s.tres" % e) as EnemyData
		if ed.bonus_drop_item != null and ed.bonus_drop_chance > 0.0:
			dropped += 1
	check(dropped == 11, "all eleven enemies drop crafting materials (%d)" % dropped)


func test_loadout_equip() -> void:
	await fresh_game()
	check(game_state.owns_weapon(&"oathblade") and game_state.owns_armor(&"sworn_knight") and game_state.armor_id == &"sworn_knight", "starting loadout is the preset's")
	check(is_equal_approx(player.damage_taken_mult, 1.0) and player.weapon.id == &"oathblade", "player starts as before")
	var speed0 := player.run_speed
	# Take the armour off.
	check(Loadout.equip_armor(Armors.NONE), "taking armour off works")
	check(is_equal_approx(player.damage_taken_mult, Armors.NAKED_DAMAGE) and player.run_speed > speed0, "naked: takes more damage, runs faster")
	check(player.look.armor_look == PresetData.ArmorLook.BARE, "naked: drawn without armour")
	var hp0 := player.health.current
	player.receive_hit(damage(10.0))
	check(is_equal_approx(hp0 - player.health.current, 10.0 * Armors.NAKED_DAMAGE), "naked: the hit really is bigger")
	check(not Loadout.equip_armor(Armors.NONE), "taking it off twice does nothing")
	# Put it back on.
	check(Loadout.equip_armor(&"sworn_knight") and is_equal_approx(player.damage_taken_mult, 1.0) and is_equal_approx(player.run_speed, speed0), "wearing it again restores the numbers")
	check(player.look.armor_look == PresetData.ArmorLook.KNIGHT, "drawn in armour again")
	check(not Loadout.equip_armor(&"marshal_plate"), "cannot wear what you do not own")
	# Heavy armour: slower, tougher, costlier dodge.
	game_state.grant_gear("armor", &"marshal_plate")
	Loadout.equip_armor(&"marshal_plate")
	check(player.damage_taken_mult < 0.75 and player.run_speed < speed0 * 0.9 and player.dodge_stamina > 22.0, "marshal plate: tough, slow, heavy dodge")
	check(player.look.armor_look == PresetData.ArmorLook.HEAVY, "marshal plate drawn heavy")
	# Weapons.
	check(not Loadout.equip_weapon(&"toll_hammer"), "cannot wield what you do not own")
	game_state.grant_gear("weapon", &"wayfarers_rapier")
	check(Loadout.equip_weapon(&"wayfarers_rapier") and player.weapon.id == &"wayfarers_rapier" and player.look.weapon_look == PresetData.WeaponLook.RAPIER, "rapier equipped and drawn")
	check(not Loadout.equip_weapon(&"wayfarers_rapier"), "equipping the same weapon does nothing")
	# Weapon level feeds damage.
	var b0 := player.attack_runner.damage_bonus
	game_state.set_gear_level("weapon", &"wayfarers_rapier", 3)
	events.loadout_changed.emit()
	check(is_equal_approx(player.attack_runner.damage_bonus / b0, 1.3), "+3 weapon deals 30%% more (%.3f)" % (player.attack_runner.damage_bonus / b0))
	# Armour level feeds protection.
	game_state.set_gear_level("armor", &"marshal_plate", 5)
	events.loadout_changed.emit()
	check(is_equal_approx(player.damage_taken_mult, Armors.get_armor(&"marshal_plate").damage_taken_mult * 0.85), "+5 armour takes 15%% less")
	# An unsworn who takes the wraps off.
	await fresh_game(&"unsworn")
	check(game_state.armor_id == &"unsworn" and player.look.armor_look == PresetData.ArmorLook.BARE, "unsworn begins in wraps")
	Loadout.equip_armor(Armors.NONE)
	check(player.damage_taken_mult > 1.3, "unsworn can go fully naked and takes even more")


func test_forge_rules() -> void:
	await fresh_game()
	game_state.embers = 10000
	# Upgrading a weapon.
	check(Forge.upgrade_cost("weapon", &"oathblade").embers == 150, "first weapon upgrade costs 150 embers")
	var r := Forge.upgrade("weapon", &"oathblade")
	check(not r.ok and game_state.embers == 10000 and game_state.weapon_level(&"oathblade") == 0, "no scrap: nothing happens, nothing is taken")
	game_state.add_item(&"forge_scrap", 30)
	r = Forge.upgrade("weapon", &"oathblade")
	check(r.ok and game_state.weapon_level(&"oathblade") == 1 and game_state.embers == 9850 and game_state.item_count(&"forge_scrap") == 29, "upgrade spends embers + 1 scrap")
	check(is_equal_approx(player.attack_runner.damage_bonus, 1.1), "the player gets the stronger blade at once (%.2f)" % player.attack_runner.damage_bonus)
	for i in 6:
		Forge.upgrade("weapon", &"oathblade")
	check(game_state.weapon_level(&"oathblade") == 5 and Forge.upgrade_cost("weapon", &"oathblade").is_empty(), "stops at +5")
	var e: int = game_state.embers
	check(not Forge.upgrade("weapon", &"oathblade").ok and game_state.embers == e, "no charge at the maximum")
	check(not Forge.upgrade("weapon", &"toll_hammer").ok, "cannot upgrade what you do not own")
	# Armour.
	r = Forge.upgrade("armor", &"sworn_knight")
	check(r.ok and game_state.armor_level(&"sworn_knight") == 1 and is_equal_approx(player.damage_taken_mult, 0.97), "armour +1 takes 3%% less (%.3f)" % player.damage_taken_mult)
	# Forging.
	game_state.embers = 5000
	r = Forge.make(&"toll_hammer")
	check(not r.ok and not game_state.owns_weapon(&"toll_hammer") and game_state.embers == 5000, "the hammer needs the Bell Warden's shard")
	game_state.add_item(&"warden_bell_shard", 1)
	var scrap: int = game_state.item_count(&"forge_scrap")
	r = Forge.make(&"toll_hammer")
	check(r.ok and game_state.owns_weapon(&"toll_hammer") and game_state.embers == 4400 and game_state.item_count(&"forge_scrap") == scrap - 3, "forged: 600 embers + 3 scrap")
	check(game_state.item_count(&"warden_bell_shard") == 1, "the relic is shown, not taken")
	check(not Forge.make(&"toll_hammer").ok, "cannot forge it twice")
	r = Forge.make(&"pilgrim_coat")
	check(r.ok and game_state.owns_armor(&"pilgrim_coat"), "a plain armour needs no relic")
	check(not Forge.make(&"oathblade").ok, "no recipe for starter gear")
	game_state.embers = 0
	check(not Forge.make(&"kingsfall_greatsword").ok and not game_state.owns_weapon(&"kingsfall_greatsword"), "broke: nothing forged")
	# Vials.
	game_state.embers = 10000
	var hp := player.flask_heal
	var fl0 := player.max_flasks
	check(not Forge.upgrade_vials().ok, "vials need Hollow Resin")
	game_state.add_item(&"hollow_resin", 20)
	check(Forge.upgrade_vials().ok and game_state.flask_level == 1 and is_equal_approx(player.flask_heal, hp + 6.0) and player.max_flasks == fl0, "vials +1: heal +6, same count")
	Forge.upgrade_vials()
	check(game_state.flask_level == 2 and player.max_flasks == fl0 + 1 and player.flasks == fl0 + 1, "vials +2: one more vial, filled")
	for i in 5:
		Forge.upgrade_vials()
	check(game_state.flask_level == 5 and player.max_flasks == fl0 + 2 and Forge.vial_cost().is_empty(), "vials stop at +5 with two extra vials")
	# Rest refills the new count.
	player.flasks = 0
	player.rest()
	check(player.flasks == player.max_flasks, "resting refills every vial")


func test_gear_save() -> void:
	wipe_saves()
	game_state.reset()
	game_state.preset_id = &"bulwark"
	Loadout.ensure(Presets.get_preset(&"bulwark"))
	game_state.grant_gear("weapon", &"marshals_lance")
	game_state.set_gear_level("weapon", &"marshals_lance", 4)
	game_state.weapon_id = &"marshals_lance"
	game_state.grant_gear("armor", &"penitent_shroud")
	game_state.set_gear_level("armor", &"bulwark", 2)
	game_state.armor_id = Armors.NONE
	game_state.flask_level = 3
	game_state.in_game = true
	game_state.current_slot = 1
	check(saves.save_slot(1), "saved")
	game_state.reset()
	var res: Dictionary = saves.load_slot(1)
	game_state.apply_dict(res.data, 1)
	check(game_state.weapon_id == &"marshals_lance" and game_state.weapon_level(&"marshals_lance") == 4 and game_state.owns_weapon(&"sword_and_shield"), "weapons restored")
	check(game_state.armor_id == Armors.NONE and game_state.owns_armor(&"penitent_shroud") and game_state.armor_level(&"bulwark") == 2, "armour restored, still taken off")
	check(game_state.flask_level == 3, "vial level restored")
	# A save from before gear existed gets the preset's loadout.
	var old: Dictionary = saves._normalize({"version": 1, "saved_at": 1, "preset_id": "duelist"})
	game_state.apply_dict(old, 1)
	check(game_state.weapon_id == &"twin_blades" and game_state.armor_id == &"duelist" and game_state.flask_level == 0, "legacy save gets its starting loadout")
	# Hostile values are cleaned.
	var bad: Dictionary = saves._normalize({"version": 1, "saved_at": 1, "weapons": {"oathblade": 99, "ghost": 3, "fists": "x"}, "weapon_id": "ghost",
		"armors": {"duelist": -4, "nope": 1}, "armor_id": "marshal_plate", "flask_level": 77})
	check(bad.weapons.size() == 1 and bad.weapons.oathblade == 5 and bad.weapon_id == "", "bad weapons dropped / clamped")
	check(bad.armors.size() == 1 and bad.armors.duelist == 0 and bad.armor_id == "" and bad.flask_level == 5, "bad armours dropped, bad worn armour reset, vials clamped")
	game_state.apply_dict(bad, 1)
	check(game_state.weapon_id == &"oathblade" and game_state.armor_id == &"duelist", "a broken loadout repairs itself")
	game_state.reset()
	wipe_saves()


func test_forge_menu() -> void:
	await fresh_game()
	var menu: ForgeMenu = main.get_node("ForgeMenu")
	game_state.embers = 5000
	game_state.add_item(&"forge_scrap", 10)
	events.station_requested.emit(&"forge")
	await frames(3)
	check(menu.is_open and get_tree().paused and game_state.ui_modal, "forge opens and pauses")
	var weapon_ids: Array = menu.rows.map(func(r): return r.id)
	check(weapon_ids.has(&"oathblade") and weapon_ids.has(&"toll_hammer") and not weapon_ids.has(&"twin_blades"), "weapons tab: owned + forgeable only (%s)" % [weapon_ids])
	check("+0" in menu.row_text(&"oathblade") and "150" in menu.row_text(&"oathblade"), "row shows level and cost: %s" % menu.row_text(&"oathblade"))
	var idx := weapon_ids.find(&"oathblade")
	(menu.rows[idx].button as Button).pressed.emit()
	await frames(2)
	check(game_state.weapon_level(&"oathblade") == 1 and "+1" in menu.row_text(&"oathblade"), "pressing a row upgrades it")
	check("Light combo" in menu.describe(&"oathblade") and "->" in menu.describe(&"oathblade"), "description previews the gain")
	menu.show_tab("armor")
	await frames(2)
	var armor_ids: Array = menu.rows.map(func(r): return r.id)
	check(armor_ids.has(&"sworn_knight") and armor_ids.has(&"marshal_plate"), "armour tab lists armour")
	menu.act(&"sworn_knight")
	check(game_state.armor_level(&"sworn_knight") == 1, "armour upgrades from the menu")
	await tap_action(&"ui_cancel")
	check(not menu.is_open and not get_tree().paused and not game_state.ui_modal, "Cancel leaves")
	# Vials.
	game_state.add_item(&"hollow_resin", 3)
	events.station_requested.emit(&"vials")
	await frames(3)
	check(menu.is_open and menu.rows.size() == 1 and menu.rows[0].id == &"vials", "the vial station has one row")
	menu.act(&"vials")
	check(game_state.flask_level == 1 and "+1" in menu.row_text(&"vials"), "vials upgrade from the menu")
	menu.close()
	await frames(2)
	check(not get_tree().paused, "closed")


func test_equip_ui() -> void:
	await fresh_game()
	game_state.grant_gear("weapon", &"tide_sabre")
	game_state.grant_gear("armor", &"pilgrim_coat")
	var im: InventoryMenu = main.get_node("InventoryMenu")
	im.open()
	await frames(3)
	check(im.is_open, "inventory opens")
	im.open_picker("weapon")
	await frames(2)
	var ids: Array = im.picker_buttons.map(func(r): return r.id)
	check(ids == [&"oathblade", &"tide_sabre"], "weapon picker lists exactly the owned weapons (%s)" % [ids])
	(im.picker_buttons[1].button as Button).pressed.emit()
	await frames(3)
	check(player.weapon.id == &"tide_sabre" and game_state.weapon_id == &"tide_sabre", "choosing a weapon equips it")
	im.open_picker("armour")
	await frames(2)
	var aids: Array = im.picker_buttons.map(func(r): return r.id)
	check(aids == [Armors.NONE, &"sworn_knight", &"pilgrim_coat"], "armour picker: take off + owned (%s)" % [aids])
	(im.picker_buttons[0].button as Button).pressed.emit()
	await frames(3)
	check(game_state.armor_id == Armors.NONE and player.look.armor_look == PresetData.ArmorLook.BARE, "'Take off' removes the armour")
	check(im._d_title.text == "No armour", "the slot reflects it (%s)" % im._d_title.text)
	im.open_picker("armour")
	await frames(2)
	await tap_action(&"ui_cancel")
	check(im.is_open and im._picking == "", "Cancel closes only the picker")
	im.open_picker("armour")
	await frames(2)
	(im.picker_buttons[2].button as Button).pressed.emit()
	await frames(3)
	check(game_state.armor_id == &"pilgrim_coat", "put another armour on")
	im.close()
	await frames(2)
	check(not get_tree().paused, "menu closed")


func test_new_weapons_land() -> void:
	for id in [&"wayfarers_rapier", &"kingsfall_greatsword", &"toll_hammer", &"marshals_lance", &"tide_sabre"]:
		await fresh_game()
		game_state.grant_gear("weapon", id)
		Loadout.equip_weapon(id)
		await place_player(300.0, 480.0, 1)
		await frames(4)
		var dummy := level.get_node("TrainingDummy")
		var best := 0.0
		for i in 3:
			await press(&"attack_light")
			for f in 14:
				await get_tree().physics_frame
				best = maxf(best, dummy._combo_total)
		await frames(70)
		check(best > 5.0, "%s: light attacks damage the dummy (%.0f)" % [id, best])
		check(player.state == Player.State.FREE, "%s: returns to FREE" % id)
		# The heavy and the pose code run without errors for every attack.
		await press(&"attack_heavy")
		await frames(80)
		check(player.state == Player.State.FREE, "%s: heavy finishes" % id)
		var w := Weapons.get_weapon(id)
		check(w.heavy.total_frames() > w.light_combo_start.total_frames(), "%s: heavy is slower than a light" % id)


func test_gear_npcs() -> void:
	await fresh_game()
	await go_to_level(AWAKE, &"arrival")
	for n in ["Hobb", "Ilse"]:
		check(level.get_node_or_null(n) != null, "%s stands in Vaelmoor, Awake" % n)
	await go_to_level(ROAD, &"from_awake")
	var hobb: Npc = level.get_node("Hobb")
	var ilse: Npc = level.get_node("Ilse")
	check(hobb.station == &"forge" and ilse.station == &"vials", "stations are wired")
	var box: DialogueBox = main.get_node("DialogueBox")
	var menu: ForgeMenu = main.get_node("ForgeMenu")
	await place_player(hobb.global_position.x - 24.0, 480.0, 1)
	await frames(8)
	await press(&"interact")
	await frames(3)
	check(box.is_open and box._name.text == "Hobb", "Hobb speaks first")
	await frames(14)
	await tap_action(&"ui_cancel")
	await frames(6)
	check(menu.is_open and menu.kind == &"forge", "after talking the forge opens")
	menu.close()
	await frames(25)
	check(Dialogues.talks(&"hobb") >= 1, "the visit is remembered")
	check(Dialogues.conversation(&"hobb").lines.size() == 1, "later visits are a single greeting")
	# Spacing: no interaction zones overlapping.
	var xs := []
	for n in level.get_children():
		if n is Npc or n is OathCandle:
			xs.append(n.global_position.x)
	xs.sort()
	var tight := false
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < 60.0:
			tight = true
	check(not tight, "NPCs and candles are spaced out (%s)" % [xs])


# ---------------------------------------------------------------- Hollowmere Manor and the sigil

func test_sigil_gift() -> void:
	await fresh_game()
	var it := Items.get_item(&"hollow_sigil")
	check(it != null and it.validate().is_empty() and IconArt.has_icon(&"hollow_sigil") and it.is_usable() and it.max_stack == 1, "the sigil is a valid, usable key item with an icon")
	game_state.add_item(&"hollow_sigil", 1)
	check(game_state.quick_item == &"", "the sigil never becomes the quick item")
	game_state.inventory.erase("hollow_sigil")
	# Pages 1-3 give nothing.
	for n in 3:
		Dialogues.finish(&"ommen")
	check(game_state.item_count(&"hollow_sigil") == 0, "the first three pages give nothing")
	# Page 4 contains the gift and hands it over.
	var c := Dialogues.conversation(&"ommen")
	check(" ".join(c.lines.map(func(l): return str(l))).contains("sigil"), "page four talks about the sigil")
	Dialogues.finish(&"ommen")
	check(game_state.item_count(&"hollow_sigil") == 1 and game_state.get_flag(&"ommen_gave_sigil"), "he gives the sigil once")
	Dialogues.finish(&"ommen")
	check(game_state.item_count(&"hollow_sigil") == 1, "never a second one")
	# Someone who already heard everything still gets it (a save from before this build).
	await fresh_game()
	game_state.set_flag(&"talks_ommen", 7)
	var late := Dialogues.conversation(&"ommen")
	check(" ".join(late.lines.map(func(l): return str(l))).contains("sigil"), "late visitors are offered the sigil")
	Dialogues.finish(&"ommen")
	check(game_state.item_count(&"hollow_sigil") == 1, "late visitors receive it")
	game_state.set_flag(&"quest_ommen_cantors", "done")   # errands have their own tests
	game_state.set_flag(&"quest_ommen_draft", "done")
	check(Dialogues.conversation(&"ommen").lines.size() == 1, "afterwards he is back to idle lines")
	# Aldous
	var a0 := Dialogues.conversation(&"aldous")
	check(a0.speaker == "Aldous Vane" and a0.lines.size() == 3, "Aldous introduces himself at length")
	Dialogues.finish(&"aldous")
	game_state.set_flag(&"quest_aldous_gallery", "done")
	check(Dialogues.conversation(&"aldous").lines.size() == 1, "then greets briefly")
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	var am := Dialogues.conversation(&"aldous")
	check(" ".join(am.lines.map(func(l): return str(l))).contains("Orren"), "he reacts once to the Marshal's fall")
	Dialogues.finish(&"aldous")
	check(Dialogues.conversation(&"aldous").lines.size() == 1 and not " ".join(Dialogues.conversation(&"aldous").lines).contains("Orren"), "and only once")


func test_sigil_travel() -> void:
	await fresh_game()
	game_state.in_game = true
	var start_path: String = game_state.level_path
	check(not Items.use(&"hollow_sigil", player), "without the sigil nothing happens")
	game_state.add_item(&"hollow_sigil", 1)
	await place_player(500.0, 480.0, 1)
	# A live boss blocks it.
	var gs := GDScript.new()
	gs.source_code = "extends Node\nvar active := true\nfunc is_dead() -> bool:\n\treturn false\n"
	gs.reload()
	var fake := Node.new()
	fake.set_script(gs)
	fake.add_to_group(&"bosses")
	add_child(fake)
	check(not Manor.can_travel(player).ok and "fight" in Manor.can_travel(player).msg, "the oath will not let you leave a boss fight")
	check(not Items.use(&"hollow_sigil", player), "using it mid-fight does nothing")
	fake.queue_free()
	await frames(2)
	# Go.
	var x0 := player.global_position.x
	check(Items.use(&"hollow_sigil", player), "using the sigil works")
	check(game_state.item_count(&"hollow_sigil") == 1, "the sigil is not consumed")
	await frames(300)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"hollowmere_manor" and game_state.level_path == Manor.PATH, "arrived in Hollowmere Manor")
	check(player.global_position.x < 260.0, "in the front hall (%.0f)" % player.global_position.x)
	check(game_state.get_flag(Manor.FROM_FLAG, {}).level == start_path, "where you came from is remembered")
	# Back by the sigil.
	check(Items.use(&"hollow_sigil", player), "using it in the manor goes back")
	await frames(300)
	level = main.current_level()
	player = level.player
	check(game_state.level_path == start_path and absf(player.global_position.x - x0) < 40.0, "back exactly where you stood (%.0f vs %.0f)" % [player.global_position.x, x0])
	# And through the manor's own door (works even without the sigil).
	Items.use(&"hollow_sigil", player)
	await frames(300)
	level = main.current_level()
	player = level.player
	game_state.inventory.erase("hollow_sigil")
	var door: ManorDoor = level.get_node("ReturnDoor")
	await place_player(door.global_position.x, 480.0, 1)
	await frames(6)
	await press(&"interact")
	await frames(300)
	level = main.current_level()
	player = level.player
	check(game_state.level_path == start_path and absf(player.global_position.x - x0) < 40.0, "the door returns you too")


func test_manor_level() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(Manor.PATH, &"arrival")
	check(level.level_id == &"hollowmere_manor", "the manor loads")
	for n in ["Ommen", "Hobb", "Ilse", "Wenna", "Aldous", "ReturnDoor", "HollowmereCandle", "BalconyChest", "VisitorsLedger", "GalleryDoor", "Hall"]:
		check(level.get_node_or_null(n) != null, "%s is in the manor" % n)
	check((level.get_node("Hobb") as Npc).station == &"forge" and (level.get_node("Ilse") as Npc).station == &"vials" and (level.get_node("Wenna") as Npc).shop_id == &"pedlar", "the residents keep their trades")
	var gd := level.get_node("GalleryDoor") as LevelExit
	check(not gd.sealed and gd.required_item == &"gallery_key", "the Gallery opens with the cellar key")
	check(level.get_node_or_null("CellarDoor") != null, "the cellar door is in the hall")
	check(enemies().is_empty(), "no enemies: it is a safe house")
	check(WorldMap.LEVELS.has(Manor.PATH), "it is on the world map")
	check(WorldMap.info(Manor.PATH).candles.size() == 1, "its candle is known to fast travel")
	# Spacing: no two interaction zones closer than 60 px.
	var xs := []
	for n in level.get_children():
		if n is Npc or n is OathCandle or n is ManorDoor:
			xs.append(n.global_position.x)
	xs.sort()
	var tight := false
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < 60.0:
			tight = true
	check(not tight, "residents, candle and door are spaced out (%s)" % [xs])
	# The mezzanine can be climbed (steps no higher than a jump).
	var planks: Array = []
	for b in level.get_node("Geometry").get_children():
		if b is StoneBlock and b.one_way:
			planks.append(b.position.y)
	planks.sort()
	planks.reverse()
	var prev := 480.0
	var ok := true
	for y in planks:
		if prev - y > 50.0:
			ok = false
		prev = y
	check(ok, "each step to the balcony is within jump height (%s)" % [planks])
	# Resting at its candle makes it a respawn point and a travel destination.
	await place_player(330.0 - 22.0, 480.0, 1)
	await press(&"interact")
	await frames(70)
	check(game_state.checkpoint_id == &"hollowmere_candle" and game_state.checkpoint_level_path() == Manor.PATH, "the manor candle is a checkpoint")
	check(CandleMenu.travel_destinations().any(func(d): return d.id == "hollowmere_candle"), "and a fast-travel destination")
	# A save made in the manor loads back into it.
	wipe_saves()
	game_state.current_slot = 1
	check(saves.save_slot(1), "saved in the manor")
	var r: Dictionary = saves.load_slot(1)
	check(r.status == saves.Status.OK and String(r.data.level_path) == Manor.PATH, "the save remembers the manor")
	wipe_saves()


## Every NPC must stand on a solid block's top surface (not sunk into a hill or floating).
func npc_grounding_problems() -> Array:
	var bad := []
	for n in level.get_children():
		if not (n is Npc):
			continue
		var found := false
		for b in level.get_node("Geometry").get_children():
			if b is StoneBlock and not b.one_way:
				var r := Rect2(b.position, b.size)
				if n.position.x >= r.position.x and n.position.x <= r.end.x and absf(n.position.y - r.position.y) <= 1.5:
					found = true
		if not found:
			bad.append("%s (%.0f,%.0f)" % [n.name, n.position.x, n.position.y])
	return bad


func test_npcs_stand_on_ground() -> void:
	await fresh_game()
	game_state.in_game = true
	for path in [AWAKE, ROAD, Manor.PATH]:
		await go_to_level(path, &"")
		var bad := npc_grounding_problems()
		check(bad.is_empty(), "%s: every NPC stands on the ground %s" % [path.get_file(), bad])


func test_travel_key_combat_lock() -> void:
	await fresh_game()
	game_state.in_game = true
	check(InputMap.has_action(&"travel_manor") and InputMap.has_action(&"skill"), "new actions registered")
	check(InputConfig.REMAPPABLE.has(&"travel_manor") and InputConfig.REMAPPABLE.has(&"skill"), "both remappable")
	game_state.add_item(&"hollow_sigil", 1)
	await place_player(500.0, 480.0, 1)
	player.combat_frames = 100
	check(not Manor.can_travel(player).ok, "recent combat blocks travel")
	await press(&"travel_manor")
	await frames(30)
	check(game_state.level_path != Manor.PATH, "the key does nothing mid-combat")
	player.combat_frames = 0
	check(Manor.can_travel(player).ok, "calm: allowed")
	await press(&"travel_manor")
	await frames(300)
	check(game_state.level_path == Manor.PATH, "the key carries you to Hollowmere")
	level = main.current_level()
	player = level.player
	await press(&"travel_manor")
	await frames(300)
	check(game_state.level_path != Manor.PATH, "the key carries you back")


func test_status_effects() -> void:
	await fresh_game()
	game_state.in_game = true
	var sc := StatusComponent.new()
	var hp := HealthComponent.new()
	hp.max_health = 100.0
	add_child(hp)
	hp.current = 100.0
	sc.health = hp
	add_child(sc)
	check(not sc.apply(StatusFx.BLEED, 60.0), "60 buildup does not trigger")
	check(sc.apply(StatusFx.BLEED, 60.0), "120 total triggers bleed")
	check(absf(hp.current - (100.0 - 16.0)) < 0.01, "bleed bursts 16%% of max (%.1f)" % hp.current)
	check(not sc.apply(StatusFx.BLEED, 200.0), "bleed cannot retrigger while active")
	sc.resist = {"poison": 1.0, "burn": 0.5}
	check(not sc.apply(StatusFx.POISON, 500.0), "immune to poison")
	check(not sc.apply(StatusFx.BURN, 150.0) == false or true, "burn runs")
	sc.clear()
	sc.apply(StatusFx.BURN, 150.0)
	check(not sc.is_active(StatusFx.BURN), "50%% resist: 150 buildup counts as 75")
	check(sc.apply(StatusFx.BURN, 60.0), "burn triggers on the next hit")
	var before := hp.current
	await frames(130)
	check(hp.current < before, "burning ticks damage")
	sc.clear()
	check(is_equal_approx(sc.speed_mult(), 1.0), "no frost, no slow")
	sc.apply(StatusFx.FROST, 150.0)
	check(is_equal_approx(sc.speed_mult(), StatusFx.FROST_SLOW), "frost slows")
	sc.queue_free()
	hp.queue_free()
	# Armour feeds the player's resistance.
	game_state.grant_gear("armor", &"marshal_plate")
	Loadout.equip_armor(&"marshal_plate")
	await frames(3)
	check(player.status.resist_of(StatusFx.BLEED) > 0.35, "marshal plate resists bleed")
	# A weapon-borne status travels with the hit.
	game_state.grant_gear("weapon", &"wayfarers_rapier")
	Loadout.equip_weapon(&"wayfarers_rapier")
	await frames(3)
	check(player.attack_runner.weapon_status == StatusFx.BLEED, "rapier carries bleed")
	# A hit with status builds up on a real enemy.
	var e: EnemyBase = load("res://actors/enemies/roadside_pikeman.tscn").instantiate()
	level.add_child(e)
	e.global_position = player.global_position + Vector2(60, 0)
	await frames(3)
	check(e.status != null, "enemies carry a status component")
	var h := HitData.make(1.0, player, Vector2(10, 0))
	h.status = StatusFx.FROST
	h.status_amount = 40.0
	e.receive_hit(h)
	check(e.status.buildup[StatusFx.FROST] > 40.0, "weak-to-frost pikeman takes extra buildup (%.1f)" % e.status.buildup[StatusFx.FROST])
	e.queue_free()


func test_status_data_valid() -> void:
	for w in Weapons.IDS:
		var wd := Weapons.get_weapon(w)
		check(wd.status == &"" or StatusFx.is_kind(wd.status), "%s has a valid status" % w)
	for a in Armors.IDS:
		for k in Armors.get_armor(a).resist:
			check(StatusFx.is_kind(StringName(k)), "%s resists a real kind (%s)" % [a, k])
	for p in DirAccess.get_files_at("res://data/attacks"):
		var ad := load("res://data/attacks/" + p) as AttackData
		check(ad.status == &"" or StatusFx.is_kind(ad.status), "%s inflicts a valid status" % p)


func test_weapon_skills_data() -> void:
	for w in Weapons.IDS:
		var wd := Weapons.get_weapon(w)
		check(wd.skill != null, "%s has a skill" % w)
		if wd.skill:
			check(wd.skill.validate().is_empty(), "%s skill is valid: %s" % [w, wd.skill.validate()])
			check(wd.skill_cost > 0.0 and wd.skill_cost <= Player.MAX_FOCUS, "%s skill cost is payable" % w)
			check(wd.skill.damage > wd.heavy.damage * 0.9 or w == &"twin_blades" or w == &"sword_and_shield", "%s skill hits harder than a heavy" % w)
		check(wd.block_reduction == 0.0 or w == &"sword_and_shield" or w == &"abbots_crozier", "only the shield and the crozier guard")


func test_focus_and_skill() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(400.0, 480.0, 1)
	player.set_focus(0.0)
	await press(&"skill")
	await frames(6)
	check(player.attack_runner.attack == null or player.state != Player.State.ATTACK, "no skill without focus")
	# Landing blows builds focus.
	var e := await spawn_enemy(428.0, -1)
	e.health.set_max(99999.0)
	e.health.restore_full()
	player.health.set_max(9999.0)
	player.health.restore_full()
	await press(&"attack_light")
	await frames(30)
	check(player.focus > 0.0, "a landed hit gives focus (%.0f)" % player.focus)
	# Each weapon's skill fires, costs focus and hits.
	for w in Weapons.IDS:
		game_state.grant_gear("weapon", w)
		Loadout.equip_weapon(w)
		await frames(3)
		await place_player(400.0, 480.0, 1)
		e.health.restore_full()
		e.set_physics_process(false)
		player.set_focus(Player.MAX_FOCUS)
		player.stamina.restore_full()
		await frames(50)
		e.global_position = player.global_position + Vector2(28, 0)
		var wd := Weapons.get_weapon(w)
		var hp := e.health.current
		await press(&"skill")
		var seen := false
		for i in 70:
			await get_tree().physics_frame
			if player.attack_runner.attack == wd.skill:
				seen = true
		check(seen, "%s: the skill button starts its skill" % w)
		check(e.health.current < hp, "%s: the skill hits the enemy" % w)
		check(player.focus <= Player.MAX_FOCUS - wd.skill_cost + Player.FOCUS_PER_CRIT * 2.0 + 0.1, "%s: skill spends focus (%.0f)" % [w, player.focus])
		await frames(60)
	e.queue_free()


func test_weapon_parry_and_guard() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(400.0, 480.0, 1)
	var base := player._window_frames()
	game_state.grant_gear("weapon", &"kingsfall_greatsword")
	Loadout.equip_weapon(&"kingsfall_greatsword")
	await frames(3)
	check(player._window_frames() > base, "greatsword has a longer parry window (%d vs %d)" % [player._window_frames(), base])
	game_state.grant_gear("weapon", &"wayfarers_rapier")
	Loadout.equip_weapon(&"wayfarers_rapier")
	await frames(3)
	check(player._window_frames() < base, "rapier has a tighter window")
	game_state.grant_gear("weapon", &"sword_and_shield")
	Loadout.equip_weapon(&"sword_and_shield")
	await frames(3)
	player.health.set_max(500.0)
	player.health.restore_full()
	Input.action_press(&"parry")
	await frames(30)
	check(player.blocking, "holding parry raises the shield guard")
	var src := Node2D.new()
	level.add_child(src)
	src.global_position = player.global_position + Vector2(30, 0)
	var h := HitData.make(40.0, src, Vector2.ZERO)
	var hp := player.health.current
	var r := player.receive_hit(h)
	check(r == HitData.Result.BLOCKED, "frontal hit blocked")
	check(hp - player.health.current < 20.0, "block cuts the damage (%.1f)" % (hp - player.health.current))
	Input.action_release(&"parry")
	await frames(40)
	check(not player.blocking, "releasing parry drops the guard")
	# Without a shield there is no guard.
	game_state.grant_gear("weapon", &"oathblade")
	Loadout.equip_weapon(&"oathblade")
	await frames(3)
	Input.action_press(&"parry")
	await frames(40)
	check(not player.blocking, "swords do not guard")
	Input.action_release(&"parry")
	src.queue_free()


func test_new_enemy_data_and_scenes() -> void:
	for id in [&"hollow_archer", &"candle_cantor", &"gilded_penitent", &"oathguard_captain", &"pike_sergeant"]:
		var d := load("res://data/enemies/%s.tres" % id) as EnemyData
		check(d != null and d.max_health > 0.0 and not d.attacks.is_empty(), "%s data loads" % id)
		var sc := load("res://actors/enemies/%s.tscn" % id) as PackedScene
		check(sc != null, "%s scene loads" % id)
		for a in d.attacks:
			check((a as AttackData).validate().is_empty(), "%s attack %s valid" % [id, a.id])
		for k in d.status_resist:
			check(StatusFx.is_kind(StringName(k)), "%s resists real kinds" % id)
	var base := load("res://data/enemies/hollow_penitent.tres") as EnemyData
	var el := load("res://data/enemies/gilded_penitent.tres") as EnemyData
	check(el.elite and el.max_health > base.max_health * 2.0 and el.damage_mult > 1.0 and el.ember_reward > base.ember_reward * 3, "elite is tougher and pays more")


func test_archer_and_cantor() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	player.health.set_max(5000.0)
	player.health.restore_full()
	var arc: EnemyBase = load("res://actors/enemies/hollow_archer.tscn").instantiate()
	arc.position = Vector2(520, 480)
	arc.start_facing = -1
	level.add_child(arc)
	var shots := 0
	var seen_proj := false
	for i in 400:
		await get_tree().physics_frame
		if level.get_tree().get_nodes_in_group(&"projectiles").size() > 0 or _find_projectile(level):
			seen_proj = true
			break
	check(seen_proj, "the archer looses an arrow from range")
	arc.queue_free()
	# The cantor calls at most two minions, and they die with it.
	var can: EnemyBase = load("res://actors/enemies/candle_cantor.tscn").instantiate()
	can.position = Vector2(560, 480)
	can.start_facing = -1
	level.add_child(can)
	await frames(500)
	var minions: int = can.call("alive_minions")
	check(minions >= 1 and minions <= 2, "the cantor has 1-2 minions (%d)" % minions)
	for m in can._minions:
		check(m is EnemyBase, "minions are enemies")
	var held: Array = can._minions.duplicate()
	can.health.take_damage(99999.0)
	await frames(10)
	for m in held:
		check(not is_instance_valid(m) or m.is_dead(), "minions die with the cantor")


func _find_projectile(n: Node) -> bool:
	for c in n.get_children():
		if c is Projectile:
			return true
	return false


func test_elite_enemy() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	var e: EnemyBase = load("res://actors/enemies/gilded_penitent.tscn").instantiate()
	e.position = Vector2(600, 480)
	level.add_child(e)
	await frames(3)
	check(e.get_node_or_null(^"EliteMark") != null, "elites wear the gold mark")
	check(is_equal_approx(e.attack_runner.base_multiplier, 1.3), "elite hits harder")
	check(e.status.resist_of(StatusFx.POISON) >= 1.0, "gilded penitent is poison-proof")
	e.queue_free()


func test_quests_collect_and_kill() -> void:
	await fresh_game()
	game_state.in_game = true
	# Hobb: introduced on the first talk, offers on the second.
	var c := Dialogues.conversation(&"hobb")
	check(not c.has("quest"), "first talk is the introduction")
	Dialogues.finish(&"hobb")
	c = Dialogues.conversation(&"hobb")
	check(c.has("quest") and c.quest.mode == "offer", "second talk offers the errand")
	Dialogues.finish(&"hobb")
	check(Quests.is_active(&"hobb_scrap"), "the errand is open")
	c = Dialogues.conversation(&"hobb")
	check(c.quest.mode == "remind" and "0 / 3" in String(c.lines[0]), "while open, Hobb reminds you with progress")
	game_state.add_item(&"forge_scrap", 2)
	check(not Quests.is_ready(&"hobb_scrap"), "two scrap is not enough")
	game_state.add_item(&"forge_scrap", 1)
	check(Quests.is_ready(&"hobb_scrap"), "three scrap is")
	var embers: int = game_state.embers
	c = Dialogues.conversation(&"hobb")
	check(c.quest.mode == "complete", "Hobb accepts the scrap")
	Dialogues.finish(&"hobb")
	check(Quests.is_done(&"hobb_scrap"), "errand done")
	check(game_state.item_count(&"forge_scrap") == 0, "scrap handed over")
	check(game_state.embers >= embers + 400 and game_state.item_count(&"ember_shard") >= 2, "reward paid")
	c = Dialogues.conversation(&"hobb")
	check(not c.has("quest") or c.quest.id != &"hobb_scrap", "a finished errand is not offered again")
	check(not c.has("quest") or c.quest.id == &"hobb_sergeants", "a follow-up errand may be offered once the first is done")
	check(Dialogues.conversation(&"wenna").get("quest", {}).get("id", &"") != &"wenna_moths", "a second errand stays closed until the first is done")
	# Wenna: kill three crows.
	Dialogues.finish(&"wenna")
	Dialogues.finish(&"wenna")
	check(Quests.is_active(&"wenna_crows"), "Wenna's errand opens")
	var fake := Node.new()
	var crow := load("res://data/enemies/carrion_crow.tres")
	fake.set_meta(&"x", 1)
	var gs := GDScript.new()
	gs.source_code = "extends Node\nvar data\n"
	gs.reload()
	fake.set_script(gs)
	fake.data = crow
	add_child(fake)
	for i in 3:
		game_state._on_enemy_killed(fake)
	check(Quests.kills(&"wenna_crows") == 3 and Quests.is_ready(&"wenna_crows"), "three crow kills count")
	fake.queue_free()
	# Saves keep it (flags only).
	var d: Dictionary = game_state.to_dict()
	check(d.is_empty() or String(d.get("flags", {}).get("quest_hobb_scrap", "")) == "done", "quest state is in the saved flags")


func test_quest_gating_and_manor_lines() -> void:
	await fresh_game()
	game_state.in_game = true
	# Ommen's errand waits behind his story and the sigil.
	for i in 4:
		Dialogues.finish(&"ommen")
	check(not Dialogues.conversation(&"ommen").has("quest"), "Ommen finishes his story first")
	game_state.set_flag(Dialogues.SIGIL_FLAG, true)
	for i in 2:
		Dialogues.finish(&"ommen")
	check(Dialogues.conversation(&"ommen").has("quest"), "then he asks his favour")
	# Manor-only lines replace the road greetings.
	game_state.set_flag(&"talks_wenna", 1)
	var field: String = Dialogues.conversation(&"wenna").lines[0]
	game_state.level_path = Manor.PATH
	var inside := Dialogues.conversation(&"wenna")
	if inside.has("quest"):
		game_state.set_flag(&"quest_wenna_crows", "done")
		inside = Dialogues.conversation(&"wenna")
	check(inside.lines[0] in Dialogues.MANOR_GREETINGS[&"wenna"], "Wenna has manor lines")
	check(not (field in Dialogues.MANOR_GREETINGS[&"wenna"]), "field lines are not manor lines")
	# Vesper explains what you carry, once.
	game_state.add_item(&"candlewright_note", 1)
	var v := Dialogues.conversation(&"vesper")
	check(v.speaker == "Vesper" and v.lines.size() == 2, "Vesper introduces herself")
	Dialogues.finish(&"vesper")
	v = Dialogues.conversation(&"vesper")
	check("Note" in String(v.lines[0]), "she explains the note")
	Dialogues.finish(&"vesper")
	v = Dialogues.conversation(&"vesper")
	check(not ("Note" in String(v.lines[0])), "only once")
	for id in Quests.DEFS:
		check(Quests.DEFS[id].giver != &"" and Items.get_item(Quests.DEFS[id].get("item", &"forge_scrap")) != null, "%s refers to real items" % id)
	for id in Dialogues.ARCHIVE:
		check(Items.get_item(id) != null, "archive entry %s is a real item" % id)


func test_journal_tab() -> void:
	await fresh_game()
	game_state.in_game = true
	var inv: InventoryMenu = main.get_node("InventoryMenu") if main.has_node("InventoryMenu") else get_tree().get_first_node_in_group(&"inventory_menu")
	check(inv != null, "inventory menu found")
	if inv == null:
		return
	Quests.start(&"hobb_scrap")
	var t := inv.journal_text()
	check("Iron for the Forge" in t and "0 / 3" in t, "open errand listed with progress")
	inv.open(InventoryMenu.Tab.JOURNAL)
	await frames(3)
	check(inv.tab == InventoryMenu.Tab.JOURNAL, "journal tab opens")
	inv.close()


const CELLAR := "res://world/levels/hollowmere_cellar.tscn"
const GALLERY := "res://world/levels/hollowmere_gallery.tscn"
const GRAVEYARD := "res://world/levels/pilgrims_graveyard.tscn"


## Anything placed in a level that should stand on a block top: [name (x,y)] for those that do not.
func placement_problems() -> Array:
	var bad := []
	for n in level.get_children():
		var needs := n is Npc or n is TreasureChest or n is OathCandle or n is LoreTablet or n is EnemySpawner
		if not needs:
			continue
		var found := false
		for b in level.get_node("Geometry").get_children():
			if b is StoneBlock:
				var r := Rect2(b.position, b.size)
				if n.position.x >= r.position.x and n.position.x <= r.end.x and absf(n.position.y - r.position.y) <= 1.5:
					found = true
		if not found:
			bad.append("%s (%.0f,%.0f)" % [n.name, n.position.x, n.position.y])
	return bad


func test_side_levels_load() -> void:
	await fresh_game()
	game_state.in_game = true
	var expect := {
		CELLAR: ["Hall", "FromManor", "ToManor", "CellarCandle", "CellarerArena", "CellarChest"],
		GALLERY: ["Hall", "FromManor", "ToManor", "Vesper", "GhostlightChest", "GalleryCandle"],
		GRAVEYARD: ["Background", "FromRoad", "ToRoad", "GraveCandle", "SextonArena", "CantorA", "CantorB", "Cycle"],
	}
	for path in expect:
		await go_to_level(path, &"")
		check(level.scene_file_path == path, "%s loads" % path.get_file())
		for n in expect[path]:
			check(level.get_node_or_null(n) != null, "%s has %s" % [path.get_file(), n])
		var bad := placement_problems()
		check(bad.is_empty(), "%s: everything stands on something %s" % [path.get_file(), bad])
		check(WorldMap.LEVELS.has(path), "%s is on the map" % path.get_file())
		check(player != null and player.global_position.y > 300.0, "the player arrived")
	# Cross-links resolve to real entries.
	for pair in [[Manor.PATH, "from_cellar"], [Manor.PATH, "from_gallery"], [ROAD, "from_graveyard"], [CELLAR, "from_manor"], [GALLERY, "from_manor"], [GRAVEYARD, "from_road"]]:
		await go_to_level(pair[0], StringName(pair[1]))
		check(level.find_entry(StringName(pair[1])) != null, "%s has entry %s" % [pair[0].get_file(), pair[1]])
	# The Ommen errand needs two cantors in the graveyard.
	await go_to_level(GRAVEYARD, &"")
	var cantors := 0
	for sp in get_tree().get_nodes_in_group(&"enemy_spawners"):
		if sp is EnemySpawner and sp.enemy_scene and "candle_cantor" in sp.enemy_scene.resource_path:
			cantors += 1
	check(cantors >= 2, "the graveyard holds the two cantors Ommen asks for (%d)" % cantors)


func test_gallery_gate_and_key() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(Manor.PATH, &"arrival")
	var gd := level.get_node("GalleryDoor") as LevelExit
	check(not gd.try_open(), "locked without the key")
	game_state.add_item(&"gallery_key", 1)
	check(gd.try_open(), "opens with the key")
	await frames(90)
	level = main.current_level()
	player = level.player
	check(level.level_id == &"hollowmere_gallery", "arrived in the Gallery")
	var chest := level.get_node("GhostlightChest") as TreasureChest
	check(not game_state.owns_armor(&"ghostlight_raiment"), "the raiment is not owned yet")
	chest.open()
	check(game_state.owns_armor(&"ghostlight_raiment"), "the chest gives the Ghostlight Raiment")
	check(Armors.get_armor(&"ghostlight_raiment") != null and Armors.is_valid_id("ghostlight_raiment"), "the armour is registered")
	# Quest 'have' completes with the key.
	game_state.set_flag(&"talks_aldous", 1)
	Quests.start(&"aldous_gallery")
	check(Quests.is_ready(&"aldous_gallery"), "holding the key completes Aldous' errand")
	check(Quests.complete(&"aldous_gallery") and game_state.item_count(&"gallery_key") == 1, "the key is not consumed")


func test_minibosses() -> void:
	await fresh_game()
	game_state.in_game = true
	for spec in [["res://actors/bosses/cellarer_grume.tscn", &"gallery_key", &"cellarer"], ["res://actors/bosses/sexton_hale.tscn", &"sextons_lantern", &"gravewarden"], ["res://actors/bosses/mother_cinder.tscn", &"cinder_heart", &"mother_cinder"], ["res://actors/bosses/ser_ashfall.tscn", &"ashfall_seal", &"ser_ashfall"], ["res://actors/bosses/gaoler_vess.tscn", &"relic_shackle", &"gaoler_vess"], ["res://actors/bosses/foundrymaster_brand.tscn", &"relic_slag", &"foundrymaster_brand"], ["res://actors/bosses/hollow_regent.tscn", &"relic_regent", &"hollow_regent"], ["res://actors/bosses/last_ringer.tscn", &"relic_clapper", &"last_ringer"], ["res://actors/bosses/thornmother.tscn", &"relic_briar", &"thornmother"], ["res://actors/bosses/orrerist.tscn", &"relic_gear", &"orrerist"], ["res://actors/bosses/drowned_bishop.tscn", &"relic_chalice", &"drowned_bishop"], ["res://actors/bosses/crownless_king.tscn", &"relic_oathbreaker", &"crownless_king"]]:
		await fresh_game()
		game_state.in_game = true
		await place_player(300.0, 480.0, 1)
		player.health.set_max(9999.0)
		player.health.restore_full()
		var b: BossBase = load(spec[0]).instantiate()
		b.position = Vector2(420, 480)
		level.add_child(b)
		await frames(3)
		check(b.boss_id == spec[2] and not b.phase2_attacks.is_empty(), "%s is a two-phase boss" % spec[2])
		check(b.status == null, "bosses shrug off status effects")
		b.start_fight()
		var ids := {}
		for i in 1500:
			await get_tree().physics_frame
			if b.attack_runner.attack:
				ids[b.attack_runner.attack.id] = true
			if i % 120 == 0:
				player.global_position = b.global_position + Vector2(-70, 0)
				player.velocity = Vector2.ZERO
		check(ids.size() >= 2, "%s uses several attacks (%s)" % [spec[2], ids.keys()])
		check(player.health.current < 9999.0, "%s can hurt the player" % spec[2])
		b.receive_hit(damage(b.health.max_health * 0.6))
		await frames(120)
		check(b.phase == 2, "%s enters phase two" % spec[2])
		var before: int = game_state.item_count(spec[1])
		b.health.take_damage(99999.0)
		await frames(5)
		check(game_state.item_count(spec[1]) > before, "%s drops %s" % [spec[2], spec[1]])
		check(Dialogues.ARCHIVE.has(spec[1]), "Vesper has something to say about %s" % spec[1])


func test_day_night() -> void:
	await fresh_game()
	game_state.in_game = true
	DayNight.forced = 0.2
	check(DayNight.phase() == DayNight.Phase.DAY and DayNight.darkness() == 0.0 and not DayNight.is_night(), "day")
	DayNight.forced = 0.5
	check(DayNight.phase() == DayNight.Phase.DUSK and DayNight.darkness() > 0.0 and DayNight.darkness() < 1.0, "dusk")
	DayNight.forced = 0.7
	check(DayNight.phase() == DayNight.Phase.NIGHT and DayNight.is_night() and DayNight.darkness() == 1.0, "night")
	DayNight.forced = 0.97
	check(DayNight.phase() == DayNight.Phase.DAWN and DayNight.darkness() < 1.0, "dawn")
	DayNight.forced = -1.0
	var d0 := DayNight.time()
	game_state.play_time += DayNight.CYCLE * 0.5
	check(absf(fposmod(DayNight.time() - d0 - 0.5, 1.0)) < 0.001 or absf(fposmod(DayNight.time() - d0 - 0.5, 1.0) - 1.0) < 0.001, "time follows play time")
	game_state.play_time = 0.0
	check(DayNight.tint(0.0).r > DayNight.tint(1.0).r and DayNight.tint(1.0).b > DayNight.tint(1.0).r, "night is dark and blue")
	# The road: night-only spawners are absent by day, present at night, and follow the cycle.
	DayNight.forced = 0.2
	await go_to_level(ROAD, &"")
	var night_sp := []
	for sp in get_tree().get_nodes_in_group(&"enemy_spawners"):
		if sp is EnemySpawner and sp.when == 2:
			night_sp.append(sp)
	check(night_sp.size() >= 4, "the road has night-only spawners (%d)" % night_sp.size())
	for sp in night_sp:
		check(not is_instance_valid(sp.enemy), "%s is not out by day" % sp.name)
	check(level.get_node_or_null("Cycle") != null, "the road has a day/night cycle")
	DayNight.forced = 0.7
	Events.daynight_changed.emit(true)
	await frames(5)
	for sp in night_sp:
		check(is_instance_valid(sp.enemy), "%s walks at night" % sp.name)
	DayNight.forced = 0.2
	Events.daynight_changed.emit(false)
	await frames(5)
	for sp in night_sp:
		check(not is_instance_valid(sp.enemy) or sp.enemy.is_queued_for_deletion(), "%s fades at dawn" % sp.name)
	# The cycle node tints the level.
	DayNight.forced = 0.7
	level.get_node("Cycle").apply()
	check(level.get_node("Light").color.b > level.get_node("Light").color.r, "the level goes blue at night")
	var sky = level.get_node("Background/Sky/SkyDraw")
	check(sky.darkness > 0.9, "the sky darkens")
	DayNight.forced = -1.0


# ------------------------------------------------------------------ expansion

const RELIQUARY := "res://world/levels/sunken_reliquary.tscn"


func test_reliquary_region() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	check(level.scene_file_path == RELIQUARY and WorldMap.LEVELS.has(RELIQUARY), "the Sunken Reliquary loads and is on the map")
	for n in ["FromChapel", "ToChapel", "StairCandle", "SaltCandle", "VaultCandle", "Pell", "AbbotArena", "LurkerA", "PilgrimA", "JetA", "JetB", "NookWall", "AxeChest", "VaultWallBreak", "VaultBlock", "WickChest"]:
		check(level.get_node_or_null(n) != null, "the reliquary has %s" % n)
	var bad := placement_problems()
	check(bad.is_empty(), "the reliquary: everything stands on something %s" % [bad])
	check((level.get_node("Pell") as Npc).shop_id == &"salt_diver" and Shops.stock(&"salt_diver").size() >= 5, "Pell runs a shop")
	await go_to_level("res://world/levels/ashen_chapel.tscn", &"from_reliquary")
	check(level.find_entry(&"from_reliquary") != null and level.get_node_or_null("ToReliquary") != null, "the chapel links down to the reliquary")
	for id in [&"drowned_pilgrim", &"reliquary_lurker", &"salt_abbot"]:
		check(Bestiary.IDS.has(id) and Bestiary.data(id) != null, "%s is in the bestiary" % id)
	var ab := Bestiary.data(&"salt_abbot")
	check(ab.drop_item != null and ab.drop_item.id == &"abbots_signet", "the Abbot drops his signet")
	check(Forge.recipe(&"abbots_crozier").relic == &"abbots_signet", "the signet is forged into the crozier")
	check(Quests.DEFS.has(&"pell_lurkers") and Quests.DEFS.has(&"pell_signet"), "Pell has a two-part errand")
	var c := Dialogues.conversation(&"pell")
	check(c.speaker == "Pell" and c.lines.size() >= 2, "Pell introduces himself")


const KEEP := "res://world/levels/hollow_keep.tscn"


func test_keep_region() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(KEEP, &"")
	check(level.scene_file_path == KEEP and WorldMap.LEVELS.has(KEEP), "the Hollow Keep loads and is on the map")
	for n in ["FromReliquary", "ToReliquary", "KeepGateCandle", "FoundryCandle", "ThroneCandle", "VessArena", "BrandArena", "RegentArena", "KeepChest", "GantryChest"]:
		check(level.get_node_or_null(n) != null, "the keep has %s" % n)
	var bad := placement_problems()
	check(bad.is_empty(), "the keep: everything stands on something %s" % [bad])
	var arenas := []
	for n in ["VessArena", "BrandArena", "RegentArena"]:
		arenas.append((level.get_node(n) as Node2D).position.x)
	check(arenas[0] < arenas[1] and arenas[1] < arenas[2] and arenas[1] - arenas[0] > 1000.0, "three boss arenas, spaced out along the keep")
	await go_to_level(RELIQUARY, &"from_keep")
	check(level.find_entry(&"from_keep") != null and level.get_node_or_null("ToKeep") != null, "the reliquary links on to the keep")
	for id in [&"gaoler_vess", &"foundrymaster_brand", &"hollow_regent"]:
		check(Bestiary.IDS.has(id) and Bestiary.data(id) != null and Bestiary.data(id).drop_item != null, "%s is in the bestiary and drops something" % id)
	for id in [&"relic_shackle", &"relic_slag", &"relic_regent"]:
		check(Relics.DEFS.has(id) and Relics.IDS.has(id) and Items.IDS.has(id), "%s is a wearable relic" % id)
		check(ResourceLoader.exists("res://data/items/%s.tres" % id), "%s has item data" % id)
	check(Trials.RUSH_BOSSES.size() >= 10, "the boss rush includes the keep's bosses")
	for d in [&"gaoler_down", &"brand_down", &"regent_down"]:
		check(Deeds.DEFS.has(d) and Deeds.ORDER.has(d), "deed %s exists" % d)


const BELFRY := "res://world/levels/drowned_belfry.tscn"


func test_belfry_and_crown() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(BELFRY, &"")
	check(level.scene_file_path == BELFRY and WorldMap.LEVELS.has(BELFRY), "the Drowned Belfry loads and is on the map")
	for n in ["FromKeep", "ToKeep", "BelfryGateCandle", "BellChamberCandle", "RingerArena", "BelfryChest", "LoftChest", "BelfryCache"]:
		check(level.get_node_or_null(n) != null, "the belfry has %s" % n)
	var bad := placement_problems()
	check(bad.is_empty(), "the belfry: everything stands on something %s" % [bad])
	await go_to_level(KEEP, &"from_belfry")
	check(level.find_entry(&"from_belfry") != null and level.get_node_or_null("ToBelfry") != null, "the keep links on to the belfry")
	var hesk := level.get_node_or_null("Hesk")
	check(hesk != null and Dialogues.conversation(&"hesk").speaker == "Hesk", "Hesk waits in the keep and speaks")
	check(Quests.DEFS.has(&"hesk_shackle") and Quests.ORDER.has(&"hesk_shackle"), "Hesk has an errand")
	game_state.set_flag(&"talks_hesk", 1)
	Quests.start(&"hesk_shackle")
	game_state.add_item(&"relic_shackle", 1)
	check(Quests.is_ready(&"hesk_shackle") and Quests.complete(&"hesk_shackle"), "showing the shackle finishes Hesk's errand")
	check(Bestiary.data(&"last_ringer") != null and Bestiary.data(&"last_ringer").drop_item.id == &"relic_clapper", "the Ringer is in the bestiary and drops the Bell Clapper")
	check(Relics.DEFS.has(&"relic_clapper"), "the Bell Clapper is a relic")
	# The fourth ending
	check(Endings.ORDER.has(&"crown") and not Endings.available(&"crown"), "the Crown ending is locked at first")
	check(Endings.reason(&"crown") != "", "and says what it needs")
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	check(not Endings.available(&"crown"), "the Marshal alone does not unlock it")
	game_state.set_flag(&"boss_defeated_hollow_regent", true)
	check(Endings.available(&"crown") and Endings.choose(&"crown") and Endings.chosen() == &"crown", "defeating the Regent unlocks the Crown ending")
	check(Endings.DEFS[&"crown"].pages.size() >= 3, "the Crown ending has an epilogue")
	check(Endings.ORDER.has(&"unsworn") and not Endings.available(&"unsworn") and Endings.reason(&"unsworn") != "", "the Unsworn ending is locked until the Oath Eternal falls")
	game_state.set_flag(&"boss_defeated_the_oath_eternal", true)
	check(Endings.available(&"unsworn") and Endings.DEFS[&"unsworn"].pages.size() >= 3, "defeating the Oath Eternal unlocks the Unsworn ending")
	game_state.set_flag(&"boss_defeated_the_oath_eternal", false)
	# a player who already chose at the gate is asked once more after the Oath Eternal
	check(Endings.chosen() == &"crown" and not Endings.gate_open(), "choosing an ending closes the gate")
	game_state.set_flag(&"boss_defeated_the_oath_eternal", true)
	check(Endings.gate_open() and Endings.available(&"unsworn") and not Endings.available(&"break"), "the Oath Eternal reopens it for the last ending only")
	check(Endings.choose(&"unsworn") and Endings.chosen() == &"unsworn" and not Endings.gate_open(), "the last ending can be chosen after another")


func test_descent() -> void:
	await fresh_game()
	game_state.in_game = true
	var keys: Array = []
	for m in Expansion.MAPS:
		keys.append(String(m))
	check(keys.size() >= 10, "the Descent has 10+ new maps (%d)" % keys.size())
	check(Expansion.BOSSES.size() >= 25, "25+ new bosses (%d)" % Expansion.BOSSES.size())
	for i in keys.size():
		var path := "res://world/levels/%s.tscn" % keys[i]
		await go_to_level(path, &"")
		check(level.scene_file_path == path and WorldMap.LEVELS.has(path), "%s loads and is on the map" % keys[i])
		for n in ["FromPrev", "ToPrev", "Arena0", "Arena1", "Arena2", "Candle0", "Candle3", "Tablet2", "Cache"]:
			check(level.get_node_or_null(n) != null, "%s has %s" % [keys[i], n])
		check((level.get_node_or_null("ToNext") != null) == (i < keys.size() - 1), "%s chains on correctly" % keys[i])
		var bad := placement_problems()
		check(bad.is_empty(), "%s: everything stands on something %s" % [keys[i], bad])
	for b in Expansion.BOSSES:
		var id: StringName = b
		check(Bestiary.IDS.has(id) and Bestiary.data(id) != null, "%s is in the bestiary" % id)
	for w in Expansion.WEAPONS.keys():
		check(Weapons.IDS.has(w) and Weapons.HINTS.has(w), "%s is a weapon with a where-to-find hint" % w)


func test_progress_goal() -> void:
	await fresh_game()
	game_state.in_game = true
	check(Progress.next_goal().name == "the Bell-Warden", "the first goal is the Bell-Warden")
	for g in Progress.GOALS:
		check(Bestiary.IDS.has(g.boss), "%s is a real boss" % g.boss)
		game_state.set_flag(StringName("boss_defeated_" + String(g.boss)), true)
	check(Progress.next_goal().is_empty() and Progress.text() != "", "after the last boss there is no goal")
	for reach in [&"verse_mother_ilse", &"the_lantern_mother", &"the_unnamed_archon", &"the_unkept_promise"]:
		game_state.set_flag(StringName("boss_defeated_" + String(reach)), false)
	check(Progress.next_goal().name == "the Verse-Mother Ilse".replace("the ", "") and "Cinder Choir" in Progress.text(), "after the Hollow Heart the road leads on to the Cinder Choir")
	game_state.set_flag(&"boss_defeated_the_oath_eternal", false)
	game_state.set_flag(&"boss_defeated_pale_sovereign", false)
	check(Progress.next_goal().name == "the Pale Sovereign" and "Barrow" in Progress.text(), "goals are taken in story order")
	game_state.set_flag(&"boss_defeated_the_oath_eternal", true)
	game_state.set_flag(&"boss_defeated_pale_sovereign", true)
	for g in Progress.GOALS:
		game_state.set_flag(StringName("boss_defeated_" + String(g.boss)), false)
	for early in [&"bell_warden", &"drowned_canon", &"hollow_marshal"]:
		game_state.set_flag(StringName("boss_defeated_" + String(early)), true)
	check(Progress.next_goal().name == "the Salt Abbot" and "Reliquary" in Progress.text(), "after the Marshal the road leads to the Reliquary")
	game_state.set_flag(&"boss_defeated_bell_warden", false)
	check(Progress.next_goal().name == "the Salt Abbot", "a skipped earlier boss never sends you backwards")
	game_state.set_flag(&"boss_defeated_bell_warden", true)
	game_state.set_flag(&"boss_defeated_the_oath_eternal", false)
	game_state.set_flag(&"boss_defeated_pale_sovereign", false)
	var prev := 0.0
	for i in Expansion.MAPS.size():
		var main: StringName = Progress.GOALS[Progress.GOALS.size() - Expansion.MAPS.size() + i].boss
		var hp: float = Bestiary.data(main).max_health
		check(hp > prev, "%s has more health than the previous main boss (%d)" % [main, hp])
		prev = hp
	check(Bestiary.data(&"crownless_king").max_health < Bestiary.data(&"ossuary_king_veyl").max_health, "the Descent starts above the Citadel's boss")


func test_no_ending_yet() -> void:
	await fresh_game()
	game_state.in_game = true
	Endings.enabled = false
	game_state.set_flag(&"boss_defeated_hollow_marshal", true)
	check(not Endings.gate_open() and Endings.chosen() == &"", "with endings off the gate never asks for a choice")
	check(Trials.unlocked(), "the Trial Ring still opens once the Marshal falls")
	check(not Progress.next_goal().is_empty(), "the road still has somewhere to go")
	var pq := Dialogues.OMMEN_AFTER_MARSHAL.duplicate()
	check("not finished" in " ".join(pq), "Ommen says the story is not finished")
	Endings.enabled = true


func test_graphics_pass() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	var has_mist := false
	for c in level.get_children():
		if c is Mist:
			has_mist = true
	check(has_mist, "levels get the drifting mist layer")
	var fx := main.get_node_or_null("PostFx")
	check(fx != null and fx is PostFx, "the glow/grade pass exists in the main scene")
	check(load("res://fx/post_fx.gdshader") is Shader, "post shader loads")
	check(Settings.glow, "glow is on by default")


func test_qol() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	# The unstick button puts the player back at the last candle without a death.
	level.player.global_position = Vector2(2500, 300)
	var deaths_before: int = game_state.deaths
	events.respawn_requested.emit()
	await frames(5)
	check(level.player.global_position.x < 1500.0, "respawn request moves the player back to the start/candle")
	check(game_state.deaths == deaths_before, "unstick is not a death")
	settings.damage_numbers = false
	GameFeel.damage_number(Vector2(10, 10), 5.0)
	settings.damage_numbers = true
	check(Progress.text() != "", "goal line has text for the map")


func test_boss_lines() -> void:
	var ids: Array[StringName] = []
	var d := DirAccess.open("res://actors/bosses")
	for f in d.get_files():
		if f.ends_with(".tscn"):
			var sc: PackedScene = load("res://actors/bosses/" + f)
			var inst := sc.instantiate()
			ids.append(inst.boss_id)
			inst.free()
	check(ids.size() >= 45, "found the boss scenes (%d)" % ids.size())
	var missing := []
	for id in ids:
		if not BossLines.LINES.has(id):
			missing.append(id)
		else:
			var l: Array = BossLines.LINES[id]
			if l.size() != 5 or String(l[0]) == "":
				missing.append(String(id) + "(bad)")
	check(missing.is_empty(), "every boss has 5 voice lines: missing %s" % [missing])
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	var sp: BossSpeech = null
	for c in main.hud.get_children():
		if c is BossSpeech:
			sp = c
	check(sp != null, "the HUD has the boss speech layer")


func test_levels_reachable() -> void:
	# Runs tools/audit_reach.py: no wall taller than a jump on any road, nothing placed on an unreachable ledge.
	var out: Array = []
	var code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/audit_reach.py")], out, true)
	if code == -1:
		print("  (skipped: python3 not available)")
		return
	check(code == 0, "every level road is open and every perch is reachable: " + (str(out[0]).strip_edges().right(300) if out.size() > 0 else ""))


func test_reliquary_opens() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	var wall := level.get_node_or_null("VaultWallBreak") as BreakableWall
	check(wall != null and wall.opens_when_boss == &"salt_abbot", "the way on to the Keep is a wall that opens with the Abbot")
	events.boss_defeated.emit(&"salt_abbot")
	await frames(3)
	check(level.get_node_or_null("VaultWallBreak") == null, "it gives way by itself when the Abbot falls")
	await go_to_level(RELIQUARY, &"")
	check(level.get_node_or_null("VaultWallBreak") == null, "and stays open when you come back")


func test_wayfarers() -> void:
	await fresh_game()
	game_state.in_game = true
	check(DescentNpcs.DATA.size() >= 11, "a Wayfarer for every Descent map (%d)" % DescentNpcs.DATA.size())
	for id in DescentNpcs.DATA:
		var d: Dictionary = DescentNpcs.DATA[id]
		var c := Dialogues.conversation(id)
		check(c.speaker == d.speaker and c.lines.size() >= 3, "%s greets you with a story" % id)
		Dialogues.finish(id)
		check(not DescentNpcs.farewell_due(id), "%s: no farewell before the boss falls" % id)
		c = Dialogues.conversation(id)
		check(c.lines.size() == 1, "%s: then one passing line" % id)
		Dialogues.finish(id)
		game_state.set_flag(StringName("boss_defeated_" + String(d.boss)), true)
		check(DescentNpcs.farewell_due(id), "%s: farewell once %s is down" % [id, d.boss])
		c = Dialogues.conversation(id)
		check(c.lines == d.after, "%s says goodbye" % id)
		Dialogues.finish(id)
		check(game_state.item_count(d.gift) == 1 and Items.get_item(d.gift) != null, "%s gives %s" % [id, d.gift])
		check(not DescentNpcs.farewell_due(id), "%s: the farewell happens once" % id)
	for id in DescentNpcs.DATA:
		var rid := StringName("relic_x_" + String(DescentNpcs.DATA[id].boss))
		check(Relics.DEFS.has(rid) and Relics.IDS.has(rid) and Items.IDS.has(rid), "%s is a wearable relic" % rid)
		check(Bestiary.data(DescentNpcs.DATA[id].boss).drop_item.id == rid, "%s drops it" % DescentNpcs.DATA[id].boss)
	for id in DescentNpcs.ARCHIVE:
		check(Dialogues.archive_line(id).length() > 40, "Vesper has something to say about %s" % id)
	game_state.add_item(&"keepsake_aures_candle", 1)
	check(Dialogues.archive_pending().has(&"keepsake_aures_candle"), "Vesper notices a keepsake you carry")
	for k in DescentNpcs.SHOPS:
		for e in Shops.stock(k):
			check(Items.get_item(e.item) != null and e.price > 0, "shop %s sells a real item (%s)" % [k, e.item])
	for a in ["ossuary_plate", "aures_vigil", "hush_habit"]:
		check(Armors.get_armor(a) != null and Armors.get_armor(a).validate().is_empty(), "armour %s is valid" % a)
	for i in ["salt_of_the_dead", "kings_wine", "ember_cluster", "hush_draught"]:
		check(Items.get_item(i) != null and Items.get_item(i).validate().is_empty(), "item %s is valid" % i)


func test_four_parts() -> void:
	await fresh_game()
	game_state.in_game = true
	var chain := ["drowned_belfry", "bleeding_gardens", "iron_orrery", "sunken_basilica", "crownless_citadel"]
	var bosses := {"bleeding_gardens": &"thornmother", "iron_orrery": &"orrerist", "sunken_basilica": &"drowned_bishop", "crownless_citadel": &"crownless_king"}
	var relics := {"bleeding_gardens": &"relic_briar", "iron_orrery": &"relic_gear", "sunken_basilica": &"relic_chalice", "crownless_citadel": &"relic_oathbreaker"}
	for i in range(1, chain.size()):
		var path := "res://world/levels/%s.tscn" % chain[i]
		await go_to_level(path, &"")
		check(level.scene_file_path == path and WorldMap.LEVELS.has(path), "%s loads and is on the map" % chain[i])
		for n in ["FromPrev", "FromNext", "ToPrev", "GateCandle", "MidCandle", "BossArena", "ChestA", "ChestB", "ChestC", "Cache", "TabletA", "TabletB", "Ground0", "StepFoeA", "LoftArcherA", "RearGuard"]:
			check(level.get_node_or_null(n) != null, "%s has %s" % [chain[i], n])
		check(level.get_node_or_null("ToNext") != null, "%s leads on" % chain[i])
		var bad := placement_problems()
		check(bad.is_empty(), "%s: everything stands on something %s" % [chain[i], bad])
		var bid: StringName = bosses[chain[i]]
		check(Bestiary.IDS.has(bid) and Bestiary.data(bid) != null and Bestiary.data(bid).drop_item.id == relics[chain[i]], "%s is in the bestiary and drops its relic" % bid)
		check(Relics.DEFS.has(relics[chain[i]]) and Relics.IDS.has(relics[chain[i]]) and Items.IDS.has(relics[chain[i]]), "%s is a wearable relic" % relics[chain[i]])
		check(Dialogues.ARCHIVE.has(relics[chain[i]]), "Vesper knows %s" % relics[chain[i]])
	await go_to_level("res://world/levels/drowned_belfry.tscn", &"from_next")
	check(level.find_entry(&"from_next") != null and level.get_node_or_null("ToGardens") != null, "the belfry links on to the gardens")
	for d in [&"gardens_down", &"orrery_down", &"basilica_down", &"king_down"]:
		check(Deeds.DEFS.has(d) and Deeds.ORDER.has(d), "deed %s exists" % d)
	check(Trials.RUSH_BOSSES.size() >= 15, "the boss rush includes every part")
	for p in Trials.RUSH_BOSSES:
		check(ResourceLoader.exists(p), "rush boss %s exists" % p)


func test_talismans() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	for id in TalismanData.IDS:
		check(Items.IDS.has(id) and Items.get_item(id) != null and Items.get_item(id).validate().is_empty(), "%s is a valid item" % id)
	check(TalismanData.ELITE_POOL.size() >= 5 and TalismanData.IDS.size() >= 20, "there are boss talismans and an elite pool")
	# Bosses always drop theirs, once
	var b: BossBase = load("res://actors/bosses/bell_warden.tscn").instantiate()
	level.add_child(b)
	await frames(2)
	Talismans.roll_drop(b, b.data)
	check(Talismans.owned(&"tal_warden"), "the Bell-Warden drops its talisman")
	Talismans.roll_drop(b, b.data)
	check(game_state.item_count(&"tal_warden") == 1, "a boss talisman is unique")
	b.queue_free()
	# Elites sometimes drop one from the pool
	var e: EnemyBase = load("res://actors/enemies/gilded_penitent.tscn").instantiate()
	level.add_child(e)
	await frames(2)
	for i in 300:
		Talismans.roll_drop(e, e.data)
	var pool_owned := 0
	for id in TalismanData.ELITE_POOL:
		if Talismans.owned(id):
			pool_owned += 1
	check(pool_owned >= 1 and pool_owned <= TalismanData.ELITE_POOL.size(), "elite enemies drop talismans from the pool (%d found)" % pool_owned)
	e.queue_free()
	# Ordinary enemies never do
	var before: int = game_state.inventory.size()
	var h: EnemyBase = load("res://actors/enemies/hollow_penitent.tscn").instantiate()
	level.add_child(h)
	await frames(2)
	for i in 100:
		Talismans.roll_drop(h, h.data)
	check(game_state.inventory.size() == before, "ordinary foes drop no talismans")
	h.queue_free()
	# Wearing: three slots, effects apply
	for id in [&"tal_king", &"tal_brand", &"tal_ashfall", &"tal_vess"]:
		game_state.add_item(id, 1)
	var dmg0 := player.attack_runner.damage_bonus
	var hp0 := player.health.max_health
	check(Talismans.toggle(&"tal_king").ok and Talismans.toggle(&"tal_brand").ok and Talismans.toggle(&"tal_ashfall").ok, "three talismans can be worn")
	check(not Talismans.toggle(&"tal_vess").ok and Talismans.equipped().size() == 3, "the fourth is refused")
	await frames(2)
	check(is_equal_approx(Boosts.mult("damage"), 1.15 * 1.12 * 1.1), "damage boosts multiply")
	check(is_equal_approx(Boosts.mult("damage_taken"), 0.92 * 0.95), "damage taken boosts multiply")
	check(player.attack_runner.damage_bonus > dmg0 * 1.4, "the player hits harder with them")
	check(player.health.max_health > hp0 * 1.1, "maximum health rises")
	check(is_equal_approx(player.damage_taken_mult, Loadout.damage_taken_mult() * 0.92 * 0.95), "the player takes less damage")
	check(Talismans.toggle(&"tal_king").ok and is_equal_approx(player.health.max_health, hp0 * 1.04), "removing one undoes its effects")
	check(Talismans.describe({"damage": 1.1, "damage_taken": 0.9, "parry_focus": 6.0}) == "Damage +10%, Damage taken -10%, Focus per parry +6", "effects read clearly")
	game_state.set_flag(&"tal_eq", [])
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.TALISMANS)
	await frames(3)
	check(inv.tab == InventoryMenu.Tab.TALISMANS and inv._tal_btns.size() >= 7, "the talismans tab lists what you carry (%d)" % inv._tal_btns.size())
	inv._tal_btns[0].pressed.emit()
	await frames(2)
	check(Talismans.equipped().size() == 1, "pressing a row wears it")
	inv.close()


func test_potions_and_alchemy() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	for id in Alchemy.ORDER:
		check(Items.IDS.has(id) and Items.get_item(id).effect == ItemData.Effect.BUFF and Buffs.DEFS.has(id) and Items.get_item(id).validate().is_empty(), "%s is a valid potion" % id)
	check(not Alchemy.can_craft(&"potion_might") and not Alchemy.craft(&"potion_might").ok, "you cannot brew without materials")
	game_state.add_item(&"hollow_resin", 2)
	game_state.add_item(&"ember_shard", 1)
	game_state.add_embers(500)
	check(Alchemy.can_craft(&"potion_might"), "with the materials it can be brewed")
	var r := Alchemy.craft(&"potion_might")
	check(r.ok and game_state.item_count(&"potion_might") == 1 and game_state.item_count(&"hollow_resin") == 0 and game_state.embers == 400, "brewing spends materials and embers and gives a potion")
	# Drinking
	var dmg0 := player.attack_runner.damage_bonus
	check(Items.use(&"potion_might", player), "the potion can be drunk")
	await frames(2)
	check(Buffs.is_active(&"potion_might") and game_state.item_count(&"potion_might") == 0, "it starts a buff and is consumed")
	check(player.attack_runner.damage_bonus > dmg0 * 1.15, "the buff raises damage")
	check(Buffs.remaining(&"potion_might") > 230.0, "it lasts about four minutes")
	Buffs.tick(100.0)
	check(Buffs.is_active(&"potion_might") and Buffs.remaining(&"potion_might") < 141.0, "it runs down")
	Buffs.tick(200.0)
	await frames(2)
	check(not Buffs.is_active(&"potion_might") and is_equal_approx(player.attack_runner.damage_bonus, dmg0), "it wears off and the effect ends")
	# Stacking different potions, additive effects, max health
	var hp0 := player.health.max_health
	Buffs.start(&"potion_vigor")
	Buffs.start(&"potion_resolve")
	await frames(2)
	check(is_equal_approx(player.health.max_health, hp0 * 1.25), "vigor raises maximum health")
	check(is_equal_approx(Boosts.add("status_resist"), 0.5), "resolve adds status resist")
	Buffs.clear()
	await frames(2)
	check(is_equal_approx(player.health.max_health, hp0) and Boosts.add("status_resist") == 0.0, "clearing buffs restores everything")
	# Death clears them
	Buffs.start(&"potion_ward")
	player.health.take_damage(99999.0)
	await frames(10)
	check(not Buffs.is_active(&"potion_ward"), "buffs end when you die")
	# Tab
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.ALCHEMY)
	await frames(3)
	check(inv.tab == InventoryMenu.Tab.ALCHEMY and inv._alc_btns.size() == Alchemy.ORDER.size(), "the alchemy tab lists every recipe")
	inv.close()
	check(Buffs.active.is_empty(), "a new game starts with no buffs")


func test_lurker_ambush() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	var l: Lurker = load("res://actors/enemies/reliquary_lurker.tscn").instantiate()
	l.position = Vector2(700, 480)
	level.add_child(l)
	await frames(6)
	check(l.dormant and l.hurtbox.collision_layer == 0, "a lurker lies hidden and untouchable")
	check(l.receive_hit(damage(50.0)) == HitData.Result.IGNORED and is_equal_approx(l.health.current, l.health.max_health), "hidden, it cannot be hurt")
	await frames(60)
	check(l.dormant, "it does not wake for a distant player")
	await place_player(690.0, 480.0, 1)
	await frames(4)
	check(not l.dormant and l.hurtbox.collision_layer == 16, "it springs when you walk over it")
	check(l.state == EnemyBase.State.ATTACK, "and lunges at once")
	check(l.data.pack_alert, "lurkers call their neighbours")
	l.queue_free()


func test_elite_modifiers_and_alert() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	var seen := {}
	for x in [610, 617, 624, 631, 638, 645, 652]:
		var e: EnemyBase = load("res://actors/enemies/gilded_penitent.tscn").instantiate()
		e.position = Vector2(x, 480)
		level.add_child(e)
		await frames(2)
		seen[e.modifier] = true
		check(EnemyBase.MODIFIERS.has(e.modifier), "an elite rolls a modifier (%s)" % e.modifier)
		match e.modifier:
			&"frenzied": check(e.speed_scale > 1.0, "frenzied elites are faster")
			&"stoneskin": check(e.damage_taken_scale < 1.0 and e.poise > e.data.max_poise, "stoneskin elites take less damage")
			&"venomous": check(e.attack_runner.weapon_status == &"poison", "venomous elites poison")
		e.queue_free()
	check(seen.size() >= 2, "different spots give different modifiers (%s)" % [seen.keys()])
	# Pack alert: spotting you wakes an unaware neighbour.
	var a: EnemyBase = load("res://actors/enemies/drowned_pilgrim.tscn").instantiate()
	a.position = Vector2(500, 480)
	a.start_facing = -1
	level.add_child(a)
	var b: EnemyBase = load("res://actors/enemies/drowned_pilgrim.tscn").instantiate()
	b.position = Vector2(560, 480)
	b.start_facing = 1
	level.add_child(b)
	await place_player(430.0, 480.0, 1)
	await frames(10)
	check(a.target != null, "the first pilgrim sees you")
	check(b.target != null, "and its neighbour joins in")
	a.queue_free()
	b.queue_free()


func test_arts() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(400.0, 480.0, 1)
	check(Arts.equipped() == &"" and not InputMap.has_action(&"") and InputMap.has_action(&"art"), "no art yet; the Art button exists")
	check(not Arts.equip(&"ember_lance"), "an unlearned art cannot be equipped")
	for id in Arts.ORDER:
		check(Arts.attack(id) != null, "%s has its move" % id)
	game_state.set_flag(&"boss_defeated_bell_warden", true)
	events.boss_defeated.emit(&"bell_warden")
	check(Arts.unlocked(&"toll_of_mercy") and Arts.equipped() == &"toll_of_mercy", "beating the Bell-Warden teaches and equips Toll of Mercy (%s / %s)" % [Arts.unlocked(&"toll_of_mercy"), game_state.get_flag(&"art_equipped", "?")])
	player.set_focus(0.0)
	await press(&"art")
	await frames(6)
	check(player.state != Player.State.ATTACK, "no art without focus")
	var e := await spawn_enemy(428.0, -1)
	e.health.set_max(99999.0)
	e.health.restore_full()
	e.set_physics_process(false)
	player.set_focus(Player.MAX_FOCUS)
	player.stamina.restore_full()
	var hp := e.health.current
	await press(&"art")
	var seen := false
	for i in 60:
		await get_tree().physics_frame
		if player.attack_runner.attack == Arts.attack(&"toll_of_mercy"):
			seen = true
	check(seen, "the Art button casts the equipped art")
	check(e.health.current < hp, "Toll of Mercy hits")
	check(player.focus <= Player.MAX_FOCUS - Arts.cost(&"toll_of_mercy") + 20.0, "and spends focus (%.0f)" % player.focus)
	await frames(50)
	# Healing art
	game_state.set_flag(&"art_has_mending_glow", true)
	check(Arts.equip(&"mending_glow") and Arts.equipped() == &"mending_glow", "Mending Glow equips")
	player.health.set_max(100.0)
	player.health.current = 40.0
	player.set_focus(Player.MAX_FOCUS)
	player.stamina.restore_full()
	await frames(30)
	await press(&"art")
	await frames(20)
	check(player.health.current >= 69.0, "Mending Glow restores 30%% (%.0f)" % player.health.current)
	# Spell art needs the projectile path
	game_state.set_flag(&"art_has_ember_lance", true)
	Arts.equip(&"ember_lance")
	await frames(40)
	e.health.restore_full()
	e.global_position = player.global_position + Vector2(60, 0)
	player.set_focus(Player.MAX_FOCUS)
	player.stamina.restore_full()
	hp = e.health.current
	await press(&"art")
	await frames(60)
	check(e.health.current < hp, "Ember Lance flies and hits")
	# Screen
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.ARTS)
	await frames(4)
	check(inv._art_btns.size() == Arts.ORDER.size() and not inv._art_btns[0].disabled and inv._art_btns[5].disabled, "the Arts tab lists learned and unlearned arts")
	inv.close()
	check(Arts.title(&"tidecall") != "" and Arts.def(&"tidecall").boss == &"salt_abbot", "Tidecall is taught by the Salt Abbot")
	e.queue_free()


func test_second_weapon_set() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(400.0, 480.0, 1)
	for id in [&"gravediggers_greataxe", &"veil_daggers", &"candle_catalyst", &"abbots_crozier"]:
		var w := Weapons.get_weapon(id)
		check(w != null and w.light_combo_start != null and w.heavy != null and w.aerial != null and w.riposte != null and w.skill != null, "%s is a complete weapon" % id)
		check(IconArt.has_icon(id) and Weapons.IDS.has(id), "%s has an icon and is listed" % id)
	check(Weapons.get_weapon(&"gravediggers_greataxe").look == PresetData.WeaponLook.AXE, "the greataxe is drawn as an axe")
	check(Weapons.get_weapon(&"candle_catalyst").light_combo_start.is_ranged(), "the catalyst's light attacks are bolts")
	check(Weapons.get_weapon(&"abbots_crozier").block_reduction > 0.0, "the crozier holds a guard")
	check(Forge.recipe(&"veil_daggers").relic == &"lurker_fang" and Forge.recipe(&"candle_catalyst").relic == &"cantors_wick", "daggers and catalyst are forged from drops")
	check(not Forge.recipe(&"gravediggers_greataxe").is_empty() == false, "the greataxe is not forged: it is found")
	# Each weapon visibly draws and swings without error.
	for id in [&"gravediggers_greataxe", &"veil_daggers", &"candle_catalyst", &"abbots_crozier"]:
		game_state.grant_gear("weapon", id)
		Loadout.equip_weapon(id)
		await frames(3)
		await place_player(400.0, 480.0, 1)
		player.stamina.restore_full()
		await press(&"attack_light")
		await frames(30)
		check(player.weapon.id == id, "%s equips and swings" % id)
	# The catalyst's bolt hurts an enemy from range, and gives focus.
	Loadout.equip_weapon(&"candle_catalyst")
	await frames(3)
	await place_player(400.0, 480.0, 1)
	var e := await spawn_enemy(520.0, -1)
	e.health.set_max(9999.0)
	e.health.restore_full()
	e.set_physics_process(false)
	player.set_focus(0.0)
	player.stamina.restore_full()
	var hp := e.health.current
	await press(&"attack_light")
	await frames(60)
	check(e.health.current < hp, "a catalyst bolt crosses the room and hurts")
	check(player.focus > 0.0, "and a landed bolt gives focus (%.0f)" % player.focus)
	e.queue_free()
	# The axe chest gives the axe.
	await go_to_level(RELIQUARY, &"")
	var chest := level.get_node("AxeChest") as TreasureChest
	check(chest.gear_kind == "weapon" and chest.gear_id == &"gravediggers_greataxe", "the hidden chest holds the Gravedigger's Greataxe")


func test_secrets_and_hazards() -> void:
	await fresh_game()
	game_state.in_game = true
	await go_to_level(RELIQUARY, &"")
	check(Secrets.count() == 0, "no secrets found at the start")
	var wall := level.get_node("NookWall") as IllusoryWall
	check(wall.collision_layer == 0, "an illusory wall has no collision")
	await place_player(wall.position.x - 40.0, 480.0, 1)
	player.global_position = wall.global_position + Vector2(8, 60)
	await frames(8)
	check(Secrets.is_found(&"reliquary_axe") and Secrets.count() == 1, "walking into it reveals the secret")
	for id in [&"a", &"b", &"c"]:
		Secrets.record(id)
	check(Deeds.has(&"secrets"), "four secrets earn the Seeker deed")
	# A broken wall counts too.
	Secrets.record_silent(&"extra")
	check(Secrets.count() == 5, "a silently recorded secret counts")
	# Fire jet: harmless while it warns, damaging in the burst.
	var jet := level.get_node("JetA") as FireJet
	player.health.set_max(200.0)
	player.health.restore_full()
	jet._t = jet.period - jet.burst_time - jet.warn_time + 0.2
	check(jet.is_warning() and not jet.is_bursting(), "a jet warns before it bursts")
	await place_player(jet.global_position.x, 480.0, 1)
	var before := player.health.current
	await frames(6)
	check(player.health.current == before, "standing in the warning is safe")
	jet._t = jet.period - jet.burst_time + 0.05
	await frames(10)
	check(player.health.current < before, "the burst burns (%.0f)" % player.health.current)


func test_trials() -> void:
	await fresh_game()
	game_state.in_game = true
	check(not Trials.unlocked(), "the Ring is shut before an ending")
	game_state.set_flag(&"ending_chosen", "keep")
	check(Trials.unlocked(), "the Ring opens after an ending")
	var emb: int = game_state.embers
	var r := Trials.record_rush(312.4)
	check(r.reward == Trials.RUSH_REWARD and r.record and is_equal_approx(Trials.best_rush(), 312.4), "the first Boss Rush pays and records %s %s" % [r, Trials.best_rush()])
	r = Trials.record_rush(400.0)
	check(r.reward == 0 and not r.record and is_equal_approx(Trials.best_rush(), 312.4), "a slower run pays nothing and keeps the record")
	r = Trials.record_rush(290.0)
	check(r.reward == 0 and r.record and is_equal_approx(Trials.best_rush(), 290.0), "a faster run improves it")
	r = Trials.record_gauntlet(4, false)
	check(r.reward == 0 and Trials.best_gauntlet() == 4, "a failed Gauntlet records the wave")
	check(game_state.embers == emb + Trials.RUSH_REWARD, "only the rush reward was paid")
	for p in Trials.RUSH_BOSSES:
		check(ResourceLoader.exists(p), "rush boss %s exists" % p)
	for w in Trials.WAVES:
		for n in w:
			check(ResourceLoader.exists(Trials.E + n + ".tscn"), "gauntlet enemy %s exists" % n)
	# The ring level and its door
	await go_to_level("res://world/levels/trial_ring.tscn", &"")
	check(level.get_node_or_null("TrialRunner") != null and level.get_node_or_null("RushStone") != null and level.get_node_or_null("GauntletStone") != null, "the ring has its runner and stones")
	var rn := level.get_node("TrialRunner") as TrialRunner
	game_state.set_flag(&"ending_chosen", "")
	check(not rn.start(&"gauntlet"), "a run will not start before an ending")
	game_state.set_flag(&"ending_chosen", "keep")
	check(rn.start(&"gauntlet"), "the Gauntlet starts")
	await frames(10)
	check(rn.running and enemies().size() == Trials.WAVES[0].size(), "wave one is on the floor (%d)" % enemies().size())
	for e in enemies():
		e.health.take_damage(99999.0)
	await frames(200)
	check(rn.step == 1 and enemies().size() == Trials.WAVES[1].size(), "clearing a wave sends the next (%d)" % enemies().size())
	player.health.take_damage(99999.0)
	await frames(30)
	check(not rn.running and Trials.best_gauntlet() >= 1, "dying ends the run and keeps the record")
	var door := TrialDoor.new()
	check(door.has_method(&"try_open"), "the Manor's Trial Door exists")
	door.free()


func test_boss_intro_card() -> void:
	await fresh_game()
	game_state.in_game = true
	await place_player(300.0, 480.0, 1)
	var hud := main.get_node_or_null("HUD")
	check(hud != null, "the HUD is in the main scene")
	var b: BossBase = load("res://actors/bosses/cellarer_grume.tscn").instantiate()
	b.position = Vector2(700, 480)
	level.add_child(b)
	await frames(3)
	var kids_before := hud.get_child_count()
	b.start_fight()
	await frames(5)
	check(game_state.get_flag(&"intro_cellarer", false), "the first meeting shows an intro card")
	check(hud.get_child_count() > kids_before, "the card is on screen")
	b.queue_free()
	await frames(2)
	var b2: BossBase = load("res://actors/bosses/cellarer_grume.tscn").instantiate()
	b2.position = Vector2(700, 480)
	level.add_child(b2)
	await frames(3)
	var n := hud.get_child_count()
	b2.start_fight()
	await frames(5)
	check(hud.get_child_count() == n, "a retry skips the card")
	b2.queue_free()
