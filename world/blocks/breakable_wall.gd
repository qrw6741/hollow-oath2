@tool
class_name BreakableWall
extends StaticBody2D
## A cracked section of wall that collapses after a few hits, revealing what is behind it.
## Remembered as a saved flag. Origin = top-left. TEMPORARY ART.

@export var size := Vector2(16, 60):
	set(v): size = v; queue_redraw()
@export var wall_id: StringName = &"wall"
@export var hits_needed := 3

var hits := 0
var _shape: CollisionShape2D
var _hurtbox: Hurtbox
var _shake := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if GameState.get_flag(_flag(), false):
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	_shape.shape = r
	_shape.position = size / 2.0
	add_child(_shape)
	_hurtbox = Hurtbox.new()
	_hurtbox.collision_layer = 16   # enemy hurtbox layer: the player's attacks look for it
	_hurtbox.collision_mask = 0
	_hurtbox.receiver = self
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = size + Vector2(4, 0)
	hs.shape = hr
	hs.position = size / 2.0
	_hurtbox.add_child(hs)
	add_child(_hurtbox)


func _flag() -> StringName:
	return StringName("wall_broken_" + String(wall_id))


func receive_hit(hit: HitData) -> int:
	if hit.environmental:
		return HitData.Result.IGNORED
	hits += 1
	_shake = 0.25
	GameFeel.spark(global_position + size / 2.0, Palette.STONE_LIGHT, 8)
	Audio.sfx_at(&"land", global_position + size / 2.0, 2.0, 0.7)
	if hits >= hits_needed:
		GameState.set_flag(_flag(), true)
		GameFeel.spark(global_position + size / 2.0, Palette.DUST, 26)
		GameFeel.shake(3.0, 0.3)
		Audio.sfx_at(&"gate_open", global_position + size / 2.0, -2.0, 1.3)
		Events.banner_requested.emit("A HIDDEN PASSAGE")
		queue_free()
	return HitData.Result.HIT


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		queue_redraw()


func _draw() -> void:
	var off := Vector2(randf_range(-1, 1), 0) * (_shake * 6.0)
	draw_rect(Rect2(off, size), Palette.STONE)
	for y in range(0, int(size.y), 10):
		draw_line(off + Vector2(0, y), off + Vector2(size.x, y), Palette.STONE_DARK, 1.0)
	# Cracks give it away (they grow with each hit).
	var c := Palette.INK
	draw_line(off + Vector2(size.x * 0.3, 4), off + Vector2(size.x * 0.6, size.y * 0.4), c, 1.0)
	draw_line(off + Vector2(size.x * 0.6, size.y * 0.4), off + Vector2(size.x * 0.4, size.y * 0.75), c, 1.0)
	if hits >= 1:
		draw_line(off + Vector2(size.x * 0.4, size.y * 0.75), off + Vector2(size.x * 0.7, size.y - 2), c, 1.0)
	if hits >= 2:
		draw_line(off + Vector2(2, size.y * 0.5), off + Vector2(size.x - 2, size.y * 0.55), c, 1.0)
