class_name Mist
extends CanvasLayer
## Screen-space atmosphere for a level: two slow drifting fog banks and a few soft light shafts.
## Added by Level._ready. Colour follows the level's CanvasModulate so every region keeps its mood.
## Cosmetic only; no collision, no per-frame allocation (animation is just moving two textures).

var _fog: Array[TextureRect] = []
var _shafts: Array[Polygon2D] = []
var _t := 0.0


func _ready() -> void:
	layer = 2
	visible = not Settings.classic_gfx
	var tint := Color(0.55, 0.55, 0.65)
	var lv := get_parent()
	if lv:
		var cm := lv.get_node_or_null("Light") as CanvasModulate
		if cm:
			tint = cm.color.lerp(Color.WHITE, 0.35)
	var base := Color(tint.r, tint.g, tint.b, 1.0)
	for i in 2:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(base, 0.0), Color(base, 0.13 if i == 0 else 0.09), Color(base, 0.0)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0.5, 0.0)
		gt.fill_to = Vector2(0.5, 1.0)
		gt.width = 4
		gt.height = 64
		var r := TextureRect.new()
		r.texture = gt
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_left = 0.0
		r.anchor_right = 1.0
		r.anchor_top = 0.62 if i == 0 else 0.45
		r.anchor_bottom = 1.02 if i == 0 else 0.78
		add_child(r)
		_fog.append(r)
	# Light shafts: long pale slanted wedges from the top of the screen, very faint.
	for i in 3:
		var p := Polygon2D.new()
		var x0 := 160.0 + i * 330.0
		p.polygon = PackedVector2Array([Vector2(x0, -20), Vector2(x0 + 70, -20), Vector2(x0 - 150, 760), Vector2(x0 - 330, 760)])
		var warm := Color(1.0, 0.9, 0.7, 0.03 - i * 0.006)
		p.color = warm
		add_child(p)
		_shafts.append(p)


func _process(dt: float) -> void:
	visible = not Settings.classic_gfx
	if not visible:
		return
	_t += dt
	for i in _fog.size():
		var r := _fog[i]
		r.modulate.a = 0.75 + 0.25 * sin(_t * (0.25 + i * 0.13) + i * 2.0)
		r.position.x = sin(_t * (0.12 + i * 0.07)) * 26.0
		r.offset_left = -60.0
		r.offset_right = 60.0
	for i in _shafts.size():
		_shafts[i].modulate.a = 0.6 + 0.4 * sin(_t * 0.2 + i * 1.7)
