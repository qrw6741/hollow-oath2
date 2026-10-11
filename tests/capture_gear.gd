extends Node
## Renders the gear content: the smiths, both menus, the equipment screen with its pickers,
## and every new weapon / armour on the character.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_gear.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node
var lv: Level
var pl: Player

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

func go(path: String, entry: StringName) -> void:
	Events.level_change_requested.emit(path, entry, false)
	await frames(80)
	lv = main.current_level()
	pl = lv.player

func at(x: float, y := 480.0, face := 1) -> void:
	pl.global_position = Vector2(x, y)
	pl.velocity = Vector2.ZERO
	pl.facing = face

func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.embers = 2400
	GameState.add_item(&"forge_scrap", 12)
	GameState.add_item(&"hollow_resin", 4)
	GameState.add_item(&"warden_bell_shard", 1)
	GameState.add_item(&"marshals_crest", 1)
	GameState.set_gear_level("weapon", &"oathblade", 2)
	for w in [&"wayfarers_rapier", &"kingsfall_greatsword", &"toll_hammer", &"marshals_lance", &"tide_sabre"]:
		GameState.grant_gear("weapon", w)
	for a in [&"pilgrim_coat", &"penitent_shroud", &"canons_mail", &"marshal_plate"]:
		GameState.grant_gear("armor", a)
	GameState.set_gear_level("armor", &"sworn_knight", 1)
	# --- The road: Hobb, Wenna and Ilse
	await go("res://world/levels/vaelmoor_road.tscn", &"from_awake")
	at(300.0)
	await frames(30)
	await shot("g1_smiths")
	Events.station_requested.emit(&"forge")
	await frames(10)
	await shot("g2_forge_weapons")
	var fm: ForgeMenu = main.get_node("ForgeMenu")
	fm.show_tab("armor")
	await frames(6)
	await shot("g3_forge_armour")
	fm.close()
	await frames(4)
	Events.station_requested.emit(&"vials")
	await frames(10)
	await shot("g4_vials")
	fm.close()
	await frames(4)
	# --- Equipment screen and pickers
	var im: InventoryMenu = main.get_node("InventoryMenu")
	im.open()
	await frames(10)
	await shot("g5_equipment")
	im.open_picker("armour")
	await frames(6)
	await shot("g6_armour_picker")
	im.choose(Armors.NONE)
	await frames(8)
	await shot("g7_naked")
	im.open_picker("weapon")
	await frames(6)
	await shot("g8_weapon_picker")
	im.close_picker()
	im.close()
	await frames(4)
	# --- Each weapon mid-swing, and each armour at rest (the arena has the dummy)
	await go("res://world/levels/test_arena.tscn", &"")
	Loadout.equip_armor(&"sworn_knight")
	var i := 0
	for w in [&"oathblade", &"wayfarers_rapier", &"kingsfall_greatsword", &"toll_hammer", &"marshals_lance", &"tide_sabre"]:
		Loadout.equip_weapon(w)
		await frames(3)
		at(300.0)
		await frames(20)
		var wd := Weapons.get_weapon(w)
		pl._start_attack(wd.light_combo_start)
		await frames(wd.light_combo_start.startup_frames + 2)
		await shot("w%d_%s_active" % [i, w])
		await frames(40)
		pl._start_attack(wd.heavy)
		await frames(wd.heavy.startup_frames + wd.heavy.active_frames / 2)
		await shot("w%d_%s_heavy" % [i, w])
		await frames(70)
		i += 1
	Loadout.equip_weapon(&"oathblade")
	i = 0
	for a in [&"sworn_knight", &"duelist", &"bulwark", &"pilgrim_coat", &"penitent_shroud", &"canons_mail", &"marshal_plate", Armors.NONE]:
		Loadout.equip_armor(a)
		at(300.0)
		await frames(30)
		await shot("a%d_%s" % [i, a])
		i += 1
	print("gear captures done")
	get_tree().quit()
