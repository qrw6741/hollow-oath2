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
	await frames(60)
	GameState.grant_gear("weapon", &"nightreaper")
	Loadout.equip_weapon(&"nightreaper")
	var p: Player = get_tree().get_first_node_in_group(&"player")
	p.set_focus(100.0)
	await frames(10)
	Input.action_press(&"art")
	await frames(3)
	Input.action_release(&"art")
	await frames(40)
	await shot("jutsu_a")
	get_tree().quit()
