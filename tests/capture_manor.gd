extends Node
## Renders Hollowmere Manor and the sigil flow.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_manor.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node
var lv: Level
var pl: Player

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

func at(x: float, y := 480.0, face := 1) -> void:
	pl.global_position = Vector2(x, y)
	pl.velocity = Vector2.ZERO
	pl.facing = face

func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.in_game = true
	GameState.add_item(&"hollow_sigil", 1)
	GameState.embers = 840
	lv = main.current_level()
	pl = lv.player
	# The sigil in the pack
	var im: InventoryMenu = main.get_node("InventoryMenu")
	im.open(InventoryMenu.Tab.ITEMS)
	await frames(10)
	await shot("m0_sigil_item")
	im._on_use()
	await frames(300)
	lv = main.current_level()
	pl = lv.player
	await shot("m1_arrival")
	for x in [520.0, 830.0, 1060.0, 1900.0]:
		at(x)
		await frames(40)
		await shot("m2_hall_%d" % int(x))
	at(1500.0, 300.0)
	await frames(40)
	await shot("m3_balcony")
	at(1960.0)
	await frames(20)
	Events.dialogue_requested.emit("Aldous Vane", Dialogues.conversation(&"aldous").lines)
	await frames(60)
	await shot("m4_aldous_dialogue")
	print("manor captures done")
	get_tree().quit()
