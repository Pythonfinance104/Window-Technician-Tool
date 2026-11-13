# Windows Technician Toolkit - System information
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Stop'
try {
    Write-Host "`nSYSTEM DIAGNOSTICS`n" -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = @(Get-CimInstance Win32_Processor)
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $gpu = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)
    $disks = @(Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue)
    $nics = @(Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' -ErrorAction SilentlyContinue)
    $installed = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $available = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $boot = $os.LastBootUpTime
    $uptime = (Get-Date) - $boot
    $installDate = try { [Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate) } catch { $null }

    $lines = @(
        "Computer: $($cs.Name)", "Manufacturer/model: $($cs.Manufacturer) / $($cs.Model)",
        "CPU: $(($cpu | ForEach-Object { $_.Name.Trim() }) -join '; ')",
        "CPU cores/logical processors: $(($cpu | Measure-Object -Property NumberOfCores -Sum).Sum) / $(($cpu | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)",
        "Installed RAM: $installed GB", "Currently available RAM: $available GB",
        "BIOS: $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)", "Motherboard: $($board.Manufacturer) $($board.Product)",
        "Windows: $($os.Caption)", "Version/build: $($os.Version) / $($os.BuildNumber)",
        "Architecture: $($os.OSArchitecture)", "Install date: $installDate",
        "Uptime: {0} days, {1} hours" -f [math]::Floor($uptime.TotalDays), $uptime.Hours,
        '', 'Graphics adapters:'
    )
    $lines += $gpu | ForEach-Object { '  {0} ({1} MB adapter memory reported)' -f $_.Name, [math]::Round($_.AdapterRAM / 1MB) }
    $lines += 'Storage devices:'
    $lines += $disks | ForEach-Object { '  {0} | {1} GB | {2}' -f $_.Model, [math]::Round($_.Size / 1GB,2), $_.MediaType }
    $lines += 'Physical network adapters:'
    $lines += $nics | ForEach-Object { '  {0} | {1}' -f $_.Name, $_.NetConnectionStatus }
    $lines | ForEach-Object { Write-Host $_ }
    Write-Host "`nInstalled RAM is physical memory. Available RAM is an OS snapshot and changes as programs run."
    if ($installed -lt 8) { Write-Finding -Title 'Installed memory capacity' -Detected "$installed GB physical RAM" -Meaning 'This is a relatively limited memory capacity for modern multitasking.' -Why 'Many applications open at once may increase paging to storage.' -Risk 'INFORMATIONAL' -Action 'Check actual workload and memory pressure before considering an upgrade.' }
    $report = ($lines -join [Environment]::NewLine) + "`n`nMeaning: Installed RAM is physical memory; available RAM is a point-in-time measurement.`n"
    if (Read-ToolkitYesNo 'Save a system report?') { $path = New-ToolkitReport -Category 'SystemInfo' -Body $report; Write-Host "Saved: $path" -ForegroundColor Green }
    Write-ToolkitLog -Module 'SystemInfo' -Operation 'CIM inventory' -Result 'Completed'
} catch {
    Write-Host ('System information collection failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-ToolkitLog -Level ERROR -Module 'SystemInfo' -Operation 'CIM inventory' -Result 'Failed' -Details $_.Exception.Message
}
Pause-Toolkit
