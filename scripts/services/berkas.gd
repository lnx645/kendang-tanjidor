class_name Berkas
extends RefCounted
## Akses berkas pengguna TANPA dialog native: memindai folder umum perangkat
## (Download/Musik/Gambar/Dokumen) + folder internal aplikasi (user://).
## Berkas pilihan selalu DISALIN ke user:// agar pasti terbaca & tersimpan.

const NAMA_FOLDER := "KendangVirtual"

static func daftar_akar() -> Array:
	return [
		{"id": "unduh", "nama": "Download", "path": OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)},
		{"id": "musik", "nama": "Musik", "path": OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)},
		{"id": "gambar", "nama": "Gambar", "path": OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)},
		{"id": "dokumen", "nama": "Dokumen", "path": OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)},
		{"id": "aplikasi", "nama": "Di Aplikasi", "path": "user://impor"},
	]

static func pindai_dalam(path: String, ekstensi: Array, kedalaman: int = 1) -> Array:
	var hasil: Array = []
	_pindai(path, ekstensi, kedalaman, hasil)
	hasil.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["nama"]) < String(b["nama"]))
	return hasil

static func _pindai(path: String, ekstensi: Array, kedalaman: int, hasil: Array) -> void:
	if path == "" or kedalaman < 0:
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.include_hidden = false
	for nama in dir.get_directories():
		_pindai(path.path_join(nama), ekstensi, kedalaman - 1, hasil)
	for nama in dir.get_files():
		var ext := nama.get_extension().to_lower()
		if ekstensi.is_empty() or ekstensi.has(ext):
			hasil.append({"nama": nama, "path": path.path_join(nama)})

## Salin berkas luar ke penyimpanan internal aplikasi. Kembalikan path barunya ("" bila gagal).
static func salin_masuk(sumber: String, subfolder: String) -> String:
	if sumber.begins_with("user://") or sumber.begins_with("res://"):
		return sumber
	var tujuan_dir := "user://impor/" + subfolder
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tujuan_dir))
	var tujuan := tujuan_dir + "/" + sumber.get_file()
	var data := FileAccess.get_file_as_bytes(sumber)
	if data.is_empty():
		return ""
	var f := FileAccess.open(tujuan, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(data)
	f.close()
	return tujuan

## Folder ekspor yang bisa dijangkau pengguna (Download/KendangVirtual, dst). "" bila semua gagal.
static func folder_ekspor() -> String:
	var kandidat: Array = []
	var unduh := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if unduh != "":
		kandidat.append(unduh.path_join(NAMA_FOLDER))
	var dokumen := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if dokumen != "":
		kandidat.append(dokumen.path_join(NAMA_FOLDER))
	kandidat.append("user://ekspor")
	for k in kandidat:
		var path := String(k)
		var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
		if DirAccess.make_dir_recursive_absolute(abs_path) == OK:
			# Uji tulis
			var uji := path.path_join(".tulis_uji")
			var f := FileAccess.open(uji, FileAccess.WRITE)
			if f != null:
				f.store_string("ok")
				f.close()
				DirAccess.remove_absolute(ProjectSettings.globalize_path(uji))
				return path
	return ""

static func tulis_teks(path: String, isi: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(isi)
	f.close()
	return true

static func baca_teks(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)
