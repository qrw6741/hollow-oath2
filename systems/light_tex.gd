class_name LightTex
extends RefCounted
## Shared procedural light textures (cached), so lights need no image assets.

static var _radial: GradientTexture2D


static func radial() -> GradientTexture2D:
	if _radial == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		_radial = GradientTexture2D.new()
		_radial.gradient = g
		_radial.width = 128
		_radial.height = 128
		_radial.fill = GradientTexture2D.FILL_RADIAL
		_radial.fill_from = Vector2(0.5, 0.5)
		_radial.fill_to = Vector2(1.0, 0.5)
	return _radial
