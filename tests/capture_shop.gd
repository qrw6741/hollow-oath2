extends Node
## Renders the upgrade (candle) menu and the shop's buy/sell tabs.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_shop.tscn -- <out_dir>
var out_dir := "user://screens"
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
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main: Node = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.embers = 480
	GameState.add_item(&"ash_bandage", 2)
	GameState.add_item(&"ember_shard", 1)
	Events.shop_requested.emit(&"pedlar")
	await frames(30)
	await shot("shop_buy")
	main.get_node("ShopMenu").show_tab(true)
	await frames(30)
	await shot("shop_sell")
	main.get_node("ShopMenu").close()
	await frames(5)
	main.get_node("CandleMenu").open()
	await frames(40)
	await shot("candle")
	get_tree().quit()
