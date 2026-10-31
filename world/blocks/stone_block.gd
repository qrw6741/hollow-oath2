@tool
class_name StoneBlock
extends StaticBody2D
## Level-building primitive: a solid rectangle of masonry (or a one-way plank
## platform) whose collision and look are generated from [member size].
## Origin = top-left corner. Drop it into a level, set size, done.
## TEMPORARY ART: procedural masonry until the region tilesets exist (Milestone 5).

enum Style { MASONRY, RUBBLE, PLANKS, GRASS, CRYPT }

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
		_rebuild()

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
	_make_chunks()
	queue_redraw()


const CHUNK := 256.0   ## wide blocks are drawn in chunks so the renderer culls the ones off screen

var _chunks: Array[Node2D] = []


func _is_chunked() -> bool:
	return size.x > CHUNK * 1.5 and not (style == Style.PLANKS or one_way) and not Engine.is_editor_hint()


func _draw() -> void:
	if _is_chunked():
		return   # the chunks draw the art
	_paint(self, 0.0, size.x)


func _make_chunks() -> void:
	for c in _chunks:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_chunks.clear()
	if not _is_chunked():
		return
	var x := 0.0
	while x < size.x:
		var ch := StoneChunk.new()
		ch.block = self
		ch.x0 = x
		ch.x1 = minf(x + CHUNK, size.x)
		add_child(ch)
		_chunks.append(ch)
		x += CHUNK


## Paints the slice [x0, x1] of this block onto `cv` (the block itself, or one of its chunks).
## A chunk uses its own random sequence, so a block looks the same every run.
func _paint(cv: CanvasItem, x0: float, x1: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + int(size.x) * 31 + int(size.y) + int(x0) * 104729
	if style == Style.PLANKS or one_way:
		cv.draw_rect(Rect2(0, 0, size.x, 6), Palette.WOOD)
		cv.draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), Palette.WOOD_LIGHT, 1.0)
		var px := 0.0
		while px < size.x:
			cv.draw_line(Vector2(px, 1), Vector2(px, 6), Palette.INK, 1.0)
			px += rng.randi_range(14, 24)
		for sx in [4.0, size.x - 6.0]:
			cv.draw_line(Vector2(sx, 6), Vector2(sx + 1, 14), Palette.WOOD, 2.0)
		return
	var w_all := x1 - x0
	if style == Style.GRASS:
		_paint_grass(cv, rng, x0, x1)
		return
	if style == Style.CRYPT:
		_paint_crypt(cv, rng, x0, x1)
		return
	cv.draw_rect(Rect2(x0, 0, w_all, size.y), Palette.STONE_DARK)
	var row_h := 8.0
	var y := 0.0
	var row := 0
	while y < size.y:
		var x := x0 - float((row % 2) * 8)
		while x < x1:
			var w := float(rng.randi_range(12, 20)) if style == Style.MASONRY else float(rng.randi_range(6, 14))
			var bx := maxf(x, x0)
			var r := Rect2(bx + 1, y + 1, minf(minf(w, x1 - bx), size.x - bx) - 1, minf(row_h, size.y - y) - 1)
			if r.size.x > 1 and r.size.y > 1:
				var shade := rng.randf_range(-0.06, 0.06) - (y / maxf(size.y, 1.0)) * 0.12
				var col := Palette.STONE.lightened(shade) if shade > 0 else Palette.STONE.darkened(-shade)
				cv.draw_rect(r, col)
				cv.draw_line(r.position, r.position + Vector2(r.size.x, 0), col.lightened(0.12), 1.0)
				if rng.randf() < 0.12:
					var cx := r.position.x + rng.randf() * r.size.x
					cv.draw_line(Vector2(cx, r.position.y), Vector2(cx + rng.randf_range(-3, 3), r.end.y), Palette.STONE_DARK, 1.0)
			x += w
		y += row_h
		row += 1
	# Worn top edge with bone dust.
	cv.draw_rect(Rect2(x0, 0, w_all, 2), Palette.STONE_LIGHT)
	for i in int(w_all / 10.0):
		if rng.randf() < 0.4:
			cv.draw_rect(Rect2(x0 + rng.randf() * w_all, 0, rng.randi_range(1, 3), 1), Palette.DUST)


## Daylight earth: soil with stones and a living green top (only in the true Vaelmoor).
func _paint_grass(cv: CanvasItem, rng: RandomNumberGenerator, x0: float, x1: float) -> void:
	var w_all := x1 - x0
	cv.draw_rect(Rect2(x0, 0, w_all, size.y), Color("5a4532"))
	for i in int(w_all * size.y / 260.0):
		var p := Vector2(x0 + rng.randf() * w_all, 8.0 + rng.randf() * maxf(0.0, size.y - 8.0))
		cv.draw_rect(Rect2(p, Vector2(rng.randi_range(2, 5), rng.randi_range(1, 3))), Color("6e5640") if rng.randf() < 0.6 else Color("463526"))
	cv.draw_rect(Rect2(x0, 0, w_all, 5), Color("5f8a3e"))
	cv.draw_rect(Rect2(x0, 0, w_all, 2), Color("86b356"))
	var x := x0
	while x < x1:
		var h := rng.randf_range(2.0, 6.0)
		cv.draw_line(Vector2(x, 1), Vector2(x + rng.randf_range(-1.5, 1.5), -h), Color("7aa84c") if rng.randf() < 0.7 else Color("a7c96a"), 1.0)
		x += rng.randf_range(2.0, 5.0)


## Underground earth: cold dark soil, packed stone, a thin crust of dim moss and bone chips.
func _paint_crypt(cv: CanvasItem, rng: RandomNumberGenerator, x0: float, x1: float) -> void:
	var w_all := x1 - x0
	cv.draw_rect(Rect2(x0, 0, w_all, size.y), Color("2c2a31"))
	for i in int(w_all * size.y / 220.0):
		var p := Vector2(x0 + rng.randf() * w_all, 6.0 + rng.randf() * maxf(0.0, size.y - 6.0))
		var c := Color("3a3740") if rng.randf() < 0.55 else Color("201e25")
		cv.draw_rect(Rect2(p, Vector2(rng.randi_range(2, 6), rng.randi_range(1, 3))), c)
	for i in int(w_all / 90.0) + 1:
		var bp := Vector2(x0 + rng.randf() * w_all, 8.0 + rng.randf() * maxf(0.0, size.y - 10.0))
		cv.draw_rect(Rect2(bp, Vector2(rng.randi_range(3, 6), 1)), Color("8d867e", 0.55))
	cv.draw_rect(Rect2(x0, 0, w_all, 4), Color("3d4a44"))
	cv.draw_rect(Rect2(x0, 0, w_all, 1), Color("5d7068"))
	var x := x0
	while x < x1:
		var h := rng.randf_range(1.0, 4.0)
		cv.draw_line(Vector2(x, 1), Vector2(x + rng.randf_range(-1.0, 1.0), -h), Color("4a5d54") if rng.randf() < 0.75 else Color("788a7c"), 1.0)
		x += rng.randf_range(3.0, 8.0)
