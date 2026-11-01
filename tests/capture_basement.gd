extends Node
## Renders the Lower Hell puzzles, the fox, the basement, the elder's awakening and the Fire Meteor.
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
func go(path: String, x: float) -> Player:
	Events.level_change_requested.emit(path, &"", false)
	await frames(90)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	p.global_position = Vector2(x, 480)
	await frames(30)
	return p
func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	GameState.preset_id = &"sworn_knight"
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.grant_gear("weapon", &"nightreaper")
	Loadout.equip_weapon(&"nightreaper")
	var p: Player = null
	# the basement: the elder asleep, then the change
	p = await go("res://world/levels/hell_basement.tscn", 1250.0)
	await shot("bs_elder")
	var boss := (load("res://actors/bosses/ember_elder.tscn") as PackedScene).instantiate() as BossBase
	boss.position = Vector2(1500, 480)
	boss.start_facing = -1
	main.find_child("HellBasement", true, false).add_child(boss)
	await frames(30)
	boss.start_fight()
	await frames(100)
	await shot("bs_boss")
	await frames(60)
	await shot("bs_boss2")
	# the meteor
	GameState.set_flag(&"art_has_fire_meteor", true)
	GameState.set_flag(&"art_equipped", "fire_meteor")
	Loadout.equip_weapon(&"oathblade")
	p.cutscene_lock = false
	p.set_focus(100.0)
	boss.queue_free()
	await frames(10)
	p.global_position = Vector2(1100, 480)
	await frames(20)
	Input.action_press(&"art")
	await frames(3)
	Input.action_release(&"art")
	await frames(12)
	await shot("bs_meteor_a")
	await frames(30)
	await shot("bs_meteor_b")
	get_tree().quit()
