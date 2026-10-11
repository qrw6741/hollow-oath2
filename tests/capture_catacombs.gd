extends Node
## Renders a walk through the Drowned Catacombs (blockout review).
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_village.tscn -- <out_dir>
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
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(20)
	Events.level_change_requested.emit("res://world/levels/drowned_catacombs.tscn", &"from_chapel", false)
	await frames(80)
	var spots := [[150, 240], [520, 240], [900, 420], [1300, 660], [1730, 646], [2000, 560], [2250, 660], [2320, 560], [2600, 720], [2900, 720], [3100, 720]]
	for i in spots.size():
		var lv: Level = main.current_level()
		lv.player._iframes = 100000
		lv.player.global_position = Vector2(spots[i][0], spots[i][1])
		lv.player.velocity = Vector2.ZERO
		await frames(45)
		await shot("v%02d_%d" % [i, spots[i][0]])
	get_tree().quit()
