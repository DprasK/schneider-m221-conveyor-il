# Checklist commissioning

## Sebelum memberi daya motor

- Cocokkan tipe CPU, catu daya, jenis input, dan rating output dengan panel.
- Verifikasi semua alamat `%I` dan `%Q` terhadap wiring drawing aktual.
- Pastikan output PLC mengendalikan kontaktor/VFD melalui rangkaian yang sesuai.
- Uji safety relay, E-Stop, guard switch, dan overload tanpa bergantung pada PLC.
- Masukkan parameter timer/counter dari file proyek ke Software Objects.
- Analyze/Compile dan selesaikan semua error.

## Uji I/O

- Paksa/aktifkan satu input pada satu waktu dan cek status online.
- Dengan daya motor terisolasi, aktifkan satu output pada satu waktu.
- Pastikan arah putaran motor benar sebelum menyambungkan beban conveyor.
- Pastikan semua sensor kembali ke keadaan normal saat produk sudah lewat.

## Uji urutan

- Jalankan skenario normal minimum 20 siklus.
- Uji Stop, E-Stop, overload, sensor macet, bin penuh, dan downstream tidak siap.
- Pastikan reset tidak dapat menghapus alarm selama penyebab masih ada.
- Catat nilai timer aktual dan sesuaikan dengan jarak serta kecepatan conveyor.
- Setelah perubahan, ulangi Analyze/Compile dan regression test semua interlock.

## Kriteria serah terima

- Tidak ada output tak terduga saat PLC boot atau berpindah mode.
- Kehilangan safety feedback mematikan seluruh output gerak.
- Hanya satu aktuator sortir aktif pada satu waktu.
- Counter bertambah sekali per produk, bukan selama sensor tetap ON.
- Recovery setelah fault memerlukan tindakan reset yang jelas.

