class_name ElderArena
extends BossArena
## The basement of the Lower Hell. An old man lies chained on the grass. Interact to wake him: he is confused,
## remembers, and screams; mouth, eyes and spine blaze white (like a titan's change) and he becomes the Burning
## Elder (a fire-monster boss). Once awake the room behaves like any boss arena (a respawn resets the boss, no
## cutscene). The Elder teaches the Fire Meteor jutsu (an Art, see Arts). X skips the scene.
## TEMPORARY ART: all procedural.

const AWAKE_FLAG := &"ember_elder_awake"
const LINES := [
	["OLD MAN", "...Is it morning? ...Who is... Who is there?"],
	["OLD MAN", "Why am I... chains? How long have I been asleep?"],
	["OLD MAN", "There was a fire. I put it out. I put it IN. ...No. No, no, no..."],
	["OLD MAN", "It is still burning. It never stopped burning. AAAAAAAAH!"],
]

var elder: ChainedElder
var cine: CineLayer
var _skip := false
var _flash: ColorRect
var _flash_layer: CanvasLayer
var _scene_running := false


func spawn() -> void:
	if is_instance_valid(elder):
		elder.queue_free()
	elder = null
	_scene_running = false
	_cine_cleanup()
	if is_defeated() or bool(GameState.get_flag(AWAKE_FLAG, false)):
		super()   # a normal boss room from here on
		return
	if fight_active:
		_end_fight(false)
	if is_instance_valid(boss):
		boss.queue_free()
	boss = null
	_set_sealed(false)
	_defeated = false
	_arm = 30
	elder = ChainedElder.new()
	elder.position = position + boss_offset
	elder.woken.connect(_wake)
	get_parent().add_child.call_deferred(elder)


func _cine_begin() -> void:
	_skip = false
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.cutscene_lock = true
		p.velocity.x = 0.0
	if cine == null or not is_instance_valid(cine):
		cine = CineLayer.new()
		add_child(cine)
		cine.skip_requested.connect(func(): _skip = true)
	cine.bars(true, 0.8)
	get_tree().call_group(&"hud", "set_cinematic", true)


func _cine_end() -> void:
	get_tree().call_group(&"hud", "set_cinematic", false)
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_end(0.9)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.cutscene_lock = false
	if cine and is_instance_valid(cine):
		cine.bars(false, 0.8)
		var c := cine
		get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(c): c.queue_free())
	cine = null


func _cine_cleanup() -> void:
	if not is_inside_tree():
		return
	get_tree().call_group(&"hud", "set_cinematic", false)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p and p.cutscene_lock:
		p.cutscene_lock = false
	if cine and is_instance_valid(cine):
		cine.queue_free()
	cine = null
	if _flash_layer and is_instance_valid(_flash_layer):
		_flash_layer.queue_free()
	_flash_layer = null


func _cam(pos: Vector2, z: float, dur: float) -> void:
	var cam := get_viewport().get_camera_2d() as CameraRig
	if cam:
		cam.cine_to(pos, z, 0.05 if _skip else dur)


func _wait(secs: float) -> void:
	var t := 0.0
	while not _skip and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()


func _white(alpha_to: float, dur: float) -> void:
	if _flash == null or not is_instance_valid(_flash):
		_flash_layer = CanvasLayer.new()
		_flash_layer.layer = 90
		_flash = ColorRect.new()
		_flash.color = Color(1, 1, 1, 0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_flash_layer.add_child(_flash)
		add_child(_flash_layer)
	create_tween().tween_property(_flash, "color:a", alpha_to, 0.05 if _skip else dur)


func _wake() -> void:
	if _scene_running or not is_instance_valid(elder):
		return
	_scene_running = true
	GameState.set_flag(AWAKE_FLAG, true)
	_cine_begin()
	var e := elder
	var epos := e.global_position
	_cam(epos + Vector2(0, -30), 1.7, 1.2)
	await _wait(1.3)
	var tw := create_tween()
	tw.tween_property(e, "sitting", 1.0, 0.05 if _skip else 1.4)
	for i in 3:
		await _say(LINES[i][0], LINES[i][1])
		if not is_instance_valid(e):
			return
	# the scream: he throws his head back, mouth wide, the camera shakes and pushes in
	_cam(epos + Vector2(0, -34), 2.3, 1.6)
	Events.boss_say.emit(LINES[3][0], LINES[3][1], &"")
	var tws := create_tween()
	tws.tween_property(e, "shout", 1.0, 0.05 if _skip else 0.4)
	Audio.sfx_at(&"boss_roar", epos, 2.0, 0.5)
	GameFeel.shake(4.0, 2.4)
	# mouth, eyes and spine begin to shine, brighter and brighter
	var twg := create_tween()
	twg.tween_property(e, "glow", 1.0, 0.05 if _skip else 2.4).set_trans(Tween.TRANS_QUAD)
	var twk := create_tween()
	twk.tween_property(e, "shake", 2.5, 0.05 if _skip else 2.4)
	await _wait(2.2)
	GameFeel.ring(epos + Vector2(0, -20), Color(1.0, 0.8, 0.4), 70.0)
	GameFeel.shake(9.0, 0.8)
	_white(1.0, 0.5)
	await _wait(0.6)
	# the change: the man is gone, the fire monster stands where he lay
	e.visible = false
	boss = boss_scene.instantiate() as BossBase
	boss.position = epos
	boss.start_facing = -1
	boss.scripted_intro = true
	boss.died.connect(_on_boss_died)
	get_parent().add_child(boss)
	GameFeel.rise(epos + Vector2(0, -20), Color(1.0, 0.5, 0.15), 40, 40.0)
	GameFeel.ring(epos + Vector2(0, -40), Color(1.0, 0.6, 0.2), 100.0)
	GameFeel.shake(10.0, 1.0)
	Audio.sfx_at(&"boss_roar", epos, 4.0, 0.45)
	_white(0.0, 1.2)
	_cam(epos + Vector2(0, -80), 1.25, 1.3)
	await _wait(1.5)
	if cine and not _skip:
		cine.title("THE BURNING ELDER", "the fire remembers", 2.6)
		await _wait(2.6)
	_cine_end()
	if is_instance_valid(e):
		e.queue_free()
	elder = null
	_scene_running = false
	if is_instance_valid(boss) and not boss.is_dead():
		boss.start_fight()


func _say(who: String, text: String) -> void:
	if _skip:
		return
	Events.boss_say.emit(who, text, &"")
	await _wait(clampf(1.8 + text.length() * 0.045, 2.2, 4.5))


func _on_boss_died(b: EnemyBase) -> void:
	super(b)
	if not Arts.unlocked(&"fire_meteor"):
		return
	Arts.auto_equip()
	await get_tree().create_timer(1.6, false).timeout
	Events.banner_requested.emit("You learned Fire Meteor")


func _on_player_died() -> void:
	if _scene_running:
		_scene_running = false
		_cine_cleanup()
	super()
