extends Node2D
## Kendang Virtual v2.1 — kit kendang virtual ala Real Drum (tampak atas).
## Pukul langsung multi-sentuh. Custom: tema kit, audio per pad, posisi pad,
## preset (simpan/muat/hapus), dan pemutar MP3 pengiring.

var LEBAR := 1280.0
var TINGGI := 720.0
var jari_pad := {}
const JALUR_SIMPAN := "user://pengaturan.cfg"
const JALUR_PRESET := "user://preset.cfg"

# Tema kit: palet warna pad & latar (pad digambar vektor berlapis)
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

# Tata letak kit bawaan (relatif): x, y, rx, ry (ry = rx * 1280/720 agar bulat)
const LETAK_BAWAAN := {
	"kecrek": [0.085, 0.260, 0.048, 0.086], "ketipung": [0.265, 0.235, 0.062, 0.111],
	"kulanter": [0.475, 0.225, 0.066, 0.117], "kempul": [0.685, 0.240, 0.064, 0.114],
	"gong": [0.895, 0.260, 0.077, 0.136], "tak": [0.155, 0.600, 0.084, 0.150],
	"dang": [0.455, 0.565, 0.119, 0.211], "anak": [0.755, 0.585, 0.087, 0.156],
	"pak": [0.475, 0.860, 0.058, 0.068],
}
# Preset pabrik kedua: kit rapat ke tengah
const LETAK_RAPAT := {
	"kecrek": [0.200, 0.250, 0.048, 0.086], "ketipung": [0.360, 0.230, 0.062, 0.111],
	"kulanter": [0.530, 0.230, 0.066, 0.117], "kempul": [0.690, 0.240, 0.064, 0.114],
	"gong": [0.840, 0.260, 0.077, 0.136], "tak": [0.270, 0.580, 0.084, 0.150],
	"dang": [0.500, 0.555, 0.119, 0.211], "anak": [0.730, 0.580, 0.087, 0.156],
	"pak": [0.500, 0.860, 0.058, 0.068],
}

var tema_ini := "jati"
var tekstur_latar: Texture2D = null
var berkas_latar_sendiri := ""
var pads: Array = []
var pemain: Array = []
var giliran_pemain := 0
var modus_atur := false
var pad_seret: Dictionary = {}
var pad_pilih: Dictionary = {}
var panel_terbuka := ""
var rng := RandomNumberGenerator.new()
var nama_preset_ini := ""

var lapis: CanvasLayer
var panel_tema: PanelContainer
var panel_suara: PanelContainer
var panel_preset: PanelContainer
var panel_mp3: PanelContainer
var panel_tentang: PanelContainer
var bar_atur: PanelContainer
var penggeser_ukuran: HSlider
var label_status: Label
var daftar_suara: VBoxContainer
var daftar_preset: VBoxContainer
var isian_nama_preset: LineEdit
var pemutar_musik: AudioStreamPlayer
var label_lagu: Label
var geser_posisi: HSlider
var label_waktu: Label
var cek_ulangi: CheckBox

func _ready() -> void:
	rng.randomize()
	siapkan_pemain()
	pemutar_musik = AudioStreamPlayer.new()
	pemutar_musik.bus = "Master"
	add_child(pemutar_musik)
	siapkan_pads()
	muat_pengaturan()
	terapkan_tema()
	bangun_ui()
	sesuaikan_ukuran()
	get_tree().root.size_changed.connect(sesuaikan_ukuran)
	Engine.max_fps = 120
	for pad in pads:
		pad["nada"] = muat_nada(pad)
	queue_redraw()

func sesuaikan_ukuran() -> void:
	var sz := get_viewport().get_visible_rect().size
	if sz.x > 100 and sz.y > 100:
		LEBAR = sz.x
		TINGGI = sz.y
	for p in [panel_tema, panel_preset, panel_suara, panel_mp3, panel_tentang]:
		if p:
			p.position = Vector2((LEBAR - 820) / 2, (TINGGI - 500) / 2)
	if bar_atur:
		bar_atur.position = Vector2((LEBAR - 900) / 2, TINGGI - 150)
	queue_redraw()

func siapkan_pemain() -> void:
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		pemain.append(p)

func siapkan_pads() -> void:
	pads.clear()
	for d in DEF_PAD:
		var def: Dictionary = d
		pads.append({
			"def": def, "x": 0.5, "y": 0.5, "rx": 0.06, "ry": 0.1, "skala": 1.0,
			"kedip": 0.0, "suara_aktif": "res://audio/" + String(def["suara"][0]),
			"nada": null,
		})

