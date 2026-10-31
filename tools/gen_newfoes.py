#!/usr/bin/env python3
"""Generates two new enemy types by cloning existing ones (data + scene):
  swollen_pilgrim  (from hollow_penitent): bursts on death.
  wick_mender      (from hollow_archer): heals nearby allies.
Idempotent. Run after editing:  python3 tools/gen_newfoes.py"""
import os, re
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def clone(base, nid, name, lore, script, hp, ember, tint, scale, extra=""):
    d = open(f"{R}/data/enemies/{base}.tres").read()
    d = re.sub(r'id = &"[a-z_]+"', f'id = &"{nid}"', d, count=1)
    d = re.sub(r'display_name = ".*"', f'display_name = "{name}"', d, count=1)
    d = re.sub(r'lore = ".*"', f'lore = "{lore}"', d, count=1)
    d = re.sub(r'max_health = [0-9.]+', f'max_health = {hp}', d, count=1)
    d = re.sub(r'ember_reward = [0-9]+', f'ember_reward = {ember}', d, count=1)
    open(f"{R}/data/enemies/{nid}.tres", "w").write(d)
    s = open(f"{R}/actors/enemies/{base}.tscn").read()
    s = s.replace(f"res://data/enemies/{base}.tres", f"res://data/enemies/{nid}.tres")
    s = re.sub(r'path="res://actors/enemies/(ranged_enemy|enemy_base|[a-z_]+_enemy)\.gd" id="1_enemy"', f'path="res://actors/enemies/{script}.gd" id="1_enemy"', s, count=1)
    s = re.sub(r'\[node name="[A-Za-z]+" type="CharacterBody2D"\]', f'[node name="{"".join(w.title() for w in nid.split("_"))}" type="CharacterBody2D"]', s, count=1)
    # tint + scale on the visual
    s = re.sub(r'(\[node name="Visual" type="Node2D" parent="."\]\n)', r'\1modulate = Color%s\nscale = Vector2%s\n' % (tint, scale), s, count=1)
    s += extra
    open(f"{R}/actors/enemies/{nid}.tscn", "w").write(s)

clone("hollow_penitent", "swollen_pilgrim", "Swollen Pilgrim",
      "A pilgrim who drank the marsh water to feel lighter. It did not work. Do not be near it when it finally lets go.",
      "bloat_enemy", 55.0, 60, "(1.25, 1.1, 0.6, 1)", "(1.18, 1.18)")
clone("hollow_archer", "wick_mender", "Wick-Mender",
      "She carries a taper and relights whatever the oath has left of the wounded. She is very kind about it.",
      "mender_enemy", 48.0, 70, "(0.7, 1.15, 0.8, 1)", "(1, 1)")
print("newfoes ok")
