class_name Shops
extends RefCounted
## What merchants sell. Stock is unlimited (the Pedlar restocks from a bottomless pack);
## prices are in embers. Add a shop by adding an entry and giving an Npc its shop_id.

const STOCK := {
	&"pedlar": [
		{"item": &"ash_bandage", "price": 40},
		{"item": &"stamina_tonic", "price": 90},
		{"item": &"pilgrims_draught", "price": 150},
		{"item": &"forge_scrap", "price": 110},
		{"item": &"hollow_resin", "price": 170},
	],
	## Night-only wanderer on the road: cheaper, and the only place to buy Ember Shards.
	&"lantern": [
		{"item": &"stamina_tonic", "price": 70},
		{"item": &"pilgrims_draught", "price": 120},
		{"item": &"hollow_resin", "price": 140},
		{"item": &"forge_scrap", "price": 90},
		{"item": &"ember_shard", "price": 240},
	],
	## Pell the Salt-Diver, in the Sunken Reliquary.
	&"salt_diver": [
		{"item": &"ash_bandage", "price": 40},
		{"item": &"stamina_tonic", "price": 80},
		{"item": &"pilgrims_draught", "price": 140},
		{"item": &"forge_scrap", "price": 100},
		{"item": &"hollow_resin", "price": 150},
		{"item": &"ember_shard", "price": 260},
	],
}
const NAMES := {&"pedlar": "THE PEDLAR'S WARES", &"lantern": "THE LANTERN-MAN'S WARES", &"salt_diver": "PELL'S WARES"}


static func stock(shop_id: StringName) -> Array:
	if DescentNpcs.SHOPS.has(shop_id):
		return DescentNpcs.SHOPS[shop_id].stock
	return STOCK.get(shop_id, [])


static func shop_name(shop_id: StringName) -> String:
	if DescentNpcs.SHOPS.has(shop_id):
		return DescentNpcs.SHOPS[shop_id].name
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


## What a merchant pays for things you carry. Bought stock fetches 40% of its price; a few drops
## (not sold anywhere) have their own. Keys, notes and relics are never bought.
const SELL_EXTRA := {&"ember_shard": 60, &"penitents_tear": 120}
const SELL_RATE := 0.4


static func buy_price_in(shop_id: StringName, item_id: StringName) -> int:
	for e in stock(shop_id):
		if e.item == item_id:
			return int(e.price)
	return 0


static func buy_price(item_id: StringName) -> int:
	for shop_id in STOCK:
		for e in STOCK[shop_id]:
			if e.item == item_id:
				return int(e.price)
	return 0


static func sell_price(item_id: StringName) -> int:
	if Items.get_item(item_id) == null:
		return 0
	if SELL_EXTRA.has(item_id):
		return int(SELL_EXTRA[item_id])
	return int(buy_price(item_id) * SELL_RATE)


## Everything in the pack a merchant would take: [{"item": id, "price": int}].
static func sellable() -> Array:
	var out := []
	for id in Items.IDS:
		if GameState.item_count(id) > 0 and sell_price(id) > 0:
			out.append({"item": id, "price": sell_price(id)})
	return out


static func sell(item_id: StringName) -> Dictionary:
	var price := sell_price(item_id)
	var item := Items.get_item(item_id)
	if item == null or price <= 0:
		return {"ok": false, "msg": "She will not take that."}
	if GameState.item_count(item_id) <= 0:
		return {"ok": false, "msg": "You have none."}
	GameState.remove_item(item_id, 1)
	GameState.add_embers(price)
	return {"ok": true, "msg": "Sold %s for %d." % [item.display_name, price]}
