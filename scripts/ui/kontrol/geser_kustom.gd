class_name GeserKustom
extends Control
## Slider kustom yang digambar penuh dari kode: rel berongga, isian emas menyala,
## kenop lingkaran dengan cincin. Mendukung mouse & sentuh (seret).

signal nilai_berubah(nilai: float)

@export var nilai_min := 0.0
@export var nilai_maks := 1.0
@export var nilai := 0.5:
	set(v):
		nilai = clampf(v, nilai_min, nilai_maks)
		queue_redraw()

var _seret := false
const _JEPIT := 16.0

func _init() -> void:
	custom_minimum_size = Vector2(200, 36)
	mouse_filter = MOUSE_FILTER_STOP

func _draw() -> void:
	var cy := size.y / 2.0
	var x0 := _JEPIT
	var x1 := size.x - _JEPIT
	var rasio := 0.0 if nilai_maks <= nilai_min else (nilai - nilai_min) / (nilai_maks - nilai_min)
	var xk := lerpf(x0, x1, rasio)
	# Rel
	draw_line(Vector2(x0, cy), Vector2(x1, cy), Color(0.25, 0.21, 0.16), 8.0, true)
	# Isian emas + cahaya
	draw_line(Vector2(x0, cy), Vector2(xk, cy), GayaUI.EMAS_GELAP, 10.0, true)
	draw_line(Vector2(x0, cy), Vector2(xk, cy), GayaUI.EMAS, 6.0, true)
	# Kenop
	if _seret:
		draw_circle(Vector2(xk, cy), 17.0, Color(0.93, 0.72, 0.32, 0.28))
	draw_circle(Vector2(xk, cy), 11.0, Color(0.10, 0.08, 0.05))
	draw_circle(Vector2(xk, cy), 9.0, GayaUI.EMAS_TERANG)
	draw_circle(Vector2(xk - 3, cy - 3), 3.0, Color(1, 1, 1, 0.75))

func _posisi_x(kejadian: InputEvent) -> float:
	if kejadian is InputEventMouse:
		return (kejadian as InputEventMouse).position.x
	if kejadian is InputEventScreenTouch:
		return (get_global_transform().affine_inverse() * (kejadian as InputEventScreenTouch).position).x
	if kejadian is InputEventScreenDrag:
		return (get_global_transform().affine_inverse() * (kejadian as InputEventScreenDrag).position).x
	return 0.0

func _atur_dari_x(x: float) -> void:
	var rasio := clampf((x - _JEPIT) / maxf(size.x - _JEPIT * 2.0, 1.0), 0.0, 1.0)
	nilai = lerpf(nilai_min, nilai_maks, rasio)
	nilai_berubah.emit(nilai)

func _gui_input(kejadian: InputEvent) -> void:
	if kejadian is InputEventMouseButton:
		var mb := kejadian as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_seret = mb.pressed
			if mb.pressed:
				_atur_dari_x(mb.position.x)
			queue_redraw()
			accept_event()
	elif kejadian is InputEventMouseMotion and _seret:
		_atur_dari_x((kejadian as InputEventMouseMotion).position.x)
		accept_event()
	elif kejadian is InputEventScreenTouch:
		var st := kejadian as InputEventScreenTouch
		_seret = st.pressed
		if st.pressed:
			_atur_dari_x(_posisi_x(st))
		queue_redraw()
		accept_event()
	elif kejadian is InputEventScreenDrag and _seret:
		_atur_dari_x(_posisi_x(kejadian))
		accept_event()

func atur_tanpa_sinyal(v: float) -> void:
	nilai = clampf(v, nilai_min, nilai_maks)
