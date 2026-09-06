# Proyek 4 - Sorting Conveyor Tiga Jalur

File utama: `SORTING_3_WAY_TM221CE24R_REV3_VERIFIED.smbp`

- Controller: Schneider Modicon M221 `TM221CE24R`
- Bahasa: Instruction List (IL)
- POU: `SORTING_3_WAY_IL`
- Program: 32 rung, 152 baris instruksi
- Fungsi: klasifikasi A/B/reject, aktuator sortir, timeout sequence,
  deteksi reject-bin penuh, counter produksi, serta lampu dan buzzer.

## Objek waktu dan counter

Implementasi waktu memakai counter dengan clock system M221 agar proyek tidak
bergantung pada konfigurasi time-base timer:

- `%C0`: 20 pulsa `%S5` = 2,0 detik transport
- `%C1`: 7 pulsa `%S5` = 0,7 detik aktuator
- `%C2`: 8 pulsa `%S6` = timeout 8 detik
- `%C3`, `%C4`, `%C5`: jumlah produk A, B, dan reject

Preset runtime ditulis memakai operation block, misalnya `[ %C0.P := 20 ]`,
bukan pasangan `LD` / `ST %C0.P`.

File revisi ini telah berhasil dibuka dan melewati validasi otomatis pada
EcoStruxure Machine Expert - Basic 1.4.0.484.

## Sebelum download

1. Buka file di EcoStruxure Machine Expert - Basic.
2. Periksa mapping input/output terhadap wiring panel aktual.
3. Jalankan **Analyze/Compile**.
4. Uji safety relay, E-stop, overload, dan output tanpa daya motor dahulu.
