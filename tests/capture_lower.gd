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
	GameState.set_flag(&"boss_defeated_ashkar_reaper", true)
	GameState.set_flag(&"boss_defeated_veshti_gunner", true)
	Events.level_change_requested.emit("res://world/levels/ninth_hell.tscn", &"", false)
	await frames(120)
	var hp: Node = get_tree().get_first_node_in_group(&"hand_portal")
	var pl: Node = get_tree().get_first_node_in_group(&"player")
	pl.global_position = hp.global_position + Vector2(-30, 0)
	await frames(20)
	hp.enter(pl)
	await frames(10)
	hp._skip = true
	await frames(500)
	var p: Node = get_tree().get_first_node_in_group(&"player")
	print("PLAYER ", p, " pos ", p.global_position if p else null, " vis ", p.visible if p else null, " mod ", p.modulate if p else null)
	var cam := get_viewport().get_camera_2d()
	print("CAM ", cam, " pos ", cam.global_position, " cine ", cam._cine, " tgt ", cam._target, " limits ", cam.limit_left, cam.limit_right, " zoom ", cam.zoom, " lvl ", cam.get_parent().name)
	await shot("lower_a")
	get_tree().quit()
