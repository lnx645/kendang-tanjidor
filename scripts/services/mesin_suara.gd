class_name MesinSuara
extends Node
## Mesin putar: kolam 16 pemain untuk pukulan pad (polifoni) + 1 pemutar musik MP3.
## Semua pemuatan stream lewat BankSuara; node ini hanya memutar.

var bank: BankSuara
var pemain: Array = []
var giliran := 0
var rng := RandomNumberGenerator.new()
var musik: AudioStreamPlayer

func _init() -> void:
	rng.randomize()
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		pemain.append(p)
	musik = AudioStreamPlayer.new()
	musik.bus = "Master"
	add_child(musik)

func pukul(pad: Dictionary) -> void:
	pad["kedip"] = 1.0
	if pad["nada"] == null and bank:
		pad["nada"] = bank.muat(String(pad["suara_aktif"]))
	var nada: AudioStream = pad["nada"]
	if nada == null:
		return
	var p: AudioStreamPlayer = pemain[giliran]
	giliran = (giliran + 1) % pemain.size()
	p.stream = nada
	p.pitch_scale = rng.randf_range(0.97, 1.03)
	p.play()
	Input.vibrate_handheld(12)

func panaskan(state: State) -> void:
	if bank == null:
		return
	for pad in state.pads:
		pad["nada"] = bank.muat(String(pad["suara_aktif"]))

func ganti_suara_pad(pad: Dictionary) -> void:
	pad["nada"] = null
	if bank:
		pad["nada"] = bank.muat(String(pad["suara_aktif"]))

# ---- Musik pengiring (MP3) ----

func putar_musik(jalur: String, ulangi: bool) -> bool:
	if bank == null:
		return false
	var s := bank.muat(jalur)
	if s == null:
		return false
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = ulangi
	musik.stream = s
	musik.play()
	return true

func jeda_lanjut() -> void:
	if musik.stream:
		if musik.playing:
			musik.stream_paused = not musik.stream_paused
		else:
			musik.play()

func berhenti_musik() -> void:
	musik.stop()

func musik_main() -> bool:
	return musik.playing and not musik.stream_paused

func posisi_musik() -> float:
	return musik.get_playback_position()

func durasi_musik() -> float:
	if musik.stream:
		return musik.stream.get_length()
	return 0.0

func lompat_musik(ke: float) -> void:
	if musik.stream:
		musik.seek(ke)

func atur_volume(vol: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.001)))
