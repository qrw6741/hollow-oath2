extends Node
## Close-ups of the Lower Hell models: fox (idle, pounce wind-up), chained old man, the fire monster.
var out_dir := "user://screens"
var main: Node
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	GameState.preset_id = &"sworn_knight"
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	Events.level_change_requested.emit("res://world/levels/hell_basement.tscn", &"", false)
	await frames(90)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	p.global_position = Vector2(300, 480)
	var lvl := main.find_child("HellBasement", true, false)
	var cam := get_viewport().get_camera_2d() as CameraRig
	var fox := (load("res://actors/bosses/tooth_fox.tscn") as PackedScene).instantiate() as BossBase
	fox.position = Vector2(1500, 480)
	lvl.add_child(fox)
	var el := (load("res://actors/bosses/ember_elder.tscn") as PackedScene).instantiate() as BossBase
	el.position = Vector2(1900, 480)
	lvl.add_child(el)
	var old := ChainedElder.new()
	old.position = Vector2(1700, 480)
	lvl.add_child(old)
	await frames(40)
	p.cutscene_lock = true
	cam.cine_to(Vector2(1500, 440), 3.4, 0.05)
	await frames(30)
	await shot("m_fox")
	cam.cine_to(Vector2(1700, 450), 4.0, 0.05)
	await frames(30)
	await shot("m_old")
	old.sitting = 1.0
	old.glow = 0.6
	old.shout = 1.0
	await frames(5)
	await shot("m_old_scream")
	cam.cine_to(Vector2(1900, 410), 2.4, 0.05)
	await frames(30)
	await shot("m_fire")
	get_tree().quit()
