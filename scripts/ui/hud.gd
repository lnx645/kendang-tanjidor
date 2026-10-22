class_name Hud
extends CanvasLayer
## Lapisan UI: bilah atas, panel (Tema/Preset/Suara/MP3/Tentang), pemilih berkas
## dalam aplikasi, dan bilah mode Atur. Berbicara ke Main lewat sinyal;
## logika berkas/suara/preset lewat services yang disuntikkan.

signal panggung_berubah
signal pengaturan_berubah
signal minta_atur(nyala: bool)
signal minta_reset_letak
signal ukuran_pad_berubah(nilai: float)

var state: State
var mesin: MesinSuara
var simpan: Penyimpanan

var panel_aktif := ""
var _panel: Dictionary = {}
var _daftar_suara: VBoxContainer
var _daftar_preset: VBoxContainer
var _isian_nama: LineEdit
var _label_status_preset: Label
var _label_lagu: Label
var _geser_musik: GeserKustom
var _label_waktu: Label
var _tombol_ulangi: TombolKustom
var _ulangi := false
var _bar_atur: PanelContainer
var _geser_ukuran: GeserKustom
var _label_target_atur: Label
var _label_petunjuk: Label
var _label_latensi: Label
var _toast: Label
var _toast_timer: Timer
# Pemilih berkas
var _panel_berkas: PanelContainer
var _daftar_berkas: VBoxContainer
var _label_berkas_status: Label
var _mode_berkas := ""
var _pad_konteks: Dictionary = {}
var _akar_ini := ""
var _chips_akar: Dictionary = {}

func pasang(p_state: State, p_mesin: MesinSuara, p_simpan: Penyimpanan) -> void:
	state = p_state
	mesin = p_mesin
	simpan = p_simpan

func ada_panel() -> bool:
	return panel_aktif != ""

func bangun() -> void:
	_bangun_bilah_atas()
	_bangun_panel_tema()
	_bangun_panel_preset()
	_bangun_panel_suara()
	_bangun_panel_mp3()
	_bangun_panel_tentang()
	_bangun_pemilih()
	_bangun_bar_atur()
	_bangun_toast()
	reposisi()

func reposisi() -> void:
	for nama in _panel.keys():
		var p: PanelContainer = _panel[nama]
		p.position = Vector2((state.ukuran.x - 860) / 2, (state.ukuran.y - 540) / 2)
	if _bar_atur:
		_bar_atur.position = Vector2((state.ukuran.x - 940) / 2, state.ukuran.y - 148)

func kabar(teks: String, sukses: bool = true) -> void:
	_toast.text = teks
	_toast.add_theme_color_override("font_color", GayaUI.SUKSES if sukses else GayaUI.BAHAYA)
	_toast.visible = true
	_toast_timer.start()

# ---------- kerangka panel ----------

func _buat_panel(nama: String, judul_teks: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GayaUI.kotak_panel())
	p.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p.custom_minimum_size = Vector2(860, 540)
	p.size = Vector2(860, 540)
	p.visible = false
	add_child(p)
	_panel[nama] = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var baris := HBoxContainer.new()
	baris.add_child(GayaUI.judul(judul_teks))
	var ruang := Control.new()
	ruang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(ruang)
	var tutup := TombolKustom.new("Tutup", "primer")
	tutup.pressed.connect(func() -> void: tutup_panel())
	baris.add_child(tutup)
	v.add_child(baris)
	v.add_child(GayaUI.garis_emas())
	return v

func buka_panel(nama: String) -> void:
	panel_aktif = nama
	for k in _panel.keys():
		(_panel[k] as PanelContainer).visible = k == nama
	if nama == "suara":
		_segarkan_suara()
	if nama == "tentang" and _label_latensi:
		var ms := AudioServer.get_output_latency() * 1000.0
		_label_latensi.text = "Latensi keluaran audio yang dilaporkan HP ini: %.0f ms. Itu batas perangkat (digitizer sentuh + jalur audio Android) dan dibagi semua aplikasi drum. Jeda dari aplikasinya sendiri ~0: suara dimuat di depan & serangannya ≤2 ms." % ms
	if nama == "preset":
		_segarkan_preset()

