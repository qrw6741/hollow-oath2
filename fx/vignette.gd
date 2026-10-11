class_name Vignette
extends CanvasLayer
## Screen-space darkened corners plus a faint cool tint, drawn above the world and
## below the HUD. Cheap (one gradient texture) and purely cosmetic.

@export var strength := 0.62


func _ready() -> void:
	layer = 8
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.01, 0.04, 0.0), Color(0.02, 0.01, 0.04, 0.0), Color(0.02, 0.01, 0.04, strength)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 72
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
