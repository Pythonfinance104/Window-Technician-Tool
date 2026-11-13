# Windows Technician Toolkit - network diagnostics (read-only)
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'

function Show-Adapters {
    try { Get-NetAdapter -ErrorAction Stop | Format-Table Name, InterfaceDescription, Status, LinkSpeed -AutoSize }
    catch { Write-Warning ('Adapter cmdlets unavailable or failed: {0}' -f $_.Exception.Message); Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' | Select-Object Name,NetConnectionStatus | Format-Table -AutoSize }
}
function Show-IPConfiguration {
    try { Get-NetIPConfiguration -ErrorAction Stop | Format-List InterfaceAlias,IPv4Address,IPv6Address,IPv4DefaultGateway,IPv6DefaultGateway,DNSServer }
    catch { Write-Warning ('IP configuration unavailable: {0}' -f $_.Exception.Message); ipconfig.exe /all }
}
function Invoke-ConnectivityTest {
    $target = Read-Host 'Enter a domain name or IP address (e.g. example.com)'
    if ([string]::IsNullOrWhiteSpace($target) -or $target -match '[\s;&|<>`$]') { Write-Host 'Invalid destination; use a single domain or IP.' -ForegroundColor Yellow; return }
    Write-Host "`nTesting DNS resolution for $target ..."
    $dnsOk = $false
    try { $resolved = [System.Net.Dns]::GetHostAddresses($target); $dnsOk = $resolved.Count -gt 0; $resolved | ForEach-Object { Write-Host ('Resolved: {0}' -f $_.IPAddressToString) } }
    catch { Write-Finding -Title 'DNS resolution failed' -Detected "Could not resolve $target" -Meaning 'The system could not map the host name to an address.' -Why 'Without name resolution, applications may not reach services by domain name.' -Risk 'MEDIUM RISK' -Action 'Check network connectivity and configured DNS servers; retry with an authorized known domain.' }
    if ($dnsOk) {
        $ping = Test-Connection -ComputerName $target -Count 2 -ErrorAction SilentlyContinue
        if ($ping) { $ping | Select-Object Address,ResponseTime | Format-Table -AutoSize }
        else { Write-Host 'Ping received no reply. Some hosts or networks block ICMP; this alone does not prove internet failure.' -ForegroundColor Yellow }
    }
    if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
        $tcpTarget = Read-Host 'Optional: enter a TCP port to test (blank skips)'
        if ($tcpTarget) {
            $port = 0
            if ([int]::TryParse($tcpTarget,[ref]$port) -and $port -ge 1 -and $port -le 65535) {
                Test-NetConnection -ComputerName $target -Port $port -WarningAction SilentlyContinue | Select-Object ComputerName,RemoteAddress,RemotePort,TcpTestSucceeded | Format-List
            } else { Write-Host 'Port must be an integer from 1 to 65535.' -ForegroundColor Yellow }
        }
    }
}
function New-NetworkDiagnosticReport {
    $adapterText = try { Get-NetAdapter -ErrorAction Stop | Format-Table Name,Status,LinkSpeed -AutoSize | Out-String } catch { 'Adapter details unavailable: ' + $_.Exception.Message }
    $ipText = try { Get-NetIPConfiguration -ErrorAction Stop | Format-List InterfaceAlias,IPv4Address,IPv6Address,IPv4DefaultGateway,DNSServer | Out-String } catch { ipconfig.exe /all | Out-String }
    $body = "Adapters:`n$adapterText`nIP configuration:`n$ipText`nNote: report excludes active TCP connection endpoints to reduce unnecessary exposure of private network data."
    $path = New-ToolkitReport -Category 'Network' -Body $body
    Write-Host "Report saved: $path" -ForegroundColor Green
}

do {
    Clear-Host
    Write-Host 'NETWORK DIAGNOSTICS' -ForegroundColor Cyan
    Write-Host 'Read-only checks; network settings are never changed.'
    Write-Host '1. Network adapters  2. IP/DNS/gateway  3. Test custom destination'
    Write-Host '4. Active TCP connections  5. Listening TCP ports  6. Interface statistics'
    Write-Host '7. Wi-Fi details  8. Save network report  0. Back'
    $choice = Read-Host 'Select'
    switch ($choice) {
        '1' { Show-Adapters; Pause-Toolkit }
        '2' { Show-IPConfiguration; Pause-Toolkit }
        '3' { Invoke-ConnectivityTest; Pause-Toolkit }
        '4' { try { Get-NetTCPConnection -State Established -ErrorAction Stop | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State | Format-Table -AutoSize } catch { Write-Warning $_.Exception.Message }; Pause-Toolkit }
        '5' { try { Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object LocalAddress,LocalPort,State,OwningProcess | Format-Table -AutoSize } catch { Write-Warning $_.Exception.Message }; Pause-Toolkit }
        '6' { try { Get-NetAdapterStatistics -ErrorAction Stop | Format-Table Name,ReceivedBytes,SentBytes,ReceivedDiscardedPackets,OutboundDiscardedPackets -AutoSize } catch { Write-Warning $_.Exception.Message }; Pause-Toolkit }
        '7' { if (Get-Command netsh.exe -ErrorAction SilentlyContinue) { netsh.exe wlan show interfaces } else { Write-Host 'netsh unavailable.' }; Pause-Toolkit }
        '8' { New-NetworkDiagnosticReport; Pause-Toolkit }
        '0' { break }
        default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '0')
Write-ToolkitLog -Module 'NetworkDiagnostics' -Operation 'Interactive session' -Result 'Ended'
