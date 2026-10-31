#!/usr/bin/env python3
"""Generates the Hollow Keep's three bosses (Gaoler Vess, Foundrymaster Brand, the Hollow Regent):
attacks, enemy data, boss scenes, and their relic drops. The level is in tools/levels/gen_side_levels.py.
Run: python3 tools/gen_keep.py"""
import os, sys, io, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G

# --- Gaoler Vess, the Chain-Warden: long reach, chains, wide sweeps.
G.attack("vess_whip", "Vess - Chain Whip", "sweep", 24, 6, 28, 24, (190, -60), False, (96, 26), (38, -22), amin=0, amax=84, w=1.0)
G.attack("vess_haul", "Vess - Hauling Blow", "smash", 32, 6, 34, 34, (180, -120), True, (58, 44), (30, -24), amin=0, amax=64, lunge=50, lstart=28, lframes=6)
G.attack("vess_hurl", "Vess - Shackle Hurl", "throw", 26, 2, 30, 18, (90, -40), True, (4, 4), (0, -34), proj=210.0, amin=80, amax=340, w=1.1, hs=0.06, shake=2.0)
G.attack("vess_drag", "Vess - Dragging Lunge", "lunge", 22, 8, 34, 30, (200, -80), False, (52, 34), (30, -18), amin=60, amax=240, w=0.9, lunge=210, lstart=18, lframes=8, track=False, shake=5.0)
G.enemy("gaoler_vess", "Gaoler Vess, the Chain-Warden", "She kept the Keep's cells for the Crown. No one was ever released. She wrote every sentence in the chain: one link per year.",
        ["vess_whip", "vess_haul", "vess_hurl"], 900, 110, 58, 3000, "relic_shackle", "ember_shard")
G.boss("GaolerVess", "gaoler_vess", "gaoler_vess", ["vess_whip", "vess_haul", "vess_hurl", "vess_drag"], 5, hurt=(26, 52), music_pitch=0.9)

# --- Foundrymaster Brand: heavy, slow, burning.
G.attack("brand_hammer", "Brand - Anvil Fall", "smash", 38, 7, 38, 40, (200, -130), True, (66, 48), (32, -26), amin=0, amax=70, lunge=40, lstart=34, lframes=5, shake=8.0, status=("burn", 40))
G.attack("brand_sweep", "Brand - Furnace Sweep", "sweep", 30, 8, 32, 32, (210, -70), False, (90, 32), (36, -20), amin=0, amax=80, w=0.9, status=("burn", 35))
G.attack("brand_fling", "Brand - Slag Fling", "throw", 30, 2, 32, 18, (90, -40), True, (4, 4), (0, -34), proj=170.0, amin=90, amax=340, w=1.1, status=("burn", 55), hs=0.06, shake=2.0)
G.attack("brand_pour", "Brand - Molten Pour", "leap", 50, 7, 40, 40, (220, -160), False, (130, 34), (0, -14), track=False, amin=100, amax=320, w=1.0, shake=9.0, status=("burn", 70))
G.enemy("foundrymaster_brand", "Foundrymaster Brand", "He cast the Keep's chains, then its bells, then its crowns. The furnace has not gone out. He has not left it to check.",
        ["brand_hammer", "brand_sweep", "brand_fling"], 1050, 130, 50, 3600, "relic_slag", "ember_shard")
G.boss("FoundrymasterBrand", "foundrymaster_brand", "foundrymaster_brand", ["brand_hammer", "brand_sweep", "brand_fling", "brand_pour"], 6, hurt=(30, 56), music_pitch=0.8)

# --- The Hollow Regent: fast, a crown of hollow light.
G.attack("reg_cut", "Regent - Crown Cut", "slash", 16, 5, 22, 26, (150, -60), True, (60, 32), (32, -20), amin=0, amax=70, w=1.3, lunge=70, lstart=12, lframes=4)
G.attack("reg_thrust", "Regent - Sovereign Thrust", "lunge", 18, 6, 30, 30, (180, -70), False, (48, 30), (30, -18), amin=40, amax=220, w=1.0, lunge=240, lstart=14, lframes=8, track=False, shake=4.0)
G.attack("reg_volley", "Regent - Hollow Volley", "throw", 24, 2, 26, 18, (80, -40), True, (4, 4), (0, -34), proj=260.0, amin=90, amax=380, w=1.2, hs=0.05, shake=2.0)
G.attack("reg_break", "Regent - The Oath Breaks", "leap", 44, 6, 34, 40, (230, -160), False, (140, 34), (0, -14), track=False, amin=100, amax=340, w=1.1, shake=10.0)
G.enemy("hollow_regent", "The Hollow Regent", "The last king the Keep crowned, and the first it hollowed. He still holds court. The court is the oath.",
        ["reg_cut", "reg_thrust", "reg_volley"], 1400, 150, 66, 5000, "relic_regent", "ember_shard")
G.boss("HollowRegent", "hollow_regent", "hollow_regent", ["reg_cut", "reg_thrust", "reg_volley", "reg_break"], 7, hurt=(26, 54), music_pitch=0.75)

# --- Verger Tolland, the Last Ringer (Drowned Belfry)
G.attack("ring_toll", "Ringer - Great Toll", "smash", 34, 6, 36, 34, (190, -120), True, (62, 46), (30, -24), amin=0, amax=68, lunge=45, lstart=30, lframes=5, shake=9.0)
G.attack("ring_clapper", "Ringer - Clapper Sweep", "sweep", 26, 7, 30, 28, (200, -60), False, (88, 30), (36, -20), amin=0, amax=78, w=0.9)
G.attack("ring_peal", "Ringer - Peal", "throw", 26, 2, 28, 16, (80, -40), True, (4, 4), (0, -34), proj=230.0, amin=90, amax=360, w=1.2, hs=0.05, shake=2.0)
G.attack("ring_deluge", "Ringer - Falling Bell", "leap", 48, 6, 38, 38, (220, -160), False, (120, 34), (0, -14), track=False, amin=100, amax=320, w=1.0, shake=10.0)
G.enemy("last_ringer", "Verger Tolland, the Last Ringer", "He rang the Belfry at every vow, then at every funeral, then only for himself. The bell has no clapper now. He is the clapper.",
        ["ring_toll", "ring_clapper", "ring_peal"], 1200, 120, 56, 4200, "relic_clapper", "ember_shard")
G.boss("LastRinger", "last_ringer", "last_ringer", ["ring_toll", "ring_clapper", "ring_peal", "ring_deluge"], 8, hurt=(28, 54), music_pitch=0.78)

# --- relic items
def item(id_, name, desc, col):
    open(f"{R}/data/items/{id_}.tres", "w").write(f'''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/items/item_data.gd" id="1_item"]

[resource]
script = ExtResource("1_item")
id = &"{id_}"
display_name = "{name}"
description = "{desc}"
kind = 1
effect = 0
effect_amount = 0.0
max_stack = 1
icon_color = {col}
''')
item("relic_shackle", "Gaoler's Shackle", "An iron cuff with a long chain. Resist 30% of every status buildup.", "Color(0.62, 0.64, 0.7, 1)")
item("relic_slag", "Foundry Ladle", "A ladle fused to its last pour. Ember Vials heal 40% more.", "Color(1.0, 0.55, 0.2, 1)")
item("relic_regent", "Hollow Crown", "A circlet with no head to wear it. A parry gives 20 extra focus.", "Color(0.85, 0.72, 0.3, 1)")
item("relic_clapper", "Bell Clapper", "The tongue of a bell that rang itself dumb. Foes pay 35% more embers.", "Color(0.88, 0.7, 0.35, 1)")
print("keep ok")
