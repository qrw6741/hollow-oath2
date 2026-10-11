#!/usr/bin/env python3
"""TEMPORARY AUDIO — procedural placeholder sound effects and music for The Hollow Oath.

Everything is synthesised from sine waves, noise and filters (no samples, no licences).
Re-run to regenerate:   python3 tools/audio/gen_audio.py
Output: assets/audio/sfx/*.wav (44.1 kHz mono) and assets/audio/music/*.wav (22.05 kHz mono,
sample-exact loops; reverb tails are wrapped circularly so loops have no seam).
Deterministic: fixed random seeds, so regenerating gives identical files.
"""
import os
import wave
import numpy as np
from scipy import signal

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUS_DIR = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100
MSR = 22050
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ helpers

def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack, decay_tau, sr=SR):
    t = np.arange(n) / sr
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-np.maximum(t - attack, 0) / decay_tau)


def noise(n):
    return rng.standard_normal(n)


def bandpass(x, lo, hi, sr=SR, order=2):
    sos = signal.butter(order, [lo, hi], btype="band", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x, f, sr=SR, order=2):
    sos = signal.butter(order, f, btype="low", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x, f, sr=SR, order=2):
    sos = signal.butter(order, f, btype="high", fs=sr, output="sos")
    return signal.sosfilt(sos, x)


def sweep_bandpass(x, f0, f1, q=2.0, sr=SR, blocks=24):
    """Band-pass whose centre moves from f0 to f1 (block-wise, crossfaded)."""
    out = np.zeros_like(x)
    n = len(x)
    edges = np.linspace(0, n, blocks + 1).astype(int)
    for i in range(blocks):
        a, b = edges[i], edges[i + 1]
        f = f0 * (f1 / f0) ** (i / max(blocks - 1, 1))
        lo, hi = f / (1 + 1 / q), min(f * (1 + 1 / q), sr / 2 - 100)
        seg = bandpass(x[max(0, a - 512):b], lo, hi, sr)
        out[a:b] = seg[-(b - a):]
    return out


def tone(freq, dur, sr=SR, phase=0.0):
    t = t_axis(dur, sr)
    if callable(freq):
        f = freq(t)
        ph = 2 * np.pi * np.cumsum(f) / sr
    else:
        ph = 2 * np.pi * freq * t
    return np.sin(ph + phase)


def saw(freq, dur, sr=SR):
    t = t_axis(dur, sr)
    return 2.0 * ((t * freq) % 1.0) - 1.0


def reverb_ir(seconds, sr=SR, tau=0.5, seed=3):
    r = np.random.default_rng(seed)
    n = int(seconds * sr)
    t = np.arange(n) / sr
    ir = r.standard_normal(n) * np.exp(-t / tau)
    ir = lowpass(ir, 5000, sr)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def reverb(x, wet=0.25, seconds=1.6, tau=0.45, sr=SR):
    ir = reverb_ir(seconds, sr, tau)
    y = signal.fftconvolve(x, ir)[: len(x) + len(ir)]
    out = np.zeros(len(y))
    out[: len(x)] += x * (1 - wet)
    out += y * wet
    return out


def circular_reverb(x, wet=0.3, seconds=3.0, tau=0.9, sr=MSR):
    """Reverb whose tail wraps to the start: the loop stays seamless."""
    ir = reverb_ir(seconds, sr, tau)
    n = len(x)
    pad = np.zeros(n)
    pad[: min(n, len(ir))] = ir[: min(n, len(ir))]
    y = np.real(np.fft.ifft(np.fft.fft(x) * np.fft.fft(pad)))
    return x * (1 - wet) + y * wet


def bell(f0, dur, sr=SR, decay=2.5, cracked=0.0, seed=1):
    """Church-bell-like inharmonic partials (hum, prime, tierce, quint, nominal...)."""
    r = np.random.default_rng(seed)
    t = t_axis(dur, sr)
    ratios = [0.5, 1.0, 1.19, 1.5, 2.0, 2.52, 2.66, 3.01, 4.17, 5.43]
    amps = [0.55, 0.6, 0.45, 0.25, 0.5, 0.18, 0.12, 0.15, 0.08, 0.05]
    out = np.zeros_like(t)
    for r_, a in zip(ratios, amps):
        detune = 1.0 + (r.uniform(-0.004, 0.004) + cracked * r.uniform(-0.012, 0.012))
        f = f0 * r_ * detune
        if f > sr / 2 - 200:
            continue
        d = decay / (0.6 + r_ * 0.6)
        out += a * np.sin(2 * np.pi * f * t) * np.exp(-t / d)
        if cracked > 0:   # beating partner partial: the crack
            out += a * 0.6 * cracked * np.sin(2 * np.pi * f * (1 + 0.006 * cracked) * t) * np.exp(-t / (d * 0.7))
    strike = noise(len(t)) * np.exp(-t / 0.012) * 0.6
    out += highpass(strike, 1500, sr)
    return out


