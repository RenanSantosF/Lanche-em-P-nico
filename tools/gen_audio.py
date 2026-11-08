#!/usr/bin/env python3
"""Gera todos os sons e músicas do jogo (WAV mono 22050 Hz).

Rodar: python3 tools/gen_audio.py
Os arquivos vão para audio/ e ft_intro/ e são versionados, então o celular
não precisa sintetizar nada em tempo real (bom para aparelhos fracos).
"""
import os
import wave
import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(7)


def T(d):
    return np.arange(int(SR * d)) / SR


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def fade(x, a=0.004, r=0.02):
    n = len(x)
    e = np.ones(n)
    na = min(n, int(a * SR))
    nr = min(n, int(r * SR))
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[n - nr:] *= np.linspace(1, 0, nr)
    return x * e


def lowpass(x, cutoff):
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def comb(x, delay, g):
    y = x.copy()
    for k in range(delay, len(y), delay):
        end = min(k + delay, len(y))
        y[k:end] += g * y[k - delay:end - delay]
    return y


def reverb(x, mix=0.25, size=1.0, tail=1.2):
    x = np.concatenate([x, np.zeros(int(tail * SR))])
    wet = np.zeros_like(x)
    for d, g in [(1116, 0.78), (1188, 0.76), (1277, 0.74), (1356, 0.72)]:
        wet += comb(lowpass(x, 5000), int(d * size * SR / 44100), g)
    wet /= 4.0
    return x * (1 - mix) + wet * mix


def place(buf, x, t):
    i = int(t * SR)
    end = min(len(buf), i + len(x))
    if end > i:
        buf[i:end] += x[: end - i]


def bell(f, d, decay=4.0, bright=1.0):
    t = T(d)
    parts = [(1.0, 1.0), (2.0, 0.45 * bright), (3.01, 0.22 * bright), (4.17, 0.12 * bright), (5.43, 0.06 * bright)]
    y = sum(a * np.sin(2 * np.pi * f * p * t) * np.exp(-decay * p ** 0.6 * t) for p, a in parts)
    return fade(y, 0.002, 0.01)


def ep(f, d, vel=1.0):
    """Piano elétrico (FM suave)."""
    t = T(d)
    idx = 1.6 * np.exp(-t * 6.0) + 0.25
    y = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t)) * np.exp(-t * 1.6)
    y += 0.25 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 4)
    return fade(y * vel, 0.003, 0.08)


def marimba(f, d):
    t = T(d)
    y = np.sin(2 * np.pi * f * t) * np.exp(-t * 5.0) + 0.35 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 22.0)
    return fade(y, 0.001, 0.03)


def bass(f, d):
    t = T(d)
    y = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 6)
    y *= np.exp(-t * 2.2)
    return fade(y, 0.004, 0.05)


def sweep(f0, f1, d, wave_fn=np.sin, curve=1.0):
    t = T(d)
    k = (t / d) ** curve
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / SR
    return wave_fn(ph)


def noise(d):
    return rng.standard_normal(int(SR * d))


def env_exp(d, k):
    return np.exp(-T(d) * k)


