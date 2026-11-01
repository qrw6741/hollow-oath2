#!/usr/bin/env python3
"""The Nightreaper: a real scythe (WeaponLook.SCYTHE) with its own attacks. Run after gen_nether.py."""
import re
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

# Wide, fast reaping arcs: long reach, a three-hit combo, big poise.
atk("scythe_3", "Nightreaper - Harvest", "smash", 14, 6, 24, 46.0, 70.0, 18.0, (96, 52), (40, -20), (190, -60), hs=0.12, shake=5.0)
atk("scythe_2", "Nightreaper - Backswing", "slash_rev", 10, 5, 18, 34.0, 45.0, 14.0, (92, 40), (38, -16), (140, -30), nxt="scythe_3", chain=9, hs=0.09, shake=3.0)
atk("scythe_1", "Nightreaper - Reap", "slash", 9, 5, 16, 32.0, 40.0, 14.0, (92, 40), (38, -16), (130, -25), nxt="scythe_2", chain=8, lunge=(80, 7, 3), hs=0.09, shake=3.0)
atk("scythe_heavy", "Nightreaper - Soul Cleave", "heavy", 26, 8, 28, 110.0, 220.0, 28.0, (110, 64), (42, -24), (260, -90), lunge=(120, 22, 4), hs=0.16, shake=8.0, status=("burn", 40.0))
atk("scythe_air", "Nightreaper - Falling Moon", "air", 9, 9, 14, 40.0, 50.0, 12.0, (84, 70), (22, -6), (110, 30), hs=0.07, shake=2.5, aerial=True)
atk("scythe_riposte", "Nightreaper - Execution", "riposte", 9, 5, 24, 120.0, 999.0, 0.0, (80, 44), (34, -18), (80, -20), lunge=(110, 7, 3), hs=0.14, shake=6.0)
atk("skill_nightreaper", "Nightreaper - Black Tide", "sweep", 16, 10, 26, 130.0, 260.0, 12.0, (170, 56), (0, -20), (300, -110), hs=0.15, shake=10.0, inv=8, dodge=12, status=("burn", 70.0))

W = f"{R}/data/weapons/nightreaper.tres"
s = open(W).read()
def refs(m):
    return m
for old, new in [("axe_1", "scythe_1"), ("axe_heavy", "scythe_heavy"), ("axe_air", "scythe_air"), ("axe_riposte", "scythe_riposte"), ("skill_gravediggers_greataxe", "skill_nightreaper")]:
    s = s.replace("attacks/%s.tres" % old, "attacks/%s.tres" % new)
s = re.sub(r"look = \d+", "look = 11", s, count=1)
s = re.sub(r"damage_mult = [0-9.]+", "damage_mult = 3.0", s, count=1)
s = re.sub(r"riposte_multiplier = [0-9.]+", "riposte_multiplier = 1.5", s, count=1)
s = re.sub(r"status_amount = [0-9.]+", "status_amount = 80.0", s, count=1)
s = re.sub(r"skill_cost = [0-9.]+", "skill_cost = 28.0", s, count=1)
s = re.sub(r'description = ".*"', 'description = "Ashkar\'s scythe, wrapped in the black flame that hunted him. Three fast reaping arcs reach farther than any blade, and every cut burns. It was never meant to be carried by the living. It is by far the strongest weapon in the game."', s, count=1)
if "jutsu =" not in s:
    s = s.replace("parry_window_bonus", 'jutsu = &"amaterasu"\njutsu_cost = 50.0\nparry_window_bonus', 1)
open(W, "w").write(s)
print("scythe written")
