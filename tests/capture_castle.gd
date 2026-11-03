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
	GameState.grant_gear("weapon", &"long_katana")
	Loadout.equip_weapon(&"long_katana")
	await frames(10)
	pl.global_position = Vector2(700, 470)
	pl.velocity = Vector2.ZERO
	await frames(60)
	await shot("m_katana_idle")
	Input.action_press(&"attack_light")
	await frames(2)
	Input.action_release(&"attack_light")
	await frames(6)
	await shot("n_katana_swing")
	await frames(4)
	await shot("n2_katana_flame")
	await frames(40)
	Input.action_press(&"attack_heavy")
	await frames(2)
	Input.action_release(&"attack_heavy")
	await frames(20)
	await shot("o_katana_heavy")
	var chest: Node = main.get_tree().current_scene.find_child("ChestKatana", true, false)
	if chest == null:
		chest = get_tree().root.find_child("ChestKatana", true, false)
	pl.global_position = chest.global_position + Vector2(-40, -4)
	pl.velocity = Vector2.ZERO
	await frames(80)
	await shot("p_nest")
	get_tree().quit()
