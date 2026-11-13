# Windows Technician Toolkit - hardware inventory
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'
function Show-HardwareInventory {
    $sections = @()
    try { $sections += "PROCESSORS`n$(Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | Format-Table -AutoSize | Out-String)" } catch { $sections += "Processor query failed: $($_.Exception.Message)" }
    try { $sections += "MEMORY MODULES`n$(Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,@{N='CapacityGB';E={[math]::Round($_.Capacity/1GB,2)}},Speed,ConfiguredClockSpeed | Format-Table -AutoSize | Out-String)" } catch { $sections += "Memory query failed: $($_.Exception.Message)" }
    try { $sections += "MOTHERBOARD`n$(Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer,Product,Version | Format-List | Out-String)" } catch { $sections += "Board query failed: $($_.Exception.Message)" }
    try { $sections += "BIOS/UEFI`n$(Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,ReleaseDate | Format-List | Out-String)" } catch { $sections += "Firmware query failed: $($_.Exception.Message)" }
    try { $sections += "GRAPHICS`n$(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,VideoModeDescription | Format-Table -AutoSize | Out-String)" } catch { $sections += "Graphics query failed: $($_.Exception.Message)" }
    try { $sections += "MONITORS (available EDID data)`n$(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop | ForEach-Object { [PSCustomObject]@{ Manufacturer=([char[]]$_.ManufacturerName | Where-Object {$_ -ne 0}) -join ''; Product=([char[]]$_.UserFriendlyName | Where-Object {$_ -ne 0}) -join '' } } | Format-Table -AutoSize | Out-String)" } catch { $sections += 'Monitor details unavailable through the current Windows provider.' }
    try { $sections += "DISKS`n$(Get-CimInstance Win32_DiskDrive | Select-Object Model,InterfaceType,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize | Out-String)" } catch { $sections += "Disk query failed: $($_.Exception.Message)" }
    try { $sections += "NETWORK ADAPTERS`n$(Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' | Select-Object Name,NetConnectionStatus,Speed | Format-Table -AutoSize | Out-String)" } catch { $sections += "Network query failed: $($_.Exception.Message)" }
    try { $sections += "BATTERY`n$(Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object Name,EstimatedChargeRemaining,BatteryStatus | Format-List | Out-String)" } catch { $sections += 'Battery not present or battery information unavailable.' }
    try {
        $problem = @(Get-CimInstance Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction Stop | Select-Object Name,PNPClass,ConfigManagerErrorCode)
        $sections += "DEVICES REPORTING CONFIGURATION ERRORS`n$(if($problem){$problem | Format-Table -AutoSize | Out-String}else{'No devices reported a nonzero configuration error code by this query.'})"
    } catch { $sections += "Device status query unavailable: $($_.Exception.Message)" }
    $sections | ForEach-Object { Write-Host "`n$_" }
    Write-Host 'Hardware details depend on device firmware and Windows providers; missing fields do not prove a component is absent.' -ForegroundColor Yellow
    if (Read-ToolkitYesNo 'Save hardware report?') { $path=New-ToolkitReport -Category 'Hardware' -Body ($sections -join "`n`n"); Write-Host "Saved: $path" -ForegroundColor Green }
}
try { Show-HardwareInventory; Write-ToolkitLog -Module 'HardwareInfo' -Operation 'Inventory' -Result 'Completed' } catch { Write-Host $_.Exception.Message -ForegroundColor Red; Write-ToolkitLog -Level ERROR -Module 'HardwareInfo' -Operation 'Inventory' -Result 'Failed' -Details $_.Exception.Message }
Pause-Toolkit
