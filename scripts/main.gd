extends Node2D
## Kendang Virtual v3.0 — composition root.
## Merakit domain (State), services (BankSuara/MesinSuara/Penyimpanan),
## dan UI (Panggung + Hud), lalu merutekan input panggung & siklus gambar.
## Genre: Kendang Bajidor — Sunda (bukan Tanjidor Betawi).

var state: State
var bank: BankSuara
var mesin: MesinSuara
var simpan: Penyimpanan
var panggung: Panggung
var hud: Hud

var _pad_seret: Dictionary = {}
var _pad_pilih: Dictionary = {}
var _jari_pad := {}
var _volume_awal := 0.9

func _ready() -> void:
	state = State.new()
	bank = BankSuara.new()
	simpan = Penyimpanan.new()
	mesin = MesinSuara.new()
	mesin.bank = bank
	add_child(mesin)
	panggung = Panggung.new()
	panggung.state = state
	add_child(panggung)
	hud = Hud.new()
	hud.pasang(state, mesin, simpan)
	add_child(hud)
	hud.bangun()
	_volume_awal = simpan.muat_pengaturan(state)
	mesin.atur_volume(_volume_awal)
	panggung.segarkan_latar()
	mesin.panaskan(state)
	_sesuaikan_ukuran()
	get_tree().root.size_changed.connect(_sesuaikan_ukuran)
	Engine.max_fps = 120
	hud.panggung_berubah.connect(func() -> void: panggung.segarkan_latar())
	hud.pengaturan_berubah.connect(func() -> void: simpan.simpan_pengaturan(state))
	hud.minta_atur.connect(_atur_mode)
	hud.minta_reset_letak.connect(func() -> void:
		state.pasang_letak(DataKit.LETAK_BAWAAN)
		simpan.simpan_pengaturan(state)
		panggung.queue_redraw())
	hud.ukuran_pad_berubah.connect(func(nilai: float) -> void:
		if not _pad_pilih.is_empty():
			_pad_pilih["skala"] = nilai
			panggung.queue_redraw())

func _sesuaikan_ukuran() -> void:
	var sz := get_viewport().get_visible_rect().size
	if sz.x > 100 and sz.y > 100:
		state.ukuran = sz
	hud.reposisi()
	panggung.queue_redraw()

func _atur_mode(nyala: bool) -> void:
	state.modus_atur = nyala
	_pad_seret = {}
	_pad_pilih = {}
	if nyala:
		hud.tutup_panel()
	else:
		simpan.simpan_pengaturan(state)
	hud.tampilkan_atur(nyala)
	hud.tampilkan_target_atur({})
	panggung.queue_redraw()

func _unhandled_input(kejadian: InputEvent) -> void:
	if hud.ada_panel():
		return
	if kejadian is InputEventScreenTouch:
		var st := kejadian as InputEventScreenTouch
		if st.pressed:
			var pad := state.pad_di(st.position, not state.modus_atur)
			if state.modus_atur:
				if not pad.is_empty():
					_pad_seret = pad
					_pad_pilih = pad
					hud.tampilkan_target_atur(pad)
					panggung.queue_redraw()
			elif not pad.is_empty():
				mesin.pukul(pad)
				_jari_pad[st.index] = String(pad["def"]["id"])
				panggung.queue_redraw()
		else:
			_jari_pad.erase(st.index)
			if state.modus_atur and not _pad_seret.is_empty():
				_pad_seret = {}
				simpan.simpan_pengaturan(state)
	elif kejadian is InputEventScreenDrag:
		var sd := kejadian as InputEventScreenDrag
		if state.modus_atur and not _pad_seret.is_empty():
			_seret_ke(sd.position)
		elif not state.modus_atur:
			var pad2 := state.pad_di(sd.position, true)
			if not pad2.is_empty() and String(_jari_pad.get(sd.index, "")) != String(pad2["def"]["id"]):
				mesin.pukul(pad2)
				_jari_pad[sd.index] = String(pad2["def"]["id"])
				panggung.queue_redraw()
	elif kejadian is InputEventMouseButton:
		var mb := kejadian as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var pad3 := state.pad_di(mb.position, not state.modus_atur)
				if state.modus_atur:
					if not pad3.is_empty():
						_pad_seret = pad3
						_pad_pilih = pad3
						hud.tampilkan_target_atur(pad3)
						panggung.queue_redraw()
				elif not pad3.is_empty():
					mesin.pukul(pad3)
					panggung.queue_redraw()
			elif state.modus_atur and not _pad_seret.is_empty():
				_pad_seret = {}
				simpan.simpan_pengaturan(state)
	elif kejadian is InputEventMouseMotion and state.modus_atur and not _pad_seret.is_empty():
		var mm := kejadian as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_seret_ke(mm.position)

func _seret_ke(pos: Vector2) -> void:
	_pad_seret["x"] = clampf(pos.x / state.ukuran.x, 0.03, 0.97)
	_pad_seret["y"] = clampf(pos.y / state.ukuran.y, 0.05, 0.97)
	panggung.queue_redraw()

func _process(delta: float) -> void:
	var berubah := false
	for pad in state.pads:
		if float(pad["kedip"]) > 0.0:
			pad["kedip"] = maxf(0.0, float(pad["kedip"]) - delta * 5.0)
			berubah = true
	if berubah:
		panggung.queue_redraw()
	hud.perbarui_musik()
