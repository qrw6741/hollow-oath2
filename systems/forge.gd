class_name Forge
extends RefCounted
## What the Blacksmith and the Vial-Keeper do, as pure rules (the menu only shows them).
##   - Upgrade a weapon (+1..+5: more damage) or an armour (+1..+5: less damage taken):
##     embers + Forge Scrap.
##   - Forge a new weapon / armour: embers, and for the great ones a relic you must be
##     carrying (it is shown to the smith, not consumed).
##   - Upgrade the Ember Vials (levels 1..5: stronger heal; extra vials at 2 and 5):
##     embers + Hollow Resin.
## Every function that changes anything spends only on success.

const MAX_LEVEL := 5
const SCRAP := &"forge_scrap"
const RESIN := &"hollow_resin"
const WEAPON_UPGRADES := [
	{"embers": 150, "mat": 1}, {"embers": 300, "mat": 2}, {"embers": 500, "mat": 3},
	{"embers": 800, "mat": 4}, {"embers": 1200, "mat": 6}]
const ARMOR_UPGRADES := [
	{"embers": 120, "mat": 1}, {"embers": 240, "mat": 2}, {"embers": 400, "mat": 3},
	{"embers": 640, "mat": 4}, {"embers": 960, "mat": 6}]
const VIAL_UPGRADES := [
	{"embers": 200, "mat": 1}, {"embers": 400, "mat": 1}, {"embers": 700, "mat": 2},
	{"embers": 1000, "mat": 3}, {"embers": 1500, "mat": 4}]
const VIAL_HEAL_PER_LEVEL := 6.0

## Things the smith can make. "relic" (optional) must be in the pack.
const RECIPES := {
	&"wayfarers_rapier": {"kind": "weapon", "embers": 500, "mat": 2},
	&"kingsfall_greatsword": {"kind": "weapon", "embers": 900, "mat": 4},
	&"toll_hammer": {"kind": "weapon", "embers": 600, "mat": 3, "relic": &"warden_bell_shard"},
	&"marshals_lance": {"kind": "weapon", "embers": 800, "mat": 3, "relic": &"marshals_crest"},
	&"tide_sabre": {"kind": "weapon", "embers": 700, "mat": 3, "relic": &"canon_seal"},
	&"cinderbrand": {"kind": "weapon", "embers": 1500, "mat": 6, "relic": &"cinder_heart"},
	&"ashfall_pike": {"kind": "weapon", "embers": 1800, "mat": 7, "relic": &"ashfall_seal"},
	&"pilgrim_coat": {"kind": "armor", "embers": 350, "mat": 2},
	&"penitent_shroud": {"kind": "armor", "embers": 600, "mat": 3, "relic": &"penitents_tear"},
	&"canons_mail": {"kind": "armor", "embers": 750, "mat": 4, "relic": &"canon_seal"},
	&"marshal_plate": {"kind": "armor", "embers": 1000, "mat": 6, "relic": &"marshals_crest"},
}


# ------------------------------------------------------------------ queries

static func recipe(id: StringName) -> Dictionary:
	return RECIPES.get(id, {})


static func owns(kind: String, id: StringName) -> bool:
	return GameState.owns_weapon(id) if kind == "weapon" else GameState.owns_armor(id)


static func level_of(kind: String, id: StringName) -> int:
	return GameState.weapon_level(id) if kind == "weapon" else GameState.armor_level(id)


## What the smith lists for a tab: everything owned, plus everything he knows how to make.
static func entries(kind: String) -> Array[StringName]:
	var out: Array[StringName] = []
	var ids: Array[StringName] = Weapons.IDS if kind == "weapon" else Armors.IDS
	for id in ids:
		if owns(kind, id) or (RECIPES.has(id) and RECIPES[id].kind == kind):
			out.append(id)
	return out


## Cost of the next upgrade: {"embers", "mat"} or {} at the maximum level.
static func upgrade_cost(kind: String, id: StringName) -> Dictionary:
	var lv := level_of(kind, id)
	if lv >= MAX_LEVEL:
		return {}
	return (WEAPON_UPGRADES if kind == "weapon" else ARMOR_UPGRADES)[lv]


static func vial_cost() -> Dictionary:
	var lv := GameState.flask_level
	return {} if lv >= MAX_LEVEL else VIAL_UPGRADES[lv]


static func vial_heal_bonus(level: int) -> float:
	return VIAL_HEAL_PER_LEVEL * clampi(level, 0, MAX_LEVEL)


