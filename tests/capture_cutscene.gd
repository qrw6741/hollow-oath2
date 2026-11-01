extends Node
## Plays the REAL Twin Lords cutscenes in real time and saves a screenshot every few seconds.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/capture_cutscene.tscn -- <out_dir>
var out_dir := "user://screens"
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
func secs(s: float, prefix: String, every: float, stop_when: Callable) -> void:
	var t0 := Time.get_ticks_msec()
	var n := 0
	var next := 0.0
	while float(Time.get_ticks_msec() - t0) < s * 1000.0 and not stop_when.call():
		await get_tree().process_frame
		if float(Time.get_ticks_msec() - t0) >= next * 1000.0:
			await shot("%s_%02d" % [prefix, n])
			n += 1
			next += every
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()
func _run() -> void:
	Settings.hit_stop = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	var main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await get_tree().create_timer(0.5).timeout
	GameState.in_game = true
	Events.level_change_requested.emit("res://world/levels/ninth_hell.tscn", &"", false)
	for i in 150:
		await get_tree().process_frame
	var lv = main.current_level()
	var arena := lv.get_node("TwinLordsArena") as DuoArena
	var p: Player = lv.player
	p.health.set_max(99999.0)
	p.health.restore_full()
	p.global_position = Vector2(arena.global_position.x + 120.0, 470)
	for i in 40:
		await get_tree().process_frame
	print("CUT player at ", p.global_position, " arena at ", arena.global_position)
	# the real intro
	await secs(120.0, "intro", 5.0, func(): return arena.fight_active)
	print("CUT intro done fight_active=", arena.fight_active, " lock=", p.cutscene_lock)
	await get_tree().create_timer(1.0).timeout
	arena.boss.health.take_damage(arena.boss.health.max_health * 2.0)
	await secs(60.0, "mid", 3.5, func(): return arena.boss2.enraged and not p.cutscene_lock)
	print("CUT mid done enraged=", arena.boss2.enraged, " lock=", p.cutscene_lock)
	arena.boss2.health.take_damage(arena.boss2.health.max_health * 2.0)
	var seen := [false]
	await secs(120.0, "end", 4.0, func():
		if p.cutscene_lock:
			seen[0] = true
		return seen[0] and not p.cutscene_lock)
	print("CUT end done defeated=", arena._defeated, " lock=", p.cutscene_lock)
	get_tree().quit()
