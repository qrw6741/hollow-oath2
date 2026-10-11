extends Node
## Renders button prompts for keyboard, PlayStation and Xbox styles.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_prompts.tscn -- <out_dir>
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
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))

func _run() -> void:
	SaveSystem.save_dir = "user://capture_saves"
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	var lv: Level = main.current_level()
	lv.player.global_position = Vector2(230, 480)
	await frames(20)
	for style in [["kb", 0, 0], ["ps", 1, 1], ["xbox", 2, 2]]:
		Settings.pad_style = style[1]
		if style[0] == "kb":
			InputPrompts.set_device(InputPrompts.Device.KEYBOARD, true)
		else:
			InputPrompts.set_device(InputPrompts.Device.PLAYSTATION if style[1] == 1 else InputPrompts.Device.XBOX, true)
		await frames(5)
		await shot("c_%s_arena" % style[0])
	Settings.pad_style = 1
	InputPrompts.set_device(InputPrompts.Device.PLAYSTATION, true)
	Events.interact_prompt_shown.emit("Rest at Oath Candle")
	await frames(5)
	await shot("c_ps_prompt")
	Events.interact_prompt_hidden.emit()
	main.queue_free()
	await frames(3)
	main = load("res://main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await frames(30)
	await shot("c_ps_menu")
	main.menu._show_screen(3)
	await frames(10)
	await shot("c_ps_settings")
	get_tree().quit()
