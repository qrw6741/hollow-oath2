class_name Alchemy
extends RefCounted
## Potion crafting from the ALCHEMY tab of the pack. Each recipe turns carried materials (and a
## few embers) into one potion that gives a timed buff when drunk (see Buffs).

const RECIPES := {
	&"potion_might": {"mats": {&"hollow_resin": 2, &"ember_shard": 1}, "embers": 100},
	&"potion_ward": {"mats": {&"forge_scrap": 2, &"ash_bandage": 1}, "embers": 100},
	&"potion_vigor": {"mats": {&"pilgrims_draught": 2, &"stamina_tonic": 1}, "embers": 150},
	&"potion_swift": {"mats": {&"stamina_tonic": 2, &"hollow_resin": 1}, "embers": 80},
	&"potion_greed": {"mats": {&"ember_shard": 2, &"forge_scrap": 1}, "embers": 200},
	&"potion_resolve": {"mats": {&"penitents_tear": 1, &"ash_bandage": 1}, "embers": 120},
	&"potion_focus": {"mats": {&"hollow_resin": 1, &"pilgrims_draught": 1, &"ember_shard": 1}, "embers": 150},
}
const ORDER: Array[StringName] = [&"potion_might", &"potion_ward", &"potion_vigor", &"potion_swift", &"potion_greed", &"potion_resolve", &"potion_focus"]


static func recipe(id: StringName) -> Dictionary:
	return RECIPES.get(id, {})


static func missing(id: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	var r := recipe(id)
	if r.is_empty():
		return PackedStringArray(["no such recipe"])
	for m in r.mats:
		var have := GameState.item_count(m)
		if have < int(r.mats[m]):
			out.append("%s %d/%d" % [Items.get_item(m).display_name, have, int(r.mats[m])])
	if GameState.embers < int(r.embers):
		out.append("%d embers" % int(r.embers))
	return out


static func can_craft(id: StringName) -> bool:
	var item := Items.get_item(id)
	if item == null:
		return false
	return missing(id).is_empty() and GameState.item_count(id) < item.max_stack


static func ingredients_text(id: StringName) -> String:
	var r := recipe(id)
	var parts := PackedStringArray()
	for m in r.mats:
		parts.append("%d %s" % [int(r.mats[m]), Items.get_item(m).display_name])
	parts.append("%d embers" % int(r.embers))
	return ", ".join(parts)


## Returns {"ok", "msg"}.
static func craft(id: StringName) -> Dictionary:
	var r := recipe(id)
	var item := Items.get_item(id)
	if r.is_empty() or item == null:
		return {"ok": false, "msg": "You do not know that recipe."}
	if GameState.item_count(id) >= item.max_stack:
		return {"ok": false, "msg": "You cannot carry more %s." % item.display_name}
	var lack := missing(id)
	if not lack.is_empty():
		return {"ok": false, "msg": "Missing: %s" % ", ".join(lack)}
	for m in r.mats:
		GameState.remove_item(m, int(r.mats[m]))
	GameState.spend_embers(int(r.embers))
	GameState.add_item(id, 1)
	Audio.sfx(&"coin", -4.0)
	return {"ok": true, "msg": "Brewed %s." % item.display_name}
