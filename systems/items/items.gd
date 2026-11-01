class_name Items
extends RefCounted
## Registry and rules for items. Order of IDS = order in the inventory list.

const IDS: Array[StringName] = [&"ash_bandage", &"ember_shard", &"stamina_tonic", &"rusted_key", &"warden_bell_shard", &"fox_tooth", &"penitents_tear", &"candlewright_note", &"canon_seal", &"pilgrims_draught", &"marshals_crest", &"forge_scrap", &"hollow_resin", &"hollow_sigil", &"gallery_key", &"sextons_lantern", &"relic_locket", &"relic_thorn", &"relic_knot", &"relic_coin", &"relic_candle", &"relic_riposte", &"cinder_heart", &"ashfall_seal", &"lurker_fang", &"cantors_wick", &"abbots_signet", &"relic_shackle", &"relic_slag", &"relic_regent", &"relic_clapper", &"relic_briar", &"relic_gear", &"relic_chalice", &"relic_oathbreaker", &"tal_warden", &"tal_marshal", &"tal_cellarer", &"tal_sexton", &"tal_cinder", &"tal_ashfall", &"tal_canon", &"tal_abbot", &"tal_vess", &"tal_brand", &"tal_regent", &"tal_ringer", &"tal_thornmother", &"tal_orrerist", &"tal_bishop", &"tal_king", &"tal_iron_bead", &"tal_swift_feather", &"tal_ember_bead", &"tal_mender", &"tal_keen_edge", &"tal_hardy", &"tal_steady", &"potion_might", &"potion_ward", &"potion_vigor", &"potion_swift", &"potion_greed", &"potion_resolve", &"potion_focus", &"tal_x_skarn_bone_counter", &"tal_x_marrow_mother_ide", &"tal_x_ossuary_king_veyl", &"tal_x_wickmaster_dorr", &"tal_x_tallow_hound_grise", &"tal_x_chandler_ulme", &"tal_x_archivist_pellos", &"tal_x_the_index", &"tal_x_chancellor_vorne", &"tal_x_gardener_hobthorne", &"tal_x_windfall_twins", &"tal_x_mother_sylve", &"tal_x_barker_quill", &"tal_x_pawnbroker_hask", &"tal_x_auctioneer_mordant", &"tal_x_brineknight_calder", &"tal_x_drowned_cantor_eun", &"tal_x_admiral_sorrel", &"tal_x_lensgrinder_fay", &"tal_x_mirror_knight_ysolde", &"tal_x_glasswright_orm", &"tal_x_smelter_brask", &"tal_x_cinderpriest_imre", &"tal_x_vowsmith_anaxe", &"tal_x_sister_quiet", &"tal_x_brother_lull", &"tal_x_prioress_silence", &"tal_x_hollow_houndking", &"tal_x_bannerbearer_rook", &"tal_x_pale_sovereign", &"tal_x_keeper_first_oath", &"tal_x_the_unsworn", &"tal_x_the_oath_eternal", &"salt_of_the_dead", &"grave_wax_balm", &"marrow_broth", &"glass_tonic", &"ember_pip", &"ember_cluster", &"kings_wine", &"hush_draught", &"keepsake_bone_ring", &"keepsake_last_wick", &"keepsake_first_page", &"keepsake_black_seed", &"keepsake_gavel", &"keepsake_tide_glass", &"keepsake_kind_shard", &"keepsake_vowsmiths_ring", &"keepsake_hush_bell", &"keepsake_roll_of_kings", &"keepsake_aures_candle", &"relic_x_ossuary_king_veyl", &"relic_x_chandler_ulme", &"relic_x_chancellor_vorne", &"relic_x_mother_sylve", &"relic_x_auctioneer_mordant", &"relic_x_admiral_sorrel", &"relic_x_glasswright_orm", &"relic_x_vowsmith_anaxe", &"relic_x_prioress_silence", &"relic_x_pale_sovereign", &"relic_x_the_oath_eternal", &"tal_x_chorister_vael", &"tal_x_ash_deacon_ruth", &"tal_x_verse_mother_ilse", &"tal_x_wisp_warden_nell", &"tal_x_ferryman_obol", &"tal_x_the_lantern_mother", &"tal_x_namekeeper_ish", &"tal_x_chiselmaster_tor", &"tal_x_the_unnamed_archon", &"tal_x_jessamy_court_fool", &"tal_x_chamberlain_hollin", &"tal_x_the_unkept_promise", &"keepsake_choir_ember", &"keepsake_marsh_lantern", &"keepsake_blank_slab", &"keepsake_court_bell", &"relic_x_verse_mother_ilse", &"relic_x_the_lantern_mother", &"relic_x_the_unnamed_archon", &"relic_x_the_unkept_promise"]
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
