#!/usr/bin/env python3
"""Generates world/levels/vaelmoor_road.tscn: the first real-world area after the prologue.

Layout (floor y = 480, x grows to the right, daylight):
  A  16-700     Pilgrim's Rest: arrival from Vaelmoor, Awake. Wenna the Pedlar (shop), the
                Wayside Candle and the hooded figure Ommen.
  B  700-1250   The Crow Fields: a low rise, Roadside Pikemen, Carrion Crows, a chest.
  C  1250-1750  The Ford: a stream (wading slows you), a Oathguard in the water, broken
                bridge planks.
  D  1750-2740  The Marshal's Camp: a Mimic on the bank, pikemen, an Oathguard, the Camp
                Candle (and Ommen) just before the gate.
  E  2740-3500  The Crossroads (boss arena): Sir Orren, the Hollow Marshal. Beyond it the
                road to the Crownless Citadel (sealed in this build).
Re-run after editing:  python3 tools/levels/gen_vaelmoor_road.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels", "vaelmoor_road.tscn")

ext = [
    ("Script", "res://world/levels/level.gd", "level"),
    ("Script", "res://world/blocks/stone_block.gd", "block"),
    ("PackedScene", "res://world/checkpoint/oath_candle.tscn", "candle"),
    ("Script", "res://world/spawners/enemy_spawner.gd", "spawner"),
    ("PackedScene", "res://actors/enemies/roadside_pikeman.tscn", "pikeman"),
    ("PackedScene", "res://actors/enemies/carrion_crow.tscn", "crow"),
    ("PackedScene", "res://actors/enemies/oathguard.tscn", "oathguard"),
    ("PackedScene", "res://actors/enemies/mimic.tscn", "mimic"),
    ("Script", "res://world/background/ruins_silhouette.gd", "ruins"),
    ("Script", "res://world/background/sky.gd", "sky"),
    ("Script", "res://world/background/day_night_cycle.gd", "cycle"),
    ("PackedScene", "res://actors/enemies/hollow_archer.tscn", "archer"),
    ("PackedScene", "res://actors/enemies/hollow_penitent.tscn", "penitent"),
    ("PackedScene", "res://actors/enemies/pike_sergeant.tscn", "sergeant"),
    ("Script", "res://world/pickups/item_pickup.gd", "pickup"),
    ("Script", "res://world/pickups/treasure_chest.gd", "chest"),
    ("Script", "res://world/transitions/level_exit.gd", "exit"),
    ("Script", "res://world/transitions/level_entry.gd", "entry"),
    ("Script", "res://world/hazards/water_zone.gd", "water"),
    ("Script", "res://world/boss/boss_arena.gd", "bossarena"),
    ("Script", "res://world/npcs/npc.gd", "npc"),
    ("PackedScene", "res://actors/bosses/hollow_marshal.tscn", "marshal"),
    ("Resource", "res://data/items/ash_bandage.tres", "it_band"),
    ("Resource", "res://data/items/ember_shard.tres", "it_shard"),
    ("Resource", "res://data/items/stamina_tonic.tres", "it_tonic"),
    ("Resource", "res://data/items/pilgrims_draught.tres", "it_draught"),
]

nodes = []
seed = [400]


def node(text):
    nodes.append(text.strip("\n"))


def block(name, x, y, w, h, style=3, one_way=False):
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


def enemy(name, scene, x, y, patrol=40.0, facing=-1, spawn_id="", when=0):
    node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spawner")
enemy_scene = ExtResource("{scene}")
patrol_distance = {patrol}
start_facing = {facing}''' + (f'\nspawn_id = &"{spawn_id}"' if spawn_id else "") + (f"\nwhen = {when}" if when else ""))


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


def chest(name, x, y, cid, item=None, count=1, embers=0):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("chest")
chest_id = &"{cid}"
count = {count}
embers = {embers}''' + (f'\nitem = ExtResource("{item}")' if item else ""))


def npc(name, x, y, nid, title, look, shop="", facing=-1, station=""):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("npc")
npc_id = &"{nid}"
display_name = "{title}"
look = {look}
start_facing = {facing}''' + (f'\nshop_id = &"{shop}"' if shop else "") + (f'\nstation = &"{station}"' if station else ""))


def water(name, x, y, w, h):
    node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("water")
size = Vector2({w}, {h})''')


node('''
[node name="VaelmoorRoad" type="Node2D"]
script = ExtResource("level")
level_id = &"vaelmoor_road"
display_name = "The Vaelmoor Road"
bounds = Rect2(0, 0, 3600, 540)
music = &"yard"
music_pitch = 1.2
map_origin = Vector2(2000, -1400)
default_spawn = Vector2(120, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(380, 60)
daylight = true

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.1, 0.1)

[node name="Citadel" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 215.0
max_height = 150.0
color = Color(0.5, 0.55, 0.66, 1)
seed_value = 71
spacing = 90.0
width = 2400.0
haze = 0.55
haze_color = Color(0.92, 0.88, 0.8, 1)

[node name="Mid" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.35, 0.3)

[node name="Hills" type="Node2D" parent="Background/Mid"]
script = ExtResource("ruins")
base_y = 255.0
max_height = 70.0
color = Color(0.34, 0.46, 0.34, 1)
seed_value = 73
spacing = 120.0
width = 2600.0
haze = 0.4
haze_color = Color(0.9, 0.88, 0.78, 1)

[node name="Light" type="CanvasModulate" parent="."]
color = Color(1, 0.98, 0.94, 1)

[node name="Cycle" type="Node" parent="."]
script = ExtResource("cycle")

[node name="Geometry" type="Node2D" parent="."]''')

# Ground and walls
block("CliffLeft", 0, 0, 16, 480, style=1)
block("GroundA", 16, 480, 684, 60)
block("Rise", 700, 460, 300, 80)
block("GroundB", 1000, 480, 250, 60)
block("FordBed", 1250, 500, 500, 40)
block("GroundC", 1750, 480, 990, 60)
block("GatePillar", 2740, 0, 24, 384, style=0)
block("ArenaFloor", 2740, 480, 760, 60)
block("CliffRight", 3500, 0, 100, 540, style=1)
# Fixed stepping stones in the ford and broken bridge planks
plank("BridgeStubL", 1250, 456, 90)
plank("BridgeStubR", 1660, 456, 90)
plank("CampLedge", 2260, 400, 100)
plank("CrowPerch", 1130, 410, 70)

water("FordWater", 1250, 478, 500, 22)

# Transitions
node('''
[node name="FromAwake" type="Marker2D" parent="."]
position = Vector2(110, 480)
script = ExtResource("entry")
entry_id = &"from_awake"

[node name="ToAwake" type="Area2D" parent="."]
position = Vector2(34, 480)
script = ExtResource("exit")
target_level = "res://world/levels/vaelmoor_awake.tscn"
target_entry = &"from_road"
size = Vector2(12, 80)

[node name="GraveyardGate" type="Area2D" parent="."]
position = Vector2(1830, 480)
script = ExtResource("exit")
target_level = "res://world/levels/pilgrims_graveyard.tscn"
target_entry = &"from_road"
mode = 1
size = Vector2(30, 64)
display_name = "the Pilgrim's Graveyard"

[node name="FromGraveyard" type="Marker2D" parent="."]
position = Vector2(1790, 480)
script = ExtResource("entry")
entry_id = &"from_graveyard"

[node name="CitadelRoad" type="Area2D" parent="."]
position = Vector2(3440, 480)
script = ExtResource("exit")
mode = 1
size = Vector2(30, 60)
door_id = &"citadel_road"
display_name = "the road to the Crownless Citadel"
locked_text = "THE ROAD TO THE CITADEL  -  coming in the next build"
sealed = true

[node name="MarshalArena" type="Node2D" parent="."]
position = Vector2(2764, 480)
script = ExtResource("bossarena")
boss_scene = ExtResource("marshal")
boss_offset = Vector2(420, 0)
gate_height = 96.0
trigger_offset = 36.0
trigger_width = 560.0
victory_text = "THE CROSSROADS FALL QUIET"''')

candle("WaysideCandle", 520, 480, "wayside_candle", "Wayside Candle")
candle("CampCandle", 2090, 480, "marshals_camp_candle", "Marshal's Camp Candle")

# NPCs
npc("Hobb", 215, 480, "hobb", "Hobb", 2, station="forge", facing=1)
npc("Wenna", 360, 480, "wenna", "Wenna", 0, shop="pedlar", facing=-1)
npc("Ilse", 440, 480, "ilse", "Sister Ilse", 3, station="vials", facing=-1)
npc("OmmenWayside", 600, 480, "ommen", "Hooded Figure", 1, facing=-1)
npc("OmmenCamp", 2170, 480, "ommen", "Hooded Figure", 1, facing=-1)

# Enemies
# Night only: the road's dead walk when the light goes (see systems/day_night.gd).
enemy("NightPenitentA", "penitent", 560, 480, 60.0, 1, when=2)
enemy("NightArcherRise", "archer", 880, 460, 20.0, -1, when=2)
enemy("NightPenitentB", "penitent", 1080, 480, 60.0, -1, when=2)
enemy("NightArcherCamp", "archer", 2330, 400, 20.0, -1, when=2)
enemy("NightSergeant", "sergeant", 2000, 480, 50.0, -1, when=2)
enemy("PikemanRise", "pikeman", 820, 460, 40.0)
enemy("CrowFieldA", "crow", 660, 385, 60.0)
enemy("PikemanField", "pikeman", 1120, 480, 50.0)
enemy("CrowFieldB", "crow", 1060, 370, 40.0)
enemy("OathguardFord", "oathguard", 1500, 500, 30.0)
enemy("CrowFord", "crow", 1380, 400, 70.0)
enemy("MimicBank", "mimic", 1850, 480, 0.0, 1, spawn_id="road_bank_mimic")
enemy("PikemanCampA", "pikeman", 2380, 480, 40.0)
enemy("PikemanCampB", "pikeman", 2480, 480, 30.0)
enemy("CrowCamp", "crow", 2300, 370, 50.0)
enemy("OathguardGate", "oathguard", 2640, 480, 30.0)

# Loot
chest("FieldChest", 1005, 460, "road_field_chest", item="it_draught", count=1, embers=200)
pickup("PickupRoadBandages", 880, 460, "it_band", 2, "road_bandages")
pickup("PickupBankShard", 1790, 480, "it_shard", 1, "road_bank_shard")
pickup("PickupCampTonic", 2300, 400, "it_tonic", 1, "road_camp_tonic")

node('''
[node name="Petals" type="CPUParticles2D" parent="."]
position = Vector2(1800, -10)
amount = 70
lifetime = 12.0
preprocess = 12.0
emission_shape = 3
emission_rect_extents = Vector2(1800, 4)
direction = Vector2(0.6, 1)
spread = 30.0
gravity = Vector2(8, 12)
initial_velocity_min = 6.0
initial_velocity_max = 16.0
color = Color(1, 0.9, 0.75, 0.6)
z_index = 5''')

header = f'[gd_scene load_steps={len(ext) + 1} format=3]\n\n'
header += "\n".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]' for t, p, i in ext)
open(OUT, "w").write(header + "\n\n" + "\n\n".join(nodes) + "\n")
print("wrote", os.path.relpath(OUT, ROOT))