def save(path, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) if len(x) else 1.0
    if m > 0:
        x = x / m * peak
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with wave.open(full, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print("ok", path, round(len(x) / SR, 2), "s")


# ---------------------------------------------------------------- efeitos
def sfx():
    # pop: "blup" macio de ingrediente caindo
    d = 0.12
    x = sweep(820, 260, d, curve=0.5) * env_exp(d, 30)
    x += 0.15 * lowpass(noise(d), 2500) * env_exp(d, 80)
    save("audio/pop.wav", fade(x), 0.7)

    # bun: "tuf" fofinho de pão
    d = 0.16
    x = sweep(240, 90, d, curve=0.4) * env_exp(d, 22)
    x += 0.5 * lowpass(noise(d), 900) * env_exp(d, 35)
    save("audio/bun.wav", fade(x), 0.75)

    # click de interface
    d = 0.05
    x = np.sin(2 * np.pi * 1500 * T(d)) * env_exp(d, 90) + 0.3 * np.sin(2 * np.pi * 3000 * T(d)) * env_exp(d, 140)
    save("audio/click.wav", fade(x), 0.45)

    # sizzle: carne caindo na chapa
    d = 0.6
    n = highpass(noise(d), 2500)
    crack = np.zeros(int(SR * d))
    for _ in range(40):
        place(crack, highpass(noise(0.004), 3000), rng.uniform(0, d - 0.01))
    x = (n * 0.6 + crack * 0.8) * (0.3 + 0.7 * env_exp(d, 4))
    save("audio/sizzle.wav", fade(x, 0.01, 0.15), 0.5)

    # grill_loop: chiado contínuo da chapa (loop de 2s)
    d = 2.0
    n = highpass(lowpass(noise(d), 9000), 2200) * 0.5
    crack = np.zeros(int(SR * d))
    for _ in range(120):
        place(crack, highpass(noise(0.003), 3500) * rng.uniform(0.3, 1.0), rng.uniform(0, d - 0.01))
    x = n + crack * 0.7
    # costura do loop: crossfade com o começo
    cf = int(0.1 * SR)
    x[:cf] = x[:cf] * np.linspace(0, 1, cf) + x[-cf:] * np.linspace(1, 0, cf)
    x = x[: len(x) - cf]
    save("audio/grill_loop.wav", x, 0.35)

    # ready: carne pronta "plim"
    x = bell(1568, 0.6, 5) * 0.6 + bell(2349, 0.6, 6) * 0.4
    save("audio/ready.wav", reverb(x, 0.2, 0.6, 0.4), 0.6)

    # burnt: fumaça + tom triste
    d = 0.7
    x = highpass(noise(d), 1500) * env_exp(d, 4) * 0.5
    x += 0.5 * sweep(330, 220, d) * env_exp(d, 3)
    save("audio/burnt.wav", fade(x, 0.01, 0.1), 0.55)

    # trash: whoosh + lata
    d = 0.35
    nn = noise(d)
    x = lowpass(nn, 1200) * np.sin(np.linspace(0, np.pi, len(nn))) * 0.8
    can = bell(620, 0.3, 14, 1.4) * 0.35
    place(x, can, 0.18)
    save("audio/trash.wav", fade(x), 0.6)

    # bell: sininho da porta (cliente chegando)
    x = np.zeros(int(SR * 1.0))
    place(x, bell(1319, 0.9, 4.5), 0.0)
    place(x, bell(1568, 0.8, 4.5) * 0.8, 0.09)
    save("audio/bell.wav", reverb(x, 0.25, 0.7, 0.4), 0.55)

    # coin: tilintar de moeda
    x = np.zeros(int(SR * 0.6))
    place(x, bell(1976, 0.45, 8, 0.6), 0)
    place(x, bell(2637, 0.5, 7, 0.6), 0.06)
    save("audio/coin.wav", reverb(x, 0.15, 0.5, 0.3), 0.55)

    # good: duas notas alegres
    x = np.zeros(int(SR * 0.8))
    place(x, marimba(midi(76), 0.5), 0)
    place(x, marimba(midi(83), 0.6), 0.09)
    save("audio/good.wav", reverb(x, 0.2, 0.6, 0.4), 0.7)

    # perfect: arpejo brilhante + brilho
    x = np.zeros(int(SR * 1.3))
    for i, m in enumerate([72, 76, 79, 84]):
        place(x, marimba(midi(m), 0.6) * 0.8, i * 0.06)
        place(x, bell(midi(m + 12), 0.8, 5) * 0.25, i * 0.06)
    for i in range(6):
        place(x, bell(rng.uniform(3000, 5000), 0.3, 12) * 0.12, 0.3 + i * 0.05)
    save("audio/perfect.wav", reverb(x, 0.3, 0.8, 0.6), 0.75)

    # bad: "uóóón" fofo
    d = 0.55
    t = T(d)
    f = 300 - 120 * (t / d) + 8 * np.sin(2 * np.pi * 7 * t)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR)
    x += 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    x = lowpass(x * (1 - t / d) ** 1.2, 1800)
    save("audio/bad.wav", fade(x, 0.02, 0.08), 0.5)

    # angry: "hmpf" (cliente impaciente)
    d = 0.25
    x = lowpass(noise(d), 700) * env_exp(d, 14) * 0.8 + 0.4 * sweep(180, 110, d) * env_exp(d, 10)
    save("audio/angry.wav", fade(x), 0.5)

    # nope: dois toques graves suaves
    x = np.zeros(int(SR * 0.3))
    place(x, sweep(330, 300, 0.1) * env_exp(0.1, 25), 0)
    place(x, sweep(260, 240, 0.12) * env_exp(0.12, 22), 0.11)
    save("audio/nope.wav", fade(x), 0.45)

    # buy: caixa registradora
    x = np.zeros(int(SR * 1.0))
    place(x, lowpass(noise(0.08), 3000) * env_exp(0.08, 40) * 0.5, 0)
    place(x, bell(2093, 0.8, 4, 0.8), 0.07)
    place(x, bell(2637, 0.8, 4, 0.8) * 0.8, 0.13)
    place(x, bell(3136, 0.9, 3.5, 0.8) * 0.7, 0.19)
    save("audio/buy.wav", reverb(x, 0.2, 0.7, 0.4), 0.65)

    # fanfare: abrindo o dia
    x = np.zeros(int(SR * 1.4))
    for i, (m, dt) in enumerate([(67, 0), (72, 0.12), (76, 0.24), (79, 0.36)]):
        place(x, marimba(midi(m), 0.5), dt)
    for m in [72, 76, 79, 84]:
        place(x, ep(midi(m), 1.0, 0.5), 0.5)
    save("audio/fanfare.wav", reverb(x, 0.25, 0.8, 0.6), 0.75)

    # levelup: subir de nível
    x = np.zeros(int(SR * 2.0))
    seq = [60, 64, 67, 72, 76, 79, 84]
    for i, m in enumerate(seq):
        place(x, marimba(midi(m), 0.5) * 0.7, i * 0.07)
        place(x, bell(midi(m + 12), 0.6, 6) * 0.2, i * 0.07)
    for m in [72, 76, 79, 83, 86]:
        place(x, ep(midi(m), 1.4, 0.45), 0.55)
    for i in range(10):
        place(x, bell(rng.uniform(3000, 6000), 0.3, 10) * 0.1, 0.6 + i * 0.07)
    save("audio/levelup.wav", reverb(x, 0.3, 0.9, 0.8), 0.8)

    # rush: apito animado subindo
    d = 0.7
    t = T(d)
    f = 600 + 900 * (t / d) ** 1.5 + 25 * np.sin(2 * np.pi * 18 * t)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 0.5
    save("audio/rush.wav", fade(x, 0.01, 0.05), 0.5)

    # combo: plim curto (o jogo sobe o tom a cada combo)
    x = marimba(midi(84), 0.4) + bell(midi(96), 0.4, 8) * 0.3
    save("audio/combo.wav", fade(x), 0.6)

    # fries_ready: "plim plim" da fritadeira
    x = np.zeros(int(SR * 0.7))
    place(x, bell(1760, 0.4, 7), 0)
    place(x, bell(1760, 0.5, 6), 0.12)
    save("audio/fries_ready.wav", reverb(x, 0.15, 0.5, 0.3), 0.5)

    # fry: batata entrando no óleo
    d = 0.8
    x = highpass(noise(d), 1800) * (0.4 + 0.6 * env_exp(d, 5))
    bub = np.zeros(int(SR * d))
    for _ in range(25):
        place(bub, sweep(rng.uniform(500, 900), rng.uniform(900, 1400), 0.03) * env_exp(0.03, 80), rng.uniform(0, d - 0.04))
    save("audio/fry.wav", fade(x * 0.5 + bub * 0.6, 0.01, 0.2), 0.5)

    # pour: refri enchendo
    d = 0.9
    x = lowpass(noise(d), 1500) * 0.4
    bub = np.zeros(int(SR * d))
    for i in range(30):
        f0 = 400 + i * 25
        place(bub, sweep(f0, f0 * 1.6, 0.035) * env_exp(0.035, 60), i * 0.028 + rng.uniform(0, 0.01))
    save("audio/pour.wav", fade(x + bub * 0.7, 0.02, 0.15), 0.5)


