$logoLines = @(
"           ++++++++++++                      ",
"        ++++++++++++++++++                   ",
"        ++++++++++++++++++  +               ",
"        ++++++++++++++++++ +++++++      ++++",
"       ++++++++++++++++++  +++++++++++++++++",
"       +++++++++++++++++  +++++++++++++++++ ",
"      ++++++++++++++++++  +++++++++++++++++ ",
"     ++++++++++++++++++  ++++++++++++++++++ ",
"     ++++         +++++ +++++++++++++++++++ ",
"       +++++++++++   +  ++++++++++++++++++  ",
"    +++++++++++++++++   ++++++++++++++++++  ",
"   ++++++++++++++++++  +   ++++++++++++     ",
"   ++++++++++++++++++  ++++          +++    ",
"  ++++++++++++++++++  ++++++++++++++++++    ",
"  +++++++++++++++++  ++++++++++++++++++     ",
" ++++++++++++++++++  ++++++++++++++++++     ",
"++++++++++++++++++  ++++++++++++++++++      ",
"++++++++++++++++++  ++++++++++++++++++      ",
"               ++  ++++++++++++++++++       ",
"                   ++++++++++++++++++       ",
"                     +++++++++++++          "
)

$configPath = Join-Path $([System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)) "xpconf.ini"
$config = @{}

function Get-ConsoleColor([string]$colorName) {
    if ([string]::IsNullOrEmpty($colorName)) { return [ConsoleColor]::White }
    $colorName = $colorName.Trim()
    return [Enum]::Parse([ConsoleColor], $colorName, $true)
}

foreach ($line in Get-Content $configPath) {
    if ($line -match '^\s*([^=]+)\s*=\s*(.+)\s*$') {
        $config[$matches[1]] = $matches[2]
    }
}
$logoColor  = Get-ConsoleColor $config["logoColor"]
$textColor1 = Get-ConsoleColor $config["TextColor1"]
$textColor2 = Get-ConsoleColor $config["TextColor2"]

$diskPercent = $false
if ($config.ContainsKey("diskPercent")) { $diskPercent = [System.Convert]::ToBoolean($config["diskPercent"]) }

$showVRAM = $false
if ($config.ContainsKey("showVRAM")) { $showVRAM = [System.Convert]::ToBoolean($config["showVRAM"]) }

$ramPercent = $false
if ($config.ContainsKey("ramPercent")) { $ramPercent = [System.Convert]::ToBoolean($config["ramPercent"]) }

function Convert-WmiDate($wmiDate) { 
    return [datetime]::ParseExact($wmiDate.Substring(0,14), "yyyyMMddHHmmss", $null)
}

$os = Get-WmiObject Win32_OperatingSystem
$cs = Get-WmiObject Win32_ComputerSystem
$model = $cs.Model
$cpuName = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -Name "ProcessorNameString"
$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
$gpuObjects = Get-WmiObject Win32_VideoController
$gpuCount = $gpuObjects.Count
$gpuLines = @()

$gpuIndex = 1
foreach ($gpu in $gpuObjects) {
    if ($showVRAM -eq $true) {
        if ($gpu.AdapterRAM) { 
            $vramMB = [math]::Round($gpu.AdapterRAM / 1MB)
            $gpuName = "$($gpu.Name) ($vramMB MB)"
        } else {
            $gpuName = "$($gpu.Name) (Unknown VRAM)"
        }
    } else {
        $gpuName = $gpu.Name
    }

    if ($gpuCount -gt 1) {
        $gpuLabel = "GPU${gpuIndex}: "
        $gpuLines += ,@($gpuLabel, $gpuName)
        $gpuIndex++
    } else {
        $gpuLabel = "GPU: "
        $gpuLines += ,@($gpuLabel, $gpuName)
    }
}

$monitorResolutions = @()
foreach ($gpu in $gpuObjects) {
    if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {
        $monitorResolutions += "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
    } elseif ($gpu.VideoModeDescription) {
        $monitorResolutions += $gpu.VideoModeDescription
    }
}
$resolutionLine = @("Resolution: ", ($monitorResolutions -join ", "))

$themeName = "Unknown"
try {
    $themeReg = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ThemeManager" -ErrorAction SilentlyContinue
    if ($themeReg) {
        if ($themeReg.CurrentTheme) { $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themeReg.CurrentTheme) }
        elseif ($themeReg.DllName) { $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themeReg.DllName) }
        if ($themeReg.ThemeActive -eq "0" -and $themeName -eq "Unknown") { $themeName = "Windows Classic" }
    }
} catch { $themeName = "Unknown" }

