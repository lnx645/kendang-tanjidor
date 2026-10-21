extends Node2D
## Kendang Tanjidor — game ritme: sentuh sisi kendang (TAK kiri / DANG kanan)
## mengikuti not yang jatuh mengikuti irama tanjidor. Ada Mode Bebas juga.

const Y_TARGET := 1000.0
const WAKTU_TEMPUH := 1.5 # detik not meluncur ke target
const JENDELA_HEBAT := 0.075
const JENDELA_BAGUS := 0.16
const JENDELA_LEPAS := 0.18

var layar := "menu" # menu | main | bebas | hasil | jeda
var lebar := 720.0
var tinggi := 1280.0

var suara: Dictionary = {}
var pemain_sfx: Array = []
var pemutar_lagu: AudioStreamPlayer

var daftar_lagu := [
	{"file": "lagu1", "judul": "Jali Pagi", "bpm": 100},
	{"file": "lagu2", "judul": "Ondel Lewat", "bpm": 118},
	{"file": "lagu3", "judul": "Tanjidor Ngebut", "bpm": 136},
]
var lagu_ini := 0
var nots: Array = [] # {waktu: float, sisi: int (0=DANG kanan, 1=TAK kiri), kena: int}
var skor := 0
var kombo := 0
var kombo_maks := 0
var jml_hebat := 0
var jml_bagus := 0
var jml_lepas := 0
var kilat := [0.0, 0.0] # indeks tampilan: 0 = kiri(TAK), 1 = kanan(DANG)
var popups: Array = []
var jeda_aktif := false
var selesai_t := -1.0

var lapis_ui: CanvasLayer
var panel_menu: VBoxContainer
var panel_hasil: VBoxContainer
var panel_jeda: VBoxContainer
var deret_trompet: HBoxContainer
var label_skor: Label
var label_kombo: Label
var label_judul: Label
var label_hasil: Label
var btn_jeda: Button

func _muat_suara() -> void:
	for nama in ["dang", "tak", "pak", "kecrek", "gong", "benar", "hebat", "salah", "lagu1", "lagu2", "lagu3"]:
		suara[nama] = load("res://audio/" + nama + ".wav")
	for midi in [72, 74, 76, 79, 81]:
		suara["trompet_%d" % midi] = load("res://audio/trompet_%d.wav" % midi)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pemain_sfx.append(p)
	pemutar_lagu = AudioStreamPlayer.new()
	add_child(pemutar_lagu)
	pemutar_lagu.finished.connect(_lagu_selesai)

func bunyi(nama: String, volume := 0.0) -> void:
	for p in pemain_sfx:
		if not p.playing:
			p.stream = suara[nama]
			p.volume_db = volume
			p.play()
			return

func _ready() -> void:
	_muat_suara()
	_bangun_ui()
	_ke_menu()

func _tombol(teks: String, warna: Color, ukuran := 26) -> Button:
	var b := Button.new()
	b.text = teks
	b.add_theme_font_size_override("font_size", ukuran)
	b.custom_minimum_size = Vector2(560, 76)
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = warna
	gaya.set_corner_radius_all(18)
	gaya.set_border_width_all(3)
	gaya.border_color = Color(1, 1, 1, 0.5)
	gaya.content_margin_top = 10
	gaya.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", gaya)
	var tekan := gaya.duplicate() as StyleBoxFlat
	tekan.bg_color = warna.lightened(0.25)
	b.add_theme_stylebox_override("pressed", tekan)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	return b