func pasang_letak(dasar: Dictionary, pakai_simpan: bool, kunci_tema: String) -> void:
	var cfg := ConfigFile.new()
	var ada := cfg.load(JALUR_SIMPAN) == OK
	for pad in pads:
		var id := String(pad["def"]["id"])
		var l: Array = dasar.get(id, [0.5, 0.5, 0.06, 0.1])
		pad["x"] = float(l[0]); pad["y"] = float(l[1])
		pad["rx"] = float(l[2]); pad["ry"] = float(l[3]); pad["skala"] = 1.0
		if pakai_simpan and ada:
			var kunci := kunci_tema + "/" + id
			pad["x"] = float(cfg.get_value("letak", kunci + "_x", pad["x"]))
			pad["y"] = float(cfg.get_value("letak", kunci + "_y", pad["y"]))
			pad["skala"] = float(cfg.get_value("letak", kunci + "_s", 1.0))

func terapkan_tema() -> void:
	tekstur_latar = null
	if tema_ini == "sendiri" and berkas_latar_sendiri != "" and FileAccess.file_exists(berkas_latar_sendiri):
		var gbr := Image.new()
		if gbr.load(berkas_latar_sendiri) == OK:
			tekstur_latar = ImageTexture.create_from_image(gbr)
	pasang_letak(LETAK_BAWAAN, true, tema_ini)

func muat_pengaturan() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_SIMPAN) != OK:
		pasang_letak(LETAK_BAWAAN, false, tema_ini)
		return
	tema_ini = String(cfg.get_value("umum", "tema", "jati"))
	berkas_latar_sendiri = String(cfg.get_value("umum", "latar_sendiri", ""))
	nama_preset_ini = String(cfg.get_value("umum", "preset", ""))
	var vol := float(cfg.get_value("umum", "volume", 0.9))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.001)))
	for pad in pads:
		var id := String(pad["def"]["id"])
		pad["suara_aktif"] = String(cfg.get_value("suara", id, pad["suara_aktif"]))

func simpan_pengaturan() -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_SIMPAN)
	cfg.set_value("umum", "tema", tema_ini)
	cfg.set_value("umum", "latar_sendiri", berkas_latar_sendiri)
	cfg.set_value("umum", "preset", nama_preset_ini)
	for pad in pads:
		var id := String(pad["def"]["id"])
		cfg.set_value("suara", id, String(pad["suara_aktif"]))
		var kunci := tema_ini + "/" + id
		cfg.set_value("letak", kunci + "_x", float(pad["x"]))
		cfg.set_value("letak", kunci + "_y", float(pad["y"]))
		cfg.set_value("letak", kunci + "_s", float(pad["skala"]))
	cfg.save(JALUR_SIMPAN)

# ---------- PRESET ----------

func ambil_daftar_preset() -> Array:
	var hasil := ["Panggung Klasik", "Rampak Rapat"]
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) == OK:
		for s in cfg.get_sections():
			hasil.append(s)
	return hasil

func simpan_preset(nama: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_PRESET)
	cfg.set_value(nama, "tema", tema_ini)
	for pad in pads:
		var id := String(pad["def"]["id"])
		cfg.set_value(nama, id + "_x", float(pad["x"]))
		cfg.set_value(nama, id + "_y", float(pad["y"]))
		cfg.set_value(nama, id + "_s", float(pad["skala"]))
		cfg.set_value(nama, id + "_suara", String(pad["suara_aktif"]))
	cfg.save(JALUR_PRESET)
	nama_preset_ini = nama
	simpan_pengaturan()

func muat_preset(nama: String) -> void:
	if nama == "Panggung Klasik":
		pasang_letak(LETAK_BAWAAN, false, tema_ini)
	elif nama == "Rampak Rapat":
		tema_ini = "panggung"
		terapkan_tema()
		pasang_letak(LETAK_RAPAT, false, tema_ini)
	else:
		var cfg := ConfigFile.new()
		if cfg.load(JALUR_PRESET) != OK:
			return
		tema_ini = String(cfg.get_value(nama, "tema", tema_ini))
		terapkan_tema()
		for pad in pads:
			var id := String(pad["def"]["id"])
			pad["x"] = float(cfg.get_value(nama, id + "_x", pad["x"]))
			pad["y"] = float(cfg.get_value(nama, id + "_y", pad["y"]))
			pad["skala"] = float(cfg.get_value(nama, id + "_s", 1.0))
			pad["suara_aktif"] = String(cfg.get_value(nama, id + "_suara", pad["suara_aktif"]))
			pad["nada"] = null
	nama_preset_ini = nama
	simpan_pengaturan()
	queue_redraw()

func hapus_preset(nama: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) == OK and cfg.has_section(nama):
		cfg.erase_section(nama)
		cfg.save(JALUR_PRESET)
	if nama_preset_ini == nama:
		nama_preset_ini = ""
		simpan_pengaturan()

# ---------- SUARA ----------

func muat_nada(pad: Dictionary) -> AudioStream:
	var jalur := String(pad["suara_aktif"])
	if jalur.begins_with("res://"):
		return load(jalur)
	if jalur.ends_with(".mp3"):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(jalur)
		return mp3
	if jalur.ends_with(".wav"):
		return baca_wav(jalur)
	return null

