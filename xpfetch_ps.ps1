$XPFetchVersion = "1.32"

$origFG = [Console]::ForegroundColor
$origBG = [Console]::BackgroundColor

# Color map
$LogoColorMap = @{
  'k'  = [ConsoleColor]::Black
  'd'  = [ConsoleColor]::DarkGray
  'l'  = [ConsoleColor]::Gray
  'w'  = [ConsoleColor]::White
  'r'  = [ConsoleColor]::Red
  'g'  = [ConsoleColor]::Green
  'b'  = [ConsoleColor]::Blue
  'c'  = [ConsoleColor]::Cyan
  'm'  = [ConsoleColor]::Magenta
  'y'  = [ConsoleColor]::Yellow
  'dr' = [ConsoleColor]::DarkRed
  'dg' = [ConsoleColor]::DarkGreen
  'db' = [ConsoleColor]::DarkBlue
  'dc' = [ConsoleColor]::DarkCyan
  'dm' = [ConsoleColor]::DarkMagenta
  'dy' = [ConsoleColor]::DarkYellow
}

# FAST parser
function Parse-ColoredLine {
    param(
        [string]$Line,
        [ConsoleColor]$DefaultColor,
        [hashtable]$ColorMap
    )

    $segments = New-Object System.Collections.ArrayList
    $sb = New-Object System.Text.StringBuilder
    $cur = $DefaultColor
    $i = 0

    while ($i -lt $Line.Length) {
        $ch = $Line[$i]
        if ($ch -eq '{') {
            $end = $Line.IndexOf('}', $i + 1)
            if ($end -gt $i) {
                if ($sb.Length -gt 0) {
                    $null = $segments.Add(@{ Text = $sb.ToString(); Color = $cur })
                    [void]$sb.Remove(0, $sb.Length)
                }
                $tag = $Line.Substring($i + 1, $end - $i - 1)
                if ($tag -eq "/") { $cur = $DefaultColor }
                elseif ($ColorMap.ContainsKey($tag)) { $cur = $ColorMap[$tag] }
                $i = $end + 1
                continue
            }
        }
        [void]$sb.Append($ch)
        $i++
    }

    if ($sb.Length -gt 0) {
        $null = $segments.Add(@{ Text = $sb.ToString(); Color = $cur })
    }

    $len = 0
    foreach ($seg in $segments) { $len += $seg.Text.Length }

    return @{ Segments = $segments; Length = $len }
}

# FAST writer (PS2-safe)
function Write-ColoredSegments {
    param($ParsedLine)
    foreach ($seg in $ParsedLine.Segments) {
        [Console]::ForegroundColor = $seg.Color
        [Console]::Write($seg.Text)
    }
}

#  Config & helpers
$configPath = "$env:APPDATA\xpfetch\xpconf.ini"
$config = @{}

function Get-ConsoleColor([string]$colorName) {
    if ([string]::IsNullOrEmpty($colorName)) { return [ConsoleColor]::White }
    $colorName = $colorName.Trim()
    return [Enum]::Parse([ConsoleColor], $colorName, $true)
}

if (Test-Path $configPath) {
    foreach ($line in Get-Content $configPath) {
        if ($line -match '^\s*([^=]+)\s*=\s*(.+)\s*$') {
            $key = $matches[1].ToLower()
            $config[$key] = $matches[2]
        }
    }
}

function Resolve-LogoPath {
    param([hashtable]$cfg)
    $defaultLogoDir  = Join-Path $env:APPDATA "xpfetch\logos"
    $logoDir  = if ($cfg.ContainsKey("logodir")  -and $cfg["logodir"].Trim())  { $cfg["logodir"].Trim() }  else { $defaultLogoDir }
    $logoFile = if ($cfg.ContainsKey("logofile") -and $cfg["logofile"].Trim()) { $cfg["logofile"].Trim() } else {
        $id = 1
        if ($cfg.ContainsKey("logoid")) {
            [void][int]::TryParse(($cfg["logoid"].ToString()), [ref]$id)
            if ($id -lt 1) { $id = 1 }
        }
        "logo$($id).txt"
    }
    if ([System.IO.Path]::IsPathRooted($logoFile)) { $logoFile } else { Join-Path $logoDir $logoFile }
}

