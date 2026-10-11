@tool
class_name LevelExit
extends Area2D
## Leads to another level. WALK exits trigger when the player walks in (open edges,
## passages); DOOR exits need the interact button and may require a key item.
## Origin = bottom centre. TEMPORARY ART: doors are drawn in code.

enum Mode { WALK, DOOR }

@export_file("*.tscn") var target_level := ""
@export var target_entry: StringName = &"entry"
@export var mode := Mode.WALK:
	set(v): mode = v; queue_redraw()
@export var size := Vector2(16, 64):
	set(v): size = v; queue_redraw()
## DOOR only: item that must be carried to open it the first time ("" = none).
@export var required_item: StringName = &""
## Unique id; an unlocked door is remembered as a saved flag.
@export var door_id: StringName = &""
@export var display_name := "door"
@export var locked_text := "It will not open."
@export var unlock_text := ""
## DOOR only: a door that can never be opened in this build (end of content).
@export var sealed := false

var _player_inside: Player
var _armed := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(0, -size.y / 2.0)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_armed = 20   # do not fire on the frame the player spawns on top of an exit


func is_unlocked() -> bool:
	return required_item == &"" or (door_id != &"" and GameState.get_flag(StringName("door_open_" + String(door_id)), false))


func _on_enter(b: Node) -> void:
	if not (b is Player):
		return
	_player_inside = b
	if mode == Mode.DOOR:
		Events.interact_prompt_shown.emit("Open %s" % display_name)


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		if mode == Mode.DOOR:
			Events.interact_prompt_hidden.emit()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _armed > 0:
		_armed -= 1
		return
	if _player_inside == null or _player_inside.is_dead() or not GameState.in_game:
		return
	if mode == Mode.WALK:
		_go()
	elif Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		try_open()


## DOOR: checks the lock, then leaves. Returns true if the level change was requested.
func try_open() -> bool:
	if sealed:
		Audio.sfx(&"door_locked")
		Events.banner_requested.emit(locked_text)
		return false
	if not is_unlocked():
		if GameState.item_count(required_item) <= 0:
			Audio.sfx(&"door_locked")
			Events.banner_requested.emit(locked_text)
			return false
		GameState.set_flag(StringName("door_open_" + String(door_id)), true)
		if unlock_text != "":
			Events.banner_requested.emit(unlock_text)
	Audio.sfx(&"door_open")
	Events.interact_prompt_hidden.emit()
	_go()
	return true


func _go() -> void:
	if target_level == "":
		return
	_player_inside = null
	Events.level_change_requested.emit(target_level, target_entry, false)


func _draw() -> void:
	if mode == Mode.WALK:
		if Engine.is_editor_hint():
			draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(0.2, 0.5, 1.0, 0.3))
		# A dark mouth / passage gradient so the way out reads.
		for i in 6:
			draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(0, 0, 0, 0.06))
		return
	# Heavy double door in a stone arch.
	var w := size.x
	var h := size.y
	draw_rect(Rect2(-w / 2.0 - 4, -h - 6, w + 8, h + 6), Palette.STONE_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0 - 4, -h - 6), Vector2(0, -h - 16), Vector2(w / 2.0 + 4, -h - 6)]), Palette.STONE_DARK)
	draw_rect(Rect2(-w / 2.0, -h, w, h), Palette.WOOD)
	draw_line(Vector2(0, -h), Vector2(0, 0), Palette.INK, 1.0)
	for y in [-h * 0.75, -h * 0.35]:
		draw_line(Vector2(-w / 2.0, y), Vector2(w / 2.0, y), Palette.STEEL_OXIDE, 2.0)
	var lock_col := Palette.GOLD if (not Engine.is_editor_hint() and is_unlocked() and not sealed) else Palette.STEEL_OXIDE
	if required_item == &"warden_bell_shard":
		# A bell-shaped lock.
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -h * 0.5 + 4), Vector2(-2, -h * 0.5 - 3), Vector2(2, -h * 0.5 - 3), Vector2(3, -h * 0.5 + 4)]), lock_col)
	else:
		draw_circle(Vector2(0, -h * 0.5), 2.2, lock_col)
	if sealed:
		draw_line(Vector2(-w / 2.0, -h * 0.55), Vector2(w / 2.0, -h * 0.45), Palette.WOOD_LIGHT, 3.0)
