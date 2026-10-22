extends Node2D
## Kendang Virtual v2.0 — kendang virtual ala Real Drum: pukul langsung di layar.
## Fitur: custom audio per pad, custom posisi pad, custom skin, putar MP3 pengiring.

const LEBAR := 1280.0
const TINGGI := 720.0
const JALUR_SIMPAN := "user://pengaturan.cfg"

const DAFTAR_KULIT := {
	"klasik": {"nama": "Kayu Klasik", "berkas": "res://aset/kendang-klasik.png", "modus": "isi"},
	"merah": {"nama": "Kayu Merah", "berkas": "res://aset/kendang-merah.png", "modus": "isi"},
	"foto": {"nama": "Foto Panggung", "berkas": "res://aset/foto-panggung.jpg", "modus": "penuh"},
	"sendiri": {"nama": "Skin Sendiri", "berkas": "", "modus": "penuh"},
}

# Definisi pad: suara bawaan (bisa diganti), warna aksen, gaya gambar
const DEF_PAD := [
	{"id": "tak", "nama": "TAK (kiri)", "bentuk": "kepala", "warna": Color(0.98, 0.80, 0.45), "suara": ["tak.wav", "tak_tajam.wav"]},
	{"id": "dang", "nama": "DANG (kanan)", "bentuk": "kepala", "warna": Color(0.98, 0.62, 0.30), "suara": ["dang.wav", "dang_rendah.wav", "dang_kering.wav"]},
	{"id": "pak", "nama": "PAK (badan)", "bentuk": "kepala", "warna": Color(0.85, 0.55, 0.35), "suara": ["pak.wav", "pak_lembut.wav"]},
	{"id": "ketipung", "nama": "KETIPUNG", "bentuk": "ketipung", "warna": Color(0.80, 0.58, 0.35), "suara": ["ketipung.wav", "ketipung_tinggi.wav"]},
	{"id": "kecrek", "nama": "KECREK", "bentuk": "kecrek", "warna": Color(0.92, 0.85, 0.55), "suara": ["kecrek.wav", "kecrek_rapat.wav"]},
	{"id": "kempul", "nama": "KEMPUL", "bentuk": "gong", "warna": Color(0.85, 0.68, 0.30), "suara": ["kempul.wav", "gong.wav"]},
	{"id": "gong", "nama": "GONG", "bentuk": "gong", "warna": Color(0.95, 0.75, 0.32), "suara": ["gong.wav", "kempul.wav"]},
	{"id": "terompet", "nama": "TEROMPET", "bentuk": "terompet", "warna": Color(0.90, 0.45, 0.35), "suara": ["terompet.wav"]},
]

# Tata letak bawaan per kulit (relatif 0..1 terhadap layar): [per pad: x, y, rx, ry]
const LETAK_BAWAAN := {
	"klasik": {
		"tak": [0.259, 0.459, 0.030, 0.105], "dang": [0.666, 0.415, 0.102, 0.210],
		"pak": [0.455, 0.420, 0.052, 0.088], "ketipung": [0.115, 0.845, 0.062, 0.075],
		"kecrek": [0.115, 0.150, 0.045, 0.080], "kempul": [0.885, 0.845, 0.048, 0.085],
		"gong": [0.885, 0.150, 0.055, 0.098], "terompet": [0.500, 0.158, 0.042, 0.072],
	},
	"merah": {
		"tak": [0.300, 0.440, 0.032, 0.110], "dang": [0.700, 0.415, 0.105, 0.215],
		"pak": [0.470, 0.420, 0.052, 0.088], "ketipung": [0.115, 0.845, 0.062, 0.075],
		"kecrek": [0.115, 0.150, 0.045, 0.080], "kempul": [0.885, 0.845, 0.048, 0.085],
		"gong": [0.885, 0.150, 0.055, 0.098], "terompet": [0.500, 0.158, 0.042, 0.072],
	},
	"foto": {
		"tak": [0.245, 0.630, 0.070, 0.130], "dang": [0.400, 0.720, 0.088, 0.165],
		"pak": [0.560, 0.600, 0.055, 0.090], "ketipung": [0.115, 0.845, 0.062, 0.075],
		"kecrek": [0.075, 0.150, 0.045, 0.080], "kempul": [0.885, 0.845, 0.048, 0.085],
		"gong": [0.925, 0.150, 0.055, 0.098], "terompet": [0.500, 0.158, 0.042, 0.072],
	},
}
const LETAK_SENDIRI := {
	"tak": [0.259, 0.459, 0.045, 0.105], "dang": [0.666, 0.415, 0.102, 0.210],
	"pak": [0.455, 0.420, 0.052, 0.088], "ketipung": [0.115, 0.845, 0.062, 0.075],
	"kecrek": [0.115, 0.150, 0.045, 0.080], "kempul": [0.885, 0.845, 0.048, 0.085],
	"gong": [0.885, 0.150, 0.055, 0.098], "terompet": [0.500, 0.158, 0.042, 0.072],
}

