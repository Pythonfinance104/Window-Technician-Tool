@echo off

REM ======================================================
REM WINDOWS TECHNICIAN TOOLKIT
REM Version: 3.0
REM Technologies: Batch + PowerShell
REM ======================================================

title Windows Technician Toolkit v3.0
color 0E

REM Define the main project directory
set "TOOLKIT=%~dp0"

REM Define the folders used by the toolkit
set "MODULES=%TOOLKIT%modules"
set "REPORTS=%TOOLKIT%reports"
set "LOGS=%TOOLKIT%logs"

REM Automatically create missing folders
if not exist "%MODULES%" mkdir "%MODULES%"
if not exist "%REPORTS%" mkdir "%REPORTS%"
if not exist "%LOGS%" mkdir "%LOGS%"

:menu

cls

echo.
echo ======================================================
echo             WINDOWS TECHNICIAN TOOLKIT
echo ======================================================
echo.
echo  [1] System Information
echo  [2] Network Diagnostics
echo  [3] Disk Health
echo  [4] Hardware Information
echo  [5] Windows Security Audit
echo  [6] Windows Administrative Tools
echo  [7] System Repair
echo  [8] Open Reports Folder
echo  [9] Exit
echo.
echo ======================================================

set /p choice=Select an option:

if "%choice%"=="1" goto system
if "%choice%"=="2" goto network
if "%choice%"=="3" goto disk
if "%choice%"=="4" goto hardware
if "%choice%"=="5" goto security
if "%choice%"=="6" goto admin
if "%choice%"=="7" goto repair
if "%choice%"=="8" start "" "%REPORTS%" & goto menu
if "%choice%"=="9" exit /b

echo.
echo Invalid selection!
pause
goto menu

REM ======================================================
REM POWERSHELL MODULE EXECUTION
REM ======================================================

:system
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\SystemInfo.ps1"
pause
goto menu

:network
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\NetworkDiagnostics.ps1"
pause
goto menu

:disk
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\DiskHealth.ps1"
pause
goto menu

:hardware
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\HardwareInfo.ps1"
pause
goto menu

:security
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MODULES%\SecurityAudit.ps1"
pause
goto menu

REM ======================================================
REM WINDOWS ADMINISTRATIVE TOOLS
REM ======================================================

:admin

cls

echo.
echo ============ ADMINISTRATIVE TOOLS ============
echo.
echo 1. Command Prompt
echo 2. PowerShell
echo 3. Registry Editor
echo 4. Services
echo 5. Event Viewer
echo 6. Task Manager
echo 7. Computer Management
echo 8. Back
echo.

set /p adminchoice=Select an option:

if "%adminchoice%"=="1" start "" cmd
if "%adminchoice%"=="2" start "" powershell
if "%adminchoice%"=="3" start "" regedit
if "%adminchoice%"=="4" start "" services.msc
if "%adminchoice%"=="5" start "" eventvwr
if "%adminchoice%"=="6" start "" taskmgr
if "%adminchoice%"=="7" start "" compmgmt.msc
if "%adminchoice%"=="8" goto menu

goto admin

REM ======================================================
REM SYSTEM REPAIR
REM ======================================================

:repair

cls

echo.
echo ================ SYSTEM REPAIR ================
echo.
echo 1. System File Checker
echo 2. DISM Check Health
echo 3. DISM Scan Health
echo 4. Disk Check
echo 5. Back
echo.

set /p repairchoice=Select an option:

if "%repairchoice%"=="1" sfc /scannow
if "%repairchoice%"=="2" DISM /Online /Cleanup-Image /CheckHealth
if "%repairchoice%"=="3" DISM /Online /Cleanup-Image /ScanHealth
if "%repairchoice%"=="4" chkdsk C:
if "%repairchoice%"=="5" goto menu

pause
goto repair
