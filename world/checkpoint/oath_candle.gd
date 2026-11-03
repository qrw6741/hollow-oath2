@tool
class_name OathCandle
extends Area2D
## Checkpoint: a cluster of votive candles before a cracked oath-stone.
## Resting kindles it, fully restores the player (health, stamina, vials),
## sets the respawn point and revives all enemies in the level.
## TEMPORARY ART (procedural), real light via PointLight2D.

@export var checkpoint_id: StringName = &"candle"
@export var display_name := "Oath Candle"
## Respawn offset from the candle (stand beside it, not inside it).
@export var respawn_offset := Vector2(22, 0)

var lit := false
var _player_inside: Player
var _t := 0.0
var _light: PointLight2D
var _kindle := 0.0


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	if get_node_or_null(^"Shape") == null:
		var cs := CollisionShape2D.new()
		cs.name = &"Shape"
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 32)
		cs.shape = r
		cs.position = Vector2(0, -16)
		add_child(cs)
	_light = PointLight2D.new()
	_light.texture = LightTex.radial()
	_light.texture_scale = 1.8
	_light.color = Palette.GOLD_BRIGHT
	_light.energy = 0.45
	_light.position = Vector2(0, -10)
	add_child(_light)
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	lit = GameState.has_checkpoint and GameState.checkpoint_id == checkpoint_id


func _on_body_entered(b: Node) -> void:
	if b is Player:
		_player_inside = b
		Events.interact_prompt_shown.emit(("Rest" if lit else "Kindle") + " at " + display_name)


func _on_body_exited(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	_kindle = maxf(0.0, _kindle - delta)
	if _light:
		var flicker := 0.06 * sin(_t * 13.0) + 0.04 * sin(_t * 31.0)
		_light.energy = (1.0 if lit else 0.45) + flicker + _kindle * 1.5
	if Near.player(self): queue_redraw()
	if Engine.is_editor_hint():
		return
	if _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		rest(_player_inside)


func rest(p: Player) -> void:
	var first := not lit
	lit = true
	_kindle = 0.6
	p.facing = 1 if global_position.x >= p.global_position.x else -1
	p.rest()
	Events.checkpoint_rested.emit(checkpoint_id, global_position + respawn_offset)
	Events.banner_requested.emit("OATH KINDLED" if first else "OATH RENEWED")
	GameFeel.spark(global_position + Vector2(0, -12), Palette.GOLD_BRIGHT, 20)


func _draw() -> void:
	# Oath-stone: cracked tablet behind the candles.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(-8, -26), Vector2(-3, -30), Vector2(3, -30), Vector2(8, -26), Vector2(9, 0)]), Palette.STONE)
	draw_line(Vector2(-1, -30), Vector2(1, -18), Palette.STONE_DARK, 1.0)
	draw_line(Vector2(1, -18), Vector2(-2, -8), Palette.STONE_DARK, 1.0)
	var glyph := Palette.GOLD if lit else Palette.STONE_LIGHT
	draw_arc(Vector2(0, -21), 3.5, 0, TAU, 10, glyph, 1.0)
	draw_line(Vector2(0, -25), Vector2(0, -12), glyph, 1.0)
	# Candles.
	var candles := [Vector2(-12, 0), Vector2(-7, 0), Vector2(7, 0), Vector2(11, 0), Vector2(15, 0)]
	var heights := [7.0, 10.0, 8.0, 5.0, 6.0]
	for i in candles.size():
		var base: Vector2 = candles[i]
		var h: float = heights[i]
		draw_rect(Rect2(base + Vector2(-1, -h), Vector2(2.5, h)), Palette.BONE_DIM)
		draw_rect(Rect2(base + Vector2(-1.5, -1), Vector2(3.5, 1)), Palette.BONE)  # wax pool
		if lit or i % 2 == 0:
			var fl := sin(_t * 11.0 + i * 1.7) * 0.6
			var tip := base + Vector2(0.25 + fl * 0.4, -h - 3.5)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-0.8, -h - 0.5), tip, base + Vector2(1.3, -h - 0.5)]), Palette.EMBER if lit else Color(Palette.EMBER, 0.5))
			draw_circle(base + Vector2(0.25, -h - 1.2), 0.8, Palette.GOLD_BRIGHT)
