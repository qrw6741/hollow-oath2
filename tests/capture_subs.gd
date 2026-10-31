extends Node
## Screenshot of the boss subtitle (single and two-boss HUD).
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var out := OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(30)
	GameState.in_game = true
	Events.level_change_requested.emit("res://world/levels/ninth_hell.tscn", &"", false)
	await frames(300)
	var lv = main.current_level()
	var arena := lv.get_node("TwinLordsArena") as DuoArena
	lv.player.global_position = Vector2(4850, 470)
	await frames(3)
	arena.intro_running = true
	for b in [arena.boss, arena.boss2]:
		arena._hide(b, false)
	arena._begin_fight()
	await frames(60)
	Events.boss_say.emit("Ashkar, the Black Reaper", "The Court slept. The Door slept. And still it walks.", &"twins_intro_1")
	await frames(60)
	get_viewport().get_texture().get_image().save_png(out + "/sub_two_bosses.png")
	Events.boss_say.emit("Veshti, the Far Hand", "Little ember. You carried your oath so far. Lay the weapon down, and we will make it quick.", &"twins_intro_2")
	await frames(120)
	get_viewport().get_texture().get_image().save_png(out + "/sub_long.png")
	get_tree().quit()
