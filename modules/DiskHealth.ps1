# ==========================================
# WINDOWS TECHNICIAN TOOLKIT
# MODULE: DISK HEALTH
# ==========================================

# Function: Get-DiskInformation
# Purpose: Display information about physical disks.

function Get-DiskInformation {

    # Retrieve physical disks connected to Windows.
    $Disks = Get-Disk

    # Display selected information about each disk.
    $Disks | Select-Object `
        Number,
        FriendlyName,
        OperationalStatus,
        HealthStatus,
        PartitionStyle,
        @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}} |
        Format-Table -AutoSize
}

# ==========================================
# FUNCTION: Get-VolumeInformation
# PURPOSE: Display storage volume information.
# ==========================================

function Get-VolumeInformation {

    # Retrieve volumes available to Windows.
    $Volumes = Get-Volume

    # Display useful volume properties.
    $Volumes | Select-Object `
        DriveLetter,
        FileSystem,
        FileSystemLabel,
        HealthStatus,
        OperationalStatus,
        @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
        @{Name="FreeSpace(GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}} |
        Format-Table -AutoSize
}

# ==========================================
# FUNCTION: Get-PartitionInformation
# PURPOSE: Display disk partition information.
# ==========================================

function Get-PartitionInformation {

    # Retrieve partitions from all available disks.
    $Partitions = Get-Partition

    # Display useful partition properties.
    $Partitions | Select-Object `
        DiskNumber,
        PartitionNumber,
        DriveLetter,
        Type,
        @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}} |
        Format-Table -AutoSize
}

# ==========================================
# FUNCTION: Test-LowDiskSpace
# PURPOSE: Identify drives with low free space.
# ==========================================

function Test-LowDiskSpace {

    # Retrieve volumes that have drive letters.
    $Volumes = Get-Volume | Where-Object {
        $_.DriveLetter -and $_.Size -gt 0
    }

    # Examine each volume and calculate free space.
    $Results = foreach ($Volume in $Volumes) {

        # Calculate available space as a percentage.
        $FreePercentage = [math]::Round(
            ($Volume.SizeRemaining / $Volume.Size) * 100, 2
        )

        # Determine whether the drive has low space.
        if ($FreePercentage -lt 15) {
            $Status = "LOW SPACE"
        }
        else {
            $Status = "OK"
        }

        # Create an organized result for each drive.
        [PSCustomObject]@{
            Drive        = $Volume.DriveLetter
            FreeSpaceGB  = [math]::Round($Volume.SizeRemaining / 1GB, 2)
            TotalSizeGB  = [math]::Round($Volume.Size / 1GB, 2)
            FreePercent  = $FreePercentage
            Status       = $Status
        }
    }

    # Display the results.
    $Results | Format-Table -AutoSize

    # Warn if any drive has less than 15% free space.
    if ($Results.Status -contains "LOW SPACE") {
        Write-Warning "One or more drives have low available storage!"
    }
}

# ==========================================
# FUNCTION: Get-LargestFiles
# PURPOSE: Find the largest files in Downloads.
# ==========================================

function Get-LargestFiles {

    # Identify the Downloads directory.
    $DownloadFolder = Join-Path $env:USERPROFILE "Downloads"

    # Check whether the Downloads directory exists.
    if (!(Test-Path $DownloadFolder)) {

        Write-Warning "Downloads folder was not found."
        return
    }

    # Retrieve files from the Downloads directory.
    $Files = Get-ChildItem -Path $DownloadFolder -File `
        -ErrorAction SilentlyContinue

    # Sort files from largest to smallest.
    $LargestFiles = $Files |
        Sort-Object Length -Descending |
        Select-Object -First 10

    # Display the results.
    $LargestFiles | Select-Object `
        Name,
        @{Name="Size(MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}} |
        Format-Table -AutoSize
}

# ==========================================
# FUNCTION: Get-DiskReliability
# PURPOSE: Retrieve available disk reliability indicators.
# ==========================================

function Get-DiskReliability {

    # Retrieve physical disks.
    $Disks = Get-PhysicalDisk

    # Examine each physical disk.
    foreach ($Disk in $Disks) {

        Write-Host "`nDisk: $($Disk.FriendlyName)" -ForegroundColor Cyan

        try {

            # Retrieve available reliability information.
            $Reliability = Get-StorageReliabilityCounter `
                -PhysicalDisk $Disk -ErrorAction Stop

            # Display selected reliability indicators.
            $Reliability | Select-Object `
                Temperature,
                Wear,
                PowerOnHours,
                ReadErrorsTotal,
                WriteErrorsTotal |
                Format-List

        }
        catch {

            # Display an explanation if information is unavailable.
            Write-Warning "Reliability information is unavailable for this disk."
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
}




# Run the function.
Get-DiskInformation
# Execute the function.
Get-VolumeInformation
# Execute the function.
Get-PartitionInformation
#Test for low disk space.
Test-LowDiskSpace

#find Largest files in Download
Get-LargestFiles
#Display disk reliability information.
Get-DiskReliability