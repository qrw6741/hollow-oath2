#!/usr/bin/env python3
"""Generates world/levels/forsaken_village.tscn (blockout + content placement).

Layout (floor y = 480, x grows to the right):
  A  0-640      Outskirts: entry from the Yard, Village Gate Candle, a Penitent.
                Shortcut gate at x 660 (lever on its right side) seals the lower corridor.
  B  660-1480   Rooftops (top y 330) over a low corridor (y 400-480). Main route goes over
                the roofs: a Penitent and an Ember Acolyte up there, a tonic on the chimney.
                The corridor below leads back to the shortcut gate (ember shard, Penitent).
  C  1540-2440  Village square: a Bell-Bearer, an Acolyte on a balcony, a Candlewright's note.
  D  2440-3400  Chapel road: Chapel Steps Candle, two Penitents, a spike pit, an Acolyte on a
                ledge, steps up to the chapel door, which leads down into the Drowned Catacombs.
Re-run after editing:  python3 tools/levels/gen_forsaken_village.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels", "forsaken_village.tscn")

ext = [
    ("Script", "res://world/levels/level.gd", "level"),
    ("Script", "res://world/blocks/stone_block.gd", "block"),
    ("Script", "res://world/hazards/spike_pit.gd", "spikes"),
    ("PackedScene", "res://world/checkpoint/oath_candle.tscn", "candle"),
    ("Script", "res://world/spawners/enemy_spawner.gd", "spawner"),
    ("PackedScene", "res://actors/enemies/hollow_penitent.tscn", "penitent"),
    ("PackedScene", "res://actors/enemies/ember_acolyte.tscn", "acolyte"),
    ("PackedScene", "res://actors/enemies/bell_bearer.tscn", "bearer"),
    ("PackedScene", "res://actors/enemies/gloam_moth.tscn", "moth"),
    ("PackedScene", "res://actors/enemies/oathguard.tscn", "oathguard"),
    ("PackedScene", "res://actors/enemies/mimic.tscn", "mimic"),
    ("Script", "res://world/pickups/treasure_chest.gd", "chest"),
    ("Script", "res://world/background/ruins_silhouette.gd", "ruins"),
    ("Script", "res://world/background/sky.gd", "sky"),
    ("Script", "res://world/pickups/item_pickup.gd", "pickup"),
    ("Script", "res://world/transitions/level_exit.gd", "exit"),
    ("Script", "res://world/transitions/level_entry.gd", "entry"),
    ("Script", "res://world/transitions/shortcut_gate.gd", "gate"),
    ("Resource", "res://data/items/ash_bandage.tres", "it_band"),
    ("Resource", "res://data/items/ember_shard.tres", "it_shard"),
    ("Resource", "res://data/items/stamina_tonic.tres", "it_tonic"),
    ("Resource", "res://data/items/candlewright_note.tres", "it_note"),
]

nodes = []
seed = [40]


def node(text):
    nodes.append(text.strip("\n"))


def block(name, x, y, w, h, style=0, one_way=False):
    seed[0] += 1
    node(f'''
[node name="{name}" type="StaticBody2D" parent="Geometry"]
position = Vector2({x}, {y})
script = ExtResource("block")
size = Vector2({w}, {h})
style = {style}
seed_value = {seed[0]}''' + ("\none_way = true" if one_way else ""))


def plank(name, x, y, w):
    block(name, x, y, w, 6, style=2, one_way=True)


def enemy(name, scene, x, y, patrol=40.0, facing=-1, spawn_id=""):
    node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spawner")
enemy_scene = ExtResource("{scene}")
patrol_distance = {patrol}
start_facing = {facing}''' + (f'\nspawn_id = &"{spawn_id}"' if spawn_id else ""))


def chest(name, x, y, cid, item=None, count=1, embers=0):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("chest")
chest_id = &"{cid}"
count = {count}
embers = {embers}''' + (f'\nitem = ExtResource("{item}")' if item else ""))


def candle(name, x, y, cid, title):
    node(f'''
[node name="{name}" parent="." instance=ExtResource("candle")]
position = Vector2({x}, {y})
checkpoint_id = &"{cid}"
display_name = "{title}"''')


def pickup(name, x, y, item, count, pid):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("pickup")
item = ExtResource("{item}")
count = {count}
pickup_id = &"{pid}"''')


# ------------------------------------------------------------------ root & background
node('''
[node name="ForsakenVillage" type="Node2D"]
script = ExtResource("level")
level_id = &"forsaken_village"
display_name = "The Forsaken Village"
bounds = Rect2(0, 0, 3432, 540)
music = &"village"
map_origin = Vector2(2468, -32)
default_spawn = Vector2(96, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(96, 52)

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.15, 0.1)

[node name="Ruins" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 210.0
max_height = 140.0
color = Color(0.082, 0.086, 0.110, 1)
window_color = Color(0.549, 0.239, 0.133, 0.45)
seed_value = 23
spacing = 55.0
width = 1400.0
haze_color = Color(0.26, 0.28, 0.34, 1)

[node name="Mid" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.4, 0.3)

[node name="Ruins" type="Node2D" parent="Background/Mid"]
script = ExtResource("ruins")
base_y = 250.0
max_height = 110.0
color = Color(0.102, 0.106, 0.133, 1)
window_color = Color(0.549, 0.239, 0.133, 0.3)
seed_value = 29
spacing = 70.0
width = 2200.0
haze_color = Color(0.26, 0.28, 0.34, 1)

[node name="Near" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.7, 0.6)

[node name="Ruins" type="Node2D" parent="Background/Near"]
script = ExtResource("ruins")
base_y = 330.0
max_height = 90.0
color = Color(0.125, 0.125, 0.150, 1)
seed_value = 31
spacing = 120.0
width = 3000.0
haze_color = Color(0.26, 0.28, 0.34, 1)

[node name="Darkness" type="CanvasModulate" parent="."]
color = Color(0.62, 0.65, 0.74, 1)

[node name="Geometry" type="Node2D" parent="."]''')

# ------------------------------------------------------------------ geometry
# A: outskirts
block("WallLeftTop", 0, 0, 32, 400, style=0)
block("FloorA", 0, 480, 640, 60)
plank("StepA1", 490, 436, 60)
plank("StepA2", 572, 392, 56)
plank("StepA3", 616, 348, 44)
# B: rooftops over the corridor
block("Houses", 660, 330, 820, 70)
block("Chimney", 900, 290, 120, 40)
block("CorridorFloor", 640, 480, 900, 60)
# C: square
block("FloorC", 1540, 480, 900, 60)
plank("Balcony", 2140, 390, 110)
plank("SquareLedge", 1560, 420, 60)
# D: chapel road
block("FloorD1", 2440, 480, 400, 60)
block("PitFloor", 2840, 520, 60, 20, style=1)
block("FloorD2", 2900, 480, 180, 60)
plank("HighLedge", 2700, 380, 90)
plank("ShardLedge", 2960, 400, 60)
block("StepD1", 3080, 440, 120, 100)
block("StepD2", 3200, 400, 200, 140)
block("WallRight", 3400, 0, 32, 540)
node('''
[node name="ChapelSpikes" type="Area2D" parent="Geometry"]
position = Vector2(2840, 520)
script = ExtResource("spikes")
width = 60.0''')

# ------------------------------------------------------------------ transitions
node('''
[node name="FromYard" type="Marker2D" parent="."]
position = Vector2(92, 480)
script = ExtResource("entry")
entry_id = &"from_yard"

[node name="ToYard" type="Area2D" parent="."]
position = Vector2(40, 480)
script = ExtResource("exit")
target_level = "res://world/levels/test_arena.tscn"
target_entry = &"bell_door"
size = Vector2(12, 80)

[node name="ShortcutGate" type="StaticBody2D" parent="."]
position = Vector2(660, 480)
script = ExtResource("gate")
gate_id = &"village_corridor"
height = 80.0
lever_side = 1

[node name="ChapelDoor" type="Area2D" parent="."]
position = Vector2(3330, 400)
script = ExtResource("exit")
target_level = "res://world/levels/drowned_catacombs.tscn"
target_entry = &"from_chapel"
mode = 1
size = Vector2(30, 60)
door_id = &"chapel_door"
display_name = "the chapel doors"

[node name="FromCatacombs" type="Marker2D" parent="."]
position = Vector2(3372, 400)
script = ExtResource("entry")
entry_id = &"chapel_door"''')

# ------------------------------------------------------------------ candles, enemies, pickups
candle("GateCandle", 200, 480, "village_gate_candle", "Village Gate Candle")
candle("ChapelCandle", 2500, 480, "chapel_steps_candle", "Chapel Steps Candle")

enemy("PenitentA", "penitent", 470, 480, 40.0)
enemy("PenitentRoof", "penitent", 820, 330, 30.0)
enemy("AcolyteRoof", "acolyte", 1300, 330, 20.0)
enemy("PenitentCorridor", "penitent", 1120, 480, 60.0, 1)
enemy("BearerSquare", "bearer", 1960, 480, 50.0)
enemy("AcolyteBalcony", "acolyte", 2200, 390, 0.0)
enemy("PenitentRoad1", "penitent", 2680, 480, 50.0)
enemy("AcolyteLedge", "acolyte", 2745, 380, 0.0)
enemy("PenitentRoad2", "penitent", 2990, 480, 30.0)
enemy("BearerSteps", "bearer", 3230, 400, 20.0)

pickup("PickupBandage", 330, 480, "it_band", 1, "village_bandage")
pickup("PickupTonic", 960, 290, "it_tonic", 1, "village_tonic")
pickup("PickupCorridorShard", 720, 480, "it_shard", 1, "village_corridor_shard")
pickup("PickupNote", 2400, 480, "it_note", 1, "village_note")
pickup("PickupLedgeShard", 2990, 400, "it_shard", 1, "village_ledge_shard")

node('''
[node name="Ash" type="CPUParticles2D" parent="."]
position = Vector2(1716, -10)
amount = 110
lifetime = 14.0
preprocess = 14.0
emission_shape = 3
emission_rect_extents = Vector2(1740, 4)
direction = Vector2(0.3, 1)
spread = 25.0
gravity = Vector2(6, 10)
initial_velocity_min = 4.0
initial_velocity_max = 12.0
color = Color(0.62, 0.64, 0.7, 0.45)
z_index = 5''')

# New enemy types
enemy("MothRoofs", "moth", 1150, 262, 60.0)
enemy("MothSquare", "moth", 1820, 400, 70.0)
enemy("OathguardSquare", "oathguard", 1680, 480, 40.0)
chest("CorridorChest", 1360, 480, "village_corridor_chest", item="it_band", count=2, embers=120)
enemy("MimicLedge", "mimic", 1590, 420, 0.0, 1, spawn_id="village_ledge_mimic")

header = f'[gd_scene load_steps={len(ext) + 1} format=3]\n\n'
header += "\n".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]' for t, p, i in ext)
open(OUT, "w").write(header + "\n\n" + "\n\n".join(nodes) + "\n")
print("wrote", os.path.relpath(OUT, ROOT))
