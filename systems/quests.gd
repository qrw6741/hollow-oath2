class_name Quests
extends RefCounted
## Small errands the people of the road and the manor give. Data-driven: add a dictionary to
## DEFS. State lives in world flags (saved with the game, no save-format change):
##   quest_<id>  = "active" | "done"      qk_<id> = kill count so far
## Kinds:  collect (hand over [item] x[count], consumed), kill (slay [count] of [enemy]),
##         have (own [item]; not consumed), flag (a world flag is set).
## NPC dialogue (Dialogues) offers a quest on a later visit, reminds you while it is open and
## pays out on the visit after it is done. A quest opens only after [after_talks] chats.

const DEFS := {
	&"hobb_scrap": {
		"giver": &"hobb", "after_talks": 1, "title": "Iron for the Forge", "kind": "collect",
		"item": &"forge_scrap", "count": 3,
		"summary": "Bring Hobb three Forge Scrap. The pikemen and shield-bearers of the road carry plenty.",
		"offer": ["My stock is down to slag. Bring me three Forge Scrap - the pikemen on the road carry it, belt-buckles and spear-ferrules and the like - and I'll make it worth your while."],
		"remind": "Three Forge Scrap, friend. The pikemen on the road carry it.",
		"complete": ["Good iron! That'll hold an edge. Here - for the coal, and for the trouble."],
		"reward": {"embers": 400, "items": {&"ember_shard": 2}},
	},
	&"wenna_crows": {
		"giver": &"wenna", "after_talks": 1, "title": "Thieving Crows", "kind": "kill",
		"enemy": &"carrion_crow", "count": 3,
		"summary": "Wenna wants three Carrion Crows dealt with. They keep stealing from her pack.",
		"offer": ["Those blasted crows took a whole string of my best beads. Three of them, I counted. Drop three Carrion Crows for me, and I'll make it worth your while."],
		"remind": "The crows, dear. Three of them. They are still laughing at me.",
		"complete": ["Ha! I heard them hit the ground from here. Take these - the last of my good tonic, and some coin for your trouble."],
		"reward": {"embers": 250, "items": {&"pilgrims_draught": 2, &"relic_locket": 1}},
	},
	&"ilse_resin": {
		"giver": &"ilse", "after_talks": 1, "title": "Resin for the Vials", "kind": "collect",
		"item": &"hollow_resin", "count": 2,
		"summary": "Sister Ilse needs two Hollow Resin. Moths and crows leave it behind.",
		"offer": ["My vials grow thin. If you could find two lumps of Hollow Resin - the moths and the crows leave it behind, I'm told - I could mend a good many things. I would be grateful."],
		"remind": "Two lumps of resin, if you come across them. The moths and the crows leave it behind.",
		"complete": ["Oh, this is lovely - it still glows a little. Thank you. Take these; they are no use to me, but they may be to you."],
		"reward": {"embers": 200, "items": {&"stamina_tonic": 2, &"ash_bandage": 2, &"relic_candle": 1}},
	},
	&"ommen_cantors": {
		"giver": &"ommen", "after_talks": 5, "title": "The Silent Choir", "kind": "kill",
		"enemy": &"candle_cantor", "count": 2,
		"summary": "Ommen asks you to silence two Candle Cantors. They sing in the graveyard behind the road.",
		"offer": ["There is something I should have asked sooner. The graveyard behind the road - the cantors sing there, still, the old liturgy, backwards. I wrote some of those words.", "Silence two of them, if you can. It is not cruelty. It is the only mercy I have left to ask."],
		"remind": "Two cantors. Behind the road, in the graveyard. I can hear them from here when the wind is right.",
		"complete": ["It is quiet. I had forgotten what quiet sounded like.", "Take this. Resin from the first candles we ever lit - I kept it for the right hour."],
		"reward": {"embers": 600, "items": {&"hollow_resin": 3, &"relic_knot": 1}},
	},
	&"aldous_gallery": {
		"giver": &"aldous", "after_talks": 1, "title": "The Gallery Key", "kind": "have",
		"item": &"gallery_key", "count": 1,
		"summary": "Aldous would like the Gallery opened. The key lies below the manor, in the cellar, with whatever guards it.",
		"offer": ["The Gallery has been sealed since the Night. The key went down to the cellar with the last cellarer, and he has not come up again - he is, I am told, rather large now.", "Should you find the cellar - the way is behind the old shelving in the Hall, I believe - and the key, the Gallery door will answer to it."],
		"remind": "The key is below the house, in the cellar. Mind the cellarer; he was never fond of guests.",
		"complete": ["The key! Splendid. The Gallery door will answer to it - go in, Archivist Vesper will be delighted. She has been waiting a very long time to be useful."],
		"reward": {"embers": 500, "items": {&"relic_coin": 1}},
	},
}
const ORDER: Array[StringName] = [&"hobb_scrap", &"wenna_crows", &"ilse_resin", &"ommen_cantors", &"aldous_gallery"]


