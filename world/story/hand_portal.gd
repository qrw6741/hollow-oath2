class_name HandPortal
extends Area2D
## A colossal hand with open palms, left behind by the Twin Lords. Press Interact to walk into it:
## a short cutscene (bars, the player steps in, the fingers close, black flame) carries you to
## [member target_level]. It stays after the fight; the way is open for as long as the pair is dead.
## X skips the walk (the teleport still happens). TEMPORARY ART: the hand is RisingHand's procedural art.

@export_file("*.tscn") var target_level := "res://world/levels/lower_hell.tscn"
@export var target_entry: StringName = &"from_hand"

var hand: RisingHand
var busy := false
## True for a reloaded level: the hand is already standing.
var start_risen := false
var _player_inside: Player
var _t := 0.0
var _skip := false
var _cine: CineLayer


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(54, 80)
	cs.shape = r
	cs.position = Vector2(0, -40)
	add_child(cs)
	hand = RisingHand.new()
	hand.rise = 1.0 if start_risen else 0.0
	hand.open = 1.0
	hand.fade = 1.0
	hand.scale = Vector2(0.75, 0.75)
	hand.z_index = -1
	add_child(hand)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	add_to_group(&"hand_portal")


## Rises out of the floor (the death scene) or is simply there (a reloaded level).
func appear(animated: bool) -> void:
	if animated:
		var tw := create_tween()
		tw.tween_property(hand, "rise", 1.0, 1.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		GameFeel.shake(3.0, 1.2)
		Audio.sfx_at(&"boss_stomp", global_position, 0.0, 0.6)
	else:
		hand.rise = 1.0


func _on_enter(b: Node) -> void:
	if b is Player and not busy:
		_player_inside = b
		Events.interact_prompt_shown.emit("Step into the hand")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	if busy or _player_inside == null or hand.rise < 0.95:
		return
	if _player_inside.is_dead() or not GameState.in_game:
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		enter(_player_inside)


func _wait(secs: float) -> void:
	var t := 0.0
	while not _skip and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()


## The teleport cutscene.
func enter(p: Player) -> void:
	if busy:
		return
	busy = true
	_skip = false
	_player_inside = null
	Events.interact_prompt_hidden.emit()
	p.cutscene_lock = true
	p.velocity = Vector2.ZERO
	_cine = CineLayer.new()
	add_child(_cine)
	_cine.skip_requested.connect(func(): _skip = true)
	_cine.bars(true, 0.7)
	get_tree().call_group(&"hud", "set_cinematic", true)
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_to(global_position + Vector2(0, -60), 1.5, 1.0)
	# the player walks into the open palms
	p.facing = 1 if global_position.x >= p.global_position.x else -1
	var tw := create_tween()
	tw.tween_property(p, "global_position:x", global_position.x, 0.05 if _skip else 1.3).set_trans(Tween.TRANS_SINE)
	await _wait(1.4)
	if not is_inside_tree():
		return
	# the fingers close round them, black flame lifts, the player fades
	Audio.sfx_at(&"boss_roar", global_position, -6.0, 0.6)
	GameFeel.rise(global_position + Vector2(0, -30), Color(0.35, 0.2, 0.6), 26, 18.0)
	GameFeel.ring(global_position + Vector2(0, -40), Color(0.55, 0.3, 0.9), 50.0)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(hand, "open", 0.0, 0.05 if _skip else 1.4)
	tw2.tween_property(p, "modulate:a", 0.0, 0.05 if _skip else 1.2).set_delay(0.0 if _skip else 0.4)
	if cam:
		cam.cine_to(global_position + Vector2(0, -50), 1.9, 1.4)
	await _wait(1.6)
	if not is_inside_tree():
		return
	Events.hand_teleport_requested.emit(target_level, target_entry)   # Main hands the HUD back on arrival
