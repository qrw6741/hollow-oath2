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
    "backdrop": ("Script", "res://world/background/descent_backdrop.gd"),
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
    "runner": ("Script", "res://world/trial/trial_runner.gd"),
    "stone": ("Script", "res://world/trial/trial_stone.gd"),
    "illusion": ("Script", "res://world/blocks/illusory_wall.gd"),
    "water": ("Script", "res://world/hazards/water_zone.gd"),
    "drown": ("Script", "res://world/hazards/drown_zone.gd"),
    "spikes": ("Script", "res://world/hazards/spike_pit.gd"),
    "jet": ("Script", "res://world/hazards/fire_jet.gd"),
    "pilgrim": ("PackedScene", "res://actors/enemies/drowned_pilgrim.tscn"),
    "lurker": ("PackedScene", "res://actors/enemies/reliquary_lurker.tscn"),
    "abbot": ("PackedScene", "res://actors/bosses/salt_abbot.tscn"),
    "vess": ("PackedScene", "res://actors/bosses/gaoler_vess.tscn"),
    "brand": ("PackedScene", "res://actors/bosses/foundrymaster_brand.tscn"),
    "ringer": ("PackedScene", "res://actors/bosses/last_ringer.tscn"),
    "bloat": ("PackedScene", "res://actors/enemies/swollen_pilgrim.tscn"),
    "mender": ("PackedScene", "res://actors/enemies/wick_mender.tscn"),
    "bearer": ("PackedScene", "res://actors/enemies/bell_bearer.tscn"),
    "moth": ("PackedScene", "res://actors/enemies/gloam_moth.tscn"),
    "thornmother": ("PackedScene", "res://actors/bosses/thornmother.tscn"),
    "orrerist": ("PackedScene", "res://actors/bosses/orrerist.tscn"),
    "bishop": ("PackedScene", "res://actors/bosses/drowned_bishop.tscn"),
    "crownless": ("PackedScene", "res://actors/bosses/crownless_king.tscn"),
    "regent": ("PackedScene", "res://actors/bosses/hollow_regent.tscn"),
    "it_wick": ("Resource", "res://data/items/cantors_wick.tres"),
    "it_knot": ("Resource", "res://data/items/relic_knot.tres"),
    "it_draught": ("Resource", "res://data/items/pilgrims_draught.tres"),
    "it_scrap": ("Resource", "res://data/items/forge_scrap.tres"),
    "it_shard": ("Resource", "res://data/items/ember_shard.tres"),
    "it_resin": ("Resource", "res://data/items/hollow_resin.tres"),
    "it_thorn": ("Resource", "res://data/items/relic_thorn.tres"),
    "it_glove": ("Resource", "res://data/items/relic_riposte.tres"),
    "it_band": ("Resource", "res://data/items/ash_bandage.tres"),
}

import sys as _sys
_sys.path.insert(0, os.path.join(ROOT, "tools"))
import expansion_data as XD
import descent2_data as D2
for _g in XD.BOSSES:
    for _b in _g:
        EXT["x_" + _b["id"]] = ("PackedScene", "res://actors/bosses/%s.tscn" % _b["id"])


class Level:
    def __init__(self, fname):
        self.fname = fname
        self.blocks = []     # (name, x, y, w, h, one_way): geometry, for the reachability pass
        self.things = []     # (kind, name, x, y): what stands on it
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
        self.blocks.append((name, x, y, w, h, one_way))
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
        self.things.append(("enemy", name, x, y))
        self.use("spawner"); self.use(scene)
        self.node(f'''
[node name="{name}" type="Marker2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spawner")
enemy_scene = ExtResource("{scene}")
patrol_distance = {patrol}
start_facing = {facing}''' + (f"\nwhen = {when}" if when else ""))

    def candle(self, name, x, y, cid, title):
        self.things.append(("candle", name, x, y))
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
        self.things.append(("chest", name, x, y))
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
        self.things.append(("tablet", name, x, y))
        self.use("tablet")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("tablet")
title = "{title}"
text = "{text}"''')

    def npc(self, name, x, nid, title, look, facing=-1, shop=None):
        self.things.append(("npc", name, x, 480))
        self.use("npc")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, 480)
script = ExtResource("npc")
npc_id = &"{nid}"
display_name = "{title}"
look = {look}
start_facing = {facing}''' + (f'\nshop_id = &"{shop}"' if shop else ""))

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

    def water(self, name, x, y, w, h):
        self.use("water")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("water")
size = Vector2({w}, {h})''')

    def spikes(self, name, x, y, w, dmg=20.0):
        self.use("spikes")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("spikes")
width = {w}.0
damage = {dmg}''')

    def jet(self, name, x, y, phase=0.0, period=3.0, height=56):
        self.use("jet")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("jet")