def fade(x, fin=0.002, fout=0.02, sr=SR):
    x = x.copy()
    a, b = int(fin * sr), int(fout * sr)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def norm(x, peak=0.89):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def write(path, x, sr=SR, peak=0.89, do_fade=True):
    x = norm(fade(x, sr=sr) if do_fade else x, peak)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def sfx(name, x, peak=0.89):
    write(os.path.join(SFX_DIR, name + ".wav"), x, SR, peak)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def thud(f0=95, f1=45, dur=0.18, click=0.4):
    t = t_axis(dur)
    body = tone(lambda tt: f1 + (f0 - f1) * np.exp(-tt / 0.03), dur) * np.exp(-t / (dur * 0.35))
    n = lowpass(noise(len(t)), 1400) * np.exp(-t / 0.02) * click
    return body + n


# ------------------------------------------------------------------ sound effects

def make_sfx():
    n = lambda d: noise(int(d * SR))
    # Swings
    for name, d, f0, f1, amp in [("swing_light", 0.2, 600, 2600, 1.0), ("swing_heavy", 0.34, 280, 1500, 1.0), ("swing_fist", 0.13, 900, 2200, 0.8)]:
        x = sweep_bandpass(n(d), f0, f1, q=1.6) * env(int(d * SR), d * 0.35, d * 0.25)
        if name == "swing_fist":
            x = mix(x, thud(160, 90, 0.08, 0.2) * 0.25)
        sfx(name, x * amp, 0.7)
    # Impacts
    sfx("hit_flesh", mix(thud(110, 50, 0.2, 0.6), lowpass(n(0.08), 2500) * env(int(0.08 * SR), 0.001, 0.02) * 0.5))
    t = t_axis(0.35)
    metal = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t / d) for f, a, d in [(520, 0.4, 0.12), (1340, 0.3, 0.09), (2210, 0.25, 0.07), (3480, 0.12, 0.05)])
    sfx("hit_armor", mix(thud(120, 60, 0.2, 0.5), metal))
    crit = mix(thud(80, 35, 0.4, 0.9), lowpass(n(0.25), 900) * env(int(0.25 * SR), 0.002, 0.06) * 0.8)
    sfx("hit_crit", reverb(crit, 0.25, 1.2, 0.3))
    # Parry: bright clang with a long ring — the most important sound in the game.
    t = t_axis(1.1)
    clang = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t / d) for f, a, d in
                [(1210, 0.5, 0.45), (1873, 0.45, 0.32), (2651, 0.35, 0.25), (3897, 0.25, 0.18), (5120, 0.15, 0.1), (1216, 0.3, 0.5)])
    clang += highpass(noise(len(t)), 3000) * np.exp(-t / 0.008) * 0.8
    sfx("parry", reverb(clang, 0.2, 1.4, 0.4))
    # Movement
    sfx("dodge", lowpass(n(0.28), 1800) * env(int(0.28 * SR), 0.05, 0.08), 0.55)
    sfx("jump", bandpass(n(0.09), 300, 1500) * env(int(0.09 * SR), 0.005, 0.03), 0.4)
    sfx("land", thud(90, 50, 0.12, 0.7), 0.5)
    for i in range(2):
        st = lowpass(n(0.06), 900 + i * 200) * env(int(0.06 * SR), 0.002, 0.012)
        sfx("step_%d" % (i + 1), mix(st, thud(70 + i * 10, 45, 0.05, 0.1) * 0.3), 0.32)
    # Player state
    hurt = mix(thud(130, 60, 0.22, 0.8), tone(lambda tt: 300 - 400 * tt, 0.25) * env(int(0.25 * SR), 0.005, 0.07) * 0.25)
    sfx("hurt", hurt, 0.8)
    t = t_axis(1.0)
    heal = sum(np.sin(2 * np.pi * f * t) * np.exp(-t / 0.5) * (0.4 if i else 0.5) for i, f in enumerate([880, 1320, 1760, 2637]))
    heal *= (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t))
    heal += sweep_bandpass(noise(len(t)), 800, 4000) * env(len(t), 0.3, 0.2) * 0.3
    sfx("heal", reverb(heal, 0.3), 0.6)
    t = t_axis(2.8)
    death = tone(lambda tt: 70 * np.exp(-tt / 3.0), 2.8) * env(len(t), 0.02, 1.0)
    death += lowpass(noise(len(t)), 300) * env(len(t), 0.05, 0.8) * 0.6
    death += bell(73.4, 2.8, decay=2.2, cracked=0.8, seed=5) * 0.4
    sfx("death", reverb(death, 0.35, 2.0, 0.7), 0.85)
    t = t_axis(1.8)
    rest = sum(np.sin(2 * np.pi * f * t) * env(len(t), 0.25, 0.7) * 0.3 for f in [220, 261.6, 329.6, 440])
    rest += lowpass(noise(len(t)), 900) * env(len(t), 0.2, 0.25) * 0.4
    sfx("rest", reverb(rest, 0.35, 1.8, 0.6), 0.6)
    # Economy
    t = t_axis(0.5)
    sp = np.zeros_like(t)
    for i, f in enumerate([1568, 1976, 2349, 3136]):
        s0 = int(i * 0.06 * SR)
        tt = t[: len(t) - s0]
        sp[s0:] += np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.12) * 0.4
    sfx("ember", reverb(sp, 0.2), 0.5)
    t = t_axis(0.5)
    pk = np.sin(2 * np.pi * 784 * t) * np.exp(-t / 0.15)
    pk[int(0.1 * SR):] += np.sin(2 * np.pi * 1175 * t[: len(t) - int(0.1 * SR)]) * np.exp(-t[: len(t) - int(0.1 * SR)] / 0.2)
    sfx("pickup", reverb(pk, 0.2), 0.5)
    t = t_axis(1.6)
    lv = np.zeros_like(t)
    for i, f in enumerate([293.7, 440, 587.3, 740, 880]):
        s0 = int(i * 0.09 * SR)
        tt = t[: len(t) - s0]
        lv[s0:] += bell(f, len(tt) / SR, decay=1.0, seed=10 + i)[: len(tt)] * 0.25
    sfx("levelup", reverb(lv, 0.3), 0.6)
    # UI
    t = t_axis(0.04)
    sfx("ui_move", np.sin(2 * np.pi * 1800 * t) * np.exp(-t / 0.008), 0.25)
    t = t_axis(0.16)
    sfx("ui_select", mix(np.sin(2 * np.pi * 1200 * t) * np.exp(-t / 0.03), np.sin(2 * np.pi * 1800 * t) * np.exp(-t / 0.05) * 0.6), 0.35)
    t = t_axis(0.12)
    sfx("ui_back", np.sin(2 * np.pi * 700 * t) * np.exp(-t / 0.03), 0.3)
    sfx("save", reverb(bell(523.3, 0.9, decay=0.5, seed=21), 0.25), 0.35)
    # Enemies
    d = 0.45
    rasp = bandpass(noise(int(d * SR)), 400, 2200) * env(int(d * SR), 0.3, 0.08)
    rasp *= 0.7 + 0.3 * np.sin(2 * np.pi * 38 * t_axis(d))
    sfx("enemy_windup", rasp, 0.45)
    sfx("enemy_death", reverb(mix(thud(80, 40, 0.3, 0.5), lowpass(noise(int(0.6 * SR)), 600) * env(int(0.6 * SR), 0.02, 0.2) * 0.6), 0.3), 0.6)
    # Boss — the Bell-Warden
    sfx("boss_bell", reverb(bell(98.0, 4.0, decay=3.0, cracked=0.6, seed=2), 0.3, 2.5, 0.9), 0.95)
    sfx("boss_stomp", mix(thud(70, 30, 0.35, 1.0), lowpass(noise(int(0.4 * SR)), 400) * env(int(0.4 * SR), 0.002, 0.12)), 0.8)
    land = mix(thud(60, 25, 0.6, 1.2), lowpass(noise(int(0.9 * SR)), 700) * env(int(0.9 * SR), 0.003, 0.25) * 1.2,
               bell(65.4, 1.5, decay=0.8, cracked=0.9, seed=8) * 0.35)
    sfx("boss_land", reverb(land, 0.3, 1.8, 0.6), 0.95)
    d = 2.2
    t = t_axis(d)
    vib = 55 + 3 * np.sin(2 * np.pi * 5.5 * t) + 10 * np.exp(-t / 0.6)
    growl = signal.sawtooth(2 * np.pi * np.cumsum(vib) / SR) * env(len(t), 0.15, 0.9)
    growl = bandpass(growl, 120, 1400) + lowpass(noise(len(t)), 500) * env(len(t), 0.1, 0.7) * 0.5
    growl += bell(110, d, decay=1.6, cracked=1.0, seed=4) * 0.35
    sfx("boss_roar", reverb(np.tanh(growl * 1.5), 0.35, 2.0, 0.7), 0.9)
    d = 4.5
    crack = bell(98.0, d, decay=2.5, cracked=1.0, seed=9) * 0.8
    crack += highpass(noise(int(d * SR)), 1800) * env(int(d * SR), 0.001, 0.08) * 1.2
    crack += tone(lambda tt: 90 * np.exp(-tt / 2.0), d) * env(int(d * SR), 0.01, 1.4) * 0.5
    sfx("boss_death", reverb(crack, 0.4, 3.0, 1.1), 0.95)
    d = 1.3
    seal = lowpass(noise(int(d * SR)), 600) * env(int(d * SR), 0.4, 0.3) + tone(55, d) * env(int(d * SR), 0.3, 0.4) * 0.5
    sfx("gate_seal", reverb(seal, 0.3), 0.7)
    # Village additions
    d = 0.3
    thr = sweep_bandpass(noise(int(d * SR)), 500, 1800, q=1.4) * env(int(d * SR), 0.06, 0.07)
    thr += lowpass(noise(int(d * SR)), 3000) * env(int(d * SR), 0.01, 0.15) * 0.25 * (0.5 + 0.5 * np.sin(2 * np.pi * 30 * t_axis(d)))
    sfx("throw", thr, 0.55)
    d = 0.5
    fz = highpass(noise(int(d * SR)), 2500) * env(int(d * SR), 0.005, 0.12) * (0.6 + 0.4 * np.sin(2 * np.pi * 47 * t_axis(d)))
    sfx("fizzle", fz, 0.45)
    sfx("bell_small", reverb(bell(392.0, 2.0, decay=1.0, cracked=0.4, seed=12), 0.25, 1.2, 0.4), 0.7)
    d = 1.4
    creak = sweep_bandpass(noise(int(d * SR)), 200, 600, q=6.0) * env(int(d * SR), 0.2, 0.5)
    creak *= 0.6 + 0.4 * np.sin(2 * np.pi * 11 * t_axis(d))
    sfx("door_open", mix(creak, thud(80, 40, 0.3, 0.6) * 0.6), 0.7)
    sfx("door_locked", mix(thud(140, 80, 0.12, 0.8), tone(260, 0.15) * env(int(0.15 * SR), 0.002, 0.04) * 0.4), 0.6)
    d = 1.8
    gate = mix(thud(70, 35, 0.4, 0.9), lowpass(noise(int(d * SR)), 500) * env(int(d * SR), 0.3, 0.5) * 0.8)
    sfx("gate_open", reverb(gate, 0.3), 0.8)

    t = t_axis(4.5)
    vic = np.zeros_like(t)
    for i, f in enumerate([146.8, 220, 293.7, 440, 587.3]):
        s0 = int(i * 0.25 * SR)
        vic[s0:] += bell(f, (len(t) - s0) / SR, decay=2.0, seed=30 + i)[: len(t) - s0] * 0.25
    sfx("victory", reverb(vic, 0.4, 2.5, 1.0), 0.8)


