class_name BossGimmicks
extends Node
## A boss's signature trick, on top of its attack pool. Attached to a BossBase when its fight starts.
## Data-driven: FOR[boss_id] is a list of {kind, every, phase, ...}.
##   mark   - telegraphed strike on the ground under you (move!)
##   wave   - a floor ripple races toward you (jump it)
##   rain   - falling debris columns across the arena
##   adds   - calls helpers once (and again at half health)
##   enrage - below 25% health: faster and angrier (red glow)
## phase = minimum boss phase for the entry to run (2 = only after the half-health roar).

const FOR := {
	&"bell_warden": [{"kind": "wave", "every": 7.0, "phase": 2}],
	&"drowned_canon": [{"kind": "mark", "every": 5.5, "phase": 1}, {"kind": "rain", "every": 9.0, "phase": 2}],
	&"hollow_marshal": [{"kind": "wave", "every": 6.5, "phase": 1}, {"kind": "enrage"}],
	&"gravewarden": [{"kind": "mark", "every": 6.0, "phase": 2}],
	&"salt_abbot": [{"kind": "wave", "every": 6.0, "phase": 1}, {"kind": "mark", "every": 7.0, "phase": 2}],
	&"hollow_regent": [{"kind": "adds", "phase": 2, "count": 2}, {"kind": "mark", "every": 6.5, "phase": 1}],
	&"last_ringer": [{"kind": "rain", "every": 7.0, "phase": 1}, {"kind": "enrage"}],
	&"thornmother": [{"kind": "mark", "every": 4.5, "phase": 1}, {"kind": "adds", "phase": 2, "count": 2}],
	&"orrerist": [{"kind": "mark", "every": 4.5, "phase": 1}, {"kind": "rain", "every": 8.0, "phase": 2}],
	&"drowned_bishop": [{"kind": "wave", "every": 5.5, "phase": 1}, {"kind": "rain", "every": 8.0, "phase": 2}],
	&"crownless_king": [{"kind": "wave", "every": 6.0, "phase": 1}, {"kind": "mark", "every": 5.0, "phase": 2}, {"kind": "enrage"}],
	&"ossuary_king_veyl": [{"kind": "adds", "phase": 1, "count": 2}, {"kind": "wave", "every": 7.0, "phase": 2}],
	&"chandler_ulme": [{"kind": "rain", "every": 6.5, "phase": 2}, {"kind": "enrage"}],
	&"chancellor_vorne": [{"kind": "mark", "every": 4.0, "phase": 1}],
	&"mother_sylve": [{"kind": "adds", "phase": 2, "count": 3}, {"kind": "mark", "every": 6.0, "phase": 1}],
	&"auctioneer_mordant": [{"kind": "mark", "every": 4.5, "phase": 1}, {"kind": "rain", "every": 9.0, "phase": 2}],
	&"admiral_sorrel": [{"kind": "wave", "every": 5.0, "phase": 1}, {"kind": "enrage"}],
	&"glasswright_orm": [{"kind": "rain", "every": 5.5, "phase": 1}, {"kind": "mark", "every": 6.0, "phase": 2}],
	&"vowsmith_anaxe": [{"kind": "wave", "every": 6.0, "phase": 1}, {"kind": "mark", "every": 5.5, "phase": 2}],
	&"prioress_silence": [{"kind": "mark", "every": 3.8, "phase": 1}],
	&"pale_sovereign": [{"kind": "wave", "every": 5.5, "phase": 1}, {"kind": "mark", "every": 4.5, "phase": 2}, {"kind": "enrage"}],
	&"the_oath_eternal": [{"kind": "mark", "every": 4.0, "phase": 1}, {"kind": "wave", "every": 6.0, "phase": 1}, {"kind": "rain", "every": 7.0, "phase": 2}, {"kind": "adds", "phase": 2, "count": 2}, {"kind": "enrage"}],
	&"verse_mother_ilse": [{"kind": "wave", "every": 5.0, "phase": 1}, {"kind": "rain", "every": 7.0, "phase": 2}],
	&"the_lantern_mother": [{"kind": "mark", "every": 3.8, "phase": 1}, {"kind": "adds", "phase": 2, "count": 3}],
	&"the_unnamed_archon": [{"kind": "mark", "every": 4.0, "phase": 1}, {"kind": "wave", "every": 6.0, "phase": 2}, {"kind": "enrage"}],
	&"the_unkept_promise": [{"kind": "mark", "every": 3.5, "phase": 1}, {"kind": "wave", "every": 5.0, "phase": 1}, {"kind": "rain", "every": 6.0, "phase": 2}, {"kind": "adds", "phase": 2, "count": 3}, {"kind": "enrage"}],
	# Mini-bosses: one small trick each.
	&"cellarer": [{"kind": "mark", "every": 7.0, "phase": 2}],
	&"ser_ashfall": [{"kind": "wave", "every": 8.0, "phase": 2}],
	&"mother_cinder": [{"kind": "rain", "every": 8.0, "phase": 2}],
	&"skarn_bone_counter": [{"kind": "mark", "every": 7.0, "phase": 1}],
	&"marrow_mother_ide": [{"kind": "adds", "phase": 2, "count": 2}],
	&"wickmaster_dorr": [{"kind": "mark", "every": 7.0, "phase": 1}],
	&"tallow_hound_grise": [{"kind": "wave", "every": 7.0, "phase": 1}],
	&"archivist_pellos": [{"kind": "rain", "every": 7.0, "phase": 1}],
	&"the_index": [{"kind": "mark", "every": 6.5, "phase": 1}],
	&"gardener_hobthorne": [{"kind": "adds", "phase": 2, "count": 2}],
	&"windfall_twins": [{"kind": "mark", "every": 6.0, "phase": 1}, {"kind": "enrage"}],
	&"barker_quill": [{"kind": "mark", "every": 6.5, "phase": 1}],
	&"pawnbroker_hask": [{"kind": "wave", "every": 7.5, "phase": 1}],
	&"brineknight_calder": [{"kind": "wave", "every": 6.5, "phase": 1}],
	&"drowned_cantor_eun": [{"kind": "rain", "every": 7.0, "phase": 1}],
	&"lensgrinder_fay": [{"kind": "mark", "every": 6.0, "phase": 1}],
	&"mirror_knight_ysolde": [{"kind": "enrage"}, {"kind": "mark", "every": 7.0, "phase": 2}],
	&"smelter_brask": [{"kind": "rain", "every": 7.5, "phase": 1}],
	&"cinderpriest_imre": [{"kind": "mark", "every": 6.0, "phase": 1}],
	&"sister_quiet": [{"kind": "mark", "every": 5.0, "phase": 1}],
	&"brother_lull": [{"kind": "wave", "every": 7.0, "phase": 1}],
	&"hollow_houndking": [{"kind": "wave", "every": 6.0, "phase": 1}, {"kind": "enrage"}],
	&"bannerbearer_rook": [{"kind": "adds", "phase": 2, "count": 2}],
	&"keeper_first_oath": [{"kind": "mark", "every": 6.0, "phase": 1}],
	&"the_unsworn": [{"kind": "wave", "every": 6.5, "phase": 2}],
	&"foundrymaster_brand": [{"kind": "rain", "every": 7.0, "phase": 1}],
	&"gaoler_vess": [{"kind": "mark", "every": 6.0, "phase": 1}],
	&"chorister_vael": [{"kind": "wave", "every": 6.5, "phase": 1}],
	&"ash_deacon_ruth": [{"kind": "rain", "every": 7.0, "phase": 1}],
	&"wisp_warden_nell": [{"kind": "mark", "every": 5.5, "phase": 1}],
	&"ferryman_obol": [{"kind": "wave", "every": 6.5, "phase": 1}],
	&"namekeeper_ish": [{"kind": "mark", "every": 6.0, "phase": 1}],
	&"chiselmaster_tor": [{"kind": "rain", "every": 7.0, "phase": 1}],
	&"jessamy_court_fool": [{"kind": "mark", "every": 5.0, "phase": 1}, {"kind": "enrage"}],
	&"chamberlain_hollin": [{"kind": "wave", "every": 6.5, "phase": 1}],
}
const ADD_SCENES := ["res://actors/enemies/hollow_penitent.tscn", "res://actors/enemies/gilded_penitent.tscn", "res://actors/enemies/drowned_pilgrim.tscn"]

