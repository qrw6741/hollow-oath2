@tool
extends Node2D
## Banded dusk sky with a pale, haloed moon. Screen-space (parallax 0).

@export var size := Vector2(480, 270)
@export var moon_pos := Vector2(372, 58)
## Daylight: a pale gold sky with a sun instead of the night sky and moon (the true Vaelmoor).
@export var daylight := false


func _draw() -> void:
	if daylight:
		_draw_day()
		return
	var bands := 18
	for i in bands:
		var t := float(i) / (bands - 1)
		var c := Palette.SKY_TOP.lerp(Palette.SKY_LOW, pow(t, 1.6))
		draw_rect(Rect2(0, size.y * i / bands, size.x, size.y / bands + 1), c)
	# Static stars (seeded so the sky never shimmers between redraws).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		var sp := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.55)
		var a := rng.randf_range(0.25, 0.75) * (1.0 - sp.y / (size.y * 0.6))
		draw_rect(Rect2(sp.floor(), Vector2.ONE), Color(Palette.BONE, a))
	# Ember glow on the horizon: warm light from the burning kingdom.
	var y0 := int(size.y * 0.50)
	var span := int(size.y * 0.34)
	for i in span:
		var t := float(i) / span
		draw_rect(Rect2(0, y0 + i, size.x, 1), Color(0.55, 0.22, 0.14, 0.13 * sin(t * PI)))
	draw_circle(moon_pos, 34, Color(Palette.MOON, 0.05))
	draw_circle(moon_pos, 24, Color(Palette.MOON, 0.08))
	draw_circle(moon_pos, 15, Palette.MOON)
	draw_circle(moon_pos + Vector2(4, -3), 3, Palette.MOON.darkened(0.12))
	draw_circle(moon_pos + Vector2(-5, 4), 2, Palette.MOON.darkened(0.1))
	# Thin cloud streaks crossing the moon.
	draw_rect(Rect2(moon_pos.x - 60, moon_pos.y + 6, 120, 2), Color(Palette.SKY_LOW, 0.85))
	draw_rect(Rect2(moon_pos.x - 30, moon_pos.y - 9, 80, 1), Color(Palette.SKY_LOW, 0.7))


func _draw_day() -> void:
	var top := Color("6f8fb0")
	var low := Color("f2d9a8")
	var bands := 30
	for i in bands:
		var t := float(i) / (bands - 1)
		draw_rect(Rect2(0, size.y * i / bands, size.x, size.y / bands + 1), top.lerp(low, pow(t, 1.3)))
	# Sun with a broad halo.
	for r in [70.0, 48.0, 32.0]:
		draw_circle(moon_pos, r, Color(1.0, 0.95, 0.8, 0.08))
	draw_circle(moon_pos, 17, Color("fff4d6"))
	# Soft clouds.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 7:
		var cy := rng.randf_range(30, 120)
		var cx := rng.randf_range(0, size.x)
		for k in 4:
			draw_circle(Vector2(cx + k * 14, cy + sin(k) * 3), rng.randf_range(8, 14), Color(1, 1, 1, 0.18))
