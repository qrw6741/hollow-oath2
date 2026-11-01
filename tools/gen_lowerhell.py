#!/usr/bin/env python3
"""Lower Hell content: the Fox (mini-boss, drops the Fox Tooth), the Burning Elder (fire-monster boss, teaches the
Fire Meteor jutsu), the Fox Tooth key item and the Fire Meteor art. Idempotent. Run after gen_nether.py.
Levels: tools/levels/gen_nether_levels.py (lower(), basement())."""
import os, sys, io, re, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G
A = G.attack

FOX = [
    ("lh_fox_bite", "Fox - Snap", "smash", 16, 5, 26, 34, (150, -90), True, (60, 34), (30, -20), 0.0, 0, 80, 1.2, None, 0.08, 4.0, True, 60.0, 12, 5),
    ("lh_fox_claws", "Fox - Raking Claws", "sweep", 14, 6, 24, 26, (170, -50), False, (78, 30), (34, -18), 0.0, 0, 90, 1.0, ("bleed", 25), 0.06, 4.0, True, 40.0, 10, 5),
    ("lh_fox_pounce", "Fox - Ground Pounce", "leap", 36, 7, 34, 46, (240, -160), False, (150, 36), (0, -14), 0.0, 90, 380, 1.2, None, 0.1, 11.0, False, 0.0, 0, 0),
    ("lh_fox_pounce2", "Fox - Quake Pounce", "leap", 26, 7, 26, 56, (260, -170), False, (190, 40), (0, -16), 0.0, 90, 420, 1.0, ("burn", 20), 0.1, 13.0, False, 0.0, 0, 0),
]
ELDER = [
    ("lh_eld_smash", "Elder - Burning Fist", "smash", 36, 7, 36, 62, (210, -120), True, (80, 60), (46, -28), 0.0, 0, 90, 1.2, ("burn", 45), 0.1, 8.0, True, 60.0, 30, 6),
    ("lh_eld_sweep", "Elder - Wall of Flame", "sweep", 30, 8, 32, 50, (230, -80), False, (150, 44), (60, -24), 0.0, 0, 120, 1.0, ("burn", 40), 0.1, 6.0, True, 0.0, 0, 0),
    ("lh_eld_throw", "Elder - Hurled Fireball", "throw", 28, 2, 30, 40, (100, -40), True, (4, 4), (0, -44), 280.0, 100, 420, 1.0, ("burn", 40), 0.05, 2.0, True, 0.0, 0, 0),
    ("lh_eld_leap", "Elder - Falling Star", "leap", 44, 7, 38, 70, (250, -170), False, (190, 40), (0, -16), 0.0, 110, 400, 1.0, ("burn", 40), 0.1, 12.0, False, 0.0, 0, 0),
]


def write_attacks(rows):
    ids = []
    for (aid, name, anim, su, act, rec, dmg, kb, parry, hs, ho, proj, amin, amax, w, st, hst, shake, track, lunge, lstart, lframes) in rows:
        A(aid, name, anim, su, act, rec, dmg, kb, parry, hs, ho, proj=proj, amin=amin, amax=amax, w=w, status=st, hs=hst, shake=shake, track=track, lunge=lunge, lstart=lstart, lframes=lframes)
        ids.append(aid)
    return ids


fox_ids = write_attacks(FOX)
eld_ids = write_attacks(ELDER)

# ---- items: the tooth is a key; the art's cast move is a harmless pose (the meteor is spawned by the player)
open(f"{R}/data/items/fox_tooth.tres", "w").write('''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://systems/items/item_data.gd" id="1_item"]

[resource]
script = ExtResource("1_item")
id = &"fox_tooth"
display_name = "Fox Tooth"
description = "A tooth as long as a hand, shaped like a key. It came out of the fox clean, the way a key leaves a lock. Somewhere in the Lower Hell a gate has a keyhole the shape of it."
kind = 1
effect = 0
effect_amount = 0.0
max_stack = 1
icon_color = Color(0.94, 0.9, 0.78, 1)
''')
A("art_fire_meteor", "Art - Fire Meteor", "smash", 14, 4, 22, 0, (0, 0), False, (4, 4), (20, -20), amin=0, amax=0, shake=2.0)

