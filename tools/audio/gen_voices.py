#!/usr/bin/env python3
"""TEMPORARY VOICES: spoken boss lines made with ffmpeg's flite text-to-speech, then pitched down, doubled with
a detuned layer and drowned in echo so they sound demonic. NOT recorded acting: it is robotic TTS.
Text comes from the game's own data (systems/boss_lines.gd, world/boss/duo_arena.gd), so subtitles and
voice never drift apart.  Output: assets/audio/voice/<boss_id>_<n>.ogg, twins_intro_<n>.ogg, twins_enrage_<n>.ogg
(n: 0,1 = intro, 2 = half health, 3 = defeated, 4 = you fell).
Run:  python3 tools/audio/gen_voices.py [boss_id ...]      (needs ffmpeg built with flite)"""
import os, re, subprocess, sys, tempfile
R = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = f"{R}/assets/audio/voice"
os.makedirs(OUT, exist_ok=True)

# flite voice, main pitch factor, second (detuned) layer factor, echo delays (ms), tempo
STYLES = {
    "reaper":  dict(v="rms", p=0.60, p2=0.50, echo="70|140", tempo=1.12),   # deep, slow, grave
    "gunner":  dict(v="slt", p=0.74, p2=0.62, echo="55|110", tempo=1.08),   # lower, colder, quicker
    "warden":  dict(v="kal", p=0.58, p2=0.47, echo="90|180", tempo=1.10),   # booming and gravelly
}
WHO = {"ashkar_reaper": "reaper", "veshti_gunner": "gunner", "morvane_warden": "warden"}


def quoted(s):
    return re.findall(r'"((?:[^"\\]|\\.)*)"', s)


src = open(f"{R}/systems/boss_lines.gd").read()
duo = open(f"{R}/world/boss/duo_arena.gd").read()
jobs = {}   # file name -> (text, style)
for bid, style in WHO.items():
    m = re.search(r'&"%s": \[(.*?)\],\n' % bid, src, re.S)
    for i, t in enumerate(quoted(m.group(1))):
        jobs[f"{bid}_{i}"] = (t, style)
ti = re.search(r"const TWINS_INTRO := \[(.*?)\n\]", src, re.S).group(1)
for i, (who, t) in enumerate(re.findall(r'\["([^"]*)", "([^"]*)"\]', ti)):
    jobs[f"twins_intro_{i}"] = (t, "gunner" if who.startswith("Veshti") else "reaper")
e0 = re.search(r'"(Brother![^"]*)"', duo).group(1)
e1 = re.search(r'"(Veshti![^"]*)"', duo).group(1)
jobs["twins_enrage_0"] = (e0, "gunner")   # the Reaper fell: the Gunner answers
jobs["twins_enrage_1"] = (e1, "reaper")   # the Gunner fell: the Reaper answers

for grp, name in (("TWINS_MID", "twins_mid"), ("TWINS_END", "twins_end")):
    body = re.search(r"const %s := \[(.*?)\n\]" % grp, src, re.S).group(1)
    for i, (who, t) in enumerate(re.findall(r'\["([^"]*)", "([^"]*)"\]', body)):
        jobs[f"{name}_{i}"] = (t, "gunner" if who.startswith("Veshti") else "reaper")

only = set(sys.argv[1:])
n = 0
for name, (text, style) in sorted(jobs.items()):
    if only and not any(name.startswith(o) for o in only):
        continue
    st = STYLES[style]
    esc = text.replace("\\", "").replace("'", "").replace(":", " ").replace(",", ", ")
    sr = 16000
    fc = (f"[0:a]asplit[a][b];"
          f"[a]asetrate={int(sr * st['p'])},aresample=44100,atempo={st['tempo']}[a2];"
          f"[b]asetrate={int(sr * st['p2'])},aresample=44100,atempo={st['tempo']},volume=0.55[b2];"
          f"[a2][b2]amix=inputs=2:duration=longest:normalize=0,"
          f"lowpass=f=3800,highpass=f=70,aecho=0.8:0.6:{st['echo']}:0.30|0.18,"
          f"acompressor=threshold=-18dB:ratio=3,loudnorm=I=-16:TP=-1.5:LRA=7[out]")
    out = f"{OUT}/{name}.ogg"
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i", f"flite=text='{esc}':voice={st['v']}",
           "-filter_complex", fc, "-map", "[out]", "-ac", "1", "-c:a", "libvorbis", "-q:a", "3", out]
    subprocess.run(cmd, check=True)
    n += 1
print("voices written:", n, "->", OUT)
