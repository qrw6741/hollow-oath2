class_name UITheme
extends RefCounted
## One theme for every menu so they all share the game's look (see docs/ART_BIBLE.md).
## Flat bone-on-black buttons; the focused button gets a gold frame. Fully keyboard
## and gamepad navigable: focus and hover look identical.

static var _theme: Theme
static var _body: Font
static var _title: Font


## Lora (SIL OFL) for reading text; slightly heavier than regular so small sizes stay legible.
static func body_font() -> Font:
	if _body == null:
		var base := load("res://assets/fonts/Lora-Variable.ttf") as FontFile
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_opentype = {2003265652: 520.0}   # OpenType tag "wght"
		_body = fv
	return _body


## GFS Baskerville (SIL OFL) for titles and menu choices, with a little letter-spacing.
static func title_font() -> Font:
	if _title == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/GFSBaskerville.otf") as FontFile
		fv.spacing_glyph = 1
		_title = fv
	return _title


## Styles a Label as a heading.
static func title(l: Label, size := 12, color := Color(0.85, 0.80, 0.70)) -> Label:
	l.add_theme_font_override(&"font", title_font())
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	return l


## Adds gold corner ornaments to a PanelContainer / Control by drawing on it (a child node
## would be laid out as panel content instead of overlaying the border).
static func frame(c: Control) -> void:
	c.draw.connect(func(): draw_corners(c, Rect2(Vector2.ZERO, c.size)))
	c.resized.connect(c.queue_redraw)


## A thin gold rule with a centre diamond, used under headings.
static func rule(width := 160.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 7)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := width / 2.0
		c.draw_line(Vector2(0, 3.5), Vector2(m - 7, 3.5), Color(Palette.GOLD, 0.7), 1.0)
		c.draw_line(Vector2(m + 7, 3.5), Vector2(width, 3.5), Color(Palette.GOLD, 0.7), 1.0)
		c.draw_colored_polygon(PackedVector2Array([Vector2(m - 4, 3.5), Vector2(m, 0), Vector2(m + 4, 3.5), Vector2(m, 7)]), Palette.GOLD_BRIGHT))
	return c


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func box(bg: Color, border: Color, border_width := 1, pad := Vector2(8, 3)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.content_margin_left = pad.x
	sb.content_margin_right = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_bottom = pad.y
	return sb


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 8

	var clear := Color(0, 0, 0, 0)
	var focus := box(Color(Palette.NIGHT, 0.92), Palette.GOLD)
	focus.border_width_left = 3
	focus.border_width_right = 3
	t.set_stylebox(&"normal", &"Button", box(clear, clear))
	t.set_stylebox(&"hover", &"Button", focus)
	t.set_stylebox(&"focus", &"Button", focus)
	t.set_stylebox(&"pressed", &"Button", box(Palette.STONE_DARK, Palette.GOLD_BRIGHT))
	t.set_stylebox(&"disabled", &"Button", box(clear, clear))
	t.set_font(&"font", &"Button", body_font())
	t.set_color(&"font_color", &"Button", Palette.BONE_DIM)
	t.set_color(&"font_hover_color", &"Button", Palette.GOLD_BRIGHT)
	t.set_color(&"font_focus_color", &"Button", Palette.GOLD_BRIGHT)
	t.set_color(&"font_pressed_color", &"Button", Palette.BONE)
	t.set_color(&"font_disabled_color", &"Button", Palette.STONE)
	t.set_font_size(&"font_size", &"Button", 8)

	t.set_color(&"font_color", &"Label", Palette.BONE)
	t.set_color(&"font_outline_color", &"Label", Palette.INK)
	t.set_constant(&"outline_size", &"Label", 2)
	t.set_font_size(&"font_size", &"Label", 8)

	t.set_stylebox(&"panel", &"PanelContainer", box(Color(0.05, 0.045, 0.065, 0.94), Color(Palette.STONE, 0.9), 1, Vector2(9, 7)))
	return t


## Same look as the shared theme, with less vertical padding (for long option lists).
static func compact(b: Button) -> void:
	var clear := Color(0, 0, 0, 0)
	var pad := Vector2(8, 1)
	var focus := box(Color(Palette.NIGHT, 0.92), Palette.GOLD, 1, pad)
	focus.border_width_left = 3
	focus.border_width_right = 3
	b.add_theme_stylebox_override(&"normal", box(clear, clear, 1, pad))
	b.add_theme_stylebox_override(&"hover", focus)
	b.add_theme_stylebox_override(&"focus", focus)
	b.add_theme_stylebox_override(&"disabled", box(clear, clear, 1, pad))
	b.add_theme_stylebox_override(&"pressed", box(Palette.STONE_DARK, Palette.GOLD_BRIGHT, 1, pad))


## Gold corner brackets and top/bottom centre diamonds inside [param rect].
static func draw_corners(ci: CanvasItem, rect: Rect2) -> void:
	var gold := Color(0.78, 0.62, 0.28, 0.9)
	var r := rect.grow(-2.0)
	var a := minf(9.0, minf(r.size.x, r.size.y) / 3.0)
	for c in [[r.position, 1, 1], [Vector2(r.end.x, r.position.y), -1, 1], [Vector2(r.position.x, r.end.y), 1, -1], [r.end, -1, -1]]:
		var p: Vector2 = c[0]
		ci.draw_line(p, p + Vector2(a * c[1], 0), gold, 1.0)
		ci.draw_line(p, p + Vector2(0, a * c[2]), gold, 1.0)
	for y in [r.position.y, r.end.y]:
		var cx := r.position.x + r.size.x / 2.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 3, y), Vector2(cx, y - 2.5), Vector2(cx + 3, y), Vector2(cx, y + 2.5)]), gold)


## Draws a dark panel with a stone border and gold corner ornaments onto any CanvasItem
## (used by menus that have no PanelContainer to hold the drawing).
static func draw_panel(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect, Color(0.05, 0.045, 0.065, 0.94))
	ci.draw_rect(rect, Color(Palette.STONE, 0.9), false, 1.0)
	draw_corners(ci, rect)
