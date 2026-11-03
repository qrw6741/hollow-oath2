extends Node
var out_dir := "user://screens"
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
	var main: Node = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	Events.level_change_requested.emit("res://world/levels/lower_hell.tscn", &"", false)
	await frames(120)
	var pl: Player = get_tree().get_first_node_in_group(&"player")
	pl.health.set_max(99999.0)
	pl.health.restore_full()
	GameState.grant_gear("weapon", &"long_katana")
	Loadout.equip_weapon(&"long_katana")
	var lvl: Node = main.current_level()
	var spots := [["01_landing", "Candle0"], ["02_outer_ward", "WardBrazier1"], ["03_great_hall", "Hall4"], ["04_throne", "HallThrone"],
		["05_four_wards_loft", "LeverB"], ["06_first_gate", "Gate1"], ["07_rune_room", "RuneEye"], ["08_timed_run", "RunLeverY"],
		["09_fox_stair", "Candle3"], ["10_broken_stair", "StairStep5"], ["11_keepers_walk", "KeepA2"], ["12_chandelier_run", "Chand8"],
		["13_belfry_climb", "Belfry5"], ["14_katana_nest", "ChestKatana"], ["15_kennels", "KennelFoe4"], ["16_gallows_stair", "Gallows12"],
		["17_long_corridor", "CorrFoe6"], ["18_crown_walk", "Crown13"], ["19_the_end", "Candle13"]]
	for sp in spots:
		var n: Node = lvl.find_child(sp[1], true, false)
		if n == null:
			print("MISSING ", sp[1])
			continue
		var pos: Vector2 = n.global_position
		if n is StoneBlock:
			pos += Vector2(n.size.x * 0.5, -8.0)
		elif sp[1] == "Gate1":
			pos += Vector2(-110, -4)
		else:
			pos += Vector2(-30 if sp[1] != "ChestKatana" else -45, -6)
		pl.global_position = pos
		pl.velocity = Vector2.ZERO
		await frames(75)
		await shot(sp[0])
	get_tree().quit()
