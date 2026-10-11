#!/usr/bin/env python3
"""Generates world/levels/drowned_catacombs.tscn (blockout + content placement).

The catacombs lie under the village chapel; two screens tall (0..1080), flooded.
  Ossuary Stair   x 0-600, floor y 240: arrival from the chapel, Ossuary Candle.
  The Descent     x 600-1240: eight steps of 45 px down to the hall (climbable back up).
  Flooded Nave    x 1240-2200, floor y 660, waist-deep water (slows you), a drowned shaft
                  at x 1700 (falling in is death; a broken pillar top is the stepping stone),
                  Acolytes on pillar ledges, a Bell-Bearer and Penitents in the water.
  Canon's Ledge   x 2200-2440, top y 560: Canon's Rest candle. A cracked wall under it
                  hides an alcove (hit it three times).
  The Drowned Choir (boss arena) x 2440-3168, floor y 720, shallow water: the Drowned
                  Canon. Behind it the stair to the Ashen Cathedral (end of this build).
Re-run after editing:  python3 tools/levels/gen_drowned_catacombs.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels", "drowned_catacombs.tscn")

ext = [
    ("Script", "res://world/levels/level.gd", "level"),
    ("Script", "res://world/blocks/stone_block.gd", "block"),
    ("PackedScene", "res://world/checkpoint/oath_candle.tscn", "candle"),
    ("Script", "res://world/spawners/enemy_spawner.gd", "spawner"),
    ("PackedScene", "res://actors/enemies/hollow_penitent.tscn", "penitent"),
    ("PackedScene", "res://actors/enemies/ember_acolyte.tscn", "acolyte"),
    ("PackedScene", "res://actors/enemies/bell_bearer.tscn", "bearer"),
    ("Script", "res://world/background/ruins_silhouette.gd", "ruins"),
    ("Script", "res://world/pickups/item_pickup.gd", "pickup"),
    ("Script", "res://world/transitions/level_exit.gd", "exit"),
    ("Script", "res://world/transitions/level_entry.gd", "entry"),
    ("Script", "res://world/hazards/water_zone.gd", "water"),
    ("Script", "res://world/hazards/drown_zone.gd", "drown"),
    ("Script", "res://world/blocks/breakable_wall.gd", "wall"),
    ("Script", "res://world/boss/boss_arena.gd", "bossarena"),
    ("PackedScene", "res://actors/bosses/drowned_canon.tscn", "canon"),
    ("Resource", "res://data/items/ash_bandage.tres", "it_band"),
    ("Resource", "res://data/items/ember_shard.tres", "it_shard"),
    ("Resource", "res://data/items/stamina_tonic.tres", "it_tonic"),
]

nodes = []
seed = [100]


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


def enemy(name, scene, x, y, patrol=40.0, facing=-1):
    node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spawner")
enemy_scene = ExtResource("{scene}")
patrol_distance = {patrol}
start_facing = {facing}''')


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


def water(name, x, y, w, h):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("water")
size = Vector2({w}, {h})''')


node('''
[node name="DrownedCatacombs" type="Node2D"]
script = ExtResource("level")
level_id = &"drowned_catacombs"
display_name = "The Drowned Catacombs"
bounds = Rect2(0, 0, 3200, 1080)
music = &"catacombs"
map_origin = Vector2(5900, 200)
default_spawn = Vector2(90, 240)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Back" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.3, 0.3)

[node name="Vaults" type="Node2D" parent="Background/Back"]
script = ExtResource("ruins")
base_y = 330.0
max_height = 200.0
color = Color(0.07, 0.08, 0.09, 1)
window_color = Color(0.25, 0.45, 0.42, 0.25)
seed_value = 51
spacing = 80.0
width = 1600.0
haze = 0.45
haze_color = Color(0.12, 0.18, 0.2, 1)

[node name="Darkness" type="CanvasModulate" parent="."]
color = Color(0.48, 0.55, 0.58, 1)

[node name="Geometry" type="Node2D" parent="."]''')

# Cave shell
block("Ceiling", 0, 0, 3200, 40, style=1)
block("WallLeft", 0, 40, 24, 160, style=0)
block("WallRight", 3168, 0, 32, 1080)
# Ossuary stair (arrival)
block("FloorTop", 0, 240, 600, 840)
# The descent: 8 steps of 45 px
for i in range(8):
    block("Step%d" % (i + 1), 600 + i * 80, 285 + i * 45, 80, 1080 - (285 + i * 45))
# Flooded nave
block("NaveFloorA", 1240, 660, 460, 420)
block("NaveFloorB", 1764, 660, 436, 420)
block("ShaftBottom", 1700, 1060, 64, 20, style=1)
plank("BrokenPillar", 1720, 646, 24)
plank("PillarLedgeA", 1440, 560, 80)
plank("PillarLedgeB", 1960, 560, 80)
plank("NaveStep1", 2096, 625, 50)
plank("NaveStep2", 2150, 592, 46)
# Canon's ledge with a hidden alcove under it
block("LedgeTop", 2200, 560, 240, 40)
block("LedgeBase", 2290, 600, 150, 60)
block("NaveFloorC", 2200, 660, 240, 420)
# Boss arena
block("GatePillar", 2440, 40, 24, 424)
block("ArenaFloor", 2440, 720, 728, 360)
block("ArenaLip", 2440, 560, 24, 160)

water("NaveWater", 1240, 630, 960, 30)
water("ArenaWater", 2464, 700, 704, 20)
node('''
[node name="DrownedShaft" type="Area2D" parent="."]
position = Vector2(1700, 700)
script = ExtResource("drown")
size = Vector2(64, 360)

[node name="CrackedWall" type="StaticBody2D" parent="."]
position = Vector2(2200, 600)
script = ExtResource("wall")
size = Vector2(16, 60)
wall_id = &"canon_alcove"
hits_needed = 3''')

# Transitions
node('''
[node name="FromChapel" type="Marker2D" parent="."]
position = Vector2(90, 240)
script = ExtResource("entry")
entry_id = &"from_chapel"

[node name="ToVillage" type="Area2D" parent="."]
position = Vector2(36, 240)
script = ExtResource("exit")
target_level = "res://world/levels/forsaken_village.tscn"
target_entry = &"chapel_door"
size = Vector2(12, 80)

[node name="CathedralStair" type="Area2D" parent="."]
position = Vector2(3120, 720)
script = ExtResource("exit")
mode = 1
size = Vector2(30, 60)
door_id = &"cathedral_stair"
display_name = "the stair to the Ashen Cathedral"
locked_text = "THE STAIR IS FLOODED BEYOND  -  end of this build"
sealed = true

[node name="CanonArena" type="Node2D" parent="."]
position = Vector2(2440, 560)
script = ExtResource("bossarena")
boss_scene = ExtResource("canon")
boss_offset = Vector2(420, 160)
gate_height = 96.0
trigger_offset = 40.0
trigger_width = 640.0
trigger_below = 160.0
victory_text = "THE HYMN DROWNS"
light_target_level = "res://world/levels/vaelmoor_awake.tscn"
light_target_entry = &"arrival"
light_offset = Vector2(420, 160)''')

candle("OssuaryCandle", 220, 240, "ossuary_candle", "Ossuary Candle")
candle("CanonCandle", 2320, 560, "canons_rest_candle", "Canon's Rest Candle")

enemy("PenitentStair", "penitent", 470, 240, 50.0)
enemy("PenitentStep", "penitent", 960, 465, 0.0)
enemy("PenitentNave1", "penitent", 1380, 660, 40.0)
enemy("AcolytePillarA", "acolyte", 1480, 560, 0.0)
enemy("BearerNave", "bearer", 1880, 660, 40.0)
enemy("AcolytePillarB", "acolyte", 2000, 560, 0.0)
enemy("PenitentNave2", "penitent", 2120, 660, 20.0)

pickup("PickupStairBandage", 520, 240, "it_band", 2, "catacombs_bandages")
pickup("PickupPillarTonic", 1490, 560, "it_tonic", 1, "catacombs_tonic")
pickup("PickupAlcoveShards", 2250, 660, "it_shard", 2, "catacombs_alcove_shards")

node('''
[node name="Drips" type="CPUParticles2D" parent="."]
position = Vector2(1600, 42)
amount = 40
lifetime = 2.5
emission_shape = 3
emission_rect_extents = Vector2(1580, 2)
direction = Vector2(0, 1)
spread = 2.0
gravity = Vector2(0, 380)
initial_velocity_min = 0.0
initial_velocity_max = 10.0
color = Color(0.6, 0.8, 0.85, 0.5)
z_index = 5''')

header = f'[gd_scene load_steps={len(ext) + 1} format=3]\n\n'
header += "\n".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]' for t, p, i in ext)
open(OUT, "w").write(header + "\n\n" + "\n\n".join(nodes) + "\n")
print("wrote", os.path.relpath(OUT, ROOT))
