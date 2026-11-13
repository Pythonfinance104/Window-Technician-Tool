@echo off
setlocal

rem ==============================================================
rem WINDOWS TECHNICIAN TOOLKIT
rem VERSION: 3.1
rem PURPOSE: Safe diagnostic launcher with validated menu navigation
rem ==============================================================

title Windows Technician Toolkit v3.1
color 0E

set "TOOLKIT=%~dp0"
set "MODULES=%TOOLKIT%modules"
set "REPORTS=%TOOLKIT%reports"
set "LOGS=%TOOLKIT%logs"
set "IS_ADMIN=UNKNOWN"

if not exist "%REPORTS%\" md "%REPORTS%" 2>nul
if not exist "%LOGS%\" md "%LOGS%" 2>nul

call :check_admin

goto :main_menu

:main_menu
cls

echo ==============================================================
echo                  WINDOWS TECHNICIAN TOOLKIT
echo                            Version 3.1
echo ==============================================================
echo.
echo Administrator privileges: %IS_ADMIN%
echo.
echo  [1] System diagnostics       - Windows edition, CPU, RAM and system details
echo  [2] Network diagnostics      - Adapters, IP configuration and connectivity
echo  [3] Storage and disk health  - Disks, volumes, free space and reliability
echo  [4] Hardware information     - Detailed hardware inventory
echo  [5] Windows security audit   - Defender, firewall and security settings
echo  [6] System administration    - Open built-in Windows administration tools
echo  [7] Repair and maintenance   - Inspect or confirm selected Windows checks
echo  [8] Reports and logs         - Open the toolkit output folders
echo  [9] About                    - Toolkit information and safety notes
echo  [0] Exit
echo.
echo Use the listed number keys. Other keys are rejected by the menu.
choice /c 1234567890 /n /m "Select an option: "

if errorlevel 10 goto :exit_menu
if errorlevel 9 goto :about_menu
if errorlevel 8 goto :reports_menu
if errorlevel 7 goto :repair_menu
if errorlevel 6 goto :admin_menu
if errorlevel 5 goto :security_module
if errorlevel 4 goto :hardware_module
if errorlevel 3 goto :disk_module
if errorlevel 2 goto :network_module
if errorlevel 1 goto :system_module

goto :main_menu

:system_module
call :run_module "SystemInfo.ps1" "System diagnostics"
goto :main_menu

:network_module
call :run_module "NetworkDiagnostics.ps1" "Network diagnostics"
goto :main_menu

:disk_module
call :run_module "DiskHealth.ps1" "Storage and disk health"
goto :main_menu

:hardware_module
call :run_module "HardwareInfo.ps1" "Hardware information"
goto :main_menu

:security_module
call :run_module "SecurityAudit.ps1" "Windows security audit"
goto :main_menu

:run_module
cls

echo ==============================================================
echo %~2
echo ==============================================================
echo.

if not exist "%MODULES%\%~1" (
    echo.
    echo This function is not available because the required module
    echo was not found:
    echo "%MODULES%\%~1"
    echo.
    echo No action was taken. Add the module before using this option.
    pause
    exit /b 0
)

where.exe powershell.exe >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Windows PowerShell could not be found.
    echo The module was not started.
    pause
    exit /b 1
)

echo.
echo Starting module: %~1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\%~1"
set "MODULE_EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%MODULE_EXIT_CODE%"=="0" (
    echo The module returned exit code %MODULE_EXIT_CODE%.
    echo Review any error message above. The launcher will continue.
) else (
    echo Module process completed.
)
pause
exit /b 0

:admin_menu
cls
echo ==============================================================
echo                    SYSTEM ADMINISTRATION
echo ==============================================================
echo These choices open built-in Windows tools; they do not elevate
echo this toolkit automatically. A tool may request UAC elevation.
echo.
echo  [1] Command Prompt
echo  [2] Windows PowerShell
echo  [3] Services
echo  [4] Event Viewer
echo  [5] Task Manager
echo  [6] Computer Management
echo  [7] Registry Editor - opening only; changes are not made here
echo  [8] Open toolkit logs folder
echo  [0] Back to main menu
echo.
choice /c 123456780 /n /m "Select an option: "

if errorlevel 9 goto :main_menu
if errorlevel 8 goto :admin_logs
if errorlevel 7 goto :admin_registry
if errorlevel 6 start "" compmgmt.msc
if errorlevel 5 start "" taskmgr.exe
if errorlevel 4 start "" eventvwr.msc
if errorlevel 3 start "" services.msc
if errorlevel 2 start "" powershell.exe
if errorlevel 1 start "" cmd.exe

goto :admin_menu

:admin_registry
cls
echo.
echo Registry Editor allows system configuration changes.
echo This toolkit will only open it; it will not change the registry.
choice /c YN /n /m "Open Registry Editor? (Y/N): "
if errorlevel 2 goto :admin_menu
start "" regedit.exe
goto :admin_menu

:admin_logs
if not exist "%LOGS%\" (
    echo.
    echo The logs folder could not be found or created:
    echo "%LOGS%"
    pause
    goto :admin_menu
)
start "" "%LOGS%"
goto :admin_menu

