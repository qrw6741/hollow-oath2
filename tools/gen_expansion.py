#!/usr/bin/env python3
"""Generates 'The Descent': 33 bosses (attacks shared by archetype/status/tier), their enemy data and
scenes, six new weapons (clones of existing weapons with new stats), and registers everything in the
GDScript lists (Bestiary, WorldMap, Deeds, Weapons, Items). Idempotent. Levels: gen_side_levels.py.
Run: python3 tools/gen_expansion.py && python3 tools/gen_talismans.py && python3 tools/levels/gen_side_levels.py"""
import os, sys, io, re, contextlib
sys.path.insert(0, os.path.dirname(__file__))
R = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
with contextlib.redirect_stdout(io.StringIO()):
    import gen_side_areas as G
import expansion_data as E

# anim, startup, active, recovery, damage multiplier
ARCH = {
    "brute":   [("smash", 32, 6, 34, 1.15), ("sweep", 26, 7, 30, 0.95), ("smash", 28, 6, 30, 1.0), ("leap", 46, 6, 36, 1.25)],
    "duelist": [("slash", 16, 5, 22, 0.9), ("lunge", 18, 6, 30, 1.0), ("throw", 24, 2, 26, 0.7), ("leap", 44, 6, 34, 1.2)],
    "caster":  [("throw", 22, 2, 26, 0.8), ("sweep", 26, 7, 30, 0.9), ("throw", 30, 2, 32, 1.0), ("leap", 48, 6, 38, 1.25)],
    "heavy":   [("smash", 38, 7, 38, 1.3), ("sweep", 32, 8, 32, 1.0), ("throw", 30, 2, 32, 0.8), ("leap", 50, 7, 40, 1.4)],
    "stalker": [("lunge", 16, 6, 26, 0.95), ("slash", 14, 5, 20, 0.85), ("throw", 22, 2, 26, 0.7), ("leap", 42, 6, 32, 1.15)],
}
NAMES = {"smash": "Crushing Blow", "sweep": "Wide Sweep", "slash": "Quick Cut", "lunge": "Charging Lunge", "throw": "Hurled Strike", "leap": "Falling Strike"}
TIER = {"mini": 0, "main": 1, "final": 2}
BASE_DMG = {0: 22, 1: 30, 2: 40}


def hexcol(h):
    h = h.lstrip("#")
    return "Color(%.3f, %.3f, %.3f, 1)" % tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def attack_set(arch, status, tier, mi):
    ids = []
    for i, (anim, su, act, rec, mult) in enumerate(ARCH[arch]):
        aid = f"x_{arch}_{status}_{tier}_{i}"
        ids.append(aid)
        dmg = round((BASE_DMG[tier] + mi * 1.2) * mult)
        st = None if status == "none" else (status, 50 if anim == "throw" else 35)
        nm = f"{arch.title()} - {NAMES[anim]} ({status})"
        parry = anim in ("smash", "slash", "throw", "lunge") and i != 1
        if anim == "throw":
            G.attack(aid, nm, anim, su, act, rec, dmg, (90, -40), parry, (4, 4), (0, -34), proj=210.0 + 20 * tier, amin=90, amax=360, w=1.1, status=st, hs=0.05, shake=2.0)
        elif anim == "leap":
            G.attack(aid, nm, anim, su, act, rec, dmg, (220, -160), False, (130, 34), (0, -14), track=False, amin=100, amax=330, w=1.0, shake=10.0, status=st)
        elif anim == "lunge":
            G.attack(aid, nm, anim, su, act, rec, dmg, (180, -70), parry, (48, 30), (30, -18), amin=40, amax=220, w=1.0, lunge=240, lstart=14, lframes=8, track=False, shake=4.0, status=st)
        elif anim == "slash":
            G.attack(aid, nm, anim, su, act, rec, dmg, (150, -60), parry, (60, 32), (32, -20), amin=0, amax=70, w=1.3, lunge=70, lstart=12, lframes=4, status=st)
        elif anim == "sweep":
            G.attack(aid, nm, anim, su, act, rec, dmg, (200, -70), False, (90, 30), (36, -20), amin=0, amax=78, w=0.9, status=st)
        else:
            G.attack(aid, nm, anim, su, act, rec, dmg, (180, -110), parry, (60, 44), (30, -24), amin=0, amax=66, lunge=45, lstart=28, lframes=6, shake=7.0, status=st)
    return ids


def patch_scene(bid, b):
    p = f"{R}/actors/bosses/{bid}.tscn"
    s = open(p).read()
    s = re.sub(r"(\[node name=\"Visual\" type=\"Node2D\" parent=\"\.\"\]\nscript = ExtResource\(\"7_visual\"\)\nstyle = )\d+",
               lambda m: m.group(1) + "13\ncustom_coat = %s\ncustom_trim = %s\ncustom_long = %s\ncustom_prop = %d\ncustom_scale = %.2f" % (
                   hexcol(b["coat"]), hexcol(b["trim"]), "true" if b["long"] else "false", b["prop"], b["scale"]), s, count=1)
    assert "custom_prop" in s, bid
    open(p, "w").write(s)


