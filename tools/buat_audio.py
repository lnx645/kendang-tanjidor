#!/usr/bin/env python3
"""Generator audio Kendang Tanjidor — semua suara disintesis (tanpa rekaman berhak cipta).
Output: audio/*.wav (efek + 3 lagu pengiring) dan data/laguN.json (peta not kendang).
"""
import json, math, os
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
DATA = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(OUT, exist_ok=True)
os.makedirs(DATA, exist_ok=True)

def simpan(nama, data):
    data = np.clip(data, -1, 1)
    pcm = (data * 32767 * 0.9).astype(np.int16)
    import wave
    with wave.open(os.path.join(OUT, nama), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(nama, f"{len(data)/SR:.2f}s")

def t(detik):
    return np.arange(int(detik * SR)) / SR

def bunyi_kendang(f0, f1, dur, keras=1.0, klik=0.5):
    """Membran kendang: nada meluncur turun + klik awal + partial."""
    tt = t(dur)
    f = f1 + (f0 - f1) * np.exp(-tt * 22)
    fase = np.cumsum(f) / SR * 2 * np.pi
    env = np.exp(-tt * (3.2 / dur * 2.2))
    y = np.sin(fase) * env
    y += 0.35 * np.sin(fase * 2.76) * np.exp(-tt * 26)
    noise = np.random.default_rng(7).normal(0, 1, len(tt))
    y += klik * noise * np.exp(-tt * 90) * 0.6
    return y * keras

def kecrek(dur=0.05, keras=0.5):
    tt = t(dur)
    noise = np.random.default_rng(3).normal(0, 1, len(tt))
    # highpass kasar: kurangi rata-rata bergerak
    hp = noise - np.convolve(noise, np.ones(24) / 24, mode="same")
    return hp * np.exp(-tt * 60) * keras

def gong(dur=2.4, keras=0.8):
    tt = t(dur)
    y = np.zeros_like(tt)
    for rasio, amp in [(1, 1), (1.5, 0.55), (2.24, 0.4), (2.93, 0.26), (3.91, 0.15)]:
        y += amp * np.sin(2 * np.pi * 94 * rasio * tt) * np.exp(-tt * (1.1 + rasio * 0.35))
    y *= 1 + 0.12 * np.sin(2 * np.pi * 4.5 * tt) * np.exp(-tt * 1.5)
    return y * keras

def pak(dur=0.09, keras=0.9):
    tt = t(dur)
    noise = np.random.default_rng(11).normal(0, 1, len(tt))
    bp = np.convolve(noise, np.ones(6) / 6, mode="same") - np.convolve(noise, np.ones(60) / 60, mode="same")
    return (bp * 3 * np.exp(-tt * 55) + 0.7 * np.sin(2 * np.pi * 290 * tt) * np.exp(-tt * 48)) * keras

def nada_kuningan(midi, dur, keras=0.5, tuba=False):
    """Timbre kuningan sederhana: tumpukan harmonik + amplop tiup."""
    f = 440 * 2 ** ((midi - 69) / 12)
    tt = t(dur)
    harm = [(1, 1.0), (2, 0.55), (3, 0.32), (4, 0.18), (5, 0.09)] if not tuba else [(1, 1.0), (2, 0.5), (3, 0.14)]
    y = np.zeros_like(tt)
    for h, a in harm:
        y += a * np.sin(2 * np.pi * f * h * tt + 0.0)
    serang = np.minimum(tt / 0.03, 1)
    lepas = np.exp(-np.maximum(tt - dur * 0.75, 0) * 14)
    bergetar = 1 + 0.008 * np.sin(2 * np.pi * 5.2 * tt)
    return y * serang * lepas * bergetar * keras / 2.1

def ding(freq=1180, dur=0.12, keras=0.5):
    tt = t(dur)
    return (np.sin(2 * np.pi * freq * tt) + 0.5 * np.sin(2 * np.pi * freq * 1.5 * tt)) * np.exp(-tt * 30) * keras

# ===== EFEK =====
simpan("dang.wav", bunyi_kendang(165, 74, 0.42, 1.0, 0.5))
simpan("tak.wav", bunyi_kendang(430, 235, 0.2, 0.9, 0.7))
simpan("pak.wav", pak())
simpan("kecrek.wav", kecrek())
simpan("gong.wav", gong())
simpan("benar.wav", ding(1180))
simpan("hebat.wav", ding(1560, 0.18, 0.55))
simpan("salah.wav", (np.sign(np.sin(2 * np.pi * 130 * t(0.16))) * 0.4 + np.sin(2 * np.pi * 65 * t(0.16)) * 0.4) * np.exp(-t(0.16) * 10))

# ===== LAGU =====
# Progresi akor per 8 bar (diulang 2x = 16 bar per lagu)
AKOR = ["C", "F", "C", "G", "C", "F", "G", "C"]
BAS = {"C": 36, "F": 41, "G": 43}       # midi akar tuba (C2=36)
TEROMPET = {"C": [60, 64, 67, 72], "F": [65, 69, 72, 77], "G": [67, 71, 74, 79]}

def buat_lagu(nomor, bpm, melodi_bars, pola_kendang_bars, judul):
    spb = 60.0 / bpm            # detik per ketuk
    total_kur = 16 * 4          # 16 bar x 4 ketuk
    total_detik = total_kur * spb + 2.5
    trek = np.zeros(int(total_detik * SR))
    def taruh(sinyal, mulai_detik, gain=1.0):
        i = int(mulai_detik * SR)
        j = min(i + len(sinyal), len(trek))
        trek[i:j] += sinyal[: j - i] * gain
    gong_s = gong(2.2, 0.5)
    kecrek_s = kecrek(0.05, 0.30)
    for bar in range(16):
        akor = AKOR[bar % 8]
        dasar = bar * 4 * spb
        # Gong di awal tiap 4 bar
        if bar % 4 == 0:
            taruh(gong_s, dasar)
        # Tuba: ketuk 1 & 3 (dan 4 untuk variasi)
        for ketuk, panjang in [(0, 1.6), (2, 1.2), (3, 0.7)]:
            taruh(nada_kuningan(BAS[akor], panjang * spb, 0.62, tuba=True), dasar + ketuk * spb)
        # Kecrek: delapanan — pemelihara tempo
        for d in range(8):
            taruh(kecrek_s, dasar + d * 0.5 * spb, 0.75 if d % 2 == 0 else 0.5)
        # Melodi terompet bar ini
        for (ketuk, midi, panjang) in melodi_bars[bar % len(melodi_bars)]:
            taruh(nada_kuningan(midi, panjang * spb * 0.96, 0.5), dasar + ketuk * spb)
    simpan(f"lagu{nomor}.wav", trek * 0.85)
    # Peta not kendang untuk dimainkan
    nots = []
    for bar in range(16):
        for (ketuk, sisi) in pola_kendang_bars[bar % len(pola_kendang_bars)]:
            nots.append({"b": round(bar * 4 + ketuk, 2), "s": sisi})
    with open(os.path.join(DATA, f"lagu{nomor}.json"), "w") as f:
        json.dump({"judul": judul, "bpm": bpm, "durasi_ketuk": total_kur, "notes": nots}, f, indent=1)
    print(f"lagu{nomor}.json: {len(nots)} not @ {bpm}bpm")

# Lagu 1 — Jali Pagi (100bpm) melodi sederhana
m1 = [
    [(0, 72, 1), (1, 71, 1), (2, 67, 1), (3, 69, 1)],
    [(0, 72, 2), (2, 76, 1), (3, 74, 1)],
    [(0, 69, 1), (1, 72, 1), (2, 74, 1), (3, 76, 1)],
    [(0, 79, 2), (2, 76, 1), (3, 74, 1)],
    [(0, 72, 1), (1, 71, 1), (2, 67, 1), (3, 69, 1)],
    [(0, 72, 2), (2, 69, 1), (3, 65, 1)],
    [(0, 67, 1), (1, 69, 1), (2, 71, 1), (3, 74, 1)],
    [(0, 72, 4)],
]
# Pola kendang dasar tanjidor (0=DANG, 1=TAK)
p1 = [
    [(0, 0), (1, 1), (2, 0), (3, 1)],
    [(0, 0), (1, 1), (2, 0), (2.5, 1), (3, 1)],
    [(0, 0), (1, 1), (1.5, 1), (2, 0), (3, 1)],
    [(0, 0), (1, 1), (2, 0), (3, 1), (3.5, 1)],
]
buat_lagu(1, 100, m1, p1, "Jali Pagi")

# Lagu 2 — Ondel Lewat (118bpm) lebih rapat
m2 = [
    [(0, 76, 0.5), (0.5, 74, 0.5), (1, 72, 1), (2, 74, 1), (3, 76, 1)],
    [(0, 81, 1.5), (1.5, 79, 0.5), (2, 76, 1), (3, 74, 1)],
    [(0, 72, 1), (1, 74, 1), (2, 77, 1.5), (3.5, 76, 0.5)],
    [(0, 79, 1), (1, 76, 1), (2, 74, 1), (3, 71, 1)],
    [(0, 76, 0.5), (0.5, 74, 0.5), (1, 72, 1), (2, 74, 1), (3, 79, 1)],
    [(0, 81, 2), (2, 79, 1), (3, 76, 1)],
    [(0, 77, 1), (1, 79, 1), (2, 81, 1), (3, 79, 1)],
    [(0, 76, 3), (3, 74, 1)],
]
p2 = [
    [(0, 0), (0.5, 1), (1, 1), (2, 0), (2.5, 1), (3, 1)],
    [(0, 0), (1, 1), (1.5, 1), (2, 0), (3, 1), (3.5, 0)],
    [(0, 0), (0.5, 1), (1, 0), (2, 1), (2.5, 0), (3, 1)],
    [(0, 0), (1, 1), (2, 0), (2.5, 1), (3, 0), (3.5, 1)],
]
buat_lagu(2, 118, m2, p2, "Ondel Lewat")

# Lagu 3 — Tanjidor Ngebut (136bpm) rapat & tinggi
m3 = [
    [(0, 79, 0.5), (0.5, 81, 0.5), (1, 84, 1), (2, 81, 0.5), (2.5, 79, 0.5), (3, 76, 1)],
    [(0, 77, 1), (1, 81, 1), (2, 84, 1.5), (3.5, 81, 0.5)],
    [(0, 83, 0.5), (0.5, 81, 0.5), (1, 79, 1), (2, 76, 1), (3, 74, 1)],
    [(0, 79, 1), (1, 76, 1), (2, 79, 2)],
    [(0, 79, 0.5), (0.5, 81, 0.5), (1, 84, 1), (2, 86, 1), (3, 84, 1)],
    [(0, 81, 1.5), (1.5, 79, 0.5), (2, 77, 1), (3, 79, 1)],
    [(0, 81, 0.5), (0.5, 79, 0.5), (1, 77, 0.5), (1.5, 76, 0.5), (2, 79, 1), (3, 81, 1)],
    [(0, 84, 4)],
]
p3 = [
    [(0, 0), (0.5, 1), (1, 1), (1.5, 1), (2, 0), (2.5, 1), (3, 1), (3.5, 0)],
    [(0, 0), (0.5, 0), (1, 1), (1.5, 1), (2, 0), (3, 1), (3.5, 1)],
    [(0, 1), (0.5, 0), (1, 1), (2, 0), (2.5, 1), (3, 0), (3.5, 1)],
    [(0, 0), (1, 1), (1.5, 0), (2, 1), (2.5, 1), (3, 0), (3.5, 1)],
]
buat_lagu(3, 136, m3, p3, "Tanjidor Ngebut")
print("SELESAI")