func tutup_panel() -> void:
	panel_aktif = ""
	for k in _panel.keys():
		(_panel[k] as PanelContainer).visible = false

# ---------- bilah atas & toast ----------

func _bangun_bilah_atas() -> void:
	var atas := PanelContainer.new()
	atas.add_theme_stylebox_override("panel", GayaUI.kotak_bilah())
	atas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(atas)
	var isi := HBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	atas.add_child(isi)
	var judul := GayaUI.label("◆ KENDANG VIRTUAL", 26, GayaUI.EMAS_TERANG)
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var genre := GayaUI.label("Bajidor • Sunda", 15, GayaUI.TEKS_REDUP)
	genre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	isi.add_child(genre)
	var ruang := Control.new()
	ruang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_child(ruang)
	for pasangan in [["Tema", "tema"], ["Preset", "preset"], ["Suara", "suara"], ["MP3", "mp3"], ["Info", "tentang"]]:
		var nama_panel := String(pasangan[1])
		var b := TombolKustom.new(String(pasangan[0]), "sekunder")
		b.pressed.connect(func() -> void: buka_panel(nama_panel))
		isi.add_child(b)
	var atur := TombolKustom.new("Atur", "primer")
	atur.pressed.connect(func() -> void: minta_atur.emit(true))
	isi.add_child(atur)
	_label_petunjuk = GayaUI.label("Pukul kendangnya! DANG di tengah • TAK kiri • ANAK kanan", 16, Color(1, 0.95, 0.85, 0.7))
	_label_petunjuk.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label_petunjuk.offset_top = -36
	_label_petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label_petunjuk)

func _bangun_toast() -> void:
	_toast = GayaUI.label("", 19, GayaUI.SUKSES)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -84
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.visible = false
	add_child(_toast)
	_toast_timer = Timer.new()
	_toast_timer.wait_time = 3.0
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func() -> void: _toast.visible = false)
	add_child(_toast_timer)

# ---------- Panel Tema ----------

func _bangun_panel_tema() -> void:
	var v := _buat_panel("tema", "Tema Kit & Latar")
	for id in DataKit.DAFTAR_TEMA.keys():
		var info: Dictionary = DataKit.DAFTAR_TEMA[id]
		var kunci := String(id)
		if kunci == "sendiri":
			continue
		var b := TombolKustom.new(String(info["nama"]), "aktif" if kunci == state.tema_ini else "sekunder")
		b.pressed.connect(func() -> void: _pilih_tema(kunci))
		v.add_child(b)
	var impor := TombolKustom.new("Impor Gambar Latar dari HP…", "primer")
	impor.pressed.connect(func() -> void: buka_pemilih("gambar", {}))
	v.add_child(impor)
	v.add_child(GayaUI.label("Tema mengganti warna pad & latar panggung. \"Latar Sendiri\" memakai gambar pilihanmu sebagai latar.", 15, GayaUI.TEKS_REDUP))

func _pilih_tema(id: String) -> void:
	state.tema_ini = id
	pengaturan_berubah.emit()
	panggung_berubah.emit()
	tutup_panel()
	kabar("Tema: " + String(DataKit.DAFTAR_TEMA[id]["nama"]))

# ---------- Panel Preset ----------

func _bangun_panel_preset() -> void:
	var v := _buat_panel("preset", "Manage Preset")
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	_isian_nama = LineEdit.new()
	_isian_nama.placeholder_text = "Nama preset baru…"
	_isian_nama.custom_minimum_size = Vector2(430, 0)
	_isian_nama.add_theme_font_size_override("font_size", 20)
	baris.add_child(_isian_nama)
	var simpan_b := TombolKustom.new("Simpan Preset", "primer")
	simpan_b.pressed.connect(_simpan_preset_baru)
	baris.add_child(simpan_b)
	var impor_b := TombolKustom.new("Impor JSON…", "sekunder")
	impor_b.pressed.connect(func() -> void: buka_pemilih("preset", {}))
	baris.add_child(impor_b)
	v.add_child(baris)
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(816, 280)
	v.add_child(gulir)
	_daftar_preset = VBoxContainer.new()
	_daftar_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar_preset.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar_preset)
	_label_status_preset = GayaUI.label("Preset menyimpan: tema, posisi & ukuran pad, dan suara tiap pad. Ekspor menulis berkas JSON ke folder Download/KendangVirtual.", 15, GayaUI.TEKS_REDUP)
	_label_status_preset.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_label_status_preset)

