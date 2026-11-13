# Windows Technician Toolkit - security audit (read-only)
. (Join-Path $PSScriptRoot 'Common.ps1')
$ErrorActionPreference = 'Continue'
$script:SecurityFindings = New-Object System.Collections.Generic.List[string]
function Add-SecurityFinding {
    param([string]$Risk,[string]$Title,[string]$Detected,[string]$Meaning,[string]$Action,[string]$Admin='Usually not required for viewing')
    Write-Finding -Title $Title -Detected $Detected -Meaning $Meaning -Why 'Security controls reduce exposure to malware, unauthorized access, or data loss.' -Risk $Risk -Action ($Action + ' Administrator privileges: ' + $Admin + '.')
    $script:SecurityFindings.Add("[$Risk] $Title`nDetected: $Detected`nMeaning: $Meaning`nRecommended action: $Action`nAdministrator privileges: $Admin")
}
Write-Host 'WINDOWS SECURITY AUDIT' -ForegroundColor Cyan
Write-Host 'Read-only checks. This audit does not change security settings and cannot certify a system as secure.'
try {
    $def = Get-MpComputerStatus -ErrorAction Stop
    Add-SecurityFinding -Risk $(if($def.RealTimeProtectionEnabled){'INFORMATIONAL'}else{'HIGH RISK'}) -Title 'Microsoft Defender real-time protection' -Detected ("Real-time protection enabled: {0}; antivirus enabled: {1}; signatures last updated: {2}" -f $def.RealTimeProtectionEnabled,$def.AntivirusEnabled,$def.AntivirusSignatureLastUpdated) -Meaning 'Defender status as exposed by the local Defender cmdlet.' -Action 'If protection is unexpectedly off, review Windows Security and organizational policy; do not disable other protection.' -Admin 'May be required to change settings'
} catch { Add-SecurityFinding -Risk 'INFORMATIONAL' -Title 'Defender status unavailable' -Detected $_.Exception.Message -Meaning 'This system/provider does not expose Defender status to this session.' -Action 'Check Windows Security or the installed antivirus console; unavailable is not equivalent to protected.' }
try {
    Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object { Add-SecurityFinding -Risk $(if($_.Enabled){'INFORMATIONAL'}else{'HIGH RISK'}) -Title ("Firewall profile: {0}" -f $_.Name) -Detected ("Enabled: {0}; default inbound: {1}" -f $_.Enabled,$_.DefaultInboundAction) -Meaning 'This reports the Windows Defender Firewall profile configuration.' -Action 'If disabled unexpectedly, consult the administrator/security policy before enabling or changing rules.' -Admin 'Required to change firewall configuration' }
} catch { Add-SecurityFinding -Risk 'INFORMATIONAL' -Title 'Firewall profile status unavailable' -Detected $_.Exception.Message -Meaning 'Firewall information could not be queried.' -Action 'Inspect Windows Security or ask an administrator; do not infer firewall state.' }
try {
    $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop
    Add-SecurityFinding -Risk $(if($uac.EnableLUA -eq 1){'INFORMATIONAL'}else{'HIGH RISK'}) -Title 'User Account Control configuration' -Detected ("EnableLUA={0}" -f $uac.EnableLUA) -Meaning 'UAC helps limit unintended administrative changes.' -Action 'Review UAC policy with the system owner if disabled; changing it may require restart.' -Admin 'Required to change registry-backed system policy'
} catch { Add-SecurityFinding -Risk 'INFORMATIONAL' -Title 'UAC status unavailable' -Detected $_.Exception.Message -Meaning 'The UAC configuration could not be read.' -Action 'Review Windows security policy with an administrator.' }
try {
    $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
    Add-SecurityFinding -Risk $(if($secureBoot){'INFORMATIONAL'}else{'MEDIUM RISK'}) -Title 'Secure Boot' -Detected "Enabled: $secureBoot" -Meaning 'Secure Boot helps prevent untrusted boot software on supported UEFI systems.' -Action 'Check firmware support and organizational requirements before changing firmware settings.' -Admin 'Firmware access may be required'
} catch { Add-SecurityFinding -Risk 'INFORMATIONAL' -Title 'Secure Boot status unavailable' -Detected 'Unsupported firmware, legacy boot, or insufficient access.' -Meaning 'This check could not determine Secure Boot state.' -Action 'Check System Information or firmware setup; unavailable is not a failure finding.' }
try {
    $rdp = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction Stop
    $enabled = ($rdp.fDenyTSConnections -eq 0)
    Add-SecurityFinding -Risk $(if($enabled){'MEDIUM RISK'}else{'INFORMATIONAL'}) -Title 'Remote Desktop listener setting' -Detected "Remote Desktop enabled: $enabled" -Meaning 'Remote Desktop can allow remote logon when networking and policy permit.' -Action 'If not needed, consult the device owner/admin before changing the setting; secure approved remote access appropriately.' -Admin 'Required to change'
} catch { Add-SecurityFinding -Risk 'INFORMATIONAL' -Title 'Remote Desktop status unavailable' -Detected $_.Exception.Message -Meaning 'The configuration could not be queried.' -Action 'Review system settings or policy.' }
try {
    $admins = Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | Select-Object Name,ObjectClass,PrincipalSource
    Write-Host "`nLocal Administrators group membership:" -ForegroundColor Cyan
    $admins | Format-Table -AutoSize
    $script:SecurityFindings.Add("Administrator membership queried; see console. Membership requires context review and is not automatically classified as a risk.")
} catch { Write-Host 'Local group membership query unavailable (for example, older Windows/provider or access limitation).' -ForegroundColor Yellow }
try {
    $updates = Get-HotFix -ErrorAction Stop | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($updates) { Write-Host ("Latest listed hotfix: {0}, installed {1}" -f $updates.HotFixID,$updates.InstalledOn) }
    Write-Host 'Hotfix inventory is not a complete Windows Update compliance check.' -ForegroundColor Yellow
} catch { Write-Host 'Hotfix inventory unavailable.' -ForegroundColor Yellow }
$reportBody = if($script:SecurityFindings.Count){$script:SecurityFindings -join "`n`n"}else{'No findings could be collected.'}
if (Read-ToolkitYesNo 'Save security audit report?') { try { $path=New-ToolkitReport -Category 'SecurityAudit' -Body ($reportBody + "`n`nThis limited local audit is not a complete security assessment."); Write-Host "Saved: $path" -ForegroundColor Green } catch { Write-Host ('Report save failed: {0}' -f $_.Exception.Message) -ForegroundColor Red } }
Write-ToolkitLog -Module 'SecurityAudit' -Operation 'Read-only audit' -Result 'Completed'
Pause-Toolkit
