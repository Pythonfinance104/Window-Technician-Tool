# Windows Technician Toolkit - Common helpers (Windows PowerShell 5.1 compatible)
$script:ToolkitRoot = Split-Path -Parent $PSScriptRoot
$script:ReportsRoot = Join-Path $script:ToolkitRoot 'reports'
$script:LogsRoot = Join-Path $script:ToolkitRoot 'logs'

function Initialize-ToolkitDirectories {
    foreach ($path in @($script:ReportsRoot, $script:LogsRoot)) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }
    }
}

function Test-ToolkitAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Write-ToolkitLog {
    param(
        [ValidateSet('INFO','WARNING','ERROR','SUCCESS','DEBUG')][string]$Level = 'INFO',
        [string]$Module = 'Toolkit', [string]$Operation = 'General',
        [string]$Result = '', [string]$Details = ''
    )
    try {
        Initialize-ToolkitDirectories
        $safe = ($Details -replace '(?i)(password|token|secret|credential)\s*[:=]\s*[^\s,;]+', '$1=[REDACTED]') -replace '[\r\n]+',' '
        $line = '{0} | {1} | {2} | {3} | {4} | {5}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Module, $Operation, $Result, $safe
        Add-Content -LiteralPath (Join-Path $script:LogsRoot ('toolkit_{0}.log' -f (Get-Date -Format 'yyyy-MM-dd'))) -Value $line -Encoding UTF8 -ErrorAction Stop
    } catch { Write-Warning ('Could not write toolkit log: {0}' -f $_.Exception.Message) }
}

function New-ToolkitReport {
    param([Parameter(Mandatory=$true)][string]$Category, [Parameter(Mandatory=$true)][string]$Body)
    Initialize-ToolkitDirectories
    $safe = $Category -replace '[^A-Za-z0-9_-]',''
    $path = Join-Path $script:ReportsRoot ('{0}_{1}_{2}.txt' -f $safe, (Get-Date -Format 'yyyyMMdd_HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0,6)))
    $header = @(
        'WINDOWS TECHNICIAN TOOLKIT',
        ('Category: {0}' -f $Category),
        ('Computer: {0}' -f $env:COMPUTERNAME),
        ('Generated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')),
        ('Toolkit version: 3.1'),
        ('-' * 72), ''
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $path -Value ($header + $Body) -Encoding UTF8 -ErrorAction Stop
    Write-ToolkitLog -Level SUCCESS -Module $Category -Operation 'Report generation' -Result 'Saved'
    return $path
}

function Write-Finding {
    param([string]$Title, [string]$Detected, [string]$Meaning, [string]$Why, [string]$Risk='INFORMATIONAL', [string]$Action='No action indicated by this check.')
    Write-Host ('[{0}] {1}' -f $Risk, $Title) -ForegroundColor $(if ($Risk -in @('HIGH RISK','CRITICAL')) {'Red'} elseif ($Risk -eq 'MEDIUM RISK') {'Yellow'} else {'Cyan'})
    Write-Host ('Detected: {0}' -f $Detected)
    Write-Host ('What it means: {0}' -f $Meaning)
    Write-Host ('Why it matters: {0}' -f $Why)
    Write-Host ('Recommended action: {0}' -f $Action)
    Write-Host ''
}

function Read-ToolkitYesNo {
    param([Parameter(Mandatory=$true)][string]$Prompt)
    do { $answer = Read-Host ($Prompt + ' (Y/N)') } while ($answer -notmatch '^(?i:y|yes|n|no)$')
    return ($answer -match '^(?i:y|yes)$')
}

function Pause-Toolkit { [void](Read-Host 'Press Enter to continue') }
Initialize-ToolkitDirectories