func baca_wav(jalur: String) -> AudioStreamWAV:
	var b := FileAccess.get_file_as_bytes(jalur)
	if b.size() < 44:
		return null
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 44100
	w.stereo = false
	var pos := 12
	var data_mulai := -1
	var data_ukuran := 0
	while pos + 8 <= b.size():
		var idc := b.slice(pos, pos + 4).get_string_from_ascii()
		var uk := b.decode_u32(pos + 4)
		if idc == "fmt ":
			var ch := b.decode_u16(pos + 10)
			w.stereo = ch > 1
			w.mix_rate = int(b.decode_u32(pos + 12))
			var bits := b.decode_u16(pos + 22)
			if bits == 8:
				w.format = AudioStreamWAV.FORMAT_8_BITS
		elif idc == "data":
			data_mulai = pos + 8
			data_ukuran = uk
			break
		pos += 8 + int(uk) + (int(uk) % 2)
	if data_mulai < 0:
		return null
	w.data = b.slice(data_mulai, mini(data_mulai + data_ukuran, b.size()))
	return w

func pukul(pad: Dictionary) -> void:
	pad["kedip"] = 1.0
	if pad["nada"] == null:
		pad["nada"] = muat_nada(pad)
	var nada: AudioStream = pad["nada"]
	if nada == null:
		return
	var p: AudioStreamPlayer = pemain[giliran_pemain]
	giliran_pemain = (giliran_pemain + 1) % pemain.size()
	p.stream = nada
	p.pitch_scale = rng.randf_range(0.97, 1.03)
	p.play()
	Input.vibrate_handheld(12)
	queue_redraw()

func geo(pad: Dictionary) -> Dictionary:
	var rx := float(pad["rx"]) * float(pad["skala"]) * LEBAR
	var ry := rx
	if String(pad["def"]["bentuk"]) == "blok":
		ry = float(pad["ry"]) * float(pad["skala"]) * TINGGI
	return {"c": Vector2(float(pad["x"]) * LEBAR, float(pad["y"]) * TINGGI), "rx": rx, "ry": ry}

func pad_di(pos: Vector2, longgar: bool = false) -> Dictionary:
	var faktor := 1.12 if longgar else 1.0
	for i in range(pads.size() - 1, -1, -1):
		var pad: Dictionary = pads[i]
		var g := geo(pad)
		var t: Vector2 = g["c"]
		var d := Vector2((pos.x - t.x) / maxf(float(g["rx"]) * faktor, 1.0), (pos.y - t.y) / maxf(float(g["ry"]) * faktor, 1.0))
		if d.length() <= 1.0:
			return pad
	return {}

func _unhandled_input(kejadian: InputEvent) -> void:
	if panel_terbuka != "":
		return
	if kejadian is InputEventScreenTouch:
		var st := kejadian as InputEventScreenTouch
		if st.pressed:
			if modus_atur:
				var pad := pad_di(st.position)
				if not pad.is_empty():
					pad_seret = pad
					pad_pilih = pad
					if penggeser_ukuran:
						penggeser_ukuran.value = float(pad["skala"])
					queue_redraw()
			else:
				var pad2 := pad_di(st.position, true)
				if not pad2.is_empty():
					pukul(pad2)
					jari_pad[st.index] = String(pad2["def"]["id"])
		else:
			jari_pad.erase(st.index)
			if modus_atur and not pad_seret.is_empty():
				pad_seret = {}
				simpan_pengaturan()
	elif kejadian is InputEventScreenDrag and not modus_atur and panel_terbuka == "":
		var sd2 := kejadian as InputEventScreenDrag
		var pad5 := pad_di(sd2.position, true)
		if not pad5.is_empty() and String(jari_pad.get(sd2.index, "")) != String(pad5["def"]["id"]):
			pukul(pad5)
			jari_pad[sd2.index] = String(pad5["def"]["id"])
	elif kejadian is InputEventScreenDrag and modus_atur and not pad_seret.is_empty():
		var sd := kejadian as InputEventScreenDrag
		pad_seret["x"] = clampf(sd.position.x / LEBAR, 0.03, 0.97)
		pad_seret["y"] = clampf(sd.position.y / TINGGI, 0.05, 0.97)
		queue_redraw()
	elif kejadian is InputEventMouseButton:
		var mb := kejadian as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if modus_atur:
					var pad3 := pad_di(mb.position)
					if not pad3.is_empty():
						pad_seret = pad3
						pad_pilih = pad3
						if penggeser_ukuran:
							penggeser_ukuran.value = float(pad3["skala"])
						queue_redraw()
				else:
					var pad4 := pad_di(mb.position, true)
					if not pad4.is_empty():
						pukul(pad4)
			else:
				if modus_atur and not pad_seret.is_empty():
					pad_seret = {}
					simpan_pengaturan()
	elif kejadian is InputEventMouseMotion and modus_atur and not pad_seret.is_empty():
		var mm := kejadian as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			pad_seret["x"] = clampf(mm.position.x / LEBAR, 0.03, 0.97)
			pad_seret["y"] = clampf(mm.position.y / TINGGI, 0.05, 0.97)
			queue_redraw()

