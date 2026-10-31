#!/usr/bin/env python3
"""Generates 'The Ninth Hell' content: Morvane the Warden of the Ninth Door (custom boss), the Twin Lords
(Ashkar the Black Reaper + Veshti the Far Hand, fought at once), their attacks/data/scenes, the Nightreaper
(an overpowered weapon cloned from the greataxe), and registers everything in the GDScript lists.
Levels (the Ninth Door, the Ninth Hell) are written by tools/levels/gen_nether_levels.py.
Idempotent.   Run: python3 tools/gen_nether.py && python3 tools/levels/gen_side_levels.py"""
import os, sys, io, re, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G

A = G.attack
# ---- Morvane, Warden of the Ninth Door: a heavy greatsword duelist wreathed in dull red fire
MORV = [
    ("nx_morv_smash", "Morvane - Door-Splitter", "smash", 38, 7, 38, 58, (200, -110), True, (70, 48), (34, -26), 0.0, 0, 70, 1.2, ("burn", 40), 0.1, 8.0, True, 55.0, 30, 6),
    ("nx_morv_sweep", "Morvane - Closing Arc", "sweep", 30, 8, 32, 46, (220, -70), False, (110, 34), (46, -22), 0.0, 0, 95, 1.0, ("burn", 30), 0.1, 5.0, True, 0.0, 0, 0),
    ("nx_morv_throw", "Morvane - Hurled Ember", "throw", 28, 2, 30, 36, (90, -40), True, (4, 4), (0, -34), 260.0, 90, 380, 1.0, ("burn", 40), 0.05, 2.0, True, 0.0, 0, 0),
    ("nx_morv_leap", "Morvane - Falling Door", "leap", 50, 7, 40, 66, (240, -170), False, (150, 36), (0, -14), 0.0, 100, 340, 1.0, ("burn", 35), 0.1, 11.0, False, 0.0, 0, 0),
]
# ---- Ashkar, the Black Reaper (scythe): long reach, slow and heavy, a leaping reap
REAP = [
    ("nx_reap_sweep", "Ashkar - Reaping Arc", "sweep", 30, 8, 34, 50, (230, -80), False, (136, 40), (60, -28), 0.0, 0, 130, 1.3, ("burn", 40), 0.1, 6.0, True, 0.0, 0, 0),
    ("nx_reap_smash", "Ashkar - Harvest Fall", "smash", 38, 6, 36, 58, (190, -120), True, (74, 62), (50, -30), 0.0, 0, 86, 1.1, ("burn", 40), 0.1, 8.0, True, 70.0, 30, 6),
    ("nx_reap_leap", "Ashkar - Black Crescent", "leap", 48, 6, 38, 62, (240, -170), False, (150, 40), (0, -14), 0.0, 100, 330, 1.0, ("burn", 40), 0.1, 11.0, False, 0.0, 0, 0),
    ("nx_reap_rush", "Ashkar - Fury Reap", "sweep", 20, 8, 26, 46, (230, -80), False, (136, 40), (60, -28), 0.0, 0, 140, 1.4, ("burn", 40), 0.08, 6.0, True, 0.0, 0, 0),
]
# ---- Veshti, the Far Hand (gun): shoots from range, a quick double shot, a butt-strike when cornered
GUN = [
    ("nx_gun_shot", "Veshti - Black Shot", "shoot", 30, 2, 26, 38, (110, -50), True, (4, 4), (0, -34), 360.0, 110, 460, 1.4, ("burn", 40), 0.06, 3.0, True, 0.0, 0, 0),
    ("nx_gun_double", "Veshti - Twin Report", "shoot", 18, 2, 22, 30, (100, -40), True, (4, 4), (0, -34), 420.0, 110, 460, 1.0, ("burn", 40), 0.05, 2.5, True, 0.0, 0, 0),
    ("nx_gun_butt", "Veshti - Stock Strike", "butt", 20, 5, 28, 40, (200, -90), True, (56, 44), (30, -30), 0.0, 0, 70, 1.6, ("burn", 30), 0.08, 5.0, True, 40.0, 14, 5),
    ("nx_gun_rapid", "Veshti - Hail of Cinders", "shoot", 14, 2, 20, 26, (90, -30), False, (4, 4), (0, -34), 470.0, 140, 460, 0.8, ("burn", 40), 0.04, 2.0, True, 0.0, 0, 0),
]