# ------------------------------------------------------------------ music (seamless loops)

def place(buf, x, at):
    """Adds x into buf at sample `at`, wrapping around the loop end."""
    n = len(buf)
    at %= n
    end = at + len(x)
    if end <= n:
        buf[at:end] += x
    else:
        k = n - at
        buf[at:] += x[:k]
        rest = x[k:]
        while len(rest):
            m = min(len(rest), n)
            buf[:m] += rest[:m]
            rest = rest[m:]


def loop_tone(freq, n, sr=MSR, kind="sine"):
    """A tone whose frequency is snapped so it completes whole cycles in the loop."""
    cycles = max(1, round(freq * n / sr))
    ph = 2 * np.pi * cycles * np.arange(n) / n
    if kind == "saw":
        return 2.0 * ((cycles * np.arange(n) / n) % 1.0) - 1.0
    return np.sin(ph)


def slow_lfo(n, cycles, phase=0.0):
    return 0.5 + 0.5 * np.sin(2 * np.pi * cycles * np.arange(n) / n + phase)


def loop_noise(n, sr=MSR, lo=None, hi=None, seed=1):
    """Filtered noise that loops: filter a 2x buffer, keep the steady-state middle, crossfade."""
    r = np.random.default_rng(seed)
    x = r.standard_normal(n * 3)
    if lo and hi:
        x = bandpass(x, lo, hi, sr)
    elif hi:
        x = lowpass(x, hi, sr)
    y = x[n: 2 * n].copy()
    # crossfade the tail of the previous block into the start for continuity
    k = sr // 2
    y[:k] = y[:k] * np.linspace(0, 1, k) + x[2 * n: 2 * n + k] * np.linspace(1, 0, k)
    return y


