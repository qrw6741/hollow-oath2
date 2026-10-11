class_name ShiningLight
extends Area2D
## The light that opens after the prologue's last boss. Walking into it lifts the player
## into it and carries them, through a white fade, to the true Vaelmoor.
## Origin = floor point under the light. TEMPORARY ART (procedural rays and glow).

@export_file("*.tscn") var target_level := ""
@export var target_entry: StringName = &"arrival"

var _t := 0.0
var _grow := 0.0
var _taken := false
var _arm := 40
var _glow: PointLight2D


func _ready() -> void:
	add_to_group(&"shining_light")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 90)
	cs.shape = r
	cs.position = Vector2(0, -45)
	add_child(cs)
	_glow = PointLight2D.new()
	_glow.texture = LightTex.radial()
	_glow.texture_scale = 3.5
	_glow.color = Color(1.0, 0.95, 0.8)
	_glow.energy = 0.0
	_glow.position = Vector2(0, -50)
	add_child(_glow)
	z_index = 7
	Audio.sfx_at(&"levelup", global_position, 0.0, 0.7)


func _physics_process(delta: float) -> void:
	_t += delta
	_grow = minf(1.0, _grow + delta * 0.6)
	_glow.energy = 1.6 * _grow + 0.2 * sin(_t * 3.0)
	queue_redraw()
	if _taken or _arm > 0:
		_arm -= 1
		return
	for b in get_overlapping_bodies():
		if b is Player and not b.is_dead():
			ascend(b)
			return


## Lifts the player into the light and asks Main to carry them to the true world.
func ascend(p: Player) -> void:
	if _taken:
		return
	_taken = true
	p.rest()                         # holds the player still (and restores them)
	p.velocity = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(p, "global_position", global_position + Vector2(0, -24), 1.4).set_trans(Tween.TRANS_SINE)
	Audio.sfx(&"heal", 2.0, 0.7)
	Audio.music(&"", 1.0)
	Audio.sting(&"victory")
	GameFeel.shake(2.0, 1.2)
	Events.teleport_requested.emit(target_level, target_entry)


func _draw() -> void:
	var g := _grow
	var h := 140.0 * g
	# Rays fanning up from the floor.
	for i in 9:
		var a := -PI / 2.0 + (i - 4) * 0.13 + sin(_t * 0.7 + i) * 0.03
		var tip := Vector2.from_angle(a) * (h + 30.0 * sin(_t * 2.0 + i))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), tip + Vector2(-6, 0), tip + Vector2(6, 0), Vector2(3, 0)]), Color(1.0, 0.95, 0.75, 0.10 * g))
	# Core pillar.
	for k in 4:
		var w := (18.0 - k * 4.0) * g
		draw_rect(Rect2(-w / 2.0, -h, w, h), Color(1.0, 0.97, 0.85, (0.12 + k * 0.12) * g))
	draw_circle(Vector2(0, -50), 22.0 * g, Color(1, 0.98, 0.9, 0.25 * g))
	# Motes rising.
	for i in 14:
		var y := -fmod(_t * 40.0 + i * 23.0, h + 1.0)
		var x := sin(_t * 1.3 + i * 2.1) * 12.0
		draw_circle(Vector2(x, y), 1.2, Color(1, 0.95, 0.75, 0.8 * g))
