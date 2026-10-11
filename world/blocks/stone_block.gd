@tool
class_name StoneBlock
extends StaticBody2D
## Level-building primitive: a solid rectangle of masonry (or a one-way plank
## platform) whose collision and look are generated from [member size].
## Origin = top-left corner. Drop it into a level, set size, done.
## TEMPORARY ART: procedural masonry until the region tilesets exist (Milestone 5).

enum Style { MASONRY, RUBBLE, PLANKS }

@export var size := Vector2(64, 32):
	set(v):
		size = v.max(Vector2(4, 4))
		_rebuild()
@export var style := Style.MASONRY:
	set(v):
		style = v
		_rebuild()
## One-way platforms can be jumped through from below.
@export var one_way := false:
	set(v):
		one_way = v
		_rebuild()
@export var seed_value := 1:
	set(v):
		seed_value = v
		queue_redraw()

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = get_node_or_null(^"Shape") as CollisionShape2D
		if _shape == null:
			_shape = CollisionShape2D.new()
			_shape.name = &"Shape"
			add_child(_shape)
	var rect := RectangleShape2D.new()
	var h := 6.0 if one_way else size.y
	rect.size = Vector2(size.x, h)
	_shape.shape = rect
	_shape.position = Vector2(size.x * 0.5, h * 0.5)
	_shape.one_way_collision = one_way
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + int(size.x) * 31 + int(size.y)
	if style == Style.PLANKS or one_way:
		draw_rect(Rect2(0, 0, size.x, 6), Palette.WOOD)
		draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), Palette.WOOD_LIGHT, 1.0)
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, 1), Vector2(x, 6), Palette.INK, 1.0)
			x += rng.randi_range(14, 24)
		# Supports.
		for sx in [4.0, size.x - 6.0]:
			draw_line(Vector2(sx, 6), Vector2(sx + 1, 14), Palette.WOOD, 2.0)
		return

	draw_rect(Rect2(Vector2.ZERO, size), Palette.STONE_DARK)
	var row_h := 8.0
	var y := 0.0
	var row := 0
	while y < size.y:
		var x := -float((row % 2) * 8)
		while x < size.x:
			var w := float(rng.randi_range(12, 20)) if style == Style.MASONRY else float(rng.randi_range(6, 14))
			var r := Rect2(maxf(x, 0.0) + 1, y + 1, minf(w, size.x - maxf(x, 0.0)) - 1, minf(row_h, size.y - y) - 1)
			if r.size.x > 1 and r.size.y > 1:
				var shade := rng.randf_range(-0.06, 0.06) - (y / maxf(size.y, 1.0)) * 0.12
				var col := Palette.STONE.lightened(shade) if shade > 0 else Palette.STONE.darkened(-shade)
				draw_rect(r, col)
				draw_line(r.position, r.position + Vector2(r.size.x, 0), col.lightened(0.12), 1.0)
				if rng.randf() < 0.12:
					var cx := r.position.x + rng.randf() * r.size.x
					draw_line(Vector2(cx, r.position.y), Vector2(cx + rng.randf_range(-3, 3), r.end.y), Palette.STONE_DARK, 1.0)
			x += w
		y += row_h
		row += 1
	# Worn top edge with bone dust.
	draw_rect(Rect2(0, 0, size.x, 2), Palette.STONE_LIGHT)
	for i in int(size.x / 10.0):
		if rng.randf() < 0.4:
			draw_rect(Rect2(rng.randf() * size.x, 0, rng.randi_range(1, 3), 1), Palette.DUST)