def music_menu():
    sr, dur = MSR, 48.0
    n = int(sr * dur)
    out = np.zeros(n)
    # Drone: D2 + A2, slow swell
    out += loop_tone(73.4, n) * 0.25 * (0.6 + 0.4 * slow_lfo(n, 2))
    out += loop_tone(110.0, n) * 0.15 * (0.5 + 0.5 * slow_lfo(n, 3, 1.0))
    out += lowpass(loop_tone(146.8, n, kind="saw"), 400, sr) * 0.05 * slow_lfo(n, 1, 2.0)
    out += loop_noise(n, sr, hi=700, seed=11) * 0.05 * (0.5 + 0.5 * slow_lfo(n, 4))
    # Bell motif: D minor, sparse
    motif = [(0, 293.7), (4, 349.2), (8, 440.0), (12, 392.0), (16, 349.2), (20, 293.7), (26, 220.0), (32, 293.7), (36, 349.2), (40, 466.2), (44, 440.0)]
    for i, (beat, f) in enumerate(motif):
        b = bell(f, 4.0, sr=sr, decay=2.2, seed=40 + i) * 0.18
        place(out, b, int(beat * sr))
    out = circular_reverb(out, 0.35, 3.5, 1.2, sr)
    write(os.path.join(MUS_DIR, "menu.wav"), out, sr, 0.7, do_fade=False)


