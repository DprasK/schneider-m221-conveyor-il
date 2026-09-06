# Proyek siap buka: Conveyor Dua Zona Zero-Pressure

File proyek terbaru: `CONVEYOR_2_ZONE_ZPA_TM221CE24R_REV2_FIXED.smbp`

Revisi 2 memperbaiki error rung 10-13: assignment preset counter kini memakai
operation block M221, bukan pasangan instruksi `LD`/`ST` ke `%C.P`.

Konfigurasi:

- PLC: Schneider Modicon `TM221CE24R`
- Bahasa: Instruction List (IL)
- POU: `CONVEYOR_2_ZONE_ZPA_IL`
- 14 digital input dan 10 relay output bawaan CPU
- Deteksi jam: counter `%C0/%C1` dengan pulsa sistem `%S6`
- Batas jam: 8 pulsa, ditulis dengan operation block
  `[ %C0.P := 8 ]` dan `[ %C1.P := 8 ]` pada first scan `%S13`

Mengapa memakai counter dan `%S6`:

- Tidak memerlukan pengaturan time-base timer terpisah.
- Nilai 8 detik terlihat langsung di IL.
- Counter otomatis di-reset ketika motor tidak diperintah atau sensor bebas.
- Alarm `%M20/%M21` tetap dilatch sampai kondisi sensor bebas dan operator reset.

## Pemeriksaan saat pertama dibuka

1. Pastikan CPU tampil sebagai `TM221CE24R`.
2. Buka POU `CONVEYOR_2_ZONE_ZPA_IL` dan pastikan ada 23 rung IL.
3. Jalankan **Analyze/Compile**.
4. `%C0` dan `%C1` sudah diset Preset=8 dan Adjustable/Dynamic Preset aktif.
5. Lakukan commissioning tanpa daya motor mengikuti `../CHECKLIST_COMMISSIONING.md`.

Emergency stop harus tetap memakai rangkaian keselamatan hardwired. Feedback
`ESTOP_OK` di PLC bukan pengganti safety relay atau safety PLC.
