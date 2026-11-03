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
size = Vector2(44, 384)
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


G.EXT["prop"] = ("Script", "res://world/puzzle/castle_prop.gd")
BRAZIER, STATUE, CARPET, THRONE, RACK, CAGE, BARRELS, GARGOYLE = range(8)


def _prop(L, name, x, kind, y=480, span=0):
    L.use("prop")
    L.node(f'''
[node name="{name}" type="Node2D" parent="."]
position = Vector2({x}, {y})
script = ExtResource("prop")
kind = {kind}''' + (f"\nspan = {span}.0" if span else ""))


def lower():
    """THE LOWER HELL: a castle lowered under the Ninth Hell like a lid. A long road (landing, outer ward,
    the Great Hall), then three HARD puzzle rooms, each shutting the way with a portcullis:
      1. THE FOUR WARDS: four levers (one open, one on a high loft over spikes, one behind staggered fire,
         one hidden behind a cracked wall);
      2. THE ORDER OF LOST THINGS: five rune stones, an order nobody states: it has to be worked out from
         three clue tablets; a wrong touch puts every stone out;
      3. THE RUN: three timed levers far apart, all alight at once, through fire and spikes;
    then the Gate-Fox (the single custom mini-boss). The fox drops a tooth shaped like a key; the Tooth Gate
    in the Landing takes it and leads down to the Grass Cellar. No other mini-bosses."""
    W = 13400
    L = G.Level("lower_hell.tscn")
    _head(L, "lower_hell", "The Lower Hell", "LowerHell", W, "(0.86, 0.68, 0.78, 1)", 12, 51800, 0.42)
    L.block("CliffLeft", 0, 0, 16, 480)
    L.block("Ground", 16, 480, W - 16, 60, style=0)
    L.block("CliffRight", W - 60, 0, 60, 540)
    L.block("Ceiling", 0, 40, W, 56)
    L.entry("FromHand", 200, 480, "from_hand")
    L.entry("FromBasement", 860, 480, "from_basement")
    L.walk_exit("ToHell", 34, 480, HELL, "from_lower")

    # ---- THE LANDING (0 - 1100): where the hand sets you down; the Tooth Gate under the stair ----------------
    _prop(L, "LandCarpet", 240, CARPET, span=820)
    _prop(L, "LandBrazier0", 330, BRAZIER)
    _prop(L, "LandBrazier1", 700, BRAZIER)
    _prop(L, "LandStatue", 1050, STATUE)
    L.candle("Candle0", 430, 480, "lower_hell_candle_0", "Hand's Landing Candle")
    L.tablet("Tablet0", 580, 480, "Set Down", "The hand did not drop you. It set you down, the way a hand sets down something it means to come back for. Above you there is no sky. There is a ceiling, and it has been swept.")
    L.tablet("ToothTablet", 790, 480, "The Keyhole", "A door beneath the stair. No handle, no hinge: only a keyhole the shape of a tooth. Something further in keeps what fits it.")
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

    # ---- THE OUTER WARD (1100 - 3100): ramparts, a rack of rusted pikes, the first guards ---------------------
    L.tablet("CastleTablet", 1220, 480, "A Lid", "A castle. Under hell. Nobody built it: it was lowered, the way a lid is lowered over a pot, and whatever is in the pot has been quiet for a very long time. Walk softly. The guards are still on their rounds.")
    _prop(L, "WardBrazier0", 1330, BRAZIER)
    _prop(L, "WardRack", 1470, RACK)
    _prop(L, "WardStatue0", 1640, STATUE)
    _prop(L, "WardCage0", 1850, CAGE)
    _prop(L, "WardBrazier1", 1960, BRAZIER)
    _prop(L, "WardBarrels", 2330, BARRELS)
    _prop(L, "WardGargoyle", 2560, GARGOYLE)
    _prop(L, "WardBrazier2", 2720, BRAZIER)
    _prop(L, "WardStatue1", 2860, STATUE)
    L.enemy("WardFoe0", "gilded", 1560, 480, 50)
    L.enemy("WardFoe1", "pikeman", 2050, 480, 60)
    L.spikes("WardSpikesA", 1760, 480, 80)
    L.block("Rampart", 2180, 436, 300, 44, style=0)
    L.enemy("WardArcher", "archer", 2400, 436, 20)
    L.chest("Chest0", 2260, 436, "lower_hell_chest_0", count=2, embers=5000, item="it_draught")
    L.enemy("WardFoe2", "cantor", 2780, 480, 50)
    L.candle("Candle1", 3010, 480, "lower_hell_candle_1", "Outer Ward Candle")

    # ---- THE GREAT HALL (3100 - 5600): a long red carpet to a throne nobody sits on ------------------------
    _prop(L, "HallCarpet", 3200, CARPET, span=2300)
    L.tablet("HallTablet", 3260, 480, "The Hall of Oaths", "The Great Hall. Four hundred knights knelt on this carpet and swore the same oath, and the oath is why the castle was lowered. The carpet is still red. Do not ask what keeps it that way.")
    for i, (kind, x) in enumerate([(STATUE, 3480), (BRAZIER, 3660), (STATUE, 3900), (BRAZIER, 4100), (STATUE, 4320), (BRAZIER, 4560), (STATUE, 4740), (BRAZIER, 4980)]):
        _prop(L, f"Hall{i}", x, kind)
    _prop(L, "HallCage0", 3790, CAGE)
    _prop(L, "HallCage1", 4650, CAGE)
    L.enemy("HallFoe0", "gilded", 3560, 480, 60)
    L.enemy("HallFoe1", "sergeant", 3850, 480, 60)
    L.enemy("HallFoe2", "cantor", 4200, 480, 50)
    L.jet("HallJetA", 4440, 480, 0.0)
    L.jet("HallJetB", 4500, 480, 1.5)
    L.enemy("HallFoe3", "captain", 4700, 480, 60)
    L.enemy("HallFoe4", "mender", 4900, 480, 40)
    L.block("Dais", 5080, 452, 360, 28, style=0)
    _prop(L, "HallThrone", 5260, THRONE, y=452)
    L.chest("Chest1", 5150, 452, "lower_hell_chest_1", count=2, embers=9000, item="it_shard")
    L.tablet("ThroneTablet", 5380, 452, "The Empty Seat", "The throne faces the door, not the hall. Whoever sat here was never watching the knights. He was watching for whatever would come in behind them.")
    L.candle("Candle2", 5560, 480, "lower_hell_candle_2", "Great Hall Candle")

    # ---- PUZZLE 1: THE FOUR WARDS (5700 - 7700) -----------------------------------------------------------
    _prop(L, "P1Brazier0", 5720, BRAZIER)
    L.tablet("LeverTablet", 5820, 480, "Four Wards", "FOUR WARDS HOLD THE FIRST GATE, AND EACH WARD IS A LEVER. One stands in the open, guarded. One is up where the dead cannot climb, over the teeth. One is behind the fire, and the fire keeps time. The fourth is not on the road at all: listen for the stone that sounds hollow. All four. Any three is a locked door.")
    _lever(L, "LeverA", 6040, 480, "lh_lever_a", 0.0, "first ward")
    L.enemy("P1Foe0", "pikeman", 5930, 480, 40)
    L.enemy("P1Foe1", "gilded", 6130, 480, 40)
    L.spikes("WardTeeth", 6320, 480, 440)
    L.block("WardStep", 6230, 452, 100, 28, style=1)
    L.plank("Loft1", 6320, 410, 150)
    L.plank("Loft2", 6530, 368, 160)
    _lever(L, "LeverB", 6640, 368, "lh_lever_b", 0.0, "high ward")
    _prop(L, "P1Cage", 6500, CAGE)
    L.jet("JetA", 6900, 480, 0.0)
    L.jet("JetB", 6970, 480, 1.0)
    L.jet("JetC", 7040, 480, 2.0)
    _lever(L, "LeverC", 7130, 480, "lh_lever_c", 0.0, "fire ward")
    L.enemy("P1Foe2", "mender", 7190, 480, 30)
    # the hidden ward: a cracked wall closes a low alcove
    L.node('''
[node name="HollowWall" type="StaticBody2D" parent="."]
position = Vector2(7250, 392)
script = ExtResource("wall")
size = Vector2(22, 88)
wall_id = &"lh_hollow_wall"
hits_needed = 3''')
    L.use("wall")
    L.block("AlcoveRoof", 7250, 380, 230, 14, style=0)
    L.block("AlcoveBack", 7460, 394, 20, 76, style=0)
    _lever(L, "LeverD", 7370, 480, "lh_lever_d", 0.0, "hidden ward")
    _gate(L, "Gate1", 7640, "lh_gate_1", ["lh_lever_a", "lh_lever_b", "lh_lever_c", "lh_lever_d"])
    L.candle("Candle4", 7780, 480, "lower_hell_candle_4", "First Portcullis Candle")
    _prop(L, "P1Statue", 7900, STATUE)
    L.chest("Chest2", 8000, 480, "lower_hell_chest_2", count=3, embers=7000, item="it_draught")

    # ---- PUZZLE 2: THE ORDER OF LOST THINGS (8150 - 10150) -------------------------------------------------
    _prop(L, "P2Carpet", 8150, CARPET, span=1900)
    L.tablet("RuneTablet0", 8200, 480, "The Order of Waking: I", "FIVE THINGS WERE LOST, AND THEY MUST BE WOKEN IN THE ORDER THEY WERE LOST. Nobody here will tell you the order. Three tablets each keep a piece of it. Read all three. The CROWN fell first. The MOON went last.")
    _rune(L, "RuneHand", 8420, 480, "lh_runes", 2, 5, 2)
    L.spikes("RuneSpikesA", 8520, 480, 70)
    L.enemy("P2Foe0", "gilded", 8340, 480, 40)
    L.enemy("P2Foe1", "cantor", 8620, 480, 40)
    L.block("MoonDais", 8700, 440, 130, 40, style=0)
    _rune(L, "RuneMoon", 8770, 440, "lh_runes", 4, 5, 0)
    _prop(L, "P2Brazier0", 8620, BRAZIER)
    L.tablet("RuneTablet1", 8930, 480, "The Order of Waking: II", "THE EYE CLOSED BEFORE THE HAND SIGNED. It had seen what was in the paper, and it closed rather than watch the hand do it.")
    _rune(L, "RuneEye", 9040, 480, "lh_runes", 1, 5, 1)
    L.jet("P2JetA", 9140, 480, 0.0)
    L.jet("P2JetB", 9200, 480, 1.5)
    L.enemy("P2Foe2", "captain", 9060, 480, 50)
    _prop(L, "P2Statue", 9330, STATUE)
    _rune(L, "RuneCrown", 9420, 480, "lh_runes", 0, 5, 4)
    L.enemy("P2Foe3", "sergeant", 9500, 480, 50)
    L.tablet("RuneTablet2", 9620, 480, "The Order of Waking: III", "THE FLAME WAS LIT AFTER THE HAND SIGNED, AND BEFORE THE MOON LOOKED AWAY. It was lit to burn the paper. It did not burn the paper. That is why you are here.")
    L.spikes("RuneSpikesB", 9720, 480, 70)
    _rune(L, "RuneFlame", 9860, 480, "lh_runes", 3, 5, 3)
    L.enemy("P2Foe4", "pikeman", 9780, 480, 40)
    _prop(L, "P2Cage", 9290, CAGE)
    _gate(L, "Gate2", 10080, "lh_gate_2", ["lh_runes"])
    L.candle("Candle5", 10220, 480, "lower_hell_candle_5", "Second Portcullis Candle")
    L.chest("Chest3", 10340, 480, "lower_hell_chest_3", count=2, embers=12000, item="it_shard")

    # ---- PUZZLE 3: THE RUN (10500 - 12300): three timed levers, a gate beyond all of them ---------------------
    _prop(L, "P3Brazier0", 10480, BRAZIER)
    L.tablet("RunTablet", 10560, 480, "One Breath", "THE LAST GATE OPENS ONLY WHEN ALL THREE LEVERS ARE ALIGHT AT ONCE. They spring back: the first will wait the longest, the last hardly at all. Throw them in the order you meet them and do not stop for the fire. If the first goes out before you reach the last, you walk it all again.")
    _lever(L, "RunLeverX", 10700, 480, "lh_run_x", 26.0, "first lever")
    L.jet("RunJetA", 10960, 480, 0.0)
    L.jet("RunJetB", 11020, 480, 1.5)
    L.spikes("RunSpikesA", 11160, 480, 80)
    L.enemy("P3Foe0", "gilded", 11330, 480, 40)
    L.block("RunStep", 11440, 452, 100, 28, style=1)
    L.plank("RunLoft", 11530, 410, 170)
    _lever(L, "RunLeverY", 11640, 410, "lh_run_y", 18.0, "middle lever")
    L.spikes("RunSpikesB", 11780, 480, 80)
    L.jet("RunJetC", 11900, 480, 0.5)
    L.jet("RunJetD", 11960, 480, 2.0)
    L.enemy("P3Foe1", "sergeant", 11800, 480, 40)
    _lever(L, "RunLeverZ", 12120, 480, "lh_run_z", 8.0, "last lever")
    _gate(L, "Gate3", 12220, "lh_gate_3", ["lh_run_x", "lh_run_y", "lh_run_z"])
    _prop(L, "P3Gargoyle", 12320, GARGOYLE)
    L.candle("Candle3", 12380, 480, "lower_hell_candle_3", "Fox Stair Candle")
    L.arena("FoxArena", 12460, 480, "foxboss", "THE GATE-FOX YIELDS", 420, 560)
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