func _simpan_preset_baru() -> void:
	var nm := _isian_nama.text.strip_edges()
	if nm == "" or DataKit.PRESET_PABRIK.has(nm):
		kabar("Isi nama preset dulu (bukan nama bawaan).", false)
		return
	simpan.simpan_preset(state, nm)
	state.nama_preset_ini = nm
	_isian_nama.text = ""
	pengaturan_berubah.emit()
	_segarkan_preset()
	kabar("Preset \"" + nm + "\" tersimpan.")

func _segarkan_preset() -> void:
	for c in _daftar_preset.get_children():
		c.queue_free()
	for nama in simpan.daftar_preset():
		var nm := String(nama)
		var baris := HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		var l := GayaUI.label(nm + ("  ● aktif" if nm == state.nama_preset_ini else ""), 20)
		l.custom_minimum_size = Vector2(360, 0)
		baris.add_child(l)
		var muat := TombolKustom.new("Muat", "sekunder")
		muat.pressed.connect(func() -> void:
			if simpan.muat_preset(state, nm):
				state.nama_preset_ini = nm
				pengaturan_berubah.emit()
				panggung_berubah.emit()
				tutup_panel()
				kabar("Preset \"" + nm + "\" dimuat."))
		baris.add_child(muat)
		var ekspor := TombolKustom.new("Ekspor", "sekunder")
		ekspor.pressed.connect(func() -> void: _ekspor_preset(nm))
		baris.add_child(ekspor)
		if not DataKit.PRESET_PABRIK.has(nm):
			var hapus := TombolKustom.new("Hapus", "sekunder")
			hapus.pressed.connect(func() -> void:
				simpan.hapus_preset(nm)
				if state.nama_preset_ini == nm:
					state.nama_preset_ini = ""
					pengaturan_berubah.emit()
				_segarkan_preset())
			baris.add_child(hapus)
		_daftar_preset.add_child(baris)

func _ekspor_preset(nama: String) -> void:
	var data := simpan.ambil_data_preset(state, nama)
	if data.is_empty():
		kabar("Preset tidak ditemukan.", false)
		return
	var folder := Berkas.folder_ekspor()
	if folder == "":
		kabar("Tidak ada folder yang bisa ditulis.", false)
		return
	var bersih := nama.to_lower().replace(" ", "-")
	var tujuan := folder.path_join("preset-" + bersih + ".json")
	if Berkas.tulis_teks(tujuan, JSON.stringify(data, "\t")):
		_label_status_preset.text = "Terekspor ke: " + tujuan
		kabar("Preset terekspor.")
	else:
		kabar("Gagal menulis berkas ekspor.", false)

# ---------- Panel Suara ----------

func _bangun_panel_suara() -> void:
	var v := _buat_panel("suara", "Custom Suara per Pad")
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(816, 350)
	v.add_child(gulir)
	_daftar_suara = VBoxContainer.new()
	_daftar_suara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar_suara.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar_suara)
	v.add_child(GayaUI.label("Tes = dengarkan • Ganti = varian bawaan • Impor = berkas MP3/WAV dari HP (disalin ke aplikasi)", 15, GayaUI.TEKS_REDUP))

func _segarkan_suara() -> void:
	for c in _daftar_suara.get_children():
		c.queue_free()
	for pad in state.pads:
		var def: Dictionary = pad["def"]
		var pad_ini: Dictionary = pad
		var baris := HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		var nama := GayaUI.label(String(def["nama"]), 20)
		nama.custom_minimum_size = Vector2(170, 0)
		baris.add_child(nama)
		var aktif := GayaUI.label(String(pad["suara_aktif"]).get_file(), 17, GayaUI.TEKS_REDUP)
		aktif.custom_minimum_size = Vector2(240, 0)
		baris.add_child(aktif)
		var tes := TombolKustom.new("Tes", "sekunder")
		tes.pressed.connect(func() -> void: mesin.pukul(pad_ini))
		baris.add_child(tes)
		var ganti := TombolKustom.new("Ganti", "sekunder")
		ganti.pressed.connect(func() -> void: _ganti_suara(pad_ini))
		baris.add_child(ganti)
		var impor := TombolKustom.new("Impor", "primer")
		impor.pressed.connect(func() -> void: buka_pemilih("suara", pad_ini))
		baris.add_child(impor)
		_daftar_suara.add_child(baris)

