extends Node
## Renders the expansion: Sunken Reliquary, new weapons, Arts tab, Trial Ring.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_expansion.tscn -- <out_dir>
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
	var lv := await go("res://world/levels/sunken_reliquary.tscn", &"from_chapel")
	var pl: Player = lv.player
	for id in [&"gravediggers_greataxe", &"veil_daggers", &"candle_catalyst", &"abbots_crozier"]:
		GameState.grant_gear("weapon", id)
	Loadout.equip_weapon(&"gravediggers_greataxe")
	pl.global_position = Vector2(300, 480)
	await frames(60)
	await shot("rel_stair")
	pl.global_position = Vector2(1760, 480)
	await frames(100)
	await shot("rel_jets")
	pl.global_position = Vector2(1100, 480)
	await frames(30)
	await shot("rel_lurker_spring")
	pl.global_position = Vector2(3500, 480)
	await frames(30)
	GameState.set_flag(&"boss_defeated_bell_warden", true)
	Events.boss_defeated.emit(&"bell_warden")
	await frames(120)
	await shot("rel_boss_intro")
	await frames(60)
	await shot("rel_boss")
	for w in [&"gravediggers_greataxe", &"candle_catalyst", &"abbots_crozier", &"veil_daggers"]:
		Loadout.equip_weapon(w)
		pl.global_position = Vector2(2000, 480)
		await frames(20)
		Input.action_press(&"attack_light")
		await frames(8)
		Input.action_release(&"attack_light")
		await frames(6)
		await shot("weapon_" + String(w))
	var inv = main.get_node("InventoryMenu")
	inv.open(InventoryMenu.Tab.ARTS)
	await frames(10)
	await shot("arts_tab")
	inv.open(InventoryMenu.Tab.WEAPONS)
	await frames(10)
	await shot("weapons_tab")
	inv.close()
	GameState.set_flag(&"ending_chosen", "keep")
	var lv3 := await go("res://world/levels/trial_ring.tscn", &"from_manor")
	lv3.player.global_position = Vector2(250, 480)
	await frames(30)
	await shot("trial_ring")
	get_tree().quit()