def pascal(s):
    return "".join(w.title() for w in s.split("_"))


all_ids = []
for mi, group in enumerate(E.BOSSES):
    for b in group:
        tier = TIER[b["role"]]
        ids = attack_set(b["arch"], b["status"], tier, mi)
        role = b["role"]
        # The Descent follows the Crownless King (2,200 hp), so it ramps up steadily map by map from there.
        hp = {"mini": 1500 + 130 * mi, "main": 2600 + 280 * mi, "final": 9000}[role]
        if mi >= 11:   # beyond the Hollow Heart: the mains outgrow the Oath Eternal, the last boss tops them all
            hp = {"mini": 1500 + 130 * mi, "main": 9500 + 450 * (mi - 11), "final": 16000}[role]
        poise = {"mini": 110 + 8 * mi, "main": 150 + 12 * mi, "final": 280}[role]
        embers = {"mini": 2200 + 250 * mi, "main": 4800 + 450 * mi, "final": 20000}[role]
        if mi >= 11:
            embers = {"mini": 2200 + 250 * mi, "main": 22000 + 1500 * (mi - 11), "final": 40000}[role]
        chase = {"heavy": 50, "brute": 54, "caster": 52, "duelist": 62, "stalker": 70}[b["arch"]]
        G.enemy(b["id"], b["name"], b["lore"], ids[:3], hp, poise, chase, embers, b["drop"], "ember_shard")
        G.boss(pascal(b["id"]), b["id"], b["id"], ids, 13, hurt=(28, 54), music_pitch=round(0.66 - 0.01 * mi - (0.06 if role == "final" else 0.0), 2))
        patch_scene(b["id"], b)
        all_ids.append(b["id"])

# ---- six new weapons, cloned from existing ones (data only)
CLONES = [  # new id, base id, name, description, status, amount, damage_mult, map index it is found in
    ("bone_cleaver", "gravediggers_greataxe", "Bone Cleaver", "A cleaver hewn from a single femur the size of a man. The Ossuary never missed it.", "bleed", 30.0, 1.12, 0),
    ("chandlers_maul", "toll_hammer", "Chandler's Maul", "A hammer of hardened tallow around an iron core. It strikes like a hammer and burns like a wick.", "burn", 26.0, 1.12, 1),
    ("archivists_needle", "wayfarers_rapier", "Archivist's Needle", "A pen-thin blade used to pin pages. It writes your name in the wound.", "poison", 22.0, 1.1, 2),
    ("thornwood_sabre", "tide_sabre", "Thornwood Sabre", "A sabre cut from a tree that fed on the dead. It drinks and gives back poison.", "poison", 26.0, 1.12, 3),
    ("glasswrights_shards", "veil_daggers", "Glasswright's Shards", "Twin shards of the Gallery's windows. They cut sharply, and the cut shows you your own face.", "bleed", 28.0, 1.14, 6),
    ("vowbreaker", "kingsfall_greatsword", "Vowbreaker", "A greatsword with a cracked blade, bound by oaths it does not honour. It is very, very sharp.", "frost", 20.0, 1.2, 10),
    ("choirmasters_baton", "wayfarers_rapier", "Choirmaster's Baton", "A slim baton that conducts the choir's last note. Each flick leaves a cinder where it points.", "burn", 24.0, 1.12, 11),
    ("lantern_hook", "tide_sabre", "Lantern-Hook", "A ferryman's hook-blade with a marsh light caught in its curve. It pulls what it cuts.", "poison", 28.0, 1.14, 12),
    ("namebreaker", "gravediggers_greataxe", "Namebreaker", "A chisel as long as an axe-haft. It cuts a name out of whatever it strikes.", "frost", 32.0, 1.18, 13),
    ("unkept_blade", "kingsfall_greatsword", "The Unkept Blade", "A greatsword that was promised to someone and never given. It is very heavy with it.", "burn", 30.0, 1.24, 14),
]
for nid, base, name, desc, st, amt, dm, _ in CLONES:
    s = open(f"{R}/data/weapons/{base}.tres").read()
    s = re.sub(r'id = &"[a-z_]+"', f'id = &"{nid}"', s, count=1)
    s = re.sub(r'display_name = ".*"', f'display_name = "{name}"', s, count=1)
    s = re.sub(r'description = ".*"', f'description = "{desc}"', s, count=1)
    if "damage_mult = " in s:
        s = re.sub(r'damage_mult = [0-9.]+', f'damage_mult = {dm}', s, count=1)
    else:   # most base weapons omit it (default 1.0): add it, or the clone's stat is silently ignored
        s = s.replace('\ntwo_handed', f'\ndamage_mult = {dm}\ntwo_handed', 1) if "\ntwo_handed" in s else s.replace('\nstatus = &', f'\ndamage_mult = {dm}\nstatus = &', 1)
    s = re.sub(r'status = &"[a-z]*"', f'status = &"{st}"', s, count=1)
    s = re.sub(r'status_amount = [0-9.]+', f'status_amount = {amt}', s, count=1)
    open(f"{R}/data/weapons/{nid}.tres", "w").write(s)


