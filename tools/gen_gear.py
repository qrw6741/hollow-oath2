#!/usr/bin/env python3
"""Generates the gear added after the prologue: weapon attacks + weapons, armours, materials.
Run from the project root:  python3 tools/gen_gear.py
(Older weapons / armours were authored by hand; their data lives next to these.)"""
import os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

def atk(aid, name, anim, su, ac, rec, dmg, poise, stam, hb, off, kb=(50, -10), chain=4, dc=5,
        lunge=0, ls=0, lf=0, hs=0.05, shake=1.5, nxt=None, air=False, crit=False, grav=1.0):
    ext = '[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]\n'
    n = 2
    if nxt:
        ext += f'[ext_resource type="Resource" path="res://data/attacks/{nxt}.tres" id="2_next"]\n'
    body = f'''script = ExtResource("1_attack")
id = &"{aid}"
display_name = "{name}"
animation = &"{anim}"
startup_frames = {su}
active_frames = {ac}
recovery_frames = {rec}
chain_open_frame = {chain}
dodge_cancel_frame = {dc}
damage = {float(dmg)}
poise_damage = {float(poise)}
stamina_cost = {float(stam)}
knockback = Vector2({kb[0]}, {kb[1]})
hitbox_size = Vector2({hb[0]}, {hb[1]})
hitbox_offset = Vector2({off[0]}, {off[1]})
lunge_speed = {float(lunge)}
lunge_start_frame = {ls}
lunge_frames = {lf}
hit_stop = {hs}
shake = {shake}
'''
    if air: body += f'gravity_scale = {grav}\nis_aerial = true\n'
    if crit: body += 'critical = true\n'
    if nxt: body += 'next_in_combo = ExtResource("2_next")\n'
    steps = 3 if nxt else 2
    txt = f'[gd_resource type="Resource" script_class="AttackData" load_steps={steps} format=3]\n\n{ext}\n[resource]\n{body}'
    open(f'data/attacks/{aid}.tres', 'w').write(txt)

def weapon(wid, name, desc, look, light, heavy, air, rip, mult, two=False):
    ids = [light, heavy, air, rip]
    ext = '[ext_resource type="Script" path="res://systems/combat/weapon_data.gd" id="1_weapon"]\n'
    for i, a in enumerate(ids):
        ext += f'[ext_resource type="Resource" path="res://data/attacks/{a}.tres" id="{i+2}_a"]\n'
    txt = f'''[gd_resource type="Resource" script_class="WeaponData" load_steps=6 format=3]

{ext}
[resource]
script = ExtResource("1_weapon")
id = &"{wid}"
display_name = "{name}"
description = "{desc}"
light_combo_start = ExtResource("2_a")
heavy = ExtResource("3_a")
aerial = ExtResource("4_a")
riposte = ExtResource("5_a")
riposte_multiplier = {mult}
look = {look}
two_handed = {"true" if two else "false"}
'''
    open(f'data/weapons/{wid}.tres', 'w').write(txt)

