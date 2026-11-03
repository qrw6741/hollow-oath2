@tool
class_name CastleProp
extends Node2D
## Scenery for the castle in the Lower Hell: braziers, knight statues, carpets, a throne, weapon racks,
## hanging cages, barrels. Purely decorative (no collision). Origin = feet. TEMPORARY ART (drawn in code).

enum Kind { BRAZIER, STATUE, CARPET, THRONE, RACK, CAGE, BARRELS, GARGOYLE }

@export var kind: Kind = Kind.BRAZIER:
	set(v): kind = v; queue_redraw()
## Width, for carpets.
@export var span := 240.0:
	set(v): span = v; queue_redraw()
@export var glow := Color(1.0, 0.55, 0.2)

var _t := 0.0
var _light: PointLight2D


func _ready() -> void:
	z_index = -4 if kind == Kind.CARPET else -3
	if Engine.is_editor_hint():
		return
	if kind == Kind.BRAZIER or kind == Kind.CAGE:
		_light = PointLight2D.new()
		_light.texture = LightTex.radial()
		_light.texture_scale = 1.9
		_light.color = glow
		_light.energy = 0.5
		_light.position = Vector2(0, -50) if kind == Kind.BRAZIER else Vector2(0, -150)
		add_child(_light)
	_t = float(int(global_position.x) % 97) * 0.13


func _process(delta: float) -> void:
	_t += delta
	if kind == Kind.BRAZIER or kind == Kind.CAGE or kind == Kind.GARGOYLE:
		if _light:
			_light.energy = 0.42 + 0.14 * sin(_t * 9.0) + 0.06 * sin(_t * 23.0)
		if Near.player(self): queue_redraw()


