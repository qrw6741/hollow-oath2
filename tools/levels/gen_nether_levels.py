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


BASEMENT = "res://world/levels/hell_basement.tscn"
G.EXT["pgate"] = ("Script", "res://world/puzzle/puzzle_gate.gd")
G.EXT["lever"] = ("Script", "res://world/puzzle/lever.gd")
G.EXT["rune"] = ("Script", "res://world/puzzle/rune_stone.gd")
G.EXT["foxboss"] = ("PackedScene", "res://actors/bosses/tooth_fox.tscn")
G.EXT["elderboss"] = ("PackedScene", "res://actors/bosses/ember_elder.tscn")
G.EXT["elderarena"] = ("Script", "res://world/boss/elder_arena.gd")
G.EXT["it_tooth"] = ("Resource", "res://data/items/fox_tooth.tres")


def _gate(L, name, x, gid, requires, hint="The gate will not move."):
    L.use("pgate")
    L.node(f'''
[node name="{name}" type="StaticBody2D" parent="."]
position = Vector2({x}, 480)
script = ExtResource("pgate")
gate_id = &"{gid}"
requires = PackedStringArray({", ".join('"%s"' % r for r in requires)})
size = Vector2(20, 130)
hint = "{hint}"''')


def _lever(L, name, x, y, lid, secs=0.0, title="lever"):
    L.things.append(("lever", name, x, y))
    L.use("lever")
    L.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("lever")
lever_id = &"{lid}"
seconds = {secs}
display_name = "{title}"''')


def _rune(L, name, x, y, seq, idx, total, glyph):
    L.things.append(("rune", name, x, y))
    L.use("rune")
    L.node(f'''