func _process(delta: float) -> void:
	if pemutar_musik and pemutar_musik.stream and panel_terbuka == "mp3":
		var lagu := pemutar_musik.stream as AudioStreamMP3
		if lagu:
			geser_posisi.max_value = maxf(lagu.get_length(), 1.0)
			geser_posisi.set_value_no_signal(pemutar_musik.get_playback_position())
			label_waktu.text = format_waktu(pemutar_musik.get_playback_position()) + " / " + format_waktu(lagu.get_length())
	var berubah := false
	for pad in pads:
		if float(pad["kedip"]) > 0.0:
			pad["kedip"] = maxf(0.0, float(pad["kedip"]) - delta * 5.0)
			berubah = true
	if berubah:
		queue_redraw()

func format_waktu(detik: float) -> String:
	var d := int(detik)
	return "%d:%02d" % [d / 60, d % 60]

# ---------- GAMBAR ----------

func palet() -> Dictionary:
	return DAFTAR_TEMA[tema_ini]

func lingkaran(tengah: Vector2, r: float, warna: Color) -> void:
	draw_circle(tengah, r, warna)

func elips_garis(tengah: Vector2, rx: float, ry: float, warna: Color, lebar: float = 3.0) -> void:
	var titik := PackedVector2Array()
	for i in 41:
		var a := TAU * float(i) / 40.0
		titik.append(tengah + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(titik, warna, lebar, true)

func _draw() -> void:
	var p := palet()
	if tekstur_latar != null:
		var uk := tekstur_latar.get_size()
		var s := maxf(LEBAR / uk.x, TINGGI / uk.y)
		draw_texture_rect(tekstur_latar, Rect2((LEBAR - uk.x * s) / 2, (TINGGI - uk.y * s) / 2, uk.x * s, uk.y * s), false)
	else:
		# Latar panggung gelap + pola lubang (perforated) ala Real Drum
		for i in 24:
			var t := float(i) / 24.0
			var c: Color = p["latar1"]
			c = c.lerp(p["latar2"], t)
			draw_rect(Rect2(0, TINGGI * t, LEBAR, TINGGI / 24.0 + 1), c)
		var titik := Color(1, 1, 1, 0.045)
		for gx in range(24, int(LEBAR), 48):
			for gy in range(88, int(TINGGI) - 8, 48):
				draw_circle(Vector2(gx, gy), 5.0, titik)
		# Garis cahaya panggung
		draw_rect(Rect2(0, TINGGI * 0.80, LEBAR, 3), Color(0.35, 0.55, 0.95, 0.30))
	for pad in pads:
		gambar_pad(pad)
	for pad in pads:
		gambar_nama(pad)
	if modus_atur:
		draw_string(ThemeDB.fallback_font, Vector2(24, 112), "MODE ATUR: seret pad untuk memindah", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.95, 0.8))