# ---------------------------------------------------------------- música
def music(path, bpm=96, transpose=0, bars_mel=None):
    beat = 60.0 / bpm
    e = beat / 2
    bars = 8
    total = bars * 4 * beat
    buf_ep = np.zeros(int(SR * (total + 3)))
    buf_mel = np.zeros_like(buf_ep)
    buf_bass = np.zeros_like(buf_ep)
    buf_dr = np.zeros_like(buf_ep)
    chords = [
        [60, 64, 67, 71], [57, 60, 64, 67], [62, 65, 69, 72], [55, 59, 62, 65],
        [60, 64, 67, 71], [57, 60, 64, 67], [62, 65, 69, 72], [55, 59, 62, 65],
    ]
    roots = [36, 33, 38, 31, 36, 33, 38, 31]
    mel = bars_mel or [
        [(0, 76, 3), (3, 79, 1), (4, 81, 2), (6, 79, 2)],
        [(0, 76, 2), (2, 72, 2), (4, 74, 4)],
        [(0, 77, 3), (3, 76, 1), (4, 74, 2), (6, 72, 2)],
        [(0, 71, 2), (2, 74, 2), (4, 79, 4)],
        [(0, 79, 3), (3, 81, 1), (4, 84, 2), (6, 83, 2)],
        [(0, 81, 2), (2, 79, 2), (4, 76, 4)],
        [(0, 77, 2), (2, 81, 2), (4, 79, 2), (6, 77, 2)],
        [(0, 74, 3), (3, 71, 1), (4, 67, 4)],
    ]
    comp = [(0, 2, 0.9), (3, 1, 0.6), (6, 2, 0.7)]
    for b in range(bars):
        t0 = b * 4 * beat
        for pos, ln, vel in comp:
            for m in chords[b]:
                place(buf_ep, ep(midi(m + transpose), ln * e + 0.25, vel * 0.5), t0 + pos * e)
        r = roots[b] + transpose
        place(buf_bass, bass(midi(r), beat * 1.4), t0)
        place(buf_bass, bass(midi(r + 7), beat * 0.9) * 0.8, t0 + 3 * e)
        place(buf_bass, bass(midi(r), beat * 1.4) * 0.9, t0 + 4 * e)
        place(buf_bass, bass(midi(r + 7), beat * 0.9) * 0.7, t0 + 7 * e)
        for pos, m, ln in mel[b]:
            place(buf_mel, marimba(midi(m + transpose), ln * e + 0.3), t0 + pos * e)
        for k in range(8):
            sw = 0.02 if k % 2 == 1 else 0.0
            amp = 0.5 if k % 2 == 0 else 0.3
            place(buf_dr, highpass(noise(0.05), 6000) * env_exp(0.05, 70) * amp, t0 + k * e + sw)
        kick = sweep(110, 45, 0.18, curve=0.4) * env_exp(0.18, 18)
        place(buf_dr, kick * 1.2, t0)
        place(buf_dr, kick * 0.9, t0 + 4 * e)
    mix = buf_ep * 0.28 + buf_mel * 0.32
    mix = reverb(mix, 0.22, 0.9, 0.0)
    mix = mix + buf_bass * 0.42 + buf_dr * 0.16
    mix = lowpass(mix, 7000)
    n = int(total * SR)
    tail = mix[n:]
    loop = mix[:n].copy()
    loop[: len(tail)] += tail[: len(loop)]
    save(path, loop, 0.8)


