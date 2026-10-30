@tool
class_name Npc
extends Area2D
## A person you can talk to. Walk up, press Interact: a conversation (Dialogues, chosen by
## npc_id and how often you have talked), then - for a merchant - their shop.
## Origin = feet. TEMPORARY ART (procedural): Pedlar = hunched trader with a towering pack
## and a lantern; Figure = tall hooded stranger holding a candle.

enum Look { PEDLAR, FIGURE, SMITH, KEEPER, STEWARD, ARCHIVIST }

@export var npc_id: StringName = &"wenna"
@export var display_name := "Wenna"
@export var look := Look.PEDLAR:
	set(v): look = v; queue_redraw()
## Shop opened after the conversation ("" = just talk).
@export var shop_id: StringName = &""
## Smithing station opened after the conversation: &"forge" or &"vials" ("" = none).
@export var station: StringName = &""
@export_enum("Left:-1", "Right:1") var start_facing := -1
## When they are about: 0 always, 1 by day only, 2 by night only.
@export_enum("Always:0", "Day only:1", "Night only:2") var when := 0

var facing := -1
var talking := false
var _player_inside: Player
var _t := 0.0
var _cooldown := 0


func _ready() -> void:
	facing = start_facing
	_t = randf() * 10.0
	if Engine.is_editor_hint():
		return
	add_to_group(&"npcs")
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(54, 40)
	cs.shape = r
	cs.position = Vector2(0, -20)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	Events.dialogue_closed.connect(_on_dialogue_closed)
	Events.daynight_changed.connect(func(_n): _apply_time())
	_apply_time()


## Hides a day- or night-only person (and stops them being talked to) out of their hours.
func _apply_time() -> void:
	var here := when == 0 or (when == 2) == DayNight.is_night()
	visible = here
	if when == 2:
		modulate = Color(0.78, 0.84, 1.0)
	set_deferred(&"monitoring", here)
	if not here and _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func is_about() -> bool:
	return when == 0 or (when == 2) == DayNight.is_night()


func _on_enter(b: Node) -> void:
	if b is Player:
		_player_inside = b
		Events.interact_prompt_shown.emit("Talk to %s" % Dialogues.display_name(npc_id, display_name))


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	if _cooldown > 0:
		_cooldown -= 1
	queue_redraw()
	if Engine.is_editor_hint():
		return
	if _player_inside:
		var dx := _player_inside.global_position.x - global_position.x
		if absf(dx) > 6.0:
			facing = 1 if dx > 0.0 else -1
		if _cooldown <= 0 and not talking and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
			talk()


func talk() -> void:
	if talking:
		return
	talking = true
	var c := Dialogues.conversation(npc_id)
	Events.dialogue_requested.emit(c.speaker, c.lines)


