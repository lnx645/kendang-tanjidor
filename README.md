# 🥁 Kendang Tanjidor

Game ritme kendang Betawi untuk Android (Godot 4.3). Sentuh sisi kendang mengikuti not yang jatuh mengikuti irama tanjidor!

## Cara Main
- **TAK** = kendang kecil (kiri), **DANG** = kendang besar (kanan).
- Not jatuh dari atas — sentuh sisi yang benar tepat saat not menyentuh kendang: **HEBAT** (300 poin), **Bagus** (100), **Lepas** (kombo putus).
- 3 lagu: *Jali Pagi* (100 BPM), *Ondel Lewat* (118 BPM), *Tanjidor Ngebut* (136 BPM) — nilai akhir S/A/B/C/D.
- **Mode Bebas**: pukul kendang sesukamu + tombol nada terompet (Do Re Mi Sol La).

## Musik
Seluruh suara & musik **disintesis dari kode** (`tools/buat_audio.py`, Python + NumPy) — kendang, kecrek, gong, terompet, tuba — tanpa berkas audio berhak cipta. Melodi lagu adalah komposisi orisinal bergaya tanjidor Betawi. Peta not per lagu ada di `data/lagu*.json`.

## Build APK
APK dibangun otomatis oleh **GitHub Actions** (`.github/workflows/android.yml`, container Godot CI) setiap push ke `main` — unduh dari tab **Actions → artifact `kendang-tanjidor-apk`**, lalu install di HP (izinkan "sumber tidak dikenal").

## Teknologi
Godot 4.3 • GDScript • satu berkas logika `main.gd` • target Android (arm64), juga bisa diekspor ke Web.