:repair_menu
cls
echo ==============================================================
echo                 REPAIR AND MAINTENANCE
echo ==============================================================
echo Read each description before choosing an operation.
echo No operation runs automatically after a diagnostic.
echo.
echo  [1] SFC /scannow
echo      Checks protected Windows system files and attempts repairs.
echo      Requires administrator privileges and can modify system files.
echo.
echo  [2] DISM CheckHealth
echo      Checks whether Windows records component-store corruption.
echo      Requires administrator privileges; this is a check.
echo.
echo  [3] DISM ScanHealth
echo      Performs a more thorough component-store corruption scan.
echo      Requires administrator privileges; this is a scan.
echo.
echo  [4] CHKDSK C:
echo      Displays file-system status for C: without /F or /R repair flags.
echo      It does not request a disk repair or schedule one.
echo.
echo  [5] DISM RestoreHealth
echo      Attempts to repair the Windows component store. This can take
echo      time and may use Windows Update as a repair source.
echo      Requires administrator privileges and modifies Windows files.
echo.
echo  [0] Back to main menu
echo.
choice /c 123450 /n /m "Select an option: "

if errorlevel 6 goto :main_menu
if errorlevel 5 call :confirm_repair "DISM RestoreHealth" "Repairs the Windows component store; this can take a long time and may use Windows Update." "YES" "RESTORE"
if errorlevel 4 call :confirm_repair "CHKDSK C:" "Checks the C: file system without repair flags. It will not run /F or /R." "NO" "CHKDSK"
if errorlevel 3 call :confirm_repair "DISM ScanHealth" "Scans the Windows component store for corruption; this is a diagnostic scan." "YES" "SCAN"
if errorlevel 2 call :confirm_repair "DISM CheckHealth" "Checks whether Windows has recorded component-store corruption." "YES" "CHECK"
if errorlevel 1 call :confirm_repair "SFC /scannow" "Checks protected Windows system files and attempts to repair detected problems." "YES" "SFC"

goto :repair_menu

:confirm_repair
cls
echo ==============================================================
echo %~1
echo ==============================================================
echo.
echo Purpose and caution:
echo %~2
echo.
if /I "%~3"=="YES" (
    echo This operation requires an elevated administrator session.
) else (
    echo This check does not include disk repair flags.
)
echo.
choice /c YN /n /m "Proceed with this operation? (Y/N): "
if errorlevel 2 (
    echo.
    echo Cancelled. No operation was run.
    pause
    exit /b 0
)

if /I "%~3"=="YES" (
    call :check_admin
    if /I not "%IS_ADMIN%"=="YES" (
        echo.
        echo This operation was not started because this toolkit is not
        echo running with administrator privileges.
        echo Close the toolkit and launch it from an elevated terminal
        echo only if you choose to proceed with this operation.
        pause
        exit /b 1
    )
)

echo.
echo Running %~1...
echo Do not close this window while the operation is running.
echo.

if /I "%~4"=="SFC" sfc.exe /scannow
if /I "%~4"=="CHECK" DISM.exe /Online /Cleanup-Image /CheckHealth
if /I "%~4"=="SCAN" DISM.exe /Online /Cleanup-Image /ScanHealth
if /I "%~4"=="RESTORE" DISM.exe /Online /Cleanup-Image /RestoreHealth
if /I "%~4"=="CHKDSK" chkdsk.exe C:

set "REPAIR_EXIT_CODE=%ERRORLEVEL%"
echo.
echo Operation process exit code: %REPAIR_EXIT_CODE%
echo No additional repair operation was started.
pause
exit /b 0

:reports_menu
cls
echo ==============================================================
echo                      REPORTS AND LOGS
echo ==============================================================
echo Reports and logs may contain system or diagnostic details.
echo Review them before sharing.
echo.
echo  [1] Open reports folder
echo  [2] Open logs folder
echo  [0] Back to main menu
echo.
choice /c 120 /n /m "Select an option: "

if errorlevel 3 goto :main_menu
if errorlevel 2 goto :open_logs
if errorlevel 1 goto :open_reports
goto :reports_menu

:open_reports
if not exist "%REPORTS%\" (
    echo.
    echo The reports folder could not be found or created:
    echo "%REPORTS%"
    pause
    goto :reports_menu
)
start "" "%REPORTS%"
goto :reports_menu

:open_logs
if not exist "%LOGS%\" (
    echo.
    echo The logs folder could not be found or created:
    echo "%LOGS%"
    pause
    goto :reports_menu
)
start "" "%LOGS%"
goto :reports_menu

:about_menu
cls
echo ==============================================================
echo                  WINDOWS TECHNICIAN TOOLKIT
echo ==============================================================
echo Version: 3.1
echo.
echo A local launcher for Windows diagnostics and technician tools.
echo Diagnostics and repairs are provided by the PowerShell modules
echo in the modules folder and built-in Windows utilities.
echo.
echo Missing modules are reported and are not launched.
echo Repair operations require a separate confirmation. Administrator
echo access is checked when selected operations require it.
echo.
echo This toolkit does not guarantee that a computer is secure or that
echo a diagnostic result identifies the root cause of a problem.
echo Review recommendations and back up important data before repairs.
echo.
pause
goto :main_menu

:check_admin
set "IS_ADMIN=UNKNOWN"
where.exe powershell.exe >nul 2>&1
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -NonInteractive -Command "$identity = [Security.Principal.WindowsIdentity]::GetCurrent(); $principal = New-Object Security.Principal.WindowsPrincipal($identity); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }" >nul 2>&1
if errorlevel 1 (
    set "IS_ADMIN=NO"
) else (
    set "IS_ADMIN=YES"
)
exit /b 0

:exit_menu
cls
echo Exit the Windows Technician Toolkit?
choice /c YN /n /m "Exit? (Y/N): "
if errorlevel 2 goto :main_menu
echo.
echo Toolkit closed.
endlocal
exit /b 0
