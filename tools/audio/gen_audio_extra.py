#!/usr/bin/env python3
"""TEMPORARY AUDIO, second batch: footstep variants, enemy voices, status and UI sounds, and
two more music loops (night, chapel). Uses gen_audio's helpers but its own random seed, so
running this never changes the first batch.
Run:  python3 tools/audio/gen_audio_extra.py"""
import os, subprocess, sys
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
import gen_audio as g

g.rng = np.random.default_rng(1234)
SR, MSR = g.SR, g.MSR
n = lambda d: g.noise(int(d * SR))


def make():
    # Footsteps: three more so running never sounds like two clops.
    for i, (lp, f) in enumerate([(700, 62), (1100, 78), (850, 70)]):
        st = g.lowpass(n(0.07), lp) * g.env(int(0.07 * SR), 0.002, 0.014)
        g.sfx("step_%d" % (i + 3), g.mix(st, g.thud(f, 42, 0.06, 0.12) * 0.3), 0.32)
    # Voices (rough, filtered noise and detuned saws; no words).
    d = 0.55
    t = g.t_axis(d)
    growl = g.lowpass(g.saw(70, d) + 0.6 * g.saw(73.5, d), 600) * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * t)) * g.env(len(t), 0.05, 0.25)
    g.sfx("voice_growl", g.reverb(growl + g.lowpass(g.noise(len(t)), 500) * 0.15, 0.1, 0.6, 0.2), 0.7)
    d = 0.6
    t = g.t_axis(d)
    hiss = g.bandpass(g.noise(len(t)), 3500, 8000) * g.env(len(t), 0.08, 0.3) * 0.8
    g.sfx("voice_hiss", hiss + g.lowpass(g.saw(180, d), 700) * g.env(len(t), 0.1, 0.25) * 0.2, 0.55)
    d = 1.1
    t = g.t_axis(d)
    chant = sum(a * np.sin(2 * np.pi * f * t * (1 + 0.004 * np.sin(2 * np.pi * 5 * t))) for f, a in [(130.8, 0.5), (196.0, 0.35), (261.6, 0.25)]) * g.env(len(t), 0.2, 0.7)
    g.sfx("voice_chant", g.reverb(chant, 0.35, 1.6, 0.5), 0.5)
    d = 0.35
    t = g.t_axis(d)
    twang = (np.sin(2 * np.pi * 380 * t * np.exp(-t * 1.4)) + 0.4 * np.sin(2 * np.pi * 760 * t)) * np.exp(-t / 0.09)
    g.sfx("archer_twang", g.mix(twang, g.highpass(g.noise(len(t)), 2500) * np.exp(-t / 0.01) * 0.5), 0.6)
    # Status effects
    g.sfx("fx_burn", g.mix(g.bandpass(n(0.45), 1500, 6000) * g.env(int(0.45 * SR), 0.03, 0.15) * 0.8, g.thud(110, 60, 0.2, 0.3) * 0.4), 0.7)
    t = g.t_axis(0.5)
    crack = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t / dd) for f, a, dd in [(2400, 0.4, 0.05), (3600, 0.3, 0.04), (5200, 0.2, 0.03)])
    g.sfx("fx_frost", g.mix(crack, g.highpass(g.noise(len(t)), 4000) * np.exp(-t / 0.02) * 0.6), 0.6)
    g.sfx("fx_bleed", g.mix(g.thud(90, 40, 0.3, 0.7), g.lowpass(n(0.2), 1200) * g.env(int(0.2 * SR), 0.01, 0.07) * 0.6), 0.75)
    t = g.t_axis(0.6)
    g.sfx("fx_poison", g.bandpass(g.noise(len(t)), 600, 2400) * (0.5 + 0.5 * np.sin(2 * np.pi * 11 * t)) * g.env(len(t), 0.05, 0.25), 0.5)
    # Skills / UI
    d = 0.5
    t = g.t_axis(d)
    cast = g.mix(g.sweep_bandpass(n(d), 300, 3000, q=1.4) * g.env(len(t), 0.1, 0.22), g.thud(70, 40, 0.3, 0.3) * 0.3)
    g.sfx("skill_cast", cast, 0.8)
    t = g.t_axis(0.5)
    ready = (np.sin(2 * np.pi * 880 * t) + 0.5 * np.sin(2 * np.pi * 1320 * t)) * np.exp(-t / 0.14)
    g.sfx("focus_ready", g.reverb(ready, 0.2, 1.0, 0.3), 0.35)
    t = g.t_axis(0.4)
    g.sfx("relic_equip", (np.sin(2 * np.pi * 523 * t) + np.sin(2 * np.pi * 784 * t) * 0.6) * np.exp(-t / 0.12), 0.4)


