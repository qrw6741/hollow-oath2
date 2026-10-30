#!/usr/bin/env python3
"""Generates the enemies added with the combat-depth update: Hollow Archer, Candle Cantor
(summoner) and the elite variants (Gilded Penitent, Oathguard Captain, Pike Sergeant).
Run:  python3 tools/gen_combat_depth.py     (safe to re-run; only touches the files it lists)"""
import os, re
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def attack(id_, name, anim, su, act, rec, dmg, kb, parry, hsize, hoff, proj=0.0, amin=0, amax=40, w=1.0,
           status=None, hs=0.07, shake=2.5, track=True, lunge=0.0, lstart=0, lframes=0):
    s = f'''[gd_resource type="Resource" script_class="AttackData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/combat/attack_data.gd" id="1_attack"]

[resource]
script = ExtResource("1_attack")
id = &"{id_}"
display_name = "{name}"
animation = &"{anim}"
startup_frames = {su}
active_frames = {act}
recovery_frames = {rec}
chain_open_frame = -1
dodge_cancel_frame = -1
damage = {dmg:.1f}
poise_damage = 0.0
stamina_cost = 0.0
knockback = Vector2({kb[0]}, {kb[1]})
parryable = {"true" if parry else "false"}
hitbox_size = Vector2({hsize[0]}, {hsize[1]})
hitbox_offset = Vector2({hoff[0]}, {hoff[1]})
lunge_speed = {lunge:.1f}
lunge_start_frame = {lstart}
lunge_frames = {lframes}
track_during_startup = {"true" if track else "false"}
projectile_speed = {proj}
projectile_offset = Vector2(12, -22)
hit_stop = {hs}
shake = {shake}
ai_min_range = {amin}
ai_max_range = {amax}
ai_weight = {w}
ai_chain_chance = 1.0
'''
    if status:
        s += f'status = &"{status[0]}"\nstatus_amount = {status[1]}.0\n'
    open(f"{R}/data/attacks/{id_}.tres", "w").write(s)

attack("archer_shot", "Hollow Archer - Arrow", "shoot", 34, 2, 30, 14, (70, -30), True, (4, 4), (0, -20),
       proj=290.0, amin=100, amax=300, status=("bleed", 18))
attack("archer_knife", "Hollow Archer - Knife", "stab", 14, 4, 24, 12, (90, -30), True, (26, 14), (18, -14),
       amin=0, amax=40, w=1.0, lunge=60, lstart=12, lframes=4)
attack("cantor_summon", "Candle Cantor - Call the Choir", "summon", 46, 3, 40, 1, (0, 0), False, (2, 2), (0, -60),
       proj=1.0, amin=0, amax=420, w=1.6, track=False, hs=0.0, shake=0.0)
attack("cantor_bolt", "Candle Cantor - Cold Flame", "bolt", 30, 2, 30, 16, (80, -40), True, (4, 4), (0, -30),
       proj=150.0, amin=50, amax=280, w=1.0, status=("frost", 28))

def enemy(id_, name, lore, atks, hp, poise, patrol, chase, det, vdet, cdmin, cdmax, recover, backstep, stagger,
          pstag, embers, resist, drops, leash=320):
    ext = ['[ext_resource type="Script" path="res://actors/enemies/enemy_data.gd" id="1_enemy"]']
    for i, a in enumerate(atks):
        ext.append(f'[ext_resource type="Resource" path="res://data/attacks/{a}.tres" id="a{i}"]')
    body = ""
    for n, (item, ch, ct) in enumerate(drops):
        ext.append(f'[ext_resource type="Resource" path="res://data/items/{item}.tres" id="d{n}"]')
    if len(drops) > 0:
        body += f'drop_item = ExtResource("d0")\ndrop_chance = {drops[0][1]}\ndrop_count = {drops[0][2]}\n'
    if len(drops) > 1:
        body += f'bonus_drop_item = ExtResource("d1")\nbonus_drop_chance = {drops[1][1]}\nbonus_drop_count = {drops[1][2]}\n'
    arr = ", ".join(f'ExtResource("a{i}")' for i in range(len(atks)))
    res = "{" + ", ".join(f'"{k}": {v}' for k, v in resist.items()) + "}"
    s = f'''[gd_resource type="Resource" script_class="EnemyData" load_steps={len(ext)+1} format=3]

{chr(10).join(ext)}

[resource]
script = ExtResource("1_enemy")
id = &"{id_}"
display_name = "{name}"
lore = "{lore}"
max_health = {hp:.1f}
max_poise = {poise:.1f}
poise_regen_delay_frames = 90
poise_regen_per_second = 30.0
patrol_speed = {patrol:.1f}
chase_speed = {chase:.1f}
detection_range = {det:.1f}
vertical_detection = {vdet:.1f}
leash_range = {leash:.1f}
attacks = [{arr}]
attack_cooldown_min = {cdmin}
attack_cooldown_max = {cdmax}
recover_frames = {recover}
backstep_speed = {backstep:.1f}
stagger_frames = {stagger}
parry_stagger_frames = {pstag}
ember_reward = {embers}
{body}status_resist = {res}
'''
    open(f"{R}/data/enemies/{id_}.tres", "w").write(s)

enemy("hollow_archer", "Hollow Archer", "The road watch kept bowmen on every rise. They still keep the rise. The arrows no longer care whose road it is.",
      ["archer_shot", "archer_knife"], 38, 14, 22, 52, 300, 110, 50, 90, 18, 60, 36, 90, 55,
      {"bleed": 0.2, "poison": 0.3}, [("ash_bandage", 0.2, 1), ("forge_scrap", 0.25, 1)], leash=380)