var boss: BossBase
var _entries: Array = []
var _timers: Array[float] = []
var _adds_done: Array[int] = []
var _enraged := false
var spawned := 0          ## zones and adds created so far (tests read this)


static func has_for(id: StringName) -> bool:
	return FOR.has(id)


func setup(b: BossBase) -> BossGimmicks:
	boss = b
	_entries = FOR.get(b.boss_id, [])
	for e in _entries:
		_timers.append(float(e.get("every", 99.0)) * 0.6)
	return self


func _physics_process(delta: float) -> void:
	if boss == null or not is_instance_valid(boss) or boss.is_dead() or not boss.active:
		return
	if boss.roaring:
		return
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		if boss.phase < int(e.get("phase", 1)):
			continue
		match String(e.kind):
			"enrage":
				_maybe_enrage()
			"adds":
				_maybe_adds(i, e)
			_:
				_timers[i] -= delta
				if _timers[i] <= 0.0:
					_timers[i] = float(e.every) * randf_range(0.85, 1.15) * (0.8 if boss.phase >= 2 else 1.0)
					_fire(String(e.kind))


func _level() -> Node:
	return boss.get_parent()


func _tint() -> Color:
	return Color(0.9, 0.35, 0.25).lerp(Palette.GOLD_BRIGHT, 0.0)


