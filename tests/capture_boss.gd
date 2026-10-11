extends Node
## Renders the Bell-Warden fight: gate, intro, telegraphs, phase 2, leap, death.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_boss.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node

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

func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	var lv: Level = main.current_level()
	var pl: Player = lv.player
	var ar: BossArena = lv.get_node("BellWardenArena")
	pl.global_position = Vector2(1820, 448)
	await frames(60)
	await shot("b1_gate")
	pl.global_position = Vector2(2010, 448)
	await frames(50)
	await shot("b2_intro")
	var boss: BossBase = ar.boss
	boss._cooldown = 99999
	boss.global_position = Vector2(2150, 448)
	pl.global_position = Vector2(2110, 448)
	await frames(10)
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/warden_smash.tres"))
	await frames(26)
	await shot("b3_smash_glint")
	await frames(40)
	boss._start_attack(load("res://data/attacks/warden_charge.tres"))
	pl.global_position = Vector2(1990, 448)
	await frames(24)
	await shot("b4_charge_danger")
	await frames(60)
	pl.health.restore_full()
	var h := HitData.make(boss.health.max_health * 0.52, null, Vector2.ZERO)
	h.poise_damage = 0.0
	h.parryable = false
	boss.receive_hit(h)
	await frames(34)
	await shot("b5_phase2_roar")
	await frames(60)
	boss._cooldown = 99999
	pl.health.restore_full()
	pl.global_position = Vector2(boss.global_position.x - 150, 448)
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/warden_leap.tres"))
	await frames(30)
	await shot("b6_leap_marker")
	await frames(80)
	var k := HitData.make(99999.0, null, Vector2.ZERO)
	k.parryable = false
	boss.receive_hit(k)
	await frames(90)
	await shot("b7_victory")
	get_tree().quit()
