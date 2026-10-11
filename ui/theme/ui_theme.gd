class_name UITheme
extends RefCounted
## One theme for every menu so they all share the game's look (see docs/ART_BIBLE.md).
## Flat bone-on-black buttons; the focused button gets a gold frame. Fully keyboard
## and gamepad navigable: focus and hover look identical.

static var _theme: Theme


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

	t.set_stylebox(&"panel", &"PanelContainer", box(Color(Palette.NIGHT, 0.88), Palette.STONE, 1, Vector2(8, 5)))
	return t