var kulit_ini := "klasik"
var tekstur_kulit: Texture2D = null
var berkas_kulit_sendiri := ""
var pads: Array = []            # {def, x, y, rx, ry, skala, kedip, suara_aktif, nada}
var pemain: Array = []          # kumpulan AudioStreamPlayer untuk polifoni
var giliran_pemain := 0
var modus_atur := false
var pad_seret: Dictionary = {}
var pad_pilih: Dictionary = {}
var panel_terbuka := ""         # "", "kulit", "suara", "video", "tentang"
var rng := RandomNumberGenerator.new()

var lapis: CanvasLayer
var panel_kulit: PanelContainer
var panel_suara: PanelContainer
var panel_mp3: PanelContainer
var panel_tentang: PanelContainer
var bar_atur: PanelContainer
var penggeser_ukuran: HSlider
var label_status: Label
var pemutar_musik: AudioStreamPlayer
var label_lagu: Label
var geser_posisi: HSlider
var label_waktu: Label
var daftar_suara: VBoxContainer
var cek_ulangi: CheckBox

func _ready() -> void:
	rng.randomize()
	siapkan_pemain()
	pemutar_musik = AudioStreamPlayer.new()
	pemutar_musik.bus = "Master"
	add_child(pemutar_musik)
	siapkan_pads()
	muat_pengaturan()
	terapkan_kulit()
	bangun_ui()
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
			"def": def, "x": 0.5, "y": 0.5, "rx": 0.05, "ry": 0.09, "skala": 1.0,
			"kedip": 0.0, "suara_aktif": "res://audio/" + String(def["suara"][0]),
			"nada": null,
		})

func letak_untuk(kulit: String) -> Dictionary:
	if kulit == "sendiri":
		return LETAK_SENDIRI
	return LETAK_BAWAAN.get(kulit, LETAK_BAWAAN["klasik"])

func pasang_letak(kulit: String, pakai_simpan: bool) -> void:
	var dasar: Dictionary = letak_untuk(kulit)
	var cfg := ConfigFile.new()
	var ada := cfg.load(JALUR_SIMPAN) == OK
	for pad in pads:
		var id := String(pad["def"]["id"])
		var l: Array = dasar.get(id, [0.5, 0.5, 0.05, 0.09])
		pad["x"] = float(l[0]); pad["y"] = float(l[1])
		pad["rx"] = float(l[2]); pad["ry"] = float(l[3]); pad["skala"] = 1.0
		if pakai_simpan and ada:
			var kunci := kulit + "/" + id
			pad["x"] = float(cfg.get_value("letak", kunci + "_x", pad["x"]))
			pad["y"] = float(cfg.get_value("letak", kunci + "_y", pad["y"]))
			pad["skala"] = float(cfg.get_value("letak", kunci + "_s", 1.0))

func terapkan_kulit() -> void:
	var info: Dictionary = DAFTAR_KULIT[kulit_ini]
	var jalur := String(info["berkas"])
	if kulit_ini == "sendiri":
		jalur = berkas_kulit_sendiri
	tekstur_kulit = null
	if jalur.begins_with("res://"):
		tekstur_kulit = load(jalur)
	elif jalur != "" and FileAccess.file_exists(jalur):
		var gbr := Image.new()
		if gbr.load(jalur) == OK:
			tekstur_kulit = ImageTexture.create_from_image(gbr)
	pasang_letak(kulit_ini, true)

func muat_pengaturan() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_SIMPAN) != OK:
		pasang_letak(kulit_ini, false)
		return
	kulit_ini = String(cfg.get_value("umum", "kulit", "klasik"))
	berkas_kulit_sendiri = String(cfg.get_value("umum", "kulit_sendiri", ""))
	var vol := float(cfg.get_value("umum", "volume", 0.9))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.001)))
	for pad in pads:
		var id := String(pad["def"]["id"])
		pad["suara_aktif"] = String(cfg.get_value("suara", id, pad["suara_aktif"]))

