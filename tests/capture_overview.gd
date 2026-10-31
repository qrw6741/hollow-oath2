extends Node
## Renders every level whole (camera zoomed out to fit its width, HUD hidden). Needs a display.
##   xvfb-run godot --path . res://tests/capture_overview.tscn -- <out_dir> [level_key ...]
var out_dir := "user://screens"
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()
func _run() -> void:
	var keys: PackedStringArray = OS.get_cmdline_user_args().slice(1)
	if keys.is_empty():
		var d := DirAccess.open("res://world/levels")
		for f in d.get_files():
			if f.ends_with(".tscn") and not f.begins_with("test_") and f != "trial_ring.tscn":
				keys.append(f.get_basename())
		keys.sort()
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(2400, 1000)
	await frames(5)
	var vp := get_viewport().get_visible_rect().size
	for key in keys:
		Events.level_change_requested.emit("res://world/levels/%s.tscn" % key, &"", false)
		await frames(60)
		var lv = main.current_level()
		if lv == null or lv.player == null:
			print("OVERVIEW skip ", key)
			continue
		for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
			n.visible = false
		lv.player.visible = false
		var cam := Camera2D.new()
		lv.add_child(cam)
		cam.make_current()
		var b: Rect2 = lv.bounds
		cam.limit_left = -100000
		cam.limit_right = 100000
		cam.limit_top = -100000
		cam.limit_bottom = 100000
		cam.position_smoothing_enabled = false
		cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
		var z: float = minf(vp.x / b.size.x, vp.y / b.size.y)
		cam.zoom = Vector2(z, z)
		cam.global_position = b.get_center()
		await frames(8)
		cam.global_position = b.get_center()
		await frames(2)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var h := int(b.size.y * z)
		var w := int(b.size.x * z)
		var crop := img.get_region(Rect2i(int((vp.x - w) / 2), int((vp.y - h) / 2), w, h))
		crop.save_png(out_dir.path_join(key + ".png"))
		cam.queue_free()
		print("OVERVIEW ", key, " ", b.size, " ", crop.get_size())
	get_tree().quit()
