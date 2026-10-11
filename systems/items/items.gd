class_name Items
extends RefCounted
## Registry and rules for items. Order of IDS = order in the inventory list.

const IDS: Array[StringName] = [&"ash_bandage", &"ember_shard", &"stamina_tonic", &"rusted_key", &"penitents_tear"]
const DIR := "res://data/items/"

static var _cache := {}


static func get_item(id: StringName) -> ItemData:
	if not IDS.has(id):
		return null
	if not _cache.has(id):
		_cache[id] = load(DIR + String(id) + ".tres") as ItemData
	return _cache[id]


static func is_valid_id(id: String) -> bool:
	return IDS.has(StringName(id))


## Uses one item on the player. Returns false (and consumes nothing) if it would do nothing.
static func use(id: StringName, player: Player) -> bool:
	var item := get_item(id)
	if item == null or not item.is_usable() or GameState.item_count(id) <= 0:
		return false
	if player == null or player.is_dead():
		return false
	match item.effect:
		ItemData.Effect.HEAL:
			if player.health.current >= player.health.max_health:
				return false
			player.health.heal(item.effect_amount)
			player.heal_flash = 20
		ItemData.Effect.STAMINA:
			player.stamina.refund(item.effect_amount)
		ItemData.Effect.EMBERS:
			GameState.add_embers(int(item.effect_amount))
	GameState.remove_item(id, 1)
	Events.item_used.emit(id)
	return true
