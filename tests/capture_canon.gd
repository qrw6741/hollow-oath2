extends Node
## Renders the Drowned Canon's attacks and telegraphs.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_canon.tscn -- <out_dir>
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
	await frames(20)
	Events.level_change_requested.emit("res://world/levels/drowned_catacombs.tscn", &"from_chapel", false)
	await frames(80)
	var lv: Level = main.current_level()
	var pl: Player = lv.player
	pl._iframes = 100000
	pl.global_position = Vector2(2600, 720)
	await frames(60)
	var boss: BossBase = lv.get_node("CanonArena").boss
	boss._cooldown = 99999
	await shot("c1_intro")
	boss.global_position.x = 2700
	boss.facing = -1
	boss._start_attack(load("res://data/attacks/canon_lash.tres"))
	await frames(18)
	await shot("c2_lash_glint")
	await frames(10)
	await shot("c3_lash_strike")
	await frames(50)
	boss.global_position.x = 2900
	boss._start_attack(load("res://data/attacks/canon_spit.tres"))
	await frames(40)
	await shot("c4_spit")
	await frames(60)
	boss._start_attack(load("res://data/attacks/canon_submerge.tres"))
	await frames(50)
	await shot("c5_bubbles")
	await frames(28)
	await shot("c6_geyser")
	await frames(60)
	boss._start_attack(load("res://data/attacks/canon_wave.tres"))
	await frames(48)
	await shot("c7_wave")
	get_tree().quit()
