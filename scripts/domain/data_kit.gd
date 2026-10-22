class_name DataKit
extends RefCounted
## Data murni kit: definisi pad, tema (palet panggung), dan tata letak bawaan.
## Tidak ada logika UI di sini — hanya konstanta domain Kendang Bajidor.

const DAFTAR_TEMA := {
	"jati": {"nama": "Kayu Jati", "latar1": Color(0.13, 0.08, 0.05), "latar2": Color(0.05, 0.03, 0.02),
		"rim": Color(0.48, 0.29, 0.15), "rim_gelap": Color(0.28, 0.16, 0.08), "tali": Color(0.92, 0.80, 0.58),
		"kepala": Color(0.85, 0.63, 0.36), "kepala_terang": Color(0.98, 0.85, 0.60), "logam": Color(0.85, 0.66, 0.28)},
	"panggung": {"nama": "Hitam Panggung", "latar1": Color(0.07, 0.08, 0.10), "latar2": Color(0.02, 0.02, 0.03),
		"rim": Color(0.20, 0.21, 0.25), "rim_gelap": Color(0.09, 0.09, 0.11), "tali": Color(0.55, 0.58, 0.65),
		"kepala": Color(0.24, 0.25, 0.29), "kepala_terang": Color(0.38, 0.40, 0.46), "logam": Color(0.62, 0.55, 0.35)},
	"merah": {"nama": "Merah Ukir", "latar1": Color(0.16, 0.06, 0.04), "latar2": Color(0.07, 0.02, 0.02),
		"rim": Color(0.55, 0.24, 0.13), "rim_gelap": Color(0.32, 0.13, 0.07), "tali": Color(0.95, 0.82, 0.60),
		"kepala": Color(0.90, 0.68, 0.40), "kepala_terang": Color(0.99, 0.87, 0.62), "logam": Color(0.88, 0.68, 0.30)},
	"sendiri": {"nama": "Latar Sendiri", "latar1": Color(0.13, 0.08, 0.05), "latar2": Color(0.05, 0.03, 0.02),
		"rim": Color(0.48, 0.29, 0.15), "rim_gelap": Color(0.28, 0.16, 0.08), "tali": Color(0.92, 0.80, 0.58),
		"kepala": Color(0.85, 0.63, 0.36), "kepala_terang": Color(0.98, 0.85, 0.60), "logam": Color(0.85, 0.66, 0.28)},
}

const DEF_PAD := [
	{"id": "kecrek", "nama": "KECREK", "bentuk": "kecrek", "suara": ["kecrek.wav", "kecrek_rapat.wav"]},
	{"id": "ketipung", "nama": "KETIPUNG", "bentuk": "drum", "suara": ["ketipung.wav", "ketipung_tinggi.wav"]},
	{"id": "kulanter", "nama": "KULANTER", "bentuk": "drum", "suara": ["ketipung_tinggi.wav", "tak_tajam.wav"]},
	{"id": "kempul", "nama": "KEMPUL", "bentuk": "gong", "suara": ["kempul.wav", "gong.wav"]},
	{"id": "gong", "nama": "GONG", "bentuk": "gong", "suara": ["gong.wav", "kempul.wav"]},
	{"id": "tak", "nama": "TAK", "bentuk": "drum", "suara": ["tak.wav", "tak_tajam.wav"]},
	{"id": "dang", "nama": "DANG", "bentuk": "drum", "suara": ["dang.wav", "dang_rendah.wav", "dang_kering.wav"]},
	{"id": "anak", "nama": "ANAK", "bentuk": "drum", "suara": ["ketipung.wav", "pak.wav", "dang_kering.wav"]},
	{"id": "pak", "nama": "PAK", "bentuk": "blok", "suara": ["pak.wav", "pak_lembut.wav"]},
]

const LETAK_BAWAAN := {
	"kecrek": [0.085, 0.260, 0.048, 0.086], "ketipung": [0.265, 0.235, 0.062, 0.111],
	"kulanter": [0.475, 0.225, 0.066, 0.117], "kempul": [0.685, 0.240, 0.064, 0.114],
	"gong": [0.895, 0.260, 0.077, 0.136], "tak": [0.155, 0.600, 0.084, 0.150],
	"dang": [0.455, 0.565, 0.119, 0.211], "anak": [0.755, 0.585, 0.087, 0.156],
	"pak": [0.475, 0.860, 0.058, 0.068],
}

const LETAK_RAPAT := {
	"kecrek": [0.200, 0.250, 0.048, 0.086], "ketipung": [0.360, 0.230, 0.062, 0.111],
	"kulanter": [0.530, 0.230, 0.066, 0.117], "kempul": [0.690, 0.240, 0.064, 0.114],
	"gong": [0.840, 0.260, 0.077, 0.136], "tak": [0.270, 0.580, 0.084, 0.150],
	"dang": [0.500, 0.555, 0.119, 0.211], "anak": [0.730, 0.580, 0.087, 0.156],
	"pak": [0.500, 0.860, 0.058, 0.068],
}

const PRESET_PABRIK := ["Panggung Klasik", "Rampak Rapat"]
