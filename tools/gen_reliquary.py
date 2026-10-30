#!/usr/bin/env python3
"""Generates the Sunken Reliquary's cast: Drowned Pilgrim, Reliquary Lurker (ambusher), the Salt
Abbot (boss) with their attacks, data and scenes. The level is in tools/levels/gen_side_levels.py.
Run: python3 tools/gen_reliquary.py"""
import os, sys, io, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G
    import gen_combat_depth as C

# --- attacks
G.attack("pilgrim_drag", "Drowned Pilgrim - Dragging Blow", "overhead", 26, 5, 30, 22, (110, -80), True, (36, 36), (22, -18), amin=0, amax=46, status=("frost", 28), lunge=40, lstart=22, lframes=6, hs=0.08, shake=3.0)
G.attack("lurker_snap", "Reliquary Lurker - Snap", "bite", 14, 4, 24, 16, (80, -30), True, (30, 26), (18, -14), amin=0, amax=44, w=1.0, hs=0.06, shake=2.0)
G.attack("lurker_lunge", "Reliquary Lurker - Lunge", "lunge", 12, 6, 28, 22, (150, -60), False, (40, 30), (22, -14), amin=30, amax=160, w=1.0, lunge=240, lstart=10, lframes=8, track=False, shake=4.0)
G.attack("abbot_crook", "Abbot - Crook Haul", "smash", 30, 6, 32, 32, (170, -110), True, (56, 42), (30, -24), amin=0, amax=66, lunge=55, lstart=26, lframes=6, status=("frost", 35))
G.attack("abbot_sweep", "Abbot - Tidal Sweep", "sweep", 26, 7, 30, 28, (200, -60), False, (84, 30), (34, -20), amin=0, amax=74, w=0.8, status=("frost", 30))
G.attack("abbot_spray", "Abbot - Salt Spray", "throw", 28, 2, 30, 16, (80, -40), True, (4, 4), (0, -34), proj=190.0, amin=70, amax=320, w=1.1, status=("frost", 50), hs=0.06, shake=2.0)
G.attack("abbot_tide", "Abbot - Drowning Leap", "leap", 46, 6, 36, 36, (210, -150), False, (120, 30), (0, -14), track=False, amin=90, amax=300, w=1.0, shake=8.0, status=("frost", 60))

# --- enemies
C.enemy("drowned_pilgrim", "Drowned Pilgrim", "They came to the Reliquary to be blessed by the water. The water kept its side of it, and they never left.",
        ["pilgrim_drag", "penitent_thrust"], 95, 42, 34, 60, 190, 60, 30, 70, 24, 70, 40, 100, 150,
        {"frost": 0.8, "burn": -0.2, "poison": 0.4}, [("pilgrims_draught", 0.3, 1), ("forge_scrap", 0.3, 1)])
C.enemy("reliquary_lurker", "Reliquary Lurker", "Something that learned to wait in shallow water. It does not hunt. It lets you arrive.",
        ["lurker_snap", "lurker_lunge"], 70, 25, 0, 84, 120, 70, 24, 50, 20, 90, 36, 90, 140,
        {"frost": 0.5, "poison": 0.5, "bleed": 0.2}, [("lurker_fang", 0.35, 1), ("hollow_resin", 0.3, 1)])
for n in ("drowned_pilgrim", "reliquary_lurker"):
    p = f"{R}/data/enemies/{n}.tres"
    t = open(p).read()
    if "pack_alert" not in t:
        t = t.rstrip("\n") + "\npack_alert = true\n"
    open(p, "w").write(t)

pen = open(f"{R}/actors/enemies/hollow_penitent.tscn").read()
t = pen.replace("res://data/enemies/hollow_penitent.tres", "res://data/enemies/drowned_pilgrim.tres")
t = t.replace('[node name="HollowPenitent"', '[node name="DrownedPilgrim"')
t = t.rstrip("\n") + "\nmodulate = Color(0.68, 0.88, 1.0, 1)\n"
open(f"{R}/actors/enemies/drowned_pilgrim.tscn", "w").write(t)
t = pen.replace("res://data/enemies/hollow_penitent.tres", "res://data/enemies/reliquary_lurker.tres")
t = t.replace("actors/enemies/enemy_base.gd", "actors/enemies/lurker.gd").replace("actors/enemies/penitent_visual.gd", "actors/enemies/lurker_visual.gd")
t = t.replace('[node name="HollowPenitent"', '[node name="ReliquaryLurker"')
open(f"{R}/actors/enemies/reliquary_lurker.tscn", "w").write(t)

# --- boss
G.enemy("salt_abbot", "Abbot Merrow, the Salt Abbot", "Keeper of the Reliquary. He blessed every drowning in it, and signed each one. The water was a congregation he could not dismiss.",
        ["abbot_crook", "abbot_sweep", "abbot_spray"], 760, 100, 56, 2400, "abbots_signet", "ember_shard")
G.boss("SaltAbbot", "salt_abbot", "salt_abbot", ["abbot_crook", "abbot_sweep", "abbot_spray", "abbot_tide"], 4, hurt=(26, 52), music_pitch=0.85)
print("reliquary ok")