func _label(teks: String, ukuran: int, warna := Color.WHITE, tengah := true) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if tengah:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _bangun_ui() -> void:
	lapis_ui = CanvasLayer.new()
	add_child(lapis_ui)
	# HUD saat main
	label_skor = _label("Skor 0", 30, Color(1, 0.95, 0.6), false)
	label_skor.position = Vector2(24, 14)
	lapis_ui.add_child(label_skor)
	label_judul = _label("", 22, Color(1, 1, 1, 0.85))
	label_judul.position = Vector2(24, 56)
	lapis_ui.add_child(label_judul)
	label_kombo = _label("", 54, Color(1, 0.85, 0.25))
	label_kombo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label_kombo.position = Vector2(-200, 120)
	label_kombo.custom_minimum_size = Vector2(400, 70)
	lapis_ui.add_child(label_kombo)
	btn_jeda = _tombol("II", Color(0, 0, 0, 0.35), 24)
	btn_jeda.custom_minimum_size = Vector2(64, 64)
	btn_jeda.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_jeda.position = Vector2(-84, 12)
	btn_jeda.pressed.connect(_jeda)
	lapis_ui.add_child(btn_jeda)
	# Panel menu
	panel_menu = VBoxContainer.new()
	panel_menu.set_anchors_preset(Control.PRESET_CENTER)
	panel_menu.position = Vector2(-290, -430)
	panel_menu.custom_minimum_size = Vector2(580, 0)
	panel_menu.add_theme_constant_override("separation", 14)
	lapis_ui.add_child(panel_menu)
	var judul := _label("KENDANG", 62, Color(1, 0.85, 0.25))
	panel_menu.add_child(judul)
	var judul2 := _label("TANJIDOR", 62, Color(1, 0.55, 0.35))
	panel_menu.add_child(judul2)
	panel_menu.add_child(_label("Sentuh kendang mengikuti irama tanjidor!", 21, Color(1, 1, 1, 0.9)))
	for i in 3:
		var info: Dictionary = daftar_lagu[i]
		var b := _tombol("%s — %d BPM" % [info.judul, info.bpm], Color(0.72, 0.2, 0.28))
		var idx := i
		b.pressed.connect(func() -> void: _mulai_lagu(idx))
		panel_menu.add_child(b)
	var btn_bebas := _tombol("Mode Bebas — Main Sesukamu", Color(0.15, 0.5, 0.45))
	btn_bebas.pressed.connect(_ke_bebas)
	panel_menu.add_child(btn_bebas)
	panel_menu.add_child(_label("TAK = kendang kecil (kiri) • DANG = kendang besar (kanan)", 17, Color(1, 1, 1, 0.7)))
	# Panel hasil
	panel_hasil = VBoxContainer.new()
	panel_hasil.set_anchors_preset(Control.PRESET_CENTER)
	panel_hasil.position = Vector2(-290, -330)
	panel_hasil.custom_minimum_size = Vector2(580, 0)
	panel_hasil.add_theme_constant_override("separation", 14)
	lapis_ui.add_child(panel_hasil)
	panel_hasil.add_child(_label("LAGU SELESAI!", 44, Color(1, 0.85, 0.25)))
	label_hasil = _label("", 27)
	panel_hasil.add_child(label_hasil)
	var btn_ulang := _tombol("Main Lagi", Color(0.72, 0.2, 0.28))
	btn_ulang.pressed.connect(func() -> void: _mulai_lagu(lagu_ini))
	panel_hasil.add_child(btn_ulang)
	var btn_menu2 := _tombol("Menu Utama", Color(0.25, 0.3, 0.6))
	btn_menu2.pressed.connect(_ke_menu)
	panel_hasil.add_child(btn_menu2)
	# Panel jeda
	panel_jeda = VBoxContainer.new()
	panel_jeda.set_anchors_preset(Control.PRESET_CENTER)
	panel_jeda.position = Vector2(-290, -200)
	panel_jeda.custom_minimum_size = Vector2(580, 0)
	panel_jeda.add_theme_constant_override("separation", 14)
	lapis_ui.add_child(panel_jeda)
	panel_jeda.add_child(_label("JEDA", 40, Color(1, 0.85, 0.25)))
	var btn_lanjut := _tombol("Lanjut Main", Color(0.15, 0.55, 0.3))
	btn_lanjut.pressed.connect(_lanjut)
	panel_jeda.add_child(btn_lanjut)
	var btn_menu3 := _tombol("Menu Utama", Color(0.25, 0.3, 0.6))
	btn_menu3.pressed.connect(_ke_menu)
	panel_jeda.add_child(btn_menu3)
	# Deret trompet (Mode Bebas)
	deret_trompet = HBoxContainer.new()
	deret_trompet.set_anchors_preset(Control.PRESET_CENTER_TOP)
	deret_trompet.position = Vector2(-290, 210)
	deret_trompet.add_theme_constant_override("separation", 10)
	var nama_nada := ["Do", "Re", "Mi", "Sol", "La"]
	var midis := [72, 74, 76, 79, 81]
	for k in 5:
		var bt := _tombol("♪\n" + nama_nada[k], Color(0.8, 0.55, 0.1), 19)
		bt.custom_minimum_size = Vector2(104, 84)
		var m: int = midis[k]
		bt.pressed.connect(func() -> void: bunyi("trompet_%d" % m))
		deret_trompet.add_child(bt)
	lapis_ui.add_child(deret_trompet)