func gambar_nama(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var g := geo(pad)
	var tengah: Vector2 = g["c"]
	var ry := float(g["ry"])
	var geser := ry + 24
	if String(def["id"]) == "pak":
		geser = 6
	var pos := tengah + Vector2(0, geser)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1, 1), String(def["nama"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0, 0, 0, 0.7))
	draw_string(ThemeDB.fallback_font, pos, String(def["nama"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1, 0.97, 0.9, 0.95))

func gambar_pad(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var p := palet()
	var g := geo(pad)
	var tengah: Vector2 = g["c"]
	var rx := float(g["rx"])
	var ry := float(g["ry"])
	var kedip := float(pad["kedip"])
	var bentuk := String(def["bentuk"])
	var r := rx  # pad bulat: rx (px) dipakai sebagai jari-jari visual
	# Bayangan di lantai
	draw_circle(tengah + Vector2(0, ry * 0.92), rx * 0.95, Color(0, 0, 0, 0.35))
	if bentuk == "drum":
		# Rim luar gelap -> rim kayu -> ring tali -> kepala bergradasi
		lingkaran(tengah, r, p["rim_gelap"])
		lingkaran(tengah, r * 0.965, p["rim"])
		for i in 12:
			var a := TAU * float(i) / 12.0
			var pos_tali := tengah + Vector2(cos(a) * r * 0.915, sin(a) * r * 0.915)
			draw_circle(pos_tali, r * 0.045, p["tali"])
		lingkaran(tengah, r * 0.875, p["kepala"])
		for k in 5:
			var t := float(k) / 5.0
			var ck: Color = p["kepala"]
			ck = ck.lerp(p["kepala_terang"], t * 0.85)
			lingkaran(tengah, r * 0.875 * (1.0 - t * 0.72), ck)
		draw_arc(tengah, r * 0.875, PI * 0.9, PI * 1.7, 24, Color(0, 0, 0, 0.20), r * 0.05, true)
		lingkaran(tengah, r * 0.20, Color(1, 1, 1, 0.10))
	elif bentuk == "gong":
		lingkaran(tengah, r, Color(0.30, 0.22, 0.08))
		lingkaran(tengah, r * 0.94, p["logam"])
		lingkaran(tengah, r * 0.72, Color(p["logam"].r * 1.08, p["logam"].g * 1.08, p["logam"].b * 1.05))
		lingkaran(tengah, r * 0.46, p["logam"])
		lingkaran(tengah, r * 0.24, Color(1.0, 0.92, 0.62))
		draw_arc(tengah, r * 0.83, PI * 1.05, PI * 1.6, 20, Color(1, 1, 1, 0.18), r * 0.06, true)
	elif bentuk == "kecrek":
		lingkaran(tengah, r, Color(0.16, 0.16, 0.18))
		lingkaran(tengah, r * 0.92, Color(0.62, 0.63, 0.66))
		for i in 8:
			var a := TAU * float(i) / 8.0
			draw_circle(tengah + Vector2(cos(a) * r * 0.66, sin(a) * r * 0.66), r * 0.17, Color(0.88, 0.86, 0.60))
		lingkaran(tengah, r * 0.26, Color(0.80, 0.79, 0.72))
	elif bentuk == "blok":
		# Blok kayu PAK
		var kotak := Rect2(tengah - Vector2(rx, ry * 0.62), Vector2(rx * 2, ry * 1.24))
		draw_rect(kotak, Color(0.30, 0.18, 0.09))
		draw_rect(kotak.grow(-5), p["rim"])
		draw_rect(Rect2(tengah - Vector2(rx * 0.7, 3), Vector2(rx * 1.4, 6)), Color(0.22, 0.12, 0.05))
	if kedip > 0.0:
		lingkaran(tengah, r * 0.875 if bentuk == "drum" else r * 0.9, Color(1, 1, 1, 0.22 * kedip))
		elips_garis(tengah, rx * (1.05 + 0.12 * kedip), ry * (1.05 + 0.12 * kedip), Color(1, 0.98, 0.85, 0.55 * kedip), 4.0)
	if modus_atur:
		elips_garis(tengah, rx + 4, ry + 4, Color(1, 0.9, 0.5, 0.55), 2.5)
		if pad == pad_pilih:
			elips_garis(tengah, rx + 10, ry + 10, Color(1, 1, 1, 0.95), 3.5)


# ---------- UI ----------

func gaya_tombol() -> Dictionary:
	var biasa := StyleBoxTexture.new()
	biasa.texture = load("res://aset/ui/button_rectangle_depth_gradient.png")
	biasa.set_texture_margin_all(14)
	biasa.content_margin_left = 16; biasa.content_margin_right = 16
	biasa.content_margin_top = 9; biasa.content_margin_bottom = 9
	var tekan := StyleBoxTexture.new()
	tekan.texture = load("res://aset/ui/button_rectangle_depth_flat.png")
	tekan.set_texture_margin_all(14)
	tekan.content_margin_left = 16; tekan.content_margin_right = 16
	tekan.content_margin_top = 9; tekan.content_margin_bottom = 9
	return {"biasa": biasa, "tekan": tekan}

func buat_tombol(teks: String, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	var g := gaya_tombol()
	b.add_theme_stylebox_override("normal", g["biasa"])
	b.add_theme_stylebox_override("hover", g["biasa"])
	b.add_theme_stylebox_override("pressed", g["tekan"])
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	b.pressed.connect(aksi)
	return b

func gaya_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.08, 0.07, 0.97)
	s.set_corner_radius_all(18)
	s.set_border_width_all(2)
	s.border_color = Color(0.85, 0.62, 0.30)
	s.content_margin_left = 22; s.content_margin_right = 22
	s.content_margin_top = 18; s.content_margin_bottom = 18
	return s

func buat_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", gaya_panel())
	p.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p.custom_minimum_size = Vector2(820, 500)
	p.size = Vector2(820, 500)
	p.position = Vector2((LEBAR - 820) / 2, (TINGGI - 500) / 2)
	p.visible = false
	return p

func judul_panel(teks: String) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", 29)
	l.add_theme_color_override("font_color", Color(0.98, 0.82, 0.50))
	return l

func kepala_panel(teks: String, induk: VBoxContainer) -> void:
	var baris := HBoxContainer.new()
	baris.add_child(judul_panel(teks))
	var r := Control.new()
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(r)
	baris.add_child(buat_tombol("Tutup", func() -> void: tutup_panel()))
	induk.add_child(baris)

func bangun_ui() -> void:
	lapis = CanvasLayer.new()
	add_child(lapis)
	var atas := PanelContainer.new()
	atas.add_theme_stylebox_override("panel", gaya_panel())
	atas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lapis.add_child(atas)
	var isi_atas := HBoxContainer.new()
	isi_atas.add_theme_constant_override("separation", 8)
	atas.add_child(isi_atas)
	var judul := Label.new()
	judul.text = "KENDANG VIRTUAL"
	judul.add_theme_font_size_override("font_size", 28)
	judul.add_theme_color_override("font_color", Color(0.98, 0.82, 0.50))
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	isi_atas.add_child(judul)
	var ruang := Control.new()
	ruang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi_atas.add_child(ruang)
	isi_atas.add_child(buat_tombol("Tema", func() -> void: buka_panel("tema")))
	isi_atas.add_child(buat_tombol("Preset", func() -> void: buka_panel("preset")))
	isi_atas.add_child(buat_tombol("Suara", func() -> void: buka_panel("suara")))
	isi_atas.add_child(buat_tombol("Atur", func() -> void: masuk_atur()))
	isi_atas.add_child(buat_tombol("MP3", func() -> void: buka_panel("mp3")))
	isi_atas.add_child(buat_tombol("Info", func() -> void: buka_panel("tentang")))
	label_status = Label.new()
	label_status.text = "Pukul kendangnya! DANG di tengah • TAK kiri • ANAK kanan"
	label_status.add_theme_font_size_override("font_size", 17)
	label_status.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 0.75))
	label_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label_status.offset_top = -38
	label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lapis.add_child(label_status)
	bangun_panel_tema()
	bangun_panel_preset()
	bangun_panel_suara()
	bangun_panel_mp3()
	bangun_panel_tentang()
	bangun_bar_atur()