# ---- enemy data and scenes
G.enemy("tooth_fox", "The Gate-Fox",
        "It lives on the stairs to a door that is not supposed to open. It bit the last pilgrim who tried it. It kept the tooth that did not fit.",
        fox_ids[:3], 6500, 150, 130, 9000, "fox_tooth", "ember_shard")
G.boss("ToothFox", "tooth_fox", "tooth_fox", fox_ids, 13, hurt=(46, 30), music_pitch=0.8)
G.enemy("ember_elder", "The Burning Elder",
        "Chained in a cellar of grass, in a place with no grass. He had been asleep so long that the fire inside him had forgotten it was fire.",
        eld_ids[:3], 16000, 300, 62, 40000, "ember_shard", "ember_shard")
G.boss("EmberElder", "ember_elder", "ember_elder", eld_ids, 13, hurt=(40, 108), music_pitch=0.65)


def patch(path, visual, body, hurt, hitpos):
    s = open(path).read()
    s = s.replace("res://actors/bosses/brute_visual.gd", "res://actors/bosses/%s.gd" % visual)
    s = re.sub(r'(\[node name="Visual" type="Node2D" parent="\."\]\nscript = ExtResource\("7_visual"\)\n)(?:[a-z_]+ = [^\n]*\n?)*', r"\1", s, count=1)
    s = s.replace('[sub_resource type="RectangleShape2D" id="body_shape"]\nsize = Vector2(20, 46)', '[sub_resource type="RectangleShape2D" id="body_shape"]\nsize = Vector2(%d, %d)' % body)
    s = s.replace('[node name="Body" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -23)', '[node name="Body" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -%d)' % (body[1] // 2))
    s = s.replace('[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]\nposition = Vector2(0, -26)', '[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]\nposition = Vector2(0, -%d)' % (hurt[1] // 2 + 2))
    assert visual in s
    open(path, "w").write(s)


patch(f"{R}/actors/bosses/tooth_fox.tscn", "fox_visual", (30, 24), (46, 30), 0)
patch(f"{R}/actors/bosses/ember_elder.tscn", "inferno_visual", (30, 100), (40, 108), 0)


def edit(path, check, old, new):
    p = f"{R}/{path}"
    t = open(p).read()
    if check in t:
        return
    assert old in t, (path, old)
    open(p, "w").write(t.replace(old, new, 1))


edit("systems/items/items.gd", "fox_tooth", "&\"warden_bell_shard\", ", "&\"warden_bell_shard\", &\"fox_tooth\", ")
edit("ui/icons/icon_art.gd", "fox_tooth", '&"rusted_key", &"warden_bell_shard",', '&"rusted_key", &"warden_bell_shard", &"fox_tooth",')
edit("ui/icons/icon_art.gd", "_tooth(ci)", '\t\t&"rusted_key": _key(ci)\n', '\t\t&"rusted_key": _key(ci)\n\t\t&"fox_tooth": _tooth(ci)\n')
edit("ui/icons/icon_art.gd", "static func _tooth", "static func _axe(ci: CanvasItem) -> void:", '''static func _tooth(ci: CanvasItem) -> void:
	_poly(ci, [Vector2(5, 2), Vector2(11, 2), Vector2(12, 8), Vector2(9, 15), Vector2(8, 11), Vector2(7, 15), Vector2(4, 8)], Color("efe6d2"))
	ci.draw_line(Vector2(6, 4), Vector2(10, 4), Color("c9b98e"), 1.0)
	ci.draw_line(Vector2(8, 5), Vector2(8, 11), Color("c9b98e"), 0.8)


static func _axe(ci: CanvasItem) -> void:''')
edit("systems/bestiary.gd", "tooth_fox", "&\"morvane_warden\", ", "&\"morvane_warden\", &\"tooth_fox\", &\"ember_elder\", ")
print("lowerhell ok")
