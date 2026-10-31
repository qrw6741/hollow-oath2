extends Node
## GPU/VRAM probe: visits every level twice, prints texture/video memory, draw calls, objects and frame cost.
## Run under a GL driver (xvfb + opengl3), NOT headless:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 res://tests/perf_levels.tscn -- [classic]
func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
func _ready() -> void:
	_run.call_deferred()
func _mon(m) -> float:
	return Performance.get_monitor(m)
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	Settings.classic_gfx = a.has("classic")
	Settings.fps_cap = 0
	Engine.max_fps = 0
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	for round in 1:
		for path in WorldMap.LEVELS:
			Events.level_change_requested.emit(path, &"", false)
			await frames(40)
			var t0 := Time.get_ticks_usec()
			await frames(15)
			var ms := (Time.get_ticks_usec() - t0) / 15000.0
			print("PERF r%d %-26s tex=%6.1fMB vid=%6.1fMB draws=%4d prims=%6d objs=%5d nodes=%5d frame=%.1fms proc=%.1fms" % [round, str(path).get_file().get_basename(), _mon(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, _mon(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, _mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), _mon(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), _mon(Performance.OBJECT_COUNT), _mon(Performance.OBJECT_NODE_COUNT), ms, _mon(Performance.TIME_PROCESS) * 1000.0])
	get_tree().quit()
