extends Node
## Plays every level with a bot: runs right, spams light attack, jumps on stall, retreats off dead ends.
## Prints one BOTALL line per level: furthest x, level width, frames, boss gates seen. Errors show in stderr.
## godot --headless --path . res://tests/bot_all.tscn -- [level_key ...]
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var keys: PackedStringArray = OS.get_cmdline_user_args()
	if keys.is_empty():
		var d := DirAccess.open("res://world/levels")
		for f in d.get_files():
			if f.ends_with(".tscn") and not f.begins_with("test_") and f != "trial_ring.tscn":
				keys.append(f.get_basename())
		keys.sort()
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	for key in keys:
		Events.level_change_requested.emit("res://world/levels/%s.tscn" % key, &"", false)
		await frames(75)
		var lv: Node = main.current_level()
		if lv == null or not ("player" in lv) or lv.player == null:
			print("BOTALL %s NO_LEVEL" % key)
			continue
		var p: Player = lv.player
		var width := 0.0
		var g := lv.get_node_or_null("Geometry/Ground")
		if g:
			width = g.position.x
			for c in g.get_children():
				if c is CollisionShape2D and c.shape is RectangleShape2D:
					width = g.position.x + c.position.x * 2.0 if false else g.position.x + (c.shape as RectangleShape2D).size.x
		var last_x: float = p.global_position.x
		var stall := 0
		var back := 0
		var best := 0.0
		var f := 0
		var fell := 0
		while f < 9000:
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
				back = 45
				stall = 0
			if stall > 20:
				Input.action_press(&"jump")
			else:
				Input.action_release(&"jump")
			if f % 12 < 2:
				Input.action_press(&"attack_light")
			else:
				Input.action_release(&"attack_light")
			await get_tree().physics_frame
			if not is_instance_valid(p) or main.current_level() != lv:
				break
			var x: float = p.global_position.x
			if p.global_position.y > 700.0:
				fell += 1
			best = maxf(best, x)
			stall = stall + 1 if absf(x - last_x) < 0.3 else 0
			last_x = x
			if width > 0.0 and x >= width - 120.0:
				break
		print("BOTALL %s best=%.0f width=%.0f frames=%d fell=%d" % [key, best, width, f, fell])
		for a in [&"move_right", &"move_left", &"jump", &"attack_light"]:
			Input.action_release(a)
	get_tree().quit()
