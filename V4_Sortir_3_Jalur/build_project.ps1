param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'SORTING_3_WAY_TM221CE24R_REV3_VERIFIED.smbp')
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path $PSScriptRoot -Parent
$workspaceRoot = Split-Path $packageRoot -Parent
. (Join-Path $packageRoot 'smbp_builder_common.ps1')

$inputs = @(
    @('START_PB','Tombol Start NO'), @('STOP_OK','Kontak Stop NC; 1 sehat'),
    @('ESTOP_OK','Feedback safety relay; 1 sehat'), @('OVERLOAD_OK','Overload conveyor; 1 sehat'),
    @('ENTRY_SENSOR','Sensor produk masuk'), @('TYPE_A_SENSOR','Sensor klasifikasi A'),
    @('TYPE_B_SENSOR','Sensor klasifikasi B'), @('PUSHER_HOME','Pusher pada posisi home'),
    @('EXIT_SENSOR','Sensor keluar'), @('BIN_A_AVAILABLE','Bin A belum penuh'),
    @('BIN_B_AVAILABLE','Bin B belum penuh'), @('REJECT_BIN_AVAILABLE','Bin reject belum penuh'),
    @('RESET_PB','Reset alarm'), @('','Tidak digunakan')
)
$outputs = @(
    @('MOTOR_CONVEYOR','Kontaktor/VFD conveyor'), @('PUSHER_A','Solenoid pusher A'),
    @('PUSHER_B','Solenoid pusher B'), @('REJECT_GATE','Solenoid gate reject'),
    @('LAMP_RUN','Lampu run'), @('LAMP_BUSY','Lampu sequence busy'),
    @('LAMP_FAULT','Lampu fault'), @('BUZZER','Buzzer fault'),
    @('','Tidak digunakan'), @('','Tidak digunakan')
)
$memory = @(
    @(0,'AUTO_MODE','1 Auto'), @(1,'START_HMI','Start HMI momentary'), @(2,'STOP_HMI','Stop HMI'),
    @(3,'AUTO_ENABLE','Izin auto'), @(10,'RUN_MEMORY','Latch produksi'), @(11,'SAFETY_OK','Ringkasan interlock'),
    @(20,'PRODUCT_A_LATCH','Produk A'), @(21,'PRODUCT_B_LATCH','Produk B'), @(22,'PRODUCT_REJECT_LATCH','Produk reject'),
    @(23,'SORT_BUSY','Sequence sortir aktif'), @(24,'TRANSPORT_DONE','Produk sampai aktuator'),
    @(25,'PUSH_ACTIVE','Aktuator sortir aktif'), @(26,'PUSH_DONE','Pulsa selesai pusher'),
    @(27,'EXIT_PULSE','Pulsa satu scan sensor keluar'), @(30,'JAM_ALARM_LATCH','Timeout sortir'),
    @(31,'BIN_ALARM_LATCH','Reject bin penuh'), @(32,'ALARM_ACTIVE','Alarm umum'),
    @(40,'RESET_HMI','Reset HMI'), @(41,'RESET_COUNTERS_HMI','Reset production counter'), @(42,'RESET_REQUEST','Gabungan reset')
)
$counters = @(
    @(0,'TRANSPORT_TICKS','20 x pulsa 100 ms = 2 s',20,$true),
    @(1,'PUSH_TICKS','7 x pulsa 100 ms = 0.7 s',7,$true),
    @(2,'SEQUENCE_SECONDS','8 x pulsa 1 s = timeout 8 s',8,$true),
    @(3,'COUNT_A','Jumlah produk A',9999,$false),
    @(4,'COUNT_B','Jumlah produk B',9999,$false),
    @(5,'COUNT_REJECT','Jumlah produk reject',9999,$false)
)
$program = @(
    @('N01_SAFETY','Safety feedback.',@('LD  %I0.1','AND  %I0.2','AND  %I0.3','ANDN  %M2','ST  %M11')),
    @('N02_RUN','Latch auto run.',@('LD  %I0.0','OR  %M1','OR  %M10','AND  %M0','AND  %M3','AND  %M11','ST  %M10')),
    @('N03_RESET','Gabungan reset.',@('LD  %I0.12','OR  %M40','ST  %M42')),
    @('N04_CLASS_A','Tangkap produk A.',@('LDR  %I0.4','AND  %M10','ANDN  %M23','AND  %I0.5','AND  %I0.9','S  %M20')),
    @('N05_CLASS_B','Tangkap produk B.',@('LDR  %I0.4','AND  %M10','ANDN  %M23','ANDN  %I0.5','AND  %I0.6','AND  %I0.10','S  %M21')),
    @('N06_CLASS_REJECT','Selain A/B masuk reject.',@('LDR  %I0.4','AND  %M10','ANDN  %M23','ANDN  %M20','ANDN  %M21','AND  %I0.11','S  %M22')),
    @('N07_BIN_FULL','Alarm jika reject dibutuhkan tetapi bin penuh.',@('LDR  %I0.4','AND  %M10','ANDN  %M23','ANDN  %M20','ANDN  %M21','ANDN  %I0.11','S  %M31')),
    @('N08_SORT_BUSY','Mulai sequence.',@('LD  %M20','OR  %M21','OR  %M22','S  %M23')),
    @('N09_PRESET_C0','Preset transport saat first scan.',@('LD  %S13','[ %C0.P := 20 ]')),
    @('N09_PRESET_C1','Preset pusher saat first scan.',@('LD  %S13','[ %C1.P := 7 ]')),
    @('N09_PRESET_C2','Preset timeout saat first scan.',@('LD  %S13','[ %C2.P := 8 ]')),
    @('N10_TRANSPORT_COUNTER','Hitung 2 detik menuju aktuator.',@('BLK  %C0','LD  %S5','AND  %M23','ANDN  %M24','CU','LDN  %M23','OR  %M24','R','END_BLK')),
    @('N11_AT_POSITION','Aktifkan pusher bila home.',@('LD  %C0.D','AND  %I0.7','S  %M24','S  %M25')),
    @('N13_PUSH_COUNTER','Durasi aktuator 0.7 detik.',@('BLK  %C1','LD  %S5','AND  %M25','CU','LDN  %M25','R','END_BLK')),
    @('N14_PUSH_DONE','Akhiri aktuator.',@('LD  %C1.D','ST  %M26','R  %M25')),
    @('N16_TIMEOUT_COUNTER','Hitung maksimum waktu sequence.',@('BLK  %C2','LD  %S6','AND  %M23','CU','LDN  %M23','R','END_BLK')),
    @('N17_TIMEOUT_ALARM','Latch timeout.',@('LD  %C2.D','S  %M30')),
    @('N18_EXIT_PULSE','Pulsa produk selesai.',@('LDR  %I0.8','AND  %M23','ST  %M27')),
    @('N19_COUNT_A','Counter produksi A.',@('BLK  %C3','LD  %M27','AND  %M20','CU','LD  %M41','R','END_BLK')),
    @('N20_COUNT_B','Counter produksi B.',@('BLK  %C4','LD  %M27','AND  %M21','CU','LD  %M41','R','END_BLK')),
    @('N21_COUNT_REJECT','Counter produk reject.',@('BLK  %C5','LD  %M27','AND  %M22','CU','LD  %M41','R','END_BLK')),
    @('N22_CLEAR_SEQUENCE','Bersihkan latch setelah exit.',@('LD  %M27','R  %M25','R  %M24','R  %M23','R  %M20','R  %M21','R  %M22')),
    @('N23_RESET_JAM','Reset timeout setelah kondisi pulih.',@('LD  %M42','ANDN  %I0.4','AND  %I0.7','R  %M30')),
    @('N24_RESET_BIN','Reset bin alarm setelah tersedia.',@('LD  %M42','AND  %I0.11','R  %M31')),
    @('N25_ALARM','Ringkasan alarm.',@('LD  %M30','OR  %M31','ORN  %I0.2','ORN  %I0.3','ST  %M32')),
    @('N26_MOTOR','Motor berhenti saat pusher/alarm.',@('LD  %M10','AND  %M11','ANDN  %M25','ANDN  %M32','ST  %Q0.0')),
    @('N27_PUSHER_A','Output A.',@('LD  %M25','AND  %M20','AND  %M11','ST  %Q0.1')),
    @('N28_PUSHER_B','Output B.',@('LD  %M25','AND  %M21','AND  %M11','ST  %Q0.2')),
    @('N29_REJECT','Output reject.',@('LD  %M25','AND  %M22','AND  %M11','ST  %Q0.3')),
    @('N30_LAMP_RUN','Lampu run.',@('LD  %M10','ANDN  %M32','ST  %Q0.4')),
    @('N31_LAMP_BUSY','Lampu sequence busy.',@('LD  %M23','ST  %Q0.5')),
    @('N32_FAULT_OUTPUTS','Lampu fault dan buzzer.',@('LD  %M32','ST  %Q0.6','ST  %Q0.7'))
)

New-M221SmbpProject -TemplatePath (Join-Path $workspaceRoot 'AWGC_3_Pintu_TM221CE24R_REV3.smbp') `
    -OutputPath $OutputPath -ProjectName 'SORTING_3_WAY_TM221CE24R_REV3' `
    -PouName 'SORTING_3_WAY_IL' -Inputs $inputs -Outputs $outputs -MemoryDefinitions $memory `
    -CounterDefinitions $counters -Program $program
