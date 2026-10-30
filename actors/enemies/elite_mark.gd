class_name EliteMark
extends Node2D
## A slow gold diamond and ember halo over elite enemies, so they read as dangerous at a glance.

var _t := 0.0
var tint := Palette.EMBER


func _ready() -> void:
	position = Vector2(0, -62)
	z_index = 19
	_t = randf() * 6.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var b := 0.75 + 0.25 * sin(_t * 3.0)
	var c := Color(Palette.GOLD_BRIGHT, b)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)]), c)
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, Color(tint, 0.65 * b), 0.8)
