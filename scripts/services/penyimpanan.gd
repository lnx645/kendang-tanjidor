class_name Penyimpanan
extends RefCounted
## Persistensi: pengaturan aplikasi (ConfigFile) + preset (ConfigFile internal,
## JSON untuk ekspor/impor antar perangkat).

const JALUR_SIMPAN := "user://pengaturan.cfg"
const JALUR_PRESET := "user://preset.cfg"

func muat_pengaturan(state: State) -> float:
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_SIMPAN) != OK:
		return 0.9
	state.tema_ini = String(cfg.get_value("umum", "tema", "jati"))
	state.berkas_latar_sendiri = String(cfg.get_value("umum", "latar_sendiri", ""))
	state.nama_preset_ini = String(cfg.get_value("umum", "preset", ""))
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		pad["suara_aktif"] = String(cfg.get_value("suara", id, pad["suara_aktif"]))
		var kunci := state.tema_ini + "/" + id
		pad["x"] = float(cfg.get_value("letak", kunci + "_x", pad["x"]))
		pad["y"] = float(cfg.get_value("letak", kunci + "_y", pad["y"]))
		pad["skala"] = float(cfg.get_value("letak", kunci + "_s", 1.0))
	return float(cfg.get_value("umum", "volume", 0.9))

func simpan_pengaturan(state: State) -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_SIMPAN)
	cfg.set_value("umum", "tema", state.tema_ini)
	cfg.set_value("umum", "latar_sendiri", state.berkas_latar_sendiri)
	cfg.set_value("umum", "preset", state.nama_preset_ini)
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		cfg.set_value("suara", id, String(pad["suara_aktif"]))
		var kunci := state.tema_ini + "/" + id
		cfg.set_value("letak", kunci + "_x", float(pad["x"]))
		cfg.set_value("letak", kunci + "_y", float(pad["y"]))
		cfg.set_value("letak", kunci + "_s", float(pad["skala"]))
	cfg.save(JALUR_SIMPAN)

func simpan_volume(vol: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_SIMPAN)
	cfg.set_value("umum", "volume", vol)
	cfg.save(JALUR_SIMPAN)

# ---- Preset internal ----

func daftar_preset() -> Array:
	var hasil: Array = DataKit.PRESET_PABRIK.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) == OK:
		for s in cfg.get_sections():
			hasil.append(s)
	return hasil

func simpan_preset(state: State, nama: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(JALUR_PRESET)
	cfg.set_value(nama, "tema", state.tema_ini)
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		cfg.set_value(nama, id + "_x", float(pad["x"]))
		cfg.set_value(nama, id + "_y", float(pad["y"]))
		cfg.set_value(nama, id + "_s", float(pad["skala"]))
		cfg.set_value(nama, id + "_suara", String(pad["suara_aktif"]))
	cfg.save(JALUR_PRESET)

func muat_preset(state: State, nama: String) -> bool:
	if nama == "Panggung Klasik":
		state.pasang_letak(DataKit.LETAK_BAWAAN)
		return true
	if nama == "Rampak Rapat":
		state.tema_ini = "panggung"
		state.pasang_letak(DataKit.LETAK_RAPAT)
		return true
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) != OK or not cfg.has_section(nama):
		return false
	terapkan_data(state, {
		"tema": String(cfg.get_value(nama, "tema", state.tema_ini)),
		"pad": _pad_dari_cfg(cfg, nama, state),
	})
	return true

func _pad_dari_cfg(cfg: ConfigFile, nama: String, state: State) -> Dictionary:
	var hasil := {}
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		hasil[id] = {
			"x": float(cfg.get_value(nama, id + "_x", pad["x"])),
			"y": float(cfg.get_value(nama, id + "_y", pad["y"])),
			"s": float(cfg.get_value(nama, id + "_s", 1.0)),
			"suara": String(cfg.get_value(nama, id + "_suara", pad["suara_aktif"])),
		}
	return hasil

func hapus_preset(nama: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) == OK and cfg.has_section(nama):
		cfg.erase_section(nama)
		cfg.save(JALUR_PRESET)

# ---- Ekspor / impor JSON ----

func ekspor_preset(state: State, nama: String) -> Dictionary:
	var data := {"format": "kendang-virtual-preset", "versi": 1, "nama": nama, "tema": state.tema_ini, "pad": {}}
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		data["pad"][id] = {
			"x": float(pad["x"]), "y": float(pad["y"]), "s": float(pad["skala"]),
			"suara": String(pad["suara_aktif"]).get_file(),
		}
	return data

func terapkan_data(state: State, data: Dictionary) -> void:
	if data.has("tema"):
		state.tema_ini = String(data["tema"])
	var per_pad: Dictionary = data.get("pad", {})
	for pad in state.pads:
		var id := String(pad["def"]["id"])
		if per_pad.has(id):
			var d: Dictionary = per_pad[id]
			pad["x"] = float(d.get("x", pad["x"]))
			pad["y"] = float(d.get("y", pad["y"]))
			pad["skala"] = float(d.get("s", 1.0))
			if d.has("suara"):
				# Suara impor hanya nama berkas: cocokkan ke varian bawaan bila ada.
				var berkas := String(d["suara"])
				if String(pad["suara_aktif"]).get_file() != berkas:
					for pilihan in pad["def"]["suara"]:
						if String(pilihan) == berkas:
							pad["suara_aktif"] = "res://audio/" + berkas
			pad["nada"] = null

## Ambil data sebuah preset sebagai Dictionary (untuk ekspor), tanpa mengubah state aktif.
func ambil_data_preset(state: State, nama: String) -> Dictionary:
	if nama == "Panggung Klasik":
		return {"format": "kendang-virtual-preset", "versi": 1, "nama": nama, "tema": state.tema_ini,
			"pad": _pad_dari_letak(DataKit.LETAK_BAWAAN)}
	if nama == "Rampak Rapat":
		return {"format": "kendang-virtual-preset", "versi": 1, "nama": nama, "tema": "panggung",
			"pad": _pad_dari_letak(DataKit.LETAK_RAPAT)}
	var cfg := ConfigFile.new()
	if cfg.load(JALUR_PRESET) != OK or not cfg.has_section(nama):
		return {}
	return {"format": "kendang-virtual-preset", "versi": 1, "nama": nama,
		"tema": String(cfg.get_value(nama, "tema", state.tema_ini)), "pad": _pad_dari_cfg(cfg, nama, state)}

func _pad_dari_letak(letak: Dictionary) -> Dictionary:
	var hasil := {}
	for id in letak.keys():
		var l: Array = letak[id]
		hasil[id] = {"x": float(l[0]), "y": float(l[1]), "s": 1.0, "suara": ""}
	return hasil