column = Vector2(14, {height})
period = {period}
phase = {phase}''')

    def illusion(self, name, x, y, w, h, sid):
        self.use("illusion")
        self.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("illusion")
size = Vector2({w}, {h})
secret_id = &"{sid}"''')

    def secret_wall(self, name, x, y, w, h, wid, hits=3, opens_when=None):
        self.use("wall")
        self.node(f'''
[node name="{name}" type="StaticBody2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("wall")
size = Vector2({w}, {h})
wall_id = &"{wid}"
hits_needed = {hits}''' + (f'\nopens_when_boss = &"{opens_when}"' if opens_when else ""))

    # ---- reachability (the player's jump rises ~52 px and crosses ~100 px) -------------------
    RISE, GAP, STEP = 48.0, 90.0, 44.0

    def _surfaces(self):
        return [(n, x, x + w, y, o) for (n, x, y, w, h, o) in self.blocks if n not in ("CliffLeft", "CliffRight", "Ceiling")]

    def reachable(self):
        surf = self._surfaces()
        ground = next((t for t in surf if t[0] == "Ground"), None)
        if ground is None:
            return surf, None
        seen = {ground[0]}
        todo = [ground]
        while todo:
            a = todo.pop()
            for b in surf:
                if b[0] not in seen and b[3] >= a[3] - self.RISE and max(0.0, b[1] - a[2], a[1] - b[2]) <= self.GAP:
                    seen.add(b[0]); todo.append(b)
        return surf, seen

    def auto_steps(self):
        """Gives every perch that something stands on (archers, chests...) a way up: one low step beside it.
        Without this a ledge 80 px up is out of reach (a jump only rises about 52 px)."""
        for _ in range(8):
            surf, seen = self.reachable()
            if seen is None:
                return
            fixed = False
            for (kind, name, x, y) in self.things:
                host = [t for t in surf if abs(t[3] - y) <= 2.0 and t[1] - 2 <= x <= t[2] + 2]
                if not host or any(h[0] in seen for h in host):
                    continue
                h = host[0]
                top = h[3] + self.STEP
                if top > 470:
                    continue
                for side in (-1, 1):
                    sx = h[1] - self.STEP if side < 0 else h[2]
                    clear = not any(abs(tx - (sx + self.STEP / 2)) < self.STEP / 2 + 14 and ty >= 470 for (_k, _n, tx, ty) in self.things)
                    clear = clear and not any(bn != h[0] and bx < sx + self.STEP and sx < bx + bw and by < 480 and by + bh > top - 4 and bn not in ("Ground", "Ceiling") for (bn, bx, by, bw, bh, _o) in self.blocks)
                    if clear:
                        self.block(h[0] + "Step", sx, top, self.STEP, 480 - top, style=1)
                        fixed = True
                        break
                else:
                    print("  !! no room for a step beside", h[0], "in", self.fname)
                if fixed:
                    break
            if not fixed:
                break

    def write(self):
        self.auto_steps()
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
RELIQUARY = "res://world/levels/sunken_reliquary.tscn"
KEEP = "res://world/levels/hollow_keep.tscn"
BELFRY = "res://world/levels/drowned_belfry.tscn"


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
    L.chest("RapierChest", 800, 480, "cellar_rapier_chest", gear=("weapon", "wayfarers_rapier"))
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
    L.chest("GreatswordChest", 1800, 480, "graveyard_greatsword_chest", gear=("weapon", "kingsfall_greatsword"))
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
music = &"chapel"
music_pitch = 1.0
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
    L.entry("FromReliquary", 3700, 480, "from_reliquary")
    # A DOOR (interact to use), not a walk-in trigger: the road continues east to the Ashfall crypt,
    # and a walk-in exit on the road would send the player away before they could pass it.
    L.use("exit")
    L.node(f'''
[node name="ToReliquary" type="Area2D" parent="."]
position = Vector2(3730, 480)
script = ExtResource("exit")
target_level = "{RELIQUARY}"
target_entry = &"from_chapel"
mode = 1
display_name = "the flooded stair"
size = Vector2(28, 60)''')
    L.tablet("FloodedStair", 3660, 480, "A Flooded Stair",
             "A stair runs down behind the vestry, and the bottom steps are underwater. Someone has chalked on the wall: 'THE RELIQUARY. WE BLESSED THE WATER. IT BLESSED US BACK.'")
    L.write()


