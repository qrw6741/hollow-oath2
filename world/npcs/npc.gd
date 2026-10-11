@tool
class_name Npc
extends Area2D
## A person you can talk to. Walk up, press Interact: a conversation (Dialogues, chosen by
## npc_id and how often you have talked), then - for a merchant - their shop.
## Origin = feet. TEMPORARY ART (procedural): Pedlar = hunched trader with a towering pack
## and a lantern; Figure = tall hooded stranger holding a candle.

enum Look { PEDLAR, FIGURE }

@export var npc_id: StringName = &"wenna"
@export var display_name := "Wenna"
@export var look := Look.PEDLAR:
	set(v): look = v; queue_redraw()
## Shop opened after the conversation ("" = just talk).
@export var shop_id: StringName = &""
@export_enum("Left:-1", "Right:1") var start_facing := -1

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


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	match look:
		Look.PEDLAR: _draw_pedlar()
		Look.FIGURE: _draw_figure()
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