def music_yard():
    sr, dur = MSR, 60.0
    n = int(sr * dur)
    out = np.zeros(n)
    wind = loop_noise(n, sr, lo=150, hi=900, seed=21) * (0.3 + 0.7 * slow_lfo(n, 3)) * 0.18
    gust = loop_noise(n, sr, lo=600, hi=2400, seed=22) * slow_lfo(n, 5, 1.3) ** 3 * 0.06
    out += wind + gust
    out += loop_tone(55.0, n) * 0.08 * slow_lfo(n, 2, 0.4)
    out += loop_tone(82.4, n) * 0.05 * slow_lfo(n, 3, 2.2)
    for i, (sec, f) in enumerate([(5, 196.0), (21, 174.6), (38, 196.0), (51, 146.8)]):
        place(out, bell(f, 6.0, sr=sr, decay=3.0, cracked=0.3, seed=60 + i) * 0.12, int(sec * sr))
    out = circular_reverb(out, 0.4, 3.5, 1.4, sr)
    write(os.path.join(MUS_DIR, "yard.wav"), out, sr, 0.55, do_fade=False)


def music_village():
    sr, dur = MSR, 64.0
    n = int(sr * dur)
    out = np.zeros(n)
    out += loop_noise(n, sr, lo=120, hi=700, seed=31) * (0.3 + 0.7 * slow_lfo(n, 4, 0.7)) * 0.14
    # Cold choir-like pad: detuned saws, A minor -> F -> G -> E, each 16 s.
    chords = [[110.0, 130.8, 164.8], [87.3, 110.0, 130.8], [98.0, 123.5, 146.8], [82.4, 103.8, 123.5]]
    seg = n // 4
    for i, ch in enumerate(chords):
        x = np.zeros(seg)
        tt = np.arange(seg) / sr
        for f in ch:
            for dt in (0.996, 1.0, 1.005):
                x += signal.sawtooth(2 * np.pi * f * 2 * dt * tt)
        x = lowpass(x, 700, sr) / 9.0
        a = np.minimum(1, tt / 3.0) * np.minimum(1, (seg / sr - tt) / 3.0)
        place(out, x * a * 0.22, i * seg)
    for i, (sec, f) in enumerate([(2, 220.0), (18, 174.6), (34, 196.0), (50, 164.8), (58, 220.0)]):
        place(out, bell(f, 6.0, sr=sr, decay=3.2, cracked=0.2, seed=80 + i) * 0.13, int(sec * sr))
    out = circular_reverb(out, 0.45, 4.0, 1.6, sr)
    write(os.path.join(MUS_DIR, "village.wav"), out, sr, 0.55, do_fade=False)


