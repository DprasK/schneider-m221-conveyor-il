function New-M221SmbpProject {
    param(
        [Parameter(Mandatory)][string]$TemplatePath,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$PouName,
        [Parameter(Mandatory)][object[]]$Inputs,
        [Parameter(Mandatory)][object[]]$Outputs,
        [Parameter(Mandatory)][object[]]$MemoryDefinitions,
        [Parameter(Mandatory)][object[]]$CounterDefinitions,
        [Parameter(Mandatory)][object[]]$Program
    )

    $ErrorActionPreference = 'Stop'
    [xml]$doc = Get-Content -Raw -LiteralPath $TemplatePath

    function Set-Text {
        param([System.Xml.XmlNode]$Parent, [string]$Name, [string]$Value)
        $child = $Parent.SelectSingleNode($Name)
        if ($null -eq $child) {
            $child = $doc.CreateElement($Name)
            [void]$Parent.AppendChild($child)
        }
        $child.InnerText = $Value
    }

    function Clear-Node {
        param([System.Xml.XmlNode]$Node)
        if ($null -eq $Node) { return }
        while ($Node.HasChildNodes) {
            [void]$Node.RemoveChild($Node.FirstChild)
        }
    }

    function Add-PlcObject {
        param(
            [System.Xml.XmlNode]$Container,
            [string]$NodeName,
            [string]$Address,
            [int]$Index,
            [string]$Symbol,
            [string]$Comment,
            [hashtable]$Properties
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
        foreach ($key in $Properties.Keys) {
            $child = $doc.CreateElement($key)
            $child.InnerText = [string]$Properties[$key]
            [void]$node.AppendChild($child)
        }
        [void]$Container.AppendChild($node)
    }

    function Add-IlRung {
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
            [void]$entity.AppendChild($instruction)
            [void]$entity.AppendChild($doc.CreateElement('Comment'))
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
    $project.Name = $ProjectName
    $project.FullName = [System.IO.Path]::GetFullPath($OutputPath)
    $projectInfo = $project.GlobalProperties.SelectSingleNode("*[local-name()='New project']/Name")
    if ($null -ne $projectInfo) { $projectInfo.InnerText = $ProjectName }

    $pou = $project.SoftwareConfiguration.Pous.ProgramOrganizationUnits
    $pou.Name = $PouName
    $pou.SectionNumber = '1'

    $inputNodes = @($project.HardwareConfiguration.Plc.Cpu.DigitalInputs.DiscretInput)
    for ($index = 0; $index -lt $inputNodes.Count; $index++) {
        $definition = if ($index -lt $Inputs.Count) { $Inputs[$index] } else { @('', 'Tidak digunakan') }
        Set-Text $inputNodes[$index] 'Symbol' $definition[0]
        Set-Text $inputNodes[$index] 'Comment' $definition[1]
    }

    $outputNodes = @($project.HardwareConfiguration.Plc.Cpu.DigitalOutputs.DiscretOutput)
    for ($index = 0; $index -lt $outputNodes.Count; $index++) {
        $definition = if ($index -lt $Outputs.Count) { $Outputs[$index] } else { @('', 'Tidak digunakan') }
        Set-Text $outputNodes[$index] 'Symbol' $definition[0]
        Set-Text $outputNodes[$index] 'Comment' $definition[1]
    }

    $memoryBits = $project.SoftwareConfiguration.SelectSingleNode('MemoryBits')
    Clear-Node $memoryBits
    foreach ($definition in $MemoryDefinitions) {
        Add-PlcObject $memoryBits 'MemoryBit' ("%M{0}" -f $definition[0]) $definition[0] $definition[1] $definition[2] @{}
    }

    $timers = $project.SoftwareConfiguration.SelectSingleNode('Timers')
    Clear-Node $timers
    $counters = $project.SoftwareConfiguration.SelectSingleNode('Counters')
    Clear-Node $counters
    foreach ($definition in $CounterDefinitions) {
        # Counter entities in the SMBP 3.0 schema contain only Address, Index,
        # Symbol, and Comment. Presets are assigned from IL operation blocks.
        Add-PlcObject $counters 'Counter' ("%C{0}" -f $definition[0]) $definition[0] $definition[1] $definition[2] @{}
    }

    $rungs = $pou.Rungs
    Clear-Node $rungs
    foreach ($definition in $Program) {
        Add-IlRung $rungs $definition[0] $definition[1] $definition[2]
    }

    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Encoding = [System.Text.UTF8Encoding]::new($true)
    $settings.Indent = $true
    $settings.NewLineChars = "`r`n"
    $settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $writer = [System.Xml.XmlWriter]::Create($resolvedOutput, $settings)
    try { $doc.Save($writer) } finally { $writer.Dispose() }
    return $resolvedOutput
}
