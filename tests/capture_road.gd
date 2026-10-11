extends Node
## Renders the after-prologue content: Ommen at the First Light Candle, Wenna and her shop,
## the dialogue box, the Vaelmoor road, the new enemies and the Hollow Marshal's poses.
##   xvfb-run godot --path . --fixed-fps 60 res://tests/capture_road.tscn -- <out_dir>
var out_dir := "user://screens"
var main: Node
var lv: Level
var pl: Player

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

func go(path: String, entry: StringName) -> void:
	Events.level_change_requested.emit(path, entry, false)
	await frames(80)
	lv = main.current_level()
	pl = lv.player

func at(x: float, y := 480.0, face := 1) -> void:
	pl.global_position = Vector2(x, y)
	pl.velocity = Vector2.ZERO
	pl.facing = face

func _run() -> void:
	Settings.hit_stop = false
	Settings.candle_menu_on_rest = false
	SaveSystem.save_dir = "user://capture_saves"
	GameState.reset()
	main = load("res://main/main.tscn").instantiate()
	main.show_menu_on_start = false
	get_tree().root.add_child(main)
	await frames(40)
	GameState.embers = 420
	GameState.set_flag(&"candle_lit_first_light_candle", true)
	# --- Vaelmoor, Awake: Ommen by the First Light Candle
	await go("res://world/levels/vaelmoor_awake.tscn", &"arrival")
	at(470.0)
	await frames(30)
	await shot("r1_ommen_prompt")
	Events.dialogue_requested.emit("Hooded Figure", Dialogues.conversation(&"ommen").lines)
	await frames(50)
	await shot("r2_ommen_dialogue")
	var box: DialogueBox = main.get_node("DialogueBox")
	box.close()
	await frames(5)
	# --- The road: Wenna and her shop
	await go("res://world/levels/vaelmoor_road.tscn", &"from_awake")
	at(335.0)
	await frames(30)
	await shot("r3_wenna")
	Events.shop_requested.emit(&"pedlar")
	await frames(10)
	await shot("r4_shop")
	main.get_node("ShopMenu").close()
	await frames(5)
	# --- Road views
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.process_mode = Node.PROCESS_MODE_DISABLED
	at(900.0, 460.0)
	await frames(30)
	await shot("r5_crow_fields")
	at(1500.0, 440.0)
	await frames(30)
	await shot("r6_ford")
	at(2200.0)
	await frames(30)
	await shot("r7_camp")
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.process_mode = Node.PROCESS_MODE_INHERIT
	# --- Pikeman and crow poses
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if not e.is_in_group(&"bosses"):
			e.queue_free()
	for s in get_tree().get_nodes_in_group(&"enemy_spawners"):
		if not s is BossArena:
			s.remove_from_group(&"enemy_spawners")
	at(700.0)
	await frames(20)
	var pk: EnemyBase = load("res://actors/enemies/roadside_pikeman.tscn").instantiate()
	pk.position = Vector2(745, 480)
	pk.start_facing = -1
	pk.patrol_distance = 0
	lv.add_child(pk)
	await frames(3)
	pk._cooldown = 100000
	pk._start_attack(load("res://data/attacks/pike_thrust.tres"))
	await frames(18)
	await shot("r8_pikeman_glint")
	pk._set_state(EnemyBase.State.IDLE)
	pk._start_attack(load("res://data/attacks/pike_trip.tres"))
	await frames(26)
	await shot("r9_pikeman_trip_red")
	pk.queue_free()
	var cr: FlyingEnemy = load("res://actors/enemies/carrion_crow.tscn").instantiate()
	cr.position = Vector2(760, 430)
	cr.start_facing = -1
	cr.patrol_distance = 0
	lv.add_child(cr)
	await frames(20)
	await shot("r10_crow")
	cr.queue_free()
	# --- The Hollow Marshal
	pl.global_position = Vector2(2840, 480)
	await frames(50)
	var ar: BossArena = lv.get_node("MarshalArena")
	var b := ar.boss as HollowMarshal
	await shot("r11_marshal_intro")
	b._cooldown = 99999
	pl.global_position = Vector2(b.global_position.x - 80.0, 480.0)
	pl.facing = 1
	b.facing = -1
	await frames(10)
	b._start_attack(load("res://data/attacks/marshal_thrust.tres"))
	await frames(22)
	await shot("r12_marshal_thrust_glint")
	await frames(24)
	b._start_attack(load("res://data/attacks/marshal_sweep.tres"))
	await frames(20)
	await shot("r13_marshal_sweep_windup")
	await frames(40)
	b._start_attack(load("res://data/attacks/marshal_charge.tres"))
	await frames(28)
	await shot("r14_marshal_charge_red")
	await frames(90)
	b.receive_hit(HitData.make(b.health.max_health * 0.55, pl))
	await frames(40)
	await shot("r15_marshal_phase2_roar")
	await frames(60)
	b._cooldown = 99999
	pl.global_position = Vector2(b.global_position.x - 140.0, 480.0)
	b.facing = -1
	b._start_attack(load("res://data/attacks/marshal_banner.tres"))
	await frames(38)
	await shot("r16_marshal_banner")
	await frames(50)
	await shot("r17_marshal_crows")
	get_tree().quit()