func _on_dialogue_closed() -> void:
	if not talking:
		return
	talking = false
	_cooldown = 20
	Dialogues.finish(npc_id)
	if shop_id != &"":
		Events.shop_requested.emit.call_deferred(shop_id)
	elif station != &"":
		Events.station_requested.emit.call_deferred(station)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	match look:
		Look.PEDLAR: _draw_pedlar()
		Look.FIGURE: _draw_figure()
		Look.SMITH: _draw_smith()
		Look.KEEPER: _draw_keeper()
		Look.STEWARD: _draw_steward()
		Look.ARCHIVIST: _draw_archivist()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pedlar() -> void:
	var bob := sin(_t * 1.6) * 0.5
	var cloth := Color("5b4a3a")
	var cloth_d := Color("3f3328")
	# Legs
	draw_line(Vector2(-3, -10), Vector2(-4, 0), cloth_d, 3.0)
	draw_line(Vector2(3, -10), Vector2(4, 0), cloth_d, 3.0)
	# Towering pack behind (to the left of the facing direction)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -8), Vector2(-15, -34 + bob), Vector2(-4, -36 + bob), Vector2(-2, -10)]), Palette.WOOD)
	draw_line(Vector2(-16, -14), Vector2(-3, -15), Palette.WOOD_LIGHT, 1.0)
	draw_line(Vector2(-15, -24), Vector2(-3, -25), Palette.WOOD_LIGHT, 1.0)
	draw_circle(Vector2(-12, -38 + bob), 3.0, Palette.STEEL_OXIDE)           # a pot
	draw_rect(Rect2(-8, -40 + bob, 4, 4), Palette.RUST)                       # a crate
	draw_line(Vector2(-6, -36 + bob), Vector2(-6, -30 + bob), Palette.GOLD, 1.0)  # a hanging bell cord
	draw_circle(Vector2(-6, -29 + bob), 1.6, Palette.GOLD)
	# Body, hunched forward
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -12), Vector2(-3, -26 + bob), Vector2(5, -27 + bob), Vector2(7, -12)]), cloth)
	draw_line(Vector2(-4, -22 + bob), Vector2(6, -23 + bob), cloth_d, 1.0)
	# Head with a wide hat
	draw_circle(Vector2(5, -30 + bob), 3.4, Color("c9a98a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-1, -31 + bob), Vector2(11, -31 + bob), Vector2(8, -37 + bob), Vector2(2, -37 + bob)]), cloth_d)
	draw_line(Vector2(-2, -31 + bob), Vector2(12, -31 + bob), cloth_d, 1.5)
	# Lantern on a pole
	var lx := 13.0
	draw_line(Vector2(lx, -2), Vector2(lx, -30), Palette.WOOD, 1.2)
	draw_line(Vector2(lx, -30), Vector2(lx - 3, -30), Palette.WOOD, 1.2)
	var fl := 0.75 + 0.25 * sin(_t * 9.0) * sin(_t * 5.3)
	draw_circle(Vector2(lx - 3, -26), 9.0, Color(Palette.EMBER, 0.12 * fl))
	draw_rect(Rect2(lx - 5, -29, 4, 6), Color(0.1, 0.08, 0.06))
	draw_rect(Rect2(lx - 4.2, -28.2, 2.4, 4.4), Color(1.0, 0.8, 0.4, fl))


func _draw_figure() -> void:
	var sway := sin(_t * 0.9) * 0.8
	var robe := Color(0.62, 0.62, 0.66, 0.92)
	var robe_d := Color(0.42, 0.42, 0.48, 0.92)
	# Candle glow behind everything
	var fl := 0.8 + 0.2 * sin(_t * 7.0) * sin(_t * 4.1)
	draw_circle(Vector2(9, -18), 16.0, Color(1.0, 0.85, 0.5, 0.07 * fl))
	draw_circle(Vector2(9, -18), 8.0, Color(1.0, 0.85, 0.5, 0.08 * fl))
	# Long robe, frayed hem
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-4, -26), Vector2(3 + sway * 0.3, -29), Vector2(6, -26), Vector2(7, 0)]), robe)
	for i in 5:
		var x := -6.0 + i * 3.1
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 1.5, 2 + (i % 2)), Vector2(x + 3, 0)]), robe_d)
	draw_line(Vector2(-3, -20), Vector2(-4, -2), robe_d, 1.0)
	# Hood: dark hollow where a face would be, two faint points of light
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -26), Vector2(0 + sway * 0.3, -37), Vector2(5, -26), Vector2(2, -23), Vector2(-3, -23)]), robe_d)
	draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -27), Vector2(0, -33), Vector2(2.5, -27), Vector2(0, -24.5)]), Color(0.04, 0.03, 0.05))
	draw_circle(Vector2(-1, -28.5), 0.5, Color(1, 0.9, 0.6, 0.8))
	draw_circle(Vector2(1.2, -28.5), 0.5, Color(1, 0.9, 0.6, 0.8))
	# Arm holding a candle
	draw_line(Vector2(3, -22), Vector2(8, -19), robe_d, 2.0)
	draw_rect(Rect2(7.5, -19, 2, 6), Palette.BONE)
	draw_colored_polygon(PackedVector2Array([Vector2(8.5, -20), Vector2(7.4, -22.5 - fl), Vector2(8.5, -25 - fl * 2.0), Vector2(9.6, -22.5 - fl)]), Color(1.0, 0.8, 0.4, 0.95))


