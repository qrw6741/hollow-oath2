extends Node
## Soak test: the bot fights through a level for a long time; prints node count, orphan nodes, memory and
## frame time every 600 frames so leaks (nodes/memory that only ever grow) show up.
##   godot --headless --path . res://tests/soak.tscn -- <level_key> <frames>
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var key: String = a[0] if a.size() > 0 else "cinder_choir"
	var total := int(a[1]) if a.size() > 1 else 12000
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	Events.level_change_requested.emit("res://world/levels/%s.tscn" % key, &"", false)
	await frames(75)
	var lv = main.current_level()
	var p: Player = lv.player
	var f := 0
	var back := 0
	var stall := 0
	var last_x := p.global_position.x
	var t0 := Time.get_ticks_msec()
	while f < total:
		f += 1
		p.health.current = p.health.max_health
		if back > 0:
			back -= 1
			Input.action_release(&"move_right")
			Input.action_press(&"move_left")
		else:
			Input.action_release(&"move_left")
			Input.action_press(&"move_right")
		if stall > 90 and back == 0:
			back = 60
			stall = 0
		Input.action_press(&"jump") if stall > 20 else Input.action_release(&"jump")
		if f % 12 < 2:
			Input.action_press(&"attack_light")
		else:
			Input.action_release(&"attack_light")
		await get_tree().physics_frame
		if absf(p.global_position.x - last_x) < 0.5:
			stall += 1
		else:
			stall = 0
		last_x = p.global_position.x
		if f % 1200 == 0:
			print("SOAK f=%d nodes=%d orphans=%d objects=%d mem_MB=%.1f ms_total=%d players2d=%d" % [f, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Time.get_ticks_msec() - t0, get_tree().get_nodes_in_group(&"enemies").size()])
	get_tree().quit()
