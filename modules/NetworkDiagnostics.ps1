# =====================================================
# WINDOWS TECHNICIAN TOOLKIT
# MODULE: NETWORK DIAGNOSTICS
# VERSION: 3.1
# TECHNOLOGY: POWERSHELL
# =====================================================


# Display the network diagnostics menu

function Show-NetworkMenu {

    Clear-Host

    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "          NETWORK DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "1. Network Adapters"
    Write-Host "2. IP Configuration"
    Write-Host "3. Test Internet Connectivity"
    Write-Host "4. Test DNS Resolution"
    Write-Host "5. Trace Network Route"
    Write-Host "6. View Active Connections"
    Write-Host "7. Generate Network Report"
    Write-Host "8. Back to Main Menu"

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Yellow

}


# =====================================================
# OPTION 1: NETWORK ADAPTERS
# =====================================================

function Get-NetworkAdapters {

    Write-Host "`nNETWORK ADAPTER INFORMATION" -ForegroundColor Cyan

    # Retrieve installed network adapters

    Get-NetAdapter |
    Format-Table Name, InterfaceDescription, Status, MacAddress, LinkSpeed -AutoSize

}


# =====================================================
# OPTION 2: IP CONFIGURATION
# =====================================================

function Get-IPInformation {

    Write-Host "`nIP CONFIGURATION" -ForegroundColor Cyan

    # Retrieve IP configuration information

    Get-NetIPConfiguration |
    Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer

}


# =====================================================
# OPTION 3: INTERNET CONNECTIVITY
# =====================================================

function Test-InternetConnection {

    Write-Host "`nTESTING INTERNET CONNECTIVITY" -ForegroundColor Cyan

    # Test connectivity to Cloudflare using HTTPS port 443

    Test-NetConnection -ComputerName 1.1.1.1 -Port 443

}


# =====================================================
# OPTION 4: DNS RESOLUTION
# =====================================================

function Test-DNSResolution {

    Write-Host "`nTESTING DNS RESOLUTION" -ForegroundColor Cyan

    # Resolve the domain name into IP addresses

    Resolve-DnsName google.com

}


# =====================================================
# OPTION 5: TRACE NETWORK ROUTE
# =====================================================

function Trace-NetworkRoute {

    Write-Host "`nTRACING NETWORK ROUTE" -ForegroundColor Cyan

    # Identify the network path towards the destination

    Test-NetConnection -ComputerName google.com -TraceRoute

}


# =====================================================
# OPTION 6: ACTIVE NETWORK CONNECTIONS
# =====================================================

function Get-ActiveConnections {

    Write-Host "`nACTIVE TCP CONNECTIONS" -ForegroundColor Cyan

    # Retrieve established TCP connections

    Get-NetTCPConnection -State Established |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
    Format-Table -AutoSize

}


# =====================================================
# OPTION 7: GENERATE NETWORK REPORT
# =====================================================

function New-NetworkReport {

    Write-Host "`nGENERATING NETWORK REPORT..." -ForegroundColor Cyan

    # Locate the reports directory

    $ReportFolder = Join-Path $PSScriptRoot "..\reports"

    # Create the reports folder if missing

    if (!(Test-Path $ReportFolder)) {

        New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null

    }

    # Generate a timestamp

    $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Create report filename

    $ReportFile = Join-Path $ReportFolder "NetworkReport_$Date.txt"


    try {

        # Collect network information

        $Adapters = Get-NetAdapter | Format-Table -AutoSize | Out-String

        $IPInfo = Get-NetIPConfiguration | Format-List | Out-String

        $Internet = Test-NetConnection 1.1.1.1 -Port 443 -WarningAction SilentlyContinue | Out-String

        $DNS = Resolve-DnsName google.com -ErrorAction Continue | Out-String

        $Connections = Get-NetTCPConnection -State Established |
        Format-Table -AutoSize | Out-String


        # Combine the information into one report

        $ReportContent = @"

WINDOWS TECHNICIAN TOOLKIT
NETWORK DIAGNOSTIC REPORT

Generated: $(Get-Date)

========================================
NETWORK ADAPTERS
========================================

$Adapters

========================================
IP CONFIGURATION
========================================

$IPInfo

========================================
INTERNET CONNECTIVITY
========================================

$Internet

========================================
DNS RESOLUTION
========================================

$DNS

========================================
ACTIVE TCP CONNECTIONS
========================================

$Connections

"@

        # Save the report

        $ReportContent |
        Set-Content -Path $ReportFile -Encoding UTF8 -ErrorAction Stop


        Write-Host "`nNETWORK REPORT GENERATED SUCCESSFULLY!" -ForegroundColor Green

        Write-Host "Location: $ReportFile" -ForegroundColor Cyan

    }

    catch {

        Write-Host "`nERROR GENERATING REPORT!" -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow

    }

}


# =====================================================
# MAIN MODULE EXECUTION
# =====================================================

do {

    Show-NetworkMenu

    $NetworkChoice = Read-Host "Select an option"

    switch ($NetworkChoice) {

        "1" {
            Get-NetworkAdapters
            Pause
        }

        "2" {
            Get-IPInformation
            Pause
        }

        "3" {
            Test-InternetConnection
            Pause
        }

        "4" {
            Test-DNSResolution
            Pause
        }

        "5" {
            Trace-NetworkRoute
            Pause
        }

        "6" {
            Get-ActiveConnections
            Pause
        }

        "7" {
            New-NetworkReport
            Pause
        }

        "8" {
            return
        }

        default {

            Write-Host "`nInvalid selection!" -ForegroundColor Red

            Start-Sleep -Seconds 2

        }

    }

} while ($true)
