class_name GayaUI
extends RefCounted
## Sistem desain "Emas Panggung": gelap hangat + aksen emas, SEMUA digambar dari kode
## (tekstur tombol dibuat prosedural piksel demi piksel — tanpa UI kit luar).
## Dipakai oleh TombolKustom, panel, dan kontrol lain agar satu bahasa visual.

const EMAS := Color(0.93, 0.72, 0.32)
const EMAS_TERANG := Color(1.0, 0.85, 0.50)
const EMAS_GELAP := Color(0.55, 0.38, 0.14)
const LATAR_PANEL := Color(0.08, 0.065, 0.05, 0.98)
const GARIS := Color(0.85, 0.62, 0.30, 0.85)
const TEKS := Color(0.97, 0.92, 0.80)
const TEKS_REDUP := Color(0.85, 0.78, 0.65, 0.85)
const COKLAT_TUA := Color(0.16, 0.10, 0.04)
const BAHAYA := Color(0.85, 0.38, 0.30)
const SUKSES := Color(0.55, 0.85, 0.50)

static var _cache_tekstur := {}

## Tekstur tombol: persegi membulat + gradasi vertikal + bingkai, digambar prosedural.
static func tekstur_tombol(atas: Color, bawah: Color, garis: Color) -> Texture2D:
	var kunci := atas.to_html() + bawah.to_html() + garis.to_html()
	if _cache_tekstur.has(kunci):
		return _cache_tekstur[kunci]
	var w := 96
	var h := 48
	var r := 14.0
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := Vector2(x - w / 2.0 + 0.5, y - h / 2.0 + 0.5)
			var kotak := Vector2(w / 2.0 - r, h / 2.0 - r)
			var q := Vector2(absf(p.x) - kotak.x, absf(p.y) - kotak.y)
			var sdf := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			if sdf > 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var t := float(y) / float(h - 1)
				var c: Color = atas.lerp(bawah, t)
				if sdf > -2.5:
					c = garis
				img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache_tekstur[kunci] = tex
	return tex

static func kotak_tombol(varian: String, ditekan: bool = false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	match varian:
		"primer":
			sb.texture = tekstur_tombol(Color(0.72, 0.52, 0.20) if ditekan else EMAS_TERANG,
				Color(0.80, 0.58, 0.20) if ditekan else EMAS, EMAS_GELAP)
		"aktif":
			sb.texture = tekstur_tombol(Color(0.45, 0.33, 0.12), Color(0.30, 0.22, 0.09), EMAS)
		_:
			sb.texture = tekstur_tombol(Color(0.16, 0.13, 0.10) if not ditekan else Color(0.24, 0.19, 0.13),
				Color(0.09, 0.075, 0.06) if not ditekan else Color(0.14, 0.11, 0.08), Color(0.45, 0.36, 0.24))
	sb.set_texture_margin_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func kotak_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = LATAR_PANEL
	s.set_corner_radius_all(16)
	s.set_border_width_all(2)
	s.border_color = GARIS
	s.shadow_size = 12
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s

static func kotak_bilah() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.05, 0.04, 0.96)
	s.set_corner_radius_all(0)
	s.border_width_bottom = 2
	s.border_color = GARIS
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

static func label(teks: String, ukuran: int = 18, warna: Color = TEKS) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	return l

static func judul(teks: String) -> Label:
	return label(teks, 27, EMAS_TERANG)

static func garis_emas() -> HSeparator:
	var g := HSeparator.new()
	var sb := StyleBoxLine.new()
	sb.color = Color(0.85, 0.62, 0.30, 0.5)
	sb.thickness = 2
	g.add_theme_stylebox_override("separator", sb)
	return g
