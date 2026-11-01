#!/usr/bin/env python3
"""The two maps after the Wakeless Court: THE NINTH DOOR (a threshold with Morvane, the custom boss, and
the portal that opens when he falls) and THE NINTH HELL (a netherish map ending in the Twin Lords' hand arena).
Uses the Level builder of gen_side_levels.py; called from its main block and from tools/audit_reach.py."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gen_side_levels as G

G.EXT["duo"] = ("Script", "res://world/boss/duo_arena.gd")
G.EXT["morvane"] = ("PackedScene", "res://actors/bosses/morvane_warden.tscn")
G.EXT["ashkar"] = ("PackedScene", "res://actors/bosses/ashkar_reaper.tscn")
G.EXT["veshti"] = ("PackedScene", "res://actors/bosses/veshti_gunner.tscn")
G.EXT["bloat"] = ("PackedScene", "res://actors/enemies/swollen_pilgrim.tscn")
G.EXT["mender"] = ("PackedScene", "res://actors/enemies/wick_mender.tscn")

DOOR = "res://world/levels/the_ninth_door.tscn"
HELL = "res://world/levels/ninth_hell.tscn"
LOWER = "res://world/levels/lower_hell.tscn"
COURT = "res://world/levels/wakeless_court.tscn"


def _head(L, key, name, node, W, tint, look, origin_x, music_pitch):
    L.use("hall")
    L.use("backdrop")
    L.node(f'''
[node name="{node}" type="Node2D"]
script = ExtResource("level")
level_id = &"{key}"
display_name = "{name}"
bounds = Rect2(0, 0, {W}, 540)
music = &"catacombs"
music_pitch = {music_pitch}
map_origin = Vector2({origin_x}, -1750)
default_spawn = Vector2(130, 480)

[node name="Hall" type="Node2D" parent="."]
z_index = -10
script = ExtResource("backdrop")
theme = {look}
width = {W}.0
floor_y = 480.0
ceiling_y = 96.0
seed_value = {777 + origin_x % 97}

[node name="Light" type="CanvasModulate" parent="."]
color = Color{tint}

[node name="Geometry" type="Node2D" parent="."]''')


def door():
    W = 2600
    L = G.Level("the_ninth_door.tscn")
    _head(L, "the_ninth_door", "The Ninth Door", "TheNinthDoor", W, "(0.78, 0.52, 0.58, 1)", 9, 43900, 0.5)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromCourt", 130, 480, "from_court")
    L.walk_exit("ToCourt", 34, 480, COURT, "from_next")
    L.entry("FromHell", 1500, 480, "from_hell")
    L.candle("DoorCandle", 330, 480, "ninth_door_candle", "Ninth Door Candle")
    L.tablet("DoorTablet", 520, 480, "The Ninth Door",
             "EIGHT DOORS WERE OPENED FOR THE OATH. THE NINTH WAS NEVER OPENED. IT WAS NEVER MEANT TO BE. Beneath, scratched deep: 'It is warm on the other side.'")
    L.tablet("WardenTablet", 1900, 480, "A Warden's Rule",
             "KEEP IT SHUT. If any pilgrim reaches this far, they have already done what no vow allows. Do not open it for them. Do not open it for yourself.")
    L.chest("DoorCache", 2300, 480, "ninth_door_cache", count=3, embers=8000, item="it_shard")
    L.arena("MorvaneArena", 700, 480, "morvane", "THE WARDEN YIELDS", 420, 620)
    L.nodes[-1] += (f'\nlight_target_level = "{HELL}"\nlight_target_entry = &"from_door"\n'
                    'light_tint = Color(0.75, 0.3, 1, 1)\nlight_offset = Vector2(900, 0)\nlight_delay = 3.0')
    L.write()


def hell():
    W = 6000
    L = G.Level("ninth_hell.tscn")
    _head(L, "ninth_hell", "The Ninth Hell", "NinthHell", W, "(1.0, 0.52, 0.42, 1)", 11, 45600, 0.46)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromDoor", 130, 480, "from_door")
    L.entry("FromLower", 4880, 480, "from_lower")
    L.walk_exit("ToDoor", 34, 480, DOOR, "from_hell")
    for ci, (cx, cn) in enumerate(((300, "Hell Gate Candle"), (1750, "Brimstone Candle"), (3200, "Chain Hall Candle"), (4350, "Twin Gate Candle"))):
        L.candle("Candle%d" % ci, cx, 480, "ninth_hell_candle_%d" % ci, cn)
    for ti, (tx, tt, tx_) in enumerate(((420, "Burnt Verse", "Not a punishment. A debt. Whatever is owed down here is owed to someone, and they are patient."),
                                        (2350, "Wrapped in Black", "The first dead were wrapped in white. These were wrapped in what burns without light. They do not seem to mind."),
                                        (4100, "The Hand That Signs", "Every oath is signed by a hand. This is the hand. It has been waiting so long to be asked what it signed."))):
        L.tablet("Tablet%d" % ti, tx, 480, tt, tx_)
    grounds = (("gilded", "bloat"), ("captain", "bloat"), ("sergeant", "cantor"))
    steps = (("captain", "gilded"), ("gilded", "sergeant"), ("captain", "captain"))
    lofts = (("archer", "mender"), ("mender", "cantor"), ("archer", "mender"))
    haz = ("jet", "spikes", "jet")
    for s_i, b in enumerate((0, 1500, 3000)):
        L.block("Step%d" % s_i, b + 600, 452, 200, 28, style=1)
        L.plank("Loft%d" % s_i, b + 1000, 400, 150)
        L.enemy("GroundA%d" % s_i, grounds[s_i][0], b + 450, 480, 40)
        L.enemy("GroundB%d" % s_i, grounds[s_i][1], b + 1250, 480, 40)
        L.enemy("StepFoe%d" % s_i, steps[s_i][0], b + 780, 452, 40)
        L.enemy("Archer%d" % s_i, lofts[s_i][0], b + 1040, 400, 20, -1)
        L.enemy("LoftFoe%d" % s_i, lofts[s_i][1], b + 1100, 400, 20, -1)
        hx = b + (1400 if s_i < 2 else 1330)
        if haz[s_i] == "spikes":
            L.spikes("Spikes%d" % s_i, hx, 480, 48)
        else:
            L.jet("JetA%d" % s_i, hx, 480, 0.0)
            L.jet("JetB%d" % s_i, hx + 40, 480, 1.5)
        L.chest("Chest%d" % s_i, b + 900, 480, "ninth_hell_chest_%d" % s_i, count=2 + s_i, embers=3000 + 800 * s_i, item=("it_draught", "it_shard", "it_resin")[s_i])
        L.chest("LoftChest%d" % s_i, b + 1100, 400, "ninth_hell_loft_chest_%d" % s_i, count=1, embers=2500, item=("it_knot", "it_scrap", "it_band")[s_i])
    L.chest("Cache", 5700, 480, "ninth_hell_cache", count=4, embers=15000, item="it_shard")
    for k in ("duo", "ashkar", "veshti"):
        L.use(k)
    L.node('''
[node name="TwinLordsArena" type="Node2D" parent="."]
position = Vector2(4500, 480)
script = ExtResource("duo")
boss_scene = ExtResource("ashkar")
second_scene = ExtResource("veshti")
boss_offset = Vector2(430, 0)
second_offset = Vector2(510, 0)
hand_offset = Vector2(470, 0)
gate_height = 96.0
trigger_offset = 36.0
trigger_width = 760.0
victory_text = "THE TWO HANDS ARE STILL"
reward_weapon = &"nightreaper"
reward_chest_id = &"twin_lords_reward"
portal_level = "''' + LOWER + '''"
portal_entry = &"from_hand"''')
    L.write()


def lower():
    """THE LOWER HELL: where the Twin Lords' hand carries you. A short PLACEHOLDER map (candle, tablets, a
    few foes, a chest) that ends at a sealed door, ready for the creative director's own boss and area."""
    W = 3200
    L = G.Level("lower_hell.tscn")
    _head(L, "lower_hell", "The Lower Hell", "LowerHell", W, "(0.72, 0.38, 0.5, 1)", 11, 51800, 0.42)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromHand", 200, 480, "from_hand")
    L.walk_exit("ToHell", 34, 480, HELL, "from_lower")
    L.candle("Candle0", 360, 480, "lower_hell_candle_0", "Hand's Landing Candle")
    L.candle("Candle1", 2000, 480, "lower_hell_candle_1", "Lower Brink Candle")
    L.tablet("Tablet0", 520, 480, "Set Down", "The hand did not drop you. It set you down, the way a hand sets down something it means to come back for.")
    L.tablet("Tablet1", 2700, 480, "Unwritten", "The way down ends here, for now. What waits below has not been written. It will be.")
    L.block("Step0", 900, 452, 200, 28, style=1)
    L.plank("Loft0", 1300, 400, 150)
    L.enemy("GroundA", "captain", 760, 480, 40)
    L.enemy("StepFoe", "gilded", 980, 452, 40)
    L.enemy("GroundB", "bloat", 1500, 480, 40)
    L.enemy("Archer", "archer", 1340, 400, 20, -1)
    L.enemy("GroundC", "sergeant", 2300, 480, 40)
    L.enemy("GroundD", "cantor", 2450, 480, 40)
    L.chest("Chest0", 1750, 480, "lower_hell_chest_0", count=3, embers=6000, item="it_draught")
    L.chest("Chest1", 2900, 480, "lower_hell_chest_1", count=2, embers=9000, item="it_shard")
    L.write()


def write_all():
    door()
    hell()
    lower()


if __name__ == "__main__":
    write_all()
