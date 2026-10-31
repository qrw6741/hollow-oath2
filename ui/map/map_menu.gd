class_name MapMenu
extends CanvasLayer
## The world map. Shows every level you have set foot in, laid out where they connect,
## but only the parts you have explored (64 px cells revealed as you walk).
## Marks: you (pulsing gold), Oath Candles (lit = rested at), bosses (red; crossed out when
## defeated), doors and passages. Pan with movement, zoom with Parry / Heal (L1 / R1) or
## the mouse wheel, drag with the mouse. Opens with Map (M / touchpad / L3) or from the
## pause menu; pauses the game.

const ZOOM_MIN := 0.04
const ZOOM_MAX := 0.5
const PAN_SPEED := 900.0   # screen px per second at any zoom

var is_open := false
var center := Vector2.ZERO      # world-map units shown at screen centre
var zoom := 0.14                # screen px per map unit
var _panel: ColorRect
var _canvas: Control
var _title: Label
var _area: Label
var _was_paused := false
var _prev_modal := false
var _t := 0.0
var _levels: Array = []
var _rects := {}                # level path -> {"blocks": [...], "water": [...], "cells": [...]} (map units)
var _drag := false


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false
	Events.map_requested.connect(open)


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0.035, 0.03, 0.045, 0.97)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UITheme.get_theme()
	add_child(_panel)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.clip_contents = true
	_canvas.draw.connect(_draw_map)
	_canvas.gui_input.connect(_on_canvas_input)
	_panel.add_child(_canvas)
	_title = Label.new()
	_title.text = "MAP"
	_title.position = Vector2(14, 8)
	UITheme.title(_title, 14)
	_panel.add_child(_title)
	_area = Label.new()
	_area.position = Vector2(14, 26)
	_area.add_theme_color_override(&"font_color", Palette.BONE_DIM)
	_panel.add_child(_area)
	var hint := HintBar.new()
	hint.spec = "map:close,dpad|Arrows:move,parry:zoom out,heal:zoom in"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -16
	hint.offset_bottom = -3
	_panel.add_child(hint)


# ------------------------------------------------------------------ open / close

func _unhandled_input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed(&"map") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"map") and GameState.in_game and not GameState.ui_modal and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	_was_paused = get_tree().paused
	_prev_modal = GameState.ui_modal
	get_tree().paused = true
	GameState.ui_modal = true
	GameFeel.reset()
	_rebuild()
	center = player_map_position()
	_panel.visible = true
	Audio.sfx(&"ui_select")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	get_tree().paused = _was_paused
	GameState.ui_modal = _prev_modal
	Audio.sfx(&"ui_back")
	Events.map_closed.emit()


## Player position in map units (the current level's origin + local position).
func player_map_position() -> Vector2:
	var lv := get_tree().get_first_node_in_group(&"level") as Level
	if lv and is_instance_valid(lv.player):
		return lv.map_origin + lv.player.global_position
	return center


# ------------------------------------------------------------------ data

## Precomputes what to draw: level geometry clipped to explored cells (map units).
func _rebuild() -> void:
	_levels = WorldMap.all()
	_rects.clear()
	for d in _levels:
		var seen: Dictionary = GameState.explored.get(d.level_id, {})
		var o: Vector2 = d.origin
		var cells: Array[Rect2] = []
		var blocks: Array[Rect2] = []
		var water: Array[Rect2] = []
		var planks: Array[Rect2] = []
		for k in seen:
			var c := WorldMap.key_cell(int(k))
			var cr := Rect2(Vector2(c.x, c.y) * WorldMap.CELL, Vector2.ONE * WorldMap.CELL)
			if not (d.bounds as Rect2).intersects(cr):
				continue
			cells.append(Rect2(cr.position + o, cr.size))
			for list_pair in [[d.blocks, blocks], [d.water, water], [d.planks, planks]]:
				for r: Rect2 in list_pair[0]:
					if r.intersects(cr):
						var i := r.intersection(cr)
						list_pair[1].append(Rect2(i.position + o, i.size))
		_rects[d.path] = {"cells": cells, "blocks": blocks, "water": water, "planks": planks, "seen": seen}


# ------------------------------------------------------------------ controls

func _process(delta: float) -> void:
	if not is_open:
		return
	_t += delta
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if v != Vector2.ZERO:
		center += v * PAN_SPEED * delta / zoom
	if Input.is_action_pressed(&"heal"):
		zoom = clampf(zoom * (1.0 + 1.6 * delta), ZOOM_MIN, ZOOM_MAX)
	if Input.is_action_pressed(&"parry"):
		zoom = clampf(zoom / (1.0 + 1.6 * delta), ZOOM_MIN, ZOOM_MAX)
	_area.text = _area_line() + "\n" + Progress.text()
	_canvas.queue_redraw()


func _on_canvas_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom = clampf(zoom * 1.15, ZOOM_MIN, ZOOM_MAX)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom = clampf(zoom / 1.15, ZOOM_MIN, ZOOM_MAX)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_drag = e.pressed
	elif e is InputEventMouseMotion and _drag:
		center -= e.relative / zoom


func _area_line() -> String:
	var lv := get_tree().get_first_node_in_group(&"level") as Level
	if lv == null:
		return ""
	for d in _levels:
		if d.level_id == String(lv.level_id):
			return "%s  -  %d%% explored" % [d.name, roundi(WorldMap.explored_fraction(d) * 100.0)]
	return lv.display_name


