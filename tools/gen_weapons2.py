#!/usr/bin/env python3
"""Generates the second weapon set: Gravedigger's Greataxe, Veilglass Daggers, Candle Catalyst
(casts bolts), Abbot's Crozier (guarding staff), plus their attacks and the new key items.
Run: python3 tools/gen_weapons2.py"""
import os
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def atk(id_, name, anim, su, act, rec, dmg, poise, stam, hsize, hoff, chain=-1, dodge=-1, lunge=0, ls=0, lf=0,
        kb=(60, -10), nxt=None, proj=0.0, status=None, hs=0.06, shake=1.5, inv=0, air=False, off=(14, -22)):
    ext = '[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]\n'
    if nxt:
        ext += f'[ext_resource type="Resource" path="res://data/attacks/{nxt}.tres" id="2_next"]\n'
    s = f'''[gd_resource type="Resource" script_class="AttackData" load_steps={3 if nxt else 2} format=3]

{ext}
[resource]
script = ExtResource("1_attack")
id = &"{id_}"
display_name = "{name}"
animation = &"{anim}"
startup_frames = {su}
active_frames = {act}
recovery_frames = {rec}
chain_open_frame = {chain}
dodge_cancel_frame = {dodge}
damage = {dmg:.1f}
poise_damage = {poise:.1f}
stamina_cost = {stam:.1f}
invulnerable_frames = {inv}
knockback = Vector2({kb[0]}, {kb[1]})
hitbox_size = Vector2({hsize[0]}, {hsize[1]})
hitbox_offset = Vector2({hoff[0]}, {hoff[1]})
lunge_speed = {lunge:.1f}
lunge_start_frame = {ls}
lunge_frames = {lf}
projectile_speed = {proj}
projectile_offset = Vector2({off[0]}, {off[1]})
hit_stop = {hs}
shake = {shake}
'''
    if air:
        s += "is_aerial = true\n"
    if nxt:
        s += 'next_in_combo = ExtResource("2_next")\n'
    if status:
        s += f'status = &"{status[0]}"\nstatus_amount = {status[1]}.0\n'
    open(f"{R}/data/attacks/{id_}.tres", "w").write(s)

def weapon(id_, name, desc, light, heavy, aerial, riposte, skill, look, two, dmg_mult, status, cost, rmult=1.0,
           pw=0, pr=0, block=0.0):
    atks = [light, heavy, aerial, riposte, "skill_" + id_]
    ext = '[ext_resource type="Script" path="res://systems/combat/weapon_data.gd" id="1_weapon"]\n'
    for i, a in enumerate(atks):
        ext += f'[ext_resource type="Resource" path="res://data/attacks/{a}.tres" id="a{i}"]\n'
    s = f'''[gd_resource type="Resource" script_class="WeaponData" load_steps=7 format=3]

{ext}
[resource]
script = ExtResource("1_weapon")
id = &"{id_}"
display_name = "{name}"
description = "{desc}"
light_combo_start = ExtResource("a0")
heavy = ExtResource("a1")
aerial = ExtResource("a2")
riposte = ExtResource("a3")
riposte_multiplier = {rmult}
look = {look}
two_handed = {"true" if two else "false"}
damage_mult = {dmg_mult}
status = &"{status[0]}"
status_amount = {status[1]}.0
skill = ExtResource("a4")
skill_cost = {cost}
parry_window_bonus = {pw}
parry_recovery_bonus = {pr}
'''
    if block:
        s += f"block_reduction = {block}\n"
    open(f"{R}/data/weapons/{id_}.tres", "w").write(s)