func _draw_smith() -> void:
	var bob := sin(_t * 1.3) * 0.4
	var fl := 0.75 + 0.25 * sin(_t * 8.0) * sin(_t * 4.7)
	# Anvil on a stump, hot iron on it
	draw_rect(Rect2(-22, -6, 10, 6), Palette.WOOD)
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -10), Vector2(-9, -10), Vector2(-12, -7), Vector2(-23, -7)]), Color("5a5f68"))
	draw_rect(Rect2(-22, -12, 8, 2), Color(1.0, 0.45 + 0.2 * fl, 0.15, 0.95))
	draw_circle(Vector2(-18, -12), 7.0, Color(1.0, 0.5, 0.2, 0.10 * fl))
	# Legs and broad body in a leather apron
	draw_line(Vector2(-3, -10), Vector2(-4, 0), Color("3a2e26"), 3.4)
	draw_line(Vector2(4, -10), Vector2(5, 0), Color("3a2e26"), 3.4)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -11), Vector2(-7, -27 + bob), Vector2(9, -27 + bob), Vector2(10, -11)]), Color("6e5b4a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -12), Vector2(-4, -24 + bob), Vector2(7, -24 + bob), Vector2(8, -12)]), Color("4a3626"))
	# Bald head, heavy beard
	draw_circle(Vector2(1, -31 + bob), 4.0, Color("c29a7c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -30 + bob), Vector2(5, -30 + bob), Vector2(3, -24 + bob), Vector2(-1, -24 + bob)]), Color("5a4a3a"))
	# Hammer arm raised a little, bobbing
	draw_line(Vector2(7, -24 + bob), Vector2(14, -22 + bob), Color("c29a7c"), 3.0)
	draw_line(Vector2(14, -22 + bob), Vector2(16, -33 + bob), Palette.WOOD_LIGHT, 1.6)
	draw_rect(Rect2(13.5, -37 + bob, 6, 4), Color("7a808a"))


func _draw_keeper() -> void:
	var sway := sin(_t * 1.0) * 0.6
	var fl := 0.8 + 0.2 * sin(_t * 6.0) * sin(_t * 3.7)
	var robe := Color("6b5a78")
	var robe_d := Color("4a3d58")
	draw_circle(Vector2(10, -16), 14.0, Color(1.0, 0.55, 0.2, 0.07 * fl))
	# Robe
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-4, -25), Vector2(3, -27), Vector2(6, -24), Vector2(7, 0)]), robe)
	for i in 4:
		var x := -6.0 + i * 3.4
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 1.7, 2.0), Vector2(x + 3.4, 0)]), robe_d)
	draw_line(Vector2(-2, -22), Vector2(-3, -2), robe_d, 1.0)
	# Veiled head
	draw_circle(Vector2(0.5 + sway * 0.3, -29), 3.6, Color("d9c5b0"))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -29), Vector2(0, -35), Vector2(5, -29), Vector2(6, -22), Vector2(-5, -22)]), Color(robe_d, 0.95))
	draw_circle(Vector2(1.5, -29), 2.4, Color("d9c5b0"))
	# Arm holding a glass vial of ember-light
	draw_line(Vector2(4, -22), Vector2(10, -19), robe_d, 2.0)
	draw_rect(Rect2(8.5, -22, 3.4, 5.5), Color(0.15, 0.1, 0.1, 0.9))
	draw_rect(Rect2(9.1, -21.4, 2.2, 4.3), Color(1.0, 0.5 + 0.2 * fl, 0.15, 0.95))
	draw_rect(Rect2(8.8, -23.4, 2.8, 1.4), Palette.BONE)