def write_attacks(rows):
    ids = []
    for (aid, name, anim, su, act, rec, dmg, kb, parry, hs, ho, proj, amin, amax, w, st, hst, shake, track, lunge, lstart, lframes) in rows:
        A(aid, name, anim, su, act, rec, dmg, kb, parry, hs, ho, proj=proj, amin=amin, amax=amax, w=w, status=st, hs=hst, shake=shake, track=track, lunge=lunge, lstart=lstart, lframes=lframes)
        ids.append(aid)
    return ids


def hexcol(h):
    h = h.lstrip("#")
    return "Color(%.3f, %.3f, %.3f, 1)" % tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def scene_text(path, fn):
    s = open(path).read()
    s = fn(s)
    open(path, "w").write(s)


morv_ids = write_attacks(MORV)
reap_ids = write_attacks(REAP)
gun_ids = write_attacks(GUN)

# ---------------------------------------------------------------- enemy data + scenes
G.enemy("morvane_warden", "Morvane, Warden of the Ninth Door",
        "He held the last door when the Court fell asleep. He was told to keep it shut. He did not ask what was behind it.",
        morv_ids[:3], 14000, 260, 55, 50000, "ember_shard", "ember_shard")
G.boss("MorvaneWarden", "morvane_warden", "morvane_warden", morv_ids, 13, hurt=(30, 58), music_pitch=0.6)


def patch_morvane(s):
    return re.sub(r"(\[node name=\"Visual\" type=\"Node2D\" parent=\"\.\"\]\nscript = ExtResource\(\"7_visual\"\)\nstyle = )\d+",
                  lambda m: m.group(1) + "13\ncustom_coat = %s\ncustom_trim = %s\ncustom_long = true\ncustom_prop = 2\ncustom_scale = 1.18" % (hexcol("#2a0c0c"), hexcol("#c8402a")), s, count=1)


scene_text(f"{R}/actors/bosses/morvane_warden.tscn", patch_morvane)

G.enemy("ashkar_reaper", "Ashkar, the Black Reaper",
        "One of the two hands that sign the oath and take it back. He wears the wrappings of the first dead, and a scythe that cuts in black flame.",
        reap_ids[:3], 9500, 220, 58, 30000, "ember_shard", "ember_shard")
G.boss("AshkarReaper", "ashkar_reaper", "ashkar_reaper", reap_ids, 13, hurt=(18, 70), music_pitch=0.55)
G.enemy("veshti_gunner", "Veshti, the Far Hand",
        "The other hand: she never walks closer than she has to. She was only ever taught to point, and to wait for the end of the line.",
        gun_ids[:3], 9500, 220, 70, 30000, "ember_shard", "ember_shard")
G.boss("VeshtiGunner", "veshti_gunner", "veshti_gunner", gun_ids, 13, hurt=(18, 70), music_pitch=0.55)


def patch_twin(weapon, script):
    def fn(s):
        s = s.replace('res://actors/bosses/brute_visual.gd', 'res://actors/bosses/wrapped_visual.gd')
        if script:
            s = s.replace('res://actors/bosses/boss_base.gd', script)
        s = re.sub(r'(\[node name="Visual" type="Node2D" parent="\."\]\nscript = ExtResource\("7_visual"\)\n)style = \d+', r'\1weapon = %d' % weapon, s, count=1)
        s = s.replace('[sub_resource type="RectangleShape2D" id="body_shape"]\nsize = Vector2(20, 46)', '[sub_resource type="RectangleShape2D" id="body_shape"]\nsize = Vector2(16, 62)')
        s = s.replace('[node name="Body" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -23)', '[node name="Body" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -31)')
        s = s.replace('[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]\nposition = Vector2(0, -26)', '[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]\nposition = Vector2(0, -35)')
        assert "wrapped_visual" in s and "weapon = %d" % weapon in s
        return s
    return fn