def trial():
    W = 1000
    L = Level("trial_ring.tscn")
    L.use("sky"); L.use("ruins"); L.use("props"); L.use("cycle")
    L.node(f'''
[node name="TrialRing" type="Node2D"]
script = ExtResource("level")
level_id = &"trial_ring"
display_name = "The Trial Ring"
bounds = Rect2(0, 0, {W}, 540)
music = &"chapel"
music_pitch = 0.9
map_origin = Vector2(8800, -1750)
default_spawn = Vector2(130, 480)

[node name="Background" type="ParallaxBackground" parent="."]

[node name="Sky" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0, 0)

[node name="SkyDraw" type="Node2D" parent="Background/Sky"]
script = ExtResource("sky")
moon_pos = Vector2(340, 56)
daylight = false
darkness = 0.9

[node name="Far" type="ParallaxLayer" parent="Background"]
motion_scale = Vector2(0.1, 0.1)

[node name="Hills" type="Node2D" parent="Background/Far"]
script = ExtResource("ruins")
base_y = 235.0
max_height = 70.0
color = Color(0.13, 0.1, 0.16, 1)
seed_value = 7
spacing = 90.0
width = 1200.0
haze = 0.4
haze_color = Color(0.4, 0.3, 0.45, 1)

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.62, 0.5, 0.58, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=3)
    L.block("CliffRight", W - 40, 0, 40, 540)
    L.entry("FromManor", 130, 480, "from_manor")
    L.walk_exit("ToManor", 34, 480, "res://world/levels/hollowmere_manor.tscn", "from_trial")
    L.candle("RingCandle", 170, 480, "ring_candle", "Ring Candle")
    L.use("stone")
    L.node('''
[node name="RushStone" type="Area2D" parent="."]
position = Vector2(250, 480)
script = ExtResource("stone")
trial = "rush"

[node name="GauntletStone" type="Area2D" parent="."]
position = Vector2(330, 480)
script = ExtResource("stone")
trial = "gauntlet"''')
    L.use("runner")
    L.node('''
[node name="TrialRunner" type="Node2D" parent="."]
script = ExtResource("runner")''')
    L.tablet("RingStone", 420, 480, "The Trial Ring",
             "Those who have decided are free to be tested. The left stone calls every lord of the road, one after another. The right stone calls what is left of everyone else. Dying here costs nothing but time.")
    L.write()


def reliquary():
    W = 5400
    L = Level("sunken_reliquary.tscn")
    L.use("hall")
    L.node(f'''
[node name="SunkenReliquary" type="Node2D"]
script = ExtResource("level")
level_id = &"sunken_reliquary"
display_name = "The Sunken Reliquary"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = 0.8
map_origin = Vector2(7200, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 77
ghosts = 5
style = 1

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.4, 0.62, 0.64, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    # Stair and ossuary hall
    L.block("StairStep", 520, 458, 160, 22, style=1)
    L.plank("OssuaryLoft", 1250, 400, 140)
    L.plank("OssuaryLoftB", 1560, 392, 120)
    L.block("BellStep", 2420, 452, 220, 28, style=1)
    L.plank("ChoirGallery", 2800, 398, 150)
    L.block("VaultStep", 4400, 450, 160, 30, style=1)
    # The axe nook: a roofed alcove closed by an illusory wall
    L.block("NookBase", 1840, 436, 200, 44, style=1)
    L.block("NookRoof", 1840, 372, 200, 14)
    L.illusion("NookWall", 1840, 386, 16, 50, "reliquary_axe")
    # Water
    L.water("StairWater", 420, 468, 600, 12)
    L.water("OssuaryWater", 1000, 464, 800, 16)
    L.water("ChoirWater", 2100, 468, 640, 12)
    L.water("VaultWater", 4400, 466, 700, 14)
    # Entry, candles, people
    L.entry("FromChapel", 130, 480, "from_chapel")
    L.walk_exit("ToChapel", 34, 480, CHAPEL, "from_reliquary")
    L.candle("StairCandle", 360, 480, "reliquary_candle", "Stair Candle")
    L.candle("SaltCandle", 3180, 480, "salt_candle", "Salt Candle")
    L.candle("VaultCandle", 4260, 480, "vault_candle", "Vault Candle")
    L.npc("Pell", 3060, "pell", "Pell", 0, 1, "salt_diver")
    L.tablet("BlessedWater", 220, 480, "A Blessing, Half Legible",
             "BLESSED BE THE WATER THAT KEEPS. Below, in salt: 'We asked it to keep us. It keeps everything.'")
    L.tablet("AbbotLedger", 3320, 480, "The Abbot's Ledger",
             "MERROW, ABBOT. A column of names, each ticked. The last tick is wet. Beneath: 'The water is a congregation I cannot dismiss.'")
    # Enemies
    L.enemy("PilgrimA", "pilgrim", 600, 458, 40)
    L.enemy("PilgrimB", "pilgrim", 880, 480, 50)
    L.enemy("LurkerA", "lurker", 1110, 480, 0)
    L.enemy("LurkerB", "lurker", 1480, 480, 0)
    L.enemy("ArcherLoft", "archer", 1280, 400, 20, -1)
    L.enemy("PilgrimC", "pilgrim", 1720, 480, 40)
    L.enemy("CantorChoir", "cantor", 2300, 480, 30)
    L.enemy("GildedHall", "gilded", 2480, 452, 40)
    L.enemy("LurkerC", "lurker", 2700, 480, 0)
    L.enemy("PilgrimD", "pilgrim", 2820, 480, 40)
    L.enemy("ArcherGallery", "archer", 2850, 398, 20, -1)
    L.enemy("NightLurker", "lurker", 1300, 480, 0, 1, 2)
    L.enemy("NightPilgrim", "pilgrim", 2150, 480, 60, 1, 2)
    L.enemy("CaptainVault", "captain", 4640, 480, 40)
    L.enemy("PilgrimVault", "pilgrim", 5010, 480, 40)
    L.enemy("LurkerVault", "lurker", 5080, 480, 0)
    # Hazards: alternating fire jets in the hall, spikes in the vault
    L.jet("JetA", 1640, 480, 0.0)
    L.jet("JetB", 1670, 480, 1.5)
    L.jet("JetC", 4800, 480, 0.8, 2.6)
    L.spikes("VaultSpikes", 4720, 480, 48)
    # Chests (the secrets)
    L.chest("PewChest2", 1180, 480, "reliquary_chest", count=2, embers=450, item="it_draught")
    L.chest("AxeChest", 1990, 436, "reliquary_axe_chest", gear=("weapon", "gravediggers_greataxe"))
    L.chest("ChoirChest", 2900, 398, "reliquary_chest_2", count=1, embers=600, item="it_knot")
    # Boss
    L.arena("AbbotArena", 3560, 480, "abbot", "THE BOOK IS CLOSED", 420, 620)
    # Beyond the boss: the Salt Vault
    L.secret_wall("VaultWallBreak", 5150, 280, 16, 200, "reliquary_vault", 3, opens_when="salt_abbot")
    L.entry("FromKeep", 5200, 480, "from_keep")
    L.walk_exit("ToKeep", 5330, 480, KEEP, "from_reliquary")
    L.chest("VaultCache", 5260, 480, "reliquary_cache", count=2, embers=900, item="it_shard")
    L.illusion("VaultBlock", 4850, 420, 100, 60, "reliquary_vault_block")
    L.chest("WickChest", 4900, 480, "reliquary_wick", count=1, embers=300, item="it_wick")
    L.tablet("VaultStone", 4340, 480, "The Salt Vault",
             "Where the Abbot kept what the water returned. A rack of wicks, a rack of rings. Most are green. One shelf has been swept clean.")
    L.write()


def keep():
    W = 6000
    L = Level("hollow_keep.tscn")
    L.use("hall")
    L.node(f'''
[node name="HollowKeep" type="Node2D"]
script = ExtResource("level")
level_id = &"hollow_keep"
display_name = "The Hollow Keep"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = 0.72
map_origin = Vector2(8800, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 91
ghosts = 4
style = 1

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.7, 0.56, 0.5, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.block("CellStep", 600, 456, 180, 24, style=1)
    L.plank("CellLoft", 950, 400, 140)
    L.block("FoundryStep", 2500, 452, 200, 28, style=1)
    L.plank("FoundryGantry", 2800, 398, 150)
    L.block("ThroneStep", 4350, 450, 200, 30, style=1)
    L.entry("FromReliquary", 130, 480, "from_reliquary")
    L.walk_exit("ToReliquary", 34, 480, RELIQUARY, "from_keep")
    L.candle("KeepGateCandle", 300, 480, "keep_gate_candle", "Keep Gate Candle")
    L.candle("FoundryCandle", 2130, 480, "foundry_candle", "Foundry Candle")
    L.candle("ThroneCandle", 4120, 480, "throne_candle", "Throne Candle")
    L.tablet("GaolerSlate", 400, 480, "Roll of the Kept",
             "A slate of names, each struck through but one. Under it: 'No one is released. I am only keeping the count.'")
    L.tablet("FoundryPlaque", 2200, 480, "Foundry Plaque",
             "CAST HERE: ONE THOUSAND CHAINS, THIRTY BELLS, SEVEN CROWNS. The last line has been filed off.")
    L.tablet("ThroneStone", 4200, 480, "The Court",
             "The throne room is full. Nobody in it is breathing. They are all waiting to be told what to swear.")
    L.enemy("KeepPilgrim", "pilgrim", 520, 480, 40)
    L.enemy("KeepLurker", "lurker", 780, 480, 0)
    L.enemy("KeepArcher", "archer", 1000, 400, 20, -1)
    L.enemy("KeepGilded", "gilded", 1080, 480, 40)
    L.enemy("KeepCaptain", "captain", 1180, 480, 40)
    L.enemy("FoundryPilgrim", "pilgrim", 2350, 480, 40)
    L.enemy("FoundryGuard", "gilded", 2540, 452, 40)
    L.enemy("FoundrySergeant", "sergeant", 2700, 480, 40)
    L.enemy("GantryArcher", "archer", 2850, 398, 20, -1)
    L.enemy("FoundryCantor", "cantor", 3000, 480, 30)
    L.enemy("CourtCaptain", "captain", 4400, 480, 40)
    L.enemy("CourtGilded", "gilded", 4480, 450, 40)
    L.enemy("CourtLurker", "lurker", 4720, 480, 0)
    L.jet("KeepJetA", 1020, 480, 0.0)
    L.jet("KeepJetB", 1050, 480, 1.5)
    L.chest("KeepChest", 880, 480, "keep_chest", count=2, embers=700, item="it_draught")
    L.chest("GantryChest", 2860, 398, "keep_chest_2", count=1, embers=800, item="it_shard")
    L.arena("VessArena", 1300, 480, "vess", "THE CHAIN IS SLACK", 420, 620)
    L.arena("BrandArena", 3250, 480, "brand", "THE FURNACE GOES COLD", 420, 620)
    L.arena("RegentArena", 5000, 480, "regent", "THE COURT IS DISMISSED", 420, 560)
    L.walk_exit("ToBelfry", 5880, 480, BELFRY, "from_keep")
    L.entry("FromBelfry", 5800, 480, "from_belfry")
    L.npc("Hesk", 2010, "hesk", "Hesk", 1, -1)
    L.write()


def belfry():
    W = 4800
    L = Level("drowned_belfry.tscn")
    L.use("hall")
    L.node(f'''
[node name="DrownedBelfry" type="Node2D"]
script = ExtResource("level")
level_id = &"drowned_belfry"
display_name = "The Drowned Belfry"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = 0.68
map_origin = Vector2(10400, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = 133
ghosts = 6
style = 1

[node name="Light" type="CanvasModulate" parent="."]
color = Color(0.66, 0.62, 0.78, 1)

[node name="Geometry" type="Node2D" parent="."]''')
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.block("StairA", 600, 452, 200, 28, style=1)
    L.plank("LoftA", 1000, 400, 150)
    L.plank("LoftB", 1300, 392, 130)
    L.block("StairB", 1750, 450, 200, 30, style=1)
    L.entry("FromKeep", 130, 480, "from_keep")
    L.walk_exit("ToKeep", 34, 480, KEEP, "from_belfry")
    L.candle("BelfryGateCandle", 300, 480, "belfry_gate_candle", "Belfry Gate Candle")
    L.candle("BellChamberCandle", 2050, 480, "belfry_mid_candle", "Bell Chamber Candle")
    L.tablet("RingersBoard", 420, 480, "The Ringers' Board",
             "A board of names, each with a number of strokes. Tolland's has no number. It says: 'Until relieved.' No one relieved him.")
    L.tablet("CrackedBell", 4000, 480, "The Cracked Bell",
             "The great bell lies on its side, its tongue gone. The stone around it is worn smooth by hands that came to listen to nothing.")
    L.enemy("BearerA", "bearer", 520, 480, 40)
    L.enemy("MothA", "moth", 700, 452, 40)
    L.enemy("GildedA", "gilded", 780, 452, 40)
    L.enemy("ArcherLoft", "archer", 1040, 400, 20, -1)
    L.enemy("CaptainA", "captain", 1180, 480, 40)
    L.enemy("BearerB", "bearer", 1500, 480, 40)
    L.enemy("MothB", "moth", 1800, 450, 40)
    L.enemy("SergeantA", "sergeant", 1910, 450, 40)
    L.enemy("CantorA", "cantor", 2200, 480, 30)
    L.enemy("PilgrimA", "pilgrim", 2400, 480, 40)
    L.jet("BelfryJetA", 1450, 480, 0.0)
    L.jet("BelfryJetB", 1480, 480, 1.5)
    L.spikes("BelfrySpikes", 2300, 480, 48)
    L.chest("BelfryChest", 880, 480, "belfry_chest", count=2, embers=800, item="it_draught")
    L.chest("LoftChest", 1360, 392, "belfry_chest_2", count=1, embers=900, item="it_shard")
    L.arena("RingerArena", 2600, 480, "ringer", "THE BELL RINGS NO MORE", 420, 620)
    L.walk_exit("ToGardens", 4710, 480, "res://world/levels/bleeding_gardens.tscn", "from_prev")
    L.entry("FromGardens", 4620, 480, "from_next")
    L.chest("BelfryCache", 4300, 480, "belfry_cache", count=3, embers=1500, item="it_shard")
    L.write()


PART_SPECS = [
    dict(level="bleeding_gardens", name="The Bleeding Gardens", node="BleedingGardens", prev=("drowned_belfry", BELFRY), nxt="iron_orrery",
         tint="(0.82, 0.62, 0.7, 1)", pitch=0.7, origin=12000, seed=151, style=0, boss="thornmother", text="THE GARDEN GOES TO SEED",
         ground=["moth", "penitent", "cantor", "moth", "gilded", "penitent"], step=["bearer", "captain"], loft=["archer", "archer"],
         hazard="spikes", tabs=("Gardener's Tag", "A wooden tag on a rose stem: 'ELSBET. PLEASE WATER.' The water was never the problem.", "The Last Bloom", "One rose, black at the edges, grown through a fence of ribs. It is the only thing in the garden that is not moving."),
         cands=("Garden Gate Candle", "Bower Candle")),
    dict(level="iron_orrery", name="The Iron Orrery", node="IronOrrery", prev=("bleeding_gardens", None), nxt="sunken_basilica",
         tint="(0.78, 0.7, 0.55, 1)", pitch=0.68, origin=13600, seed=173, style=1, boss="orrerist", text="THE CLOCK STOPS",
         ground=["sergeant", "gilded", "captain", "bearer", "sergeant", "cantor"], step=["captain", "gilded"], loft=["archer", "archer"],
         hazard="jet", tabs=("Calloway's Note", "A card pinned to a brass arm: 'The Crown returns on the 1,461st day. I have recounted. It was the 1,461st yesterday.'", "The Stopped Face", "A great dial with no hands. Someone has scratched a face where the hands should be."),
         cands=("Orrery Gate Candle", "Escapement Candle")),
    dict(level="sunken_basilica", name="The Sunken Basilica", node="SunkenBasilica", prev=("iron_orrery", None), nxt="crownless_citadel",
         tint="(0.5, 0.68, 0.76, 1)", pitch=0.64, origin=15200, seed=191, style=1, boss="bishop", text="THE SERMON ENDS",
         ground=["pilgrim", "lurker", "pilgrim", "cantor", "lurker", "pilgrim"], step=["pilgrim", "gilded"], loft=["archer", "archer"],
         hazard="water", tabs=("The Pulpit Scrawl", "Scratched under the water line: 'HE IS STILL PREACHING. WE ARE STILL KNEELING. THE WATER HAS REACHED THE SECOND PEW.'", "The Flooded Nave", "The pews are in rows. The rows are under water. The hymn board reads, in drowned numerals: ONE HUNDRED AND FOUR."),
         cands=("Basilica Gate Candle", "Nave Candle")),
    dict(level="crownless_citadel", name="The Crownless Citadel", node="CrownlessCitadel", prev=("sunken_basilica", None), nxt="weeping_ossuary",
         tint="(0.7, 0.66, 0.78, 1)", pitch=0.6, origin=16800, seed=211, style=1, boss="crownless", text="THE THRONE IS EMPTY",
         ground=["captain", "gilded", "sergeant", "captain", "cantor", "gilded"], step=["captain", "gilded"], loft=["archer", "archer"],
         hazard="jet", tabs=("The Roll of Kings", "A scroll of names, each crossed out. The last has no name, only a crown drawn in ink and left unfinished.", "The Empty Hall", "A long hall of chairs, all facing a throne. On the throne sits nothing, very carefully."),
         cands=("Citadel Gate Candle", "Hall of Chairs Candle")),
]


def parts():
    for sp in PART_SPECS:
        W = 5000
        L = Level(sp["level"] + ".tscn")
        L.use("hall")
        lvl = sp["level"]
        L.node(f'''
[node name="{sp["node"]}" type="Node2D"]
script = ExtResource("level")
level_id = &"{lvl}"
display_name = "{sp["name"]}"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = {sp["pitch"]}
map_origin = Vector2({sp["origin"]}, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("hall")
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = {sp["seed"]}
ghosts = 5
style = {sp["style"]}

[node name="Light" type="CanvasModulate" parent="."]
color = Color{sp["tint"]}

[node name="Geometry" type="Node2D" parent="."]''')
        L.block("CliffLeft", 0, 0, 16, 480)
        L.block("Ground", 16, 480, W - 16, 60, style=4)
        L.block("CliffRight", W - 60, 0, 60, 540)
        L.block("Ceiling", 0, 40, W, 56)
        L.block("StepA", 600, 452, 200, 28, style=1)
        L.plank("LoftA", 1000, 400, 150)
        L.plank("LoftB", 1300, 392, 130)
        L.block("StepB", 1750, 450, 200, 30, style=1)
        L.block("StepC", 3500, 452, 200, 28, style=1)
        L.plank("LoftC", 3900, 398, 150)
        prev_level, prev_path = sp["prev"]
        prev_path = prev_path or f"res://world/levels/{prev_level}.tscn"
        L.entry("FromPrev", 130, 480, "from_prev")
        L.walk_exit("ToPrev", 34, 480, prev_path, "from_next")
        L.entry("FromNext", W - 140, 480, "from_next")
        if sp["nxt"]:
            L.walk_exit("ToNext", W - 90, 480, f"res://world/levels/{sp['nxt']}.tscn", "from_prev")
        L.candle("GateCandle", 300, 480, lvl + "_gate_candle", sp["cands"][0])
        L.candle("MidCandle", 2050, 480, lvl + "_mid_candle", sp["cands"][1])
        L.tablet("TabletA", 420, 480, sp["tabs"][0], sp["tabs"][1])
        L.tablet("TabletB", 4000, 480, sp["tabs"][2], sp["tabs"][3])
        gx = [520, 880, 1180, 1500, 2250, 2400]
        for i, sc in enumerate(sp["ground"]):
            L.enemy(f"Ground{i}", sc, gx[i], 480, 40 if sc not in ("lurker", "moth") else (0 if sc == "lurker" else 40))
        L.enemy("StepFoeA", sp["step"][0], 780, 452, 40)
        L.enemy("StepFoeB", sp["step"][1], 1910, 450, 40)
        L.enemy("LoftArcherA", sp["loft"][0], 1040, 400, 20, -1)
        L.enemy("LoftArcherB", sp["loft"][1], 1360, 392, 20, -1)
        L.enemy("RearGuard", "captain", 3600, 452, 40)
        if sp["hazard"] == "spikes":
            L.spikes("Spikes", 1560, 480, 48)
            L.spikes("SpikesB", 2300, 480, 48)
        elif sp["hazard"] == "jet":
            L.jet("JetA", 1450, 480, 0.0)
            L.jet("JetB", 1480, 480, 1.5)
            L.jet("JetC", 2300, 480, 0.8, 2.6)
        else:
            L.water("FloodA", 1000, 466, 700, 14)
            L.water("FloodB", 2200, 466, 500, 14)
            L.spikes("Spikes", 1560, 480, 48)
        L.chest("ChestA", 900, 480, lvl + "_chest", count=2, embers=900, item="it_draught")
        L.chest("ChestB", 1360, 392, lvl + "_chest_2", count=1, embers=1000, item="it_shard")
        L.chest("ChestC", 3960, 398, lvl + "_chest_3", count=1, embers=1100, item="it_knot")
        L.chest("Cache", 4400, 480, lvl + "_cache", count=3, embers=1800, item="it_shard")
        L.arena("BossArena", 2600, 480, sp["boss"], sp["text"], 420, 620)
        L.write()


# Which map holds which new weapon (the Descent): index into XD.MAPS -> (weapon id).
GRAND_WEAPONS = {0: "bone_cleaver", 1: "chandlers_maul", 2: "archivists_needle", 3: "thornwood_sabre",
                 6: "glasswrights_shards", 10: "vowbreaker", 11: "choirmasters_baton", 12: "lantern_hook", 13: "namebreaker", 14: "unkept_blade"}


def grand():
    """The Descent: eleven long maps (W=7400), each with three boss arenas (mini, mini, main/final)."""
    n = len(XD.MAPS)
    for i, mp in enumerate(XD.MAPS):
        W = 7400
        key = mp["key"]
        L = Level(key + ".tscn")
        L.use("hall")
        L.use("backdrop")
        L.node(f'''
[node name="{mp["node"]}" type="Node2D"]
script = ExtResource("level")
level_id = &"{key}"
display_name = "{mp["name"]}"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = {round(0.58 - 0.012 * i, 3)}
map_origin = Vector2({18400 + 1700 * i}, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("backdrop")
theme = {mp.get('look', i)}
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = {300 + 17 * i}

[node name="Light" type="CanvasModulate" parent="."]
color = Color{mp["tint"]}

[node name="Geometry" type="Node2D" parent="."]''')
        L.block("CliffLeft", 0, 0, 16, 480)
        L.block("Ground", 16, 480, W - 16, 60, style=4)
        L.block("CliffRight", W - 60, 0, 60, 540)
        L.block("Ceiling", 0, 40, W, 56)
        prev_path = "res://world/levels/crownless_citadel.tscn" if i == 0 else "res://world/levels/%s.tscn" % XD.MAPS[i - 1]["key"]
        L.entry("FromPrev", 130, 480, "from_prev")
        L.walk_exit("ToPrev", 34, 480, prev_path, "from_next")
        L.entry("FromNext", W - 140, 480, "from_next")
        if i < n - 1:
            L.walk_exit("ToNext", W - 90, 480, "res://world/levels/%s.tscn" % XD.MAPS[i + 1]["key"], "from_prev")
        else:   # the Wakeless Court is the last of the Descent: its far end leads to the Ninth Door
            L.walk_exit("ToNinthDoor", W - 90, 480, "res://world/levels/the_ninth_door.tscn", "from_court")
        cands = mp["cands"]
        for ci, cx in enumerate((300, 1450, 3750, 6050)):
            L.candle("Candle%d" % ci, cx, 480, "%s_candle_%d" % (key, ci), cands[ci])
        tabs = mp["tabs"]
        for ti, tx in enumerate((420, 3500, 5600)):
            L.tablet("Tablet%d" % ti, tx, 480, tabs[ti][0], tabs[ti][1])
        g = mp["ground"]
        for s_i, b in enumerate((0, 2300, 4600)):
            L.block("Step%d" % s_i, b + 600, 452, 200, 28, style=1)
            L.plank("Loft%d" % s_i, b + 1000, 400, 150)
            L.enemy("GroundA%d" % s_i, g[2 * s_i], b + 450, 480, 0 if g[2 * s_i] == "lurker" else 40)
            L.enemy("GroundB%d" % s_i, g[2 * s_i + 1], b + 1250, 480, 0 if g[2 * s_i + 1] == "lurker" else 40)
            L.enemy("StepFoe%d" % s_i, mp["step"][s_i % 2], b + 780, 452, 40)
            L.enemy("Archer%d" % s_i, mp["loft"][s_i % 2], b + 1040, 400, 20, -1)
            if mp["hazard"] == "spikes":
                L.spikes("Spikes%d" % s_i, b + 1400, 480, 48)
            elif mp["hazard"] == "jet":
                L.jet("JetA%d" % s_i, b + 1380, 480, 0.0)
                L.jet("JetB%d" % s_i, b + 1420, 480, 1.5)
            else:
                L.water("Flood%d" % s_i, b + 1330, 466, 280, 14)
            L.chest("Chest%d" % s_i, b + 900, 480, "%s_chest_%d" % (key, s_i), count=1 + s_i, embers=900 + 300 * s_i, item=("it_draught", "it_shard", "it_resin")[s_i])
            L.chest("LoftChest%d" % s_i, b + 1100, 400, "%s_loft_chest_%d" % (key, s_i), count=1, embers=1000 + 200 * i, item=("it_knot", "it_scrap", "it_band")[s_i])
        wf = D2.NPCS[i]
        L.npc("Wayfarer", wf["x"], wf["id"], wf["name"], wf["look"], -1, wf.get("shop"))
        am = D2.ARMORS[i]
        L.chest("ArmorChest", 3650, 480, key + "_armor_chest", gear=("armor", am[0]))
        L.chest("Cache", 7200, 480, key + "_cache", count=3, embers=2500 + 300 * i, item="it_shard")
        if i in GRAND_WEAPONS:
            L.chest("WeaponChest", 7100, 480, key + "_weapon_chest", gear=("weapon", GRAND_WEAPONS[i]))
        for s_i, b in enumerate((0, 2300, 4600)):
            bs = XD.BOSSES[i][s_i]
            word = bs["short"].upper()
            text = word + (" IS NO MORE" if bs["role"] != "mini" else " FALLS")
            L.arena("Arena%d" % s_i, b + 1700, 480, "x_" + bs["id"], text, 420, 620)
        L.write()


if __name__ == "__main__":
    grand()
    trial()
    reliquary()
    keep()
    belfry()
    parts()
    cellar()
    gallery()
    graveyard()
    chapel()
    import gen_nether_levels
    gen_nether_levels.write_all()
