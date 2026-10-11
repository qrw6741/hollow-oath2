class_name EmberRemnant
extends Area2D
## The glowing stain left where the player lost their embers. Walk into it to recover them.
## TEMPORARY ART (procedural).

var amount := 0
var _t := 0.0
var _taken := false
## Frames before it can be collected. A freshly spawned stain can overlap the dying player's
## body for a moment (respawn teleport not yet applied), which must not count as a pickup.
var _arm_frames := 30


func _ready() -> void:
	add_to_group(&"ember_remnant")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 14.0
	cs.shape = r
	cs.position = Vector2(0, -10)
	add_child(cs)
	var l := PointLight2D.new()
	l.texture = LightTex.radial()
	l.texture_scale = 0.9
	l.color = Palette.EMBER
	l.energy = 0.7
	l.position = Vector2(0, -10)
	add_child(l)
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _arm_frames > 0:
		_arm_frames -= 1
		return
	for b in get_overlapping_bodies():
		if b is Player and not b.is_dead():
			_collect()
			return


func _collect() -> void:
	if _taken:
		return
	_taken = true
	var got := GameState.recover_drop()
	Events.banner_requested.emit("EMBERS RECOVERED  +%d" % got)
	GameFeel.spark(global_position + Vector2(0, -10), Palette.EMBER, 24)
	queue_free()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 1.5
	draw_circle(Vector2(0, -10 + bob), 9.0, Color(Palette.EMBER, 0.12))
	draw_circle(Vector2(0, -10 + bob), 5.0, Color(Palette.EMBER, 0.28))
	# A little stack of embers and a rising flicker.
	for i in 5:
		var a := _t * 1.5 + i * 1.256
		draw_circle(Vector2(cos(a) * 4.0, -10 + bob + sin(a * 1.3) * 3.0), 1.1, Palette.GOLD_BRIGHT)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -2), Vector2(0, -16 + bob), Vector2(3, -2)]), Color(Palette.EMBER, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(-1.5, -3), Vector2(0, -11 + bob), Vector2(1.5, -3)]), Palette.GOLD_BRIGHT)