static func vial_extra(level: int) -> int:
	return (1 if level >= 2 else 0) + (1 if level >= 5 else 0)


# ------------------------------------------------------------------ infusions
## Hobb can soak a weapon in a status. Stored as world flag `infuse_<weapon>` (no save change).
## Re-infusing replaces the old one; `&""` cleans the weapon (free).
const INFUSE_COST := {"embers": 300, "mat": 2}   ## embers + Hollow Resin
const INFUSE_AMOUNT := 28.0


static func infusion_of(weapon_id: StringName) -> StringName:
	return StringName(str(GameState.get_flag(StringName("infuse_" + String(weapon_id)), "")))


## The status a weapon's hits carry right now: {"kind": StringName, "amount": float}.
static func effective_status(w: WeaponData) -> Dictionary:
	if w == null:
		return {"kind": &"", "amount": 0.0}
	var inf := infusion_of(w.id)
	if inf != &"":
		return {"kind": inf, "amount": maxf(INFUSE_AMOUNT, w.status_amount if w.status == inf else 0.0)}
	return {"kind": w.status, "amount": w.status_amount}


static func infuse(weapon_id: StringName, kind: StringName) -> Dictionary:
	if not owns("weapon", weapon_id):
		return {"ok": false, "msg": "You do not own that."}
	if kind == &"":
		GameState.set_flag(StringName("infuse_" + String(weapon_id)), "")
		Events.loadout_changed.emit()
		return {"ok": true, "msg": "The blade is cleaned."}
	if not StatusFx.is_kind(kind):
		return {"ok": false, "msg": "He knows no such oil."}
	if infusion_of(weapon_id) == kind:
		return {"ok": false, "msg": "Already soaked in that."}
	var r := _pay(INFUSE_COST, RESIN)
	if not r.ok:
		return r
	GameState.set_flag(StringName("infuse_" + String(weapon_id)), String(kind))
	Events.loadout_changed.emit()
	return {"ok": true, "msg": "Soaked in %s." % StatusFx.name_of(kind)}


## Next infusion in the cycle none -> bleed -> poison -> burn -> frost -> none.
static func next_infusion(weapon_id: StringName) -> StringName:
	var cur := infusion_of(weapon_id)
	if cur == &"":
		return StatusFx.KINDS[0]
	var i := StatusFx.KINDS.find(cur)
	return &"" if i < 0 or i + 1 >= StatusFx.KINDS.size() else StatusFx.KINDS[i + 1]


# ------------------------------------------------------------------ actions

static func _pay(c: Dictionary, material: StringName) -> Dictionary:
	if GameState.embers < int(c.embers):
		return {"ok": false, "msg": "Not enough embers."}
	if GameState.item_count(material) < int(c.mat):
		return {"ok": false, "msg": "Not enough %s." % Items.get_item(material).display_name}
	GameState.spend_embers(int(c.embers))
	GameState.remove_item(material, int(c.mat))
	return {"ok": true}


static func upgrade(kind: String, id: StringName) -> Dictionary:
	if not owns(kind, id):
		return {"ok": false, "msg": "You do not own that."}
	var c := upgrade_cost(kind, id)
	if c.is_empty():
		return {"ok": false, "msg": "Already at its finest."}
	var r := _pay(c, SCRAP)
	if not r.ok:
		return r
	GameState.set_gear_level(kind, id, level_of(kind, id) + 1)
	Events.loadout_changed.emit()
	return {"ok": true, "msg": "Upgraded to +%d." % level_of(kind, id)}


static func make(id: StringName) -> Dictionary:
	var rc := recipe(id)
	if rc.is_empty():
		return {"ok": false, "msg": "He does not know how to make that."}
	var kind: String = rc.kind
	if owns(kind, id):
		return {"ok": false, "msg": "You already have it."}
	if rc.has("relic") and GameState.item_count(rc.relic) <= 0:
		return {"ok": false, "msg": "Bring the %s." % Items.get_item(rc.relic).display_name}
	var r := _pay(rc, SCRAP)
	if not r.ok:
		return r
	GameState.grant_gear(kind, id)
	Events.loadout_changed.emit()
	return {"ok": true, "msg": "Forged."}


static func upgrade_vials() -> Dictionary:
	var c := vial_cost()
	if c.is_empty():
		return {"ok": false, "msg": "The vials can hold no more."}
	var r := _pay(c, RESIN)
	if not r.ok:
		return r
	GameState.flask_level += 1
	Events.loadout_changed.emit()
	return {"ok": true, "msg": "Vials upgraded to +%d." % GameState.flask_level}