$validIPs = @()
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null -and $_.IPEnabled -eq $true }
foreach ($adapter in $adapters) {
    foreach ($ip in $adapter.IPAddress) {
        if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$' -and $ip -ne "0.0.0.0" -and -not $ip.StartsWith("127.") -and -not $ip.StartsWith("169.")) {
            $validIPs += $ip
        }
    }
}
$ipAddress = if ($validIPs.Count -gt 0) { $validIPs[0] } else { "Unknown" }

$uptime = ((Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime))
$uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

$username = $cs.UserName
if ($username -like "*\*") { $username = $username.Split('\')[-1] }
$userHostLine = "$username@$($cs.Name)"
$separatorLine = "-" * $userHostLine.Length

$totalMemoryKB = $os.TotalVisibleMemorySize
$freeMemoryKB = $os.FreePhysicalMemory
$usedMemoryKB = $totalMemoryKB - $freeMemoryKB
$totalMB = [math]::Round($totalMemoryKB / 1024)
$usedMB = [math]::Round($usedMemoryKB / 1024)
$ramDisplay = "$usedMB MB / $totalMB MB"
if ($ramPercent) {
    $ramPercentUsed = [math]::Round(($usedMemoryKB / $totalMemoryKB) * 100)
    $ramDisplay += " ($ramPercentUsed`%)"
}

$driveInfoLines = @()
$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"
foreach ($drive in $drives) {
    if ($drive.Size -and $drive.FreeSpace) {
        $totalGB = [math]::Round($drive.Size / 1GB, 1)
        $usedGB = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 1)
        $display = "$usedGB GB / $totalGB GB"
        if ($diskPercent) {
            $percentUsed = [math]::Round((($drive.Size - $drive.FreeSpace)/$drive.Size)*100)
            $display += " ($percentUsed`%)"
        }
        $driveInfoLines += ,@("$($drive.DeviceID) ", $display)
    }
}

$topInfoLines = @(@("", $userHostLine), @("", $separatorLine))
$infoLines = @(
    @("OS: ", $os.Caption),
    @("Version: ", $os.Version),
    @("IP: ", $ipAddress),
    @("Model: ", $model),
    @("CPU: ", $cpuName.ProcessorNameString),
    @("Cores: ", $cpu.NumberOfCores),
    @("RAM: ", $ramDisplay)
)

$finalInfoLines = @()
for ($i = 0; $i -lt $infoLines.Count; $i++) {
    $finalInfoLines += ,$infoLines[$i]
    if ($infoLines[$i][0] -eq "RAM: ") {
        foreach ($line in $driveInfoLines) { $finalInfoLines += ,$line }
    }
}

$finalInfoLines += $gpuLines
$finalInfoLines += ,$resolutionLine
$finalInfoLines += ,@("Theme: ", $themeName)
$finalInfoLines += ,@("Uptime: ", $uptimeStr)
$allInfoLines = $topInfoLines + $finalInfoLines
$logoHeight = $logoLines.Count
$infoHeight = $allInfoLines.Count
$paddingTop = [Math]::Max([Math]::Floor(($logoHeight - $infoHeight) / 2), 0)
$paddedInfoLines = @()
for ($i = 0; $i -lt $paddingTop; $i++) { $paddedInfoLines += ,@("","") }
$paddedInfoLines += $allInfoLines
$maxLines = [Math]::Max($logoLines.Count, $paddedInfoLines.Count)

Write-Host ""
for ($i = 0; $i -lt $maxLines; $i++) {
    $logo = if ($i -lt $logoLines.Count) { $logoLines[$i] } else { " " * 42 }
    if ($i -lt $paddedInfoLines.Count) {
        $label = $paddedInfoLines[$i][0]
        $value = $paddedInfoLines[$i][1]
    } else { $label = ""; $value = "" }

    Write-Host -NoNewline $logo -ForegroundColor $logoColor
    Write-Host -NoNewline "    "

    if ($value -ne "") {
        if ($label -eq "") {
            Write-Host $value -ForegroundColor White
        } else {
            Write-Host $label -NoNewline -ForegroundColor $textColor1
            Write-Host $value -ForegroundColor $textColor2
        }
    } else { Write-Host "" }
}
Write-Host ""
