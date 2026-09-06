# Proyek 5 - Lini Tiga Conveyor Terintegrasi

File utama: `INTEGRATED_3_CONVEYOR_TM221CE24R_REV3_VERIFIED.smbp`

- Controller: Schneider Modicon M221 `TM221CE24R`
- Bahasa: Instruction List (IL)
- POU: `INTEGRATED_3_CONVEYOR_IL`
- Program: 53 rung, 217 baris instruksi
- Fungsi: start berurutan dari hilir ke hulu, kontrol dua buffer, inspeksi
  OK/NG, reject pneumatik, jog maintenance, jam alarm per zona, dan counter
  produk good/reject.

## Objek waktu dan counter

Semua delay dan timeout dibuat dengan counter clock system M221:

- `%C0`, `%C1`: start delay transfer dan infeed, masing-masing 1 detik
- `%C2`: delay posisi reject 0,5 detik
- `%C3`: pulsa solenoid reject 0,7 detik
- `%C4`, `%C5`, `%C6`: jam timeout 10 detik per conveyor
- `%C7`: timeout pusher kembali home 3 detik
- `%C8`, `%C9`: jumlah produk good dan reject

Preset runtime memakai operation block seperti `[ %C4.P := 10 ]`. Sintaks
lama `ST %C4.P` tidak dipakai.

File revisi ini telah berhasil dibuka dan melewati validasi otomatis pada
EcoStruxure Machine Expert - Basic 1.4.0.484.

## Sebelum download

1. Buka file di EcoStruxure Machine Expert - Basic.
2. Cocokkan alamat sensor, overload, motor, dan solenoid dengan panel aktual.
3. Jalankan **Analyze/Compile**.
4. Uji urutan hilir-ke-hulu, buffer, reject, lalu setiap kondisi timeout.
5. Validasi fungsi keselamatan dengan safety relay/safety PLC terpisah.