scene_text(f"{R}/actors/bosses/ashkar_reaper.tscn", patch_twin(0, None))
scene_text(f"{R}/actors/bosses/veshti_gunner.tscn", patch_twin(1, "res://actors/bosses/gunner_lord.gd"))

# ---------------------------------------------------------------- the Nightreaper (OP weapon)
s = open(f"{R}/data/weapons/gravediggers_greataxe.tres").read()
s = re.sub(r'id = &"[a-z_]+"', 'id = &"nightreaper"', s, count=1)
s = re.sub(r'display_name = ".*"', 'display_name = "Nightreaper"', s, count=1)
s = re.sub(r'description = ".*"', 'description = "Ashkar\'s scythe, wrapped in the black flame that hunted him. It was never meant to be carried by the living. It is by far the strongest weapon in the game."', s, count=1)
s = re.sub(r'status = &"[a-z]*"', 'status = &"burn"', s, count=1)
s = re.sub(r'status_amount = [0-9.]+', 'status_amount = 55.0', s, count=1)
if "damage_mult = " in s:
    s = re.sub(r'damage_mult = [0-9.]+', 'damage_mult = 2.0', s, count=1)
else:
    s = s.replace("\ntwo_handed", "\ndamage_mult = 2.0\ntwo_handed", 1)
open(f"{R}/data/weapons/nightreaper.tres", "w").write(s)


# ---------------------------------------------------------------- registration (idempotent)
def edit(path, check, old, new):
    p = f"{R}/{path}"
    t = open(p).read()
    if check in t:
        return
    assert old in t, (path, old)
    open(p, "w").write(t.replace(old, new, 1))


edit("systems/bestiary.gd", '&"morvane_warden"', '&"the_unkept_promise", &"swollen_pilgrim"',
     '&"the_unkept_promise", &"morvane_warden", &"ashkar_reaper", &"veshti_gunner", &"swollen_pilgrim"')
edit("systems/weapons.gd", '&"nightreaper"', '&"unkept_blade"]', '&"unkept_blade", &"nightreaper"]')
edit("systems/weapons.gd", '&"nightreaper":', '\t&"unkept_blade": "A hidden chest',
     '\t&"nightreaper": "Dropped by the Twin Lords, Ashkar and Veshti, at the end of the Ninth Hell.",\n\t&"unkept_blade": "A hidden chest')
edit("ui/icons/icon_art.gd", "nightreaper", '&"gravediggers_greataxe", &"bone_cleaver", &"namebreaker": _axe(ci)',
     '&"gravediggers_greataxe", &"bone_cleaver", &"namebreaker", &"nightreaper": _axe(ci)')
edit("systems/boss_gimmicks.gd", "morvane_warden", '	&"hollow_marshal":',
     '	&"morvane_warden": [{"kind": "wave", "every": 5.5, "phase": 1}, {"kind": "mark", "every": 5.0, "phase": 2}, {"kind": "enrage"}],\n'
     '	&"ashkar_reaper": [{"kind": "mark", "every": 4.5, "phase": 1}, {"kind": "rain", "every": 7.0, "phase": 2}],\n'
     '	&"veshti_gunner": [{"kind": "rain", "every": 5.5, "phase": 1}, {"kind": "mark", "every": 5.0, "phase": 2}],\n'
     '	&"hollow_marshal":')
edit("systems/progress.gd", "morvane_warden", '	{"boss": &"the_unkept_promise", "name": "the Unkept Promise", "area": "The Wakeless Court"},\n',
     '	{"boss": &"the_unkept_promise", "name": "the Unkept Promise", "area": "The Wakeless Court"},\n'
     '	{"boss": &"morvane_warden", "name": "Morvane, Warden of the Ninth Door", "area": "The Ninth Door"},\n'
     '	{"boss": &"ashkar_reaper", "name": "the Twin Lords", "area": "The Ninth Hell"},\n')
edit("systems/world_map.gd", "the_ninth_door", '	"res://world/levels/wakeless_court.tscn",\n',
     '	"res://world/levels/wakeless_court.tscn",\n	"res://world/levels/the_ninth_door.tscn",\n	"res://world/levels/ninth_hell.tscn",\n')
print("nether ok")
