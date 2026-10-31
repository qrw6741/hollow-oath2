extends Node
## Renders the long fast-travel list (scrolled) and the forge with owned / not-owned sections.
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
func _run() -> void:
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.in_game = true
	GameState.set_flag(&"candle_lit_village_gate_candle", true)
	for d in WorldMap.all():
		for cd in d.candles:
			GameState.set_flag(StringName("candle_lit_" + String(cd.id)), true)
	var cm: CandleMenu = main.get_node("CandleMenu")
	cm.open()
	await frames(30)
	await shot("candle_main")
	cm._travel_btn.pressed.emit()
	await frames(10)
	await shot("travel_top")
	var sc: ScrollContainer = cm.find_child("TravelScroll", true, false)
	var inner: Control = sc.get_child(0)
	print("TRAVEL dests=", CandleMenu.travel_destinations().size(), " list_h=", inner.size.y, " sc_h=", sc.size.y, " panel_h=", cm._travel_v.size.y, " vp=", get_viewport().get_visible_rect().size, " travel_pos=", cm._travel_v.global_position)
	sc.scroll_vertical = 100000
	await frames(10)
	print("TRAVEL scrolled to ", sc.scroll_vertical, " max=", sc.get_v_scroll_bar().max_value)
	await shot("travel_bottom")
	get_tree().quit()
