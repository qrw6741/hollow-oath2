#!/usr/bin/env python3
"""Generates the talisman items (data/items/tal_*.tres), the potion items (potion_*.tres) and
systems/talisman_data.gd. Run: python3 tools/gen_talismans.py
Talismans are KEY-kind items (unique); wearing them is handled by systems/talismans.gd.
Effects: multiplicative names damage, damage_taken, max_health, stamina_regen, run_speed,
ember_gain, flask_heal, focus_gain, weapon_status; additive names status_resist, parry_focus."""
import os
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# id, title, source (boss_id or "elite"), effects, lore, colour
TAL = [
 ("tal_warden", "Warden's Toll Charm", "bell_warden", {"focus_gain": 1.15, "parry_focus": 6.0}, "A sliver of the great bell, strung on wire. It rings once when you are struck, and you remember to strike back.", "Color(0.8, 0.72, 0.4, 1)"),
 ("tal_marshal", "Marshal's Crest-Pin", "hollow_marshal", {"damage_taken": 0.92, "max_health": 1.06}, "Orren's pin. He wore it over the heart, where the oath was heaviest.", "Color(0.72, 0.72, 0.8, 1)"),
 ("tal_cellarer", "Cellarer's Ring", "cellarer", {"stamina_regen": 1.15}, "A servant's ring. It never tires, because it was never allowed to.", "Color(0.7, 0.62, 0.5, 1)"),
 ("tal_sexton", "Sexton's Grave-Nail", "gravewarden", {"ember_gain": 1.12, "status_resist": 0.08}, "A coffin nail, bent. The Sexton took payment from the dead and kept it very well.", "Color(0.6, 0.7, 0.8, 1)"),
 ("tal_cinder", "Cinder Ash-Mark", "mother_cinder", {"damage": 1.08, "weapon_status": 1.15}, "A thumbprint in warm ash. Press it to your blade and it remembers burning.", "Color(0.9, 0.5, 0.25, 1)"),
 ("tal_ashfall", "Ashfall Oath-Bar", "ser_ashfall", {"damage": 1.1, "damage_taken": 0.95}, "The only guardsman who refused to swear left this behind. It is heavier than it looks.", "Color(0.8, 0.8, 0.85, 1)"),
 ("tal_canon", "Canon's Tear", "drowned_canon", {"flask_heal": 1.15, "max_health": 1.05}, "Wax and salt. The Canon wept it for every vow he sealed.", "Color(0.6, 0.8, 0.9, 1)"),
 ("tal_abbot", "Abbot's Salt Charm", "salt_abbot", {"status_resist": 0.12, "flask_heal": 1.1}, "A pinch of salt in a glass bead. It keeps rot out of the wound.", "Color(0.75, 0.9, 0.95, 1)"),
 ("tal_vess", "Vess's Last Link", "gaoler_vess", {"damage_taken": 0.9, "status_resist": 0.05}, "One link of chain, polished by a hand that counted it every hour.", "Color(0.62, 0.64, 0.7, 1)"),
 ("tal_brand", "Brand's Slag Nugget", "foundrymaster_brand", {"damage": 1.12, "max_health": 1.04}, "A fist of cooled slag. Still warm at the core. It wants to be struck against something.", "Color(1.0, 0.5, 0.2, 1)"),
 ("tal_regent", "Regent's Hollow Shard", "hollow_regent", {"parry_focus": 10.0, "focus_gain": 1.15}, "A splinter of the crown. It hums when you turn aside a blow meant to kill you.", "Color(0.85, 0.72, 0.3, 1)"),
 ("tal_ringer", "Ringer's Bellflower", "last_ringer", {"ember_gain": 1.2, "stamina_regen": 1.1}, "A bronze flower shaped like a bell. It rang once, for the last funeral, and has been silent since.", "Color(0.88, 0.7, 0.35, 1)"),
 ("tal_thornmother", "Thornmother's Seed", "thornmother", {"weapon_status": 1.25, "damage": 1.05}, "A seed that has not decided what to grow into. It leans toward wounds.", "Color(0.7, 0.2, 0.3, 1)"),
 ("tal_orrerist", "Orrerist's Mainspring", "orrerist", {"run_speed": 1.08, "stamina_regen": 1.15}, "A mainspring wound as tight as it will go and not a turn further.", "Color(0.85, 0.65, 0.3, 1)"),
 ("tal_bishop", "Bishop's Wafer", "drowned_bishop", {"flask_heal": 1.25, "status_resist": 0.1}, "A wafer pressed in silver. It was never eaten. Perhaps that is why it still holds.", "Color(0.55, 0.78, 0.85, 1)"),
 ("tal_king", "Crownless Sigil", "crownless_king", {"damage": 1.15, "damage_taken": 0.92, "max_health": 1.08}, "A sigil with no name beneath it. Whoever carries it is promised something. It does not say what.", "Color(0.92, 0.92, 0.98, 1)"),
 # Smaller ones that strong (elite) enemies may drop
 ("tal_iron_bead", "Iron Bead", "elite", {"damage_taken": 0.97}, "A guard's prayer bead. Plain iron, rubbed smooth.", "Color(0.6, 0.6, 0.65, 1)"),
 ("tal_swift_feather", "Swift Feather", "elite", {"run_speed": 1.05}, "A crow's feather, black and oddly light.", "Color(0.3, 0.3, 0.4, 1)"),
 ("tal_ember_bead", "Ember Bead", "elite", {"ember_gain": 1.08}, "A bead of cooled amber with a spark in it.", "Color(0.9, 0.6, 0.2, 1)"),
 ("tal_mender", "Mender's Thread", "elite", {"flask_heal": 1.08}, "Red thread, wound on a bone needle.", "Color(0.8, 0.3, 0.3, 1)"),
 ("tal_keen_edge", "Keen Whetstone", "elite", {"damage": 1.04}, "A worn whetstone. Every blade it touched came away sharper.", "Color(0.7, 0.75, 0.8, 1)"),
 ("tal_hardy", "Hardy Knot", "elite", {"max_health": 1.04}, "A knotted cord. It is the kind of knot that will not come undone.", "Color(0.7, 0.55, 0.4, 1)"),
 ("tal_steady", "Steady Pebble", "elite", {"stamina_regen": 1.08}, "A river pebble, perfectly round. Holding it slows your breathing.", "Color(0.6, 0.7, 0.65, 1)"),
]
POTIONS = [  # id, name, desc, colour
 ("potion_might", "Draught of Might", "Your blows land 20% harder for four minutes.", "Color(0.9, 0.35, 0.25, 1)"),
 ("potion_ward", "Ward Tonic", "You take 20% less damage for four minutes.", "Color(0.5, 0.6, 0.85, 1)"),
 ("potion_vigor", "Vigor Elixir", "Your maximum health rises by 25% for five minutes.", "Color(0.85, 0.3, 0.45, 1)"),
 ("potion_swift", "Swiftfoot Brew", "You run 15% faster and your stamina returns 50% faster for three minutes.", "Color(0.5, 0.85, 0.6, 1)"),
 ("potion_greed", "Embergreed Draught", "Foes pay 50% more embers for five minutes.", "Color(0.95, 0.7, 0.25, 1)"),
 ("potion_resolve", "Resolve Salve", "You resist an extra 50% of status buildup for four minutes.", "Color(0.7, 0.55, 0.85, 1)"),
 ("potion_focus", "Focus Tincture", "Focus builds 50% faster and a parry gives 8 extra focus for four minutes.", "Color(0.45, 0.55, 0.95, 1)"),
]
DUR = {"potion_might": 240, "potion_ward": 240, "potion_vigor": 300, "potion_swift": 180, "potion_greed": 300, "potion_resolve": 240, "potion_focus": 240}