function Load-LogoLines {
    param([hashtable]$cfg)
    $path = Resolve-LogoPath -cfg $cfg
    if (Test-Path $path) { return ,(Get-Content -LiteralPath $path) }
    @(
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
}

$logoLines = Load-LogoLines -cfg $config

$logoColor  = if ($config.ContainsKey("logocolor")) { Get-ConsoleColor $config["logocolor"] } else { [ConsoleColor]::Cyan }
$textColor1 = if ($config.ContainsKey("textcolor1")) { Get-ConsoleColor $config["textcolor1"] } else { [ConsoleColor]::White }
$textColor2 = if ($config.ContainsKey("textcolor2")) { Get-ConsoleColor $config["textcolor2"] } else { [ConsoleColor]::Gray }

$diskPercent    = ($config.ContainsKey("diskpercent")    -and [System.Convert]::ToBoolean($config["diskpercent"]))
$showVRAM       = ($config.ContainsKey("showvram")       -and [System.Convert]::ToBoolean($config["showvram"]))
$ramPercent     = ($config.ContainsKey("rampercent")     -and [System.Convert]::ToBoolean($config["rampercent"]))
$batteryEnabled = ($config.ContainsKey("batterypercent") -and [System.Convert]::ToBoolean($config["batterypercent"]))

function Convert-WmiDate($wmiDate) { return [datetime]::ParseExact($wmiDate.Substring(0,14), "yyyyMMddHHmmss", $null) }

# Pulling System Info
$os = Get-WmiObject Win32_OperatingSystem
$cs = Get-WmiObject Win32_ComputerSystem
$model = $cs.Model
$cpuName = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -Name "ProcessorNameString"
$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
$gpuObjects = Get-WmiObject Win32_VideoController
$gpuCount = $gpuObjects.Count
$gpuLines = @()

# Battery (safe on desktops)
$battery = $null
$batteryPercent = "N/A"
$batteryStatus  = ""
try {
    $battery = Get-WmiObject Win32_Battery
    if ($battery) { $batteryPercent = "$($battery.EstimatedChargeRemaining)%" }
} catch { }

if ($battery -and $battery.BatteryStatus -ne $null) {
    switch ($battery.BatteryStatus) {
        {@(6,7,8,9) -contains $_}   { $batteryStatus = " (Charging)" }
        {@(1,4,5) -contains $_}     { $batteryStatus = " (Discharging)" }
        {@(3,11) -contains $_}      { $batteryStatus = " (Fully Charged)" }
        default                     { $batteryStatus = " (Unknown)" }
    }
}

# GPUs
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

# Monitors
$monitorResolutions = @()
foreach ($gpu in $gpuObjects) {
    if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {
        $monitorResolutions += "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution) $($gpu.CurrentRefreshRate)Hz"
    } elseif ($gpu.VideoModeDescription) {
        $monitorResolutions += $gpu.VideoModeDescription
    }
}
$resolutionLine = @("Resolution: ", ($monitorResolutions -join ", "))

# Theme
$themeName = "Unknown"
try {
    $themeReg = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ThemeManager" -ErrorAction SilentlyContinue
    if ($themeReg) {
        if ($themeReg.CurrentTheme) { $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themeReg.CurrentTheme) }
        elseif ($themeReg.DllName)   { $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themeReg.DllName) }
        if ($themeReg.ThemeActive -eq "0" -and $themeName -eq "Unknown") { $themeName = "Windows Classic" }
    }
} catch { $themeName = "Unknown" }

# Network
$validIPs = @()
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null -and $_.IPEnabled -eq $true }

