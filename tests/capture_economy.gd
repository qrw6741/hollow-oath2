extends Node
## Renders HUD embers, a pickup, the ember remnant, the candle menu and the pack.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_economy.tscn -- <out_dir>
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
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	var lv: Level = main.current_level()
	GameState.add_embers(1280)
	GameState.add_item(&"ash_bandage", 3)
	GameState.add_item(&"stamina_tonic", 1)
	GameState.add_item(&"rusted_key", 1)
	GameState.add_item(&"penitents_tear", 2)
	lv.player.global_position = Vector2(505, 480)
	await frames(40)
	await shot("e_pickup")
	GameState.ember_drop = {"level_id": "test_arena", "x": 560.0, "y": 480.0, "amount": 640}
	lv._spawn_remnant()
	await frames(20)
	await shot("e_remnant")
	var cm: CandleMenu = main.get_node("CandleMenu")
	cm.open()
	await frames(10)
	await shot("e_candle")
	cm._inv_btn.pressed.emit()
	await frames(10)
	await shot("e_pack")
	var im: InventoryMenu = main.get_node("InventoryMenu")
	im._select(&"rusted_key")
	await frames(5)
	await shot("e_pack_key")
	get_tree().quit()