func simpan_pengaturan() -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_SIMPAN)
	cfg.set_value("umum", "kulit", kulit_ini)
	cfg.set_value("umum", "kulit_sendiri", berkas_kulit_sendiri)
	for pad in pads:
		var id := String(pad["def"]["id"])
		cfg.set_value("suara", id, String(pad["suara_aktif"]))
		var kunci := kulit_ini + "/" + id
		cfg.set_value("letak", kunci + "_x", float(pad["x"]))
		cfg.set_value("letak", kunci + "_y", float(pad["y"]))
		cfg.set_value("letak", kunci + "_s", float(pad["skala"]))
	cfg.save(JALUR_SIMPAN)

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
	# Pindai sub-chunk fmt & data (WAV standar)
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
	Input.vibrate_handheld(18)
	queue_redraw()

func pad_di(pos: Vector2) -> Dictionary:
	# Pad terakhir digambar = paling atas
	for i in range(pads.size() - 1, -1, -1):
		var pad: Dictionary = pads[i]
		var cx := float(pad["x"]) * LEBAR
		var cy := float(pad["y"]) * TINGGI
		var rx := float(pad["rx"]) * float(pad["skala"]) * LEBAR
		var ry := float(pad["ry"]) * float(pad["skala"]) * TINGGI
		var d := Vector2((pos.x - cx) / maxf(rx, 1.0), (pos.y - cy) / maxf(ry, 1.0))
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
				var pad2 := pad_di(st.position)
				if not pad2.is_empty():
					pukul(pad2)
		else:
			if modus_atur and not pad_seret.is_empty():
				pad_seret = {}
				simpan_pengaturan()
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
					var pad4 := pad_di(mb.position)
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

# ---------- GAMBAR ----------

func rect_kulit() -> Rect2:
	if tekstur_kulit == null:
		return Rect2()
	var info: Dictionary = DAFTAR_KULIT[kulit_ini]
	var uk := tekstur_kulit.get_size()
	if String(info["modus"]) == "isi":
		var s := minf(LEBAR / uk.x, TINGGI / uk.y)
		var w := uk.x * s
		var h := uk.y * s
		return Rect2((LEBAR - w) / 2.0, (TINGGI - h) / 2.0, w, h)
	var s2 := maxf(LEBAR / uk.x, TINGGI / uk.y)
	var w2 := uk.x * s2
	var h2 := uk.y * s2
	return Rect2((LEBAR - w2) / 2.0, (TINGGI - h2) / 2.0, w2, h2)

func elips(tengah: Vector2, rx: float, ry: float, warna: Color, isi: bool = true) -> void:
	var titik := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		titik.append(tengah + Vector2(cos(a) * rx, sin(a) * ry))
	if isi:
		draw_colored_polygon(titik, warna)
	else:
		titik.append(titik[0])
		draw_polyline(titik, warna, 3.0, true)

func _draw() -> void:
	# Latar: gradasi langit senja hangat
	for i in 24:
		var t := float(i) / 24.0
		var c := Color(0.16, 0.08, 0.10).lerp(Color(0.45, 0.20, 0.12), t)
		draw_rect(Rect2(0, TINGGI * t, LEBAR, TINGGI / 24.0 + 1), c)
	# Bendera segitiga (hiasan festival)
	for i in 16:
		var x0 := float(i) * (LEBAR / 15.0)
		var tengah := Vector2(x0 + LEBAR / 30.0, 26.0 + 10.0 * sin(float(i) * 1.3))
		var palet: Array[Color] = [Color(0.95, 0.45, 0.35), Color(0.98, 0.80, 0.40), Color(0.55, 0.85, 0.55), Color(0.45, 0.70, 0.95)]
		var warna: Color = palet[i % 4]
		draw_colored_polygon(PackedVector2Array([Vector2(x0, 6), Vector2(x0 + LEBAR / 15.0, 6), tengah]), warna)
	# Lantai panggung
	draw_rect(Rect2(0, TINGGI - 64, LEBAR, 64), Color(0.23, 0.13, 0.09))
	draw_rect(Rect2(0, TINGGI - 64, LEBAR, 4), Color(0.55, 0.35, 0.18))
	# Kulit / skin
	if tekstur_kulit != null:
		draw_texture_rect(tekstur_kulit, rect_kulit(), false)
	# Pads
	for pad in pads:
		gambar_pad(pad)
	if modus_atur:
		draw_string(ThemeDB.fallback_font, Vector2(24, 112), "MODE ATUR: seret pad untuk memindah", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.95, 0.8))

