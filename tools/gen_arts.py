#!/usr/bin/env python3
"""Generates the Arts' attack data (data/attacks/art_*.tres). Run: python3 tools/gen_arts.py"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def art(id_, name, anim, su, act, rec, dmg, poise, kb, hsize, hoff, inv=0, lunge=0, lstart=0, lframes=0,
        proj=0.0, status=None, shake=4.0, hs=0.08, dodge=-1):
    s = f'''[gd_resource type="Resource" script_class="AttackData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]

[resource]
script = ExtResource("1_attack")
id = &"art_{id_}"
display_name = "Art - {name}"
animation = &"{anim}"
startup_frames = {su}
active_frames = {act}
recovery_frames = {rec}
chain_open_frame = -1
dodge_cancel_frame = {dodge}
damage = {dmg:.1f}
poise_damage = {poise:.1f}
stamina_cost = 0.0
invulnerable_frames = {inv}
knockback = Vector2({kb[0]}, {kb[1]})
hitbox_size = Vector2({hsize[0]}, {hsize[1]})
hitbox_offset = Vector2({hoff[0]}, {hoff[1]})
lunge_speed = {lunge:.1f}
lunge_start_frame = {lstart}
lunge_frames = {lframes}
projectile_speed = {proj}
projectile_offset = Vector2(16, -22)
hit_stop = {hs}
shake = {shake}
'''
    if status:
        s += f'status = &"{status[0]}"\nstatus_amount = {status[1]}.0\n'
    open(f"{R}/data/attacks/art_{id_}.tres", "w").write(s)

art("toll_of_mercy", "Toll of Mercy", "smash", 14, 6, 24, 26, 90, (230, -90), (96, 40), (0, -20), shake=7.0, hs=0.12)
art("veil_step", "Veil Step", "thrust", 6, 5, 16, 22, 30, (150, -40), (46, 22), (30, -20), inv=22, lunge=300, lstart=5, lframes=6, dodge=6)
art("gravebind", "Gravebind", "sweep", 12, 6, 24, 24, 55, (170, -60), (86, 28), (36, -16), status=("frost", 65), shake=5.0)
art("ember_lance", "Ember Lance", "thrust", 14, 2, 24, 34, 40, (140, -30), (4, 4), (0, -20), proj=300.0, status=("burn", 60), shake=3.0)
art("mending_glow", "Mending Glow", "riposte", 8, 2, 22, 0, 0, (0, 0), (4, 4), (0, -20), inv=26, shake=0.0, hs=0.0)
art("tidecall", "Tidecall", "sweep", 16, 2, 26, 30, 70, (180, -50), (4, 4), (0, -12), proj=170.0, status=("frost", 45), shake=5.0)
print("arts ok")
