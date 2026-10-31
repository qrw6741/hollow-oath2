extends Node
## Walk-through bot: holds Right and jumps whenever it stalls; prints where it gets stuck.
## godot --headless --path . res://tests/bot_walk.tscn -- <level_key> <target_x>
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	print("BOT start")
	var a := OS.get_cmdline_user_args()
	var key: String = a[0] if a.size() > 0 else "sunken_reliquary"
	var target := float(a[1]) if a.size() > 1 else 3400.0
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
	var lv: Node = main.current_level()
	var p: Player = lv.player
	p.health.max_health = 999999.0
	p.health.current = 999999.0
	var last_x: float = p.global_position.x
	var stall := 0
	var back := 0
	var best := 0.0
	for f in 7000:
		if back > 0:
			back -= 1
			Input.action_release(&"move_right")
			Input.action_press(&"move_left")
		else:
			Input.action_release(&"move_left")
			Input.action_press(&"move_right")
		if stall > 90 and p.global_position.y < 470.0 and back == 0:
			back = 45
			stall = 0
		if stall > 20:
			Input.action_press(&"jump")
		else:
			Input.action_release(&"jump")
		await get_tree().physics_frame
		var x: float = p.global_position.x
		best = maxf(best, x)
		if absf(x - last_x) < 0.3:
			stall += 1
		else:
			stall = 0
		last_x = x
		if f % 300 == 0:
			print("BOTPROG f=%d x=%.0f" % [f, x])
			p.health.current = 999999.0
		if x >= target:
			break
	print("BOT %s reached x=%.0f y=%.0f best=%.0f target=%.0f" % [key, p.global_position.x, p.global_position.y, best, target])
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	get_tree().quit()
