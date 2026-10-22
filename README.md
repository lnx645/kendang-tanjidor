# Kendang Virtual

Kit kendang virtual ala Real Drum: tampak dari atas, pukul pad-padnya langsung dari layar HP.

**Genre: Kendang Bajidor — kesenian Sunda** (bukan Tanjidor Betawi; nama repo tetap kendang-tanjidor).

## Isi kit
DANG (tengah, terbesar) • TAK (kiri) • ANAK (kanan) • KETIPUNG • KULANTER • KECREK • KEMPUL • GONG • PAK (blok kayu). Multi-sentuh + gesek antar pad (buat roll cepat).

## Fitur
- **Layar penuh** mengikuti ukuran HP; latensi rendah (suara dimuat di depan, buffer audio kecil, 120 fps).
- **Tema (skin)** — Kayu Jati, Hitam Panggung, Merah Ukir, Latar Sendiri (impor gambar).
- **Preset** — simpan/muat/hapus + **ekspor/impor JSON** (folder Download/KendangVirtual).
- **Suara** — ganti varian bawaan atau **impor MP3/WAV**; parser WAV mendukung 8/16/24/32-bit & float.
- **Pemilih berkas dalam aplikasi** — memindai Download/Musik/Gambar/Dokumen; berkas pilihan disalin ke aplikasi. Tanpa dialog native.
- **Atur** — seret posisi pad & atur ukuran (slider kustom); tersimpan per tema.
- **MP3** — putar lagu dari HP lalu main kendang mengiringinya.

## Arsitektur (clean architecture, satu tanggung jawab per berkas)
- `scripts/main.gd` — composition root: merakit & merutekan input.
- `scripts/domain/` — `data_kit.gd` (data pad/tema/letak), `state.gd` (keadaan + geometri).
- `scripts/services/` — `bank_suara.gd` (muat & parse audio), `mesin_suara.gd` (polifoni + musik), `penyimpanan.gd` (pengaturan & preset), `berkas.gd` (pindai/salin/ekspor berkas).
- `scripts/ui/` — `panggung.gd` (gambar kit), `hud.gd` (panel & pemilih berkas), `gaya.gd` (sistem desain "Emas Panggung"), `kontrol/` (`tombol_kustom.gd`, `geser_kustom.gd` — slider digambar penuh dari kode).

## Kredit
- UI: sistem desain kustom "Emas Panggung" (digambar prosedural dari kode).
- Semua suara kendang disintesis dari kode.

Dibangun dengan Godot 4.3. Riwayat: v1 ritme (ditolak), v2 tampak samping→kit atas, v3 arsitektur bersih + UI kustom + pemilih berkas internal.