func _draw_steward() -> void:
	# A ghost in a tailcoat: pale, translucent, no legs, a candelabra in one hand.
	var bob := sin(_t * 1.1) * 1.2
	var a := 0.78 + 0.1 * sin(_t * 2.3)
	var coat := Color(0.55, 0.58, 0.72, a)
	var coat_d := Color(0.34, 0.36, 0.5, a)
	var skin := Color(0.82, 0.86, 0.92, a)
	draw_circle(Vector2(0, -20 + bob), 18.0, Color(0.6, 0.7, 1.0, 0.05))
	# Tails of the coat fading to wisps instead of legs
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -4 + bob), Vector2(-5, -26 + bob), Vector2(5, -26 + bob), Vector2(6, -4 + bob), Vector2(2, 2 + bob), Vector2(-1, -3 + bob), Vector2(-4, 2 + bob)]), coat)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -4 + bob), Vector2(-9, 3 + bob), Vector2(-4, -2 + bob)]), Color(coat, a * 0.6))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -4 + bob), Vector2(10, 4 + bob), Vector2(3, -2 + bob)]), Color(coat, a * 0.5))
	draw_line(Vector2(0, -25 + bob), Vector2(0, -8 + bob), coat_d, 1.0)
	draw_rect(Rect2(-2, -25 + bob, 4, 3), Color(0.9, 0.92, 1.0, a))   # cravat
	# Head: long, solemn, with white hair
	draw_circle(Vector2(0, -30 + bob), 3.8, skin)
	draw_arc(Vector2(0, -31 + bob), 3.9, PI, TAU, 8, Color(0.9, 0.9, 0.95, a), 1.6)
	draw_circle(Vector2(1.2, -30.4 + bob), 0.5, Color(0.1, 0.1, 0.2, a))
	draw_circle(Vector2(-1.4, -30.4 + bob), 0.5, Color(0.1, 0.1, 0.2, a))
	# Arm with a three-branch candelabra
	draw_line(Vector2(4, -22 + bob), Vector2(10, -18 + bob), coat_d, 2.0)
	draw_line(Vector2(10, -18 + bob), Vector2(10, -23 + bob), Color(0.75, 0.7, 0.5, a), 1.0)
	for dx in [-3.0, 0.0, 3.0]:
		draw_line(Vector2(10 + dx * 0.8, -22 + bob), Vector2(10 + dx, -25 + bob), Color(0.75, 0.7, 0.5, a), 0.8)
		var fl := 0.8 + 0.2 * sin(_t * 7.0 + dx)
		draw_circle(Vector2(10 + dx, -27 + bob), 1.1 * fl, Color(0.7, 0.85, 1.0, 0.95))
	draw_circle(Vector2(10, -25 + bob), 10.0, Color(0.6, 0.8, 1.0, 0.07))


func _draw_archivist() -> void:
	# A ghost in a long grey dress with spectacles and an open book, a quill behind one ear.
	var bob := sin(_t * 1.0) * 1.0
	var a := 0.8 + 0.1 * sin(_t * 2.0)
	var dress := Color(0.5, 0.56, 0.62, a)
	var dress_d := Color(0.3, 0.34, 0.42, a)
	var skin := Color(0.84, 0.88, 0.92, a)
	draw_circle(Vector2(0, -20 + bob), 17.0, Color(0.7, 0.8, 1.0, 0.05))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 1 + bob), Vector2(-4, -25 + bob), Vector2(4, -25 + bob), Vector2(7, 1 + bob), Vector2(3, -3 + bob), Vector2(0, 2 + bob), Vector2(-3, -3 + bob)]), dress)
	draw_line(Vector2(-4, -22 + bob), Vector2(-5, -4 + bob), dress_d, 1.0)
	draw_circle(Vector2(0, -29 + bob), 3.6, skin)
	draw_circle(Vector2(0, -30.2 + bob), 3.8, Color(0.74, 0.76, 0.84, a))   # hair bun base
	draw_circle(Vector2(-2.4, -33.4 + bob), 2.0, Color(0.74, 0.76, 0.84, a))
	draw_circle(Vector2(1.6, -29.3 + bob), 1.3, Color(0.85, 0.9, 1.0, 0.35))
	draw_arc(Vector2(1.6, -29.3 + bob), 1.4, 0.0, TAU, 8, Color(0.9, 0.95, 1.0, a), 0.6)   # spectacles
	draw_line(Vector2(-4, -31 + bob), Vector2(-7, -34 + bob), Color(0.9, 0.9, 0.85, a), 0.8)  # quill
	# Book held open in front
	draw_line(Vector2(3, -19 + bob), Vector2(9, -17 + bob), dress_d, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(7, -22 + bob), Vector2(12, -21 + bob), Vector2(12, -15 + bob), Vector2(7, -16 + bob)]), Color(0.8, 0.74, 0.55, a))
	draw_line(Vector2(9.5, -21.5 + bob), Vector2(9.5, -15.5 + bob), Color(0.4, 0.33, 0.2, a), 0.7)
	for i in 3:
		draw_line(Vector2(7.8, -20 + i * 1.8 + bob), Vector2(9.0, -19.8 + i * 1.8 + bob), Color(0.4, 0.33, 0.2, a * 0.7), 0.5)
		draw_line(Vector2(10.0, -20 + i * 1.8 + bob), Vector2(11.4, -19.8 + i * 1.8 + bob), Color(0.4, 0.33, 0.2, a * 0.7), 0.5)
	draw_circle(Vector2(9.5, -18.5 + bob), 7.0, Color(1.0, 0.9, 0.6, 0.06))
