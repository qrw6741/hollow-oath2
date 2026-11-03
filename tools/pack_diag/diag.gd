extends Node
func _ready() -> void:
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child.call_deferred(main)
	await get_tree().physics_frame
	for i in 10:
		await get_tree().physics_frame
	var gs = get_node("/root/GameState")
	gs.in_game = true
	Events.level_change_requested.emit("res://world/levels/lower_hell.tscn", &"", false)
	for i in 90:
		await get_tree().physics_frame
	var lvl = main.current_level()
	print("DIAG level=", lvl.name)
	for g in get_tree().get_nodes_in_group(&"puzzle_gates"):
		print("DIAG gate ", g.name, " requires=", g.requires, " size=", g.requires.size(), " gate_id=", g.gate_id)
	for n in ["LeverA", "LeverD", "RunLeverMain"]:
		var l = lvl.get_node_or_null(n)
		print("DIAG ", n, " ", l, " id=", (l.lever_id if l else "-"))
	get_tree().quit()