func gambar_pad(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var cx := float(pad["x"]) * LEBAR
	var cy := float(pad["y"]) * TINGGI
	var rx := float(pad["rx"]) * float(pad["skala"]) * LEBAR
	var ry := float(pad["ry"]) * float(pad["skala"]) * TINGGI
	var tengah := Vector2(cx, cy)
	var kedip := float(pad["kedip"])
	var aksen: Color = def["warna"]
	var bentuk := String(def["bentuk"])
	if bentuk == "kepala":
		# Cincin halus di atas muka kendang; menyala saat dipukul
		var a := 0.16 + 0.55 * kedip + (0.20 if modus_atur else 0.0)
		elips(tengah, rx, ry, Color(aksen.r, aksen.g, aksen.b, a * 0.5))
		elips(tengah, rx, ry, Color(aksen.r, aksen.g, aksen.b, a), false)
		if kedip > 0.0:
			elips(tengah, rx * (1.0 + 0.10 * kedip), ry * (1.0 + 0.10 * kedip), Color(1, 1, 1, 0.35 * kedip), false)
	elif bentuk == "gong":
		draw_circle(tengah, rx, Color(0.45, 0.32, 0.12))
		draw_circle(tengah, rx * 0.88, Color(0.85, 0.66, 0.28))
		draw_circle(tengah, rx * 0.55, Color(0.92, 0.74, 0.35))
		draw_circle(tengah, rx * 0.26, Color(0.98, 0.84, 0.45))
		if kedip > 0.0 or modus_atur:
			draw_arc(tengah, rx + 3, 0, TAU, 40, Color(aksen.r, aksen.g, aksen.b, 0.35 + 0.6 * kedip), 3.5, true)
	elif bentuk == "kecrek":
		for i in 8:
			var a := TAU * float(i) / 8.0
			draw_circle(tengah + Vector2(cos(a) * rx * 0.72, sin(a) * ry * 0.72), rx * 0.20, Color(0.88, 0.80, 0.45))
		draw_circle(tengah, rx * 0.30, Color(0.95, 0.88, 0.55))
		if kedip > 0.0 or modus_atur:
			draw_arc(tengah, rx + 3, 0, TAU, 40, Color(aksen.r, aksen.g, aksen.b, 0.35 + 0.6 * kedip), 3.0, true)
	elif bentuk == "ketipung":
		elips(tengah, rx, ry * 0.62, Color(0.55, 0.36, 0.20))
		elips(tengah, rx, ry * 0.62, Color(0.30, 0.19, 0.10), false)
		elips(tengah - Vector2(rx * 0.72, 0), rx * 0.24, ry * 0.45, Color(0.92, 0.80, 0.58))
		elips(tengah + Vector2(rx * 0.72, 0), rx * 0.24, ry * 0.45, Color(0.95, 0.84, 0.62))
		if kedip > 0.0 or modus_atur:
			elips(tengah, rx + 3, ry * 0.62 + 3, Color(aksen.r, aksen.g, aksen.b, 0.35 + 0.6 * kedip), false)
	elif bentuk == "terompet":
		var bell := tengah + Vector2(rx * 0.55, 0)
		draw_colored_polygon(PackedVector2Array([
			tengah - Vector2(rx * 0.8, ry * 0.14), bell - Vector2(0, ry * 0.62),
			bell + Vector2(0, ry * 0.62), tengah + Vector2(-rx * 0.8, ry * 0.14)]), Color(0.88, 0.60, 0.25))
		elips(bell, rx * 0.20, ry * 0.62, Color(0.97, 0.78, 0.38))
		if kedip > 0.0 or modus_atur:
			elips(tengah, rx + 3, ry + 3, Color(aksen.r, aksen.g, aksen.b, 0.35 + 0.6 * kedip), false)
	# Nama pad
	if modus_atur or bentuk != "kepala":
		var label := String(def["nama"])
		draw_string(ThemeDB.fallback_font, tengah + Vector2(0, ry + 22), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 17, Color(1, 0.97, 0.88, 0.95))
	if modus_atur and pad == pad_pilih:
		elips(tengah, rx + 8, ry + 8, Color(1, 1, 1, 0.9), false)

# ---------- UI ----------

func gaya_tombol() -> Dictionary:
	var biasa := StyleBoxTexture.new()
	biasa.texture = load("res://aset/ui/button_rectangle_depth_gradient.png")
	biasa.set_texture_margin_all(14)
	biasa.content_margin_left = 18; biasa.content_margin_right = 18
	biasa.content_margin_top = 10; biasa.content_margin_bottom = 10
	var tekan := StyleBoxTexture.new()
	tekan.texture = load("res://aset/ui/button_rectangle_depth_flat.png")
	tekan.set_texture_margin_all(14)
	tekan.content_margin_left = 18; tekan.content_margin_right = 18
	tekan.content_margin_top = 10; tekan.content_margin_bottom = 10
	return {"biasa": biasa, "tekan": tekan}

func buat_tombol(teks: String, aksi: Callable) -> Button:
	var b := Button.new()
	b.text = teks
	var g := gaya_tombol()
	b.add_theme_stylebox_override("normal", g["biasa"])
	b.add_theme_stylebox_override("hover", g["biasa"])
	b.add_theme_stylebox_override("pressed", g["tekan"])
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	b.pressed.connect(aksi)
	return b

func gaya_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.13, 0.09, 0.08, 0.96)
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
	p.custom_minimum_size = Vector2(760, 470)
	p.size = Vector2(760, 470)
	p.position = Vector2((LEBAR - 760) / 2, (TINGGI - 470) / 2)
	p.visible = false
	return p

