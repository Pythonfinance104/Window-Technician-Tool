# Windows Technician Toolkit - unified reports and logs viewer
. (Join-Path $PSScriptRoot 'Common.ps1')
do {
    Clear-Host
    Write-Host 'REPORTS AND LOGS' -ForegroundColor Cyan
    Write-Host '1. List reports  2. List logs  3. Open reports folder  4. Open logs folder  0. Back'
    $c=Read-Host 'Select'
    switch ($c) {
        '1' { Get-ChildItem -LiteralPath $script:ReportsRoot -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize }
        '2' { Get-ChildItem -LiteralPath $script:LogsRoot -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize }
        '3' { Start-Process explorer.exe -ArgumentList ('"{0}"' -f $script:ReportsRoot) }
        '4' { Start-Process explorer.exe -ArgumentList ('"{0}"' -f $script:LogsRoot) }
        '0' { break }
        default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow }
    }
    if ($c -ne '0') { Pause-Toolkit }
} while ($c -ne '0')
