# Windows Technician Toolkit - read-only disk and volume checks
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'

function Get-DiskSummary {
    try {
        $disks = Get-Disk -ErrorAction Stop
        foreach ($disk in $disks) {
            $physical = $null
            try { $physical = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq [string]$disk.Number } | Select-Object -First 1 } catch { }
            [PSCustomObject]@{ Number=$disk.Number; Model=if($physical){$physical.FriendlyName}else{$disk.FriendlyName}; BusType=$disk.BusType; MediaType=if($physical){$physical.MediaType}else{'Unknown'}; SizeGB=[math]::Round($disk.Size/1GB,2); PartitionStyle=$disk.PartitionStyle; OperationalStatus=($disk.OperationalStatus -join ', '); HealthStatus=if($disk.HealthStatus){$disk.HealthStatus}else{'Unknown'} }
        }
    } catch { Write-Warning ('Storage cmdlets unavailable or failed: {0}' -f $_.Exception.Message); Get-CimInstance Win32_DiskDrive | Select-Object Model,InterfaceType,MediaType,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}} }
}
function Show-Volumes {
    try {
        $volumes = Get-Volume -ErrorAction Stop | Where-Object { $_.Size -gt 0 }
        $volumes | Select-Object DriveLetter,FileSystemLabel,FileSystem,@{N='CapacityGB';E={[math]::Round($_.Size/1GB,2)}},@{N='UsedGB';E={[math]::Round(($_.Size-$_.SizeRemaining)/1GB,2)}},@{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,2)}},@{N='FreePercent';E={[math]::Round(100*$_.SizeRemaining/$_.Size,1)}} | Format-Table -AutoSize
        foreach ($volume in ($volumes | Where-Object { $_.DriveLetter -and ($_.SizeRemaining / $_.Size) -lt 0.15 })) {
            Write-Finding -Title 'Low free space' -Detected ("{0}: has {1}% free" -f $volume.DriveLetter,[math]::Round(100*$volume.SizeRemaining/$volume.Size,1)) -Meaning 'The volume is nearing capacity.' -Why 'Windows updates and applications need working space.' -Risk 'MEDIUM RISK' -Action 'Review storage usage and back up data; this tool will not delete files.'
        }
    } catch { Write-Warning ('Volume details unavailable: {0}' -f $_.Exception.Message) }
}
function Show-Partitions { try { Get-Partition -ErrorAction Stop | Select-Object DiskNumber,PartitionNumber,DriveLetter,Type,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize } catch { Write-Warning ('Partition details unavailable: {0}' -f $_.Exception.Message) } }
function Show-Reliability {
    try {
        $physical = @(Get-PhysicalDisk -ErrorAction Stop)
        foreach ($disk in $physical) {
            Write-Host "`nDisk: $($disk.FriendlyName) | reported health: $($disk.HealthStatus)"
            try {
                $counter = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction Stop
                $counter | Select-Object Temperature,Wear,PowerOnHours,ReadErrorsTotal,WriteErrorsTotal | Format-List
                if (-not $counter) { Write-Host 'Reliability values unavailable; disk health is unknown from this check.' -ForegroundColor Yellow }
            } catch { Write-Host 'Reliability/SMART-like details unavailable. This does not establish that the disk is healthy.' -ForegroundColor Yellow }
        }
    } catch { Write-Host 'Physical disk reliability cmdlets unavailable. Health status cannot be determined here.' -ForegroundColor Yellow }
}
function Find-LargeFiles {
    $folder = Read-Host 'Folder to inspect (blank uses Downloads)'
    if ([string]::IsNullOrWhiteSpace($folder)) { $folder = Join-Path $env:USERPROFILE 'Downloads' }
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) { Write-Warning 'Folder does not exist or is inaccessible.'; return }
    $limit = 10
    $files = Get-ChildItem -LiteralPath $folder -File -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First $limit
    if ($files) { $files | Select-Object FullName,@{N='SizeMB';E={[math]::Round($_.Length/1MB,1)}} | Format-Table -AutoSize } else { Write-Host 'No accessible files found.' }
    Write-Host 'Inspection only: no files were deleted or changed.'
}
function Save-DiskReport {
    $body = "Physical disks:`n$(Get-DiskSummary | Format-Table -AutoSize | Out-String)`nVolumes:`n$(try { Get-Volume -ErrorAction Stop | Where-Object {$_.Size -gt 0} | Select-Object DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining,HealthStatus | Format-Table -AutoSize | Out-String } catch { $_.Exception.Message })`nPartitions:`n$(try { Get-Partition -ErrorAction Stop | Format-Table DiskNumber,PartitionNumber,DriveLetter,Type,Size -AutoSize | Out-String } catch { $_.Exception.Message })`nReliability note: unavailable SMART/reliability data must be treated as unknown, not as a healthy result."
    $path = New-ToolkitReport -Category 'DiskHealth' -Body $body
    Write-Host "Report saved: $path" -ForegroundColor Green
}

do {
    Clear-Host
    Write-Host 'STORAGE AND DISK HEALTH' -ForegroundColor Cyan
    Write-Host 'Capacity is total size; used is occupied space; free is available space.'
    Write-Host 'A physical disk may contain partitions; Windows exposes formatted volumes.'
    Write-Host '1. Physical disks  2. Volumes/free-space  3. Partitions'
    Write-Host '4. Reliability indicators  5. Find large files (read-only)  6. Save report  0. Back'
    $choice = Read-Host 'Select'
    switch ($choice) {
        '1' { Get-DiskSummary | Format-Table -AutoSize; Pause-Toolkit }
        '2' { Show-Volumes; Pause-Toolkit }
        '3' { Show-Partitions; Pause-Toolkit }
        '4' { Show-Reliability; Pause-Toolkit }
        '5' { Find-LargeFiles; Pause-Toolkit }
        '6' { Save-DiskReport; Pause-Toolkit }
        '0' { break }
        default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '0')
Write-ToolkitLog -Module 'DiskHealth' -Operation 'Interactive session' -Result 'Ended'
