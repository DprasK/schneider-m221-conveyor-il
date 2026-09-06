param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'INTEGRATED_3_CONVEYOR_TM221CE24R_REV3_VERIFIED.smbp')
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path $PSScriptRoot -Parent
$workspaceRoot = Split-Path $packageRoot -Parent
. (Join-Path $packageRoot 'smbp_builder_common.ps1')

$inputs = @(
    @('START_PB','Tombol Start NO'), @('STOP_OK','Kontak Stop NC; 1 sehat'),
    @('ESTOP_OK','Feedback safety relay; 1 sehat'), @('OL_INFEED_OK','Overload infeed; 1 sehat'),
    @('OL_TRANSFER_OK','Overload transfer; 1 sehat'), @('OL_OUTFEED_OK','Overload outfeed; 1 sehat'),
    @('SENSOR_INFEED','Sensor infeed'), @('SENSOR_BUFFER1','Sensor buffer 1'),
    @('SENSOR_BUFFER2','Sensor buffer 2'), @('SENSOR_INSPECTION','Sensor inspeksi'),
    @('QUALITY_OK','Hasil inspeksi OK'), @('REJECT_HOME','Pusher reject home'),
    @('EXIT_SENSOR','Sensor keluar'), @('RESET_PB','Reset alarm')
)
$outputs = @(
    @('MOTOR_INFEED','Motor conveyor infeed'), @('MOTOR_TRANSFER','Motor conveyor transfer'),
    @('MOTOR_OUTFEED','Motor conveyor outfeed'), @('REJECT_SOLENOID','Solenoid reject'),
    @('BUZZER','Buzzer fault'), @('LAMP_RUN','Lampu run'),
    @('LAMP_MAINTENANCE','Lampu maintenance'), @('LAMP_FAULT','Lampu fault'),
    @('','Tidak digunakan'), @('','Tidak digunakan')
)
$memory = @(
    @(0,'AUTO_MODE','1 Auto'), @(1,'START_HMI','Start HMI'), @(2,'STOP_HMI','Stop HMI'),
    @(3,'JOG_INFEED','Jog infeed'), @(4,'JOG_TRANSFER','Jog transfer'), @(5,'JOG_OUTFEED','Jog outfeed'),
    @(6,'RESET_HMI','Reset HMI'), @(7,'MAINTENANCE_ENABLE','Izin maintenance'),
    @(10,'SYSTEM_RUN','Latch produksi'), @(11,'SAFETY_OK','Ringkasan interlock'),
    @(12,'OUTFEED_AUTO_CMD','Auto command outfeed'), @(13,'TRANSFER_AUTO_CMD','Auto command transfer'),
    @(14,'INFEED_AUTO_CMD','Auto command infeed'), @(15,'INFEED_FINAL_CMD','Final infeed'),
    @(16,'TRANSFER_FINAL_CMD','Final transfer'), @(17,'OUTFEED_FINAL_CMD','Final outfeed'),
    @(20,'TRANSFER_STAGE_READY','Start delay transfer selesai'), @(21,'INFEED_STAGE_READY','Start delay infeed selesai'),
    @(22,'REJECT_REQUEST','Permintaan reject'), @(23,'REJECT_ACTIVE','Solenoid reject aktif'),
    @(24,'PRODUCT_REJECTED','Produk saat ini reject'), @(25,'EXIT_PULSE','Pulsa exit'),
    @(26,'RESET_REQUEST','Gabungan reset'), @(30,'JAM_INFEED','Jam infeed'),
    @(31,'JAM_TRANSFER','Jam transfer'), @(32,'JAM_OUTFEED','Jam outfeed'),
    @(33,'REJECT_NOT_HOME','Pusher gagal home'), @(34,'ALARM_ACTIVE','Alarm umum'),
    @(40,'RESET_COUNTERS_HMI','Reset counter produksi'), @(41,'MANUAL_INFEED_CMD','Jog infeed tervalidasi'),
    @(42,'MANUAL_TRANSFER_CMD','Jog transfer tervalidasi'), @(43,'MANUAL_OUTFEED_CMD','Jog outfeed tervalidasi')
)
$counters = @(
    @(0,'TRANSFER_START_TICKS','10 x 100 ms = 1 s',10,$true),
    @(1,'INFEED_START_TICKS','10 x 100 ms = 1 s',10,$true),
    @(2,'REJECT_POSITION_TICKS','5 x 100 ms = 0.5 s',5,$true),
    @(3,'REJECT_PULSE_TICKS','7 x 100 ms = 0.7 s',7,$true),
    @(4,'JAM_INFEED_SECONDS','10 x 1 s',10,$true),
    @(5,'JAM_TRANSFER_SECONDS','10 x 1 s',10,$true),
    @(6,'JAM_OUTFEED_SECONDS','10 x 1 s',10,$true),
    @(7,'REJECT_HOME_SECONDS','3 x 1 s',3,$true),
    @(8,'GOOD_PRODUCT_COUNT','Counter produk OK',9999,$false),
    @(9,'REJECT_PRODUCT_COUNT','Counter produk reject',9999,$false)
)
$program = @(
    @('N01_SAFETY','Stop, E-Stop, dan tiga overload.',@('LD  %I0.1','AND  %I0.2','AND  %I0.3','AND  %I0.4','AND  %I0.5','ANDN  %M2','ST  %M11')),
    @('N02_SYSTEM_RUN','Latch produksi Auto.',@('LD  %I0.0','OR  %M1','OR  %M10','AND  %M0','AND  %M11','ST  %M10')),
    @('N03_RESET','Gabungan reset.',@('LD  %I0.13','OR  %M6','ST  %M26')),
    @('N04_OUTFEED_BASE','Hilir start lebih dahulu.',@('LD  %M10','ANDN  %M34','ST  %M12')),
    @('N05_PRESET_C0','Preset transfer start.',@('LD  %S13','[ %C0.P := 10 ]')),
    @('N05_PRESET_C1','Preset infeed start.',@('LD  %S13','[ %C1.P := 10 ]')),
    @('N05_PRESET_C2','Preset posisi reject.',@('LD  %S13','[ %C2.P := 5 ]')),
    @('N05_PRESET_C3','Preset pulsa reject.',@('LD  %S13','[ %C3.P := 7 ]')),
    @('N05_PRESET_C4','Preset jam infeed.',@('LD  %S13','[ %C4.P := 10 ]')),
    @('N05_PRESET_C5','Preset jam transfer.',@('LD  %S13','[ %C5.P := 10 ]')),
    @('N05_PRESET_C6','Preset jam outfeed.',@('LD  %S13','[ %C6.P := 10 ]')),
    @('N05_PRESET_C7','Preset pusher home.',@('LD  %S13','[ %C7.P := 3 ]')),
    @('N06_TRANSFER_DELAY','Delay 1 detik.',@('BLK  %C0','LD  %S5','AND  %M12','CU','LDN  %M12','R','END_BLK')),
    @('N07_TRANSFER_READY','Transfer siap.',@('LD  %C0.D','ST  %M20')),
    @('N09_INFEED_DELAY','Delay 1 detik setelah transfer.',@('BLK  %C1','LD  %S5','AND  %M20','CU','LDN  %M20','R','END_BLK')),
    @('N10_INFEED_READY','Infeed siap.',@('LD  %C1.D','ST  %M21')),
    @('N11_INFEED_AUTO','Kontrol buffer 1 Auto.',@('LD  %M21','ANDN  %I0.7','ANDN  %M34','ST  %M14')),
    @('N12_TRANSFER_AUTO','Kontrol buffer 2 Auto.',@('LD  %M20','ANDN  %I0.8','ANDN  %M34','ST  %M13')),
    @('N13_REJECT_CAPTURE','Latch produk NG.',@('LDR  %I0.9','ANDN  %I0.10','AND  %M10','S  %M22','S  %M24')),
    @('N14_REJECT_POSITION','Delay produk ke pusher.',@('BLK  %C2','LD  %S5','AND  %M22','AND  %I0.11','CU','LDN  %M22','ORN  %I0.11','R','END_BLK')),
    @('N15_REJECT_START','Mulai aktuator.',@('LD  %C2.D','S  %M23')),
    @('N17_REJECT_PULSE','Durasi aktuator.',@('BLK  %C3','LD  %S5','AND  %M23','CU','LDN  %M23','R','END_BLK')),
    @('N18_REJECT_DONE','Akhiri reject request.',@('LD  %C3.D','R  %M23','R  %M22')),
    @('N20_JAM_INFEED_COUNTER','Monitor buffer 1.',@('BLK  %C4','LD  %S6','AND  %M14','AND  %I0.7','CU','LDN  %M14','ORN  %I0.7','R','END_BLK')),
    @('N22_JAM_TRANSFER_COUNTER','Monitor buffer 2.',@('BLK  %C5','LD  %S6','AND  %M13','AND  %I0.8','CU','LDN  %M13','ORN  %I0.8','R','END_BLK')),
    @('N24_JAM_OUTFEED_COUNTER','Monitor exit.',@('BLK  %C6','LD  %S6','AND  %M12','AND  %I0.12','CU','LDN  %M12','ORN  %I0.12','R','END_BLK')),
    @('N26_HOME_TIMEOUT_COUNTER','Pusher harus kembali home.',@('BLK  %C7','LD  %S6','AND  %M24','ANDN  %M23','ANDN  %I0.11','CU','LDN  %M24','OR  %I0.11','R','END_BLK')),
    @('N27_LATCH_JAM_INFEED','Latch jam infeed.',@('LD  %C4.D','S  %M30')),
    @('N28_LATCH_JAM_TRANSFER','Latch jam transfer.',@('LD  %C5.D','S  %M31')),
    @('N29_LATCH_JAM_OUTFEED','Latch jam outfeed.',@('LD  %C6.D','S  %M32')),
    @('N30_LATCH_HOME_FAULT','Latch pusher tidak home.',@('LD  %C7.D','S  %M33')),
    @('N31_RESET_JAM_INFEED','Reset jam infeed saat sensor pulih.',@('LD  %M26','ANDN  %I0.7','R  %M30')),
    @('N32_RESET_JAM_TRANSFER','Reset jam transfer saat sensor pulih.',@('LD  %M26','ANDN  %I0.8','R  %M31')),
    @('N33_RESET_JAM_OUTFEED','Reset jam outfeed saat sensor pulih.',@('LD  %M26','ANDN  %I0.12','R  %M32')),
    @('N34_RESET_HOME_FAULT','Reset fault saat pusher home.',@('LD  %M26','AND  %I0.11','R  %M33')),
    @('N35_ALARM','Ringkasan alarm.',@('LD  %M30','OR  %M31','OR  %M32','OR  %M33','ORN  %I0.2','ORN  %I0.3','ORN  %I0.4','ORN  %I0.5','ST  %M34')),
    @('N36_MANUAL_INFEED','Jog maintenance infeed.',@('LD  %M3','ANDN  %M0','AND  %M7','ST  %M41')),
    @('N37_MANUAL_TRANSFER','Jog maintenance transfer.',@('LD  %M4','ANDN  %M0','AND  %M7','ST  %M42')),
    @('N38_MANUAL_OUTFEED','Jog maintenance outfeed.',@('LD  %M5','ANDN  %M0','AND  %M7','ST  %M43')),
    @('N39_FINAL_INFEED','Auto atau jog infeed.',@('LD  %M14','OR  %M41','AND  %M11','ANDN  %M34','ST  %M15')),
    @('N40_FINAL_TRANSFER','Auto atau jog transfer.',@('LD  %M13','OR  %M42','AND  %M11','ANDN  %M34','ST  %M16')),
    @('N41_FINAL_OUTFEED','Auto atau jog outfeed.',@('LD  %M12','OR  %M43','AND  %M11','ANDN  %M34','ST  %M17')),
    @('N42_OUTPUT_INFEED','Output motor infeed.',@('LD  %M15','ST  %Q0.0')),
    @('N43_OUTPUT_TRANSFER','Output motor transfer.',@('LD  %M16','ST  %Q0.1')),
    @('N44_OUTPUT_OUTFEED','Output motor outfeed.',@('LD  %M17','ST  %Q0.2')),
    @('N45_OUTPUT_REJECT','Output solenoid reject.',@('LD  %M23','AND  %M11','ANDN  %M34','ST  %Q0.3')),
    @('N46_EXIT_PULSE','Pulsa produk keluar.',@('LDR  %I0.12','ST  %M25')),
    @('N47_COUNT_GOOD','Counter produk OK.',@('BLK  %C8','LD  %M25','ANDN  %M24','CU','LD  %M40','R','END_BLK')),
    @('N48_COUNT_REJECT','Counter produk reject.',@('BLK  %C9','LD  %M25','AND  %M24','CU','LD  %M40','R','END_BLK')),
    @('N49_CLEAR_PRODUCT','Selesai tracking produk.',@('LD  %M25','R  %M24')),
    @('N50_LAMP_RUN','Lampu run.',@('LD  %M10','ANDN  %M34','ST  %Q0.5')),
    @('N51_LAMP_MAINT','Lampu maintenance.',@('LDN  %M0','AND  %M7','ST  %Q0.6')),
    @('N52_FAULT_OUTPUTS','Lampu fault dan buzzer.',@('LD  %M34','ST  %Q0.7','ST  %Q0.4'))
)

New-M221SmbpProject -TemplatePath (Join-Path $workspaceRoot 'AWGC_3_Pintu_TM221CE24R_REV3.smbp') `
    -OutputPath $OutputPath -ProjectName 'INTEGRATED_3_CONVEYOR_TM221CE24R_REV3' `
    -PouName 'INTEGRATED_3_CONVEYOR_IL' -Inputs $inputs -Outputs $outputs -MemoryDefinitions $memory `
    -CounterDefinitions $counters -Program $program
