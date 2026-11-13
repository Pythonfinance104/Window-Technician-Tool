# Windows Technician Toolkit - administrative inventory (read-only)
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'
function Show-AdminInventory {
    do {
        Clear-Host
        Write-Host 'SYSTEM ADMINISTRATION - READ-ONLY INVENTORY' -ForegroundColor Cyan
        Write-Host '1. Running processes  2. Services  3. Startup entries  4. Logged-in sessions'
        Write-Host '5. Local administrators  6. Scheduled tasks  7. Resource snapshot'
        Write-Host '8. Recent System event errors  9. Installed applications  0. Back'
        $c = Read-Host 'Select'
        switch ($c) {
            '1' { Get-Process | Sort-Object CPU -Descending | Select-Object -First 30 ProcessName,Id,CPU,WorkingSet64 | Format-Table -AutoSize }
            '2' { Get-Service | Sort-Object Status,DisplayName | Format-Table -AutoSize }
            '3' { Get-CimInstance Win32_StartupCommand | Select-Object Name,Location,User,Command | Format-Table -Wrap -AutoSize }
            '4' { try { quser.exe } catch { Write-Host 'Session listing command unavailable.' } }
            '5' { try { Get-LocalGroupMember -Group Administrators | Format-Table Name,ObjectClass,PrincipalSource -AutoSize } catch { Write-Host ('Local group query unavailable: {0}' -f $_.Exception.Message) } }
            '6' { Get-ScheduledTask -ErrorAction SilentlyContinue | Select-Object TaskName,TaskPath,State | Format-Table -AutoSize }
            '7' { $os=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average; [PSCustomObject]@{CpuLoadPercent=[math]::Round($cpu.Average,1);FreeRAMGB=[math]::Round($os.FreePhysicalMemory/1MB,2);TotalRAMGB=[math]::Round($os.TotalVisibleMemorySize/1MB,2)} | Format-List }
            '8' { try { Get-WinEvent -FilterHashtable @{LogName='System';Level=2;StartTime=(Get-Date).AddDays(-3)} -MaxEvents 30 -ErrorAction Stop | Select-Object TimeCreated,ProviderName,Id,LevelDisplayName,Message | Format-List } catch { Write-Host ('Event log query unavailable: {0}' -f $_.Exception.Message) } }
            '9' { $paths=@('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'); Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher | Sort-Object DisplayName | Format-Table -AutoSize }
            '0' { break }
            default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow }
        }
        if ($c -ne '0') { Pause-Toolkit }
    } while ($c -ne '0')
}
Show-AdminInventory
Write-ToolkitLog -Module 'AdminTools' -Operation 'Read-only inventory' -Result 'Completed'
