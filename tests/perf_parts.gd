extends Node
## Which parts of a level cost the most draw calls? Usage (xvfb, opengl3): ... perf_parts.tscn -- <level_key>
func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
func _ready() -> void:
	_run.call_deferred()
func draws() -> int:
	await frames(6)
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var key: String = a[0] if a.size() > 0 else "drowned_catacombs"
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	Events.level_change_requested.emit("res://world/levels/%s.tscn" % key, &"", false)
	await frames(40)
	var lv = main.current_level()
	print("PARTS %s total=%d" % [key, await draws()])
	var kinds := {}
	var stack: Array = [lv]
	while stack:
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is CanvasItem and n != lv:
			var k: String = n.get_class() + ":" + (n.get_script().resource_path.get_file() if n.get_script() else "")
			kinds[k] = kinds.get(k, 0) + 1
	var base := await draws()
	for k in kinds:
		if kinds[k] < 1: continue
		var hid: Array = []
		stack = [lv]
		while stack:
			var n2: Node = stack.pop_back()
			for c in n2.get_children():
				stack.append(c)
			if n2 is CanvasItem and n2 != lv and n2.visible and (n2.get_class() + ":" + (n2.get_script().resource_path.get_file() if n2.get_script() else "")) == k:
				n2.visible = false
				hid.append(n2)
		var d := await draws()
		if base - d >= 20:
			print("PARTS   hide %-45s x%-4d saves %d draws" % [k, hid.size(), base - d])
		for h in hid: h.visible = true
	# lights: turn the 2D light pass off globally
	var lights := get_tree().get_nodes_in_group(&"lights")
	print("PARTS done")
	get_tree().quit()
