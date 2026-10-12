class_name TreasureChest
extends Area2D
## A chest. Press interact to open it and take what is inside; it stays open for the
## life of the save (world flag chest_open_<id>). Some chests in the world are Mimics,
## which use the same drawing (see Mimic) — a real chest never breathes.
## TEMPORARY ART (procedural).

@export var item: ItemData
@export var count := 1
@export var embers := 0
## Optional gear inside: "weapon" or "armor" and its id (see GameState.grant_gear).
@export_enum("none", "weapon", "armor") var gear_kind := "none"
@export var gear_id: StringName = &""
## Unique across the game; used for the saved "opened" flag.
@export var chest_id: StringName = &""

var opened := false
var _open_t := 1.0
var _player_inside: Player


func _ready() -> void:
	opened = chest_id != &"" and GameState.get_flag(_flag(), false)
	_open_t = 1.0 if opened else 0.0
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(b: Node) -> void:
	if b is Player and not opened:
		_player_inside = b
		Events.interact_prompt_shown.emit("Open chest")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _flag() -> StringName:
	return StringName("chest_open_" + String(chest_id))


func _physics_process(delta: float) -> void:
	if opened and _open_t < 1.0:
		_open_t = minf(1.0, _open_t + delta * 3.0)
		queue_redraw()
	if not opened and _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		open()


func open() -> void:
	opened = true
	_player_inside = null
	Events.interact_prompt_hidden.emit()
	GameState.set_flag(_flag(), true)
	Audio.sfx_at(&"door_open", global_position, -4.0, 1.4)
	var parts: Array[String] = []
	if item and count > 0 and GameState.add_item(item.id, count) > 0:
		parts.append("%s  x%d" % [item.display_name, count])
	if gear_kind != "none" and gear_id != &"":
		GameState.grant_gear(gear_kind, gear_id)
		var nm := String(gear_id)
		if gear_kind == "armor" and Armors.get_armor(gear_id):
			nm = Armors.get_armor(gear_id).display_name
		elif gear_kind == "weapon" and Weapons.get_weapon(gear_id):
			nm = Weapons.get_weapon(gear_id).display_name
		parts.append(nm)
	if embers > 0:
		GameState.add_embers(embers)
		parts.append("%d embers" % embers)
	if not parts.is_empty():
		Events.banner_requested.emit("   ".join(parts))
	GameFeel.spark(global_position + Vector2(0, -14), Palette.GOLD_BRIGHT, 14)
	queue_redraw()


func _draw() -> void:
	draw_chest(self, _open_t, 0.0, 1.0)


## Shared chest drawing (origin = bottom centre). [param lid] 0 closed .. 1 open.
static func draw_chest(ci: CanvasItem, lid: float, flash: float, alpha: float, lid_lift := 0.0) -> void:
	var wood := Palette.WOOD.lerp(Color.WHITE, flash)
	var wood_l := Palette.WOOD_LIGHT.lerp(Color.WHITE, flash)
	var iron := Palette.STEEL_OXIDE.lerp(Color.WHITE, flash)
	wood.a = alpha; wood_l.a = alpha; iron.a = alpha
	ci.draw_rect(Rect2(-11, -12, 22, 12), wood)
	ci.draw_rect(Rect2(-11, -12, 22, 1), wood_l)
	ci.draw_rect(Rect2(-9, -12, 2, 12), iron)
	ci.draw_rect(Rect2(7, -12, 2, 12), iron)
	if lid < 0.5:
		var y := -12.0 - lid_lift
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-11, y), Vector2(-10, y - 5), Vector2(-6, y - 7), Vector2(6, y - 7), Vector2(10, y - 5), Vector2(11, y)]), wood_l)
		ci.draw_rect(Rect2(-9, y - 6.5, 2, 6.5), iron)
		ci.draw_rect(Rect2(7, y - 6.5, 2, 6.5), iron)
		ci.draw_rect(Rect2(-2, y - 2, 4, 4), Color(Palette.GOLD, alpha))
	else:
		# Lid swung back, interior dark.
		ci.draw_rect(Rect2(-10, -12, 20, 2), Color(0.05, 0.04, 0.05, alpha))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-11, -12), Vector2(-13, -20), Vector2(-12, -24), Vector2(10, -24), Vector2(11, -20), Vector2(11, -12)]), Color(wood_l, alpha * 0.9))
		ci.draw_rect(Rect2(-9, -24, 2, 12), iron)
		ci.draw_rect(Rect2(7, -24, 2, 12), iron)