func _ganti_suara(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var pilihan: Array = def["suara"]
	var kini := String(pad["suara_aktif"]).get_file()
	var idx := pilihan.find(kini)
	idx = (idx + 1) % pilihan.size()
	pad["suara_aktif"] = "res://audio/" + String(pilihan[idx])
	mesin.ganti_suara_pad(pad)
	mesin.pukul(pad)
	pengaturan_berubah.emit()
	_segarkan_suara()

# ---------- Panel MP3 ----------

func _bangun_panel_mp3() -> void:
	var v := _buat_panel("mp3", "Putar MP3 — Main Sambil Diiringi Lagu")
	_label_lagu = GayaUI.label("Belum ada lagu dipilih.", 20, GayaUI.EMAS_TERANG)
	v.add_child(_label_lagu)
	_geser_musik = GeserKustom.new()
	_geser_musik.nilai_min = 0.0
	_geser_musik.nilai_maks = 1.0
	_geser_musik.nilai = 0.0
	_geser_musik.nilai_berubah.connect(func(nilai: float) -> void:
		if mesin.durasi_musik() > 0.0 and absf(nilai - mesin.posisi_musik()) > 1.5:
			mesin.lompat_musik(nilai))
	v.add_child(_geser_musik)
	_label_waktu = GayaUI.label("0:00 / 0:00", 16, GayaUI.TEKS_REDUP)
	v.add_child(_label_waktu)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	var pilih := TombolKustom.new("Pilih Lagu MP3…", "primer")
	pilih.pressed.connect(func() -> void: buka_pemilih("lagu", {}))
	baris.add_child(pilih)
	var putar := TombolKustom.new("Putar/Jeda", "sekunder")
	putar.pressed.connect(func() -> void: mesin.jeda_lanjut())
	baris.add_child(putar)
	var stop_b := TombolKustom.new("Berhenti", "sekunder")
	stop_b.pressed.connect(func() -> void: mesin.berhenti_musik())
	baris.add_child(stop_b)
	_tombol_ulangi = TombolKustom.new("Ulangi: MATI", "sekunder")
	_tombol_ulangi.pressed.connect(func() -> void:
		_ulangi = not _ulangi
		_tombol_ulangi.text = "Ulangi: NYALA" if _ulangi else "Ulangi: MATI"
		_tombol_ulangi.varian = "aktif" if _ulangi else "sekunder")
	baris.add_child(_tombol_ulangi)
	v.add_child(baris)
	v.add_child(GayaUI.label("Lagu tetap berputar saat panel ditutup — pukul kendangnya mengiringi!", 15, GayaUI.TEKS_REDUP))

func perbarui_musik() -> void:
	if panel_aktif != "mp3":
		return
	var dur := mesin.durasi_musik()
	if dur > 0.0:
		_geser_musik.nilai_maks = dur
		_geser_musik.atur_tanpa_sinyal(mesin.posisi_musik())
		_label_waktu.text = _format_waktu(mesin.posisi_musik()) + " / " + _format_waktu(dur)

func _format_waktu(detik: float) -> String:
	var d := int(detik)
	return "%d:%02d" % [d / 60, d % 60]

# ---------- Panel Tentang ----------

func _bangun_panel_tentang() -> void:
	var v := _buat_panel("tentang", "Tentang & Kredit")
	var isi := GayaUI.label("Kendang Virtual v3.1 — kit Kendang Bajidor (Sunda) tampak atas ala Real Drum. Bajidor itu kesenian Sunda — bukan Tanjidor Betawi.\n\nFitur: pukul multi-sentuh + gesek antar pad, Tema kit, Preset (simpan/muat/ekspor/impor JSON), custom suara per pad (bawaan/impor MP3-WAV), mode Atur, pemutar MP3 pengiring.\n\nUI \"Emas Panggung\": seluruh tombol, panel & slider digambar kustom dari kode. Semua suara kendang disintesis dari kode.", 18)
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(isi)
	_label_latensi = GayaUI.label("", 16, GayaUI.EMAS_TERANG)
	_label_latensi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_label_latensi)

