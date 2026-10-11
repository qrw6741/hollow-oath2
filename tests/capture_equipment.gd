extends Node
## Renders the equipment / items screen for two presets.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_equipment.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node

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

func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	for preset in [&"sworn_knight", &"unsworn"]:
		GameState.reset()
		GameState.preset_id = preset
		GameState.stats = {"vigor": 2, "endurance": 1, "strength": 3}
		GameState.add_embers(740)
		GameState.add_item(&"ash_bandage", 3)
		GameState.add_item(&"ember_shard", 1)
		GameState.add_item(&"warden_bell_shard", 1)
		main = load("res://main/main.tscn").instantiate()
		main.show_menu_on_start = false
		get_tree().root.add_child(main)
		await frames(40)
		var im: InventoryMenu = main.get_node("InventoryMenu")
		im.open()
		await frames(8)
		for key in ["weapon", "armour", "status"]:
			(im._slots[key] as Button).grab_focus()
			await frames(4)
			await shot("eq_%s_%s" % [preset, key])
		im.show_tab(1)
		await frames(4)
		await shot("eq_%s_items" % preset)
		im.close()
		main.queue_free()
		await frames(4)
	get_tree().quit()