func _tampilkan() -> void:
	panel_menu.visible = layar == "menu"
	panel_hasil.visible = layar == "hasil"
	panel_jeda.visible = layar == "jeda"
	deret_trompet.visible = layar == "bebas"
	btn_jeda.visible = layar in ["main", "jeda"]
	label_skor.visible = layar in ["main", "jeda", "bebas"]
	label_kombo.visible = layar == "main"
	label_judul.visible = layar in ["main", "jeda", "bebas"]

func _ke_menu() -> void:
	pemutar_lagu.stop()
	layar = "menu"
	label_judul.text = ""
	_tampilkan()

func _ke_bebas() -> void:
	pemutar_lagu.stop()
	layar = "bebas"
	label_judul.text = "Mode Bebas — pukul kendangnya!"
	bunyi("gong")
	_tampilkan()

func _mulai_lagu(idx: int) -> void:
	lagu_ini = idx
	var info: Dictionary = daftar_lagu[idx]
	var berkas := FileAccess.open("res://data/%s.json" % info.file, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(berkas.get_as_text())
	nots.clear()
	var spb := 60.0 / float(data.bpm)
	for n in data.notes:
		nots.append({"waktu": float(n.b) * spb, "sisi": int(n.s), "kena": 0})
	skor = 0
	kombo = 0
	kombo_maks = 0
	jml_hebat = 0
	jml_bagus = 0
	jml_lepas = 0
	selesai_t = -1.0
	layar = "main"
	label_judul.text = "%s — %d BPM" % [info.judul, info.bpm]
	pemutar_lagu.stream = suara[info.file]
	pemutar_lagu.play()
	bunyi("gong")
	_tampilkan()

func _jeda() -> void:
	if layar != "main":
		return
	layar = "jeda"
	pemutar_lagu.stream_paused = true
	_tampilkan()

func _lanjut() -> void:
	if layar != "jeda":
		return
	layar = "main"
	pemutar_lagu.stream_paused = false
	_tampilkan()

func _lagu_selesai() -> void:
	if layar == "main":
		selesai_t = 0.001 # tampilkan hasil di frame berikutnya

func _tampil_hasil() -> void:
	layar = "hasil"
	var total := jml_hebat + jml_bagus + jml_lepas
	var akurasi := 0.0
	if total > 0:
		akurasi = (jml_hebat * 1.0 + jml_bagus * 0.55) / total * 100.0
	var nilai := "D"
	if akurasi >= 95: nilai = "S"
	elif akurasi >= 85: nilai = "A"
	elif akurasi >= 70: nilai = "B"
	elif akurasi >= 50: nilai = "C"
	label_hasil.text = "Nilai: %s\n\nSkor: %d\nKombo Maks: %d\nHebat: %d • Bagus: %d • Lepas: %d\nAkurasi: %.0f%%" % [nilai, skor, kombo_maks, jml_hebat, jml_bagus, jml_lepas, akurasi]
	bunyi("gong")
	_tampilkan()

func _posisi_lagu() -> float:
	return pemutar_lagu.get_playback_position()

# Tampilan sisi: 0 = kiri (TAK), 1 = kanan (DANG). Not: sisi 1=TAK, 0=DANG.
func _ketuk(layar_sisi: int) -> void:
	var pusat_x := lebar * (0.25 if layar_sisi == 0 else 0.75)
	kilat[layar_sisi] = 1.0
	Input.vibrate_handheld(25)
	if layar_sisi == 0:
		bunyi("tak")
	else:
		bunyi("dang")
	if layar != "main":
		return
	var pos := _posisi_lagu()
	var sisi_not := 1 if layar_sisi == 0 else 0
	var terbaik: Dictionary = {}
	var selisih_min := 999.0
	for n in nots:
		if n.kena == 0 and n.sisi == sisi_not:
			var d: float = abs(n.waktu - pos)
			if d < selisih_min:
				selisih_min = d
				terbaik = n
	if terbaik.is_empty() or selisih_min > JENDELA_BAGUS:
		return
	terbaik.kena = 1
	kombo += 1
	kombo_maks = maxi(kombo_maks, kombo)
	if selisih_min <= JENDELA_HEBAT:
		skor += 300
		jml_hebat += 1
		_popup("HEBAT!", pusat_x, Color(1, 0.8, 0.2))
		bunyi("hebat", -8.0)
	else:
		skor += 100
		jml_bagus += 1
		_popup("Bagus", pusat_x, Color(0.45, 0.95, 0.5))
		bunyi("benar", -8.0)

func _popup(teks: String, x: float, warna: Color) -> void:
	popups.append({"teks": teks, "x": x, "y": Y_TARGET - 190.0, "sisa": 0.8, "warna": warna})

func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var tekan := false
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
		tekan = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		tekan = true
	if not tekan:
		return
	if layar == "main":
		if pos.y < 110 and pos.x > lebar - 110:
			return # tombol jeda
		_ketuk(0 if pos.x < lebar / 2.0 else 1)
	elif layar == "bebas":
		if pos.y > 800:
			_ketuk(0 if pos.x < lebar / 2.0 else 1)

func _process(delta: float) -> void:
	var ukuran := get_viewport_rect().size
	lebar = ukuran.x
	tinggi = ukuran.y
	for s in 2:
		kilat[s] = maxf(kilat[s] - delta * 5.0, 0.0)
	for i in range(popups.size() - 1, -1, -1):
		popups[i].sisa -= delta
		popups[i].y -= delta * 60.0
		if popups[i].sisa <= 0.0:
			popups.remove_at(i)
	if layar == "main":
		var pos := _posisi_lagu()
		for n in nots:
			if n.kena == 0 and pos - n.waktu > JENDELA_LEPAS:
				n.kena = 2
				jml_lepas += 1
				if kombo >= 5:
					_popup("Lepas", lebar * (0.25 if n.sisi == 1 else 0.75), Color(0.8, 0.8, 0.85))
				kombo = 0
		label_skor.text = "Skor %d" % skor
		label_kombo.text = ("%d KOMBO" % kombo) if kombo >= 3 else ""
		if selesai_t > 0.0:
			selesai_t += delta
			if selesai_t > 0.7:
				selesai_t = -1.0
				_tampil_hasil()
	queue_redraw()

func _draw() -> void:
	# Langit sore bertingkat
	var pita := 14
	for i in pita:
		var k := float(i) / pita
		var warna := Color(0.16, 0.11, 0.35).lerp(Color(1.0, 0.55, 0.25), k)
		draw_rect(Rect2(0, tinggi * i / pita, lebar, tinggi / pita + 2), warna)
	# Matahari
	draw_circle(Vector2(lebar * 0.78, 205), 120, Color(1, 0.85, 0.4, 0.25))
	draw_circle(Vector2(lebar * 0.78, 205), 82, Color(1, 0.9, 0.55, 0.9))
	# Umbul-umbul segitiga
	var warna_bendera := [Color(0.95, 0.25, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.85, 0.4), Color(0.3, 0.55, 1), Color(1, 1, 1)]
	for baris in 2:
		var y0 := 96.0 + baris * 54.0
		var titik: Array = []
		for x in range(0, int(lebar) + 40, 40):
			titik.append(Vector2(x, y0 + sin(float(x) * 0.01 + baris) * 12.0))
		for i in titik.size() - 1:
			draw_line(titik[i], titik[i + 1], Color(0, 0, 0, 0.35), 2.0)
			var tengah: Vector2 = (titik[i] + titik[i + 1]) / 2.0
			draw_colored_polygon(PackedVector2Array([titik[i] + Vector2(4, 2), titik[i + 1] - Vector2(4, -2), tengah + Vector2(0, 26)]), warna_bendera[(i + baris * 2) % warna_bendera.size()])
	# Siluet atap rumah di bawah
	draw_rect(Rect2(0, tinggi - 90, lebar, 90), Color(0.1, 0.06, 0.2))
	for rx in range(0, int(lebar), 120):
		draw_colored_polygon(PackedVector2Array([Vector2(rx, tinggi - 88), Vector2(rx + 60, tinggi - 128), Vector2(rx + 120, tinggi - 88)]), Color(0.1, 0.06, 0.2))
	if layar in ["main", "jeda"]:
		_gambar_jalur()
	_gambar_kendang()
	# Popup penilaian
	var font := ThemeDB.fallback_font
	for p in popups:
		var a: float = clampf(p.sisa / 0.8, 0.0, 1.0)
		var c: Color = p.warna
		c.a = a
		draw_string(font, Vector2(p.x - 90, p.y), p.teks, HORIZONTAL_ALIGNMENT_CENTER, 180, 40, c)

func _gambar_jalur() -> void:
	for sisi in 2:
		var cx := lebar * (0.25 if sisi == 0 else 0.75)
		draw_rect(Rect2(cx - 95, 130, 190, Y_TARGET - 90), Color(1, 1, 1, 0.05))
		draw_line(Vector2(cx - 95, 130), Vector2(cx - 95, Y_TARGET + 40), Color(1, 1, 1, 0.14), 2.0)
		draw_line(Vector2(cx + 95, 130), Vector2(cx + 95, Y_TARGET + 40), Color(1, 1, 1, 0.14), 2.0)
	# Not-not yang sedang jatuh
	var pos := _posisi_lagu()
	var font := ThemeDB.fallback_font
	for n in nots:
		if n.kena != 0:
			continue
		var sisa: float = n.waktu - pos
		if sisa > WAKTU_TEMPUH or sisa < -0.2:
			continue
		var cx := lebar * (0.25 if n.sisi == 1 else 0.75)
		var y := Y_TARGET - sisa / WAKTU_TEMPUH * (Y_TARGET + 60.0)
		if n.sisi == 0: # DANG — besar oranye
			draw_circle(Vector2(cx, y), 40, Color(1, 0.62, 0.15))
			draw_circle(Vector2(cx, y), 40, Color(0.5, 0.2, 0), false, 5.0)
			draw_circle(Vector2(cx, y), 16, Color(1, 0.85, 0.4))
			draw_string(font, Vector2(cx - 40, y + 72), "DANG", HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color(1, 0.85, 0.5))
		else: # TAK — kecil kuning
			draw_circle(Vector2(cx, y), 30, Color(1, 0.9, 0.35))
			draw_circle(Vector2(cx, y), 30, Color(0.5, 0.4, 0), false, 4.0)
			draw_circle(Vector2(cx, y), 12, Color(1, 1, 0.75))
			draw_string(font, Vector2(cx - 40, y + 62), "TAK", HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color(1, 0.95, 0.6))
	# Bilah progres lagu
	if pemutar_lagu.stream:
		var dur: float = pemutar_lagu.stream.get_length()
		if dur > 0:
			draw_rect(Rect2(0, 0, lebar, 8), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(0, 0, lebar * clampf(pos / dur, 0, 1), 8), Color(1, 0.8, 0.2))

func _gambar_kendang() -> void:
	var font := ThemeDB.fallback_font
	var cfg := [
		{"cx": lebar * 0.25, "r": 88.0, "nama": "TAK", "sisi": 0},
		{"cx": lebar * 0.75, "r": 118.0, "nama": "DANG", "sisi": 1},
	]
	for c in cfg:
		var pusat := Vector2(c.cx, Y_TARGET + 80.0)
		var nyala: float = kilat[c.sisi]
		var r: float = c.r * (1.0 + nyala * 0.07)
		# Badan kayu
		draw_ellipse_ok(pusat + Vector2(0, 26), r * 1.06, r * 0.92, Color(0.42, 0.22, 0.1))
		# Kulit kendang berlapis
		draw_circle(pusat, r, Color(0.98, 0.89, 0.7))
		draw_circle(pusat, r * 0.82, Color(0.95, 0.83, 0.58))
		draw_circle(pusat, r * 0.55, Color(0.92, 0.78, 0.5))
		# Tali pengikat menyilang di tepi
		for i in 10:
			var a1 := TAU * i / 10.0
			var a2 := TAU * (i + 1) / 10.0
			draw_line(pusat + Vector2(cos(a1), sin(a1)) * r * 0.97, pusat + Vector2(cos(a2), sin(a2)) * r * 0.97, Color(0.5, 0.25, 0.08), 5.0)
		# Kilau saat dipukul + cincin target
		if nyala > 0.0:
			draw_circle(pusat, r, Color(1, 1, 1, nyala * 0.35))
		var alpha := 0.35 + 0.25 * sin(Time.get_ticks_msec() * 0.006)
		draw_circle(pusat, r + 7, Color(1, 1, 1, alpha if layar == "main" else 0.18), false, 3.0)
		draw_string(font, Vector2(c.cx - 70, pusat.y + r + 46), c.nama, HORIZONTAL_ALIGNMENT_CENTER, 140, 34, Color(1, 1, 1, 0.95))

func draw_ellipse_ok(pusat: Vector2, rx: float, ry: float, warna: Color) -> void:
	var titik := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		titik.append(pusat + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(titik, warna)
