class_name Panggung
extends Node2D
## Panggung: menggambar latar + kit pad dari State. Hanya membaca state — tidak mengubahnya.

var state: State
var tekstur_latar: Texture2D = null

func segarkan_latar() -> void:
	tekstur_latar = null
	if state.tema_ini == "sendiri" and state.berkas_latar_sendiri != "" and FileAccess.file_exists(state.berkas_latar_sendiri):
		var gbr := Image.new()
		if gbr.load(state.berkas_latar_sendiri) == OK:
			tekstur_latar = ImageTexture.create_from_image(gbr)
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	var lebar := state.ukuran.x
	var tinggi := state.ukuran.y
	var p := state.palet()
	if tekstur_latar != null:
		var uk := tekstur_latar.get_size()
		var s := maxf(lebar / uk.x, tinggi / uk.y)
		draw_texture_rect(tekstur_latar, Rect2((lebar - uk.x * s) / 2, (tinggi - uk.y * s) / 2, uk.x * s, uk.y * s), false)
	else:
		for i in 24:
			var t := float(i) / 24.0
			var c: Color = p["latar1"]
			c = c.lerp(p["latar2"], t)
			draw_rect(Rect2(0, tinggi * t, lebar, tinggi / 24.0 + 1), c)
		var titik := Color(1, 1, 1, 0.045)
		for gx in range(24, int(lebar), 48):
			for gy in range(88, int(tinggi) - 8, 48):
				draw_circle(Vector2(gx, gy), 5.0, titik)
		# Sorotan panggung di tengah + garis cahaya
		for k in 6:
			var rr := lerpf(90.0, 460.0, float(k) / 5.0)
			draw_circle(Vector2(lebar * 0.47, tinggi * 0.52), rr, Color(1.0, 0.85, 0.55, 0.016))
		draw_rect(Rect2(0, tinggi * 0.80, lebar, 3), Color(0.35, 0.55, 0.95, 0.30))
	for pad in state.pads:
		_gambar_pad(pad)
	for pad in state.pads:
		_gambar_nama(pad)
	if state.modus_atur:
		draw_string(ThemeDB.fallback_font, Vector2(24, 112), "MODE ATUR: seret pad untuk memindah", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.95, 0.8))

func _gambar_nama(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var g := state.geo(pad)
	var tengah: Vector2 = g["c"]
	var ry := float(g["ry"])
	var geser := ry + 24
	if String(def["id"]) == "pak":
		geser = 6
	var pos := tengah + Vector2(0, geser)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1, 1), String(def["nama"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0, 0, 0, 0.7))
	draw_string(ThemeDB.fallback_font, pos, String(def["nama"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1, 0.97, 0.9, 0.95))

func _elips_garis(tengah: Vector2, rx: float, ry: float, warna: Color, lebar_garis: float = 3.0) -> void:
	var titik := PackedVector2Array()
	for i in 41:
		var a := TAU * float(i) / 40.0
		titik.append(tengah + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(titik, warna, lebar_garis, true)

func _gambar_pad(pad: Dictionary) -> void:
	var def: Dictionary = pad["def"]
	var p := state.palet()
	var g := state.geo(pad)
	var tengah: Vector2 = g["c"]
	var rx := float(g["rx"])
	var ry := float(g["ry"])
	var kedip := float(pad["kedip"])
	var bentuk := String(def["bentuk"])
	var r := rx
	draw_circle(tengah + Vector2(0, ry * 0.92), rx * 0.95, Color(0, 0, 0, 0.35))
	if bentuk == "drum":
		draw_circle(tengah, r, p["rim_gelap"])
		draw_circle(tengah, r * 0.965, p["rim"])
		for i in 12:
			var a := TAU * float(i) / 12.0
			draw_circle(tengah + Vector2(cos(a) * r * 0.915, sin(a) * r * 0.915), r * 0.045, p["tali"])
		draw_circle(tengah, r * 0.875, p["kepala"])
		for k in 5:
			var t := float(k) / 5.0
			var ck: Color = p["kepala"]
			ck = ck.lerp(p["kepala_terang"], t * 0.85)
			draw_circle(tengah, r * 0.875 * (1.0 - t * 0.72), ck)
		draw_arc(tengah, r * 0.875, PI * 0.9, PI * 1.7, 24, Color(0, 0, 0, 0.20), r * 0.05, true)
		draw_circle(tengah, r * 0.20, Color(1, 1, 1, 0.10))
	elif bentuk == "gong":
		draw_circle(tengah, r, Color(0.30, 0.22, 0.08))
		draw_circle(tengah, r * 0.94, p["logam"])
		draw_circle(tengah, r * 0.72, Color(p["logam"].r * 1.08, p["logam"].g * 1.08, p["logam"].b * 1.05))
		draw_circle(tengah, r * 0.46, p["logam"])
		draw_circle(tengah, r * 0.24, Color(1.0, 0.92, 0.62))
		draw_arc(tengah, r * 0.83, PI * 1.05, PI * 1.6, 20, Color(1, 1, 1, 0.18), r * 0.06, true)
	elif bentuk == "kecrek":
		draw_circle(tengah, r, Color(0.16, 0.16, 0.18))
		draw_circle(tengah, r * 0.92, Color(0.62, 0.63, 0.66))
		for i in 8:
			var a := TAU * float(i) / 8.0
			draw_circle(tengah + Vector2(cos(a) * r * 0.66, sin(a) * r * 0.66), r * 0.17, Color(0.88, 0.86, 0.60))
		draw_circle(tengah, r * 0.26, Color(0.80, 0.79, 0.72))
	elif bentuk == "blok":
		var kotak := Rect2(tengah - Vector2(rx, ry * 0.62), Vector2(rx * 2, ry * 1.24))
		draw_rect(kotak, Color(0.30, 0.18, 0.09))
		draw_rect(kotak.grow(-5), p["rim"])
		draw_rect(Rect2(tengah - Vector2(rx * 0.7, 3), Vector2(rx * 1.4, 6)), Color(0.22, 0.12, 0.05))
	if kedip > 0.0:
		draw_circle(tengah, r * 0.875 if bentuk == "drum" else r * 0.9, Color(1, 1, 1, 0.22 * kedip))
		_elips_garis(tengah, rx * (1.05 + 0.12 * kedip), ry * (1.05 + 0.12 * kedip), Color(1, 0.98, 0.85, 0.55 * kedip), 4.0)
	if state.modus_atur:
		_elips_garis(tengah, rx + 4, ry + 4, Color(1, 0.9, 0.5, 0.55), 2.5)
