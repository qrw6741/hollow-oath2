extends Node
## Screenshots of the Twin Lords' arena: the hand rising/opening, the lords, a fight moment.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/capture_twins.tscn -- <out_dir>
var out_dir := "user://screens"
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
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
	Events.level_change_requested.emit("res://world/levels/ninth_hell.tscn", &"", false)
	await frames(70)
	var lv = main.current_level()
	var arena := lv.get_node("TwinLordsArena") as DuoArena
	arena.intro_running = true   # hold the scripted intro back: this script poses the scene itself
	lv.player.global_position = Vector2(4850, 470)
	await frames(260)   # let the area banner fade first
	arena.hand.rise = 0.55
	arena.hand.open = 0.0
	await frames(25)
	await shot("1_hand_rising")
	arena.hand.rise = 1.0
	arena.hand.open = 0.5
	await frames(10)
	await shot("2_palm_opening")
	arena.hand.open = 1.0
	await frames(10)
	for b in [arena.boss, arena.boss2]:
		arena._hide(b, false)
		b.global_position.x = arena.global_position.x + arena.hand_offset.x + (-70.0 if b == arena.boss else 70.0)
		b.facing = 1 if b == arena.boss else -1
	await frames(10)
	for b in [arena.boss, arena.boss2]:
		var vis = b.get_node("Visual")
		print("DBG ", b.name, " pos=", b.global_position, " vis=", b.visible, " in_tree=", b.is_inside_tree(), " visual_vis=", vis.visible, " scale=", vis.scale, " z=", vis.z_index, " rise=", vis.rise, " facing=", b.facing, " state=", b.state, " cam=", get_viewport().get_camera_2d().global_position)
	await shot("3_lords_and_hand")
	get_viewport().get_camera_2d().zoom = Vector2(2.2, 2.2)
	await frames(8)
	await shot("4_lords_closeup")
	get_viewport().get_camera_2d().zoom = Vector2(1, 1)
	arena.hand.fade = 0.0
	arena._begin_fight()
	arena.intro_running = false
	lv.player.global_position = Vector2(4800, 470)
	for i in 6:
		await frames(45)
		await shot("5_fight_%d" % i)
	get_tree().quit()