foreach ($adapter in $adapters) {
    $ipArr   = @()
    $maskArr = @()
    if ($adapter.IPAddress -ne $null) { $ipArr = @($adapter.IPAddress) }
    if ($adapter.IPSubnet  -ne $null) { $maskArr = @($adapter.IPSubnet)  }

    for ($i = 0; $i -lt $ipArr.Count; $i++) {
        $ip = $ipArr[$i]
        if ($ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { continue }
        if ($ip -eq "0.0.0.0" -or $ip.StartsWith("127.") -or $ip.StartsWith("169.")) { continue }

        $mask = $null
        if ($i -lt $maskArr.Count) { $mask = $maskArr[$i] }

        $cidrBits = $null
        if ($mask) {
            if ($mask -match '^\d{1,2}$') {
                $cidrBits = [int]$mask
            } elseif ($mask -match '^\d{1,3}(\.\d{1,3}){3}$') {
                $cidrBits = 0
                foreach ($oct in ($mask -split '\.')) {
                    $b = [Convert]::ToString([int]$oct, 2).PadLeft(8,'0')
                    $cidrBits += ($b -replace '0','').Length
                }
            }
        }

        if ($cidrBits -ne $null) {
            $validIPs += "$ip/$cidrBits"
        } else {
            $validIPs += $ip
        }
    }
}
$ipAddress = if ($validIPs.Count -gt 0) { $validIPs[0] } else { "Unknown" }

# Uptime
$uptime = ((Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime))
$uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

# Host/User
$username = $cs.UserName
if ($username -like "*\*") { $username = $username.Split('\')[-1] }
$userHostLine = "$username@$($cs.Name)"
$separatorLine = "-" * $userHostLine.Length

# Memory
$totalMemoryKB = $os.TotalVisibleMemorySize
$freeMemoryKB  = $os.FreePhysicalMemory
$usedMemoryKB  = $totalMemoryKB - $freeMemoryKB
$totalMB = [math]::Round($totalMemoryKB / 1024)
$usedMB  = [math]::Round($usedMemoryKB / 1024)

if ($totalMB -ge 4096) {
    $totalGB = [math]::Round($totalMB / 1024, 1)
    $usedGB  = [math]::Round($usedMB / 1024, 1)
    $ramDisplay = "$usedGB GB / $totalGB GB"
} else {
    $ramDisplay = "$usedMB MB / $totalMB MB"
}
if ($ramPercent) {
    $ramPercentUsed = [math]::Round(($usedMemoryKB / $totalMemoryKB) * 100)
    $ramDisplay += " ($ramPercentUsed`%)"
}

# Storage
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

# CPU
$threads = ""
if ($cpu.NumberOfCores -ne $cpu.NumberOfLogicalProcessors){
    $threads = " ($($cpu.NumberOfLogicalProcessors) threads)"
}

# Info lines
$topInfoLines = @(@("", $userHostLine), @("", $separatorLine))
$infoLines = @(
    @("OS: ", $os.Caption),
    @("Version: ", $os.Version),
    @("IP: ", $ipAddress),
    @("Model: ", $model),
    @("CPU: ", $cpuName.ProcessorNameString),
    @("Cores: ", "$($cpu.NumberOfCores)$threads"),
    @("RAM: ", $ramDisplay),
    @("Theme: ", $themeName)
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
if ($batteryEnabled -and $batteryPercent -ne "N/A") {
    $finalInfoLines += ,@("Battery: ", "$($batteryPercent)$batteryStatus")
}
$finalInfoLines += ,@("Uptime: ", $uptimeStr)
$allInfoLines = $topInfoLines + $finalInfoLines

$parsedLogo = @()
$logoWidth = 0
foreach ($ln in $logoLines) {
    $p = Parse-ColoredLine -Line $ln -DefaultColor $logoColor -ColorMap $LogoColorMap
    $parsedLogo += ,$p
    if ($p.Length -gt $logoWidth) { $logoWidth = $p.Length }
}

# Centering-
$logoHeight = $logoLines.Count
$infoHeight = $allInfoLines.Count
$paddingTop = [Math]::Max([Math]::Floor(($logoHeight - $infoHeight) / 2), 0)
$paddedInfoLines = @()
for ($i = 0; $i -lt $paddingTop; $i++) { $paddedInfoLines += ,@("","") }
$paddedInfoLines += $allInfoLines
$maxLines = [Math]::Max($logoLines.Count, $paddedInfoLines.Count)

# Render
Write-Host ""
for ($i = 0; $i -lt $maxLines; $i++) {

    if ($i -lt $parsedLogo.Count) {
        $p = $parsedLogo[$i]
        Write-ColoredSegments -ParsedLine $p
        $pad = [Math]::Max($logoWidth - $p.Length, 0)
        if ($pad -gt 0) { [Console]::Write((" " * $pad)) }
    } else {
        [Console]::Write((" " * $logoWidth))
    }

    [Console]::Write("    ")

    if ($i -lt $paddedInfoLines.Count) {
        $label = $paddedInfoLines[$i][0]
        $value = $paddedInfoLines[$i][1]
    } else { $label = ""; $value = "" }

    if ($value -ne "") {
        if ($label -eq "") {
            Write-Host $value -ForegroundColor White
        } else {
            Write-Host $label -NoNewline -ForegroundColor $textColor1
            Write-Host $value -ForegroundColor $textColor2
        }
    } else {
        Write-Host ""
    }
}

[Console]::ForegroundColor = $origFG
[Console]::BackgroundColor = $origBG
