extends Node
## Renders the TALISMANS and ALCHEMY tabs plus the HUD buff list.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_talismans.tscn -- <out_dir>
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
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.in_game = true
	for id in [&"tal_warden", &"tal_marshal", &"tal_king", &"tal_brand", &"tal_iron_bead", &"tal_swift_feather", &"tal_mender", &"tal_abbot"]:
		GameState.add_item(id, 1)
	Talismans.toggle(&"tal_king")
	Talismans.toggle(&"tal_brand")
	GameState.add_item(&"hollow_resin", 3)
	GameState.add_item(&"ember_shard", 2)
	GameState.add_item(&"ash_bandage", 1)
	GameState.add_item(&"forge_scrap", 2)
	GameState.add_embers(900)
	Buffs.start(&"potion_might")
	Buffs.start(&"potion_ward")
	var inv: InventoryMenu = main.get_node("InventoryMenu")
	await frames(30)
	await shot("hud_buffs")
	inv.open(InventoryMenu.Tab.TALISMANS)
	await frames(20)
	await shot("tab_talismans")
	inv.show_tab(InventoryMenu.Tab.ALCHEMY)
	await frames(20)
	await shot("tab_alchemy")
	inv.show_tab(InventoryMenu.Tab.EQUIPMENT)
	await frames(10)
	await shot("tab_equipment")
	get_tree().quit()
