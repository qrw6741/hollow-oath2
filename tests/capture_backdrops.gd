extends Node
## Renders each Descent map's backdrop mid-level. Needs a display.
var out_dir := "user://screens"
var main: Node
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()
func _run() -> void:
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	for k in Expansion.MAPS:
		Events.level_change_requested.emit("res://world/levels/%s.tscn" % k, &"", false)
		await frames(50)
		var lv = main.current_level()
		if lv and lv.player:
			lv.player.global_position = Vector2(1500, 480)
		await frames(40)
		await shot(String(k))
	get_tree().quit()
