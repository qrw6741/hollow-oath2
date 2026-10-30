extends Node
## Persistent game root. Holds the camera, HUD, pause menu, main menu and FX layer,
## and owns the session flow: menu -> new game / continue -> level -> back to menu.
## Scene changes are covered by a short fade. Nothing else loads levels.

const LEVEL_DIR := "res://world/levels/"

## Level used for new games (and as the fallback if a save names a missing level).
@export var start_level: PackedScene
## Tests and dev runs can skip the menu and drop straight into [member start_level].
@export var show_menu_on_start := true

@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD
@onready var menu: CanvasLayer = $MainMenu

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	Events.new_cycle_requested.connect(begin_new_cycle)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	Events.new_game_requested.connect(start_new_game)
	Events.load_game_requested.connect(continue_slot)
	Events.quit_to_menu_requested.connect(return_to_menu)
	Events.level_change_requested.connect(change_level)
	Events.teleport_requested.connect(teleport)

	if show_menu_on_start:
		_enter_menu()
	else:
		menu.close()
		hud.visible = true
		if start_level:
			load_level(start_level)
		GameState.in_game = true


# ------------------------------------------------------------------ session flow

func start_new_game(slot: int, preset_id: StringName = &"sworn_knight") -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	GameState.new_game(slot, preset_id if Presets.is_valid_id(String(preset_id)) else &"sworn_knight")
	if not SaveSystem.save_slot(slot):
		# Never start a session that cannot be saved without telling the player.
		GameState.reset()
		await _fade_to(0.0)
		_busy = false
		return
	_begin_game()
	await _fade_to(0.0)
	_busy = false


## New Game+: keeps your build, restarts the story one cycle harder, saves, and reloads the world.
func begin_new_cycle() -> void:
	if _busy or not GameState.in_game:
		return
	_busy = true
	get_tree().paused = false
	await _fade_to(1.0, 1.0)
	var n := GameState.begin_new_cycle()
	SaveSystem.save_slot(GameState.current_slot)
	_begin_game()
	await _fade_to(0.0, 1.0)
	Events.banner_requested.emit("NEW CYCLE %d" % n)
	_busy = false


func continue_slot(slot: int) -> void:
	if _busy:
		return
	var r := SaveSystem.load_slot(slot)
	if r.status != SaveSystem.Status.OK:
		menu.show_message("That save could not be loaded.")
		return
	_busy = true
	await _fade_to(1.0)
	GameState.apply_dict(r.data, slot)
	_begin_game()
	await _fade_to(0.0)
	_busy = false


func return_to_menu() -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	await _fade_to(1.0)
	_enter_menu()
	await _fade_to(0.0)
	_busy = false


func _enter_menu() -> void:
	GameState.in_game = false
	GameState.session_id += 1   # Cancels any pending respawn from the old session.
	_unload_level()
	GameFeel.reset()
	hud.visible = false
	menu.open()
	Audio.music(&"menu")


func _begin_game() -> void:
	menu.close()
	hud.visible = true
	var scene := _level_scene(GameState.level_path)
	var lvl := load_level(scene)
	GameState.level_path = scene.resource_path
	GameState.level_name = lvl.display_name
	GameState.in_game = true
	Events.session_started.emit()


## Moves the session to another level (through an exit, or to respawn at a candle that
## is in a different level). Covered by the fade; autosaves on arrival through an exit.
func change_level(path: String, entry_id: StringName, respawn := false, fade_color := Color.BLACK, fade_out := 0.45, fade_in := 0.45) -> void:
	if _busy or not GameState.in_game:
		return
	_busy = true
	get_tree().paused = false
	_fade.color = Color(fade_color, _fade.color.a)
	await _fade_to(1.0, fade_out)
	GameState.level_entry = entry_id
	var scene := _level_scene(path)
	var lvl := load_level(scene)
	GameState.level_path = scene.resource_path
	GameState.level_name = lvl.display_name
	await get_tree().process_frame
	if respawn:
		lvl.player._iframes = 60
		Events.player_respawned.emit(lvl.player)
	else:
		SaveSystem.autosave()
	Events.level_entered.emit(GameState.level_path)
	await _fade_to(0.0, fade_in)
	_fade.color = Color(0, 0, 0, 0)
	_busy = false


## The prologue's ending: a long fade through white into another world.
func teleport(path: String, entry_id: StringName) -> void:
	await change_level(path, entry_id, false, Color(1.0, 0.97, 0.88), 1.6, 2.2)


## Only levels inside LEVEL_DIR that exist are accepted; anything else (an edited or
## outdated save) falls back to the start level instead of crashing.
func _level_scene(path: String) -> PackedScene:
	if path.begins_with(LEVEL_DIR) and ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene
	return start_level


# ------------------------------------------------------------------ levels

func load_level(scene: PackedScene) -> Level:
	GameFeel.reset()
	_unload_level()
	var lvl := scene.instantiate() as Level
	world.add_child(lvl)
	world.move_child(lvl, 0)
	return lvl


func _unload_level() -> void:
	for c in world.get_children():
		if c is Level:
			world.remove_child(c)
			c.queue_free()


func current_level() -> Level:
	for c in world.get_children():
		if c is Level and not c.is_queued_for_deletion():
			return c
	return null


func _fade_to(alpha: float, duration := 0.35) -> void:
	var t := create_tween()
	t.tween_property(_fade, ^"color:a", alpha, duration)
	await t.finished