# ---- registration (idempotent textual insertion into GDScript lists)
def add_to_list(path, anchor_regex, new_ids, quoted=True):
    s = open(f"{R}/{path}").read()
    m = re.search(anchor_regex, s, re.S)
    assert m, (path, anchor_regex)
    body = m.group(1)
    missing = [i for i in new_ids if f'&"{i}"' not in s[m.start():m.end()]]
    if not missing:
        return
    add = (" " if body.rstrip().endswith(",") else ", ") + ", ".join(f'&"{i}"' for i in missing)
    s = s[:m.end(1)] + add + s[m.end(1):]
    open(f"{R}/{path}", "w").write(s)


def add_text(path, marker_check, anchor, new):
    s = open(f"{R}/{path}").read()
    if marker_check in s:
        return
    assert anchor in s, (path, anchor)
    open(f"{R}/{path}", "w").write(s.replace(anchor, new + anchor, 1))


add_to_list("systems/bestiary.gd", r"const IDS: Array\[StringName\] = \[(.*?)\]", all_ids)
add_to_list("systems/weapons.gd", r"const IDS: Array\[StringName\] = \[(.*?)\]", [c[0] for c in CLONES])
s = open(f"{R}/systems/world_map.gd").read()
for m in E.MAPS:
    line = f'\t"res://world/levels/{m["key"]}.tscn",\n'
    if line not in s:
        s = s.replace('crownless_citadel.tscn",\n', 'crownless_citadel.tscn",\n' + line, 1) if m is E.MAPS[0] else s.replace(prev_line, prev_line + line, 1)
    prev_line = line
open(f"{R}/systems/world_map.gd", "w").write(s)

# Deeds: one per main/final boss, plus a count deed
mains = [b for g in E.BOSSES for b in g if b["role"] in ("main", "final")]
defs, matches, order = "", "", []
for b in mains:
    did = f"x_{b['id']}"
    defs += f'\t&"{did}": {{"title": "{b["short"]} Falls", "desc": "Defeat {b["name"]}."}},\n'
    matches += f'\t\t&"{did}": return _boss("{b["id"]}")\n'
    order.append(did)
defs += '\t&"giants_25": {"title": "Giant Killer", "desc": "Defeat 25 different bosses."},\n'
matches += '\t\t&"giants_25": return Expansion.bosses_defeated() >= 25\n'
order.append("giants_25")
if "&\"giants_25\"" not in open(f"{R}/systems/deeds.gd").read():
    s = open(f"{R}/systems/deeds.gd").read()
    s = s.replace('\t&"secrets": {"title"', defs + '\t&"secrets": {"title"', 1)
    s = s.replace('\t\t&"secrets": return Secrets', matches + '\t\t&"secrets": return Secrets', 1)
    s = s.replace('&"king_down", &"secrets"', '&"king_down", ' + ", ".join(f'&"{o}"' for o in order) + ', &"secrets"', 1)
    open(f"{R}/systems/deeds.gd", "w").write(s)

# Expansion data class for the game side (generated)
rows = []
for mi, g in enumerate(E.BOSSES):
    for b in g:
        rows.append(f'\t&"{b["id"]}": {{"name": "{b["name"]}", "short": "{b["short"]}", "role": &"{b["role"]}", "map": &"{E.MAPS[mi]["key"]}", "index": {mi}}},')
maps = ", ".join(f'&"{m["key"]}"' for m in E.MAPS)
open(f"{R}/systems/expansion.gd", "w").write(f'''class_name Expansion
extends RefCounted
## GENERATED by tools/gen_expansion.py. The Descent: 11 maps after the Crownless Citadel, each with two
## mini-bosses and one main boss. role = mini / main / final.

const BOSSES := {{
{chr(10).join(rows)}
}}
const MAPS: Array[StringName] = [{maps}]
const WEAPONS := {{{", ".join(f'&"{c[0]}": &"{E.MAPS[c[7]]["key"]}"' for c in CLONES)}}}


static func boss_ids() -> Array:
	return BOSSES.keys()


static func bosses_defeated() -> int:
	var n := 0
	for k in GameState.flags:
		if String(k).begins_with("boss_defeated_") and bool(GameState.flags[k]):
			n += 1
	return n
''')
print("expansion ok", len(all_ids))
