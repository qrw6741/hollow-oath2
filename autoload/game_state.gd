extends Node
## Run-time session state: which save slot is active, last rested checkpoint,
## play time, world flags, and the death -> respawn flow.
## [method to_dict] / [method apply_dict] are the only bridge to the save file;
## SaveSystem owns files, GameState owns what goes in them.

const RESPAWN_DELAY := 2.6
const DEFAULT_LEVEL_PATH := "res://world/levels/test_arena.tscn"

## True while a game session (not the main menu) is running.
## Runtime only (not saved): focus carried between levels; see Player.
var focus := 30.0
var in_game := false
## Active save slot (1-based). 0 = no slot: the session is never autosaved (tests, dev runs).
var current_slot := 0

## Chosen starting preset (see Presets). Fixed for the life of a save slot.
var preset_id: StringName = &"sworn_knight"
## Embers: the currency. Lost on death (dropped where you fell, recoverable once).
var embers := 0
## {} or { level_id, x, y, amount } — the one recoverable stain of lost embers.
var ember_drop := {}
## Character growth: points spent per stat. Level = 1 + total points.
var stats := {"vigor": 0, "endurance": 0, "strength": 0}
## item id (String) -> count.
var inventory := {}
var quick_item: StringName = &""
## Gear: owned id (String) -> upgrade level, and what is equipped. See Loadout / Forge.
## armor_id == &"none" means no armour (taken off); &"" means "not set up yet".
var weapons := {}
var weapon_id: StringName = &""
var armors := {}
var armor_id: StringName = &""
var flask_level := 0
const STAT_NAMES := ["vigor", "endurance", "strength"]
const VIGOR_HEALTH := 8.0
const ENDURANCE_STAMINA := 6.0
const STRENGTH_DAMAGE := 0.04
## Map exploration: level_id (String) -> { cell_key (int): true }. See WorldMap.
var explored := {}
## True while a modal menu (candle / inventory) owns input; the pause menu stays out of the way.
var ui_modal := false
## Set by the Hollowmere Sigil on the way back: the next load of this level puts the player here (not saved).
var pending_spawn_level := ""
var pending_spawn := Vector2.ZERO
var level_path := DEFAULT_LEVEL_PATH
## Level holding the last rested candle ("" = same as level_path, for old saves).
var checkpoint_level := ""
## Entry marker to appear at when a level loads (set by exits; "" = checkpoint / default).
var level_entry: StringName = &""
var level_name := ""
var has_checkpoint := false
var checkpoint_id: StringName = &""
var respawn_position := Vector2.ZERO
var deaths := 0
var play_time := 0.0
## Persistent world flags (boss defeated, shortcut opened, NPC met...). Values must be JSON-safe.
var flags := {}

## Incremented whenever the session is replaced, so stale timers (a pending respawn
## from a previous session) can recognise themselves and do nothing.
var session_id := 0
var _respawn_pending := false


func _ready() -> void:
	Events.player_died.connect(_on_player_died)
	Events.checkpoint_rested.connect(_on_checkpoint_rested)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.boss_defeated.connect(func(_id): Deeds.check_all())
	Events.quest_changed.connect(func(_i, _s): Deeds.check_all())
	Events.stats_changed.connect(func(): Deeds.check_all())
	Events.bestiary_changed.connect(func(_i): Deeds.check_all())
	Events.level_entered.connect(func(_p): Deeds.check_all())
	Events.status_triggered.connect(func(k): set_flag(StringName("fx_" + String(k)), true); Deeds.check_all())


func _process(delta: float) -> void:
	if in_game:
		# Hit-stop slows time_scale; play time should still track real time.
		play_time += delta / maxf(Engine.time_scale, 0.01)