func _draw() -> void:
	var stone := Color("4a3c44")
	var dark := Color("2a2030")
	var iron := Color("3a363c")
	match kind:
		Kind.BRAZIER:
			draw_rect(Rect2(-14, -6, 28, 6), dark)
			draw_rect(Rect2(-3, -44, 6, 40), iron)
			draw_colored_polygon(PackedVector2Array([Vector2(-16, -52), Vector2(16, -52), Vector2(10, -40), Vector2(-10, -40)]), iron)
			draw_rect(Rect2(-17, -54, 34, 4), iron.lightened(0.15))
			var f := 0.7 + 0.3 * sin(_t * 9.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-11, -54), Vector2(-3, -54 - 26 * f), Vector2(2, -54 - 14 * f), Vector2(6, -54 - 30 * f), Vector2(11, -54)]), Color(1.0, 0.45, 0.1, 0.92))
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -54), Vector2(0, -54 - 17 * f), Vector2(6, -54)]), Color(1.0, 0.85, 0.4, 0.95))
			draw_circle(Vector2(0, -64), 44.0, Color(glow, 0.06 * f))
		Kind.STATUE:
			draw_rect(Rect2(-22, -16, 44, 16), dark)
			draw_rect(Rect2(-18, -20, 36, 6), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -20), Vector2(14, -20), Vector2(12, -78), Vector2(-12, -78)]), stone)
			draw_rect(Rect2(-18, -84, 36, 12), stone.lightened(0.05))
			draw_circle(Vector2(0, -96), 11.0, stone.lightened(0.04))
			draw_rect(Rect2(-8, -99, 16, 4), dark)
			draw_rect(Rect2(-1, -99, 2, 14), dark)
			draw_line(Vector2(-22, -90), Vector2(-22, -8), stone.lightened(0.18), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-26, -90), Vector2(-18, -90), Vector2(-22, -104)]), stone.lightened(0.18))
			draw_line(Vector2(22, -78), Vector2(30, -50), stone, 5.0)
			draw_arc(Vector2(0, -96), 11.0, PI, TAU, 8, stone.lightened(0.2), 2.0)
		Kind.CARPET:
			draw_rect(Rect2(0, -3, span, 3), Color("5a1018"))
			draw_rect(Rect2(0, -3, span, 1), Color("a2303c"))
			draw_rect(Rect2(0, -1, span, 1), Color("2a080c"))
			var x := 8.0
			while x < span - 8.0:
				draw_rect(Rect2(x, -2, 6, 1), Color("c89a50"))
				x += 22.0
		Kind.THRONE:
			draw_rect(Rect2(-34, -10, 68, 10), dark)
			draw_rect(Rect2(-28, -18, 56, 10), stone)
			draw_rect(Rect2(-24, -52, 48, 36), Color("3a1a24"))
			draw_colored_polygon(PackedVector2Array([Vector2(-28, -52), Vector2(28, -52), Vector2(28, -140), Vector2(14, -170), Vector2(0, -150), Vector2(-14, -170), Vector2(-28, -140)]), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(-18, -56), Vector2(18, -56), Vector2(18, -130), Vector2(0, -144), Vector2(-18, -130)]), Color("2e0e16"))
			draw_rect(Rect2(-34, -62, 10, 50), stone.darkened(0.1))
			draw_rect(Rect2(24, -62, 10, 50), stone.darkened(0.1))
			draw_circle(Vector2(0, -122), 5.0, Color(0.85, 0.6, 0.3, 0.8))
		Kind.RACK:
			draw_rect(Rect2(-34, -8, 68, 8), Color("3a2a1e"))
			draw_rect(Rect2(-32, -58, 5, 54), Color("4a3828"))
			draw_rect(Rect2(27, -58, 5, 54), Color("4a3828"))
			draw_rect(Rect2(-32, -58, 64, 5), Color("4a3828"))
			draw_rect(Rect2(-32, -32, 64, 4), Color("4a3828"))
			for i in 4:
				var x2 := -22.0 + i * 14.0
				draw_line(Vector2(x2, -56), Vector2(x2 + 2, -12), Color("8c8c94"), 2.0)
				draw_rect(Rect2(x2 - 3, -34, 8, 3), Color("5a4630"))
		Kind.CAGE:
			draw_line(Vector2(0, -400), Vector2(0, -186), iron, 2.0)
			draw_arc(Vector2(0, -170), 22.0, PI, TAU, 10, iron, 3.0)
			draw_rect(Rect2(-22, -170, 44, 4), iron)
			draw_rect(Rect2(-22, -130, 44, 4), iron)
			for i in 5:
				draw_line(Vector2(-18 + i * 9, -170), Vector2(-18 + i * 9, -130), iron, 2.0)
			draw_circle(Vector2(0, -150), 3.0, Color(glow, 0.5 + 0.2 * sin(_t * 7.0)))
		Kind.BARRELS:
			for bx in [-16.0, 14.0]:
				draw_rect(Rect2(bx - 11, -34, 22, 34), Color("4a3422"))
				draw_rect(Rect2(bx - 12, -26, 24, 3), iron)
				draw_rect(Rect2(bx - 12, -10, 24, 3), iron)
				draw_line(Vector2(bx - 5, -33), Vector2(bx - 5, -1), Color("5e4630"), 1.0)
			draw_rect(Rect2(-9, -62, 20, 28), Color("523a26"))
			draw_rect(Rect2(-10, -50, 22, 3), iron)
		Kind.GARGOYLE:
			draw_rect(Rect2(-20, -8, 40, 8), dark)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -8), Vector2(14, -8), Vector2(10, -40), Vector2(-10, -40)]), stone)
			draw_circle(Vector2(0, -48), 10.0, stone.lightened(0.04))
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -54), Vector2(-16, -70), Vector2(-3, -58)]), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(8, -54), Vector2(16, -70), Vector2(3, -58)]), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -38), Vector2(-40, -62), Vector2(-26, -30)]), stone.darkened(0.08))
			draw_colored_polygon(PackedVector2Array([Vector2(14, -38), Vector2(40, -62), Vector2(26, -30)]), stone.darkened(0.08))
			var e := Color(1.0, 0.3, 0.1, 0.7 + 0.3 * sin(_t * 3.0))
			draw_circle(Vector2(-4, -49), 1.8, e)
			draw_circle(Vector2(4, -49), 1.8, e)
