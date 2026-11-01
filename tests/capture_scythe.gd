extends Node
## Renders the Nightreaper in hand: idle, each swing, the skill. Output: <out>/scythe_*.png
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
	var player: Node = get_tree().get_first_node_in_group(&"player")
	GameState.grant_gear("weapon", &"nightreaper")
	Loadout.equip_weapon(&"nightreaper")
	await frames(10)
	await shot("scythe_idle")
	for act in [[&"attack_light", "light1"], [&"attack_heavy", "heavy"]]:
		Input.action_press(act[0])
		for i in 3:
			await frames(5)
			await shot("scythe_%s_%d" % [act[1], i])
		Input.action_release(act[0])
		await frames(70)
	get_tree().quit()
