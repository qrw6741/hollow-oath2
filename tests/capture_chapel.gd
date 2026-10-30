extends Node
## Renders the Ashen Chapel: nave, Mother Cinder's arena and the oath gate.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_chapel.tscn -- <out_dir>
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
func go(path: String, entry: StringName) -> Level:
	GameState.level_entry = entry
	var scene: PackedScene = load(path)
	var lv: Level = main.load_level(scene)
	GameState.level_path = path
	await frames(40)
	return lv
func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	var lv := await go("res://world/levels/ashen_chapel.tscn", &"from_graveyard")
	var pl: Player = lv.player
	pl.global_position = Vector2(1650, 480)
	await frames(60)
	await shot("chapel_nave")
	pl.global_position = Vector2(2980, 480)
	await frames(90)
	await shot("chapel_cinder")
	var lv2 := await go("res://world/levels/vaelmoor_road.tscn", &"from_awake")
	lv2.player.global_position = Vector2(3380, 480)
	GameState.set_flag(&"boss_defeated_hollow_marshal", true)
	await frames(60)
	await shot("oath_gate")
	get_tree().quit()