# ---------- Bilah Atur ----------

func _bangun_bar_atur() -> void:
	_bar_atur = PanelContainer.new()
	_bar_atur.add_theme_stylebox_override("panel", GayaUI.kotak_panel())
	_bar_atur.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_bar_atur.custom_minimum_size = Vector2(940, 92)
	_bar_atur.size = Vector2(940, 92)
	_bar_atur.visible = false
	add_child(_bar_atur)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_bar_atur.add_child(h)
	_label_target_atur = GayaUI.label("Pad: —", 19, GayaUI.EMAS_TERANG)
	_label_target_atur.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_label_target_atur)
	h.add_child(GayaUI.label("Ukuran:", 18))
	_geser_ukuran = GeserKustom.new()
	_geser_ukuran.nilai_min = 0.6
	_geser_ukuran.nilai_maks = 1.7
	_geser_ukuran.nilai = 1.0
	_geser_ukuran.custom_minimum_size = Vector2(240, 36)
	_geser_ukuran.nilai_berubah.connect(func(nilai: float) -> void: ukuran_pad_berubah.emit(nilai))
	h.add_child(_geser_ukuran)
	h.add_child(GayaUI.label("Volume:", 18))
	var geser_vol := GeserKustom.new()
	geser_vol.nilai_min = 0.0
	geser_vol.nilai_maks = 1.0
	geser_vol.nilai = 0.9
	geser_vol.custom_minimum_size = Vector2(140, 36)
	geser_vol.nilai_berubah.connect(func(nilai: float) -> void:
		mesin.atur_volume(nilai))
	h.add_child(geser_vol)
	var reset := TombolKustom.new("Reset", "sekunder")
	reset.pressed.connect(func() -> void: minta_reset_letak.emit())
	h.add_child(reset)
	var selesai := TombolKustom.new("Selesai", "primer")
	selesai.pressed.connect(func() -> void: minta_atur.emit(false))
	h.add_child(selesai)

func tampilkan_atur(nyala: bool) -> void:
	_bar_atur.visible = nyala

func tampilkan_target_atur(pad: Dictionary) -> void:
	if pad.is_empty():
		_label_target_atur.text = "Pad: —"
		return
	_label_target_atur.text = "Pad: " + String(pad["def"]["nama"])
	_geser_ukuran.atur_tanpa_sinyal(float(pad["skala"]))

# ---------- Pemilih berkas dalam aplikasi (pengganti dialog native) ----------

func _bangun_pemilih() -> void:
	_panel_berkas = PanelContainer.new()
	_panel_berkas.add_theme_stylebox_override("panel", GayaUI.kotak_panel())
	_panel_berkas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel_berkas.custom_minimum_size = Vector2(860, 540)
	_panel_berkas.size = Vector2(860, 540)
	_panel_berkas.visible = false
	add_child(_panel_berkas)
	_panel["berkas"] = _panel_berkas
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel_berkas.add_child(v)
	var baris := HBoxContainer.new()
	baris.add_child(GayaUI.judul("Pilih Berkas"))
	var ruang := Control.new()
	ruang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(ruang)
	var kembali := TombolKustom.new("Kembali", "primer")
	kembali.pressed.connect(func() -> void: _kembali_dari_pemilih())
	baris.add_child(kembali)
	v.add_child(baris)
	v.add_child(GayaUI.garis_emas())
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	v.add_child(chips)
	for akar in Berkas.daftar_akar():
		var id_akar := String(akar["id"])
		var chip := TombolKustom.new(String(akar["nama"]), "sekunder")
		chip.pressed.connect(func() -> void:
			_akar_ini = id_akar
			_segarkan_berkas())
		chips.add_child(chip)
		_chips_akar[id_akar] = chip
	var gulir := ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(816, 300)
	v.add_child(gulir)
	_daftar_berkas = VBoxContainer.new()
	_daftar_berkas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar_berkas.add_theme_constant_override("separation", 6)
	gulir.add_child(_daftar_berkas)
	_label_berkas_status = GayaUI.label("", 15, GayaUI.TEKS_REDUP)
	_label_berkas_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_label_berkas_status)

