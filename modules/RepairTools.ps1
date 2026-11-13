# Windows Technician Toolkit - repair and maintenance
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'
function Invoke-ConfirmedAdminCommand {
    param([string]$Title,[string]$Explanation,[string]$Executable,[string[]]$Arguments)
    Write-Host "`n$Title`n$Explanation" -ForegroundColor Yellow
    Write-Host 'This may modify Windows state. No command runs without confirmation.' -ForegroundColor Red
    if (-not (Test-ToolkitAdministrator)) { Write-Host 'Not started: this process is not elevated. Elevate only if you decide to run it.' -ForegroundColor Red; return }
    if (-not (Read-ToolkitYesNo ('Run ' + $Title + '?'))) { Write-Host 'Cancelled; no operation was run.'; return }
    $started = Get-Date
    try {
        & $Executable @Arguments
        $code = $LASTEXITCODE
        Write-ToolkitLog -Module 'RepairTools' -Operation $Title -Result ("ExitCode={0}" -f $code)
        $summary = "Operation: $Title`nStarted: $started`nFinished: $(Get-Date)`nProcess exit code: $code`nArguments: $Executable $($Arguments -join ' ')"
        $path = New-ToolkitReport -Category 'Repair' -Body $summary
        Write-Host "Operation finished; report: $path"
    } catch { Write-Host ('Operation failed to start: {0}' -f $_.Exception.Message) -ForegroundColor Red; Write-ToolkitLog -Level ERROR -Module 'RepairTools' -Operation $Title -Result 'Failed' -Details $_.Exception.Message }
}
do {
    Clear-Host
    Write-Host 'REPAIR AND MAINTENANCE' -ForegroundColor Cyan
    Write-Host 'A: Diagnostic checks   B: Safe/read-only inspection   C: Administrative repairs'
    Write-Host '1. SFC scan (repair-capable)  2. DISM CheckHealth  3. DISM ScanHealth'
    Write-Host '4. DISM RestoreHealth (modifies component store)  5. Windows Update service status'
    Write-Host '6. DNS cache flush (modifies local resolver cache)  7. System restore point listing'
    Write-Host '8. Startup applications (inspection)  0. Back'
    $c = Read-Host 'Select'
    switch ($c) {
        '1' { Invoke-ConfirmedAdminCommand 'SFC /scannow' 'Checks protected system files and attempts to repair detected corruption.' 'sfc.exe' @('/scannow') }
        '2' { Invoke-ConfirmedAdminCommand 'DISM CheckHealth' 'Checks whether component-store corruption has already been flagged.' 'DISM.exe' @('/Online','/Cleanup-Image','/CheckHealth') }
        '3' { Invoke-ConfirmedAdminCommand 'DISM ScanHealth' 'Scans the component store; it does not repair it.' 'DISM.exe' @('/Online','/Cleanup-Image','/ScanHealth') }
        '4' { Invoke-ConfirmedAdminCommand 'DISM RestoreHealth' 'Attempts component-store repair and may use Windows Update. Allow time and avoid interruption.' 'DISM.exe' @('/Online','/Cleanup-Image','/RestoreHealth') }
        '5' { Get-Service -Name wuauserv,bits -ErrorAction SilentlyContinue | Format-Table Name,Status,StartType -AutoSize }
        '6' { Write-Host 'Flushes only the local DNS resolver cache; it does not change DNS server configuration.'; if (Read-ToolkitYesNo 'Flush DNS cache now?') { ipconfig.exe /flushdns; Write-ToolkitLog -Module 'RepairTools' -Operation 'DNS cache flush' -Result ("ExitCode={0}" -f $LASTEXITCODE) } }
        '7' { try { Get-ComputerRestorePoint -ErrorAction Stop | Select-Object SequenceNumber,Description,CreationTime,RestorePointType | Format-Table -AutoSize } catch { Write-Host ('Restore-point inventory unavailable: {0}' -f $_.Exception.Message) -ForegroundColor Yellow } }
        '8' { Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Select-Object Name,Location,Command,User | Format-Table -Wrap -AutoSize }
        '0' { break }
        default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow }
    }
    if ($c -ne '0') { Pause-Toolkit }
} while ($c -ne '0')
