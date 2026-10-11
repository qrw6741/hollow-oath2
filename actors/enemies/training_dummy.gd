extends Node2D
## Straw penitent effigy for practising combos. Cannot die; shows damage
## numbers and a running total of the last combo string.
## TEMPORARY ART (procedural).


var _shake := 0.0
var _combo_total := 0.0
var _combo_timer := 0.0
var _flash := 0


func _ready() -> void:
	add_to_group(&"dummies")


func receive_hit(hit: HitData) -> int:
	_shake = 1.0
	_flash = 5
	_combo_total += hit.damage
	_combo_timer = 1.2
	GameFeel.damage_number(global_position + Vector2(0, -40), hit.damage, hit.critical)
	GameFeel.spark(global_position + Vector2(0, -18), Palette.DUST, 8, 1 if hit.knockback.x >= 0.0 else -1)
	return HitData.Result.HIT


func _physics_process(delta: float) -> void:
	_shake = maxf(0.0, _shake - delta * 4.0)
	if _flash > 0:
		_flash -= 1
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_total = 0.0
	queue_redraw()


func _draw() -> void:
	var off := sin(_shake * 40.0) * _shake * 2.0
	var c := func(col: Color) -> Color: return col.lerp(Color.WHITE, 0.8 if _flash > 0 else 0.0)
	draw_line(Vector2(0, 0), Vector2(0, -30), c.call(Palette.WOOD), 3.0)
	draw_line(Vector2(-10 + off, -24), Vector2(10 + off, -24), c.call(Palette.WOOD_LIGHT), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6 + off, -28), Vector2(6 + off, -28), Vector2(5 + off, -10), Vector2(-5 + off, -10)]), c.call(Color("8a7547")))
	draw_circle(Vector2(off, -32), 4.5, c.call(Color("9c8752")))
	draw_line(Vector2(-3 + off, -10), Vector2(3 + off, -24), c.call(Palette.CRIMSON), 1.0)
	if _combo_total > 0.0:
		var font := ThemeDB.fallback_font
		var txt := "%d" % roundi(_combo_total)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_string(font, Vector2(-w * 0.5, -48), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Palette.BONE, minf(1.0, _combo_timer * 2.0)))
