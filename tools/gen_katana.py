#!/usr/bin/env python3
"""The Long Katana (WeaponLook.KATANA): a balanced, long-reach, fast blade. Light combo is three cuts, the heavy
is a drawing cut, the skill is Moonlit Draw. Balance target (see DEVELOPMENT_LOG): steel light-combo DPS ~34.5, ~48 with the flame, against
27-50 for the other findable weapons, reach "Long", stamina 36 per combo (cheapest of the big blades), bleed 30.
Writes data/attacks/katana_*.tres, skill_moonlit_draw.tres, data/weapons/long_katana.tres."""
R = "/root/hollow-oath"
HEAD = '[gd_resource type="Resource" script_class="AttackData" load_steps=%d format=3]\n\n[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]\n%s\n[resource]\nscript = ExtResource("1_attack")\n'
def atk(id, name, anim, su, ac, rc, dmg, poise, stam, hb, ho, kb, nxt=None, chain=-1, lunge=(0, 0, 0), hs=0.1, shake=3.0, inv=0, dodge=-1, status=None, aerial=False):
    ext = '[ext_resource type="Resource" path="res://data/attacks/%s.tres" id="2_next"]\n' % nxt if nxt else ""
    s = HEAD % (3 if nxt else 2, ext)
    s += f'id = &"{id}"\ndisplay_name = "{name}"\nanimation = &"{anim}"\nstartup_frames = {su}\nactive_frames = {ac}\nrecovery_frames = {rc}\n'
    s += f'chain_open_frame = {chain}\ndodge_cancel_frame = {dodge}\ndamage = {dmg}\npoise_damage = {poise}\nstamina_cost = {stam}\ninvulnerable_frames = {inv}\n'
    s += f'knockback = Vector2({kb[0]}, {kb[1]})\nhitbox_size = Vector2({hb[0]}, {hb[1]})\nhitbox_offset = Vector2({ho[0]}, {ho[1]})\n'
    s += f'lunge_speed = {lunge[0]}\nlunge_start_frame = {lunge[1]}\nlunge_frames = {lunge[2]}\nprojectile_speed = 0.0\nprojectile_offset = Vector2(14, -22)\nhit_stop = {hs}\nshake = {shake}\n'
    if nxt: s += "next_in_combo = ExtResource(\"2_next\")\n"
    if status: s += f'status = &"{status[0]}"\nstatus_amount = {status[1]}\n'
    if aerial: s += "is_aerial = true\n"
    open(f"{R}/data/attacks/{id}.tres", "w").write(s)

atk("katana_3", "Long Katana - Falling Cut", "smash", 9, 5, 22, 19.0, 26.0, 14.0, (70, 24), (42, -15), (110, -40), lunge=(130, 6, 5), hs=0.07, shake=2.6)
atk("katana_2", "Long Katana - Rising Cut", "slash_rev", 6, 4, 12, 13.0, 10.0, 11.0, (62, 22), (37, -15), (60, -12), nxt="katana_3", chain=5, dodge=6, hs=0.05, shake=1.4)
atk("katana_1", "Long Katana - First Cut", "slash", 7, 4, 13, 13.0, 10.0, 11.0, (62, 22), (37, -15), (60, -12), nxt="katana_2", chain=5, dodge=6, lunge=(80, 5, 4), hs=0.05, shake=1.4)
atk("katana_heavy", "Long Katana - Drawing Cut", "heavy", 19, 5, 24, 40.0, 55.0, 24.0, (80, 28), (46, -16), (170, -50), lunge=(160, 13, 6), hs=0.1, shake=4.5)
atk("katana_air", "Long Katana - Skyfall", "air", 5, 8, 12, 12.0, 10.0, 11.0, (58, 42), (28, -8), (70, 20), hs=0.05, shake=1.5, aerial=True)
atk("katana_riposte", "Long Katana - Quiet Answer", "riposte", 8, 4, 26, 72.0, 999.0, 0.0, (68, 28), (40, -15), (70, -16), lunge=(120, 4, 5), hs=0.12, shake=5.0)
atk("skill_moonlit_draw", "Long Katana - Moonlit Draw", "sweep", 12, 7, 26, 52.0, 70.0, 14.0, (100, 34), (52, -16), (190, -60), lunge=(190, 8, 8), hs=0.12, shake=6.0, inv=6, dodge=14, status=("bleed", 45.0))

W = f'''[gd_resource type="Resource" script_class="WeaponData" load_steps=7 format=3]

[ext_resource type="Script" path="res://systems/combat/weapon_data.gd" id="1_weapon"]
[ext_resource type="Resource" path="res://data/attacks/katana_1.tres" id="a0"]
[ext_resource type="Resource" path="res://data/attacks/katana_heavy.tres" id="a1"]
[ext_resource type="Resource" path="res://data/attacks/katana_air.tres" id="a2"]
[ext_resource type="Resource" path="res://data/attacks/katana_riposte.tres" id="a3"]
[ext_resource type="Resource" path="res://data/attacks/skill_moonlit_draw.tres" id="a4"]

[resource]
script = ExtResource("1_weapon")
id = &"long_katana"
display_name = "Long Katana"
description = "A blade longer than the arm that draws it, folded until it was nearly nothing. Three quick cuts, the last one falling; a drawing cut that wants a breath first. Every swing throws a crescent of fire a little way ahead of the steel, so the blade reaches farther than it looks and what it cuts keeps burning. It asks little stamina; the skill is in the spacing."
light_combo_start = ExtResource("a0")
heavy = ExtResource("a1")
aerial = ExtResource("a2")
riposte = ExtResource("a3")
riposte_multiplier = 1.15
look = 12
two_handed = true
damage_mult = 1.05
swing_fire = 0.4
status = &"bleed"
status_amount = 30.0
skill = ExtResource("a4")
skill_cost = 30.0
parry_window_bonus = 1
parry_recovery_bonus = 0
'''
open(f"{R}/data/weapons/long_katana.tres", "w").write(W)
print("katana written")