# ---------------------------------------------------------------- Wayfarer's Rapier (look 5)
P = "rapier"
atk(f"{P}_3", "Rapier — Lunge", "thrust", 8, 4, 18, 15, 14, 12, (42, 12), (28, -14), (110, -30), chain=-1, dc=8, lunge=150, ls=5, lf=5, hs=0.07, shake=2.5)
atk(f"{P}_2", "Rapier — Second Thrust", "thrust", 5, 3, 11, 9, 6, 9, (38, 12), (25, -14), (30, -5), chain=3, dc=4, lunge=80, ls=3, lf=4, nxt=f"{P}_3", hs=0.04, shake=1.0)
atk(f"{P}_1", "Rapier — Thrust", "thrust", 5, 3, 11, 9, 6, 9, (38, 12), (25, -14), (30, -5), chain=3, dc=4, lunge=80, ls=3, lf=4, nxt=f"{P}_2", hs=0.04, shake=1.0)
atk(f"{P}_heavy", "Rapier — Passata", "thrust", 16, 4, 24, 26, 24, 20, (50, 12), (31, -14), (120, -40), chain=-1, dc=11, lunge=200, ls=11, lf=6, hs=0.09, shake=3.0)
atk(f"{P}_air", "Rapier — Falling Point", "air", 4, 8, 12, 10, 7, 10, (28, 30), (13, -8), (40, 60), chain=-1, dc=-1, air=True, grav=0.5)
atk(f"{P}_riposte", "Rapier — Perfect Point", "riposte", 8, 4, 28, 50, 999, 0, (50, 20), (22, -14), (140, -80), chain=-1, dc=18, lunge=130, ls=4, lf=5, hs=0.2, shake=6.0, crit=True)
weapon("wayfarers_rapier", "Wayfarer's Rapier", "A thin travelling blade, made to be quick rather than kind. It forgives nothing, and rewards a patient parry with a very clean kill.", 5, f"{P}_1", f"{P}_heavy", f"{P}_air", f"{P}_riposte", 1.5)

# ---------------------------------------------------------------- Kingsfall Greatsword (look 4)
P = "greatsword"
atk(f"{P}_2", "Greatsword — Return Swing", "slash_rev", 11, 5, 24, 28, 36, 22, (56, 30), (30, -15), (170, -60), chain=-1, dc=10, lunge=60, ls=8, lf=5, hs=0.1, shake=4.0)
atk(f"{P}_1", "Greatsword — Cleave", "slash", 12, 5, 20, 24, 30, 20, (54, 30), (29, -15), (160, -50), chain=8, dc=8, lunge=60, ls=9, lf=5, nxt=f"{P}_2", hs=0.09, shake=3.5)
atk(f"{P}_heavy", "Greatsword — Kingsfall", "heavy", 30, 7, 34, 62, 110, 36, (60, 38), (30, -17), (240, -120), chain=-1, dc=20, lunge=130, ls=22, lf=8, hs=0.16, shake=7.0)
atk(f"{P}_air", "Greatsword — Dive", "air", 8, 8, 16, 22, 24, 18, (44, 38), (16, -10), (50, 80), chain=-1, dc=-1, air=True, grav=0.6, hs=0.08, shake=3.0)
atk(f"{P}_riposte", "Greatsword — Execution", "riposte", 9, 4, 32, 60, 999, 0, (56, 32), (20, -14), (180, -110), chain=-1, dc=20, lunge=100, ls=4, lf=5, hs=0.22, shake=6.5, crit=True)
weapon("kingsfall_greatsword", "Kingsfall Greatsword", "A sword for a king's executioner: slow, enormous, and certain. Each swing asks for room and stamina, and gives an enemy very little of either back.", 4, f"{P}_1", f"{P}_heavy", f"{P}_air", f"{P}_riposte", 1.3, True)

# ---------------------------------------------------------------- Toll Hammer (look 6)
P = "hammer"
atk(f"{P}_2", "Hammer — Second Toll", "smash", 10, 4, 22, 24, 48, 19, (36, 32), (21, -14), (150, -60), chain=-1, dc=9, lunge=70, ls=7, lf=4, hs=0.09, shake=4.0)
atk(f"{P}_1", "Hammer — First Toll", "smash", 11, 4, 20, 20, 40, 17, (34, 32), (20, -14), (130, -50), chain=7, dc=7, lunge=70, ls=8, lf=4, nxt=f"{P}_2", hs=0.08, shake=3.5)
atk(f"{P}_heavy", "Hammer — Knell", "heavy", 26, 6, 32, 48, 130, 30, (46, 38), (24, -16), (200, -100), chain=-1, dc=17, lunge=100, ls=19, lf=6, hs=0.15, shake=6.5)
atk(f"{P}_air", "Hammer — Drop", "air", 6, 8, 14, 18, 30, 16, (30, 34), (12, -8), (40, 90), chain=-1, dc=-1, air=True, grav=0.6, hs=0.07, shake=3.0)
atk(f"{P}_riposte", "Hammer — Last Toll", "riposte", 9, 4, 32, 64, 999, 0, (44, 32), (20, -14), (170, -110), chain=-1, dc=20, lunge=90, ls=4, lf=4, hs=0.22, shake=7.0, crit=True)
weapon("toll_hammer", "Toll Hammer", "The Bell Warden's own mallet, cut down to a man's size. It does not cut. It rings, and what it strikes stops listening.", 6, f"{P}_1", f"{P}_heavy", f"{P}_air", f"{P}_riposte", 1.2, True)