def item(id_, name, desc, color):
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
icon_color = {color}
''')

# ---- Gravedigger's Greataxe (look 9 AXE): slow, heavy, bleeds
atk("axe_2", "Greataxe - Overhead", "smash", 16, 5, 28, 34, 45, 24, (56, 36), (30, -17), kb=(110, -40), shake=3.0, hs=0.1)
atk("axe_1", "Greataxe - Cleave", "slash", 14, 5, 22, 28, 35, 22, (60, 32), (32, -15), chain=9, dodge=-1, lunge=70, ls=12, lf=4, kb=(100, -20), nxt="axe_2", shake=2.5, hs=0.08)
atk("axe_heavy", "Greataxe - Grave Chop", "heavy", 34, 7, 36, 70, 140, 38, (62, 40), (32, -18), lunge=110, ls=30, lf=4, kb=(180, -70), shake=7.0, hs=0.14)
atk("axe_air", "Greataxe - Falling Edge", "air", 12, 8, 18, 26, 30, 18, (50, 44), (18, -12), kb=(80, 20), air=True)
atk("axe_riposte", "Greataxe - Gravedigger's Due", "riposte", 11, 4, 32, 80, 999, 0, (52, 34), (24, -16), lunge=90, ls=9, lf=3, shake=5.0, hs=0.12)
atk("skill_gravediggers_greataxe", "Gravedigger's Swing", "sweep", 22, 8, 34, 70, 200, 14, (104, 32), (0, -14), dodge=14, kb=(220, -90), status=("bleed", 60), shake=8.0, hs=0.13, inv=6)
weapon("gravediggers_greataxe", "Gravedigger's Greataxe", "Forged for a trade of one swing and one grave. It is slow, and what it lands does not get back up. Found in a place that was not meant to be found.",
       "axe_1", "axe_heavy", "axe_air", "axe_riposte", None, 9, True, 1.1, ("bleed", 22), 32.0, rmult=1.2, pw=-1, pr=3)

# ---- Veilglass Daggers (look 1 TWIN): fastest weapon, poison
atk("dag_4", "Daggers - Cross Flurry", "twin_x", 7, 4, 15, 11, 12, 9, (36, 26), (14, -14), kb=(50, -15), shake=1.6)
atk("dag_3", "Daggers - Fan", "twin_a", 4, 3, 9, 6, 6, 7, (28, 22), (16, -14), chain=2, lunge=60, ls=3, lf=3, nxt="dag_4")
atk("dag_2", "Daggers - Back Cut", "twin_b", 4, 3, 9, 6, 6, 7, (28, 22), (16, -14), chain=2, lunge=50, ls=3, lf=3, nxt="dag_3")
atk("dag_1", "Daggers - Prick", "twin_a", 4, 3, 10, 6, 6, 7, (28, 22), (16, -14), chain=2, lunge=60, ls=3, lf=3, nxt="dag_2")
atk("dag_heavy", "Daggers - Fan of Knives", "twin_x", 10, 5, 18, 20, 26, 18, (46, 28), (6, -15), lunge=130, ls=9, lf=4, kb=(80, -20), shake=2.5)
atk("dag_air", "Daggers - Plunge", "air", 8, 6, 14, 12, 14, 10, (34, 36), (14, -10), kb=(40, 20), air=True)
atk("dag_riposte", "Daggers - Throat Cut", "riposte", 6, 3, 26, 60, 999, 0, (36, 26), (14, -14), lunge=100, ls=5, lf=3, shake=3.0)
atk("skill_veil_daggers", "Veil Flurry", "twin_x", 6, 8, 24, 44, 90, 12, (46, 30), (16, -14), inv=14, lunge=260, ls=5, lf=7, dodge=10, status=("poison", 60), shake=5.0)
weapon("veil_daggers", "Veilglass Daggers", "Twin blades ground from a lurker's fang. They weigh nothing and cut the air in rows. The poison is the fang's, not yours.",
       "dag_1", "dag_heavy", "dag_air", "dag_riposte", None, 1, False, 1.0, ("poison", 18), 26.0, rmult=1.1, pw=0, pr=-5)

# ---- Candle Catalyst (look 10 STAFF): ranged bolts, burn
atk("cat_3", "Catalyst - Candlefall", "thrust", 14, 2, 22, 18, 15, 14, (4, 4), (0, 0), proj=230.0, shake=2.0, off=(16, -22))
atk("cat_2", "Catalyst - Flicker", "thrust", 10, 2, 16, 13, 8, 10, (4, 4), (0, 0), proj=270.0, chain=7, nxt="cat_3", off=(16, -22))
atk("cat_1", "Catalyst - Spark", "thrust", 10, 2, 16, 13, 8, 10, (4, 4), (0, 0), proj=270.0, chain=7, nxt="cat_2", off=(16, -22))
atk("cat_heavy", "Catalyst - Wax Bolt", "thrust", 28, 2, 30, 40, 60, 26, (4, 4), (0, 0), proj=210.0, kb=(110, -30), shake=4.0, hs=0.1, off=(16, -22))
atk("cat_air", "Catalyst - Staff Drop", "air", 10, 6, 16, 14, 14, 12, (38, 30), (16, -10), kb=(50, 20), air=True)
atk("cat_riposte", "Catalyst - Snuffing Rap", "riposte", 8, 4, 28, 60, 999, 0, (44, 30), (20, -14), lunge=80, ls=6, lf=3)
atk("skill_candle_catalyst", "Candlefall Pillar", "thrust", 18, 2, 28, 52, 90, 14, (4, 4), (0, 0), proj=170.0, status=("burn", 70), shake=5.0, hs=0.12, kb=(160, -50), off=(16, -22))
weapon("candle_catalyst", "Candle Catalyst", "A choirmaster's staff with the wick still lit. It does not swing, it asks, and the flame answers from across the room.",
       "cat_1", "cat_heavy", "cat_air", "cat_riposte", None, 10, True, 1.0, ("burn", 16), 24.0, rmult=1.0, pw=2, pr=-3)

# ---- Abbot's Crozier (look 10 STAFF): melee, frost, holds a guard
atk("croz_3", "Crozier - Hook and Haul", "smash", 14, 5, 26, 28, 40, 20, (50, 34), (28, -16), kb=(120, -50), shake=3.0)
atk("croz_2", "Crozier - Back Stroke", "slash_rev", 10, 4, 18, 18, 22, 15, (46, 26), (26, -15), chain=7, nxt="croz_3", lunge=60, ls=8, lf=3)
atk("croz_1", "Crozier - Stroke", "slash", 10, 4, 18, 18, 22, 15, (46, 26), (26, -15), chain=7, nxt="croz_2", lunge=60, ls=8, lf=3)
atk("croz_heavy", "Crozier - Salt Toll", "heavy", 24, 6, 30, 52, 100, 30, (58, 38), (30, -16), kb=(150, -50), shake=5.0, hs=0.12, lunge=100, ls=22, lf=4)
atk("croz_air", "Crozier - Plummet", "air", 10, 7, 16, 18, 24, 14, (44, 40), (16, -10), kb=(60, 20), air=True)
atk("croz_riposte", "Crozier - Drowning Turn", "riposte", 9, 4, 30, 68, 999, 0, (48, 30), (22, -14), lunge=80, ls=7, lf=3)
atk("skill_abbots_crozier", "Salt Tide", "thrust", 16, 2, 30, 50, 80, 14, (4, 4), (0, 0), proj=200.0, status=("frost", 75), shake=5.0, hs=0.12, kb=(160, -40), off=(16, -22))
weapon("abbots_crozier", "Abbot's Crozier", "A shepherd's hook of salt-white wood. It was made to pull things back from the water. It guards as well as it strikes.",
       "croz_1", "croz_heavy", "croz_air", "croz_riposte", None, 10, True, 1.15, ("frost", 24), 30.0, rmult=1.3, pw=2, pr=2, block=0.6)

item("lurker_fang", "Lurker's Fang", "A long, pale fang that is still wet. The smith will know what it wants to be.", "Color(0.78, 0.86, 0.9, 1)")
item("cantors_wick", "Cantor's Wick", "A wick that will not go out. It was pulled from the staff of a choir-master of the Reliquary.", "Color(1.0, 0.7, 0.3, 1)")
item("abbots_signet", "Abbot's Signet", "A signet crusted with salt. It sealed every drowning in the Reliquary for a hundred years.", "Color(0.62, 0.82, 0.88, 1)")
print("weapons2 ok")
