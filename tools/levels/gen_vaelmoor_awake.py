#!/usr/bin/env python3
"""Generates world/levels/vaelmoor_awake.tscn: the first daylight area, reached through the
light that opens after the Drowned Canon falls. The end of the prologue (tutorial).
Peaceful: no enemies. Arrival, the First Light Candle, an inscribed stone that explains
where you are, rolling hills, and the sealed road onward (next build).
Re-run after editing:  python3 tools/levels/gen_vaelmoor_awake.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels", "vaelmoor_awake.tscn")

ext = [
    ("Script", "res://world/levels/level.gd", "level"),
    ("Script", "res://world/blocks/stone_block.gd", "block"),
    ("PackedScene", "res://world/checkpoint/oath_candle.tscn", "candle"),
    ("Script", "res://world/background/ruins_silhouette.gd", "ruins"),
    ("Script", "res://world/background/sky.gd", "sky"),
    ("Script", "res://world/transitions/level_exit.gd", "exit"),
    ("Script", "res://world/transitions/level_entry.gd", "entry"),
    ("Script", "res://world/story/lore_tablet.gd", "tablet"),
    ("Script", "res://world/story/prologue_end.gd", "prologue"),
]
nodes = []
seed = [300]


def node(t):
    nodes.append(t.strip("\n"))


def block(name, x, y, w, h, style=3):
    seed[0] += 1
    node(f'''
[node name="{name}" type="StaticBody2D" parent="Geometry"]
position = Vector2({x}, {y})
script = ExtResource("block")
size = Vector2({w}, {h})
style = {style}
seed_value = {seed[0]}''')


node('''
[node name="VaelmoorAwake" type="Node2D"]
script = ExtResource("level")
level_id = &"vaelmoor_awake"
display_name = "Vaelmoor, Awake"
bounds = Rect2(0, 0, 1920, 540)
music = &"menu"
music_pitch = 1.15
map_origin = Vector2(0, -1400)
default_spawn = Vector2(220, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(120, 70)
daylight = true

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.12, 0.1)

[node name="Citadel" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 205.0
max_height = 120.0
color = Color(0.55, 0.6, 0.7, 1)
seed_value = 61
spacing = 70.0
width = 1400.0
haze = 0.5
haze_color = Color(0.92, 0.88, 0.8, 1)

[node name="Mid" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.35, 0.3)

[node name="Hills" type="Node2D" parent="Background/Mid"]
script = ExtResource("ruins")
base_y = 250.0
max_height = 70.0
color = Color(0.36, 0.48, 0.36, 1)
seed_value = 67
spacing = 120.0
width = 1800.0
haze = 0.4
haze_color = Color(0.9, 0.88, 0.78, 1)

[node name="Light" type="CanvasModulate" parent="."]
color = Color(1, 0.98, 0.94, 1)

[node name="Geometry" type="Node2D" parent="."]''')

block("CliffLeft", 0, 0, 24, 480, style=1)
block("HillA", 0, 480, 520, 60)
block("HillB", 520, 460, 300, 80)
block("HillC", 820, 440, 360, 100)
block("HillD", 1180, 460, 380, 80)
block("HillE", 1560, 480, 360, 60)
block("CliffRight", 1896, 0, 24, 480, style=1)

node('''
[node name="Arrival" type="Marker2D" parent="."]
position = Vector2(220, 480)
script = ExtResource("entry")
entry_id = &"arrival"

[node name="FirstLightCandle" parent="." instance=ExtResource("candle")]
position = Vector2(420, 480)
checkpoint_id = &"first_light_candle"
display_name = "First Light Candle"

[node name="WakingStone" type="Area2D" parent="."]
position = Vector2(700, 460)
script = ExtResource("tablet")
title = "The Waking Stone"
text = "You have walked out of the Hollow: the dream the oath built around the sworn on the Night of Unbinding. The Yard, the village, the drowned choir - all of it was the oath remembering itself. This is Vaelmoor as it is now, under a real sun. The road below leads toward the Crownless Citadel.\\n\\n(End of the prologue. The real journey continues in the next build.)"

[node name="RoadGate" type="Area2D" parent="."]
position = Vector2(1860, 480)
script = ExtResource("exit")
mode = 1
size = Vector2(30, 60)
door_id = &"kingdom_road"
display_name = "the road to the kingdom"
locked_text = "THE ROAD AHEAD  -  coming in the next build"
sealed = true

[node name="PrologueEnd" type="Node" parent="."]
script = ExtResource("prologue")

[node name="Petals" type="CPUParticles2D" parent="."]
position = Vector2(960, -10)
amount = 40
lifetime = 12.0
preprocess = 12.0
emission_shape = 3
emission_rect_extents = Vector2(980, 4)
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
