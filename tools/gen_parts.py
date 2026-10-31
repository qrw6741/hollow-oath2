#!/usr/bin/env python3
"""Four more regions after the Drowned Belfry: Bleeding Gardens, Iron Orrery, Sunken Basilica,
Crownless Citadel. Generates each part's boss (attacks, data, scene) and relic. Levels are built
by `parts()` in tools/levels/gen_side_levels.py from PARTS below.
Run: python3 tools/gen_parts.py"""
import os, sys, io, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G

# id, level name, boss node, boss id, boss name, lore, hp, poise, embers, style, music pitch,
# relic (id, name, desc, colour), attacks [(id, name, anim, startup, dmg, w, status)]
PARTS = [
    dict(key="gardens", level="bleeding_gardens", title="The Bleeding Gardens", node="Thornmother", boss="thornmother",
         name="Elsbet, the Thornmother", lore="She tended the Crown's gardens until the roses learned her name. She feeds them now, and they feed her back.",
         hp=1300, poise=130, embers=4600, style=9, pitch=0.76, status="poison",
         relic=("relic_briar", "Briar Locket", "A locket grown through with thorn. Focus builds 40% faster.", "Color(0.7, 0.2, 0.3, 1)"),
         arena_text="THE GARDEN GOES TO SEED"),
    dict(key="orrery", level="iron_orrery", title="The Iron Orrery", node="Orrerist", boss="orrerist",
         name="Calloway, the Orrerist", lore="He built a machine to count the days until the Crown's return. It stopped. He keeps winding it.",
         hp=1450, poise=160, embers=5200, style=10, pitch=0.74, status="bleed",
         relic=("relic_gear", "Orrery Gear", "A brass gear still ticking. Your weapon's status builds 50% faster.", "Color(0.85, 0.65, 0.3, 1)"),
         arena_text="THE CLOCK STOPS"),
    dict(key="basilica", level="sunken_basilica", title="The Sunken Basilica", node="Bishop", boss="drowned_bishop",
         name="Bishop Anselm, the Drowned", lore="He preached until the nave flooded and kept preaching. The congregation is still there. They have stopped breathing; they have not stopped listening.",
         hp=1650, poise=170, embers=6000, style=11, pitch=0.7, status="frost",
         relic=("relic_chalice", "Drowned Chalice", "A chalice that never empties. Ember Vials heal 60% more.", "Color(0.55, 0.78, 0.85, 1)"),
         arena_text="THE SERMON ENDS"),
    dict(key="citadel", level="crownless_citadel", title="The Crownless Citadel", node="Crownless", boss="crownless_king",
         name="The Crownless King", lore="The throne of Vaelmoor, and what sits on it. He was never crowned. He was only ever promised.",
         hp=2200, poise=200, embers=9000, style=12, pitch=0.66, status="burn",
         relic=("relic_oathbreaker", "Oathbreaker's Ring", "A ring snapped in two and bound again. A parry gives 30 extra focus.", "Color(0.9, 0.9, 0.95, 1)"),
         arena_text="THE THRONE IS EMPTY"),
]
ATTACKS = [  # per part: (suffix, name, anim, startup, active, recovery, dmg, kb, parry, hitbox, off, extra)
    [("a", "Rooted Swipe", "sweep", 24, 6, 28, 26, 1), ("b", "Thorn Haul", "smash", 30, 6, 32, 32, 1), ("c", "Seed Volley", "throw", 24, 2, 28, 16, 0), ("d", "Bloom", "leap", 46, 6, 36, 38, 0)],
    [("a", "Piston Strike", "smash", 32, 6, 34, 34, 1), ("b", "Gear Sweep", "sweep", 26, 7, 30, 28, 0), ("c", "Cog Hurl", "throw", 26, 2, 30, 18, 0), ("d", "Hour Drop", "leap", 48, 6, 38, 40, 0)],
    [("a", "Pulpit Blow", "smash", 30, 6, 32, 34, 1), ("b", "Tidal Sermon", "sweep", 26, 7, 30, 30, 0), ("c", "Hymn Bolt", "throw", 24, 2, 28, 18, 0), ("d", "Flood", "leap", 50, 7, 40, 42, 0)],
    [("a", "Royal Cut", "slash", 16, 5, 22, 30, 1), ("b", "Throne Lunge", "lunge", 18, 6, 30, 34, 0), ("c", "Edict", "throw", 22, 2, 26, 20, 0), ("d", "Abdication", "leap", 44, 6, 34, 46, 0)],
]
for P, A in zip(PARTS, ATTACKS):
    ids = []
    for (suf, nm, anim, su, act, rec, dmg, parry) in A:
        i = f"{P['key']}_{suf}"; ids.append(i)
        kw = dict(amin=0, amax=70)
        if anim == "throw":
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (90, -40), bool(parry), (4, 4), (0, -34), proj=230.0, amin=90, amax=360, w=1.1, status=(P["status"], 50), hs=0.05, shake=2.0)
        elif anim == "leap":
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (220, -160), False, (130, 34), (0, -14), track=False, amin=100, amax=330, w=1.0, shake=10.0, status=(P["status"], 60))
        elif anim == "lunge":
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (180, -70), bool(parry), (48, 30), (30, -18), amin=40, amax=220, w=1.0, lunge=240, lstart=14, lframes=8, track=False, shake=4.0)
        elif anim == "slash":
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (150, -60), bool(parry), (60, 32), (32, -20), amin=0, amax=70, w=1.3, lunge=70, lstart=12, lframes=4)
        elif anim == "sweep":
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (200, -70), False, (90, 30), (36, -20), amin=0, amax=78, w=0.9, status=(P["status"], 35))
        else:
            G.attack(i, f"{P['name'].split(',')[0]} - {nm}", anim, su, act, rec, dmg, (180, -110), bool(parry), (60, 44), (30, -24), amin=0, amax=66, lunge=45, lstart=28, lframes=6, shake=7.0, status=(P["status"], 35))
    G.enemy(P["boss"], P["name"], P["lore"], ids[:3], P["hp"], P["poise"], 56, P["embers"], P["relic"][0], "ember_shard")
    G.boss(P["node"], P["boss"], P["boss"], ids, P["style"], hurt=(28, 54), music_pitch=P["pitch"])
    rid, rn, rd, rc = P["relic"]
    open(f"{R}/data/items/{rid}.tres", "w").write(f'''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/items/item_data.gd" id="1_item"]

[resource]
script = ExtResource("1_item")
id = &"{rid}"
display_name = "{rn}"
description = "{rd}"
kind = 1
effect = 0
effect_amount = 0.0
max_stack = 1
icon_color = {rc}
''')
print("parts ok")
