class_name Shops
extends RefCounted
## What merchants sell. Stock is unlimited (the Pedlar restocks from a bottomless pack);
## prices are in embers. Add a shop by adding an entry and giving an Npc its shop_id.

const STOCK := {
	&"pedlar": [
		{"item": &"ash_bandage", "price": 40},
		{"item": &"stamina_tonic", "price": 90},
		{"item": &"pilgrims_draught", "price": 150},
	],
}
const NAMES := {&"pedlar": "THE PEDLAR'S WARES"}


static func stock(shop_id: StringName) -> Array:
	return STOCK.get(shop_id, [])


static func shop_name(shop_id: StringName) -> String:
	return NAMES.get(shop_id, "WARES")


## Result of trying to buy: {"ok": bool, "msg": String}. Spends embers only on success.
static func buy(shop_id: StringName, item_id: StringName) -> Dictionary:
	var entry := {}
	for e in stock(shop_id):
		if e.item == item_id:
			entry = e
	var item := Items.get_item(item_id)
	if entry.is_empty() or item == null:
		return {"ok": false, "msg": "Not for sale."}
	if GameState.item_count(item_id) >= item.max_stack:
		return {"ok": false, "msg": "You cannot carry any more %s." % item.display_name}
	if not GameState.spend_embers(int(entry.price)):
		return {"ok": false, "msg": "Not enough embers."}
	GameState.add_item(item_id, 1)
	return {"ok": true, "msg": "Bought %s." % item.display_name}