def ft_jingle():
    d = 3.2
    x = np.zeros(int(SR * d))
    # whoosh subindo enquanto o logo se desenha
    w = noise(0.9)
    w = highpass(lowpass(w, 4000), 400) * np.linspace(0, 1, len(w)) ** 2
    place(x, w * 0.35, 0.05)
    place(x, sweep(200, 1200, 0.9, curve=2.0) * np.linspace(0, 1, int(SR * 0.9)) ** 2 * 0.15, 0.05)
    # impacto suave + acorde brilhante (Cmaj9)
    hit = sweep(120, 40, 0.4, curve=0.4) * env_exp(0.4, 9)
    place(x, hit * 0.9, 0.95)
    for i, m in enumerate([60, 67, 71, 74, 76, 79]):
        place(x, bell(midi(m + 12), 2.0, 2.2, 0.7) * 0.35, 0.95 + i * 0.035)
        place(x, ep(midi(m), 2.0, 0.35), 0.95 + i * 0.035)
    # pad
    t = T(2.0)
    pad = sum(np.sin(2 * np.pi * midi(m) * (1 + det) * t) for m in [48, 55, 64, 71] for det in (-0.003, 0.003))
    pad = lowpass(pad, 1500) * np.minimum(1, t / 0.3) * np.exp(-t * 1.3) * 0.12
    place(x, pad, 0.95)
    # brilhinhos
    for i in range(12):
        place(x, bell(rng.uniform(3500, 7000), 0.4, 9) * 0.08, 1.05 + i * 0.06)
    save("ft_intro/ft_jingle.wav", fade(reverb(x, 0.3, 1.0, 0.6), 0.002, 0.4), 0.85)


if __name__ == "__main__":
    sfx()
    music("audio/music.wav", bpm=96)
    ft_jingle()