enemy("candle_cantor", "Candle Cantor", "The choir-master of a liturgy with no congregation. Every note it holds calls something small and burning out of the dark.",
      ["cantor_summon", "cantor_bolt"], 62, 22, 20, 44, 280, 110, 60, 100, 20, 60, 40, 100, 110,
      {"frost": 0.5, "burn": -0.3, "poison": 0.5}, [("pilgrims_draught", 0.25, 1), ("hollow_resin", 0.4, 1)], leash=380)

# Elites: tougher copies of existing enemies. (base id, new id, name, lore, hp, poise, dmg, speed, embers, extra resist)
def elite(base, new, name, lore, hp, poise, dmg, spd, embers, resist):
    s = open(f"{R}/data/enemies/{base}.tres").read()
    def setv(key, val, text):
        pat = re.compile(rf'^{key} = .*$', re.M)
        return pat.sub(f'{key} = {val}', text) if pat.search(text) else text.replace("\n[resource]\nscript = ExtResource(\"1_enemy\")\n", f"\n[resource]\nscript = ExtResource(\"1_enemy\")\n{key} = {val}\n")
    s = setv("id", f'&"{new}"', s)
    s = setv("display_name", f'"{name}"', s)
    s = setv("lore", f'"{lore}"', s)
    s = setv("max_health", f"{hp:.1f}", s)
    s = setv("max_poise", f"{poise:.1f}", s)
    m = re.search(r'^chase_speed = ([\d.]+)', s, re.M)
    s = setv("chase_speed", f"{float(m.group(1)) * spd:.1f}", s)
    s = setv("ember_reward", str(embers), s)
    s = setv("drop_chance", "1.0", s) if "drop_chance" in s else s
    s = setv("bonus_drop_chance", "1.0", s) if "bonus_drop_chance" in s else s
    s = setv("bonus_drop_count", "3", s) if "bonus_drop_count" in s else s
    s = s.rstrip("\n") + f"\nelite = true\npack_alert = true\ndamage_mult = {dmg}\nstatus_resist = " + "{" + ", ".join(f'"{k}": {v}' for k, v in resist.items()) + "}\n"
    # status_resist may already exist from the base: drop the first occurrence
    first = s.find("status_resist = ")
    last = s.rfind("status_resist = ")
    if first != last:
        end = s.find("\n", first)
        s = s[:first] + s[end + 1:]
    open(f"{R}/data/enemies/{new}.tres", "w").write(s)
    t = open(f"{R}/actors/enemies/{base}.tscn").read().replace(f"res://data/enemies/{base}.tres", f"res://data/enemies/{new}.tres")
    t = re.sub(r'\[node name="[^"]+" type="CharacterBody2D"\]', f'[node name="{name.replace(" ", "")}" type="CharacterBody2D"]', t, 1)
    open(f"{R}/actors/enemies/{new}.tscn", "w").write(t)

elite("hollow_penitent", "gilded_penitent", "Gilded Penitent", "One who swore twice. The second oath was gold-leafed, and heavier, and it has not let him lie down.", 190, 80, 1.3, 1.1, 240, {"bleed": 0.6, "poison": 1.0, "frost": 0.2})
elite("oathguard", "oathguard_captain", "Oathguard Captain", "He held the line longest, and the line is still held. Each of his shield-bearers fell around him; he took their oaths as well.", 320, 170, 1.3, 1.1, 420, {"bleed": 0.7, "frost": 0.4, "burn": 0.2})
elite("roadside_pikeman", "pike_sergeant", "Pike Sergeant", "He drilled the conscripts on this road. They never learned. He drills them still, and he drills hard.", 200, 95, 1.3, 1.15, 180, {"frost": 0.2, "bleed": 0.3})

# Scenes for the new archetypes (clones of the acolyte scene with a different script/visual/data).
def scene(name, script, data, visual, extra=""):
    s = open(f"{R}/actors/enemies/ember_acolyte.tscn").read()
    s = s.replace("actors/enemies/ranged_enemy.gd", f"actors/enemies/{script}.gd")
    s = s.replace("res://data/enemies/ember_acolyte.tres", f"res://data/enemies/{data}.tres")
    s = s.replace("actors/enemies/acolyte_visual.gd", f"actors/enemies/{visual}.gd")
    s = s.replace('[node name="EmberAcolyte" type="CharacterBody2D"]', f'[node name="{name}" type="CharacterBody2D"]')
    s = s.replace('data = ExtResource("2_data")\n', 'data = ExtResource("2_data")\n' + extra, 1)
    open(f"{R}/actors/enemies/{data}.tscn", "w").write(s)

scene("HollowArcher", "ranged_enemy", "hollow_archer", "archer_visual", "keep_min = 110.0\nkeep_max = 240.0\n")
# The cantor needs its minion scene as an ext_resource; add it by hand after cloning.
scene("CandleCantor", "summoner_enemy", "candle_cantor", "summoner_visual", "minion_scene = ExtResource(\"9_minion\")\nkeep_min = 100.0\nkeep_max = 230.0\n")
p = f"{R}/actors/enemies/candle_cantor.tscn"
t = open(p).read().replace('[sub_resource type="RectangleShape2D" id="body_shape"]',
    '[ext_resource type="PackedScene" path="res://actors/enemies/gloam_moth.tscn" id="9_minion"]\n\n[sub_resource type="RectangleShape2D" id="body_shape"]', 1)
t = t.replace("load_steps=11", "load_steps=12", 1)
open(p, "w").write(t)
print("ok")