func buka_panel(nama: String) -> void:
	panel_terbuka = nama
	panel_tema.visible = nama == "tema"
	panel_preset.visible = nama == "preset"
	panel_suara.visible = nama == "suara"
	panel_mp3.visible = nama == "mp3"
	panel_tentang.visible = nama == "tentang"
	if nama == "suara":
		segarkan_panel_suara()
	if nama == "preset":
		segarkan_panel_preset()

func tutup_panel() -> void:
	panel_terbuka = ""
	panel_tema.visible = false
	panel_preset.visible = false
	panel_suara.visible = false
	panel_mp3.visible = false
	panel_tentang.visible = false

func bangun_panel_tema() -> void:
	panel_tema = buat_panel()
	lapis.add_child(panel_tema)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 13)
	panel_tema.add_child(v)
	kepala_panel("Tema Kit (Skin)", v)
	for id in DAFTAR_TEMA.keys():
		var info: Dictionary = DAFTAR_TEMA[id]
		var kunci := String(id)
		v.add_child(buat_tombol(String(info["nama"]), func() -> void: pilih_tema(kunci)))
	var ket := Label.new()
	ket.text = "\"Latar Sendiri\" memakai gambar dari HP sebagai latar panggung."
	ket.add_theme_font_size_override("font_size", 16)
	ket.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.8))
	v.add_child(ket)

func pilih_tema(id: String) -> void:
	if id == "sendiri" and berkas_latar_sendiri == "":
		impor_latar()
		return
	tema_ini = id
	terapkan_tema()
	simpan_pengaturan()
	tutup_panel()
	queue_redraw()

func impor_latar() -> void:
	DisplayServer.file_dialog_show("Pilih gambar latar", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Gambar"]),
		func(status: bool, jalur: PackedStringArray, _idx: int) -> void:
			if status and jalur.size() > 0:
				berkas_latar_sendiri = jalur[0]
				tema_ini = "sendiri"
				terapkan_tema()
				simpan_pengaturan()
				tutup_panel()
				queue_redraw())

func bangun_panel_preset() -> void:
	panel_preset = buat_panel()
	lapis.add_child(panel_preset)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_preset.add_child(v)
	kepala_panel("Manage Preset", v)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	isian_nama_preset = LineEdit.new()
	isian_nama_preset.placeholder_text = "Nama preset baru…"
	isian_nama_preset.custom_minimum_size = Vector2(430, 0)
	isian_nama_preset.add_theme_font_size_override("font_size", 20)
	baris.add_child(isian_nama_preset)
	baris.add_child(buat_tombol("Simpan Preset", func() -> void:
		var nm := isian_nama_preset.text.strip_edges()
		if nm != "" and nm != "Panggung Klasik" and nm != "Rampak Rapat":
			simpan_preset(nm)
			isian_nama_preset.text = ""
			segarkan_panel_preset()))
	v.add_child(baris)
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(776, 290)
	v.add_child(gulir)
	daftar_preset = VBoxContainer.new()
	daftar_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daftar_preset.add_theme_constant_override("separation", 8)
	gulir.add_child(daftar_preset)
	var ket := Label.new()
	ket.text = "Preset menyimpan: tema, posisi & ukuran pad, dan suara tiap pad."
	ket.add_theme_font_size_override("font_size", 16)
	ket.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.8))
	v.add_child(ket)

