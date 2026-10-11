extends Node
## Renders the preset selection screen and each preset in-game (idle + attack frames).
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_presets.tscn -- <out_dir>

var out_dir := "user://screens"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shot(name: String, crop := false) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var k := img.get_width() / 480.0
	var c := Vector2(240, 135)
	if crop and main.current_level():
		c = main.current_level().player.get_global_transform_with_canvas().origin
	if crop:
		img = img.get_region(Rect2i(c.x * k - 45 * k, c.y * k - 52 * k, 90 * k, 70 * k))
		img.resize(720, 560, Image.INTERPOLATE_NEAREST)
	else:
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(30)
	main.menu._open_slots(0)
	await frames(3)
	main.menu._rows[0].act.pressed.emit()
	await frames(3)
	for i in 4:
		main.menu._preset_btns[i].grab_focus()
		await frames(8)
		await shot("p_select_%d_%s" % [i, Presets.IDS[i]])
	main.queue_free()
	await frames(3)

	for id in Presets.IDS:
		GameState.reset()
		GameState.preset_id = id
		main = load("res://main/main.tscn").instantiate()
		main.show_menu_on_start = false
		get_tree().root.add_child(main)
		await frames(40)
		await shot("p_%s_idle" % id, true)
		var attacks := ["attack_light", "attack_light", "attack_light", "attack_heavy"]
		for a in 2:
			Input.action_press(&"attack_light")
			await frames(2)
			Input.action_release(&"attack_light")
			await frames(7 if a == 0 else 8)
			await shot("p_%s_light%d" % [id, a + 1], true)
			await frames(50)
		Input.action_press(&"attack_heavy")
		await frames(2)
		Input.action_release(&"attack_heavy")
		await frames(16)
		await shot("p_%s_heavy" % id, true)
		await frames(80)
		Input.action_press(&"parry")
		await frames(2)
		Input.action_release(&"parry")
		await frames(3)
		await shot("p_%s_parry" % id, true)
		main.queue_free()
		await frames(3)
	for s in range(1, 4):
		SaveSystem.delete_slot(s)
	get_tree().quit()