# ---------------------------------------------------------------- Marshal's Lance (look 7)
P = "lance"
atk(f"{P}_3", "Lance — Long Thrust", "thrust", 12, 5, 22, 20, 20, 15, (54, 14), (38, -14), (130, -40), chain=-1, dc=10, lunge=120, ls=8, lf=6, hs=0.08, shake=2.5)
atk(f"{P}_2", "Lance — Second Thrust", "thrust", 9, 4, 16, 14, 12, 12, (48, 14), (35, -14), (50, -10), chain=5, dc=5, lunge=60, ls=6, lf=4, nxt=f"{P}_3", hs=0.05, shake=1.5)
atk(f"{P}_1", "Lance — Thrust", "thrust", 9, 4, 16, 14, 12, 12, (48, 14), (35, -14), (50, -10), chain=5, dc=5, lunge=60, ls=6, lf=4, nxt=f"{P}_2", hs=0.05, shake=1.5)
atk(f"{P}_heavy", "Lance — Sweep", "sweep", 18, 6, 26, 30, 60, 22, (66, 26), (36, -14), (170, -70), chain=-1, dc=13, lunge=70, ls=12, lf=5, hs=0.1, shake=4.0)
atk(f"{P}_air", "Lance — Plunge", "air", 5, 9, 13, 15, 10, 13, (24, 38), (10, -4), (30, 80), chain=-1, dc=-1, air=True, grav=0.5)
atk(f"{P}_riposte", "Lance — Run Through", "riposte", 9, 4, 30, 58, 999, 0, (60, 20), (30, -14), (150, -90), chain=-1, dc=18, lunge=120, ls=4, lf=5, hs=0.2, shake=6.0, crit=True)
weapon("marshals_lance", "Marshal's Lance", "Sir Orren's couched lance. It reaches farther than any sword, and anyone who has stood in front of it knows exactly how far that is.", 7, f"{P}_1", f"{P}_heavy", f"{P}_air", f"{P}_riposte", 1.3, True)

# ---------------------------------------------------------------- Tide-Sabre (look 8)
P = "sabre"
atk(f"{P}_4", "Sabre — Rising Tide", "slash_rev", 9, 5, 22, 15, 18, 14, (38, 24), (22, -14), (120, -50), chain=-1, dc=8, lunge=90, ls=6, lf=5, hs=0.07, shake=2.5)
atk(f"{P}_3", "Sabre — Third Wave", "slash", 5, 4, 15, 10, 8, 11, (36, 22), (21, -14), (40, -10), chain=4, dc=5, lunge=70, ls=3, lf=4, nxt=f"{P}_4", hs=0.04, shake=1.2)
atk(f"{P}_2", "Sabre — Back Wave", "slash_rev", 5, 4, 14, 9, 8, 11, (36, 22), (21, -14), (40, -10), chain=4, dc=5, lunge=70, ls=3, lf=4, nxt=f"{P}_3", hs=0.04, shake=1.2)
atk(f"{P}_1", "Sabre — First Wave", "slash", 6, 4, 14, 9, 8, 11, (36, 22), (21, -14), (40, -10), chain=4, dc=5, lunge=70, ls=4, lf=4, nxt=f"{P}_2", hs=0.04, shake=1.2)
atk(f"{P}_heavy", "Sabre — Undertow", "heavy", 17, 5, 22, 28, 40, 22, (42, 28), (22, -15), (160, -70), chain=-1, dc=12, lunge=130, ls=12, lf=6, hs=0.1, shake=4.0)
atk(f"{P}_air", "Sabre — Breaker", "air", 4, 8, 12, 10, 8, 11, (32, 30), (14, -10), (40, 60), chain=-1, dc=-1, air=True, grav=0.5)
atk(f"{P}_riposte", "Sabre — Drowning Cut", "riposte", 8, 4, 28, 66, 999, 0, (46, 30), (18, -14), (150, -100), chain=-1, dc=18, lunge=110, ls=4, lf=5, hs=0.2, shake=6.0, crit=True)
weapon("tide_sabre", "Tide-Sabre", "The Drowned Canon's curved blade, still wet. It strikes in long, quick waves, one after another, and each wave is a little harder than the last.", 8, f"{P}_1", f"{P}_heavy", f"{P}_air", f"{P}_riposte", 1.1)