func buka_pemilih(mode: String, konteks: Dictionary) -> void:
	_mode_berkas = mode
	_pad_konteks = konteks
	if OS.get_name() == "Android":
		OS.request_permissions()
	if _akar_ini == "":
		_akar_ini = "unduh"
	buka_panel("berkas")
	_segarkan_berkas()

func _kembali_dari_pemilih() -> void:
	match _mode_berkas:
		"suara":
			buka_panel("suara")
		"lagu":
			buka_panel("mp3")
		"preset":
			buka_panel("preset")
		_:
			buka_panel("tema")

func _ekstensi_mode() -> Array:
	match _mode_berkas:
		"suara", "lagu":
			return ["mp3", "wav"]
		"gambar":
			return ["png", "jpg", "jpeg", "webp"]
		"preset":
			return ["json"]
	return []

func _segarkan_berkas() -> void:
	for id_akar in _chips_akar.keys():
		(_chips_akar[id_akar] as TombolKustom).varian = "aktif" if id_akar == _akar_ini else "sekunder"
	for c in _daftar_berkas.get_children():
		c.queue_free()
	var path_akar := ""
	for akar in Berkas.daftar_akar():
		if String(akar["id"]) == _akar_ini:
			path_akar = String(akar["path"])
	var ditemukan := Berkas.pindai_dalam(path_akar, _ekstensi_mode(), 2)
	if ditemukan.is_empty():
		_label_berkas_status.text = "Tidak ada berkas cocok di folder ini (" + path_akar + "). Taruh berkas di Download lalu buka lagi. Ketuk nama folder lain di atas untuk berpindah."
	else:
		_label_berkas_status.text = "Folder: " + path_akar + " — " + str(mini(ditemukan.size(), 200)) + " berkas. Ketuk untuk memilih."
	var hitung := 0
	for item in ditemukan:
		if hitung >= 200:
			break
		hitung += 1
		var jalur := String(item["path"])
		var baris := TombolKustom.new("  " + String(item["nama"]), "sekunder")
		baris.alignment = HORIZONTAL_ALIGNMENT_LEFT
		baris.pressed.connect(func() -> void: _pilih_berkas(jalur))
		_daftar_berkas.add_child(baris)

func _pilih_berkas(jalur: String) -> void:
	match _mode_berkas:
		"suara":
			var salinan := Berkas.salin_masuk(jalur, "suara")
			if salinan == "":
				kabar("Berkas tidak terbaca: " + jalur.get_file(), false)
				return
			_pad_konteks["suara_aktif"] = salinan
			mesin.ganti_suara_pad(_pad_konteks)
			mesin.pukul(_pad_konteks)
			pengaturan_berubah.emit()
			buka_panel("suara")
			kabar("Suara " + String(_pad_konteks["def"]["nama"]) + " diganti: " + jalur.get_file())
		"gambar":
			var salinan2 := Berkas.salin_masuk(jalur, "latar")
			if salinan2 == "":
				kabar("Gambar tidak terbaca: " + jalur.get_file(), false)
				return
			state.berkas_latar_sendiri = salinan2
			state.tema_ini = "sendiri"
			pengaturan_berubah.emit()
			panggung_berubah.emit()
			tutup_panel()
			kabar("Latar diganti: " + jalur.get_file())
		"lagu":
			if mesin.putar_musik(jalur, _ulangi):
				_label_lagu.text = "Memutar: " + jalur.get_file()
				buka_panel("mp3")
				kabar("Memutar " + jalur.get_file())
			else:
				kabar("Lagu tidak bisa dibaca: " + jalur.get_file(), false)
		"preset":
			var teks := Berkas.baca_teks(jalur)
			var data = JSON.parse_string(teks)
			if typeof(data) != TYPE_DICTIONARY:
				kabar("Berkas preset tidak valid.", false)
				return
			var d: Dictionary = data
			simpan.terapkan_data(state, d)
			var nm := String(d.get("nama", "Preset Impor"))
			simpan.simpan_preset(state, nm)
			state.nama_preset_ini = nm
			pengaturan_berubah.emit()
			panggung_berubah.emit()
			buka_panel("preset")
			kabar("Preset \"" + nm + "\" diimpor.")
