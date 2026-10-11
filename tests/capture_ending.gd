extends Node
## Renders the prologue ending: the light after the Drowned Canon and the true Vaelmoor.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_ending.tscn -- <out_dir>
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
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(20)
	Events.level_change_requested.emit("res://world/levels/drowned_catacombs.tscn", &"from_chapel", false)
	await frames(80)
	var lv: Level = main.current_level()
	lv.player.global_position = Vector2(2600, 720)
	await frames(50)
	var boss: BossBase = lv.get_node("CanonArena").boss
	var k := HitData.make(99999.0, null, Vector2.ZERO)
	k.parryable = false
	boss.receive_hit(k)
	await frames(60 * 4 + 30)
	await shot("e1_light")
	lv.player.global_position = Vector2(2856, 720)
	await frames(50)
	await shot("e2_ascending")
	await frames(40)
	await shot("e3_white")
	await frames(200)
	await shot("e4_awake")
	var l2: Level = main.current_level()
	l2.player.global_position = Vector2(690, 460)
	await frames(30)
	Events.message_requested.emit("The Waking Stone", l2.get_node("WakingStone").text)
	await frames(10)
	await shot("e5_stone")
	Events.message_closed.emit()
	l2.player.global_position = Vector2(1400, 460)
	await frames(80)
	await shot("e6_hills")
	get_tree().quit()
