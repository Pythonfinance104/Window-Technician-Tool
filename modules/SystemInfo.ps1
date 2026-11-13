# =====================================================

# WINDOWS TECHNICIAN TOOLKIT

# MODULE: SYSTEM INFORMATION

# Technology: PowerShell

# =====================================================

Clear-Host

Write-Host "============================================" -ForegroundColor Yellow
Write-Host "          SYSTEM INFORMATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Yellow

# Retrieve computer information

$Computer = Get-CimInstance Win32_ComputerSystem

# Retrieve operating system information

$OS = Get-CimInstance Win32_OperatingSystem

# Retrieve processor information

$CPU = Get-CimInstance Win32_Processor

# Display computer name

Write-Host "`nCOMPUTER NAME:" -ForegroundColor Green
Write-Host $Computer.Name

# Display manufacturer and model

Write-Host "`nMANUFACTURER:" -ForegroundColor Green
Write-Host $Computer.Manufacturer

Write-Host "`nMODEL:" -ForegroundColor Green
Write-Host $Computer.Model

# Display Windows version

Write-Host "`nOPERATING SYSTEM:" -ForegroundColor Green
Write-Host $OS.Caption

Write-Host "`nWINDOWS VERSION:" -ForegroundColor Green
Write-Host $OS.Version

# Convert memory from bytes to gigabytes

$RAM = [math]::Round($Computer.TotalPhysicalMemory / 1GB, 2)

Write-Host "`nINSTALLED RAM:" -ForegroundColor Green
Write-Host "$RAM GB"

# Display processor details

Write-Host "`nPROCESSOR:" -ForegroundColor Green
Write-Host $CPU.Name

# Display system architecture

Write-Host "`nSYSTEM ARCHITECTURE:" -ForegroundColor Green
Write-Host $OS.OSArchitecture

Write-Host "`n============================================" -ForegroundColor Yellow

# =====================================================
# REPORT GENERATION
# =====================================================

# Ask the technician whether to save the report
$Save = Read-Host "`nSave system report? (Y/N)"

if ($Save -match '^[Yy]$') {

    # Locate the reports directory
    $ReportFolder = Join-Path $PSScriptRoot "..\reports"

    # Ensure the reports directory exists
    if (!(Test-Path $ReportFolder)) {
        New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null
    }

    # Generate a timestamp
    $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Create the report filename
    $ReportFile = Join-Path $ReportFolder "SystemInfo_$Date.txt"

    # Prepare report contents
    $ReportContent = @"
WINDOWS TECHNICIAN TOOLKIT
SYSTEM INFORMATION REPORT

Computer Name: $($Computer.Name)
Manufacturer: $($Computer.Manufacturer)
Model: $($Computer.Model)
Operating System: $($OS.Caption)
Windows Version: $($OS.Version)
RAM: $RAM GB
Processor: $($CPU.Name)
Architecture: $($OS.OSArchitecture)

Generated: $(Get-Date)
"@

    # Write the report to a text file
    try {

        $ReportContent | Set-Content -Path $ReportFile -Encoding UTF8 -ErrorAction Stop

        Write-Host "`nReport saved successfully!" -ForegroundColor Green

        Write-Host "Location: $ReportFile" -ForegroundColor Cyan

    }
    catch {

        Write-Host "`nERROR: Could not save the report." -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow

    }

}
elseif ($Save -match '^[Nn]$') {

    Write-Host "`nReport was not saved." -ForegroundColor Yellow

}
else {

    Write-Host "`nInvalid input. Please enter Y or N." -ForegroundColor Red

}
