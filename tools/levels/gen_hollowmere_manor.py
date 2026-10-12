#!/usr/bin/env python3
"""Generates world/levels/hollowmere_manor.tscn: the old haunted manor reached with the
Hollowmere Sigil. A peaceful hub: front hall (the door back to the road, a candle), Ommen,
Hobb's forge, Sister Ilse's conservatory, Wenna's trade hall, a mezzanine with a chest and a
ledger, Steward Aldous Vane, and the Gallery (locked until the cellar key is won) and the cellar door.
Re-run after editing:  python3 tools/levels/gen_hollowmere_manor.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels", "hollowmere_manor.tscn")
W = 2500

ext = [
    ("Script", "res://world/levels/level.gd", "level"),
    ("Script", "res://world/blocks/stone_block.gd", "block"),
    ("PackedScene", "res://world/checkpoint/oath_candle.tscn", "candle"),
    ("Script", "res://world/background/manor_hall.gd", "hall"),
    ("Script", "res://world/transitions/level_exit.gd", "exit"),
    ("Script", "res://world/transitions/level_entry.gd", "entry"),
    ("Script", "res://world/transitions/manor_door.gd", "mdoor"),
    ("Script", "res://world/story/lore_tablet.gd", "tablet"),
    ("Script", "res://world/pickups/treasure_chest.gd", "chest"),
    ("Script", "res://world/npcs/npc.gd", "npc"),
    ("Resource", "res://data/items/forge_scrap.tres", "it_scrap"),
]
nodes = []
seed = [700]


def node(t):
    nodes.append(t.strip("\n"))


def block(name, x, y, w, h, style=1, one_way=False):
    seed[0] += 1
    node(f'''
[node name="{name}" type="StaticBody2D" parent="Geometry"]
position = Vector2({x}, {y})
script = ExtResource("block")
size = Vector2({w}, {h})
style = {style}
seed_value = {seed[0]}''' + ("\none_way = true" if one_way else ""))


def npc(name, x, nid, title, look, shop="", station="", facing=-1):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, 480)
script = ExtResource("npc")
npc_id = &"{nid}"
display_name = "{title}"
look = {look}
start_facing = {facing}''' + (f'\nshop_id = &"{shop}"' if shop else "") + (f'\nstation = &"{station}"' if station else ""))


node(f'''
[node name="HollowmereManor" type="Node2D"]
script = ExtResource("level")
level_id = &"hollowmere_manor"
display_name = "Hollowmere Manor"
bounds = Rect2(0, 0, {W}, 540)
music = &"menu"
music_pitch = 0.78
map_origin = Vector2(0, -2100)
default_spawn = Vector2(150, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 9

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.64, 0.6, 0.78, 1)

[node name="Geometry" type="Node2D" parent="."]''')

block("Floor", 0, 480, W, 60, style=1)
block("Ceiling", 0, 40, W, 56, style=1)
block("WallLeft", 0, 0, 24, 480, style=1)
block("WallRight", W - 24, 0, 24, 480, style=1)
# Mezzanine: a stair of planks (each step ~45 px) up to a balcony
for i, (x, y) in enumerate([(1240, 435), (1310, 390), (1380, 345), (1450, 300)]):
    block(f"Stair{i+1}", x, y, 60, 6, style=2, one_way=True)
block("Balcony", 1520, 300, 300, 6, style=2, one_way=True)

node(f'''
[node name="Arrival" type="Marker2D" parent="."]
position = Vector2(150, 480)
script = ExtResource("entry")
entry_id = &"arrival"

[node name="ReturnDoor" type="Area2D" parent="."]
position = Vector2(70, 480)
script = ExtResource("mdoor")

[node name="HollowmereCandle" parent="." instance=ExtResource("candle")]
position = Vector2(330, 480)
checkpoint_id = &"hollowmere_candle"
display_name = "Hollowmere Candle"''')

npc("Ommen", 520, "ommen", "Hooded Figure", 1, facing=1)
npc("Hobb", 740, "hobb", "Hobb", 2, station="forge", facing=1)
npc("Ilse", 920, "ilse", "Sister Ilse", 3, station="vials", facing=-1)
npc("Wenna", 1100, "wenna", "Wenna", 0, shop="pedlar", facing=-1)
npc("Aldous", 2000, "aldous", "Aldous Vane", 4, facing=-1)

node('''
[node name="VisitorsLedger" type="Area2D" parent="."]
position = Vector2(1620, 300)
script = ExtResource("tablet")
title = "The Visitors' Ledger"
text = "Hollowmere Manor, Visitors' Ledger. The last entries are in a dozen hands, none of them steady: 'Rested here, the road being what it is.' 'Hobb is a good man.' 'Do not talk to the portraits.' Under the last line, in a very neat hand: 'Dinner is at eight. It has been eight for some time.'"

[node name="BalconyChest" type="Area2D" parent="."]
position = Vector2(1760, 300)
script = ExtResource("chest")
chest_id = &"manor_balcony_chest"
count = 4
embers = 350
item = ExtResource("it_scrap")''')

node(f'''
[node name="GalleryDoor" type="Area2D" parent="."]
position = Vector2({W - 90}, 480)
script = ExtResource("exit")
target_level = "res://world/levels/hollowmere_gallery.tscn"
target_entry = &"from_manor"
mode = 1
size = Vector2(30, 80)
display_name = "the Gallery"
required_item = &"gallery_key"
door_id = &"hollowmere_gallery"
locked_text = "The Gallery is locked. The key lies below the house."
unlock_text = "The key turns."

[node name="FromGallery" type="Marker2D" parent="."]
position = Vector2({W - 150}, 480)
script = ExtResource("entry")
entry_id = &"from_gallery"

[node name="CellarDoor" type="Area2D" parent="."]
position = Vector2(640, 480)
script = ExtResource("exit")
target_level = "res://world/levels/hollowmere_cellar.tscn"
target_entry = &"from_manor"
mode = 1
size = Vector2(30, 64)
display_name = "the cellar"

[node name="FromCellar" type="Marker2D" parent="."]
position = Vector2(690, 480)
script = ExtResource("entry")
entry_id = &"from_cellar"

[node name="Motes" type="CPUParticles2D" parent="."]
position = Vector2({W // 2}, 120)
amount = 60
lifetime = 14.0
preprocess = 14.0
emission_shape = 3
emission_rect_extents = Vector2({W // 2}, 4)
direction = Vector2(0, 1)
spread = 40.0
gravity = Vector2(0, 3)
initial_velocity_min = 2.0
initial_velocity_max = 8.0
color = Color(0.8, 0.85, 1, 0.35)
scale_amount_min = 0.6
scale_amount_max = 1.2
z_index = 5''')

header = f'[gd_scene load_steps={len(ext) + 1} format=3]\n\n'
header += "\n".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]' for t, p, i in ext)
open(OUT, "w").write(header + "\n\n" + "\n\n".join(nodes) + "\n")
print("wrote", os.path.relpath(OUT, ROOT))