def item(id_, name, desc, col, kind, effect=0, amount=0.0, stack=1):
    open(f"{R}/data/items/{id_}.tres", "w").write(f'''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/items/item_data.gd" id="1_item"]

[resource]
script = ExtResource("1_item")
id = &"{id_}"
display_name = "{name}"
description = "{desc}"
kind = {kind}
effect = {effect}
effect_amount = {amount}
max_stack = {stack}
icon_color = {col}
''')


def fmt(d):
    return "{" + ", ".join(f'"{k}": {v}' for k, v in d.items()) + "}"


defs = []
for id_, title, src, eff, lore, col in TAL:
    item(id_, title, lore, col, 1)
    defs.append(f'\t&"{id_}": {{"title": "{title}", "source": &"{src}", "effects": {fmt(eff)}}},')
for id_, name, desc, col in POTIONS:
    item(id_, name, desc, col, 0, effect=5, amount=float(DUR[id_]), stack=9)
ids = ", ".join(f'&"{t[0]}"' for t in TAL)
elite = ", ".join(f'&"{t[0]}"' for t in TAL if t[2] == "elite")
potions = ", ".join(f'&"{p[0]}"' for p in POTIONS)
open(f"{R}/systems/talisman_data.gd", "w").write(f'''class_name TalismanData
extends RefCounted
## GENERATED by tools/gen_talismans.py. Do not edit by hand.
## source = the boss_id that always drops it (once), or &"elite" for the pool strong enemies roll from.

const DEFS := {{
{chr(10).join(defs)}
}}
const IDS: Array[StringName] = [{ids}]
const ELITE_POOL: Array[StringName] = [{elite}]
const POTION_IDS: Array[StringName] = [{potions}]
''')
print("talismans ok", len(TAL), len(POTIONS))
