class_name TombolKustom
extends Button
## Tombol kustom "Emas Panggung" — bukan bawaan Godot, bukan UI kit.
## varian: "primer" (emas), "sekunder" (gelap), "aktif" (pilihan menyala).

@export var varian := "sekunder":
	set(v):
		varian = v
		if is_node_ready():
			_terapkan()

func _init(teks: String = "", p_varian: String = "sekunder") -> void:
	text = teks
	varian = p_varian

func _ready() -> void:
	_terapkan()

func _terapkan() -> void:
	add_theme_stylebox_override("normal", GayaUI.kotak_tombol(varian))
	add_theme_stylebox_override("hover", GayaUI.kotak_tombol(varian))
	add_theme_stylebox_override("pressed", GayaUI.kotak_tombol(varian, true))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", 20)
	if varian == "primer":
		add_theme_color_override("font_color", GayaUI.COKLAT_TUA)
		add_theme_color_override("font_hover_color", GayaUI.COKLAT_TUA)
		add_theme_color_override("font_pressed_color", GayaUI.COKLAT_TUA)
	else:
		add_theme_color_override("font_color", GayaUI.TEKS)
		add_theme_color_override("font_hover_color", GayaUI.EMAS_TERANG)
		add_theme_color_override("font_pressed_color", GayaUI.EMAS_TERANG)
