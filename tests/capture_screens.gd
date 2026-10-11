extends Node
## Renders scripted gameplay moments to PNG for visual review.
## Needs a real renderer (not --headless). On Linux CI:
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_screens.tscn -- <out_dir>

var out_dir := "user://screens"
var main: Node
var player: Player


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_tree().root.get_node("Settings").screen_shake = 0.0
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func press(a: StringName, hold := 2) -> void:
	await get_tree().physics_frame
	Input.action_press(a)
	await frames(hold)
	Input.action_release(a)


func _run() -> void:
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(20)
	player = main.current_level().player
	await shot("01_spawn")

	# Rest at candle.
	player.global_position = Vector2(170, 480)
	await frames(6)
	await press(&"interact")
	await frames(20)
	await shot("02_rest")
	await frames(60)

	# Combo on the dummy, mid-swing.
	player.global_position = Vector2(300, 480)
	player.facing = 1
	await frames(10)
	await press(&"attack_light")
	await frames(6)
	await shot("03_light_attack")
	await frames(40)

	# Enemy telegraph.
	var level: Level = main.current_level()
	var e: EnemyBase = level.get_node("Penitent1").enemy
	player.global_position = Vector2(e.global_position.x - 30, 480)
	player.facing = 1
	e.facing = -1
	await frames(4)
	e._start_attack(load("res://data/attacks/penitent_overhead.tres"))
	await frames(20)
	await shot("04_enemy_telegraph")
	await press(&"parry")
	await frames(14)
	await shot("05_parried_riposte_cue")
	await press(&"attack_light")
	await frames(10)
	await shot("06_riposte")
	await frames(60)

	# Platforms / vertical.
	player.global_position = Vector2(960, 352)
	await frames(40)
	await shot("07_platforms")

	# Death screen.
	player.global_position = Vector2(1500, 480)
	await frames(10)
	var h := HitData.make(999, null)
	h.parryable = false
	player.receive_hit(h)
	await frames(110)
	await shot("08_death")
	await frames(200)
	await shot("09_respawned")
	get_tree().quit()
