extends Node
## Renders each Descent map's backdrop mid-level. Needs a display.
var out_dir := "user://screens"
var main: Node
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
var specs: PackedStringArray = []
func _run() -> void:
	specs = OS.get_cmdline_user_args().slice(1)
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	for spec in specs:
		var k: String = spec.split(":")[0]
		var px := float(spec.split(":")[1])
		Events.level_change_requested.emit("res://world/levels/%s.tscn" % k, &"", false)
		await frames(50)
		var lv = main.current_level()
		if lv and lv.player:
			lv.player.global_position = Vector2(px, 440)
		await frames(40)
		if lv and lv.player and OS.get_environment("FXSHOT") != "":
			var at: Vector2 = lv.player.global_position
			GameFeel.ring(at + Vector2(60, -16), Palette.GOLD_BRIGHT, 30.0)
			GameFeel.spark(at + Vector2(60, -16), Palette.GOLD_BRIGHT, 18)
			GameFeel.rise(at + Vector2(-50, -6), Palette.EMBER, 16, 12.0)
			GameFeel.dust(at, 8)
			await frames(9)
		if OS.get_environment("TEXTSHOT") != "":
			Events.banner_requested.emit("The Drowned Cathedral of the Last Unbroken Vow and Sorrow")
			Events.tip_requested.emit(&"focus")
			Events.message_requested.emit("Old Tablet", "Here lies a very long inscription that goes on and on about the oaths broken beneath the bell, the keepers who wept in the dark, and the long road that every pilgrim of Vaelmoor must walk before the last candle is lit and the final door opens at last into the hollow.")
			await frames(40)
		if OS.get_environment("ZOOM") != "":
			get_viewport().get_camera_2d().zoom = Vector2(3, 3)
			await frames(10)
		await shot("%s_%d" % [k, int(px)])
	get_tree().quit()