func _fire(kind: String) -> void:
	var p := boss.target
	if p == null:
		return
	var floor_y := boss.global_position.y
	match kind:
		"mark":
			var z := BossZone.new().setup(BossZone.Kind.BOX, Vector2(46, 72), 0.95, 26.0, _tint())
			z.global_position = Vector2(p.global_position.x, floor_y)
			_level().add_child(z)
			spawned += 1
		"wave":
			var dir := signf(p.global_position.x - boss.global_position.x)
			if dir == 0.0:
				dir = 1.0
			var z := BossZone.new().setup(BossZone.Kind.WAVE, Vector2(26, 13), 0.0, 20.0, Color(0.85, 0.7, 0.35))
			z.dir = dir
			z.global_position = Vector2(boss.global_position.x + dir * 24.0, floor_y)
			_level().add_child(z)
			spawned += 1
		"rain":
			var n := 3 + boss.phase
			for k in n:
				var z := BossZone.new().setup(BossZone.Kind.RAIN, Vector2(30, 90), 0.85 + 0.12 * k, 18.0, Color(0.7, 0.7, 0.85))
				z.global_position = Vector2(p.global_position.x + randf_range(-170.0, 170.0), floor_y)
				_level().add_child(z)
				spawned += 1


func _maybe_enrage() -> void:
	if _enraged or boss.health.current > boss.health.max_health * 0.25:
		return
	_enraged = true
	boss.data.chase_speed *= 1.25
	boss.data.attack_cooldown_min = int(boss.data.attack_cooldown_min * 0.7)
	boss.data.attack_cooldown_max = int(boss.data.attack_cooldown_max * 0.7)
	boss.modulate = Color(1.25, 0.8, 0.8)
	Events.banner_requested.emit("%s is enraged" % boss.data.display_name.split(",")[0])
	GameFeel.ring(boss.global_position + Vector2(0, -26), Color(0.9, 0.2, 0.2), 60.0)
	GameFeel.shake(4.0, 0.3)
	Audio.sfx_at(&"boss_roar", boss.global_position, -4.0, 1.15)
	spawned += 1


func _maybe_adds(i: int, e: Dictionary) -> void:
	var stage := boss.phase   # once per phase at most
	if _adds_done.has(stage) and not (i < 0):
		return
	_adds_done.append(stage)
	var scene: PackedScene = load(ADD_SCENES[(boss.boss_id.length() + stage) % ADD_SCENES.size()])
	for k in int(e.get("count", 2)):
		var m := scene.instantiate() as Node2D
		var side := -1.0 if k % 2 == 0 else 1.0
		_level().add_child(m)
		m.global_position = boss.global_position + Vector2(side * (60.0 + 28.0 * k), 0.0)
		spawned += 1
	GameFeel.spark(boss.global_position + Vector2(0, -20), Palette.EMBER, 14)
