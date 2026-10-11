@tool
extends Node2D
## Banded dusk sky with a pale, haloed moon. Screen-space (parallax 0).

@export var size := Vector2(480, 270)
@export var moon_pos := Vector2(372, 58)


func _draw() -> void:
	var bands := 18
	for i in bands:
		var t := float(i) / (bands - 1)
		var c := Palette.SKY_TOP.lerp(Palette.SKY_LOW, pow(t, 1.6))
		draw_rect(Rect2(0, size.y * i / bands, size.x, size.y / bands + 1), c)
	draw_circle(moon_pos, 34, Color(Palette.MOON, 0.05))
	draw_circle(moon_pos, 24, Color(Palette.MOON, 0.08))
	draw_circle(moon_pos, 15, Palette.MOON)
	draw_circle(moon_pos + Vector2(4, -3), 3, Palette.MOON.darkened(0.12))
	draw_circle(moon_pos + Vector2(-5, 4), 2, Palette.MOON.darkened(0.1))
	# Thin cloud streaks crossing the moon.
	draw_rect(Rect2(moon_pos.x - 60, moon_pos.y + 6, 120, 2), Color(Palette.SKY_LOW, 0.85))
	draw_rect(Rect2(moon_pos.x - 30, moon_pos.y - 9, 80, 1), Color(Palette.SKY_LOW, 0.7))
