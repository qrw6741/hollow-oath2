#!/usr/bin/env python3
"""Generates the three side-area levels:
  hollowmere_cellar.tscn     Under the manor. Casks, penitents, an archer, an elite, then the
                             Cellarer's arena (mini-boss, drops the Gallery Key).
  hollowmere_gallery.tscn    Beyond the Gallery door (needs the key): Vesper the archivist,
                             portraits, a chest with the Ghostlight Raiment.
  pilgrims_graveyard.tscn    Behind the road: pilgrims' graves, archers, two Candle Cantors
                             (Ommen's errand), a Gilded Penitent and Sexton Hale (mini-boss).
Re-run:  python3 tools/levels/gen_side_levels.py
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "world", "levels")

EXT = {
    "level": ("Script", "res://world/levels/level.gd"),
    "block": ("Script", "res://world/blocks/stone_block.gd"),
    "candle": ("PackedScene", "res://world/checkpoint/oath_candle.tscn"),
    "hall": ("Script", "res://world/background/manor_hall.gd"),
    "exit": ("Script", "res://world/transitions/level_exit.gd"),
    "entry": ("Script", "res://world/transitions/level_entry.gd"),
    "tablet": ("Script", "res://world/story/lore_tablet.gd"),
    "chest": ("Script", "res://world/pickups/treasure_chest.gd"),
    "npc": ("Script", "res://world/npcs/npc.gd"),
    "spawner": ("Script", "res://world/spawners/enemy_spawner.gd"),
    "bossarena": ("Script", "res://world/boss/boss_arena.gd"),
    "sky": ("Script", "res://world/background/sky.gd"),
    "ruins": ("Script", "res://world/background/ruins_silhouette.gd"),
    "props": ("Script", "res://world/background/graveyard_props.gd"),
    "cycle": ("Script", "res://world/background/day_night_cycle.gd"),
    "penitent": ("PackedScene", "res://actors/enemies/hollow_penitent.tscn"),
    "archer": ("PackedScene", "res://actors/enemies/hollow_archer.tscn"),
    "cantor": ("PackedScene", "res://actors/enemies/candle_cantor.tscn"),
    "gilded": ("PackedScene", "res://actors/enemies/gilded_penitent.tscn"),
    "pikeman": ("PackedScene", "res://actors/enemies/roadside_pikeman.tscn"),
    "cellarer": ("PackedScene", "res://actors/bosses/cellarer_grume.tscn"),
    "gravewarden": ("PackedScene", "res://actors/bosses/sexton_hale.tscn"),
    "cinder": ("PackedScene", "res://actors/bosses/mother_cinder.tscn"),
    "ashfall": ("PackedScene", "res://actors/bosses/ser_ashfall.tscn"),
    "sergeant": ("PackedScene", "res://actors/enemies/pike_sergeant.tscn"),
    "captain": ("PackedScene", "res://actors/enemies/oathguard_captain.tscn"),
    "wall": ("Script", "res://world/blocks/breakable_wall.gd"),
    "it_scrap": ("Resource", "res://data/items/forge_scrap.tres"),
    "it_shard": ("Resource", "res://data/items/ember_shard.tres"),
    "it_resin": ("Resource", "res://data/items/hollow_resin.tres"),
    "it_thorn": ("Resource", "res://data/items/relic_thorn.tres"),
    "it_glove": ("Resource", "res://data/items/relic_riposte.tres"),
    "it_band": ("Resource", "res://data/items/ash_bandage.tres"),
}


class Level:
    def __init__(self, fname):
        self.fname = fname
        self.nodes = []
        self.used = []
        self.seed = 900

    def use(self, key):
        if key not in self.used:
            self.used.append(key)
        return key

    def node(self, t):
        self.nodes.append(t.strip("\n"))

    def block(self, name, x, y, w, h, style=1, one_way=False):
        self.use("block")
        self.seed += 1
        self.node(f'''
[node name="{name}" type="StaticBody2D" parent="Geometry"]
position = Vector2({x}, {y})
script = ExtResource("block")
size = Vector2({w}, {h})
style = {style}
seed_value = {self.seed}''' + ("\none_way = true" if one_way else ""))

    def plank(self, name, x, y, w):
        self.block(name, x, y, w, 6, style=2, one_way=True)

    def enemy(self, name, scene, x, y, patrol=40.0, facing=-1, when=0):
        self.use("spawner"); self.use(scene)
        self.node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spawner")
enemy_scene = ExtResource("{scene}")
patrol_distance = {patrol}
start_facing = {facing}''' + (f"\nwhen = {when}" if when else ""))

    def candle(self, name, x, y, cid, title):
        self.use("candle")
        self.node(f'''
[node name="{name}" parent="." instance=ExtResource("candle")]
position = Vector2({x}, {y})
checkpoint_id = &"{cid}"
display_name = "{title}"''')

    def entry(self, name, x, y, eid):
        self.use("entry")
        self.node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("entry")
entry_id = &"{eid}"''')

    def walk_exit(self, name, x, y, target, tentry, size=(12, 80)):
        self.use("exit")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("exit")
target_level = "{target}"
target_entry = &"{tentry}"
size = Vector2({size[0]}, {size[1]})''')

    def chest(self, name, x, y, cid, count=0, embers=0, item=None, gear=None):
        self.use("chest")
        t = f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("chest")
chest_id = &"{cid}"
count = {count}
embers = {embers}'''
        if item:
            self.use(item)
            t += f'\nitem = ExtResource("{item}")'
        if gear:
            t += f'\ngear_kind = "{gear[0]}"\ngear_id = &"{gear[1]}"'
        self.node(t)

    def tablet(self, name, x, y, title, text):
        self.use("tablet")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("tablet")
title = "{title}"
text = "{text}"''')

    def npc(self, name, x, nid, title, look, facing=-1):
        self.use("npc")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, 480)
script = ExtResource("npc")
npc_id = &"{nid}"
display_name = "{title}"
look = {look}
start_facing = {facing}''')

    def arena(self, name, x, y, scene, text, offset=420, width=560):
        self.use("bossarena"); self.use(scene)
        self.node(f'''
[node name="{name}" type="Node2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("bossarena")
boss_scene = ExtResource("{scene}")
boss_offset = Vector2({offset}, 0)
gate_height = 96.0
trigger_offset = 36.0
trigger_width = {width}.0
victory_text = "{text}"''')

    def write(self):
        ext = [("level",)] + [(k,) for k in self.used if k != "level"]
        lines = []
        keys = ["level"] + [k for k in self.used if k != "level"]
        for k in keys:
            t, p = EXT[k]
            lines.append(f'[ext_resource type="{t}" path="{p}" id="{k}"]')
        head = f'[gd_scene load_steps={len(keys) + 1} format=3]\n\n' + "\n".join(lines)
        open(os.path.join(OUT, self.fname), "w").write(head + "\n\n" + "\n\n".join(self.nodes) + "\n")
        print("wrote", self.fname)


MANOR = "res://world/levels/hollowmere_manor.tscn"
ROAD = "res://world/levels/vaelmoor_road.tscn"
CELLAR = "res://world/levels/hollowmere_cellar.tscn"
GALLERY = "res://world/levels/hollowmere_gallery.tscn"
GRAVE = "res://world/levels/pilgrims_graveyard.tscn"
CHAPEL = "res://world/levels/ashen_chapel.tscn"


# ------------------------------------------------------------------ the cellar
def cellar():
    W = 2300
    L = Level("hollowmere_cellar.tscn")
    L.use("hall")
    L.node(f'''
[node name="HollowmereCellar" type="Node2D"]
script = ExtResource("level")
level_id = &"hollowmere_cellar"
display_name = "The Cellar"
bounds = Rect2(0, 0, {W}, 540)
music = &"menu"
music_pitch = 0.62
map_origin = Vector2(0, -1700)
default_spawn = Vector2(150, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 31
ghosts = 2
style = 1

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.5, 0.46, 0.56, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("Floor", 0, 480, W, 60)
    L.block("Ceiling", 0, 40, W, 56)
    L.block("WallLeft", 0, 0, 24, 480)
    L.block("WallRight", W - 24, 0, 24, 480)
    L.plank("CaskLedge", 760, 410, 130)
    L.plank("RackLedge", 1180, 400, 120)
    L.entry("FromManor", 150, 480, "from_manor")
    L.walk_exit("ToManor", 40, 480, MANOR, "from_cellar")
    L.candle("CellarCandle", 340, 480, "cellar_candle", "Cellar Candle")
    L.enemy("PenitentA", "penitent", 620, 480, 40)
    L.enemy("ArcherA", "archer", 820, 410, 20, -1)
    L.enemy("PenitentB", "penitent", 1000, 480, 50)
    L.enemy("ArcherB", "archer", 1240, 400, 20, -1)
    L.enemy("GildedWarden", "gilded", 1380, 480, 40)
    L.chest("CellarChest", 1090, 480, "cellar_chest", count=3, embers=200, item="it_scrap")
    L.tablet("CellarLedger", 480, 480, "The Cellar Book",
             "Stock-book of Hollowmere. The last entries are in a steady hand: 'One cask, sound. One cask, sour. The key to the Gallery goes on the hook by the stair, as ever.' Under it, in a different ink: 'Grume has taken the key down to the cold end. He says no one is to be let past him. He means it.'")
    L.arena("CellarerArena", 1560, 480, "cellarer", "THE CELLAR IS QUIET", 380, 640)
    L.write()


# ------------------------------------------------------------------ the gallery
def gallery():
    W = 1500
    L = Level("hollowmere_gallery.tscn")
    L.use("hall")
    L.node(f'''
[node name="HollowmereGallery" type="Node2D"]
script = ExtResource("level")
level_id = &"hollowmere_gallery"
display_name = "The Gallery"
bounds = Rect2(0, 0, {W}, 540)
music = &"menu"
music_pitch = 0.7
map_origin = Vector2(2500, -2100)
default_spawn = Vector2(150, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 17
ghosts = 5
style = 2

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.68, 0.66, 0.86, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("Floor", 0, 480, W, 60)
    L.block("Ceiling", 0, 40, W, 56)
    L.block("WallLeft", 0, 0, 24, 480)
    L.block("WallRight", W - 24, 0, 24, 480)
    L.entry("FromManor", 150, 480, "from_manor")
    L.walk_exit("ToManor", 40, 480, MANOR, "from_gallery")
    L.candle("GalleryCandle", 330, 480, "gallery_candle", "Gallery Candle")
    L.npc("Vesper", 620, "vesper", "Vesper", 5, facing=-1)
    L.tablet("PortraitDowager", 860, 480, "Portrait of the Dowager",
             "A tall woman in grey, painted at the moment before she smiles. The brass plate reads: 'Lady Hollowmere, Patroness of the Candlewrights. She never signed the oath. She is the reason the house still stands.'")
    L.tablet("LastDraft", 1060, 480, "The Last Draft",
             "A page pinned in a glass case. The liturgy of the Hollow Oath, in its final form, with one line struck through and rewritten above it. The new line is the one that turned the oath over. The hand that rewrote it is Ommen's.")
    L.chest("RelicChest", 1180, 480, "gallery_chest_2", count=1, item="it_glove")
    L.chest("GhostlightChest", 1300, 480, "gallery_chest", embers=800, gear=("armor", "ghostlight_raiment"))
    L.write()


# ------------------------------------------------------------------ the graveyard
def graveyard():
    W = 3500
    L = Level("pilgrims_graveyard.tscn")
    L.use("sky"); L.use("ruins"); L.use("props"); L.use("cycle")
    L.node(f'''
[node name="PilgrimsGraveyard" type="Node2D"]
script = ExtResource("level")
level_id = &"pilgrims_graveyard"
display_name = "Pilgrim's Graveyard"
bounds = Rect2(0, 0, {W}, 540)
music = &"yard"
music_pitch = 0.85
map_origin = Vector2(1900, -1750)
default_spawn = Vector2(120, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(340, 56)
daylight = true
darkness = 0.78

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.1, 0.1)

[node name="Hills" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 235.0
max_height = 110.0
color = Color(0.17, 0.17, 0.26, 1)
seed_value = 81
spacing = 100.0
width = 3200.0
haze = 0.5
haze_color = Color(0.45, 0.35, 0.5, 1)

[node name="Mid" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.35, 0.3)

[node name="Graves" type="Node2D" parent="Background/Mid"]
script = ExtResource("props")
width = 3400.0
base_y = 262.0
seed_value = 5

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.56, 0.55, 0.78, 1)

[node name="Cycle" type="Node" parent="."]
script = ExtResource("cycle")
light_path = NodePath("")
sky_path = NodePath("")

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=3)
    L.block("MoundA", 780, 456, 220, 30, style=3)
    L.block("MoundB", 1500, 450, 260, 36, style=3)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.plank("CryptRoof", 1180, 400, 110)
    L.plank("FenceTop", 2050, 405, 110)
    L.entry("FromRoad", 130, 480, "from_road")
    L.walk_exit("ToRoad", 34, 480, ROAD, "from_graveyard")
    L.candle("GraveCandle", 380, 480, "graveyard_candle", "Graveyard Candle")
    L.enemy("PenitentA", "penitent", 640, 480, 40)
    L.enemy("PenitentB", "penitent", 880, 456, 30)
    L.enemy("ArcherA", "archer", 1230, 400, 20, -1)
    L.enemy("CantorA", "cantor", 1450, 480, 30)
    L.enemy("GildedPilgrim", "gilded", 1640, 450, 40)
    L.enemy("ArcherB", "archer", 2100, 405, 20, -1)
    L.enemy("CantorB", "cantor", 2300, 480, 30)
    L.enemy("NightPenitentA", "penitent", 520, 480, 60, 1, 2)
    L.enemy("NightPenitentB", "penitent", 1650, 480, 60, 1, 2)
    L.enemy("NightPikeman", "pikeman", 2450, 480, 60, 1, 2)
    L.chest("GraveChest", 1120, 480, "graveyard_chest", count=3, embers=400, item="it_resin")
    L.chest("SextonChest", 2560, 480, "graveyard_chest_2", count=1, embers=300, item="it_thorn")
    L.tablet("SextonStone", 700, 480, "A Sexton's Stone",
             "HALE. Sexton of this yard, forty-one years. 'He dug them all and saw them all filled.' Someone has scratched underneath, with a spade-edge: 'Not yet.'")
    L.arena("SextonArena", 2740, 480, "gravewarden", "THE YARD IS FILLED", 420, 620)
    L.entry("FromChapel", 3350, 480, "from_chapel")
    L.walk_exit("ToChapel", 3390, 480, CHAPEL, "from_graveyard")
    L.write()


def chapel():
    W = 4700
    L = Level("ashen_chapel.tscn")
    L.use("sky"); L.use("ruins"); L.use("props"); L.use("cycle")
    L.node(f'''
[node name="AshenChapel" type="Node2D"]
script = ExtResource("level")
level_id = &"ashen_chapel"
display_name = "The Ashen Chapel"
bounds = Rect2(0, 0, {W}, 540)
music = &"yard"
music_pitch = 0.75
map_origin = Vector2(5500, -1750)
default_spawn = Vector2(130, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(340, 56)
daylight = true
darkness = 0.7

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.1, 0.1)

[node name="Hills" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 235.0
max_height = 110.0
color = Color(0.17, 0.17, 0.26, 1)
seed_value = 81
spacing = 100.0
width = 4800.0
haze = 0.5
haze_color = Color(0.45, 0.35, 0.5, 1)

[node name="Mid" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.35, 0.3)

[node name="Graves" type="Node2D" parent="Background/Mid"]
script = ExtResource("props")
width = 4800.0
base_y = 262.0
seed_value = 5

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.78, 0.52, 0.42, 1)

[node name="Cycle" type="Node" parent="."]
script = ExtResource("cycle")
light_path = NodePath("")
sky_path = NodePath("")

[node name="Geometry" type="Node2D" parent="."]''')
    L.use("wall"); L.use("sergeant")
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=3)
    L.block("AshMound", 900, 452, 240, 34, style=3)
    L.block("NaveStep", 1800, 446, 300, 40, style=3)
    L.block("AltarStep", 2260, 462, 180, 24, style=3)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.plank("ChoirLoft", 1300, 400, 130)
    L.plank("BellLoft", 2480, 400, 130)
    L.plank("VestryLoft", 3520, 405, 120)
    L.entry("FromGraveyard", 130, 480, "from_graveyard")
    L.walk_exit("ToGraveyard", 34, 480, GRAVE, "from_chapel")
    L.candle("ChapelCandle", 360, 480, "chapel_candle", "Chapel Candle")
    L.candle("NaveCandle", 3180, 480, "nave_candle", "Nave Candle")
    L.enemy("AcolyteA", "penitent", 620, 480, 40)
    L.enemy("ArcherChoirA", "archer", 1340, 400, 20, -1)
    L.enemy("GildedNave", "gilded", 1700, 480, 40)
    L.enemy("CantorNave", "cantor", 1950, 446, 30)
    L.enemy("SergeantA", "sergeant", 2150, 480, 40)
    L.enemy("ArcherBell", "archer", 2520, 400, 20, -1)
    L.enemy("CaptainA", "captain", 2720, 480, 40)
    L.enemy("NightPenitentC", "penitent", 1000, 452, 60, 1, 2)
    L.enemy("NightCantor", "cantor", 2000, 446, 40, 1, 2)
    L.chest("PewChest", 1120, 452, "chapel_chest", count=3, embers=500, item="it_resin")
    L.chest("VestryChest", 3600, 405, "chapel_chest_2", count=2, embers=700, item="it_scrap")
    L.tablet("AbbessStone", 760, 480, "The Abbess's Stone",
             "MOTHER CINDER. Abbess here eleven years. 'She kept the censer lit through the Night.' Below, in a rushed hand: 'It is still lit.'")
    L.arena("CinderArena", 2980, 480, "cinder", "THE CENSER GOES DARK", 420, 620)
    L.tablet("CrackedStone", 3800, 480, "A Cracked Stone",
             "The wall beyond the nave is thinner than it looks. Behind it: 'ASHFALL. Knight of the Crown's guard. He refused the oath, and the oath refused him a grave. Do not wake him. If you must, come ready.'")
    L.node('''
[node name="SecretWall" type="StaticBody2D" parent="."]
position = Vector2(3900, 420)
script = ExtResource("wall")
size = Vector2(16, 60)
wall_id = &"ashfall_crypt"
hits_needed = 3''')
    L.arena("AshfallArena", 4150, 480, "ashfall", "THE UNBURIED REST", 330, 440)
    L.write()


if __name__ == "__main__":
    cellar()
    gallery()
    graveyard()
    chapel()
