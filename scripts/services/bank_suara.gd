class_name BankSuara
extends RefCounted
## Memuat AudioStream dari: sumber daya bawaan (res://), MP3, dan WAV.
## Parser WAV manual mendukung PCM 8/16/24/32-bit dan float 32-bit.

func muat(jalur: String) -> AudioStream:
	if jalur == "":
		return null
	if jalur.begins_with("res://"):
		return load(jalur)
	if not FileAccess.file_exists(jalur):
		return null
	var bawah := jalur.to_lower()
	if bawah.ends_with(".mp3"):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(jalur)
		return mp3
	if bawah.ends_with(".wav"):
		return baca_wav(jalur)
	return null

func baca_wav(jalur: String) -> AudioStreamWAV:
	var b := FileAccess.get_file_as_bytes(jalur)
	if b.size() < 44:
		return null
	var format_audio := 1
	var saluran := 1
	var laju := 44100
	var bit := 16
	var data_mulai := -1
	var data_ukuran := 0
	var pos := 12
	while pos + 8 <= b.size():
		var idc := b.slice(pos, pos + 4).get_string_from_ascii()
		var uk := int(b.decode_u32(pos + 4))
		if idc == "fmt ":
			format_audio = int(b.decode_u16(pos + 8))
			saluran = int(b.decode_u16(pos + 10))
			laju = int(b.decode_u32(pos + 12))
			bit = int(b.decode_u16(pos + 22))
		elif idc == "data":
			data_mulai = pos + 8
			data_ukuran = uk
			break
		pos += 8 + uk + (uk % 2)
	if data_mulai < 0:
		return null
	var mentah := b.slice(data_mulai, mini(data_mulai + data_ukuran, b.size()))
	var w := AudioStreamWAV.new()
	w.mix_rate = laju
	w.stereo = saluran > 1
	if format_audio == 3 and bit == 32:
		# Float 32-bit -> konversi ke 16-bit PCM
		w.format = AudioStreamWAV.FORMAT_16_BITS
		var keluar := PackedByteArray()
		keluar.resize(mentah.size() / 2)
		var n := mentah.size() / 4
		for i in n:
			var f := clampf(mentah.decode_float(i * 4), -1.0, 1.0)
			keluar.encode_s16(i * 2, int(f * 32767.0))
		w.data = keluar
	elif bit == 8:
		w.format = AudioStreamWAV.FORMAT_8_BITS
		w.data = mentah
	elif bit == 16:
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.data = mentah
	elif bit == 24 or bit == 32:
		# PCM integer 24/32-bit -> ambil 2 byte tertinggi jadi 16-bit
		w.format = AudioStreamWAV.FORMAT_16_BITS
		var per_sampel := bit / 8
		var n2 := mentah.size() / per_sampel
		var keluar2 := PackedByteArray()
		keluar2.resize(n2 * 2)
		for i in n2:
			var dasar := i * per_sampel
			keluar2[i * 2] = mentah[dasar + per_sampel - 2]
			keluar2[i * 2 + 1] = mentah[dasar + per_sampel - 1]
		w.data = keluar2
	else:
		return null
	return w
