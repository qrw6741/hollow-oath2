extends Node
var out_dir := "user://screens"
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	GameState.preset_id = &"sworn_knight"
	var main: Node = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	Events.level_change_requested.emit("res://world/levels/lower_hell.tscn", &"", false)
	await frames(120)
	var pl: Node = get_tree().get_first_node_in_group(&"player")
	Puzzle.set_on(&"lh_lever_a")
	Puzzle.set_on(&"lh_lever_c")
	var spots := [["g_gate1", 7560], ["k_runegate", 9990], ["l_gate3", 12130]]
	for sp in spots:
		pl.global_position = Vector2(sp[1], 470)
		pl.velocity = Vector2.ZERO
		await frames(70)
		await shot(sp[0])
	get_tree().quit()
