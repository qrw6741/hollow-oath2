extends Node
## Prints draw calls, nodes and frame time per level (needs a display; relative numbers only).
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	for p in ["sunken_reliquary", "hollow_keep", "weeping_ossuary", "ashen_chapel", "hollowmere_cellar"]:
		Events.level_change_requested.emit("res://world/levels/%s.tscn" % p, &"", false)
		await frames(60)
		var lv = main.current_level()
		if lv and lv.player:
			lv.player.global_position = Vector2(1500, 480)
		await frames(60)
		var t0 := Time.get_ticks_usec()
		await frames(60)
		var ms := (Time.get_ticks_usec() - t0) / 60000.0
		print("PERF %s draw_calls=%d prims=%d nodes=%d ms_per_frame=%.1f" % [p, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), ms])
	get_tree().quit()
