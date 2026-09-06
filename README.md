# Paket proyek conveyor Schneider M221 - Instruction List

Target asumsi: **Modicon M221 TM221CE24R** dan **EcoStruxure Machine Expert - Basic**.
Versi paling sederhana sengaja tidak disertakan. Paket dimulai dari kontrol
manual/auto dan meningkat sampai lini tiga conveyor terintegrasi.

## Isi paket

| Level | File | Fungsi utama |
|---|---|---|
| 2 | `V2_Manual_Auto/PROGRAM_IL.txt` | Satu conveyor, manual/auto, HMI, interlock, tail-run |
| 3 | `V3_Dua_Zona/CONVEYOR_2_ZONE_ZPA_TM221CE24R_REV2_FIXED.smbp` | Proyek dua zona revisi 2; perbaikan rung counter 10-13 |
| 4 | `V4_Sortir_3_Jalur/SORTING_3_WAY_TM221CE24R_REV3_VERIFIED.smbp` | Sortir A/B/reject, pusher, timeout, dan counter produksi |
| 5 | `V5_Lini_Terintegrasi/INTEGRATED_3_CONVEYOR_TM221CE24R_REV3_VERIFIED.smbp` | Tiga conveyor, start bertahap, buffer, inspeksi, reject, dan alarm |

Setiap file berisi:

- daftar alamat I/O dan memory bit;
- parameter timer/counter;
- IL yang dibagi per network;
- urutan uji commissioning.

## Membuka file proyek 3-5

File `.smbp` dapat dibuka langsung di EcoStruxure Machine Expert - Basic.
Jalankan **Analyze/Compile** setelah dibuka dan sebelum download ke PLC.

Revisi `REV3_VERIFIED` proyek 4 dan 5 telah diuji langsung menggunakan Machine
Expert Basic 1.4.0.484: proses `End load file` dan validasi otomatis selesai.

## Cara memasukkan file IL teks

1. Buat proyek baru dengan controller `TM221CE24R`.
2. Buat POU pada **MAST Task**, lalu pilih tampilan **IL**.
3. Masukkan satu blok `NETWORK` sebagai satu rung. Teks `(* ... *)` adalah
   dokumentasi; jika editor menolaknya, salin teks tersebut ke kolom komentar
   rung dan masukkan hanya instruksinya.
4. Buat simbol sesuai tabel alamat di awal file.
5. Buka **Software Objects > Timers/Counters**, centang objek yang digunakan,
   lalu isi Type, Time Base, dan Preset sesuai tabel parameter.
6. Jalankan **Analyze/Compile**. Jangan download ke PLC sebelum semua error dan
   warning yang relevan selesai ditinjau.

## Aturan keselamatan

`ESTOP_OK`, `STOP_OK`, dan kontak overload di program adalah feedback/interlock,
bukan fungsi keselamatan utama. Emergency stop wajib memutus energi berbahaya
melalui safety relay atau safety PLC dan kontaktor yang sesuai hasil risk
assessment. Lakukan uji awal tanpa daya motor, kemudian uji I/O satu per satu.

## Catatan sintaks

- `LDR` menghasilkan kondisi satu scan pada tepi naik.
- `S` dan `R` adalah set/reset bit.
- Timer/counter memakai format blok M221: `BLK`, input blok (`IN`, `CU`, `R`),
  lalu `END_BLK`.
- Preset timer/counter dikonfigurasi pada tabel Software Objects, bukan dianggap
  sudah benar hanya karena komentarnya menyebut nilai tertentu.

Dokumentasi Schneider menyatakan Machine Expert - Basic untuk M221 mendukung
Instruction List dan program diorganisasi dalam POU/section dan rung.