def music_night():
    sr, dur = MSR, 40.0
    k = int(sr * dur)
    out = np.zeros(k)
    out += g.loop_noise(k, sr, lo=120, hi=700, seed=41) * (0.3 + 0.7 * g.slow_lfo(k, 2)) * 0.2
    out += g.loop_tone(41.2, k) * 0.12 * g.slow_lfo(k, 2, 0.3)
    out += g.loop_tone(61.7, k) * 0.07 * g.slow_lfo(k, 3, 1.1)
    for i, (sec, f) in enumerate([(5, 1318.5), (14, 987.8), (23, 1174.7), (33, 880.0)]):
        g.place(out, np.sin(2 * np.pi * f * np.arange(int(3 * sr)) / sr) * np.exp(-np.arange(int(3 * sr)) / sr / 0.6) * 0.05, int(sec * sr))
    for b in range(0, int(dur * 0.9), 4):   # a slow, distant heartbeat
        g.place(out, g.thud(70, 38, 0.2, 0.2)[::2] * 0.18, int(b * sr))
    out = g.circular_reverb(out, 0.4, 3.5, 1.4, sr)
    g.write(os.path.join(g.MUS_DIR, "night.wav"), out, sr, 0.5, do_fade=False)


def music_chapel():
    sr, dur = MSR, 40.0
    k = int(sr * dur)
    out = np.zeros(k)
    out += g.loop_noise(k, sr, lo=100, hi=500, seed=51) * 0.1
    for fq, am, cyc in [(55.0, 0.1, 2), (82.4, 0.08, 3), (110.0, 0.06, 4), (164.8, 0.04, 5)]:   # organ-ish drone
        out += g.loop_tone(fq, k) * am * g.slow_lfo(k, cyc, fq)
    for i, (sec, f) in enumerate([(4, 220.0), (14, 196.0), (24, 164.8), (34, 185.0)]):
        g.place(out, g.bell(f, 7.0, sr=sr, decay=3.2, cracked=0.5, seed=80 + i) * 0.13, int(sec * sr))
    out = g.circular_reverb(out, 0.45, 4.0, 1.6, sr)
    g.write(os.path.join(g.MUS_DIR, "chapel.wav"), out, sr, 0.55, do_fade=False)


if __name__ == "__main__":
    make()
    music_night()
    music_chapel()
    names = {"sfx": ["step_3", "step_4", "step_5", "voice_growl", "voice_hiss", "voice_chant", "archer_twang", "fx_burn", "fx_frost",
                     "fx_bleed", "fx_poison", "skill_cast", "focus_ready", "relic_equip"], "music": ["night", "chapel"]}
    total = 0
    for kind, src, dst, extra in (("sfx", g.SFX_DIR, g.OUT_SFX, ["-ar", "16000", "-q:a", "0"]), ("music", g.MUS_DIR, g.OUT_MUS, ["-q:a", "0"])):
        for nm in names[kind]:
            out = os.path.join(dst, nm + ".ogg")
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", os.path.join(src, nm + ".wav"),
                            "-c:a", "libvorbis"] + extra + [out], check=True)
            total += os.path.getsize(out)
            print("%-36s %7.1f KB" % (os.path.relpath(out, g.ROOT), os.path.getsize(out) / 1024))
    print("total %.1f KB" % (total / 1024))