# ------------------------------------------------------------------ drawing

func to_screen(p: Vector2) -> Vector2:
	return (p - center) * zoom + _canvas.size / 2.0


func _rect(r: Rect2) -> Rect2:
	return Rect2(to_screen(r.position), r.size * zoom)


func _draw_map() -> void:
	var c := _canvas
	# Faint grid for orientation.
	var step := 512.0 * zoom
	if step > 6.0:
		var off := Vector2(fposmod(-center.x * zoom + c.size.x / 2.0, step), fposmod(-center.y * zoom + c.size.y / 2.0, step))
		for x in range(int(c.size.x / step) + 2):
			c.draw_line(Vector2(off.x + x * step, 0), Vector2(off.x + x * step, c.size.y), Color(1, 1, 1, 0.025), 1.0)
		for y in range(int(c.size.y / step) + 2):
			c.draw_line(Vector2(0, off.y + y * step), Vector2(c.size.x, off.y + y * step), Color(1, 1, 1, 0.025), 1.0)
	var any := false
	for d in _levels:
		var r: Dictionary = _rects.get(d.path, {})
		if r.is_empty() or (r.cells as Array).is_empty():
			continue
		any = true
		for cr: Rect2 in r.cells:
			c.draw_rect(_rect(cr).grow(0.5), Color(0.105, 0.098, 0.115))
		for wr: Rect2 in r.water:
			c.draw_rect(_rect(wr), Color(0.25, 0.45, 0.48, 0.55))
		for br: Rect2 in r.blocks:
			c.draw_rect(_rect(br).grow(0.3), Color(0.42, 0.40, 0.45, 1.0))
		for pr: Rect2 in r.planks:
			var s := _rect(pr)
			c.draw_rect(Rect2(s.position, Vector2(s.size.x, maxf(1.0, s.size.y))), Color(0.55, 0.42, 0.3, 1.0))
		_draw_markers(d, r.seen)
		# Level name at the top-left of its explored area.
		var top := Vector2(INF, INF)
		for cr: Rect2 in r.cells:
			top = Vector2(minf(top.x, cr.position.x), minf(top.y, cr.position.y))
		var np := to_screen(top) + Vector2(2, -4)
		if np.y < 14:
			np.y = 14
		c.draw_string(UITheme.title_font(), np, String(d.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Palette.BONE, 0.85))
	if not any:
		c.draw_string(UITheme.body_font(), c.size / 2.0 + Vector2(-60, 0), "Nothing explored yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.BONE_DIM)
	# The player.
	var pp := to_screen(player_map_position())
	var k := 0.5 + 0.5 * sin(_t * 5.0)
	c.draw_circle(pp, 6.0 + k * 3.0, Color(Palette.GOLD_BRIGHT, 0.18))
	c.draw_colored_polygon(PackedVector2Array([pp + Vector2(0, -5), pp + Vector2(4, 0), pp + Vector2(0, 5), pp + Vector2(-4, 0)]), Palette.GOLD_BRIGHT)


func _draw_markers(d: Dictionary, seen: Dictionary) -> void:
	var c := _canvas
	var o: Vector2 = d.origin
	for cd in d.candles:
		if not _seen_at(seen, cd.pos):
			continue
		var p := to_screen(o + cd.pos + Vector2(0, -6))
		var lit: bool = GameState.get_flag(StringName("candle_lit_" + String(cd.id)), false)
		c.draw_rect(Rect2(p + Vector2(-1.5, -1), Vector2(3, 6)), Palette.BONE_DIM)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -1), p + Vector2(0, -6), p + Vector2(2, -1)]), Palette.GOLD_BRIGHT if lit else Palette.STONE_LIGHT)
		if lit and zoom > 0.09:
			c.draw_string(UITheme.body_font(), p + Vector2(5, 3), cd.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(Palette.GOLD, 0.9))
	for b in d.bosses:
		if not _seen_at(seen, b.pos):
			continue
		var p := to_screen(o + b.pos + Vector2(0, -16))
		var dead: bool = GameState.get_flag(StringName("boss_defeated_" + String(b.id)), false)
		c.draw_circle(p, 4.5, Color(Palette.CRIMSON_BRIGHT, 0.35 if dead else 0.9))
		c.draw_circle(p + Vector2(-1.5, -0.5), 1.0, Palette.INK)
		c.draw_circle(p + Vector2(1.5, -0.5), 1.0, Palette.INK)
		if dead:
			c.draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), Palette.BONE, 1.5)
			c.draw_line(p + Vector2(5, -5), p + Vector2(-5, 5), Palette.BONE, 1.5)
	for e in d.exits:
		if not _seen_at(seen, e.pos):
			continue
		var p := to_screen(o + e.pos + Vector2(0, -8))
		var col := Palette.STONE_LIGHT if e.sealed else Palette.BONE
		if e.door:
			c.draw_rect(Rect2(p + Vector2(-2.5, -4), Vector2(5, 8)), col, false, 1.0)
		else:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -3), p + Vector2(3, 0), p + Vector2(-3, 3)]), col)


func _seen_at(seen: Dictionary, local_pos: Vector2) -> bool:
	var cx := int(floor(local_pos.x / WorldMap.CELL))
	var cy := int(floor((local_pos.y - 4.0) / WorldMap.CELL))
	return seen.has(WorldMap.cell_key(cx, cy))
