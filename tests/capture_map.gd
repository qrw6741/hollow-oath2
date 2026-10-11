extends Node
## Renders the map screen with partly explored levels.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_map.tscn -- <out_dir>
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

func _walk(level_id: String, from: Vector2, to: Vector2) -> void:
	var steps := int(from.distance_to(to) / 32.0) + 1
	for i in steps + 1:
		GameState.explore(level_id, WorldMap.cells_around(from.lerp(to, float(i) / steps), WorldMap.REVEAL_RADIUS))

func _run() -> void:
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	# Simulated exploration: the whole yard, most of the village, the first half of the catacombs.
	_walk("test_arena", Vector2(60, 470), Vector2(2560, 440))
	_walk("test_arena", Vector2(900, 300), Vector2(1200, 300))
	_walk("forsaken_village", Vector2(60, 470), Vector2(640, 470))
	_walk("forsaken_village", Vector2(640, 320), Vector2(1480, 320))
	_walk("forsaken_village", Vector2(1480, 470), Vector2(3400, 400))
	_walk("drowned_catacombs", Vector2(60, 230), Vector2(1240, 600))
	_walk("drowned_catacombs", Vector2(1240, 650), Vector2(2300, 600))
	GameState.set_flag(&"candle_lit_yard_candle", true)
	GameState.set_flag(&"candle_lit_village_gate_candle", true)
	GameState.set_flag(&"boss_defeated_bell_warden", true)
	Events.level_change_requested.emit("res://world/levels/forsaken_village.tscn", &"from_yard", false)
	await frames(80)
	var lv: Level = main.current_level()
	lv.player.global_position = Vector2(1900, 480)
	await frames(10)
	var m: MapMenu = main.get_node("MapMenu")
	m.open()
	await frames(5)
	await shot("map_1_default")
	m.zoom = 0.06
	m.center = Vector2(4000, 300)
	await frames(5)
	await shot("map_2_overview")
	m.zoom = 0.3
	m.center = m.player_map_position()
	await frames(5)
	await shot("map_3_close")
	get_tree().quit()