static func def(id: StringName) -> Dictionary:
	return DEFS.get(id, {})


static func state(id: StringName) -> String:
	return String(GameState.get_flag(StringName("quest_" + String(id)), ""))


static func is_active(id: StringName) -> bool:
	return state(id) == "active"


static func is_done(id: StringName) -> bool:
	return state(id) == "done"


static func kills(id: StringName) -> int:
	return int(GameState.get_flag(StringName("qk_" + String(id)), 0))


## {"have": int, "need": int}
static func progress(id: StringName) -> Dictionary:
	var d := def(id)
	if d.is_empty():
		return {"have": 0, "need": 1}
	var need := int(d.get("count", 1))
	match String(d.kind):
		"collect", "have":
			return {"have": mini(GameState.item_count(d.item), need), "need": need}
		"kill":
			return {"have": mini(kills(id), need), "need": need}
		"flag":
			return {"have": 1 if bool(GameState.get_flag(d.flag, false)) else 0, "need": 1}
	return {"have": 0, "need": need}


static func is_ready(id: StringName) -> bool:
	if not is_active(id):
		return false
	var p := progress(id)
	return p.have >= p.need


static func start(id: StringName) -> void:
	if def(id).is_empty() or state(id) != "":
		return
	GameState.set_flag(StringName("quest_" + String(id)), "active")
	Events.quest_changed.emit(id, "active")


## Pays the reward and closes the quest. Returns false if it is not ready.
static func complete(id: StringName) -> bool:
	if not is_ready(id):
		return false
	var d := def(id)
	if String(d.kind) == "collect":
		GameState.remove_item(d.item, int(d.count))
	var r: Dictionary = d.reward
	if int(r.get("embers", 0)) > 0:
		GameState.add_embers(int(r.embers))
	for item_id in r.get("items", {}):
		GameState.add_item(item_id, int(r.items[item_id]))
	GameState.set_flag(StringName("quest_" + String(id)), "done")
	Events.quest_changed.emit(id, "done")
	return true


## Called for every enemy death.
static func on_enemy_killed(enemy: Node) -> void:
	var data: EnemyData = enemy.get("data") as EnemyData
	if data == null:
		return
	for id in ORDER:
		var d := def(id)
		if String(d.kind) == "kill" and is_active(id) and d.enemy == data.id:
			GameState.set_flag(StringName("qk_" + String(id)), kills(id) + 1)
			Events.quest_changed.emit(id, "progress")


## The quest this NPC can talk about right now: {"id", "mode": "offer"|"remind"|"complete"} or {}.
static func for_npc(npc: StringName, talks: int) -> Dictionary:
	for id in ORDER:
		var d := def(id)
		if d.giver != npc:
			continue
		match state(id):
			"":
				if talks >= int(d.after_talks):
					return {"id": id, "mode": "offer"}
			"active":
				return {"id": id, "mode": "complete" if is_ready(id) else "remind"}
	return {}


## "3 / 3" style progress text for the journal.
static func progress_text(id: StringName) -> String:
	var p := progress(id)
	return "%d / %d" % [p.have, p.need]


static func reward_text(id: StringName) -> String:
	var r: Dictionary = def(id).get("reward", {})
	var parts := PackedStringArray()
	if int(r.get("embers", 0)) > 0:
		parts.append("%d embers" % int(r.embers))
	for item_id in r.get("items", {}):
		var it := Items.get_item(item_id)
		parts.append("%s x%d" % [it.display_name if it else String(item_id), int(r.items[item_id])])
	return ", ".join(parts)