func segarkan_panel_preset() -> void:
	for c in daftar_preset.get_children():
		c.queue_free()
	for nama in ambil_daftar_preset():
		var nm := String(nama)
		var baris := HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = nm + ("  (aktif)" if nm == nama_preset_ini else "")
		l.custom_minimum_size = Vector2(400, 0)
		l.add_theme_font_size_override("font_size", 21)
		l.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
		baris.add_child(l)
		baris.add_child(buat_tombol("Muat", func() -> void:
			muat_preset(nm)
			tutup_panel()
			segarkan_panel_preset()))
		if nm != "Panggung Klasik" and nm != "Rampak Rapat":
			baris.add_child(buat_tombol("Hapus", func() -> void:
				hapus_preset(nm)
				segarkan_panel_preset()))
		daftar_preset.add_child(baris)

func bangun_panel_suara() -> void:
	panel_suara = buat_panel()
	lapis.add_child(panel_suara)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_suara.add_child(v)
	kepala_panel("Custom Suara per Pad", v)
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(776, 330)
	v.add_child(gulir)
	daftar_suara = VBoxContainer.new()
	daftar_suara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daftar_suara.add_theme_constant_override("separation", 8)
	gulir.add_child(daftar_suara)
	var ket := Label.new()
	ket.text = "Ganti = suara bawaan lain • Impor = berkas MP3/WAV dari HP"
	ket.add_theme_font_size_override("font_size", 16)
	ket.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.8))
	v.add_child(ket)

func segarkan_panel_suara() -> void:
	for c in daftar_suara.get_children():
		c.queue_free()
	for pad in pads:
		var def: Dictionary = pad["def"]
		var pad_ini: Dictionary = pad
		var baris := HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		var nama := Label.new()
		nama.text = String(def["nama"])
		nama.custom_minimum_size = Vector2(170, 0)
		nama.add_theme_font_size_override("font_size", 20)
		nama.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
		baris.add_child(nama)
		var aktif := Label.new()
		aktif.text = String(pad["suara_aktif"]).get_file()
		aktif.custom_minimum_size = Vector2(230, 0)
		aktif.add_theme_font_size_override("font_size", 18)
		aktif.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		baris.add_child(aktif)
		baris.add_child(buat_tombol("Tes", func() -> void: pukul(pad_ini)))
		baris.add_child(buat_tombol("Ganti", func() -> void: ganti_suara(pad_ini)))
		baris.add_child(buat_tombol("Impor", func() -> void: impor_suara(pad_ini)))
		daftar_suara.add_child(baris)

func ganti_suara(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var pilihan: Array = def["suara"]
	var kini := String(pad["suara_aktif"]).get_file()
	var idx := pilihan.find(kini)
	idx = (idx + 1) % pilihan.size()
	pad["suara_aktif"] = "res://audio/" + String(pilihan[idx])
	pad["nada"] = null
	pukul(pad)
	simpan_pengaturan()
	segarkan_panel_suara()

func impor_suara(pad: Dictionary) -> void:
	DisplayServer.file_dialog_show("Pilih berkas suara", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.mp3,*.wav ; Suara"]),
		func(status: bool, jalur: PackedStringArray, _idx: int) -> void:
			if status and jalur.size() > 0:
				pad["suara_aktif"] = jalur[0]
				pad["nada"] = null
				pukul(pad)
				simpan_pengaturan()
				segarkan_panel_suara())

func bangun_panel_mp3() -> void:
	panel_mp3 = buat_panel()
	lapis.add_child(panel_mp3)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel_mp3.add_child(v)
	kepala_panel("Putar MP3 — Main Sambil Diiringi Lagu", v)
	label_lagu = Label.new()
	label_lagu.text = "Belum ada lagu dipilih."
	label_lagu.add_theme_font_size_override("font_size", 20)
	label_lagu.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
	v.add_child(label_lagu)
	geser_posisi = HSlider.new()
	geser_posisi.min_value = 0.0
	geser_posisi.max_value = 1.0
	geser_posisi.step = 0.1
	geser_posisi.editable = false
	geser_posisi.value_changed.connect(func(nilai: float) -> void:
		if pemutar_musik and pemutar_musik.stream and absf(nilai - pemutar_musik.get_playback_position()) > 1.5:
			pemutar_musik.seek(nilai))
	v.add_child(geser_posisi)
	label_waktu = Label.new()
	label_waktu.text = "0:00 / 0:00"
	label_waktu.add_theme_font_size_override("font_size", 16)
	label_waktu.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.85))
	v.add_child(label_waktu)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	baris.add_child(buat_tombol("Pilih MP3", func() -> void: pilih_mp3()))
	baris.add_child(buat_tombol("Putar/Jeda", func() -> void:
		if pemutar_musik.stream:
			if pemutar_musik.playing:
				pemutar_musik.stream_paused = not pemutar_musik.stream_paused
			else:
				pemutar_musik.play()))
	baris.add_child(buat_tombol("Berhenti", func() -> void: pemutar_musik.stop()))
	v.add_child(baris)
	cek_ulangi = CheckBox.new()
	cek_ulangi.text = "Ulangi lagu terus"
	cek_ulangi.add_theme_font_size_override("font_size", 18)
	cek_ulangi.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
	cek_ulangi.toggled.connect(func(nyala: bool) -> void:
		if pemutar_musik.stream is AudioStreamMP3:
			(pemutar_musik.stream as AudioStreamMP3).loop = nyala)
	v.add_child(cek_ulangi)
	var ket := Label.new()
	ket.text = "Lagu tetap berputar saat panel ditutup — pukul kendangnya mengiringi!"
	ket.add_theme_font_size_override("font_size", 16)
	ket.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.8))
	v.add_child(ket)