[node name="{name}" type="Area2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("rune")
seq_id = &"{seq}"
index = {idx}
total = {total}
glyph = {glyph}''')


def lower():
    """THE LOWER HELL: where the Twin Lords' hand carries you. NO new mini-bosses and no mob gauntlets: three
    PUZZLE rooms (levers; a rune sequence; a timed two-lever run), each closing the way with a gate, then the
    Gate-Fox (the single custom mini-boss). The fox drops a tooth shaped like a key; the Tooth Gate near the
    entrance takes it and leads down to the Basement."""
    W = 7000
    L = G.Level("lower_hell.tscn")
    _head(L, "lower_hell", "The Lower Hell", "LowerHell", W, "(0.72, 0.38, 0.5, 1)", 11, 51800, 0.42)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=4)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromHand", 200, 480, "from_hand")
    L.entry("FromBasement", 860, 480, "from_basement")
    L.walk_exit("ToHell", 34, 480, HELL, "from_lower")
    L.candle("Candle0", 380, 480, "lower_hell_candle_0", "Hand's Landing Candle")
    L.tablet("Tablet0", 560, 480, "Set Down", "The hand did not drop you. It set you down, the way a hand sets down something it means to come back for.")
    # the Tooth Gate: a secret door with a keyhole shaped like a tooth (opens with the Fox Tooth)
    L.use("exit")
    L.use("it_tooth")
    L.node(f'''
[node name="ToothGate" type="Area2D" parent="."]
position = Vector2(960, 480)
script = ExtResource("exit")
target_level = "{BASEMENT}"
target_entry = &"from_gate"
mode = 1
size = Vector2(30, 70)
required_item = &"fox_tooth"
door_id = &"tooth_gate"
display_name = "the Tooth Gate"
locked_text = "A door with no handle. The keyhole is shaped like a tooth."
unlock_text = "The tooth fits. The door swings in."''')
    L.tablet("ToothTablet", 780, 480, "The Keyhole", "A door beneath the stair. No handle, no hinge: only a keyhole the shape of a tooth. Something up ahead keeps what fits it.")

    # ---- PUZZLE 1: THREE LEVERS (x 1100 - 2500) -------------------------------------------------------
    L.tablet("LeverTablet", 1150, 480, "Three Hands", "THREE LEVERS HOLD THE FIRST GATE. One stands in the open. One is above, where the dead cannot climb. One is behind the fire. All three must be thrown.")
    _lever(L, "LeverA", 1450, 480, "lh_lever_a", 0.0, "first lever")
    L.block("Step1", 1700, 452, 140, 28, style=1)
    L.plank("Loft1", 1900, 412, 150)
    _lever(L, "LeverB", 1960, 412, "lh_lever_b", 0.0, "high lever")
    L.jet("JetA", 2180, 480, 0.0)
    L.jet("JetB", 2230, 480, 1.5)
    _lever(L, "LeverC", 2330, 480, "lh_lever_c", 0.0, "last lever")
    L.enemy("P1Foe0", "captain", 1250, 480, 40)
    L.enemy("P1Foe1", "bloat", 2050, 480, 40)
    _gate(L, "Gate1", 2560, "lh_gate_1", ["lh_lever_a", "lh_lever_b", "lh_lever_c"])
    L.candle("Candle1", 2680, 480, "lower_hell_candle_1", "First Gate Candle")
    L.chest("Chest0", 2880, 480, "lower_hell_chest_0", count=3, embers=6000, item="it_draught")

    # ---- PUZZLE 2: THE RUNE ORDER (x 3000 - 4500) ------------------------------------------------------
    L.tablet("RuneTablet", 3050, 480, "The Order of Waking", "WAKE THEM IN THE ORDER THEY WERE LOST. First the MOON, that watched. Then the FLAME, that warmed. Then the EYE, that saw. Last the HAND, that signed. A wrong touch puts out every stone.")
    _rune(L, "RuneMoon", 3700, 480, "lh_runes", 0, 4, 0)
    _rune(L, "RuneFlame", 3350, 480, "lh_runes", 1, 4, 3)
    _rune(L, "RuneEye", 4150, 480, "lh_runes", 2, 4, 1)
    _rune(L, "RuneHand", 3500, 480, "lh_runes", 3, 4, 2)
    L.spikes("RuneSpikes", 3880, 480, 120)
    L.block("RuneStep", 3860, 452, 160, 28, style=1)
    L.enemy("P2Foe0", "gilded", 3600, 480, 30)
    L.enemy("P2Foe1", "cantor", 4000, 480, 30)
    _gate(L, "Gate2", 4400, "lh_gate_2", ["lh_runes"])
    L.chest("Chest1", 4560, 480, "lower_hell_chest_1", count=2, embers=9000, item="it_shard")
    L.candle("Candle2", 4660, 480, "lower_hell_candle_2", "Rune Gate Candle")

    # ---- PUZZLE 3: THE RUN (x 4800 - 6200): two timed levers, a gate beyond both -------------------------
    L.tablet("RunTablet", 4800, 480, "Two Doors, One Breath", "THE LAST GATE OPENS ONLY WHEN BOTH LEVERS ARE HELD AT ONCE. They spring back. The first will wait for you a little while. Do not stop for the fire.")
    _lever(L, "RunLeverA", 4950, 480, "lh_run_a", 22.0, "near lever")
    L.jet("RunJetA", 5200, 480, 0.0)
    L.jet("RunJetB", 5240, 480, 1.0)
    L.spikes("RunSpikes", 5400, 480, 100)
    L.block("RunStep", 5380, 452, 140, 28, style=1)
    L.jet("RunJetC", 5640, 480, 0.5)
    _lever(L, "RunLeverB", 5850, 480, "lh_run_b", 22.0, "far lever")
    _gate(L, "Gate3", 6020, "lh_gate_3", ["lh_run_a", "lh_run_b"])
    L.candle("Candle3", 6120, 480, "lower_hell_candle_3", "Fox Stair Candle")
    L.arena("FoxArena", 6200, 480, "foxboss", "THE GATE-FOX YIELDS", 420, 560)
    L.write()


def basement():
    """THE BASEMENT: behind the Tooth Gate. Grass and warm light in the middle of hell. An old man in chains."""
    W = 2400
    L = G.Level("hell_basement.tscn")
    _head(L, "hell_basement", "The Grass Cellar", "HellBasement", W, "(0.85, 1.0, 0.78, 1)", 3, 53200, 0.8)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=3)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromGate", 150, 480, "from_gate")
    L.walk_exit("ToLower", 34, 480, LOWER, "from_basement")
    L.candle("Candle0", 360, 480, "hell_basement_candle", "Grass Cellar Candle")
    L.tablet("Tablet0", 560, 480, "Green", "Grass. Down here. Someone carried the seeds in on their boots, or someone down here is still dreaming of a field.")
    L.tablet("Tablet1", 820, 480, "Before the Chains", "He kept the fire for them. That was the oath. Not to fight it, only to be the one it burned in, so it would not burn anyone else.")
    L.chest("Chest0", 1850, 480, "hell_basement_chest", count=3, embers=12000, item="it_shard")
    L.use("elderarena")
    L.use("elderboss")
    L.node('''
[node name="ElderArena" type="Node2D" parent="."]
position = Vector2(1000, 480)
script = ExtResource("elderarena")
boss_scene = ExtResource("elderboss")
boss_offset = Vector2(420, 0)
gate_height = 96.0
trigger_offset = 36.0
trigger_width = 700.0
victory_text = "THE FIRE GOES OUT"''')
    L.write()


def write_all():
    door()
    hell()
    lower()
    basement()


if __name__ == "__main__":
    write_all()
