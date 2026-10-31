extends Node
## Saves title-screen frames to prove the menu animates. Run (needs a display, e.g. xvfb):
## godot --path . res://tests/capture_menu.tscn -- /out/dir
func _ready() -> void:
	var dir := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	var m: Node = load("res://ui/menu/main_menu.tscn").instantiate()
	add_child(m)
	for shot in [["a", 8], ["b", 100], ["c", 160]]:
		for i in shot[1]:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("%s/menu_%s.png" % [dir, shot[0]])
	get_tree().quit()