func judul_panel(teks: String) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(0.98, 0.82, 0.50))
	return l

func bangun_ui() -> void:
	lapis = CanvasLayer.new()
	add_child(lapis)
	# Bilah atas
	var atas := PanelContainer.new()
	atas.add_theme_stylebox_override("panel", gaya_panel())
	atas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lapis.add_child(atas)
	var isi_atas := HBoxContainer.new()
	isi_atas.add_theme_constant_override("separation", 10)
	atas.add_child(isi_atas)
	var judul := Label.new()
	judul.text = "KENDANG VIRTUAL"
	judul.add_theme_font_size_override("font_size", 30)
	judul.add_theme_color_override("font_color", Color(0.98, 0.82, 0.50))
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	isi_atas.add_child(judul)
	var ruang := Control.new()
	ruang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi_atas.add_child(ruang)
	isi_atas.add_child(buat_tombol("Skin", func() -> void: buka_panel("kulit")))
	isi_atas.add_child(buat_tombol("Suara", func() -> void: buka_panel("suara")))
	isi_atas.add_child(buat_tombol("Atur", func() -> void: masuk_atur()))
	isi_atas.add_child(buat_tombol("MP3", func() -> void: buka_panel("mp3")))
	isi_atas.add_child(buat_tombol("Info", func() -> void: buka_panel("tentang")))
	# Petunjuk kecil di bawah
	label_status = Label.new()
	label_status.text = "Pukul kendangnya! TAK = kepala kecil (kiri) • DANG = kepala besar (kanan)"
	label_status.add_theme_font_size_override("font_size", 18)
	label_status.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 0.85))
	label_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label_status.offset_top = -42
	label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lapis.add_child(label_status)
	bangun_panel_kulit()
	bangun_panel_suara()
	bangun_panel_mp3()
	bangun_panel_tentang()
	bangun_bar_atur()

func buka_panel(nama: String) -> void:
	panel_terbuka = nama
	panel_kulit.visible = nama == "kulit"
	panel_suara.visible = nama == "suara"
	panel_mp3.visible = nama == "mp3"
	panel_tentang.visible = nama == "tentang"
	if nama == "suara":
		segarkan_panel_suara()

func tutup_panel() -> void:
	panel_terbuka = ""
	panel_kulit.visible = false
	panel_suara.visible = false
	panel_mp3.visible = false
	panel_tentang.visible = false

func kepala_panel(teks: String, induk: VBoxContainer) -> void:
	var baris := HBoxContainer.new()
	baris.add_child(judul_panel(teks))
	var r := Control.new()
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(r)
	baris.add_child(buat_tombol("Tutup", func() -> void: tutup_panel()))
	induk.add_child(baris)

