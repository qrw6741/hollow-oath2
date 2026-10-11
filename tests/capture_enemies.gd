extends Node
## Renders the new enemies: Gloam Moth (hover, glint, dazed), Oathguard (guarding,
## cracked shield, guard break), Mimic beside a real chest (dormant, breathing, awake).
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_enemies.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node
var lv: Level
var pl: Player

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

func spawn(path: String, pos: Vector2, facing := -1) -> EnemyBase:
	var e: EnemyBase = load(path).instantiate()
	e.position = pos
	e.start_facing = facing
	e.patrol_distance = 0.0
	lv.add_child(e)
	await frames(2)
	return e

func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	lv = main.current_level()
	pl = lv.player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.queue_free()
	for s in get_tree().get_nodes_in_group(&"enemy_spawners"):
		s.remove_from_group(&"enemy_spawners")
	pl.global_position = Vector2(760, 480)
	await frames(20)
	# Moth
	var m: FlyingEnemy = await spawn("res://actors/enemies/gloam_moth.tscn", Vector2(840, 420))
	await frames(30)
	await shot("e1_moth_hover")
	m.target = pl
	m._set_state(EnemyBase.State.CHASE)
	for i in 300:
		await frames(1)
		var r := m.attack_runner
		if m.state == EnemyBase.State.ATTACK and r.phase == AttackRunner.Phase.STARTUP and r.frame == r.attack.startup_frames - 4:
			break
	await shot("e2_moth_glint")
	await frames(30)
	await shot("e3_moth_dazed")
	m.queue_free()
	pl.health.restore_full()
	# Oathguard
	var g: ShieldEnemy = await spawn("res://actors/enemies/oathguard.tscn", Vector2(810, 480))
	g._cooldown = 100000
	g._set_state(EnemyBase.State.IDLE)
	pl.global_position = Vector2(760, 480)
	pl.facing = 1
	await frames(20)
	await shot("e4_guard")
	g.guard = g.max_guard * 0.25
	g.shield_flash = 6
	await frames(1)
	await shot("e5_guard_cracked")
	g.guard_break()
	await frames(10)
	await shot("e6_guard_broken")
	await frames(120)
	g._cooldown = 0
	g._set_state(EnemyBase.State.IDLE)
	g._start_attack(load("res://data/attacks/oathguard_thrust.tres"))
	await frames(18)
	await shot("e7_guard_thrust_glint")
	g.queue_free()
	pl.health.restore_full()
	# Chest and mimic side by side
	var chest := TreasureChest.new()
	chest.chest_id = &"cap_chest"
	chest.position = Vector2(800, 480)
	lv.add_child(chest)
	var mm: Mimic = await spawn("res://actors/enemies/mimic.tscn", Vector2(860, 480))
	pl.global_position = Vector2(740, 480)
	mm.breath_t = 3.0
	await frames(30)
	await shot("e8_chest_and_mimic")
	mm.breath_t = 0.3
	await frames(1)
	await shot("e9_mimic_breath")
	mm.wake(pl, false)
	mm._cooldown = 100000
	await frames(30)
	await shot("e10_mimic_awake")
	mm._start_attack(load("res://data/attacks/mimic_pounce.tres"))
	await frames(24)
	await shot("e11_mimic_pounce")
	get_tree().quit()