# ---------------------------------------------------------------- Armours
def armor(aid, name, desc, look, dmg, spd, dodge, c1, c2, acc):
    def col(h): return "Color(%.3f, %.3f, %.3f, 1)" % tuple(int(h[i:i+2], 16) / 255 for i in (1, 3, 5))
    txt = f'''[gd_resource type="Resource" script_class="ArmorData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/armor_data.gd" id="1_armor"]

[resource]
script = ExtResource("1_armor")
id = &"{aid}"
display_name = "{name}"
description = "{desc}"
look = {look}
damage_taken_mult = {dmg}
run_speed_mult = {spd}
dodge_stamina_add = {float(dodge)}
cloth_color = {col(c1)}
cloth_light_color = {col(c2)}
accent_color = {col(acc)}
'''
    open(f'data/armors/{aid}.tres', 'w').write(txt)

# the four starting armours mirror their presets (checked by a test)
armor("sworn_knight", "Oathsworn Mail", "Mail and tabard issued to every sworn knight. Balanced: it asks nothing of you and promises nothing.", 2, 1.0, 1.0, 0, "#221e28", "#3a3442", "#8e1b22")
armor("duelist", "Candlewright Leathers", "Waxed leathers worn by the Candlewrights' duellists. Light enough to dance in, thin enough to regret.", 1, 1.12, 1.12, 0, "#3b2a2a", "#5a4040", "#c9a24a")
armor("bulwark", "Bulwark Plate", "Full plate over padded wool, dented by a decade of holding the line. Heavy enough to slow the stride; strong enough to make it worth it.", 3, 0.78, 0.88, 0, "#4a5258", "#6b7478", "#5e6f69")
armor("unsworn", "Bone-cloth Wraps", "No armour at all: strips of bone-coloured cloth around the wrists, ankles and brow. The Unsworn carry nothing they would have to swear to keep.", 0, 1.3, 1.15, 0, "#6b4a3a", "#8a6a52", "#d9d0bc")
# new
armor("pilgrim_coat", "Pilgrim's Coat", "A road-worn coat of oiled wool with a few plates sewn in at the shoulders. Warmer than it looks.", 1, 1.04, 1.07, -1, "#3a3a2c", "#58563f", "#b08a3c")
armor("penitent_shroud", "Penitent's Shroud", "Grey cloth, wet with tears that never dried. It moves like a prayer, and the blows seem to forget where you are.", 1, 0.96, 1.1, -2, "#4a4a58", "#6e6e80", "#9ac0cf")
armor("canons_mail", "Drowned Canon's Mail", "Ring mail from the flooded cloister, rusted but whole. Water still runs from it when you stand still.", 2, 0.86, 0.95, 1, "#2e3a3c", "#475a5c", "#5fa3a0")
armor("marshal_plate", "Marshal's Plate", "Sir Orren's own harness, hollow and ringing. It will stop almost anything, and it wants to stand still.", 3, 0.7, 0.84, 4, "#3c2e2a", "#5c4a42", "#c9a24e")
print("gear generated")
