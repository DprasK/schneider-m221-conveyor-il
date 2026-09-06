param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'CONVEYOR_2_ZONE_ZPA_TM221CE24R_REV2_FIXED.smbp')
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$templatePath = Join-Path $workspaceRoot 'AWGC_3_Pintu_TM221CE24R_REV3.smbp'

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Template TM221CE24R tidak ditemukan: $templatePath"
}

[xml]$doc = Get-Content -Raw -LiteralPath $templatePath

function Set-ChildText {
    param(
        [System.Xml.XmlNode]$Parent,
        [string]$Name,
        [string]$Value
    )

    $child = $Parent.SelectSingleNode($Name)
    if ($null -eq $child) {
        $child = $doc.CreateElement($Name)
        [void]$Parent.AppendChild($child)
    }
    $child.InnerText = $Value
}

function Clear-Children {
    param([System.Xml.XmlNode]$Node)
    while ($Node.HasChildNodes) {
        [void]$Node.RemoveChild($Node.FirstChild)
    }
}

function Add-ObjectNode {
    param(
        [System.Xml.XmlNode]$Container,
        [string]$NodeName,
        [string]$Address,
        [int]$Index,
        [string]$Symbol,
        [string]$Comment
    )

    $node = $doc.CreateElement($NodeName)
    foreach ($item in @(
        @('Address', $Address),
        @('Index', [string]$Index),
        @('Symbol', $Symbol),
        @('Comment', $Comment)
    )) {
        $child = $doc.CreateElement($item[0])
        $child.InnerText = $item[1]
        [void]$node.AppendChild($child)
    }
    [void]$Container.AppendChild($node)
}

function Add-Rung {
    param(
        [System.Xml.XmlNode]$Rungs,
        [string]$Name,
        [string]$Comment,
        [string[]]$Lines
    )

    $rung = $doc.CreateElement('RungEntity')
    [void]$rung.AppendChild($doc.CreateElement('LadderElements'))

    $instructionLines = $doc.CreateElement('InstructionLines')
    foreach ($line in $Lines) {
        $entity = $doc.CreateElement('InstructionLineEntity')
        $instruction = $doc.CreateElement('InstructionLine')
        $instruction.InnerText = $line
        $lineComment = $doc.CreateElement('Comment')
        [void]$entity.AppendChild($instruction)
        [void]$entity.AppendChild($lineComment)
        [void]$instructionLines.AppendChild($entity)
    }
    [void]$rung.AppendChild($instructionLines)

    foreach ($item in @(
        @('Name', $Name),
        @('MainComment', $Comment),
        @('Label', ''),
        @('IsLadderSelected', 'false')
    )) {
        $child = $doc.CreateElement($item[0])
        $child.InnerText = $item[1]
        [void]$rung.AppendChild($child)
    }

    [void]$Rungs.AppendChild($rung)
}

$project = $doc.ProjectDescriptor
$project.Name = 'CONVEYOR_2_ZONE_ZPA_TM221CE24R'
$project.FullName = [System.IO.Path]::GetFullPath($OutputPath)

$projectInfo = $project.GlobalProperties.SelectSingleNode("*[local-name()='New project']/Name")
if ($null -ne $projectInfo) {
    $projectInfo.InnerText = 'CONVEYOR_2_ZONE_ZPA_TM221CE24R'
}

$pou = $project.SoftwareConfiguration.Pous.ProgramOrganizationUnits
$pou.Name = 'CONVEYOR_2_ZONE_ZPA_IL'
$pou.SectionNumber = '1'