func _on_checkpoint_rested(id: StringName, pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_id = id
	respawn_position = pos
	set_flag(StringName("candle_lit_" + String(id)), true)
	checkpoint_level = level_path
	level_entry = &""


## The level the last candle is in.
func checkpoint_level_path() -> String:
	return checkpoint_level if checkpoint_level != "" else level_path


func _on_player_died() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	deaths += 1
	_drop_embers()
	var sid := session_id
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	if sid != session_id:
		return  # The session ended (quit to menu / new game) while we waited.
	_respawn_pending = false
	Events.respawn_requested.emit()


# ------------------------------------------------------------------ New Game+
## A cycle restarts the story with everything you built kept. Enemies get tougher each time.
## Flags kept across a cycle (prefixes): what the player has *learned or earned for good*.
const KEEP_FLAG_PREFIXES := ["deed_", "bs_", "bk_", "tip_", "fx_", "infuse_", "relics_eq", "night_survived", "ng_cycle", "ending_", "candle_lit_", "art_", "secret_"]


func ng_cycle() -> int:
	return int(get_flag(&"ng_cycle", 0))


func ng_hp_mult() -> float:
	return 1.0 + 0.6 * ng_cycle()


func ng_damage_mult() -> float:
	return 1.0 + 0.35 * ng_cycle()


func ng_ember_mult() -> float:
	return 1.0 + 0.5 * ng_cycle()


## Clears the story (bosses, errands, chests, doors, conversations) but keeps gear, stats, items,
## relics, deeds and the bestiary. Returns the new cycle number. The caller reloads the world.
func begin_new_cycle() -> int:
	var keep := {}
	for k in flags:
		for pre in KEEP_FLAG_PREFIXES:
			if String(k).begins_with(pre):
				keep[k] = flags[k]
				break
	keep.erase("ending_chosen")
	keep["ng_cycle"] = ng_cycle() + 1
	flags = keep
	explored = {}
	level_path = DEFAULT_LEVEL_PATH
	level_name = ""
	checkpoint_level = ""
	level_entry = &""
	has_checkpoint = false
	checkpoint_id = &""
	respawn_position = Vector2.ZERO
	ember_drop = {}
	pending_spawn_level = ""
	return ng_cycle()


# ------------------------------------------------------------------ economy

func _on_enemy_killed(enemy: Node) -> void:
	Quests.on_enemy_killed(enemy)
	var d: EnemyData = enemy.get("data") as EnemyData
	Bestiary.record_kill(d)
	if d == null:
		return
	if d.ember_reward > 0:
		add_embers(roundi(d.ember_reward * Relics.mult("ember_gain") * ng_ember_mult()))
	if d.drop_item != null and d.drop_chance > 0.0 and randf() < d.drop_chance:
		add_item(d.drop_item.id, d.drop_count)
	if d.bonus_drop_item != null and d.bonus_drop_chance > 0.0 and randf() < d.bonus_drop_chance:
		add_item(d.bonus_drop_item.id, d.bonus_drop_count)


func add_embers(amount: int) -> void:
	if amount <= 0:
		return
	embers += amount
	Events.embers_gained.emit(amount)
	Events.embers_changed.emit(embers)


func spend_embers(amount: int) -> bool:
	if amount < 0 or amount > embers:
		return false
	embers -= amount
	Events.embers_changed.emit(embers)
	return true


## On death all carried embers fall where the player last stood safely.
## Dying again before recovering them destroys the older stain.
func _drop_embers() -> void:
	if embers <= 0:
		return
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var pos := Vector2.ZERO
	if p:
		pos = p.last_safe_position
	var lv := get_tree().get_first_node_in_group(&"level")
	ember_drop = {"level_id": String(lv.get("level_id")) if lv else "", "x": pos.x, "y": pos.y, "amount": embers}
	embers = 0
	Events.embers_changed.emit(embers)
	Events.ember_drop_changed.emit()


## Called by the remnant when touched. Returns the embers recovered.
func recover_drop() -> int:
	if ember_drop.is_empty():
		return 0
	var amount := int(ember_drop.get("amount", 0))
	ember_drop = {}
	add_embers(amount)
	Events.ember_drop_changed.emit()
	return amount


## Marks map cells as seen. Returns how many were new.
func explore(level_id: String, keys: Array) -> int:
	if not explored.has(level_id):
		explored[level_id] = {}
	var cells: Dictionary = explored[level_id]
	var added := 0
	for k in keys:
		if not cells.has(k):
			cells[k] = true
			added += 1
	return added


func is_explored(level_id: String, key: int) -> bool:
	return explored.has(level_id) and (explored[level_id] as Dictionary).has(key)


func _explored_to_save() -> Dictionary:
	var out := {}
	for lv in explored:
		var arr: Array = (explored[lv] as Dictionary).keys()
		arr.sort()
		out[lv] = arr
	return out


func level() -> int:
	var total := 0
	for s in STAT_NAMES:
		total += int(stats.get(s, 0))
	return 1 + total


## Embers needed to go from the current level to the next.
func level_cost() -> int:
	var n := level() - 1
	return 60 + 30 * n + 6 * n * n


func buy_stat(stat: String) -> bool:
	if not STAT_NAMES.has(stat):
		return false
	if not spend_embers(level_cost()):
		return false
	stats[stat] = int(stats.get(stat, 0)) + 1
	Events.stats_changed.emit()
	return true


func add_item(id: StringName, count := 1) -> int:
	var item := Items.get_item(id)
	if item == null or count <= 0:
		return 0
	var have := int(inventory.get(String(id), 0))
	var added := mini(count, item.max_stack - have)
	if added <= 0:
		return 0
	inventory[String(id)] = have + added
	if quick_item == &"" and item.is_usable() and item.effect != ItemData.Effect.TRAVEL:
		quick_item = id
	Events.item_picked.emit(id, added)
	Events.inventory_changed.emit()
	return added


func remove_item(id: StringName, count := 1) -> bool:
	var have := int(inventory.get(String(id), 0))
	if count <= 0 or have < count:
		return false
	if have == count:
		inventory.erase(String(id))
	else:
		inventory[String(id)] = have - count
	Events.inventory_changed.emit()
	return true


func item_count(id: StringName) -> int:
	return int(inventory.get(String(id), 0))


func owns_weapon(id: StringName) -> bool:
	return weapons.has(String(id))


func owns_armor(id: StringName) -> bool:
	return armors.has(String(id))


func weapon_level(id: StringName) -> int:
	return int(weapons.get(String(id), 0))


func armor_level(id: StringName) -> int:
	return int(armors.get(String(id), 0))


func grant_gear(kind: String, id: StringName) -> void:
	if kind == "weapon":
		if not weapons.has(String(id)):
			weapons[String(id)] = 0
	elif not armors.has(String(id)):
		armors[String(id)] = 0


func set_gear_level(kind: String, id: StringName, level: int) -> void:
	var d: Dictionary = weapons if kind == "weapon" else armors
	if d.has(String(id)):
		d[String(id)] = clampi(level, 0, Forge.MAX_LEVEL)


# ------------------------------------------------------------------ flags

func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[String(flag)] = value


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(String(flag), default)


# ------------------------------------------------------------------ sessions

## Clears everything. Also used by tests.
func reset() -> void:
	in_game = false
	current_slot = 0
	preset_id = &"sworn_knight"
	embers = 0
	ember_drop = {}
	stats = {"vigor": 0, "endurance": 0, "strength": 0}
	inventory = {}
	quick_item = &""
	weapons = {}
	weapon_id = &""
	armors = {}
	armor_id = &""
	flask_level = 0
	ui_modal = false
	pending_spawn_level = ""
	explored = {}
	level_path = DEFAULT_LEVEL_PATH
	level_name = ""
	checkpoint_level = ""
	level_entry = &""
	has_checkpoint = false
	checkpoint_id = &""
	respawn_position = Vector2.ZERO
	deaths = 0
	play_time = 0.0
	flags = {}
	session_id += 1
	_respawn_pending = false


func new_game(slot: int, preset: StringName = &"sworn_knight") -> void:
	reset()
	current_slot = slot
	preset_id = preset
	Loadout.ensure(Presets.get_preset(preset))


## Serialisable snapshot of durable state. No transient combat state, ever.
func to_dict() -> Dictionary:
	return {
		"play_time": play_time,
		"deaths": deaths,
		"preset_id": String(preset_id),
		"embers": embers,
		"ember_drop": ember_drop.duplicate(true),
		"stats": stats.duplicate(true),
		"inventory": inventory.duplicate(true),
		"quick_item": String(quick_item),
		"weapons": weapons.duplicate(true),
		"weapon_id": String(weapon_id),
		"armors": armors.duplicate(true),
		"armor_id": String(armor_id),
		"flask_level": flask_level,
		"explored": _explored_to_save(),
		"level_path": level_path,
		"level_name": level_name,
		"checkpoint_level": checkpoint_level,
		"level_entry": String(level_entry),
		"has_checkpoint": has_checkpoint,
		"checkpoint_id": String(checkpoint_id),
		"respawn_position": [respawn_position.x, respawn_position.y],
		"flags": flags.duplicate(true),
	}


## Loads a dictionary produced by SaveSystem (already validated/normalised).
func apply_dict(d: Dictionary, slot: int) -> void:
	reset()
	current_slot = slot
	play_time = float(d.get("play_time", 0.0))
	deaths = int(d.get("deaths", 0))
	preset_id = StringName(d.get("preset_id", "sworn_knight"))
	embers = int(d.get("embers", 0))
	ember_drop = (d.get("ember_drop", {}) as Dictionary).duplicate(true)
	stats = (d.get("stats", stats) as Dictionary).duplicate(true)
	inventory = (d.get("inventory", {}) as Dictionary).duplicate(true)
	quick_item = StringName(d.get("quick_item", ""))
	weapons = (d.get("weapons", {}) as Dictionary).duplicate(true)
	weapon_id = StringName(d.get("weapon_id", ""))
	armors = (d.get("armors", {}) as Dictionary).duplicate(true)
	armor_id = StringName(d.get("armor_id", ""))
	flask_level = int(d.get("flask_level", 0))
	explored = {}
	var ex: Dictionary = d.get("explored", {})
	for lv in ex:
		var cells := {}
		for k in ex[lv]:
			cells[int(k)] = true
		explored[String(lv)] = cells
	level_path = String(d.get("level_path", DEFAULT_LEVEL_PATH))
	level_name = String(d.get("level_name", ""))
	checkpoint_level = String(d.get("checkpoint_level", ""))
	level_entry = StringName(d.get("level_entry", ""))
	has_checkpoint = bool(d.get("has_checkpoint", false))
	checkpoint_id = StringName(d.get("checkpoint_id", ""))
	var p: Array = d.get("respawn_position", [0.0, 0.0])
	respawn_position = Vector2(float(p[0]), float(p[1]))
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	Loadout.ensure(Presets.get_preset(preset_id))
