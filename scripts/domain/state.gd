class_name State
extends RefCounted
## Keadaan runtime aplikasi: tema aktif, daftar pad, mode, dan ukuran layar.
## Murni data + geometri — tidak menggambar, tidak menyentuh berkas.

var tema_ini := "jati"
var berkas_latar_sendiri := ""
var nama_preset_ini := ""
var modus_atur := false
var ukuran := Vector2(1280, 720)
var pads: Array = []

func _init() -> void:
	siapkan_pads()
	pasang_letak(DataKit.LETAK_BAWAAN)

func siapkan_pads() -> void:
	pads.clear()
	for d in DataKit.DEF_PAD:
		var def: Dictionary = d
		pads.append({
			"def": def, "x": 0.5, "y": 0.5, "rx": 0.06, "ry": 0.1, "skala": 1.0,
			"kedip": 0.0, "suara_aktif": "res://audio/" + String(def["suara"][0]),
			"nada": null,
		})

func pasang_letak(dasar: Dictionary) -> void:
	for pad in pads:
		var id := String(pad["def"]["id"])
		var l: Array = dasar.get(id, [0.5, 0.5, 0.06, 0.1])
		pad["x"] = float(l[0])
		pad["y"] = float(l[1])
		pad["rx"] = float(l[2])
		pad["ry"] = float(l[3])
		pad["skala"] = 1.0

func pad_bernama(id: String) -> Dictionary:
	for pad in pads:
		if String(pad["def"]["id"]) == id:
			return pad
	return {}

## Geometri pad dalam piksel: pad bulat selalu lingkaran sejati (jari-jari dari lebar layar).
func geo(pad: Dictionary) -> Dictionary:
	var rx := float(pad["rx"]) * float(pad["skala"]) * ukuran.x
	var ry := rx
	if String(pad["def"]["bentuk"]) == "blok":
		ry = float(pad["ry"]) * float(pad["skala"]) * ukuran.y
	return {"c": Vector2(float(pad["x"]) * ukuran.x, float(pad["y"]) * ukuran.y), "rx": rx, "ry": ry}

func pad_di(pos: Vector2, longgar: bool = false) -> Dictionary:
	var faktor := 1.12 if longgar else 1.0
	for i in range(pads.size() - 1, -1, -1):
		var pad: Dictionary = pads[i]
		var g := geo(pad)
		var t: Vector2 = g["c"]
		var d := Vector2(
			(pos.x - t.x) / maxf(float(g["rx"]) * faktor, 1.0),
			(pos.y - t.y) / maxf(float(g["ry"]) * faktor, 1.0))
		if d.length() <= 1.0:
			return pad
	return {}

func palet() -> Dictionary:
	return DataKit.DAFTAR_TEMA[tema_ini]
