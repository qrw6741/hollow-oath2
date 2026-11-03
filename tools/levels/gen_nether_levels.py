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


def _chain(L, prefix, x, prev_y, specs, solid=()):
    """A run of floating platforms (parkour). specs = [(gap, width, top_y), ...]; every hop is checked against
    the player's reach (gap <= 86 px, rise <= 46 px) so the route is always possible. Returns the platforms
    as (name, x, width, y) and the x where the run ends."""
    out = []
    for i, (gap, w, y) in enumerate(specs):
        assert gap <= 86, (prefix, i, "gap", gap)
        assert prev_y - y <= 46, (prefix, i, "rise", prev_y - y)
        x += gap
        name = f"{prefix}{i}"
        if i in solid:
            L.block(name, x, y, w, 20, style=0)
        else:
            L.plank(name, x, y, w)
        out.append((name, x, w, y))
        x += w
        prev_y = y
    return out, x


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
    W = 33200
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
    # (no back wall: the alcove is a lintel over the road, so the road to the gate stays open once the wall is broken)
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

    # ======================= PAST THE FOX: NO MORE BOSSES, ONLY THE ROAD =======================================
    # a bulwark that only gives way when the fox falls, so the tooth can never be skipped
    L.use("wall")
    L.node('''
[node name="FoxBulwark" type="StaticBody2D" parent="."]
position = Vector2(13230, 96)
script = ExtResource("wall")
size = Vector2(24, 384)
wall_id = &"lh_fox_bulwark"
hits_needed = 9999
opens_when_boss = &"tooth_fox"''')
    L.candle("Candle6", 13360, 480, "lower_hell_candle_6", "After the Fox Candle")
    _prop(L, "AfterBrazier", 13300, BRAZIER)
    L.tablet("StairTablet", 13450, 480, "Where the Stair Was", "The castle goes on past the fox, and upward. The stair that should be here was taken out, step by step, by someone who did not want to be followed. The floor below is teeth. Do not look for a way around.")

    # ---- THE BROKEN STAIR: a staircase with the steps removed, over a field of spikes ------------------------------
    c = 13520
    stair, ex = _chain(L, "StairStep", c, 480, [
        (70, 120, 440), (80, 90, 400), (84, 90, 360), (80, 100, 322), (86, 80, 286), (80, 150, 286),
        (84, 80, 330), (80, 80, 372), (84, 90, 414), (80, 90, 450), (84, 100, 450), (80, 100, 410),
        (84, 90, 372), (82, 110, 372), (84, 90, 414), (80, 120, 450)])
    L.spikes("StairTeeth", c + 20, 480, ex - c)
    L.enemy("StairArcher", "archer", stair[5][1] + 90, 286, 20)
    L.enemy("StairMoth0", "moth", stair[2][1] + 40, 330, 90)
    L.enemy("StairMoth1", "moth", stair[8][1] + 40, 380, 90)
    L.enemy("StairMoth2", "moth", stair[12][1] + 40, 330, 90)
    L.enemy("StairGuard", "pikeman", stair[13][1] + 70, 372, 20)
    _prop(L, "StairCage0", stair[3][1] + 40, CAGE)
    _prop(L, "StairCage1", stair[10][1] + 40, CAGE)
    _prop(L, "StairGargoyle", c + (ex - c) // 2, GARGOYLE)
    c = ex + 60
    L.candle("Candle7", c, 480, "lower_hell_candle_7", "Broken Stair Candle")

    # ---- THE KEEPERS' WALK: a long hall of guards: no tricks, just more of them than you want --------------------
    k = c + 120
    _prop(L, "KeepCarpet", k, CARPET, span=1700)
    _prop(L, "KeepBrazier0", k + 40, BRAZIER)
    L.enemy("KeepA0", "gilded", k + 200, 480, 60)
    L.enemy("KeepA1", "sergeant", k + 280, 480, 50)
    L.enemy("KeepA2", "cantor", k + 420, 480, 50)
    _prop(L, "KeepStatue0", k + 480, STATUE)
    L.block("Parapet0", k + 560, 436, 220, 44, style=0)
    L.enemy("KeepArcher0", "archer", k + 700, 436, 20)
    L.enemy("KeepB0", "captain", k + 640, 480, 60)
    L.jet("KeepJetA", k + 860, 480, 0.0)
    L.jet("KeepJetB", k + 920, 480, 1.0)
    L.jet("KeepJetC", k + 980, 480, 2.0)
    L.enemy("KeepB1", "bearer", k + 1080, 480, 60)
    L.enemy("KeepB2", "pikeman", k + 1160, 480, 60)
    _prop(L, "KeepBrazier1", k + 1120, BRAZIER)
    L.spikes("KeepSpikes", k + 1250, 480, 80)
    L.enemy("KeepC0", "sergeant", k + 1360, 480, 60)
    L.enemy("KeepC1", "gilded", k + 1440, 480, 60)
    L.block("Parapet1", k + 1460, 440, 200, 40, style=0)
    L.enemy("KeepArcher1", "archer", k + 1580, 440, 20)
    L.enemy("KeepC2", "bloat", k + 1520, 480, 40)
    L.enemy("KeepC3", "mender", k + 1660, 480, 30)
    L.enemy("KeepD0", "penitent", k + 350, 480, 60)
    L.enemy("KeepD1", "pilgrim", k + 540, 480, 60)
    L.enemy("KeepD2", "captain", k + 1210, 480, 60)
    L.enemy("KeepD3", "lurker", k + 1320, 480, 40)
    _prop(L, "KeepGargoyle", k + 780, GARGOYLE)
    _prop(L, "KeepCage", k + 1000, CAGE)
    L.chest("Chest4", k + 1610, 440, "lower_hell_chest_4", count=3, embers=10000, item="it_draught")

    # ---- THE CHANDELIER RUN: small perches over fire jets and spikes, with moths on you -----------------------------
    c = k + 1800
    L.tablet("ChandelierTablet", c, 480, "Chandeliers", "The great chandeliers were lowered into the dark and never lit again. Their rings are still there, if you can call that a floor. Nothing here forgives a short jump.")
    c += 60
    chand, ex = _chain(L, "Chand", c, 480, [
        (70, 80, 440), (84, 70, 404), (86, 60, 370), (84, 70, 336), (86, 60, 370), (84, 70, 404),
        (86, 60, 370), (84, 90, 330), (86, 60, 296), (84, 70, 330), (86, 60, 366), (84, 80, 402),
        (86, 60, 440), (84, 70, 404), (86, 70, 440)])
    L.spikes("ChandTeeth", c + 20, 480, ex - c)
    jx = c + 140
    n = 0
    while jx < ex - 100:
        L.jet(f"ChandJet{n}", jx, 480, (n * 0.9) % 3.0)
        jx += 260
        n += 1
    L.enemy("ChandMoth0", "moth", chand[2][1] + 30, 340, 100)
    L.enemy("ChandMoth1", "moth", chand[5][1] + 30, 340, 100)
    L.enemy("ChandMoth2", "moth", chand[8][1] + 30, 260, 100)
    L.enemy("ChandMoth3", "moth", chand[11][1] + 30, 340, 100)
    L.enemy("ChandMoth4", "moth", chand[13][1] + 30, 370, 100)
    _prop(L, "ChandCage0", chand[4][1] + 30, CAGE)
    _prop(L, "ChandCage1", chand[10][1] + 30, CAGE)
    c = ex + 60
    _prop(L, "ChandBrazier", c - 40, BRAZIER)
    L.candle("Candle8", c, 480, "lower_hell_candle_8", "Chandelier Candle")

    # ---- THE BELFRY CLIMB: up a tower of ledges guarded at every landing, then down the far side --------------------
    b = c + 120
    L.tablet("BelfryTablet", b, 480, "The Climb", "A bell tower with the bell gone. Whoever hung the bell is said to have climbed it every night to be sure it would still ring, and it never rang. Take it a ledge at a time. Every ledge has a guard.")
    b += 80
    belfry, ex = _chain(L, "Belfry", b, 480, [
        (0, 110, 440), (80, 70, 400), (80, 170, 366), (80, 70, 334), (80, 60, 300), (80, 180, 270),
        (80, 60, 306), (80, 70, 342), (80, 70, 378), (80, 120, 414)], solid=(0, 2, 5))
    L.spikes("BelfryTeeth", b, 480, ex - b)
    L.enemy("BelfryGuard0", "sergeant", belfry[2][1] + 90, 366, 40)
    L.enemy("BelfryGuard1", "gilded", belfry[5][1] + 70, 270, 40)
    L.enemy("BelfryArcher", "archer", belfry[5][1] + 150, 270, 20)
    L.enemy("BelfryMoth0", "moth", belfry[1][1] + 30, 330, 100)
    L.enemy("BelfryMoth1", "moth", belfry[4][1] + 30, 250, 100)
    L.enemy("BelfryMoth2", "moth", belfry[7][1] + 30, 300, 100)
    # a crow's nest above the top ledge: the Long Katana, for anyone who looks up
    nx = belfry[5][1] + 40
    L.plank("NestA", nx, 228, 70)
    L.plank("NestB", nx + 100, 186, 90)
    L.chest("ChestKatana", nx + 150, 186, "lower_hell_chest_katana", gear=("weapon", "long_katana"))
    L.tablet("NestTablet", belfry[5][1] + 20, 270, "Crows", "Crows nest in the high places, and so did the sentries. The best steel in the castle never went into the armoury. Somebody hid it above the bell, where nobody would climb for it. Nobody who was supposed to.")
    _prop(L, "BelfryCage", belfry[3][1] + 30, CAGE)
    c = ex + 80
    L.candle("Candle9", c, 480, "lower_hell_candle_9", "Belfry Candle")

    # ---- THE KENNELS: where the castle kept what it did not feed -------------------------------------------------
    k = c + 140
    L.tablet("KennelTablet", k, 480, "The Kennels", "Where the castle kept what it did not feed. The doors are gone. The tenants are not. Nobody here has been fed since the lid came down, and they have decided you will do.")
    _prop(L, "KennelBrazier0", k + 60, BRAZIER)
    _prop(L, "KennelRack", k + 150, RACK)
    for i, (kind, dx, pat) in enumerate([("penitent", 260, 70), ("cellarer", 380, 50), ("gravewarden", 500, 60), ("pilgrim", 620, 70), ("cinder", 740, 50),
                                         ("ashfall", 860, 60), ("lurker", 960, 40), ("penitent", 1060, 70), ("gilded", 1160, 50), ("sergeant", 1260, 60)]):
        L.enemy(f"KennelFoe{i}", kind, k + dx, 480, pat)
    L.block("KennelLedgeA", k + 330, 440, 200, 40, style=0)
    L.enemy("KennelArcherA", "archer", k + 430, 440, 10)
    L.block("KennelLedgeB", k + 1000, 440, 200, 40, style=0)
    L.enemy("KennelArcherB", "archer", k + 1100, 440, 10)
    L.jet("KennelJetA", k + 560, 480, 0.0)
    L.jet("KennelJetB", k + 620, 480, 1.5)
    L.spikes("KennelSpikesA", k + 800, 480, 80)
    L.jet("KennelJetC", k + 1240, 480, 0.5)
    L.jet("KennelJetD", k + 1300, 480, 2.0)
    _prop(L, "KennelCage0", k + 480, CAGE)
    _prop(L, "KennelCage1", k + 1150, CAGE)
    _prop(L, "KennelGargoyle", k + 700, GARGOYLE)
    L.chest("Chest5", k + 1180, 440, "lower_hell_chest_5", count=2, embers=14000, item="it_draught")
    c = k + 1420
    L.candle("Candle10", c, 480, "lower_hell_candle_10", "Kennel Candle")

    # ---- THE GALLOWS STAIR: up and down a scaffold over teeth, a guard on every rest --------------------------------
    g = c + 140
    L.tablet("GallowsTablet", g, 480, "The Gallows Stair", "They hanged people here from a scaffold forty feet up, and the stair to it is the only thing in the castle built without a rail. The teeth below were added later, as a courtesy.")
    g += 80
    gal, ex = _chain(L, "Gallows", g, 480, [
        (0, 100, 440), (80, 70, 398), (82, 70, 356), (80, 60, 314), (84, 120, 314), (80, 60, 356), (82, 60, 398), (80, 60, 440),
        (84, 70, 400), (82, 60, 360), (84, 60, 320), (82, 60, 280), (84, 130, 280), (82, 60, 322), (84, 60, 364), (82, 60, 406), (84, 100, 448)],
        solid=(0, 4, 12))
    L.spikes("GallowsTeeth", g, 480, ex - g)
    L.enemy("GallowsGuard0", "captain", gal[4][1] + 80, 314, 40)
    L.enemy("GallowsGuard1", "sergeant", gal[12][1] + 80, 280, 40)
    L.enemy("GallowsArcher0", "archer", gal[4][1] + 110, 314, 10)
    L.enemy("GallowsArcher1", "archer", gal[10][1] + 30, 320, 6)
    L.enemy("GallowsMoth0", "moth", gal[2][1] + 30, 300, 100)
    L.enemy("GallowsMoth1", "moth", gal[8][1] + 30, 320, 100)
    L.enemy("GallowsMoth2", "moth", gal[14][1] + 30, 260, 100)
    n = 0
    jx = g + 200
    while jx < ex - 100:
        L.jet(f"GallowsJet{n}", jx, 480, (n * 1.1) % 3.0)
        jx += 240
        n += 1
    _prop(L, "GallowsCage0", gal[3][1] + 30, CAGE)
    _prop(L, "GallowsCage1", gal[11][1] + 30, CAGE)
    c = ex + 80
    L.candle("Candle11", c, 480, "lower_hell_candle_11", "Gallows Candle")

    # ---- THE LONG CORRIDOR: nothing to climb, everything to fight ------------------------------------------------
    k = c + 140
    L.tablet("CorridorTablet", k, 480, "A Straight Road", "After the stair, a straight road. It is the cruellest thing in the castle: no height to climb, no plank to count. Only a long hall, and the people at the end of it who would like very much for you to stop.")
    for i, (kind, dx, pat) in enumerate([("captain", 220, 60), ("pikeman", 320, 50), ("gilded", 420, 60), ("mender", 520, 40), ("cantor", 600, 50),
                                         ("sergeant", 760, 60), ("captain", 860, 60), ("bearer", 960, 60), ("gravewarden", 1060, 50), ("cinder", 1160, 50),
                                         ("ashfall", 1280, 60), ("lurker", 1380, 40), ("captain", 1480, 60), ("sergeant", 1560, 60)]):
        L.enemy(f"CorrFoe{i}", kind, k + dx, 480, pat)
    for i, dx in enumerate((300, 680, 1100, 1450)):
        L.jet(f"CorrJetA{i}", k + dx, 480, (i * 0.8) % 3.0)
        L.jet(f"CorrJetB{i}", k + dx + 60, 480, (i * 0.8 + 1.5) % 3.0)
    L.spikes("CorrSpikesA", k + 460, 480, 70)
    L.spikes("CorrSpikesB", k + 900, 480, 70)
    L.spikes("CorrSpikesC", k + 1240, 480, 70)
    L.block("CorrLedge", k + 700, 440, 220, 40, style=0)
    L.enemy("CorrArcher0", "archer", k + 840, 440, 10)
    L.enemy("CorrArcher1", "archer", k + 1500, 480, 10)
    for i, dx in enumerate((120, 560, 1000, 1400)):
        _prop(L, f"CorrProp{i}", k + dx, BRAZIER if i % 2 == 0 else STATUE)
    _prop(L, "CorrCarpet", k + 40, CARPET, span=1640)
    c = k + 1700
    L.candle("Candle12", c, 480, "lower_hell_candle_12", "Long Corridor Candle")

    # ---- THE CROWN WALK: planks the width of a hand, near the ceiling, with the wind of the dead in them ----------------
    w = c + 140
    L.tablet("CrownTablet", w, 480, "The Crown Walk", "Where the kings walked when they wanted the castle to see them. A ledge the width of a hand along the roof-beams, and the whole hall below. Whatever lives up here can fly.")
    w += 80
    crown, ex = _chain(L, "Crown", w, 480, [
        (0, 100, 440), (80, 60, 398), (84, 60, 356), (84, 60, 314), (84, 60, 272), (84, 120, 272), (84, 50, 314), (84, 50, 272), (84, 50, 230),
        (84, 50, 272), (84, 50, 230), (84, 50, 272), (84, 50, 314), (84, 110, 314), (84, 50, 272), (84, 50, 230), (84, 50, 272), (84, 50, 314),
        (84, 50, 356), (84, 60, 398), (84, 100, 440)], solid=(0, 5, 13))
    L.spikes("CrownTeeth", w, 480, ex - w)
    for i, idx in enumerate((2, 6, 8, 11, 15, 17)):
        L.enemy(f"CrownMoth{i}", "moth", crown[idx][1] + 20, 260, 100)
    L.enemy("CrownGuard0", "captain", crown[5][1] + 70, 272, 40)
    L.enemy("CrownGuard1", "sergeant", crown[13][1] + 60, 314, 40)
    L.enemy("CrownArcher0", "archer", crown[5][1] + 100, 272, 10)
    L.enemy("CrownArcher1", "archer", crown[13][1] + 90, 314, 10)
    L.enemy("CrownArcher2", "archer", crown[10][1] + 25, 230, 6)
    _prop(L, "CrownCage0", crown[4][1] + 30, CAGE)
    _prop(L, "CrownCage1", crown[16][1] + 30, CAGE)
    c = ex + 80
    L.candle("Candle13", c, 480, "lower_hell_candle_13", "Crown Walk Candle")
    L.chest("Chest6", c + 120, 480, "lower_hell_chest_6", count=3, embers=30000, item="it_shard")
    L.tablet("EndTablet", c + 220, 480, "The Road Does Not End", "The castle has more rooms than the dark has patience for. This is as far as the road is laid. Rest, then ask the one who laid it where it goes next.")
    L.end_x = c + 400
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