func pilih_mp3() -> void:
	DisplayServer.file_dialog_show("Pilih lagu MP3", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.mp3 ; Lagu MP3"]),
		func(status: bool, jalur: PackedStringArray, _idx: int) -> void:
			if status and jalur.size() > 0:
				var mp3 := AudioStreamMP3.new()
				mp3.data = FileAccess.get_file_as_bytes(jalur[0])
				mp3.loop = cek_ulangi.button_pressed
				pemutar_musik.stream = mp3
				pemutar_musik.play()
				label_lagu.text = "Memutar: " + jalur[0].get_file()
				geser_posisi.max_value = maxf(mp3.get_length(), 1.0)
				geser_posisi.editable = true)

func bangun_panel_tentang() -> void:
	panel_tentang = buat_panel()
	lapis.add_child(panel_tentang)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_tentang.add_child(v)
	kepala_panel("Tentang & Kredit", v)
	var isi := Label.new()
	isi.text = "Kendang Virtual v2.2 — kit Kendang Bajidor (Sunda) tampak atas ala Real Drum. Bajidor itu kesenian Sunda — bukan Tanjidor Betawi.\n\nFitur: pukul multi-sentuh, Tema kit, Preset (simpan/muat/hapus konfigurasi), custom suara per pad (bawaan/impor MP3-WAV), mode Atur (geser & ukur pad, tersimpan per tema), pemutar MP3 pengiring.\n\nTombol UI: Kenney UI Pack (CC0) — kenney.nl. Semua suara kendang disintesis dari kode."
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.add_theme_font_size_override("font_size", 18)
	isi.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	v.add_child(isi)

func masuk_atur() -> void:
	modus_atur = true
	tutup_panel()
	bar_atur.visible = true
	queue_redraw()

func keluar_atur() -> void:
	modus_atur = false
	pad_seret = {}
	pad_pilih = {}
	bar_atur.visible = false
	simpan_pengaturan()
	queue_redraw()

func bangun_bar_atur() -> void:
	bar_atur = PanelContainer.new()
	bar_atur.add_theme_stylebox_override("panel", gaya_panel())
	bar_atur.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar_atur.custom_minimum_size = Vector2(900, 84)
	bar_atur.size = Vector2(900, 84)
	bar_atur.position = Vector2((LEBAR - 900) / 2, TINGGI - 150)
	bar_atur.visible = false
	lapis.add_child(bar_atur)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	bar_atur.add_child(h)
	var ket := Label.new()
	ket.text = "Ukuran pad:"
	ket.add_theme_font_size_override("font_size", 20)
	ket.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
	ket.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(ket)
	penggeser_ukuran = HSlider.new()
	penggeser_ukuran.min_value = 0.6
	penggeser_ukuran.max_value = 1.7
	penggeser_ukuran.step = 0.02
	penggeser_ukuran.value = 1.0
	penggeser_ukuran.custom_minimum_size = Vector2(300, 0)
	penggeser_ukuran.value_changed.connect(func(nilai: float) -> void:
		if not pad_pilih.is_empty():
			pad_pilih["skala"] = nilai
			queue_redraw())
	h.add_child(penggeser_ukuran)
	var vol := Label.new()
	vol.text = "Volume:"
	vol.add_theme_font_size_override("font_size", 20)
	vol.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
	vol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(vol)
	var geser_vol := HSlider.new()
	geser_vol.min_value = 0.0
	geser_vol.max_value = 1.0
	geser_vol.step = 0.02
	geser_vol.value = 0.9
	geser_vol.custom_minimum_size = Vector2(160, 0)
	geser_vol.value_changed.connect(func(nilai: float) -> void:
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(nilai, 0.001)))
		var cfg := ConfigFile.new()
		cfg.load(JALUR_SIMPAN)
		cfg.set_value("umum", "volume", nilai)
		cfg.save(JALUR_SIMPAN))
	h.add_child(geser_vol)
	h.add_child(buat_tombol("Reset", func() -> void:
		pasang_letak(LETAK_BAWAAN, false, tema_ini)
		simpan_pengaturan()
		queue_redraw()))
	h.add_child(buat_tombol("Selesai", func() -> void: keluar_atur()))
