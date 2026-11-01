extends Node
## Screenshots of the weapon/armour chooser and the Weapons tab with every weapon owned.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/capture_inventory.tscn -- <out_dir>
var out_dir := "user://screens"
func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
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
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.in_game = true
	for id in Weapons.IDS:
		GameState.grant_gear("weapon", id)
	for id in Armors.IDS:
		GameState.grant_gear("armor", id)
	var im: InventoryMenu = main.get_node("InventoryMenu")
	im.open()
	await frames(20)
	await shot("1_equipment")
	im.open_picker("weapon")
	await frames(20)
	await shot("2_weapon_picker")
	(im.picker_buttons[im.picker_buttons.size() - 1].button as Button).grab_focus()
	await frames(25)
	await shot("3_weapon_picker_scrolled")
	im.close_picker()
	im.open_picker("armour")
	await frames(20)
	await shot("4_armour_picker")
	im.close_picker()
	im.show_tab(InventoryMenu.Tab.WEAPONS)
	await frames(20)
	await shot("5_weapons_tab")
	var ws := im.find_child("WeaponScroll", true, false) as ScrollContainer
	ws.scroll_vertical = 9999
	await frames(10)
	await shot("6_weapons_tab_scrolled")
	get_tree().quit()
