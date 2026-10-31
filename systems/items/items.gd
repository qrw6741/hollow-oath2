class_name Items
extends RefCounted
## Registry and rules for items. Order of IDS = order in the inventory list.

const IDS: Array[StringName] = [&"ash_bandage", &"ember_shard", &"stamina_tonic", &"rusted_key", &"warden_bell_shard", &"penitents_tear", &"candlewright_note", &"canon_seal", &"pilgrims_draught", &"marshals_crest", &"forge_scrap", &"hollow_resin", &"hollow_sigil", &"gallery_key", &"sextons_lantern", &"relic_locket", &"relic_thorn", &"relic_knot", &"relic_coin", &"relic_candle", &"relic_riposte", &"cinder_heart", &"ashfall_seal", &"lurker_fang", &"cantors_wick", &"abbots_signet", &"relic_shackle", &"relic_slag", &"relic_regent", &"relic_clapper", &"relic_briar", &"relic_gear", &"relic_chalice", &"relic_oathbreaker", &"tal_warden", &"tal_marshal", &"tal_cellarer", &"tal_sexton", &"tal_cinder", &"tal_ashfall", &"tal_canon", &"tal_abbot", &"tal_vess", &"tal_brand", &"tal_regent", &"tal_ringer", &"tal_thornmother", &"tal_orrerist", &"tal_bishop", &"tal_king", &"tal_iron_bead", &"tal_swift_feather", &"tal_ember_bead", &"tal_mender", &"tal_keen_edge", &"tal_hardy", &"tal_steady", &"potion_might", &"potion_ward", &"potion_vigor", &"potion_swift", &"potion_greed", &"potion_resolve", &"potion_focus"]
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
	if item.effect == ItemData.Effect.TRAVEL:
		# A reusable key: never consumed. Manor decides whether the oath lets you go.
		return Manor.travel(player).ok
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
		ItemData.Effect.BUFF:
			if not Buffs.start(id):
				return false
			player.heal_flash = 20
			Audio.sfx(&"relic_equip", -4.0)
	GameState.remove_item(id, 1)
	Events.item_used.emit(id)
	return true
