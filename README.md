# Windows Technician Toolkit

A modular, offline-capable Windows troubleshooting utility built with Windows Batch and Windows PowerShell. It provides read-only system, hardware, network, storage, security, and administration inventories, plus explicitly confirmed Windows repair operations.

## Compatibility

- Windows 10 and Windows 11 (primary target).
- Windows PowerShell 5.1; no third-party dependencies.
- Some commands depend on Windows edition, provider support, hardware, or elevation. Unavailable data is reported as unavailable, not treated as a healthy result.

## Launch

Run `TechnicianToolKit.bat` from File Explorer, Command Prompt, or PowerShell. Use the menus to select a category. The launcher does not elevate itself. Start an elevated terminal only when you intentionally select an operation requiring administrator rights.

## Categories

- System diagnostics: Windows and computer inventory, uptime, memory, CPU, graphics, disks, and adapters.
- Network diagnostics: adapter and IP settings, DNS and custom-target connectivity checks, TCP connection/listening summaries, Wi-Fi details, and reports. Does not change network settings.
- Storage and disk health: physical disks, partitions, volume capacity/usage, available reliability data, and optional large-file listing. No files are deleted. Missing reliability data is unknown, not a healthy result.
- Hardware information: CPU, memory modules, board, firmware, graphics, monitor data where exposed, storage/network devices, battery and device error codes.
- Security audit: selected Defender, firewall, UAC, Secure Boot, Remote Desktop, local administrator membership and hotfix checks. Read-only and not a certification of security.
- Repair and maintenance: SFC/DISM options, Windows Update service inspection, DNS cache flush, restore point listing and startup inspection. Repair-capable actions explain the effect, require confirmation, and require elevation where appropriate.
- Administration: read-only process/service/startup/user/group/task/resource/event/application inventory.
- Reports and logs: lists or opens generated output folders.

## Output and privacy

Reports are saved under `reports/`; logs are under `logs/`. Generated files are ignored by Git. Reports and local inventory may reveal hostnames, software, hardware, network configuration, or account names; review before sharing. The logger attempts to redact obvious password/token/secret assignments but should not be treated as a secure secret-handling boundary.

## Safety

- No automatic repair based on findings.
- No automatic security-control changes, network setting changes, user-file deletion, registry modification, formatting, or partition removal.
- SFC, DISM repair, and similar operations can alter Windows state. Read the prompt and back up important data before intentionally proceeding.
- Do not interpret a successful query as proof of overall system health or security.

## Known limitations

- Windows CIM and Storage cmdlet data varies with hardware, drivers, OS edition, virtualization, and permissions.
- Smart/reliability counters and temperatures are frequently unavailable, especially behind USB bridges or RAID controllers.
- A ping failure can mean ICMP filtering rather than a broken internet connection.
- Windows Update compliance cannot be established from a hotfix list alone.
- Detailed local group, Secure Boot, Defender, and event-log checks may be unavailable in some sessions.
- The toolkit is not a substitute for vendor diagnostics, backups, incident response, or qualified repair.

## Development and testing

Scripts are designed for Windows PowerShell 5.1. From PowerShell in the repository root, parse-check the scripts:

```powershell
Get-ChildItem .\modules\*.ps1 | ForEach-Object {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count) { $errors | ForEach-Object { Write-Error ("{0}: {1}" -f $_.Extent, $_.Message) } }
    else { "Parse OK: $($_.Name)" }
}
```

Interactive modules should be run on a Windows test machine. This repository change has not been executed against Windows hardware; treat runtime validation as outstanding.
