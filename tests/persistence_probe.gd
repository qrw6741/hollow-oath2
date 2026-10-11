extends Node
## Cross-process save check: run once with `write`, then again with `read`.
##   godot --path . --fixed-fps 60 res://tests/persistence_probe.tscn -- write
##   godot --path . --fixed-fps 60 res://tests/persistence_probe.tscn -- read
## Exit code 0 = OK. Uses its own save folder (user://probe_saves).

var main: Node


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	_run.call_deferred()


func fail(msg: String) -> void:
	print("PROBE FAIL: ", msg)
	get_tree().quit(1)


func _run() -> void:
	SaveSystem.save_dir = "user://probe_saves"
	var mode := "" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(10)
	if mode == "write":
		for s in range(1, 4):
			SaveSystem.delete_slot(s)
		Events.new_game_requested.emit(3)
		await frames(100)
		var lvl: Level = main.current_level()
		if lvl == null:
			return fail("level did not load")
		lvl.get_node("OathCandle").rest(lvl.player)
		GameState.deaths = 6
		GameState.set_flag(&"probe", true)
		await frames(4)
		SaveSystem.autosave()
		print("PROBE WRITE OK slot=3 checkpoint=", GameState.checkpoint_id)
		get_tree().quit(0)
	elif mode == "read":
		var best := SaveSystem.most_recent_slot()
		if best != 3:
			return fail("most recent slot is %d, expected 3" % best)
		Events.load_game_requested.emit(best)
		await frames(100)
		var lvl: Level = main.current_level()
		if lvl == null:
			return fail("continue did not load a level")
		var d := lvl.player.global_position.distance_to(Vector2(182, 480))
		if d > 12.0:
			return fail("player not at candle: %s" % lvl.player.global_position)
		if GameState.deaths != 6 or GameState.get_flag(&"probe") != true or GameState.checkpoint_id != &"yard_candle":
			return fail("state not restored")
		print("PROBE READ OK deaths=", GameState.deaths, " pos=", lvl.player.global_position)
		for s in range(1, 4):
			SaveSystem.delete_slot(s)
		get_tree().quit(0)
	else:
		fail("pass 'write' or 'read'")
