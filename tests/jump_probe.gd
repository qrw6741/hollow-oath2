extends Node
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
	Events.level_change_requested.emit("res://world/levels/weeping_ossuary.tscn", &"", false)
	await frames(75)
	var p: Player = main.current_level().player
	var y0: float = p.global_position.y
	var top: float = y0
	var x0: float = p.global_position.x
	var xmax: float = x0
	Input.action_press(&"jump")
	Input.action_press(&"move_right")
	for i in 90:
		await get_tree().physics_frame
		top = minf(top, p.global_position.y)
		xmax = maxf(xmax, p.global_position.x)
		if i == 20:
			Input.action_release(&"jump")
	print("JUMP rise=%.1f px (held), air distance=%.1f" % [y0 - top, xmax - x0])
	Input.action_release(&"move_right")
	get_tree().quit()
