class_name RisingHand
extends Node2D
## TEMPORARY ART: a colossal bandaged hand that rises out of the floor. [member rise] lifts the
## forearm (0 = buried, 1 = fully risen); [member open] uncurls the fingers and opens an eye in the
## palm (0 = fist, 1 = open palm). Black flames lick up from the fingertips while it is open.
## Origin = the floor point it climbs out of. Driven by DuoArena's intro; draws nothing when buried.

const WRAP := Color("cfc6ae")
const WRAP_D := Color("857d68")
const CLOTH := Color("1b1820")
const FLAME := Color("120a1c")
const FLAME_EDGE := Color("8a55e8")

var rise := 0.0
var open := 0.0
## 0 = gone, 1 = fully visible (used to fade the hand away after the intro).
var fade := 1.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	visible = rise > 0.01 and fade > 0.01
	if visible:
		queue_redraw()


func _draw() -> void:
	var a := fade
	var h := 78.0 * rise                       # how far the wrist is above the floor
	var wrist := Vector2(0, -h)
	# forearm: a tapering column of dark cloth with bandage bands
	var w0 := 22.0
	var w1 := 15.0
	draw_colored_polygon(PackedVector2Array([Vector2(-w0, 0), Vector2(-w1, -h), Vector2(w1, -h), Vector2(w0, 0)]), Color(CLOTH, a))
	var bands := int(h / 6.0)
	for i in bands:
		var y := -float(i) * 6.0 - 3.0
		var k := absf(y) / maxf(h, 1.0)
		var w := lerpf(w0, w1, k)
		draw_line(Vector2(-w, y + 2.0), Vector2(w, y - 2.0), Color(WRAP, a * 0.9), 1.4)
	draw_line(Vector2(-w0, 0), Vector2(-w1, -h), Color(WRAP_D, a), 1.2)
	draw_line(Vector2(w0, 0), Vector2(w1, -h), Color(WRAP_D, a), 1.2)
	# palm: a rounded slab above the wrist
	var pw := 21.0
	var ph := 38.0
	var palm_top := wrist.y - ph
	var palm := PackedVector2Array([wrist + Vector2(-w1, 0), wrist + Vector2(-pw, -ph * 0.45), wrist + Vector2(-pw + 2.0, -ph), wrist + Vector2(pw - 2.0, -ph), wrist + Vector2(pw, -ph * 0.45), wrist + Vector2(w1, 0)])
	draw_colored_polygon(palm, Color(CLOTH.lightened(0.08), a))
	for i in 5:
		var y := wrist.y - 4.0 - i * 7.5
		draw_line(Vector2(-pw + 1.0, y + 2.0), Vector2(pw - 1.0, y - 2.0), Color(WRAP, a * (0.35 + 0.5 * (1.0 - open))), 1.1)
	# the eye in the palm: shut as a slit, opens wide and glows as the palm opens
	var ec := Vector2(0, wrist.y - ph * 0.5)
	var lid := lerpf(0.5, 7.5, open)
	var pts := PackedVector2Array()
	for i in 13:
		var tt := float(i) / 12.0
		pts.append(ec + Vector2(lerpf(-10.0, 10.0, tt), -sin(tt * PI) * lid))
	for i in range(12, -1, -1):
		var tt := float(i) / 12.0
		pts.append(ec + Vector2(lerpf(-10.0, 10.0, tt), sin(tt * PI) * lid))
	draw_colored_polygon(pts, Color(0.88, 0.92, 1.0, a * (0.25 + 0.75 * open)))
	draw_circle(ec, 2.0 + 2.5 * open, Color(0.08, 0.04, 0.16, a))
	if open > 0.05:
		draw_circle(ec, 16.0 * open, Color(FLAME_EDGE, 0.16 * open * a))
	# fingers: five segments from the palm's top edge. Closed they curl down over the palm; open
	# they spread upward in a fan with a slight tremor.
	var base := [Vector2(-15, 0), Vector2(-7.5, 0), Vector2(0, 0), Vector2(7.5, 0), Vector2(15, 0)]
	var spread := [-0.95, -0.42, 0.0, 0.42, 0.95]
	var length := [26.0, 34.0, 38.0, 34.0, 25.0]
	for i in 5:
		var root: Vector2 = Vector2(base[i].x, palm_top + 4.0)
		var up := Vector2.UP.rotated(spread[i] * open * 0.9 + sin(_t * 3.0 + i) * 0.03 * open)
		var curl := 1.0 - open
		var mid: Vector2 = root + up * length[i] * 0.55 * (1.0 - 0.7 * curl) + Vector2(0, 8.0 * curl)
		var tip: Vector2 = mid + up.rotated(curl * 2.4 * signf(spread[i] if spread[i] != 0.0 else 1.0)) * length[i] * 0.5
		if curl > 0.5:
			tip = root + Vector2(spread[i] * 4.0, 14.0 * curl)
		draw_line(root, mid, Color(CLOTH, a), 6.5)
		draw_line(mid, tip, Color(CLOTH, a), 5.5)
		draw_line(root, mid, Color(WRAP, a * 0.8), 1.2)
		draw_line(mid, tip, Color(WRAP, a * 0.8), 1.2)
		if open > 0.3:
			_flame(tip, 9.0 + 3.0 * sin(_t * 6.0 + i), 2.4, a * open, float(i))
	# thumb on the outer side
	var troot := Vector2(-pw + 1.0, wrist.y - ph * 0.32)
	var tdir := Vector2(-1, -0.7).normalized().rotated(-0.25 * open)
	var ttip := troot + tdir * lerpf(10.0, 24.0, open)
	draw_line(troot, ttip, Color(CLOTH, a), 6.0)
	draw_line(troot, ttip, Color(WRAP, a * 0.8), 1.2)


func _flame(at: Vector2, h: float, w: float, alpha: float, seed_: float) -> void:
	var sway := sin(_t * 7.0 + seed_) * w * 0.8
	var tip := at + Vector2(sway, -h)
	var pts := PackedVector2Array([at + Vector2(-w, 0), at + Vector2(-w * 0.5 + sway * 0.3, -h * 0.55), tip, at + Vector2(w * 0.5 + sway * 0.3, -h * 0.55), at + Vector2(w, 0)])
	draw_colored_polygon(pts, Color(FLAME, 0.92 * alpha))
	draw_polyline(pts, Color(FLAME_EDGE, 0.55 * alpha), 1.0)