func bangun_panel_kulit() -> void:
	panel_kulit = buat_panel()
	lapis.add_child(panel_kulit)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel_kulit.add_child(v)
	kepala_panel("Pilih Skin Kendang", v)
	for id in DAFTAR_KULIT.keys():
		var info: Dictionary = DAFTAR_KULIT[id]
		var kunci := String(id)
		v.add_child(buat_tombol(String(info["nama"]), func() -> void: pilih_kulit(kunci)))
	v.add_child(buat_tombol("Impor Gambar Sendiri (PNG/JPG)", func() -> void: impor_gambar()))

func pilih_kulit(id: String) -> void:
	if id == "sendiri" and berkas_kulit_sendiri == "":
		impor_gambar()
		return
	kulit_ini = id
	terapkan_kulit()
	simpan_pengaturan()
	tutup_panel()
	queue_redraw()

func impor_gambar() -> void:
	DisplayServer.file_dialog_show("Pilih gambar skin", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Gambar"]),
		func(status: bool, jalur: PackedStringArray, _idx: int) -> void:
			if status and jalur.size() > 0:
				berkas_kulit_sendiri = jalur[0]
				kulit_ini = "sendiri"
				terapkan_kulit()
				simpan_pengaturan()
				tutup_panel()
				queue_redraw())

func bangun_panel_suara() -> void:
	panel_suara = buat_panel()
	lapis.add_child(panel_suara)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_suara.add_child(v)
	kepala_panel("Custom Suara per Pad", v)
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(716, 300)
	v.add_child(gulir)
	var daftar := VBoxContainer.new()
	daftar_suara = daftar
	daftar.name = "DaftarSuara"
	daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(daftar)
	var ket := Label.new()
	ket.text = "Ganti = pilih suara bawaan lain • Impor = pakai berkas MP3/WAV dari HP"
	ket.add_theme_font_size_override("font_size", 16)
	ket.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.8))
	v.add_child(ket)

func segarkan_panel_suara() -> void:
	var daftar := daftar_suara
	for c in daftar.get_children():
		c.queue_free()
	for pad in pads:
		var def: Dictionary = pad["def"]
		var pad_ini: Dictionary = pad
		var baris := HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		var nama := Label.new()
		nama.text = String(def["nama"])
		nama.custom_minimum_size = Vector2(180, 0)
		nama.add_theme_font_size_override("font_size", 20)
		nama.add_theme_color_override("font_color", Color(0.98, 0.9, 0.75))
		baris.add_child(nama)
		var aktif := Label.new()
		aktif.text = String(pad["suara_aktif"]).get_file()
		aktif.custom_minimum_size = Vector2(220, 0)
		aktif.add_theme_font_size_override("font_size", 18)
		aktif.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		baris.add_child(aktif)
		baris.add_child(buat_tombol("Tes", func() -> void: pukul(pad_ini)))
		baris.add_child(buat_tombol("Ganti", func() -> void: ganti_suara(pad_ini)))
		baris.add_child(buat_tombol("Impor", func() -> void: impor_suara(pad_ini)))
		daftar.add_child(baris)

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

func format_waktu(detik: float) -> String:
	var d := int(detik)
	return "%d:%02d" % [d / 60, d % 60]

func bangun_panel_tentang() -> void:
	panel_tentang = buat_panel()
	lapis.add_child(panel_tentang)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_tentang.add_child(v)
	kepala_panel("Tentang & Kredit", v)
	var isi := Label.new()
	isi.text = "Kendang Virtual v2.0 — mainkan kendang tanjidor langsung dari layar.\n\nGambar kendang: ilustrasi Wikimedia Commons oleh Zhmila & Vidiyans (CC BY-SA 4.0); foto panggung: Kendang Drum Indonesia (CC BY-SA 4.0).\nTombol UI: Kenney UI Pack (CC0) — kenney.nl.\nSemua suara kendang disintesis dari kode. Panel MP3: putar lagu dari HP buat mengiringi permainan.\n\nAtur: geser posisi pad • Suara: ganti/impor bunyi per pad • Skin: ganti tampilan."
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
		pasang_letak(kulit_ini, false)
		simpan_pengaturan()
		queue_redraw()))
	h.add_child(buat_tombol("Selesai", func() -> void: keluar_atur()))
