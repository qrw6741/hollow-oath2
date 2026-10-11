extends Node
## Renders the menu screens to PNG for visual review (needs a real renderer).
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_menus.tscn -- <out_dir>
## Uses a throw-away save folder; never touches real saves.

var out_dir := "user://screens"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func make_save(slot: int, deaths: int, play: float, place: String) -> void:
	GameState.reset()
	GameState.deaths = deaths
	GameState.play_time = play
	GameState.level_name = place
	SaveSystem.save_slot(slot)
	GameState.reset()


func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(30)
	await shot("m1_title_no_saves")

	make_save(1, 4, 3725.0, "The Penitent's Yard")
	make_save(3, 0, 95.0, "The Penitent's Yard")
	var f := FileAccess.open(SaveSystem.slot_path(2), FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	main.menu.open()
	await frames(10)
	await shot("m2_title_with_saves")

	main.menu._open_slots(0)
	await frames(10)
	await shot("m3_new_game_slots")
	main.menu._rows[0].act.pressed.emit()
	await frames(5)
	await shot("m4_overwrite_confirm")

	main.menu._open_slots(1)
	await frames(10)
	await shot("m5_load_slots")

	main.menu._show_screen(2)
	await frames(10)
	await shot("m6_settings")

	main.menu._show_screen(0)
	await frames(5)
	main.menu._btn_continue.pressed.emit()
	await frames(100)
	var pm := main.get_node("PauseMenu")
	pm._pause()
	await frames(5)
	await shot("m7_pause")
	pm._resume()
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	get_tree().quit()