def music_boss():
    sr = MSR
    bpm = 120.0
    beat = 60.0 / bpm
    bars = 16
    n = int(round(bars * 4 * beat * sr))
    out = np.zeros(n)
    bs = int(round(beat * sr))

    def kick():
        d = 0.35
        t = t_axis(d, sr)
        return np.sin(2 * np.pi * np.cumsum(45 + 90 * np.exp(-t / 0.04)) / sr) * np.exp(-t / 0.12)

    def tom(f):
        d = 0.3
        t = t_axis(d, sr)
        return np.sin(2 * np.pi * np.cumsum(f + 40 * np.exp(-t / 0.03)) / sr) * np.exp(-t / 0.09) * 0.6 + \
            lowpass(np.random.default_rng(int(f)).standard_normal(len(t)), 2000, sr) * np.exp(-t / 0.02) * 0.2

    def string_note(f, d):
        t = t_axis(d, sr)
        x = sum(signal.sawtooth(2 * np.pi * f * dt * t) for dt in (0.997, 1.0, 1.004)) / 3
        x = lowpass(x, 900, sr)
        return x * np.minimum(1, t / 0.02) * np.exp(-t / (d * 0.8))

    def pad(freqs, d):
        t = t_axis(d, sr)
        x = sum(signal.sawtooth(2 * np.pi * f * dt * t) for f in freqs for dt in (0.995, 1.005))
        x = lowpass(x, 1200, sr) / (len(freqs) * 2)
        a = np.minimum(1, t / 0.6) * np.minimum(1, (d - t) / 0.4)
        return x * a

    chords = [[146.8, 174.6, 220.0], [116.5, 146.8, 174.6], [130.8, 164.8, 196.0], [110.0, 138.6, 164.8]]  # Dm Bb C A
    roots = [73.4, 58.3, 65.4, 55.0]
    ost = [0, 0, 3, 0, 2, 0, 3, 5]   # semitone offsets of the 8th-note ostinato
    for bar in range(bars):
        start = bar * 4 * bs
        ci = (bar // 2) % 4
        if bar % 2 == 0:
            place(out, pad(chords[ci], 8 * beat) * 0.22, start)
        for b8 in range(8):
            f = roots[ci] * 2 ** (ost[b8] / 12.0)
            place(out, string_note(f * 2, beat / 2 * 0.95) * 0.25, start + b8 * bs // 2)
        for k in [0, 2]:
            place(out, kick() * 0.9, start + k * bs)
        place(out, kick() * 0.6, start + int(3.5 * bs))
        for k in range(8):
            if k % 2 == 1 or bar % 4 == 3:
                place(out, tom(110 if k % 4 == 1 else 90) * 0.35, start + k * bs // 2)
        if bar % 4 == 0:
            place(out, bell(98.0, 5.0, sr=sr, decay=2.5, cracked=0.6, seed=70 + bar) * 0.3, start)
    out = circular_reverb(out, 0.25, 2.5, 0.8, sr)
    write(os.path.join(MUS_DIR, "boss.wav"), np.tanh(out * 1.2), sr, 0.8, do_fade=False)


if __name__ == "__main__":
    make_sfx()
    music_menu()
    music_yard()
    music_village()
    music_boss()
    for d in (SFX_DIR, MUS_DIR):
        for f in sorted(os.listdir(d)):
            p = os.path.join(d, f)
            print("%-40s %7.1f KB" % (os.path.relpath(p, ROOT), os.path.getsize(p) / 1024))
