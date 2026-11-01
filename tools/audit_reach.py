#!/usr/bin/env python3
"""Reachability audit for the generated levels (no Godot needed). Runs every generator in memory (after
Level.auto_steps) and reports (1) tall solid blocks standing on the ground road, (2) chests, enemies,
NPCs and candles standing on a surface nobody can reach. Exit code 1 if anything is found.
The player's jump rises ~52 px and crosses ~100 px (tests/jump_probe.tscn).   Run: python3 tools/audit_reach.py"""
import os, sys, io, contextlib
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "levels"))
import gen_side_levels as G

bad = 0
checked = 0
out = []


class Rec(G.Level):
    def write(self):
        global bad, checked
        self.auto_steps()
        surf, seen = self.reachable()
        if seen is None:
            return
        checked += 1
        ground = next(t for t in surf if t[0] == "Ground")
        for (n, x, y, w, h, o) in self.blocks:
            if n in ("Ground", "CliffLeft", "CliffRight", "Ceiling") or o:
                continue
            if y + h >= 478.0 and y < 480.0 - G.Level.RISE - 2.0 and x > 40 and x + w < ground[2] - 20:
                out.append(f"WALL    {self.fname}: {n} at x={x} is {480 - y:.0f} px tall on the road")
                bad += 1
        for (kind, name, x, y) in self.things:
            host = [t for t in surf if abs(t[3] - y) <= 2.0 and t[1] - 2 <= x <= t[2] + 2]
            if not host:
                out.append(f"FLOAT   {self.fname}: {kind} {name} at ({x},{y}) is not on any surface")
                bad += 1
            elif not any(h[0] in seen for h in host):
                out.append(f"UNREACH {self.fname}: {kind} {name} at ({x},{y}) on {host[0][0]}")
                bad += 1


G.Level = Rec
with contextlib.redirect_stdout(io.StringIO()) as buf:
    for fn in ("trial", "reliquary", "keep", "belfry", "parts", "grand", "cellar", "gallery", "graveyard", "chapel"):
        getattr(G, fn)()
    import gen_nether_levels as N
    N.door()
    N.hell()
    N.lower()
for line in buf.getvalue().splitlines():
    if "!!" in line:
        out.append(line)
print("\n".join(out))
print(f"audit: {checked} levels,", "clean" if bad == 0 else f"{bad} problems")
sys.exit(1 if bad else 0)