$inputs = @(
    @('START_PB', 'Tombol Start NO'),
    @('STOP_OK', 'Kontak Stop NC; 1 = sehat'),
    @('ESTOP_OK', 'Feedback safety relay; 1 = sehat'),
    @('OL_ZONE1_OK', 'Kontak overload motor zona 1; 1 = sehat'),
    @('OL_ZONE2_OK', 'Kontak overload motor zona 2; 1 = sehat'),
    @('SENSOR_INFEED', 'Sensor produk masuk'),
    @('SENSOR_ZONE1', 'Sensor okupansi akhir zona 1'),
    @('SENSOR_ZONE2', 'Sensor okupansi akhir zona 2'),
    @('DOWNSTREAM_READY', 'Peralatan hilir siap menerima produk'),
    @('RESET_PB', 'Tombol reset alarm NO'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan')
)

$inputNodes = @($project.HardwareConfiguration.Plc.Cpu.DigitalInputs.DiscretInput)
for ($index = 0; $index -lt $inputNodes.Count; $index++) {
    Set-ChildText $inputNodes[$index] 'Symbol' $inputs[$index][0]
    Set-ChildText $inputNodes[$index] 'Comment' $inputs[$index][1]
}

$outputs = @(
    @('MOTOR_ZONE1', 'Kontaktor atau VFD run motor zona 1'),
    @('MOTOR_ZONE2', 'Kontaktor atau VFD run motor zona 2'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan'),
    @('BUZZER', 'Buzzer alarm umum'),
    @('LAMP_RUN', 'Lampu sistem berjalan'),
    @('LAMP_FAULT', 'Lampu fault'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan'),
    @('', 'Tidak digunakan')
)

$outputNodes = @($project.HardwareConfiguration.Plc.Cpu.DigitalOutputs.DiscretOutput)
for ($index = 0; $index -lt $outputNodes.Count; $index++) {
    Set-ChildText $outputNodes[$index] 'Symbol' $outputs[$index][0]
    Set-ChildText $outputNodes[$index] 'Comment' $outputs[$index][1]
}

$memoryDefinitions = @(
    @(0, 'AUTO_MODE', '1 = Auto; 0 = Manual'),
    @(1, 'START_HMI', 'Perintah Start HMI momentary'),
    @(2, 'STOP_HMI', 'Perintah Stop HMI'),
    @(3, 'JOG_ZONE1', 'Jog manual motor zona 1'),
    @(4, 'JOG_ZONE2', 'Jog manual motor zona 2'),
    @(5, 'RESET_HMI', 'Reset alarm dari HMI momentary'),
    @(10, 'SYSTEM_RUN', 'Latch sistem produksi'),
    @(11, 'SAFETY_OK', 'Ringkasan Stop E-Stop dan overload'),
    @(12, 'AUTO_ZONE1_CMD', 'Perintah otomatis zona 1'),
    @(13, 'AUTO_ZONE2_CMD', 'Perintah otomatis zona 2'),
    @(14, 'FINAL_ZONE1_CMD', 'Perintah akhir motor zona 1'),
    @(15, 'FINAL_ZONE2_CMD', 'Perintah akhir motor zona 2'),
    @(20, 'JAM_ZONE1_LATCH', 'Alarm macet zona 1 terlatch'),
    @(21, 'JAM_ZONE2_LATCH', 'Alarm macet zona 2 terlatch'),
    @(22, 'ALARM_ACTIVE', 'Alarm umum'),
    @(23, 'RESET_REQUEST', 'Gabungan reset panel dan HMI'),
    @(30, 'PRODUCT_DEMAND_ZONE1', 'Produk meminta zona 1 bergerak'),
    @(31, 'MANUAL_JOG_ZONE1', 'Perintah jog zona 1 tervalidasi'),
    @(32, 'MANUAL_JOG_ZONE2', 'Perintah jog zona 2 tervalidasi')
)

$memoryBits = $project.SoftwareConfiguration.SelectSingleNode('MemoryBits')
Clear-Children $memoryBits
foreach ($definition in $memoryDefinitions) {
    Add-ObjectNode $memoryBits 'MemoryBit' ("%M{0}" -f $definition[0]) $definition[0] $definition[1] $definition[2]
}

$timers = $project.SoftwareConfiguration.SelectSingleNode('Timers')
Clear-Children $timers

$counters = $project.SoftwareConfiguration.SelectSingleNode('Counters')
Clear-Children $counters
Add-ObjectNode $counters 'Counter' '%C0' 0 'JAM_SECONDS_ZONE1' 'Counter pulsa 1 detik untuk jam zona 1; preset dinamis 8'
Add-ObjectNode $counters 'Counter' '%C1' 1 'JAM_SECONDS_ZONE2' 'Counter pulsa 1 detik untuk jam zona 2; preset dinamis 8'

$rungs = $pou.Rungs
Clear-Children $rungs

$program = @(
    @('N01_SAFETY', 'Ringkasan feedback Stop, E-Stop, overload, dan Stop HMI.', @('LD  %I0.1','AND  %I0.2','AND  %I0.3','AND  %I0.4','ANDN  %M2','ST  %M11')),
    @('N02_RESET_REQUEST', 'Gabungkan reset panel dan HMI.', @('LD  %I0.9','OR  %M5','ST  %M23')),
    @('N03_SYSTEM_RUN', 'Latch produksi hanya pada mode Auto dan safety sehat.', @('LD  %I0.0','OR  %M1','OR  %M10','AND  %M0','AND  %M11','ST  %M10')),
    @('N04_ZONE2_AUTO', 'Zona 2 melepas produk hanya bila hilir siap.', @('LD  %M10','AND  %I0.7','AND  %I0.8','ANDN  %M22','ST  %M13')),
    @('N05_ZONE1_DEMAND', 'Produk masuk atau produk di ujung zona 1 menjadi demand.', @('LD  %I0.5','OR  %I0.6','ST  %M30')),
    @('N06_ZONE1_AUTO', 'Zona 1 bergerak bila zona 2 kosong atau sedang melepas.', @('LDN  %I0.7','OR  %M13','AND  %M10','ANDN  %M22','AND  %M30','ST  %M12')),
    @('N07_JOG_ZONE1', 'Validasi jog zona 1 hanya pada mode Manual.', @('LD  %M3','ANDN  %M0','ST  %M31')),
    @('N08_JOG_ZONE2', 'Validasi jog zona 2 hanya pada mode Manual.', @('LD  %M4','ANDN  %M0','ST  %M32')),
    @('N09_FINAL_ZONE1', 'Gabungkan Auto/Jog dengan interlock.', @('LD  %M12','OR  %M31','AND  %M11','ANDN  %M22','ST  %M14')),
    @('N10_FINAL_ZONE2', 'Gabungkan Auto/Jog dengan interlock.', @('LD  %M13','OR  %M32','AND  %M11','ANDN  %M22','ST  %M15')),
    @('N11_COUNTER_PRESET_Z1', 'Preset jam zona 1 = 8 pulsa; gunakan operation block M221.', @('LD  %S13','[ %C0.P := 8 ]')),
    @('N12_JAM_COUNTER_Z1', 'Hitung tepi naik pulsa sistem saat motor diperintah dan sensor zona 1 tetap tertutup.', @('BLK  %C0','LD  %S6','AND  %M14','AND  %I0.6','CU','LDN  %M14','ORN  %I0.6','R','END_BLK')),
    @('N13_COUNTER_PRESET_Z2', 'Preset jam zona 2 = 8 pulsa; gunakan operation block M221.', @('LD  %S13','[ %C1.P := 8 ]')),
    @('N14_JAM_COUNTER_Z2', 'Hitung tepi naik pulsa sistem saat motor diperintah dan sensor zona 2 tetap tertutup.', @('BLK  %C1','LD  %S6','AND  %M15','AND  %I0.7','CU','LDN  %M15','ORN  %I0.7','R','END_BLK')),
    @('N15_LATCH_JAM_Z1', 'Latch alarm saat counter zona 1 selesai.', @('LD  %C0.D','S  %M20')),
    @('N16_LATCH_JAM_Z2', 'Latch alarm saat counter zona 2 selesai.', @('LD  %C1.D','S  %M21')),
    @('N17_RESET_JAM_Z1', 'Reset zona 1 hanya bila sensor sudah bebas.', @('LD  %M23','ANDN  %I0.6','R  %M20')),
    @('N18_RESET_JAM_Z2', 'Reset zona 2 hanya bila sensor sudah bebas.', @('LD  %M23','ANDN  %I0.7','R  %M21')),
    @('N19_ALARM_SUMMARY', 'Alarm jam, E-Stop, atau overload.', @('LD  %M20','OR  %M21','ORN  %I0.2','ORN  %I0.3','ORN  %I0.4','ST  %M22')),
    @('N20_OUTPUT_ZONE1', 'Output fisik motor zona 1.', @('LD  %M14','ST  %Q0.0')),
    @('N21_OUTPUT_ZONE2', 'Output fisik motor zona 2.', @('LD  %M15','ST  %Q0.1')),
    @('N22_LAMP_RUN', 'Lampu Run aktif saat produksi Auto sehat.', @('LD  %M10','ANDN  %M22','ST  %Q0.5')),
    @('N23_FAULT_OUTPUTS', 'Lampu fault dan buzzer mengikuti alarm umum.', @('LD  %M22','ST  %Q0.6','ST  %Q0.4'))
)

foreach ($rungDefinition in $program) {
    Add-Rung $rungs $rungDefinition[0] $rungDefinition[1] $rungDefinition[2]
}

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Encoding = [System.Text.UTF8Encoding]::new($true)
$settings.Indent = $true
$settings.NewLineChars = "`r`n"
$settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$writer = [System.Xml.XmlWriter]::Create($resolvedOutput, $settings)
try {
    $doc.Save($writer)
}
finally {
    $writer.Dispose()
}

Write-Output $resolvedOutput
